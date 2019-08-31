import abc
from urllib.request import urlopen
import json

from restaurant import Restaurant

# https://maps.googleapis.com/maps/api/place/
# nearbysearch/json?location=-33.8670522,#151.1957362&
# radius=1500&
# type=restaurant&
# keyword=cruise&
# key=YOUR_API_KEY


class RestaurantFinder:
    @abc.abstractmethod
    def find_by_city(self, city):
        """
            Returns a list of restaurants found in a city.
        """
        return

    @abc.abstractmethod
    def find_nearby(self, latitude, longitude, radius):
        """
            Returns a list of nearby restaurants at a radius r.
        """
        return


class GoogleRestaurantFinder(RestaurantFinder):
    def __init__(self, key):
        self.__API_KEY = key
        self.__base_url = "https://maps.googleapis.com/maps/api/place/"

    def __build_nearby_search_url(self, latitude, longitude, radius):
        return "{}nearbysearch/json?location={},{}&" \
               "radius={}&type=restaurant&key=".format(self.__base_url,
                                                       latitude,
                                                       longitude,
                                                       radius,
                                                       self.__API_KEY)

    def __build_place_detail_search_url(self, place_id):
        return "{}details/json?placeid={}&key={}".format(self.__base_url,
                                                         place_id,
                                                         self.__API_KEY)

    def __get_place_detail(self, place_id):
        url = self.__build_place_detail_search_url(place_id)
        print("DETAIL_REQUEST: ")
        print(url)
        response = urlopen(url)
        return json.loads(response.read().decode("utf-8"))

    def __extract_restaurants_from_json(self, _json):
        """
            Returns list of Restaurant Object by extracting information
            from the given google nearby API request json response.
        """
        restaurants = []
        for obj in _json["results"]:
            details = self.__get_place_detail(obj["place_id"])["result"]

            rest = Restaurant(obj["name"], details["formatted_address"])
            rest.uuid = obj["place_id"]
            loc = details["geometry"]["location"]
            rest.geolocation = [loc["lat"], loc["lng"]]
            if "formatted_phone_number" in details:
                rest.telephone_number = details["formatted_phone_number"]
            if "website" in details:
                rest.website = details["website"]
            if "rating" in details:
                rest.rating = details["rating"]
            if "opening_hours" in details:
                pass  # TODO
            if "reviews" in details:
                for review in details["reviews"]:
                    rest.reviews.append(review["text"])

            restaurants.append(rest)

        return restaurants

    def find_by_city(self, city):
        pass

    def find_nearby(self, latitude, longitude, radius):
        url = self.__build_nearby_search_url(latitude, longitude, radius)
        print("REQUEST: ")
        print(url)
        response = urlopen(url)
        json_resp = json.loads(response.read().decode("utf-8"))
        return self.__extract_restaurants_from_json(json_resp)


class MockUpRestaurantFinder(RestaurantFinder):
    """
        MockUp test implementation of RestaurantFinder for test purpose.
        Returns dummy list of Restaurants for test purpose.
    """
    @staticmethod
    def __create_dummy_restaurant_list():
        restaurant = Restaurant("Taytu", "Piassa, Addis Ababa")
        restaurant.telephone_number = "+25191234556"
        restaurant.uuid = "Taytu@12345"
        restaurant.cuisines = ["Shiro", "Key wot", "Beef stew", "Enjera"]
        restaurant.geolocation = ["8.989557","38.7943925"]
        restaurant.website = "unknown"
        restaurant.rating = 4
        restaurant.total_review = 100
        restaurant.open_hours = ["10:00", "22:00"]
        restaurant.price_range = ["10", "50"]
        restaurant.reviews = [
            "The best traditional restaurant in town",
            "old architecture filled with traditional utensils and furniture",
            "Great experience."]
        return [restaurant]

    def find_by_city(self, city):
        return self.__create_dummy_restaurant_list()

    def find_nearby(self, latitude, longitude, radius):
        """
            Returns dummy list of Restaurant for test purpose.
        """
        return self.__create_dummy_restaurant_list()


