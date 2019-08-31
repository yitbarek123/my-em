(define (va-infer-cuisines) (begin
    (let* (
        (query-inferred
            (AndLink
                (EvaluationLink
                    (PredicateNode (va-prefix "inferred-cuisine"))
                    (ListLink
                        (VariableNode "$C")
                    )
                )
            )
        )
        (query-links (list
                        (AndLink
                            (EvaluationLink
                                (PredicateNode (va-prefix "user-mentioned-known-person"))
                                (ListLink
                                    (VariableNode "$X")
                                )
                            )
                            (EvaluationLink
                                (PredicateNode (va-prefix "likes"))
                                (ListLink
                                    (VariableNode "$X")
                                    (VariableNode "$Y")
                                )
                            )
                            (InheritanceLink
                                (VariableNode "$Y")
                                (WordNode "cuisine")
                            )
                        )
                        (AndLink
                            (EvaluationLink
                                (PredicateNode (va-prefix "this-va"))
                                (ListLink
                                    (VariableNode "$V")
                                )
                            )
                            (EvaluationLink
                                (PredicateNode (va-prefix "is-va-user"))
                                (ListLink
                                    (VariableNode "$X")
                                    (VariableNode "$V")
                                )
                            )
                            (EvaluationLink
                                (PredicateNode (va-prefix "likes"))
                                (ListLink
                                    (VariableNode "$X")
                                    (VariableNode "$Y")
                                )
                            )
                            (InheritanceLink
                                (VariableNode "$Y")
                                (WordNode "cuisine")
                            )
                        )
                     )
        )
    ) (begin
        (let (
            (cuisine-inferred (cog-outgoing-set (cog-execute! (GetLink query-inferred))))
        ) (begin
            (if (null? cuisine-inferred)
                (delete-duplicates (va-flat-node-list (map (lambda (query) (cog-execute! (GetLink query))) query-links) 'WordNode))
                cuisine-inferred
            )
        ))
    ))
))

(define (va-make-restaurant-recommendation) (begin
    (let* (
        (selected (va-get-restaurant-recommendation))
        (names (map (lambda (restaurant-node) (va-get-mapped-value restaurant-node "name")) selected))
    ) (begin
        (cond
            ((null? names) (va-push-vauttr "I couldn't find any interesting restaurant."))
            ((< (length names) 2) (va-push-vauttr (string-append (car names) " is well ranked in TripAdvisor")))
            (else (va-push-vauttr (string-append (va-str-list names ", " " and ") " are well ranked in TripAdvisor")))
        )
        selected
    ))
))

(define (va-get-pax) (begin
    (let* (
        (query-link (EvaluationLink
                        (PredicateNode (va-prefix "user-mentioned-pax"))
                        (ListLink (VariableNode "$X"))
                    )
        )
    ) (begin
        (va-flat-node-list (cog-execute! (GetLink query-link)) 'NumberNode)
    ))
))

(define (va-get-restaurant-recommendation) (begin
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
        (query-base
            ; If the user mentioned somewhere, the VA is supposed to look for
            ; restaurants there instead of the current location
            (if (va-fact-exist? "user-mentioned-location" 'WordNode)
                (list
                    (EvaluationLink
                        (PredicateNode (va-prefix "user-mentioned-location"))
                        (ListLink
                            (VariableNode "$L")
                        )
                    )
                    (EvaluationLink
                        (PredicateNode (va-prefix "at-location"))
                        (ListLink
                            (VariableNode "$R")
                            (VariableNode "$L")
                        )
                    )
                )
                (list
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
                        (PredicateNode (va-prefix "this-va"))
                        (ListLink
                            (VariableNode "$V")
                        )
                    )
                    (EvaluationLink
                        (PredicateNode (va-prefix "is-va-user"))
                        (ListLink
                            (VariableNode "$P")
                            (VariableNode "$V")
                        )
                    )
                )
            )
        )
        (query-links
            (if (null? target-cuisines)
                (list (AndLink query-base))
                (map (lambda (cuisine)
                    (AndLink
                        query-base
                        (EvaluationLink
                             (PredicateNode "VA: cuisine")
                             (ListLink
                                 (VariableNode "$R")
                                 cuisine
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

(define (va-get-restaurant-review) (begin
    (let* (
        (query-restaurant-recommended
            (EvaluationLink
                (PredicateNode (va-prefix "restaurant recommendation"))
                (ListLink (GlobNode "$X"))
            )
        )
        (query-review-read
            (EvaluationLink
                (PredicateNode (va-prefix "review read"))
                (ListLink (VariableNode "$X"))
            )
        )
        (restaurants (va-flat-node-list (cog-execute! (GetLink query-restaurant-recommended)) 'RestaurantNode))
        (read-review (va-flat-node-list (cog-execute! (GetLink query-review-read)) 'RestaurantNode))
        (unread-review (lset-difference equal? restaurants read-review))
        (selected (if (null? unread-review) (list) (va-random-select unread-review)))
    ) (begin
        (if (null? selected) (begin
            (False)
        ) (begin
            selected
        ))
    ))
))

(define (va-get-time) (begin
    (let* (
        (query-link
            (EvaluationLink
                (PredicateNode (va-prefix "user-mentioned-time"))
                (ListLink (VariableNode "$X"))
            )
        )
    ) (begin
        (va-flat-node-list (cog-execute! (GetLink query-link)) 'WordNode)
    ))
))
