class Restaurant:
    """
    Attributes of Restaurant:
       - Name
       - Cuisines
       - Street address
       - Geolocation
       - Overall rating
       - Price category ($, $$, $$$, etc)
       - Open hours
       - Sub-ratings (Food, Service, Value Atmosphere)
       - 3 last reviews
       - Number of reviews
       - Price range (local currency)
       - Position is site's users review rank
       - Telephone number
       - Site
    """
    
    def __init__(self, name, address):
        self.name = name
        self.uuid = ""
        self.address = address
        self.telephone_number = ""
        self.website = ""
        self.cuisines = []
        self.geolocation = []
        self.rating = 1
        self.price_category = []
        self.price_range = []
        self.open_hours = []
        self.subrating = []
        self.reviews = []
        self.total_review = 0

