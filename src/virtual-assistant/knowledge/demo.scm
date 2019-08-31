(define current-city (PhraseNode "London"))

(PersonNode "VA: person-1")
(PersonNode "VA: person-2")
(PersonNode "VA: person-3")
(PersonNode "VA: person-4")
(VirtualAssistantNode "VA: va-1")
(VirtualAssistantNode "VA: va-2")
(VirtualAssistantNode "VA: va-3")
(VirtualAssistantNode "VA: va-4")

(EvaluationLink (PredicateNode "VA: at-city") (ListLink (PersonNode "VA: person-1") current-city))

(EvaluationLink (PredicateNode "VA: this-va") (ListLink (VirtualAssistantNode "VA: va-1")))

(EvaluationLink (PredicateNode "VA: is-va-user") (ListLink (PersonNode "VA: person-1") (VirtualAssistantNode "VA: va-1")))
(EvaluationLink (PredicateNode "VA: is-va-user") (ListLink (PersonNode "VA: person-2") (VirtualAssistantNode "VA: va-2")))
(EvaluationLink (PredicateNode "VA: is-va-user") (ListLink (PersonNode "VA: person-3") (VirtualAssistantNode "VA: va-3")))
(EvaluationLink (PredicateNode "VA: is-va-user") (ListLink (PersonNode "VA: person-4") (VirtualAssistantNode "VA: va-4")))

(EvaluationLink (PredicateNode "VA: name") (ListLink (PersonNode "VA: person-1") (WordNode "Jo")))
(EvaluationLink (PredicateNode "VA: name") (ListLink (PersonNode "VA: person-2") (WordNode "Anna")))
(EvaluationLink (PredicateNode "VA: name") (ListLink (PersonNode "VA: person-3") (WordNode "Sam")))
(EvaluationLink (PredicateNode "VA: name") (ListLink (PersonNode "VA: person-4") (WordNode "Jenny")))
(EvaluationLink (PredicateNode "VA: name") (ListLink (VirtualAssistantNode "VA: va-1") (WordNode "Jiva")))
(EvaluationLink (PredicateNode "VA: name") (ListLink (VirtualAssistantNode "VA: va-2") (WordNode "Ava")))
(EvaluationLink (PredicateNode "VA: name") (ListLink (VirtualAssistantNode "VA: va-3") (WordNode "Silva")))
(EvaluationLink (PredicateNode "VA: name") (ListLink (VirtualAssistantNode "VA: va-4") (WordNode "Jeneva")))

(EvaluationLink (PredicateNode "VA: married") (ListLink (PersonNode "VA: person-1") (PersonNode "VA: person-2")))
(EvaluationLink (PredicateNode "VA: married") (ListLink (PersonNode "VA: person-3") (PersonNode "VA: person-4")))

(EvaluationLink (PredicateNode "VA: gender") (ListLink (PersonNode "VA: person-1") (ConceptNode "male")))
(EvaluationLink (PredicateNode "VA: gender") (ListLink (PersonNode "VA: person-2") (ConceptNode "female")))
(EvaluationLink (PredicateNode "VA: gender") (ListLink (PersonNode "VA: person-3") (ConceptNode "male")))
(EvaluationLink (PredicateNode "VA: gender") (ListLink (PersonNode "VA: person-4") (ConceptNode "female")))

(EvaluationLink (PredicateNode "VA: likes") (ListLink (PersonNode "VA: person-1") (WordNode "Italian")))
(EvaluationLink (PredicateNode "VA: likes") (ListLink (PersonNode "VA: person-2") (WordNode "Italian")))
(EvaluationLink (PredicateNode "VA: likes") (ListLink (PersonNode "VA: person-1") (WordNode "Thai")))
(EvaluationLink (PredicateNode "VA: likes") (ListLink (PersonNode "VA: person-2") (WordNode "Thai")))
(EvaluationLink (PredicateNode "VA: likes") (ListLink (PersonNode "VA: person-1") (WordNode "Indian")))
(EvaluationLink (PredicateNode "VA: likes") (ListLink (PersonNode "VA: person-2") (WordNode "Indian")))

(EvaluationLink (PredicateNode "VA: dislikes") (ListLink (PersonNode "VA: person-2") (WordNode "Chinese")))

; Places
(EvaluationLink (PredicateNode "IsA") (ListLink (WordNode "Embankment") (PhraseNode "a place name")))
(EvaluationLink (PredicateNode "IsA") (ListLink (WordNode "Strand") (PhraseNode "a place name")))

; Restaurants
(EvaluationLink (PredicateNode "VA: cuisine") (ListLink (RestaurantNode "VA: restaurant-indian-demo-1") (WordNode "Indian")))
(EvaluationLink (PredicateNode "VA: cuisine") (ListLink (RestaurantNode "VA: restaurant-indian-demo-2") (WordNode "Indian")))
(EvaluationLink (PredicateNode "VA: cuisine") (ListLink (RestaurantNode "VA: restaurant-thai-demo-1") (WordNode "Thai")))
(EvaluationLink (PredicateNode "VA: cuisine") (ListLink (RestaurantNode "VA: restaurant-thai-demo-2") (WordNode "Thai")))
(EvaluationLink (PredicateNode "VA: cuisine") (ListLink (RestaurantNode "VA: restaurant-thai-demo-3") (WordNode "Thai")))

(EvaluationLink (PredicateNode "VA: at-city") (ListLink (RestaurantNode "VA: restaurant-indian-demo-1") current-city))
(EvaluationLink (PredicateNode "VA: at-city") (ListLink (RestaurantNode "VA: restaurant-indian-demo-2") current-city))
(EvaluationLink (PredicateNode "VA: at-city") (ListLink (RestaurantNode "VA: restaurant-thai-demo-1") current-city))
(EvaluationLink (PredicateNode "VA: at-city") (ListLink (RestaurantNode "VA: restaurant-thai-demo-2") current-city))
(EvaluationLink (PredicateNode "VA: at-city") (ListLink (RestaurantNode "VA: restaurant-thai-demo-3") current-city))

(EvaluationLink (PredicateNode "VA: at-location") (ListLink (RestaurantNode "VA: restaurant-indian-demo-2") (WordNode "Embankment")))
(EvaluationLink (PredicateNode "VA: at-location") (ListLink (RestaurantNode "VA: restaurant-thai-demo-1") (WordNode "Embankment")))

(EvaluationLink (PredicateNode "VA: rank") (ListLink (RestaurantNode "VA: restaurant-indian-demo-1") (NumberNode "1")))
(EvaluationLink (PredicateNode "VA: rank") (ListLink (RestaurantNode "VA: restaurant-indian-demo-2") (NumberNode "2")))
(EvaluationLink (PredicateNode "VA: rank") (ListLink (RestaurantNode "VA: restaurant-thai-demo-1") (NumberNode "1")))
(EvaluationLink (PredicateNode "VA: rank") (ListLink (RestaurantNode "VA: restaurant-thai-demo-2") (NumberNode "2")))
(EvaluationLink (PredicateNode "VA: rank") (ListLink (RestaurantNode "VA: restaurant-thai-demo-3") (NumberNode "3")))

(EvaluationLink (PredicateNode "VA: subrating") (ListLink (RestaurantNode "VA: restaurant-indian-demo-1") (NumberNode "4")))
(EvaluationLink (PredicateNode "VA: subrating") (ListLink (RestaurantNode "VA: restaurant-indian-demo-2") (NumberNode "4")))
(EvaluationLink (PredicateNode "VA: subrating") (ListLink (RestaurantNode "VA: restaurant-thai-demo-1") (NumberNode "4")))
(EvaluationLink (PredicateNode "VA: subrating") (ListLink (RestaurantNode "VA: restaurant-thai-demo-2") (NumberNode "4")))
(EvaluationLink (PredicateNode "VA: subrating") (ListLink (RestaurantNode "VA: restaurant-thai-demo-3") (NumberNode "4")))

(EvaluationLink (PredicateNode "VA: review") (ListLink (RestaurantNode "VA: restaurant-indian-demo-1") (PhraseNode "Overall the food was very good and the owners friendly")))
(EvaluationLink (PredicateNode "VA: review") (ListLink (RestaurantNode "VA: restaurant-indian-demo-2") (PhraseNode "A true beauty")))
(EvaluationLink (PredicateNode "VA: review") (ListLink (RestaurantNode "VA: restaurant-thai-demo-1") (PhraseNode "Trendy, cheap, good service")))
(EvaluationLink (PredicateNode "VA: review") (ListLink (RestaurantNode "VA: restaurant-thai-demo-2") (PhraseNode "This is a fantastic Thai restaurant")))
(EvaluationLink (PredicateNode "VA: review") (ListLink (RestaurantNode "VA: restaurant-thai-demo-3") (PhraseNode "Small and cozy")))

(EvaluationLink (PredicateNode "VA: name") (ListLink (RestaurantNode "VA: restaurant-indian-demo-1") (PhraseNode "The Raj")))
(EvaluationLink (PredicateNode "VA: name") (ListLink (RestaurantNode "VA: restaurant-indian-demo-2") (PhraseNode "Tandoor Chop House")))
(EvaluationLink (PredicateNode "VA: name") (ListLink (RestaurantNode "VA: restaurant-thai-demo-1") (PhraseNode "Thai Pot")))
(EvaluationLink (PredicateNode "VA: name") (ListLink (RestaurantNode "VA: restaurant-thai-demo-2") (PhraseNode "Bangkok Palace")))
(EvaluationLink (PredicateNode "VA: name") (ListLink (RestaurantNode "VA: restaurant-thai-demo-3") (PhraseNode "Simply Thai")))

(EvaluationLink (PredicateNode "VA: name-in-words") (ListLink (PhraseNode "The Raj") (ListLink (WordNode "The") (WordNode "Raj"))))
(EvaluationLink (PredicateNode "VA: name-in-words") (ListLink (PhraseNode "Tandoor Chop House") (ListLink (WordNode "Tandoor") (WordNode "Chop") (WordNode "House"))))
(EvaluationLink (PredicateNode "VA: name-in-words") (ListLink (PhraseNode "Thai Pot") (ListLink (WordNode "Thai") (WordNode "Pot"))))
(EvaluationLink (PredicateNode "VA: name-in-words") (ListLink (PhraseNode "Bangkok Palace") (ListLink (WordNode "Bangkok") (WordNode "Palace"))))
(EvaluationLink (PredicateNode "VA: name-in-words") (ListLink (PhraseNode "Simply Thai") (ListLink (WordNode "Simply") (WordNode "Thai"))))

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
