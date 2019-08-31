;--------------------------------------Recommendation 2----------------------------

(define-public (set_nearby_place place)
    (va-add-generic-fact-1 "user-mentioned-nearby-place" (WordNode place)) 
)

(define-public (get_vibe) "romantic")



(define-public (find_restaurant_2 nearby_place) (begin
    (let (
        (restaurants (va-get-restaurant-recommendation-2 nearby_place))
    ) (begin
        ; Delete previous recommendations
        (va-remove-generic-fact "restaurant recommendation_2")

        ; Generate the new recommendations
        (EvaluationLink
            (PredicateNode (va-prefix "restaurant recommendation_2"))
            (ListLink restaurants)
        )
    ))
))

; Select All Restaurant R where at-city(R,X) AND (at-city(P,X) where is-va-user(P)) AND  is-near(R,$nearby_place)
(define (va-get-restaurant-recommendation-2 nearby_place) (begin
    (let* (
        (query-link1 (EvaluationLink
                         (PredicateNode (va-prefix "user-mentioned-cuisine"))
                         (ListLink
                             (VariableNode "X")
                             va-positive
                         )
                     )
        )
        (query-link2 (EvaluationLink
                         (PredicateNode (va-prefix "user-mentioned-cuisine"))
                         (ListLink
                             (VariableNode "X")
                             va-negative
                         )
                     )
        )
        (positive-mentions (va-flat-node-list (cog-execute! (GetLink query-link1)) 'WordNode))
        (negative-mentions (va-flat-node-list (cog-execute! (GetLink query-link2)) 'WordNode))
        (inferred-cuisines (if (null? positive-mentions) (va-infer-cuisines) '()))
        (target-cuisines (if (null? positive-mentions)
                             (lset-difference equal? inferred-cuisines negative-mentions)
                             positive-mentions
                         )
        )
        (query-links (if (null? target-cuisines)
                         (list (AndLink
                                   (EvaluationLink
                                       (PredicateNode (va-prefix "at-city"))
                                       (ListLink
                                           (VariableNode "$R")
                                           (VariableNode "$Y")
                                       )
                                   )
                                   (EvaluationLink
                                      (PredicateNode (va-prefix "is-near"))
                                      (ListLink
                                          (VariableNode "$R")
                                          nearby_place
                                      )
                                   )
                                   (EvaluationLink
                                       (PredicateNode (va-prefix "at-city"))
                                       (ListLink
                                           (VariableNode "$P")
                                           (VariableNode "$Y")
                                       )
                                   )
                                   (EvaluationLink
                                       (PredicateNode (va-prefix "is-va-user"))
                                       (ListLink
                                           (VariableNode "$P")
                                       )
                                   )
                               )
                         )
                         (map (lambda (cuisine)
                             (AndLink
                                 (EvaluationLink
                                     (PredicateNode (va-prefix "at-city"))
                                     (ListLink
                                         (VariableNode "$R")
                                         (VariableNode "$Y")
                                     )
                                 )
                                 (EvaluationLink
                                     (PredicateNode (va-prefix "at-city"))
                                     (ListLink
                                         (VariableNode "$P")
                                         (VariableNode "$Y")
                                     )
                                 )
                                 (EvaluationLink
                                      (PredicateNode (va-prefix "is-va-user"))
                                      (ListLink
                                          (VariableNode "$P")
                                      )
                                 )
                                 (EvaluationLink
                                      (PredicateNode "VA: cuisine")
                                      (ListLink
                                          (VariableNode "$R")
                                          cuisine
                                      )
                                 )
                                 (EvaluationLink
                                      (PredicateNode (va-prefix "is-near"))
                                      (ListLink
                                          (VariableNode "$R")
                                          nearby_place
                                      )
                                 )
                             )
                         ) target-cuisines)
                    )
        )
        (candidates (va-flat-node-list (map (lambda (query) (cog-execute! (GetLink query))) query-links) 'RestaurantNode))
        (ranked-candidates (va-reversed-sort-weighted-pair (map (lambda (restaurant)
            (list (string->number (cog-name (car (va-flat-node-list (cog-execute! (GetLink
                (EvaluationLink
                    (PredicateNode (va-prefix "rank"))
                    (ListLink
                        restaurant
                        (VariableNode "$X")
                    )
                )
            )) 'NumberNode)))) restaurant)) candidates))
        )
        (small-list-candidates (map (lambda (pair) (cadr pair))
                                    (if (> (length ranked-candidates) 10)
                                        (list-head ranked-candidates 10)
                                        ranked-candidates
                                    )
                               )
        )
        (selected (va-random-select-up-to-n 3 small-list-candidates))
    ) (begin
        selected
    ))
))

;---Find nearby events
;-------For R E {Restaurants} Return Ev Where near_location_event(R,Ev) == True
(define (get-events-nearby restaurants)
  (if (null? restaurants) '()
      (let ((queries (map (lambda (restaurant) (
                                        (EvaluationLink
                                          (PredicateNode "near-location-event")
                                            (ListLink
                                              restaurant
                                              (VariableNode "$E"))))) 
                        restaurants)
                     ))
           (map (lambda (query) (cog-execute! (GetLink query))))
)))

;----Get weather Information near city
(define (get-temperature city)
  (let ((query
          (AtTimeLink
            (EvaluationLink
              (PredicateNode "temperature-at-cty")
              city
              (AssociativeLink
                (ConceptNode "degree-celsius")
                (VariableNode "$T")))
          (VariableNode "$S"))))
       (let* ((result (cog-execute! (GetLink query)))
              (temperature '())
              (timestamp '()))
             (begin
              (for-each (lambda (atom)
                                (set! temperature
                                      (append!
                                       (list (car (cog-outgoing-set atom)))
                                       temperature)))
                        (cog-outgoing-set result))
              (for-each (lambda (atom)
                                (set! timestamp
                                      (append!
                                       (list (cadr (cog-outgoing-set atom)))
                                       timestamp)))
                        (cog-outgoing-set result))
              (let ((temp-date-pairs (map (lambda (temp tstmp) (list temp tstmp))
                                        temperature timestamp)))
                   ;Expected format "Fri Jul 12 14:03:24 +0800 2019"
                   (begin
                    (sort! temp-date-pairs
                           (lambda (tn1 tn2)
                                   ;template might change based on the timestamp format we follow
                                   (let* ((template "~a ~b ~d ~H:~M:~S ~z ~Y")
                                          (d1 (string->date (cog-name (cadr tn1)) template))
                                          (d2 (string->date (cog-name (cadr tn2)) template)))
                                         (time>? (date->time-utc d1) (date->time-utc d2)))))
                    ; Get the latest temperature recording
                    (car (car temp-date-pairs))
))))))

(define (get-humidity city)
  (let ((query
         (AtTimeLink
          (EvaluationLink
            (PredicateNode "humidity-at-cty")
            city
            (VariableNode "$H"))
          (VariableNode "$T")))
        )
       (let* ((result (cog-execute! (GetLink query)))
              (humidity '())
              (timestamp '()))
             (begin
              (for-each (lambda (atom)
                                (set! humidity
                                      (append!
                                       (list (car (cog-outgoing-set atom)))
                                       humidity)))
                        (cog-outgoing-set result))
              (for-each (lambda (atom)
                                (set! timestamp
                                      (append!
                                       (list (cadr (cog-outgoing-set atom)))
                                       timestamp)))
                        (cog-outgoing-set result))
              (let ((humidity-date-pairs (map (lambda (humidity tstmp) (list humidity tstmp))
                                        humidity timestamp)))
                   ;Expected format "Fri Jul 12 14:03:24 +0800 2019"
                   (begin
                    (sort! humidity-date-pairs
                           (lambda (tn1 tn2)
                                   ;template might change based on the timestamp format we follow
                                   (let* ((template "~a ~b ~d ~H:~M:~S ~z ~Y")
                                          (d1 (string->date (cog-name (cadr tn1)) template))
                                          (d2 (string->date (cog-name (cadr tn2)) template)))
                                         (time>? (date->time-utc d1) (date->time-utc d2)))))
                    ; Get the latest humidity recording
                    (car (car humidity-date-pairs))
))))))


(define (get-rain-info city)
  (let ((query
         (AtTimeLink
          (EvaluationLink
            (PredicateNode "rain-at-cty")
            city
            (VariableNode "$H"))
          (VariableNode "$T")))
        )
       (let  ((result (cog-execute! (GetLink query)))
              (raininess '())
              (timestamp '()))
             (begin
              (for-each (lambda (atom)
                                (set! raininess
                                      (append!
                                       (list (car (cog-outgoing-set atom)))
                                       raininess)))
                        (cog-outgoing-set result))
              (for-each (lambda (atom)
                                (set! timestamp
                                      (append!
                                       (list (cadr (cog-outgoing-set atom)))
                                       timestamp)))
                        (cog-outgoing-set result))
              (let ((rain-date-pairs (map (lambda (rain tstmp) (list rain tstmp))
                                        raininess timestamp)))
                   ;Expected format "Fri Jul 12 14:03:24 +0800 2019"
                   (begin
                    (sort! rain-date-pairs
                           (lambda (tn1 tn2)
                                   ;XXX template might change based on the timestamp
                                   ;format convention we follow
                                   (let ((template "~a ~b ~d ~H:~M:~S ~z ~Y")
                                          (d1 (string->date (cog-name (cadr tn1)) template))
                                          (d2 (string->date (cog-name (cadr tn2)) template)))
                                     (time>? (date->time-utc d1) (date->time-utc d2)))))
                    ; Get the latest humidity recording
                    (car (car rain-date-pairs))
))))))

(define (is_rainy? city)
  (let ((result (get-rain-info city)))
          (if (null? result) #f
              (eq? (cog-name  result) "RAINY"))))

(define (is_humid? city)
  (let ((THRESHOLD 50))
        (resutl (get-humidity city))
    (>= (string->number (cog-name result)) THRESHOLD)))

;(define (windy? city) #f)


;---Find route
;(define (get-traffic-info city args))
;(define (crowded? city) #f)
;(define (get-route start destination))

;------------------------END----------------------------------------------------------
