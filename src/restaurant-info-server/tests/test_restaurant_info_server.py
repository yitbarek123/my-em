import unittest
import grpc

from restaurant_info_server import (RestaurantInfoServer,
                                    rest_pb2_grpc,
                                    rest_pb2)


class TestRestaurantInfo(unittest.TestCase):
    def setUp(self):
        self.server = RestaurantInfoServer(port=50001)
        self.server.start_server()

    def test_grpc_call(self):
        with grpc.insecure_channel("localhost:{}".format(50001)) as channel:
            stub = rest_pb2_grpc.RestaurantInfoStub(channel)
            r = stub.GetInfo(rest_pb2.GeolocationInput(longitude=10,
                                                       latitude=10,
                                                       radius=-1))
            self.assertEqual(len(r.restaurants), 5, "Error at GetInfo!")
            for i in r.restaurants:
                print(i.name.scm)
                print(i.address.scm)
                print(i.telephone_number.scm)
                print(i.websites.scm)
                print(i.geolocation.scm)
                print(i.price_range.scm)
                print(i.opening_hours.scm)
                for j in i.cuisines:
                    print(j.scm)
                for j in i.reviews:
                    print(j.scm)
