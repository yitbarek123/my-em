import grpc
import logging

from session_manager_server import (sm_pb2_grpc,
                                    sm_pb2,
                                    hash_password,
                                    generate_access_token)

from db import Credential, Service, Device
from db.interface import Database

import api.opencog_services_pb2 as opcog_pb2

from tests.services.named_entity_recognition import \
    NamedEntityRecognitionServer
from tests.services.opencog_services import OpenCogServer
from tests.services.sentiment_analysis import SentimentAnalysisServer

opencog_services = None
named_entity_server = None
sentiment_analysis_server = None

log = logging.getLogger("session_manager_admin")

db = None

def set_db(db_file, db_create=False, logger=None):
    global db
    db = Database(db_file, db_create, logger)


def show_credentials():
    db.print_table(Credential)


def show_services():
    db.print_table(Service)


def show_devices():
    db.print_table(Device)


def add_credential(username, password):
    if db.add(Credential, username=username, password=hash_password(password)):
        log.info("Credential with username '{}' added.".format(username))
    else:
        log.error("Error adding '{}'!".format(username))


def add_device(username, password, device_name):
    cred = db.query(Credential,
                    username=username,
                    password=hash_password(password))
    device = db.query(Device,
                      username=username,
                      device_name=device_name)
    if cred and not device:
        if db.add(Device,
                  username=username,
                  device_name=device_name):
            log.info("Device '{}' added to User '{}'.".format(device_name,
                                                              username))
    else:
        log.error("Error adding device '{}'!".format(device_name))


def activate_device(username, password, device_name):
    cred = db.query(Credential,
                    username=username,
                    password=hash_password(password))
    device = db.query(Device,
                      username=username,
                      device_name=device_name)
    if cred and device:
        db.update(Credential,
                  where={"username": username},
                  update={"active_device": device_name})
        log.info("Device '{}' is active".format(device_name))
    else:
        log.error("Error activating device '{}'!".format(device_name))


def add_service(service_name, service_host, service_port):
    if db.add(Service,
              service_name=service_name,
              service_host=service_host,
              service_port=service_port):
        log.info("Service '{}' added.".format(service_name))
    else:
        log.error("Error adding service '{}'!".format(service_name))


def run_test_services_servers():
    add_service("OPENCOG_SERVICES", "localhost", 50090)
    add_service("NAMED_ENTITY_RECOGNITION", "localhost", 50021)
    add_service("SENTIMENT_ANALYSIS", "localhost", 50022)

    global opencog_services
    global named_entity_server
    global sentiment_analysis_server
    opencog_services = OpenCogServer(port=50090)
    opencog_services.start_server()

    named_entity_server = NamedEntityRecognitionServer(port=50021)
    named_entity_server.start_server()

    sentiment_analysis_server = SentimentAnalysisServer(port=50022)
    sentiment_analysis_server.start_server()


def stop_test_services_servers():
    delete_service("OPENCOG_SERVICES")
    delete_service("NAMED_ENTITY_RECOGNITION")
    delete_service("SENTIMENT_ANALYSIS")

    opencog_services.stop_server()
    named_entity_server.stop_server()
    sentiment_analysis_server.stop_server()


def get_service_info(service_name):
    log.info(db.query(Service, service_name=service_name))


def delete_one_credential(username):
    if db.delete(Credential, username=username):
        log.info("User '{}' deleted.".format(username))
    else:
        log.error("Error deleting user '{}'!".format(username))


def delete_all_credentials():
    all_entries = db.query_all(Credential)
    for c in all_entries:
        db.delete(Credential, username=c.username)


def delete_device(username, password, device_name):
    cred = db.query(Credential,
                    username=username,
                    password=hash_password(password))
    device = db.query(Device,
                      username=username,
                      device_name=device_name)
    if cred and device:
        if db.delete(Device, dev_id=device.dev_id):
            log.info("Device '{}' deleted.".format(device_name))
            return
    log.error("Error deleting device '{}'!".format(device_name))


def delete_service(service_name):
    if db.delete(Service, service_name=service_name):
        log.info("Service '{}' deleted.".format(service_name))
    else:
        log.error("Error deleting service '{}'!".format(service_name))


def delete_all_service():
    all_entries = db.query_all(Service)
    for s in all_entries:
        db.delete(Service, service_name=s.service_name)


def login(username, password, device_name):
    stub = get_session_manager_stub()
    status, access_token = grpc_login(stub, username, password, device_name)
    log.info("Login [{}], Status: {}".format(access_token, status))


def logout(access_token, device_name):
    stub = get_session_manager_stub()
    status = grpc_logout(stub, device_name, access_token)
    log.info("Logout [{}], Status: {}".format(access_token, status))


def utterance(access_token, utt):
    stub = get_session_manager_stub()
    r_utt = grpc_utterance(stub, access_token, utt)
    log.info("Utterance [{}], Response: {}".format(access_token, r_utt))


def prompt(access_token):
    stub = get_session_manager_stub()
    r = grpc_prompt(stub, access_token)
    log.info("Prompt [{}], Response: {}".format(access_token, r))


def geolocation(access_token, longitude, latitude):
    stub = get_session_manager_stub()
    status = grpc_geolocation(stub, access_token, longitude, latitude)
    log.info("Geolocation [{},{},{}], Status: {}".format(longitude,
                                                         latitude,
                                                         access_token,
                                                         status))


def reset(access_token):
    stub = get_session_manager_stub()
    r = grpc_reset(stub, access_token)
    log.info("Reset [{}], Response: {}".format(access_token, r))


def get_session_manager_stub(host="localhost", port=50000):
    channel = grpc.insecure_channel("{}:{}".format(host, port))
    return sm_pb2_grpc.SessionManagerStub(channel)


def grpc_login(stub, username, password, device_name):
    try:
        r = stub.Login(sm_pb2.LoginInput(username=username,
                                         password=password,
                                         device_name=device_name))
        return r.status, r.access_token
    except Exception as e:
        log.error(e)
        return 1, ""


def grpc_logout(stub, access_token, device_name):
    try:
        r, _ = stub.Logout.with_call(sm_pb2.LogoutInput(
            device_name=device_name),
            metadata=(("access_token", access_token),))
        return r.status
    except Exception as e:
        log.error(e)
        return "Fail"


def grpc_utterance(stub, access_token, utt):
    try:
        r, _ = stub.Utterance.with_call(sm_pb2.UtteranceInput(
            utterance=utt),
            metadata=(("access_token", access_token),))
        return r.utterance
    except Exception as e:
        log.error(e)
        return "Fail"


def grpc_prompt(stub, access_token):
    try:
        r, _ = stub.Prompt.with_call(
            opcog_pb2.Command(cmd="VA", params=["prompt"]),
            metadata=(("access_token", access_token),))
        return r.output
    except Exception as e:
        log.error(e)
        return "Fail"


def grpc_geolocation(stub, access_token, longitude, latitude):
    try:
        r, _ = stub.Geolocation.with_call(
            sm_pb2.GeolocationInput(longitude=longitude, latitude=latitude),
            metadata=(("access_token", access_token),))
        return r.status
    except Exception as e:
        log.error(e)
        return "Fail"


def grpc_reset(stub, access_token):
    try:
        r, _ = stub.Reset.with_call(
            opcog_pb2.Command(cmd="VA", params=["reset"]),
            metadata=(("access_token", access_token),))
        return r.output
    except Exception as e:
        log.error(e)
        return "Fail"
