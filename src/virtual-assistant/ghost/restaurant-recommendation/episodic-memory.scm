;; XXX
;; This should probably be in utils.scm and removed from get_reservation_details
;; as well
(define (get-detail pred-name atom-type) (begin
    (let (
        (results
            (va-flat-node-list
                (cog-execute! (GetLink
                    (EvaluationLink
                        (PredicateNode (va-prefix pred-name))
                        (ListLink (VariableNode "$X"))
                    )
                ))
                atom-type
            )
        )
    ) (begin
        (if (null? results) ("") results)
    ))
))

(define-public (va-em-add-reservation)
    ; make the following structure
    ; Evaluation
    ;   Predicate "em-reservation"
    ;   List
    ;     Restaurant "x-restaurant"
    ;     Person "company-1"
    ;     Person "company-2"...
    (let*
        ((res-time (car (get-detail "user-mentioned-time" 'WordNode)))
         (date (car (get-detail "user-mentioned-date" 'WordNode)))
         (restaurant (car (get-detail "user-mentioned-restaurant" 'RestaurantNode)))
         (company
            (map (lambda (person)
                (va-flat-node-list
                    (cog-execute! (GetLink
                        (EvaluationLink
                            (PredicateNode (va-prefix "name"))
                            (ListLink
                                person
                                (VariableNode "$VPN")
                            )
                        )
                    ))
                    'WordNode
                ))
                (get-details "user-mentioned-known-person" 'PersonNode))
         )
         (em-atm
            (Evaluation
                (Predicate "em-reservation")
                    (List
                        restaurant
                        company))))

    )
    ;; TODO
    ;; resolve date and time and pass to spacetime server with atom
)
