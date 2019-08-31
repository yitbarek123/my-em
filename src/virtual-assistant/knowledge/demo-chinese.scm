(define current-city (PhraseNode "Beijing"))

(PersonNode "VA: person-1")
(PersonNode "VA: person-2")
(VirtualAssistantNode "VA: va-1")
(VirtualAssistantNode "VA: va-2")

(EvaluationLink (PredicateNode "VA: at-city") (ListLink (PersonNode "VA: person-1") current-city))

(EvaluationLink (PredicateNode "VA: this-va") (ListLink (VirtualAssistantNode "VA: va-1")))

(EvaluationLink (PredicateNode "VA: is-va-user") (ListLink (PersonNode "VA: person-1") (VirtualAssistantNode "VA: va-1")))
(EvaluationLink (PredicateNode "VA: is-va-user") (ListLink (PersonNode "VA: person-2") (VirtualAssistantNode "VA: va-2")))

(EvaluationLink (PredicateNode "VA: name") (ListLink (PersonNode "VA: person-1") (WordNode "Jo")))
(EvaluationLink (PredicateNode "VA: name") (ListLink (PersonNode "VA: person-2") (WordNode "Anna")))
(EvaluationLink (PredicateNode "VA: name") (ListLink (VirtualAssistantNode "VA: va-1") (WordNode "Jiva")))
(EvaluationLink (PredicateNode "VA: name") (ListLink (VirtualAssistantNode "VA: va-2") (WordNode "Ava")))

(EvaluationLink (PredicateNode "VA: married") (ListLink (PersonNode "VA: person-1") (PersonNode "VA: person-2")))

(EvaluationLink (PredicateNode "VA: gender") (ListLink (PersonNode "VA: person-1") (ConceptNode "male")))
(EvaluationLink (PredicateNode "VA: gender") (ListLink (PersonNode "VA: person-2") (ConceptNode "female")))

(EvaluationLink (PredicateNode "VA: likes") (ListLink (PersonNode "VA: person-1") (WordNode "Italian")))
(EvaluationLink (PredicateNode "VA: likes") (ListLink (PersonNode "VA: person-2") (WordNode "Italian")))
(EvaluationLink (PredicateNode "VA: likes") (ListLink (PersonNode "VA: person-1") (WordNode "Thai")))
(EvaluationLink (PredicateNode "VA: likes") (ListLink (PersonNode "VA: person-2") (WordNode "Thai")))
(EvaluationLink (PredicateNode "VA: likes") (ListLink (PersonNode "VA: person-1") (WordNode "Indian")))
(EvaluationLink (PredicateNode "VA: likes") (ListLink (PersonNode "VA: person-2") (WordNode "Indian")))

; Places
(EvaluationLink (PredicateNode "IsA") (ListLink (WordNode "Wangfujing") (PhraseNode "a place name")))

; Restaurants
(EvaluationLink (PredicateNode "VA: cuisine") (ListLink (RestaurantNode "VA: restaurant-indian-demo-1") (WordNode "Indian")))
(EvaluationLink (PredicateNode "VA: cuisine") (ListLink (RestaurantNode "VA: restaurant-indian-demo-2") (WordNode "Indian")))
(EvaluationLink (PredicateNode "VA: cuisine") (ListLink (RestaurantNode "VA: restaurant-thai-demo-1") (WordNode "Thai")))
(EvaluationLink (PredicateNode "VA: cuisine") (ListLink (RestaurantNode "VA: restaurant-thai-demo-2") (WordNode "Thai")))

(EvaluationLink (PredicateNode "VA: at-city") (ListLink (RestaurantNode "VA: restaurant-indian-demo-1") current-city))
(EvaluationLink (PredicateNode "VA: at-city") (ListLink (RestaurantNode "VA: restaurant-thai-demo-1") current-city))

(EvaluationLink (PredicateNode "VA: at-location") (ListLink (RestaurantNode "VA: restaurant-indian-demo-2") (WordNode "Wangfujing")))
(EvaluationLink (PredicateNode "VA: at-location") (ListLink (RestaurantNode "VA: restaurant-thai-demo-2") (WordNode "Wangfujing")))

(EvaluationLink (PredicateNode "VA: rank") (ListLink (RestaurantNode "VA: restaurant-indian-demo-1") (NumberNode "1")))
(EvaluationLink (PredicateNode "VA: rank") (ListLink (RestaurantNode "VA: restaurant-indian-demo-2") (NumberNode "2")))
(EvaluationLink (PredicateNode "VA: rank") (ListLink (RestaurantNode "VA: restaurant-thai-demo-1") (NumberNode "1")))
(EvaluationLink (PredicateNode "VA: rank") (ListLink (RestaurantNode "VA: restaurant-thai-demo-2") (NumberNode "2")))

(EvaluationLink (PredicateNode "VA: subrating") (ListLink (RestaurantNode "VA: restaurant-indian-demo-1") (NumberNode "4")))
(EvaluationLink (PredicateNode "VA: subrating") (ListLink (RestaurantNode "VA: restaurant-indian-demo-2") (NumberNode "4")))
(EvaluationLink (PredicateNode "VA: subrating") (ListLink (RestaurantNode "VA: restaurant-thai-demo-1") (NumberNode "4")))
(EvaluationLink (PredicateNode "VA: subrating") (ListLink (RestaurantNode "VA: restaurant-thai-demo-2") (NumberNode "4")))

(EvaluationLink (PredicateNode "VA: review")
  (ListLink (RestaurantNode "VA: restaurant-indian-demo-1")
    (PhraseNode "Good atmosphere, good service and authentic Indian food. Table service was excellent.")))
(EvaluationLink (PredicateNode "VA: review")
  (ListLink (RestaurantNode "VA: restaurant-indian-demo-2")
    (PhraseNode "Great Indian food in Beijing! The decor of the restaurant is quite good and the staffs at the restaurant was especially very cordial.")))
(EvaluationLink (PredicateNode "VA: review")
  (ListLink (RestaurantNode "VA: restaurant-thai-demo-1")
    (PhraseNode "Good location, friendly service, fast, excellent Thai food, good value for money and very friendly boss.")))
(EvaluationLink (PredicateNode "VA: review")
  (ListLink (RestaurantNode "VA: restaurant-thai-demo-2")
    (PhraseNode "Food is always great, and if you like it more (or less) spicy, just ask - they are happy to accommodate you.")))

(EvaluationLink (PredicateNode "VA: name-chinese") (ListLink (RestaurantNode "VA: restaurant-indian-demo-1") (PhraseNode "恒河印度餐厅")))
(EvaluationLink (PredicateNode "VA: name-chinese") (ListLink (RestaurantNode "VA: restaurant-indian-demo-2") (PhraseNode "拉兹印度餐厅")))
(EvaluationLink (PredicateNode "VA: name-chinese") (ListLink (RestaurantNode "VA: restaurant-thai-demo-1") (PhraseNode "青柠泰餐厅")))
(EvaluationLink (PredicateNode "VA: name-chinese") (ListLink (RestaurantNode "VA: restaurant-thai-demo-2") (PhraseNode "泰辣椒")))

(EvaluationLink (PredicateNode "VA: name") (ListLink (RestaurantNode "VA: restaurant-indian-demo-1") (PhraseNode "Ganges Indian Restaurant")))
(EvaluationLink (PredicateNode "VA: name") (ListLink (RestaurantNode "VA: restaurant-indian-demo-2") (PhraseNode "Raz Indian Restaurant")))
(EvaluationLink (PredicateNode "VA: name") (ListLink (RestaurantNode "VA: restaurant-thai-demo-1") (PhraseNode "Lime Thai Restaurant")))
(EvaluationLink (PredicateNode "VA: name") (ListLink (RestaurantNode "VA: restaurant-thai-demo-2") (PhraseNode "Thai Chili")))

(EvaluationLink (PredicateNode "VA: name-in-words") (ListLink (PhraseNode "Ganges Indian Restaurant") (ListLink (WordNode "Ganges") (WordNode "Indian") (WordNode "Restaurant"))))
(EvaluationLink (PredicateNode "VA: name-in-words") (ListLink (PhraseNode "Raz Indian Restaurant") (ListLink (WordNode "Raz") (WordNode "Indian") (WordNode "Restaurant"))))
(EvaluationLink (PredicateNode "VA: name-in-words") (ListLink (PhraseNode "Lime Thai Restaurant") (ListLink (WordNode "Lime") (WordNode "Thai") (WordNode "Restaurant"))))
(EvaluationLink (PredicateNode "VA: name-in-words") (ListLink (PhraseNode "Thai Chili") (ListLink (WordNode "Thai") (WordNode "Chili"))))

; From ConceptNet
(EvaluationLink (PredicateNode "IsA") (ListLink (WordNode "am") (PhraseNode "time of day")))
(EvaluationLink (PredicateNode "IsA") (ListLink (WordNode "pm") (PhraseNode "time of day")))
(EvaluationLink (PredicateNode "IsA") (ListLink (WordNode "morning") (PhraseNode "time of day")))
(EvaluationLink (PredicateNode "IsA") (ListLink (WordNode "afternoon") (PhraseNode "time of day")))
(EvaluationLink (PredicateNode "IsA") (ListLink (WordNode "evening") (PhraseNode "time of day")))
(EvaluationLink (PredicateNode "IsA") (ListLink (WordNode "monday") (WordNode "day")))
(EvaluationLink (PredicateNode "IsA") (ListLink (WordNode "tuesday") (WordNode "day")))
(EvaluationLink (PredicateNode "IsA") (ListLink (WordNode "wednesday") (WordNode "day")))
(EvaluationLink (PredicateNode "IsA") (ListLink (WordNode "thursday") (WordNode "day")))
(EvaluationLink (PredicateNode "IsA") (ListLink (WordNode "friday") (WordNode "day")))
(EvaluationLink (PredicateNode "IsA") (ListLink (WordNode "saturaday") (WordNode "day")))
(EvaluationLink (PredicateNode "IsA") (ListLink (WordNode "sunday") (WordNode "day")))

(EvaluationLink (PredicateNode "RelatedTo") (ListLink (WordNode "breakfast") (WordNode "morning")))
(EvaluationLink (PredicateNode "RelatedTo") (ListLink (WordNode "lunch") (WordNode "afternoon")))
(EvaluationLink (PredicateNode "RelatedTo") (ListLink (WordNode "dinner") (WordNode "evening")))

(EvaluationLink (PredicateNode "IsA") (ListLink (WordNode "spaghetti") (WordNode "pasta")))
(EvaluationLink (PredicateNode "IsA") (ListLink (WordNode "pasta") (WordNode "food")))
(EvaluationLink (PredicateNode "AtLocation") (ListLink (WordNode "pasta") (PhraseNode "an Italian restaurant")))
