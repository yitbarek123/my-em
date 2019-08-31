import unittest
import grpc
from grpc_health.v1 import health_pb2 as heartb_pb2
from grpc_health.v1 import health_pb2_grpc as heartb_pb2_grpc

from db import Credential, Service
from db.interface import Database

from session_manager_server import SessionManagerServer, hash_password
from .services.opencog_services import OpenCogServer


class HealthStatus:
    UNKNOWN = 0
    SERVING = 1
    NOT_SERVING = 2


class TestSessionManager(unittest.TestCase):

    def setUp(self):
        self.db = Database(db_file="test_sessions.db", db_create=True)
        self.db.add(Credential,
                    username="username_test1",
                    password=hash_password("password_1"))

        self.db.add(Service,
                    service_name="OPENCOG_SERVICES",
                    service_host="localhost",
                    service_port=50090)

        self.sm_server = SessionManagerServer(
            db_file="test_sessions.db",
            db_create=False,
            port=50000)
        self.sm_server.start_server()

        self.opencog_services = OpenCogServer()
        self.opencog_services.start_server()

        channel = grpc.insecure_channel("localhost:50000")
        self.health_stub = heartb_pb2_grpc.HealthStub(channel)

    # One server up the other two servers down
    def test_health_one_server_down(self):
        response = self.health_stub.Check(
            heartb_pb2.HealthCheckRequest(service="opencog_services"),
            timeout=10)
        self.assertEqual(response.status, HealthStatus.SERVING)
    
    def tearDown(self):
        self.opencog_services.stop_server()
        self.sm_server.stop_server()
        self.db.delete_db_file()
