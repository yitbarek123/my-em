import sys
import time
import logging
import os
import pickle
import argparse
import traceback

from LatLon23 import LatLon, Latitude, Longitude

import grpc
from grpc_health.v1 import health_pb2 as heartb_pb2
from grpc_health.v1 import health_pb2_grpc as heartb_pb2_grpc
from concurrent import futures

from restaurant_info_crawler import (MockUpRestaurantFinder,
                                     GoogleRestaurantFinder)

from restaurant_info_to_scm import (name_to_scm, address_to_scm,
                                    geolocation_to_scm,
                                    opening_hours_to_scm,
                                    rating_to_scm,
                                    price_range_to_scm,
                                    cuisine_to_scm,
                                    review_to_scm)

ris_root_dir = os.path.abspath(os.path.join(os.path.dirname(__file__)))
sys.path.insert(0, "{}/api/".format(ris_root_dir))

import api.restaurant_info_pb2_grpc as rest_pb2_grpc
import api.restaurant_info_pb2 as rest_pb2

logging.basicConfig(format="%(asctime)s - [%(levelname)8s] "
                           "- %(name)s - %(message)s", level=logging.INFO)
log = logging.getLogger("restaurant_info_server")

_ONE_DAY_IN_SECONDS = 60 * 60 * 24
GOOGLE_PLACES_API_KEY = ''


class HealthServicer(heartb_pb2_grpc.HealthServicer):
    def Check(self, request, context):
        # UNKNOWN = 0;
        # SERVING = 1;
        # NOT_SERVING = 2;
        response = heartb_pb2.HealthCheckResponse()
        response.status = heartb_pb2.HealthCheckResponse.SERVING
        return response


class RestaurantInfoServicer(rest_pb2_grpc.RestaurantInfoServicer):
    def __init__(self):
        self.restaurants = []
        # XXX as our restaurant grows loading the world restaurant db might
        # not be appropriate. We may need a proper embedded db like sqlite.
        with open("world_restaurant_db.pkl", "rb") as db_file:
            try:
                self.restaurants = pickle.load(db_file)
            except Exception as e:
                log.error(traceback.format_exc(e))
    
    def _update_db(self, restaurants):
        """
        Updates the cache and database.
        """
        for res in restaurants:
            self.restaurants.append(res)
        with open("world_restaurant_db.pkl", "wb") as db_file:
            pickle.dump(self.restaurants, db_file)

    def _get_nearby(self, latitude, longitude, radius):
        """
         Searches for nearby restaurants given a geolocation information.
         uses WGS84 distance measurement from the LatLon library.
        """
        current = LatLon(Latitude(latitude), Longitude(longitude))
        return filter(lambda rst: current.distance(LatLon(
            float(rst.geolocation[0]),
            float(rst.geolocation[1]))) <= radius, self.restaurants)

    @staticmethod
    def _prepare_response(restaurants):
        """
         Returns a protobuf object containing list of restaurants both
         in text and atomese representation of the attributes of
         the restaurant.
        """
        geo_out = rest_pb2.RestaurantInfosOutput()
        for r in restaurants:
            geo_out.restaurants.append(
                rest_pb2.RestaurantInfos(
                    name=rest_pb2.Info(
                        text=r.name,
                        scm=name_to_scm(r.name, r.uuid)),
                
                    address=rest_pb2.Info(
                        text=r.address,
                        scm=address_to_scm(r.address, r.uuid)),
                
                    telephone_number=rest_pb2.Info(
                        text=r.telephone_number,
                        scm=address_to_scm(r.telephone_number, r.uuid)),
                
                    websites=rest_pb2.Info(
                        text=r.website,
                        scm=address_to_scm(r.website, r.uuid)),
                
                    rating=rest_pb2.Info(
                        text=str(r.rating),
                        scm=rating_to_scm(r.rating, r.uuid)),
                
                    total_review=rest_pb2.Info(
                        text=str(r.total_review),
                        scm=rating_to_scm(r.total_review, r.uuid)),
                
                    geolocation=rest_pb2.Info(
                        text="{}, {}".format(r.geolocation[0],
                                             r.geolocation[1]),
                        scm=geolocation_to_scm(
                            r.geolocation[0],
                            r.geolocation[1],
                            r.uuid)) if r.geolocation else rest_pb2.Info(),
                
                    price_range=rest_pb2.Info(
                        text="{}, {}".format(r.price_range[0],
                                             r.price_range[1]),
                        scm=price_range_to_scm(
                            r.price_range[0],
                            r.price_range[1],
                            r.uuid)) if r.price_range else rest_pb2.Info(),
                
                    opening_hours=rest_pb2.Info(
                        text="{}, {}".format(r.open_hours[0], r.open_hours[1]),
                        scm=price_range_to_scm(
                            r.open_hours,
                            r.uuid)) if r.open_hours else rest_pb2.Info(),
                
                    cuisines=[rest_pb2.Info(
                        text=cuisine,
                        scm=cuisine_to_scm(cuisine, r.uuid))
                        for cuisine in r.cuisines if cuisine],
                
                    reviews=[rest_pb2.Info(
                        text=review,
                        scm=review_to_scm(review, r.uuid))
                        for review in r.reviews if review]
                )
            )
        return geo_out

    def GetInfo(self, request, context):
        """
         Returns a list of restaurants nearby a given geolocation and radius.
         It tries to find nearby places from a local database first and if
         it fails, connects to the web using services like google places.
        """
        result = []
        longitude = request.longitude
        latitude = request.latitude
        radius = request.radius
    
        if longitude and latitude and radius:
            result = self._get_nearby(latitude, longitude, radius / 1000)
            if not result:
                result = GoogleRestaurantFinder(
                    GOOGLE_PLACES_API_KEY).find_nearby(latitude,
                                                       longitude,
                                                       radius)
                self._update_db(result)

        # Testing purpose
        if radius < 0:
            result = self.restaurants

        return self._prepare_response(result)


class RestaurantInfoServer:
    def __init__(self, port=50001, timeout=30):
        self.port = port
        self.server = None
        self.timeout = timeout

    def start_server(self):
        self.server = grpc.server(futures.ThreadPoolExecutor(max_workers=20))
        heartb_pb2_grpc.add_HealthServicer_to_server(HealthServicer(),
                                                     self.server)
        rest_pb2_grpc.add_RestaurantInfoServicer_to_server(
            RestaurantInfoServicer(), self.server)
        self.server.add_insecure_port("[::]:{}".format(self.port))
        log.info("Restaurant Info server on port {}".format(self.port))
        self.server.start()

    def stop_server(self):
        self.server.stop(0)


def main():
    global GOOGLE_PLACES_API_KEY
    if "GOOGLE_PLACES_API_KEY" in os.environ:
        GOOGLE_PLACES_API_KEY = os.environ["GOOGLE_PLACES_API_KEY"]
    port = 50001
    timeout = 30
    
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", "-p", type=int, default=port,
                        help="The Restaurant Info server port.")
    parser.add_argument("--timeout", "-t", type=int,
                        default=timeout,
                        help="Timeout for Opencog server RPC")
    args = parser.parse_args()
    
    server = RestaurantInfoServer(port=args.port, timeout=args.timeout)
    server.start_server()
    
    try:
        while True:
            time.sleep(_ONE_DAY_IN_SECONDS)
    except KeyboardInterrupt:
        server.stop_server()


if __name__ == '__main__':
    main()
