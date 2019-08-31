import grpc
from grpc_health.v1 import health_pb2_grpc as heartb_pb2_grpc
from grpc_health.v1 import health_pb2 as heartb_pb2

import sys
import os
import time
import logging
import argparse
import hashlib
import random
import string

from concurrent import futures

from db import Credential, Service, Device
from db.interface import Database

sm_root_dir = os.path.abspath(os.path.join(os.path.dirname(__file__)))
sys.path.insert(0, "{}/api/".format(sm_root_dir))

import api.session_manager_pb2_grpc as sm_pb2_grpc
import api.session_manager_pb2 as sm_pb2

import api.opencog_services_pb2_grpc as opcog_pb2_grpc
import api.opencog_services_pb2 as opcog_pb2

import api.named_entity_recognition_pb2_grpc as ner_pb2_grpc
import api.named_entity_recognition_pb2 as ner_pb2

import api.sentiment_analysis_pb2_grpc as sa_pb2_grpc
import api.sentiment_analysis_pb2 as sa_pb2


logging.basicConfig(format="%(asctime)s - [%(levelname)8s] "
                           "- %(name)s - %(message)s", level=logging.INFO)
log = logging.getLogger("session_manager")

ONE_DAY_IN_SECONDS = 60 * 60 * 24


def hash_password(password):
    m = hashlib.sha256()
    m.update(password.encode("utf-8"))
    return m.hexdigest()


def generate_access_token(length=15):
    key = ''.join(random.choice(string.ascii_letters + string.digits)
                  for _ in range(length))
    return key.upper()


class Status:
    OK = 0
    PERMISSION_DENIED = 1
    CANCELLED = 2
    UNKNOWN = 3


class HealthStatus:
    UNKNOWN = 0
    SERVING = 1
    NOT_SERVING = 2


class HealthServicer(heartb_pb2_grpc.HealthServicer):

    def __init__(self, db_file="sessions.db", db_create=False):
        self.db = Database(db_file=db_file, db_create=db_create)

    def Check(self, request, context):
        response = heartb_pb2.HealthCheckResponse()
        response.status = HealthStatus.UNKNOWN
        if request.service == "opencog_services":
            ocs = self.db.query(Service, service_name="OPENCOG_SERVICES")
            if ocs:
                s = self.create_health_stub(ocs.service_host, ocs.service_port)
                response.status = self.get_server_status(s)
            else:
                response.status = HealthStatus.NOT_SERVING
        return response

    @staticmethod
    def create_health_stub(host, port):
        try:
            channel = grpc.insecure_channel("{}:{}".format(host, port))
            stub = heartb_pb2_grpc.HealthStub(channel)
            return stub
        except Exception as e:
            log.error(e)

    @staticmethod
    def get_server_status(stub):
        try:
            stub.Check(heartb_pb2.HealthCheckRequest(service=""), timeout=10)
            return HealthStatus.SERVING
        except Exception as e:
            log.error(e)
            return HealthStatus.NOT_SERVING


class SessionManagerServicer(sm_pb2_grpc.SessionManagerServicer):
    
    def __init__(self, db_session, timeout=20):
        self.db = db_session
        self.timeout = timeout

    def Login(self, request, context):
        cred = self.db.query(Credential,
                             username=request.username,
                             password=hash_password(request.password))
        if not cred:
            return self.set_grpc_context(
                context,
                sm_pb2.LoginOutput(status=Status.PERMISSION_DENIED,
                                   access_token=""),
                "User not registered!", grpc.StatusCode.PERMISSION_DENIED)

        # Check if the Device is already registered
        device = self.db.query(Device,
                               device_name=request.device_name,
                               username=request.username)

        # Check if the Device is the active one
        if device and cred.active_device == device.device_name:
            log.warning("Device is already active and logged in.")
            return sm_pb2.LoginOutput(status=Status.OK,
                                      access_token=device.access_token)

        access_token = generate_access_token()
        if not device:
            log.info("Registering new Device: '{}'".format(
                request.device_name))
            self.db.add(Device,
                        device_name=request.device_name,
                        access_token=access_token,
                        username=cred.username)
        elif device.access_token == "":
            log.info("Setting new access_token for: '{}'".format(
                request.device_name))
            self.db.update(Device,
                           where={"username": cred.username,
                                  "device_name": device.device_name},
                           update={"access_token": access_token})
        else:
            access_token = device.access_token
            log.warning("Device '{}' is already logged in.".format(
                request.device_name))

        # Checking if no Ghost Session was initialized yet
        if not cred.session_id:
            log.info("Calling start_session: '{}'".format(request.device_name))
            if not self.start_session(cred.username):
                return self.set_grpc_context(
                    context,
                    sm_pb2.LoginOutput(status=Status.OK,
                                       access_token=access_token),
                    "Opencog Services offline!",
                    grpc.StatusCode.OK)
        return sm_pb2.LoginOutput(status=Status.OK, access_token=access_token)

    def Logout(self, request, context):
        cred, device, access_token = self.validate_access(context)
        if not access_token:
            return self.set_grpc_context(context,
                                         sm_pb2.LogoutOutput(),
                                         "Invalid access!",
                                         grpc.StatusCode.PERMISSION_DENIED)

        if cred.active_device == request.device_name:
            log.info("The active Device is logging out...")
            self.set_active_device(device.username, "")

        log.info("Updating the Device info...")
        self.db.update(Device,
                       where={"dev_id": device.dev_id},
                       update={"access_token": ""})
        return sm_pb2.LogoutOutput(status=Status.OK)

    def Utterance(self, request, context):
        cred, device, access_token = self.validate_access(context)
        if not access_token:
            return self.set_grpc_context(context,
                                         sm_pb2.UtteranceOutput(),
                                         "Invalid access!",
                                         grpc.StatusCode.PERMISSION_DENIED)
        status, response, msg = self.send_opencog_command(cred,
                                                          device,
                                                          "utterance",
                                                          [request.utterance])
        if not status:
            return self.set_grpc_context(context,
                                         sm_pb2.UtteranceOutput(),
                                         msg,
                                         grpc.StatusCode.PERMISSION_DENIED)

        ocs_stub = self.create_service_stub(service_name="OPENCOG_SERVICES")

        # Named Entity Recognition
        s = self.create_service_stub(service_name="NAMED_ENTITY_RECOGNITION")
        if s:
            future_call = s.Recognize.future(ner_pb2.EntityRecognitionInput(
                value=request.utterance), timeout=self.timeout)
            future_call.add_done_callback(
                self.create_service_callback(ocs_stub, "recognize"))

        # Sentiment Analysis
        s = self.create_service_stub(service_name="SENTIMENT_ANALYSIS")
        if s:
            future_call = s.Analyze.future(sa_pb2.SentimentAnalysisInput(
                value=request.utterance), timeout=self.timeout)
            future_call.add_done_callback(
                self.create_service_callback(ocs_stub, "analyze"))
        return sm_pb2.UtteranceOutput(utterance=response.output)
    
    def Geolocation(self, request, context):
        cred, device, access_token = self.validate_access(context)
        if not access_token:
            return self.set_grpc_context(context,
                                         sm_pb2.GeolocationOutput(),
                                         "Invalid access!",
                                         grpc.StatusCode.PERMISSION_DENIED)
        params = [str(request.latitude), str(request.longitude)]
        status, response, msg = self.send_opencog_command(cred,
                                                          device,
                                                          "geolocation",
                                                          params)
        if not status:
            return self.set_grpc_context(context,
                                         sm_pb2.GeolocationOutput(),
                                         msg,
                                         grpc.StatusCode.PERMISSION_DENIED)
        # TODO: Deal with the Opencog Geolocation.
        #       Forward this to the restaurant-info-server?.
        return sm_pb2.GeolocationOutput(status=Status.OK)

    def Prompt(self, request, context):
        cred, device, access_token = self.validate_access(context)
        if not access_token:
            return self.set_grpc_context(context,
                                         opcog_pb2.CommandOutput(),
                                         "Invalid access!",
                                         grpc.StatusCode.PERMISSION_DENIED)
        status, response, msg = self.send_opencog_command(cred,
                                                          device,
                                                          request.cmd,
                                                          request.params)
        if not status:
            return self.set_grpc_context(context,
                                         opcog_pb2.CommandOutput(),
                                         msg,
                                         grpc.StatusCode.PERMISSION_DENIED)
        # TODO: Deal with the Opencog Prompt.
        return response

    def Reset(self, request, context):
        cred, device, access_token = self.validate_access(context)
        if not access_token:
            return self.set_grpc_context(context,
                                         opcog_pb2.CommandOutput(),
                                         "Invalid access!",
                                         grpc.StatusCode.PERMISSION_DENIED)
        status, response, msg = self.send_opencog_command(cred,
                                                          device,
                                                          request.cmd,
                                                          request.params)
        if not status:
            return self.set_grpc_context(context,
                                         opcog_pb2.CommandOutput(),
                                         msg,
                                         grpc.StatusCode.PERMISSION_DENIED)
        # TODO: Deal with the Opencog reset.
        #       Update the DB to reflect this.
        self.set_active_device(device.username, "")
        return response

    # Sends a start_session command to Opencog Services
    def start_session(self, username):
        stub = self.create_service_stub(service_name="OPENCOG_SERVICES")
        if stub:
            try:
                command = opcog_pb2.Command(service="VA", cmd="start_session")
                r = stub.Execute(command)
                self.db.update(Credential,
                               where={"username": username},
                               update={"session_id": int(r.output)})
                return True
            except Exception as e:
                log.error(e)
        return False
    
    # Check if the device is the active and set it if no active_device.
    # Then send the proper command
    # Returns status, CommandOutput, error_msg
    def send_opencog_command(self, cred, device, cmd, params):
        if cred.active_device not in ["", device.device_name]:
            return False, None, "Another Device is activated!"
        if cred.active_device == "":
            self.set_active_device(device.username, device.device_name)
        # Checking if no Ghost Session was initialized yet
        if not cred.session_id:
            log.info("Starting Session: '{}'".format(device.device_name))
            if not self.start_session(device.username):
                return False, None, "Opencog Services offline!"
        log.info("[{}:{}] is sending '{}' '{}'...".format(device.device_name,
                                                          cred.session_id,
                                                          cmd,
                                                          params))
        s = self.create_service_stub(service_name="OPENCOG_SERVICES")
        if not s:
            return False, None, "Opencog Services offline!"
        command = opcog_pb2.Command(service="VA",
                                    cmd=cmd,
                                    session_id=cred.session_id,
                                    params=params)
        return True, s.Execute(command), ""

    # Checks if the incoming request is valid
    def validate_access(self, context):
        access_token = self.get_access_token(context.invocation_metadata())
        if not access_token:
            log.error("No access token!")
            return None, None, None
        device = self.db.query(Device, access_token=access_token)
        if not device:
            log.error("Device not registered!")
            return None, None, None
        cred = self.db.query(Credential, username=device.username)
        if not cred:
            log.error("User not registered!")
            return None, None, None
        return cred, device, access_token

    # Set the active_device column of Credential with the device_name
    def set_active_device(self, username, device_name):
        log.info("Setting {}.active_device to '{}'".format(username,
                                                           device_name))
        return self.db.update(Credential,
                              where={"username": username},
                              update={"active_device": device_name})
    
    def create_service_stub(self, service_name):
        s = self.db.query(Service, service_name=service_name)
        if s:
            try:
                channel = grpc.insecure_channel("{}:{}".format(s.service_host,
                                                               s.service_port))
                if service_name == "OPENCOG_SERVICES":
                    stub = opcog_pb2_grpc.OpencogServicesStub(channel)
                    grpc.channel_ready_future(channel).result()
                    return stub
                elif service_name == "NAMED_ENTITY_RECOGNITION":
                    return ner_pb2_grpc.RecognizeEntityStub(channel)
                elif service_name == "SENTIMENT_ANALYSIS":
                    return sa_pb2_grpc.SentimentAnalysisStub(channel)
            except Exception as e:
                log.error(e)
                log.error("Service '{}' not available!".format(service_name))
        else:
            log.error("Service '{}' not registered!".format(service_name))

    @staticmethod
    def set_grpc_context(context, message_type, msg, code=None):
        log.warning(msg)
        context.set_details(msg)
        if code:
            context.set_code(code)
        return message_type

    @staticmethod
    def get_access_token(metadata):
        for key, value in metadata:
            if key == "access_token" and value:
                return value
        return None

    @staticmethod
    def create_service_callback(opencog_stub, cmd):
        def _callback(future):
            try:
                response = future.result()
                command = opcog_pb2.Command(service="VA",
                                            cmd=cmd,
                                            params=[response.value])
                opencog_stub.Execute(command)
            except grpc.RpcError as e:
                log.error(e)
        return _callback


class SessionManagerServer:
    def __init__(self,
                 db_file="sessions.db",
                 db_create=False,
                 port=50000, timeout=30):

        self.db_file = db_file
        self.db_create = db_create
        self.db = Database(db_file=db_file, db_create=db_create)
        self.port = port
        self.server = None
        self.timeout = timeout

    def start_server(self):
        self.server = grpc.server(futures.ThreadPoolExecutor(max_workers=20))
        heartb_pb2_grpc.add_HealthServicer_to_server(
            HealthServicer(db_file=self.db_file,
                           db_create=self.db_create), self.server)
        sm_pb2_grpc.add_SessionManagerServicer_to_server(
            SessionManagerServicer(db_session=self.db,
                                   timeout=self.timeout), self.server)
        self.server.add_insecure_port("[::]:{}".format(self.port))
        log.info("Starting SessionManagerServer at localhost:{}".format(
            self.port))
        self.server.start()

    def stop_server(self):
        self.server.stop(0)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--db-file",
                        "-db",
                        dest="db_file",
                        default="sessions.db",
                        help="DB file name")
    parser.add_argument("--db-create",
                        action="store_true",
                        dest="db_create",
                        default=False,
                        help="Force DB creating")
    parser.add_argument("--port",
                        "-p",
                        type=int,
                        default=50000,
                        help="Session manager server port")
    parser.add_argument("--timeout",
                        "-t",
                        type=int,
                        default=30,
                        help="Timeout for Opencog server RPC")
    args = parser.parse_args()

    server = SessionManagerServer(db_file=args.db_file,
                                  db_create=args.db_create,
                                  port=args.port,
                                  timeout=args.timeout)
    server.start_server()
    
    try:
        while True:
            time.sleep(ONE_DAY_IN_SECONDS)
    except KeyboardInterrupt:
        server.stop_server()
