import grpc
from concurrent import futures
import logging
import time
import random

from grpc_health.v1 import health_pb2_grpc as heartb_pb2_grpc
from grpc_health.v1 import health_pb2 as heartb_pb2

from api import opencog_services_pb2 as opcog_pb2
from api import opencog_services_pb2_grpc as opcog_pb2_grpc


log = logging.getLogger("opencog_services_test_server")

_ONE_DAY_IN_SECONDS = 60 * 60 * 24


class Status:
    OK = 0
    PERMISSION_DENIED = 1
    CANCELLED = 2
    UNKNOWN = 3


class HealthServicer(heartb_pb2_grpc.HealthServicer):

    def Check(self, request, context):
        response = heartb_pb2.HealthCheckResponse()
        # UNKNOWN = 0;
        # SERVING = 1;
        # NOT_SERVING = 2;
        response.status = 1
        return response


class OpencogServicesServicer(opcog_pb2_grpc.OpencogServicesServicer):

    def Execute(self, request, context):
        log.info("Receiving Execute: {} {}".format(request.cmd,
                                                   request.params))
        if request.service == "VA":
            if request.cmd == "start_session":
                session_id = random.randint(1, 1000000)
                return opcog_pb2.CommandOutput(output=str(session_id))
            elif request.cmd == "utterance":
                return opcog_pb2.CommandOutput(output="Utterance")
            elif request.cmd == "prompt":
                return opcog_pb2.CommandOutput(output="Prompt")
            elif request.cmd == "geolocation":
                return opcog_pb2.CommandOutput(output="Geolocation")
            elif request.cmd == "reset":
                return opcog_pb2.CommandOutput(output="Reset")

        return opcog_pb2.CommandOutput(
            output="<Execute>:<{}>#<{}>".format(request.cmd, request.params))
    
    def AsynchronousTask(self, request, context):
        log.info("Receiving AsynchronousTask: {} {}".format(request.cmd,
                                                            request.params))
        if request.service == "VA":
            if request.cmd == "start_session":
                session_id = random.randint(1, 1000000)
                return opcog_pb2.CommandOutput(output=str(session_id))
            elif request.cmd == "utterance":
                return opcog_pb2.CommandOutput(output="Hello")
            elif request.cmd == "prompt":
                return opcog_pb2.CommandOutput(output="Prompt")
            elif request.cmd == "geolocation":
                return opcog_pb2.CommandOutput(output="Geolocation")
            elif request.cmd == "reset":
                return opcog_pb2.CommandOutput(output="Reset")

        return opcog_pb2.CommandOutput(
            output="<AsyncTask>:<{}>#<{}>".format(request.cmd, request.params))


class OpenCogServer:
    def __init__(self, port=50090):
        self.port = port
        self.server = None

    def start_server(self):
        log.info("Starting OpenCogServer at localhost:{}".format(self.port))
        self.server = grpc.server(futures.ThreadPoolExecutor(max_workers=10))
        heartb_pb2_grpc.add_HealthServicer_to_server(
            HealthServicer(), self.server)
        opcog_pb2_grpc.add_OpencogServicesServicer_to_server(
            OpencogServicesServicer(), self.server)
        self.server.add_insecure_port('[::]:{}'.format(self.port))
        self.server.start()

    def stop_server(self):
        self.server.stop(0)


if __name__ == '__main__':
    server = OpenCogServer(port=50090)
    server.start_server()
    try:
        while True:
            time.sleep(_ONE_DAY_IN_SECONDS)
    except KeyboardInterrupt:
        server.stop_server()
