import unittest
import hashlib
import random
import string

from db import Credential, Service, Device
from db.interface import Database


def generate_access_token(length=15):
    key = "".join(random.choice(string.ascii_letters + string.digits)
                  for _ in range(length))
    return key.upper()


def hash_password(password):
    m = hashlib.sha256()
    m.update(password.encode("utf-8"))
    return m.hexdigest()


class TestSessionManager(unittest.TestCase):
    def setUp(self):
        self.db = Database(db_file="test_sessions.db", db_create=True)

    def test_add_update(self):
        self.db.add(Credential,
                    username="username_1",
                    password=hash_password("password_1"))

        self.db.add(Device,
                    device_name="Android",
                    access_token=generate_access_token(),
                    username="username_1")

        self.db.add(Device,
                    device_name="MyPC",
                    access_token=generate_access_token(),
                    username="username_1")

        self.db.add(Service,
                    service_name="TESTING_SERVICE",
                    service_host="localhost",
                    service_port=50001)

        # Adding same service again, should fail!
        self.db.add(Service,
                    service_name="TESTING_SERVICE",
                    service_host="localhost",
                    service_port=50011)

        self.db.add(Service,
                    service_name="TESTING_SERVICE_2",
                    service_host="localhost",
                    service_port=50002)

        user_1 = self.db.query(Credential)
        self.assertIsNotNone(user_1, "Credential not found!")
        self.assertEqual(user_1.username, "username_1")
        self.assertEqual(user_1.password, hash_password("password_1"))
        self.assertEqual(len(user_1.devices), 2)

        devices = self.db.query_all(Device, username="username_1")
        self.assertIsNotNone(devices, "Devices not found!")
        self.assertEqual(len(devices), 2)
        self.assertEqual(devices[0].username, "username_1")
        self.assertEqual(devices[1].username, "username_1")

        service = self.db.query(Service, service_name="TESTING_SERVICE")
        self.assertIsNotNone(service, "Service not found!")
        self.assertEqual(service.service_name, "TESTING_SERVICE")
        self.assertEqual(service.service_host, "localhost")
        self.assertEqual(service.service_port, 50001)

        service = self.db.query(Service, service_name="TESTING_SERVICE_2")
        self.assertIsNotNone(service, "Service not found!")
        self.assertEqual(service.service_name, "TESTING_SERVICE_2")
        self.assertEqual(service.service_host, "localhost")
        self.assertEqual(service.service_port, 50002)

        self.db.delete(Service, service_name="TESTING_SERVICE_2")
        service = self.db.query(Service, service_name="TESTING_SERVICE_2")
        self.assertIsNone(service, "Service still registered!")

        ok = self.db.update(Service,
                            where={"service_name": "TESTING_SERVICE_2"},
                            update={"service_port": 50022})
        self.assertEqual(ok, False, "Deleted service was updated!")

        ok = self.db.update(Service,
                            where={"service_name": "TESTING_SERVICE"},
                            update={"service_port": 50011})
        self.assertEqual(ok, True, "Service wasn't updated!")

        ok = self.db.update(Credential,
                            where={"username": "username_1"},
                            update={"active_device": "Android"})
        self.assertIs(ok, True, "Credential update failed.")

        self.assertEqual(user_1.active_device,
                         "Android", "Error active_device!")

        self.db.print_table(Credential)
        self.db.print_table(Service)

    def tearDown(self):
        self.db.delete_db_file()
