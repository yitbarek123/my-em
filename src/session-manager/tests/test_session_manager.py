import grpc
import unittest

from db import Credential, Service, Device
from db.interface import Database

from session_manager_server import (SessionManagerServer,
                                    hash_password,
                                    opcog_pb2,
                                    sm_pb2_grpc,
                                    sm_pb2)

from .services.named_entity_recognition import NamedEntityRecognitionServer
from .services.opencog_services import OpenCogServer
from .services.sentiment_analysis import SentimentAnalysisServer


class Status:
    OK = 0
    PERMISSION_DENIED = 1
    CANCELLED = 2
    UNKNOWN = 3


class TestSessionManager(unittest.TestCase):
    def setUp(self):
        self.db = Database(db_file="test_sessions.db", db_create=True)
        self.db.add(Credential,
                    username="username_test1",
                    password=hash_password("password_1"))

        self.db.add(Credential,
                    username="username_test2",
                    password=hash_password("password_2"))

        self.db.add(Service,
                    service_name="OPENCOG_SERVICES",
                    service_host="localhost",
                    service_port=50090)

        self.db.add(Service,
                    service_name="NAMED_ENTITY_RECOGNITION",
                    service_host="localhost",
                    service_port=50021)

        self.db.add(Service,
                    service_name="SENTIMENT_ANALYSIS",
                    service_host="localhost",
                    service_port=50022)

        self.session_manager_server = SessionManagerServer(
            db_file="test_sessions.db",
            db_create=False,
            port=50000)
        self.session_manager_server.start_server()

        self.opencog_services = OpenCogServer(port=50090)
        self.opencog_services.start_server()

        self.named_entity_server = NamedEntityRecognitionServer(port=50021)
        self.named_entity_server.start_server()

        self.sentiment_analysis_server = SentimentAnalysisServer(port=50022)
        self.sentiment_analysis_server.start_server()

    def test_grpc_calls(self):
        va_user = "username_test1"
        va_password = "password_1"
        va_device_1 = "Android"
        va_device_2 = "MyPC"

        with grpc.insecure_channel("localhost:{}".format(50000)) as channel:
            stub = sm_pb2_grpc.SessionManagerStub(channel)
            
            # First login (device_1) creates an entry with an access_token
            device_1 = self.login(stub, va_user, va_password, va_device_1)

            # Logout to check if the access_token will be reset
            r, _ = stub.Logout.with_call(
                sm_pb2.LogoutInput(device_name=va_device_1),
                metadata=(("access_token", device_1.access_token),))
            self.assertEqual(r.status, Status.OK)

            self.db.refresh(device_1)
            self.assertEqual(device_1.access_token, "", "Token not reset!")

            # First login (device_2) creates an entry with an access_token
            device_2 = self.login(stub, va_user, va_password, va_device_2)

            self.db.refresh(device_2)
            self.assertNotEqual(device_2.access_token, "", "Empty token!")

            # Re-Login (device_1) to check if a new access_token will be set
            device_1 = self.login(stub, va_user, va_password, va_device_1)

            self.db.refresh(device_1)
            self.assertNotEqual(device_1.access_token, "", "Empty token!")

            # Checking if the active_device is still ""
            cred = self.db.query(Credential,
                                 username=va_user,
                                 password=hash_password(va_password))
            self.db.refresh(cred)
            self.assertEqual(cred.active_device, "", "Device is active!")

            # [device_1] sends an Utterance without being the active_device
            self.utterance(stub, device_1)
            self.db.refresh(device_1)

            # Now [device_1] must be the active_device
            self.db.refresh(cred)
            self.assertEqual(cred.active_device,
                             device_1.device_name,
                             "Device is not active!")

            # [device_2] sends an Utterance without being the active_device
            self.utterance(stub, device_2, will_fail=True)

            # The active_device must still be [device_1]
            self.db.refresh(cred)
            self.assertEqual(cred.active_device,
                             device_1.device_name,
                             "Device is not active!")

            r, _ = stub.Prompt.with_call(
                opcog_pb2.Command(service="VA", cmd="prompt"),
                metadata=(("access_token", device_1.access_token),))
            self.assertEqual(r.output, "Prompt", "Error at Prompt!")

            r, _ = stub.Geolocation.with_call(
                sm_pb2.GeolocationInput(longitude=10, latitude=10),
                metadata=(("access_token", device_1.access_token),))
            self.assertEqual(r.status, Status.OK, "Error at Geolocation!")

            # Reset will set active_device to ""
            r, _ = stub.Reset.with_call(
                opcog_pb2.Command(service="VA", cmd="reset"),
                metadata=(("access_token", device_1.access_token),))
            self.assertEqual(r.output, "Reset", "Error at Reset!")

            self.db.refresh(cred)
            self.assertEqual(cred.active_device, "", "Device is active!")

            # Sending an Utterance without being the active_device again
            self.utterance(stub, device_1)
            self.db.refresh(device_1)

            # Again [device_1] must be the active_device
            self.db.refresh(cred)
            self.assertEqual(cred.active_device,
                             device_1.device_name,
                             "Device is not active!")
            
            # [device_1] logging out, its access_token now must be ""
            self.logout(stub, device_1)

            self.db.refresh(device_1)
            self.assertEqual(device_1.access_token, "", "Token not reset!")

            # No device must be active now
            self.db.refresh(cred)
            self.assertEqual(cred.active_device, "", "Device is not active!")

            # [device_1] sends an Utterance with access_token == ""
            self.utterance(stub, device_1)

            # [device_2] sends an Utterance without being the active_device
            self.utterance(stub, device_2)

            # Now [device_2] must be the active_device
            self.db.refresh(cred)
            self.assertEqual(cred.active_device,
                             device_2.device_name,
                             "Device is not active!")

            # [device_2] logging out, its access_token now must be ""
            self.logout(stub, device_2)

            self.db.refresh(device_2)
            self.assertEqual(device_2.access_token, "", "Token not reset!")
    
    def login(self, stub, username, password, device_name):
        r = stub.Login(sm_pb2.LoginInput(username=username,
                                         password=password,
                                         device_name=device_name))
        self.assertEqual(r.status, Status.OK)
    
        device = self.db.query(Device,
                               username=username,
                               device_name=device_name)
        self.assertIsNotNone(device, "Device not found!")
    
        self.db.refresh(device)
        self.assertNotEqual(device.access_token, "", "Empty token!")
        return device
    
    def logout(self, stub, device):
        r, _ = stub.Logout.with_call(
            sm_pb2.LogoutInput(device_name=device.device_name),
            metadata=(("access_token", device.access_token),))
        self.assertEqual(r.status, Status.OK)
    
    def utterance(self, stub, device, will_fail=False):
        try:
            r, _ = stub.Utterance.with_call(
                sm_pb2.UtteranceInput(utterance="Hello from unittest."),
                metadata=(("access_token", device.access_token),))
            if will_fail:
                self.assertEqual(r.utterance, "", "Error at Utterance!")
            else:
                self.assertEqual(r.utterance,
                                 "Utterance",
                                 "Error at Utterance!")
        except Exception as e:
            print(e)

    def tearDown(self):
        self.sentiment_analysis_server.stop_server()
        self.named_entity_server.stop_server()
        self.opencog_services.stop_server()
        self.session_manager_server.stop_server()
        self.db.delete_db_file()
