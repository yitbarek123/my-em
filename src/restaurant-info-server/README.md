

## System Overview
Restaurant information server is a RESTful service providing list of restaurants
and details in a given geolcation area.

The server maintains a local cache of restaurants for look up whenever a requests
is processed and also serializes it to a file to reload the cache in case of system
restart. If there is no record in the cache for the given geolocation in
the request, it will call external services to fetch result and update the database
for future requests.

We have done a bit of research on available external restaurant information database services. According to our requirement documentation, we want the following information of a restaurant from the external service to be used:
 -  name, address, telephone_number, cuisines, rating, reviews, reviewers ranking, geolcation, opening hours and price ranges


 The following are the list of restaurant information services that we have tried to investigate:

**[Blodata](https://bolddata.nl/en/)** - Contains database of restaurant in Europe. They don't have free samples
to check right away. I have made a sample request to check their database out. I will have my verdict on the quality of
their data with regards to our requirement once I get access.

**[thewebminer](https://thewebminer.com/geo)** - They have online demo where one could search for restaurant by specifying country and city. Their database is only of three countries(US, Canada and UK) which seems to not fit
our requirement and most importantly, the list of information they provide is very basic consisting of name,address,
website and phone number.

**[oddity](http://www.odditysoftware.com/page-datasales793.htm)** - They don't provide API but a downloadable csv containing basic restaurant information like thewebminer. The database contains only US restaurants.

**[opentable](https://dev.opentable.com/)** - They API seems to contain most of the information we want about a restaurant and they have a database of 15 countries. I wasn't able to make sure that they have the cuisines information as well. I am suspecting the category field might be holding the list of cuisines. Another information that might be interesting in their API is the price quartile information. Unfortunately, their API is not accessible unless one fills out their online partnership application form; which I did only to find out that it takes 3-4 weeks to get an approval.

**[foursquare](https://developer.foursquare.com/docs/api/venues/details)** - I haven't fully conluded whether they provide restaurant related information as well or not. They don't have an explicity support for searching restaurants but I'm guessing their concept of venue also includes restaurants. From their [search](https://developer.foursquare.com/docs/api/venues/search) API, I can see that one could search for a venue based on geolcation and a 'query' parameter which we could use by putting restaurant/food related phrases. I wanted to test this but their free sample requires a credit card to be registered. Needs further investigation.

**[Google places API](https://developers.google.com/places/web-service/search)** - It meets all our requirement except
for the cuisines information. I suppose the cuisines could be extracted from user reviews but it will not be an easy job plus we can only retrieve cusines mentioned by reviewers. Aside from the lack of explicit information about cuisines, the places API seems the most complete database containing restaurants all around the world with the rest of the information we want.


Based on the above findings, we have chosen the [google places](https://developers.google.com/places/web-service/search)
for our current milestone since it has the most complete geolocational database of places and their
details with an easy to use API for thirdparty access. In addition to the lack of cuisine information, the other issue I encountered was, data fields are not consistent for all queries. some restaurant have complete information while others could be missing fields like website, price range etc.

The response data is a JSON format containing list of restaurants with the following
details:
- name
- address
- telephone_number
- website
- rating
- review
- geolocation
- opening hours
- price range

Each of the above information are encoded both in text and atomese format.
The text information is keyed with 'text' where as the atomese represenation is
keyed with 'scm'. See [currently supported endpoints](#currently-supported-endpoints).

### Furture work

- Choose multiple restaurant information provider services to complement missing information
- Use appropriate GIS database - This will be ultimately necessary as the number of
request types increase and database gets larger.

## How to run

### Without docker:

1. Install dependencies

```
  sudo pip install flask flask_restful LatLon
```

2. set GOOGLE_PLACES_API_KEY environmental variable

```
  export GOOGLE_PLACES_API_KEY=<KEY>
```

3. run server.py

 ``` python server.py ```

### With docker:

```
docker build -t "rest_info_server" . --build-arg API_KEY=<KEY>
docker run -p 5000:5000 rest_info_server
 ```

### currently supported endpoints:

- Find by geolocatoin
   ```
   http://127.0.0.1:5000/restaurants/?longitude=7.68&latitude=36.85&radius=5000
  ```
  **NB**. *radius* is in meters

The JSON response for both of the above requests looks like the following:

```javascript
  {
  "restaurants": [
    {
      "name": {
        "text": "Burger Brown",
        "scm": "(EvaluationLink (PredicateNode \"name\") (ListLink   (ConceptNode \"restaurant-ChIJER0lvbsJ8BIRzaqrt33cuqg\")   (PhraseNode \"Burger Brown\")))"
      },
      "address": {
        "text": "Annaba, Algeria",
        "scm": "(EvaluationLink (PredicateNode \"address\") (ListLink   (ConceptNode \"restaurant-ChIJER0lvbsJ8BIRzaqrt33cuqg\")   (PhraseNode \"Annaba, Algeria\")))"
      },
      "telephone_number": {
        "text": "",
        "scm": "(EvaluationLink (PredicateNode \"address\") (ListLink   (ConceptNode \"restaurant-ChIJER0lvbsJ8BIRzaqrt33cuqg\")   (PhraseNode \"\")))"
      },
      "websites": {
        "text": "",
        "scm": "(EvaluationLink (PredicateNode \"address\") (ListLink   (ConceptNode \"restaurant-ChIJER0lvbsJ8BIRzaqrt33cuqg\")   (PhraseNode \"\")))"
      },
      "rating": {
        "text": "3.3",
        "scm": "(EvaluationLink   (PredicateNode \"subrating\")   (ListLink     (ConceptNode \"restaurant-ChIJER0lvbsJ8BIRzaqrt33cuqg\")     (NumberNode 3.3)))"
      },
      "total_review": {
        "text": "0",
        "scm": "(EvaluationLink   (PredicateNode \"subrating\")   (ListLink     (ConceptNode \"restaurant-ChIJER0lvbsJ8BIRzaqrt33cuqg\")     (NumberNode 0)))"
      },
      "geolocation": {
        "text": "36.8749248, 7.7136687",
        "scm": "(EvaluationLink   (PredicateNode \"geolocation\")   (ListLink     (ConceptNode \"restaurant-ChIJER0lvbsJ8BIRzaqrt33cuqg\")     (ListLink      (NumberNode 7.7136687)      (NumberNode 36.8749248))))"
      },
      "reviews": {
        "text": [
          "a good restaurant, and a suitable place to have good times with friends 👍",
          "Top",
          "Un super restaurant bien situé passer un bon moment entre amis",
          "",
          ""
        ],
        "scm": "(EvaluationLink   (PredicateNode \"reviews\")     (ListLink       (ConceptNode \"restaurant-ChIJER0lvbsJ8BIRzaqrt33cuqg\")       (ListLink (TextNode \"a good restaurant, and a suitable place to have good times with friends 👍\")(TextNode \"Top\")(TextNode \"Un super restaurant bien situé passer un bon moment entre amis\")(TextNode \"\")(TextNode \"\"))))"
      }
    },
    {
      "name": {
        "text": "Pizzeria",
        "scm": "(EvaluationLink (PredicateNode \"name\") (ListLink   (ConceptNode \"restaurant-ChIJeZu0nB4G8BIRJOm2t3ehQwA\")   (PhraseNode \"Pizzeria\")))"
      },
      "address": {
        "text": "Route de Sidi Achour, Annaba, Algeria",
        "scm": "(EvaluationLink (PredicateNode \"address\") (ListLink   (ConceptNode \"restaurant-ChIJeZu0nB4G8BIRJOm2t3ehQwA\")   (PhraseNode \"Route de Sidi Achour, Annaba, Algeria\")))"
      },
      "telephone_number": {
        "text": "0778 33 82 01",
        "scm": "(EvaluationLink (PredicateNode \"address\") (ListLink   (ConceptNode \"restaurant-ChIJeZu0nB4G8BIRJOm2t3ehQwA\")   (PhraseNode \"0778 33 82 01\")))"
      },
      "websites": {
        "text": "",
        "scm": "(EvaluationLink (PredicateNode \"address\") (ListLink   (ConceptNode \"restaurant-ChIJeZu0nB4G8BIRJOm2t3ehQwA\")   (PhraseNode \"\")))"
      },
      "rating": {
        "text": "3.7",
        "scm": "(EvaluationLink   (PredicateNode \"subrating\")   (ListLink     (ConceptNode \"restaurant-ChIJeZu0nB4G8BIRJOm2t3ehQwA\")     (NumberNode 3.7)))"
      },
      "total_review": {
        "text": "0",
        "scm": "(EvaluationLink   (PredicateNode \"subrating\")   (ListLink     (ConceptNode \"restaurant-ChIJeZu0nB4G8BIRJOm2t3ehQwA\")     (NumberNode 0)))"
      },
      "geolocation": {
        "text": "36.8784511, 7.7148044",
        "scm": "(EvaluationLink   (PredicateNode \"geolocation\")   (ListLink     (ConceptNode \"restaurant-ChIJeZu0nB4G8BIRJOm2t3ehQwA\")     (ListLink      (NumberNode 7.7148044)      (NumberNode 36.8784511))))"
      },
      "reviews": {
        "text": [
          "No",
          "Super pizza mais il y pas de la place pour s'asseoir",
          "بتزا روعة توکل یدیک اوراها",
          "لذيذة جدا",
          "J'ai trouvé la cible destination sans soucis"
        ],
        "scm": "(EvaluationLink   (PredicateNode \"reviews\")     (ListLink       (ConceptNode \"restaurant-ChIJeZu0nB4G8BIRJOm2t3ehQwA\")       (ListLink (TextNode \"No\")(TextNode \"Super pizza mais il y pas de la place pour s'asseoir\")(TextNode \"بتزا روعة توکل یدیک اوراها\")(TextNode \"لذيذة جدا\")(TextNode \"J'ai trouvé la cible destination sans soucis\"))))"
      }
    },
    {
      "name": {
        "text": "Danilo's Food",
        "scm": "(EvaluationLink (PredicateNode \"name\") (ListLink   (ConceptNode \"restaurant-ChIJP-X5BYAJ8BIRy9EB3MH63_8\")   (PhraseNode \"Danilo's Food\")))"
      },
      "address": {
        "text": "Sidi Amar, Algeria",
        "scm": "(EvaluationLink (PredicateNode \"address\") (ListLink   (ConceptNode \"restaurant-ChIJP-X5BYAJ8BIRy9EB3MH63_8\")   (PhraseNode \"Sidi Amar, Algeria\")))"
      },
      "telephone_number": {
        "text": "0697 24 98 36",
        "scm": "(EvaluationLink (PredicateNode \"address\") (ListLink   (ConceptNode \"restaurant-ChIJP-X5BYAJ8BIRy9EB3MH63_8\")   (PhraseNode \"0697 24 98 36\")))"
      },
      "websites": {
        "text": "",
        "scm": "(EvaluationLink (PredicateNode \"address\") (ListLink   (ConceptNode \"restaurant-ChIJP-X5BYAJ8BIRy9EB3MH63_8\")   (PhraseNode \"\")))"
      },
      "rating": {
        "text": "5",
        "scm": "(EvaluationLink   (PredicateNode \"subrating\")   (ListLink     (ConceptNode \"restaurant-ChIJP-X5BYAJ8BIRy9EB3MH63_8\")     (NumberNode 5)))"
      },
      "total_review": {
        "text": "0",
        "scm": "(EvaluationLink   (PredicateNode \"subrating\")   (ListLink     (ConceptNode \"restaurant-ChIJP-X5BYAJ8BIRy9EB3MH63_8\")     (NumberNode 0)))"
      },
      "geolocation": {
        "text": "36.8192115, 7.7124459",
        "scm": "(EvaluationLink   (PredicateNode \"geolocation\")   (ListLink     (ConceptNode \"restaurant-ChIJP-X5BYAJ8BIRy9EB3MH63_8\")     (ListLink      (NumberNode 7.7124459)      (NumberNode 36.8192115))))"
      },
      "reviews": {
        "text": [
          "Un vrai délice ❤👈"
        ],
        "scm": "(EvaluationLink   (PredicateNode \"reviews\")     (ListLink       (ConceptNode \"restaurant-ChIJP-X5BYAJ8BIRy9EB3MH63_8\")       (ListLink (TextNode \"Un vrai délice ❤👈\"))))"
      }
    },
    {
      "name": {
        "text": "The Mediterannean",
        "scm": "(EvaluationLink (PredicateNode \"name\") (ListLink   (ConceptNode \"restaurant-ChIJPfAt6a0J8BIR64jDbWILCek\")   (PhraseNode \"The Mediterannean\")))"
      },
      "address": {
        "text": "Unnamed Road, El Bouni, Algeria",
        "scm": "(EvaluationLink (PredicateNode \"address\") (ListLink   (ConceptNode \"restaurant-ChIJPfAt6a0J8BIR64jDbWILCek\")   (PhraseNode \"Unnamed Road, El Bouni, Algeria\")))"
      },
      "telephone_number": {
        "text": "",
        "scm": "(EvaluationLink (PredicateNode \"address\") (ListLink   (ConceptNode \"restaurant-ChIJPfAt6a0J8BIR64jDbWILCek\")   (PhraseNode \"\")))"
      },
      "websites": {
        "text": "https://www.facebook.com/The-Mediterranean-Fast-Food-Annaba-231606557609958/",
        "scm": "(EvaluationLink (PredicateNode \"address\") (ListLink   (ConceptNode \"restaurant-ChIJPfAt6a0J8BIR64jDbWILCek\")   (PhraseNode \"https://www.facebook.com/The-Mediterranean-Fast-Food-Annaba-231606557609958/\")))"
      },
      "rating": {
        "text": "4",
        "scm": "(EvaluationLink   (PredicateNode \"subrating\")   (ListLink     (ConceptNode \"restaurant-ChIJPfAt6a0J8BIR64jDbWILCek\")     (NumberNode 4)))"
      },
      "total_review": {
        "text": "0",
        "scm": "(EvaluationLink   (PredicateNode \"subrating\")   (ListLink     (ConceptNode \"restaurant-ChIJPfAt6a0J8BIR64jDbWILCek\")     (NumberNode 0)))"
      },
      "geolocation": {
        "text": "36.8637788, 7.7287714",
        "scm": "(EvaluationLink   (PredicateNode \"geolocation\")   (ListLink     (ConceptNode \"restaurant-ChIJPfAt6a0J8BIR64jDbWILCek\")     (ListLink      (NumberNode 7.7287714)      (NumberNode 36.8637788))))"
      },
      "reviews": {
        "text": [
          "",
          "",
          ""
        ],
        "scm": "(EvaluationLink   (PredicateNode \"reviews\")     (ListLink       (ConceptNode \"restaurant-ChIJPfAt6a0J8BIR64jDbWILCek\")       (ListLink (TextNode \"\")(TextNode \"\")(TextNode \"\"))))"
      }
    },
    {
      "name": {
        "text": "ALBA PIZZA",
        "scm": "(EvaluationLink (PredicateNode \"name\") (ListLink   (ConceptNode \"restaurant-ChIJ2yhnS0cH8BIRZAXl79Sv9Cc\")   (PhraseNode \"ALBA PIZZA\")))"
      },
      "address": {
        "text": "Annaba, Algeria",
        "scm": "(EvaluationLink (PredicateNode \"address\") (ListLink   (ConceptNode \"restaurant-ChIJ2yhnS0cH8BIRZAXl79Sv9Cc\")   (PhraseNode \"Annaba, Algeria\")))"
      },
      "telephone_number": {
        "text": "",
        "scm": "(EvaluationLink (PredicateNode \"address\") (ListLink   (ConceptNode \"restaurant-ChIJ2yhnS0cH8BIRZAXl79Sv9Cc\")   (PhraseNode \"\")))"
      },
      "websites": {
        "text": "",
        "scm": "(EvaluationLink (PredicateNode \"address\") (ListLink   (ConceptNode \"restaurant-ChIJ2yhnS0cH8BIRZAXl79Sv9Cc\")   (PhraseNode \"\")))"
      },
      "rating": {
        "text": "1",
        "scm": "(EvaluationLink   (PredicateNode \"subrating\")   (ListLink     (ConceptNode \"restaurant-ChIJ2yhnS0cH8BIRZAXl79Sv9Cc\")     (NumberNode 1)))"
      },
      "total_review": {
        "text": "0",
        "scm": "(EvaluationLink   (PredicateNode \"subrating\")   (ListLink     (ConceptNode \"restaurant-ChIJ2yhnS0cH8BIRZAXl79Sv9Cc\")     (NumberNode 0)))"
      },
      "geolocation": {
        "text": "36.8833043, 7.7153387",
        "scm": "(EvaluationLink   (PredicateNode \"geolocation\")   (ListLink     (ConceptNode \"restaurant-ChIJ2yhnS0cH8BIRZAXl79Sv9Cc\")     (ListLink      (NumberNode 7.7153387)      (NumberNode 36.8833043))))"
      }
    }
  ]
}
```
