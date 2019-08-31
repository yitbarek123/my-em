(define-public (find_restaurant) (begin
    (let (
        (restaurants (va-get-restaurant-recommendation))
    ) (begin
        ; Delete previous recommendations
        (va-remove-generic-fact "restaurant recommendation")

        ; Generate the new recommendations
        (EvaluationLink
            (PredicateNode (va-prefix "restaurant recommendation"))
            (ListLink restaurants)
        )
    ))
))

(define-public (get_reservation_pax) (begin
    (let* (
        (pax (va-get-pax))
    ) (begin
        (cond
            ((null? pax) (cog-logger-warn "No mention of PAX yet!") (False))
            ((> (length pax) 2) (cog-logger-warn "More than one PAX mention found!") (False))
            (else (WordNode (car (string-split (cog-name (car pax)) #\.))))
        )
    ))
))

(define-public (get_recommendation) (begin
    (let* (
        (query
            (EvaluationLink
                (PredicateNode (va-prefix "restaurant recommendation"))
                (ListLink (GlobNode "$X"))
            )
        )
        (restaurants (va-flat-node-list (cog-execute! (GetLink query)) 'RestaurantNode))
        (names (map va-get-restaurant-name restaurants))
    ) (begin
        (if (= 1 (length names)) (begin
            (WordNode (car names))
        ) (begin
            (ListLink (map WordNode (string-split (va-str-list names " , " " and ") #\sp)))
        ))
    ))
))

(define-public (retrieve_review) (begin
    (let (
        (restaurant-selected (va-get-restaurant-review))
    ) (begin
        (StateLink
            (AnchorNode (va-prefix "restaurant for review"))
            restaurant-selected
        )
    ))
))

(define-public (get_review) (begin
    (let* (
        (query
            (AndLink
                (EvaluationLink
                    (PredicateNode (va-prefix "review"))
                    (ListLink
                        (VariableNode "$X")
                        (VariableNode "$Y")
                    )
                )
                (StateLink
                    (AnchorNode (va-prefix "restaurant for review"))
                    (VariableNode "$X")
                )
            )
        )
        (pm-result (cog-execute! (GetLink query)))
        (reviews (va-flat-node-list pm-result 'PhraseNode))
        (restaurant-node (car (va-flat-node-list pm-result 'RestaurantNode)))
        (restaurant-name (va-get-restaurant-name restaurant-node))
        (selected-reviews (va-random-select-up-to-n 3 reviews))
        (text (cons restaurant-name selected-reviews))
    ) (begin
        ; To record which reviews have been read
        (EvaluationLink
            (PredicateNode (va-prefix "review read"))
            (ListLink restaurant-node)
        )
        ; Return a list of words
        (ListLink (map WordNode (string-split (va-str-list text " , " " . ") #\sp)))
    ))
))

(define-public (make_reservation) (begin
    (True)
))
;em code start
(define-public (get_em_reserved) 
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
            (if (null? results) "" (cog-name (car results)))
        ))
    ))

  (let* ( (restaurant (get-detail "user-mentioned-restaurant" 'RestaurantNode))

             (company(get-detail "user-mentioned-known-person" 'PersonNode))
       
    )  

;(cog-execute! (GetLink

 ;                (EvaluationLink
   ;                    (PredicateNode "em-reservation")
  ;                     (ListLink
   ;                        (VariableNode "$res")
    ;                       (PersonNode"VA: person-2")))))

;try

(define temp2(cog-execute! (GetLink

                 (EvaluationLink
                       (PredicateNode "em-reservation")
                       (ListLink
                           (VariableNode "$res")
                           ;(PersonNode"VA: person-2")
                            (PersonNode company)
                       )
                 )
         

             )
))

(WordNode (string-join(cog-value->list(va-get-restaurant-name(RestaurantNode (string-join(cog-value->list(cog-value-ref temp2 0))))))))

;try end

))
(define-public (va-em-add-reservation)
    ; make the following structure
    ; Evaluation
    ;   Predicate "em-reservation"
    ;   List
    ;     Restaurant "x-restaurant"
    ;     Person "company-1"
    ;     Person "company-2"...
   
    ;; TODO
    ;; resolve date and time and pass to spacetime server with atom




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
            (if (null? results) "" (cog-name (car results)))
        ))
    ))


    (let* ( (restaurant (get-detail "user-mentioned-restaurant" 'RestaurantNode))

             (company(get-detail "user-mentioned-known-person" 'PersonNode))
       
    )  


       (Evaluation (Predicate "em-reservation")(List (RestaurantNode restaurant) (PersonNode company)))
)
)
                     
;end
(define-public (get_reservation_details) (begin
    (define (get-details pred-name atom-type) (begin
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
            (if (null? results) "" (cog-name (car results)))
        ))
    ))

    (let* (
        (time (get-details "user-mentioned-time" 'WordNode))
        (date (get-details "user-mentioned-date" 'WordNode))
        (restaurant-raw (get-details "user-mentioned-restaurant" 'RestaurantNode))
        (restaurant
            (if (string-null? restaurant-raw)
                ""
                (cog-name (va-get-restaurant-name (RestaurantNode restaurant-raw)))
            )
        )
        (pax (car (string-split (get-details "user-mentioned-pax" 'NumberNode) #\.)))
        (detail-txt (string-append
            (if (string-null? time) "" (string-append "for " time))
            (if (string-null? date) "" (string-append " on " date))
            (if (string-null? restaurant) "" (string-append " at the " restaurant))
            (if (string-null? pax) "" (string-append " for " pax))
        ))
    ) (begin
        (if (string-null? detail-txt)
            (ListLink)
            (ListLink (map WordNode (string-split detail-txt #\sp)))
        )
    ))
))

(define-public (get_reservation_time) (begin
    (let* (
        (time (va-get-time))
    ) (begin
        (cond
            ((null? time) (cog-logger-warn "No mention of TIME yet!") (False))
            ((> (length time) 2) (cog-logger-warn "More than one TIME mention found!") (False))
            (else (WordNode (car (string-split (cog-name (car time)) #\.))))
        )
    ))
))

(define-public (get_name arg) (begin
    (ListLink (map WordNode
        (string-split
            (va-str-list
                (cog-outgoing-set (cond
                    ((string-ci=? (cog-name arg) "user")
                     (cog-execute!
                         (BindLink
                             (VariableList
                                 (TypedVariableLink
                                     (VariableNode "$VA")
                                     (TypeNode "VirtualAssistantNode")
                                 )
                                 (TypedVariableLink
                                     (VariableNode "$P")
                                     (TypeNode "PersonNode")
                                 )
                                 (TypedVariableLink
                                     (VariableNode "$N")
                                     (TypeNode "WordNode")
                                 )
                             )
                             (AndLink
                                 (EvaluationLink
                                     (PredicateNode (va-prefix "this-va"))
                                     (ListLink
                                         (VariableNode "$VA")
                                     )
                                 )
                                 (EvaluationLink
                                     (PredicateNode (va-prefix "is-va-user"))
                                     (ListLink
                                         (VariableNode "$P")
                                         (VariableNode "$VA")
                                     )
                                 )
                                 (EvaluationLink
                                     (PredicateNode (va-prefix "name"))
                                     (ListLink
                                         (VariableNode "$P")
                                         (VariableNode "$N")
                                     )
                                 )
                             )
                             (VariableNode "$N")
                         )
                    ))
                    ((string-ci=? (cog-name arg) "known-cuisine-preference")
                     (cog-execute!
                         (BindLink
                             (VariableList
                                 (TypedVariableLink
                                     (VariableNode "$P")
                                     (TypeNode "PersonNode")
                                 )
                                 (TypedVariableLink
                                     (VariableNode "$C")
                                     (TypeNode "WordNode")
                                 )
                                 (TypedVariableLink
                                     (VariableNode "$N")
                                     (TypeNode "WordNode")
                                 )
                             )
                             (AndLink
                                 (EvaluationLink
                                     (PredicateNode (va-prefix "user-mentioned-known-person"))
                                     (ListLink
                                         (VariableNode "$P")
                                     )
                                 )
                                 (ChoiceLink
                                     (EvaluationLink
                                         (PredicateNode (va-prefix "likes"))
                                         (ListLink
                                             (VariableNode "$P")
                                             (VariableNode "$C")
                                         )
                                     )
                                     (EvaluationLink
                                         (PredicateNode (va-prefix "dislikes"))
                                         (ListLink
                                             (VariableNode "$P")
                                             (VariableNode "$C")
                                         )
                                     )
                                 )
                                 (InheritanceLink
                                     (VariableNode "$C")
                                     (WordNode "cuisine")
                                 )
                                 (EvaluationLink
                                     (PredicateNode (va-prefix "name"))
                                     (ListLink
                                         (VariableNode "$P")
                                         (VariableNode "$N")
                                     )
                                 )
                             )
                             (VariableNode "$N")
                         )
                    ))
                    ((string-ci=? (cog-name arg) "unknown-cuisine-preference")
                     (cog-execute!
                         (BindLink
                             (VariableList
                                 (TypedVariableLink
                                     (VariableNode "$P")
                                     (TypeNode "PersonNode")
                                 )
                                 (TypedVariableLink
                                     (VariableNode "$N")
                                     (TypeNode "WordNode")
                                 )
                             )
                             (AndLink
                                 (EvaluationLink
                                     (PredicateNode (va-prefix "unknown-cuisine-preference"))
                                     (ListLink
                                         (VariableNode "$P")
                                     )
                                 )
                                 (EvaluationLink
                                     (PredicateNode (va-prefix "name"))
                                     (ListLink
                                         (VariableNode "$P")
                                         (VariableNode "$N")
                                     )
                                 )
                             )
                             (VariableNode "$N")
                         )
                    ))
                    ((string-ci=? (cog-name arg) "retrieved-cuisine-preference")
                     (cog-execute!
                         (BindLink
                             (VariableList
                                 (TypedVariableLink
                                     (VariableNode "$P")
                                     (TypeNode "PersonNode")
                                 )
                                 (TypedVariableLink
                                     (VariableNode "$C")
                                     (TypeNode "WordNode")
                                 )
                                 (TypedVariableLink
                                     (VariableNode "$N")
                                     (TypeNode "WordNode")
                                 )
                             )
                             (AndLink
                                 (ExecutionLink
                                     (SchemaNode "scm: retrieve_unknown_cuisine_preference")
                                     (ChoiceLink
                                         (EvaluationLink
                                             (PredicateNode (va-prefix "likes"))
                                             (ListLink
                                                 (VariableNode "$P")
                                                 (VariableNode "$C")
                                             )
                                         )
                                         (EvaluationLink
                                             (PredicateNode (va-prefix "dislikes"))
                                             (ListLink
                                                 (VariableNode "$P")
                                                 (VariableNode "$C")
                                             )
                                         )
                                     )
                                 )
                                 (InheritanceLink
                                     (VariableNode "$C")
                                     (WordNode "cuisine")
                                 )
                                 (EvaluationLink
                                     (PredicateNode (va-prefix "name"))
                                     (ListLink
                                         (VariableNode "$P")
                                         (VariableNode "$N")
                                     )
                                 )
                             )
                             (VariableNode "$N")
                         )
                    ))
                    ((string-ci=? (cog-name arg) "conflicted-cuisine-preference")
                     (cog-execute!
                         (BindLink
                             (VariableList
                                 (TypedVariableLink
                                     (VariableNode "$C")
                                     (TypeNode "WordNode")
                                 )
                                 (TypedVariableLink
                                     (VariableNode "$P")
                                     (TypeNode "PersonNode")
                                 )
                                 (TypedVariableLink
                                     (VariableNode "$N")
                                     (TypeNode "WordNode")
                                 )
                             )
                             (AndLink
                                 (EvaluationLink
                                     (PredicateNode (va-prefix "conflicted-cuisine-preference"))
                                     (ListLink
                                         (VariableNode "$P")
                                         (VariableNode "$C")
                                     )
                                 )
                                 (EvaluationLink
                                     (PredicateNode (va-prefix "name"))
                                     (ListLink
                                         (VariableNode "$P")
                                         (VariableNode "$N")
                                     )
                                 )
                             )
                             (VariableNode "$N")
                         )
                    ))
                    (else (False))
                ))
                " , "
                " and "
            )
            #\sp
        )
    ))
))

(define-public (get_preference arg) (begin
    (ListLink (map WordNode
        (string-split
            (va-str-list
                (cog-outgoing-set (cond
                    ((string-ci=? (cog-name arg) "retrieved-cuisine")
                     (cog-execute!
                         (BindLink
                             (VariableList
                                 (TypedVariableLink
                                     (VariableNode "$P")
                                     (TypeNode "PersonNode")
                                 )
                                 (TypedVariableLink
                                     (VariableNode "$C")
                                     (TypeNode "WordNode")
                                 )
                             )
                             (AndLink
                                 (ExecutionLink
                                     (SchemaNode "scm: retrieve_unknown_cuisine_preference")
                                     (EvaluationLink
                                         (PredicateNode (va-prefix "likes"))
                                         (ListLink
                                             (VariableNode "$P")
                                             (VariableNode "$C")
                                         )
                                     )
                                 )
                                 (InheritanceLink
                                     (VariableNode "$C")
                                     (WordNode "cuisine")
                                 )
                             )
                             (VariableNode "$C")
                         )
                    ))
                    ((string-ci=? (cog-name arg) "conflicted-cuisine")
                     (cog-execute!
                         (BindLink
                             (VariableList
                                 (TypedVariableLink
                                     (VariableNode "$C")
                                     (TypeNode "WordNode")
                                 )
                                 (TypedVariableLink
                                     (VariableNode "$P")
                                     (TypeNode "PersonNode")
                                 )
                             )
                             (AndLink
                                 (EvaluationLink
                                     (PredicateNode (va-prefix "conflicted-cuisine-preference"))
                                     (ListLink
                                         (VariableNode "$P")
                                         (VariableNode "$C")
                                     )
                                 )
                             )
                             (VariableNode "$C")
                         )
                    ))
                    ((string-ci=? (cog-name arg) "inferred-cuisine")
                     (cog-execute!
                         (BindLink
                             (VariableList
                                 (TypedVariableLink
                                     (VariableNode "$C")
                                     (TypeNode "WordNode")
                                 )
                             )
                             (AndLink
                                 (EvaluationLink
                                     (PredicateNode (va-prefix "inferred-cuisine"))
                                     (ListLink
                                         (VariableNode "$C")
                                     )
                                 )
                             )
                             (VariableNode "$C")
                         )
                    ))
                ))
                " , "
                " and "
            )
            #\sp
        )
    ))
))

(define-public (retrieve_unknown_cuisine_preference) (begin
    ; These records will be used by other predicates/schemas
    (define (record-result result)
        (ExecutionLink
            (SchemaNode "scm: retrieve_unknown_cuisine_preference")
            result
        )
    )

    ; TODO: This should actually send queries to different VA to get the info, but I'll just add these
    ; to the AtomSpace for the use-case-1 until that function is ready
    (record-result (EvaluationLink (PredicateNode "VA: likes") (ListLink (PersonNode "VA: person-3") (WordNode "Chinese"))))
    (record-result (EvaluationLink (PredicateNode "VA: likes") (ListLink (PersonNode "VA: person-3") (WordNode "Thai"))))
    (record-result (EvaluationLink (PredicateNode "VA: dislikes") (ListLink (PersonNode "VA: person-4") (WordNode "Italian"))))

    ; Also delete those 'unknown-cuisine-preference' EvaluationLinks after successfully getting those info
    (for-each
        cog-extract-recursive
        (cog-outgoing-set
            (cog-execute!
                (GetLink
                    (TypedVariableLink
                        (VariableNode "$x")
                        (SignatureLink
                            (EvaluationLink
                                (PredicateNode (va-prefix "unknown-cuisine-preference"))
                                (ListLink
                                    (TypeNode "PersonNode")
                                )
                            )
                        )
                    )
                    (VariableNode "$x")
                )
            )
        )
    )

    ; Return an Atom
    (True)
))

(define-public (analyze_known_cuisine_preference) (begin
    (let (
        (known-person-query
            (GetLink
                (TypedVariableLink
                    (VariableNode "$P")
                    (TypeNode "PersonNode")
                )
                (EvaluationLink
                    (PredicateNode (va-prefix "user-mentioned-known-person"))
                    (ListLink
                        (VariableNode "$P")
                    )
                )
            )
        )
        (known-cuisine-preference-query
            (BindLink
                (VariableList
                    (TypedVariableLink
                        (VariableNode "$P")
                        (TypeNode "PersonNode")
                    )
                    (TypedVariableLink
                        (VariableNode "$C")
                        (TypeNode "WordNode")
                    )
                )
                (AndLink
                    (EvaluationLink
                        (PredicateNode (va-prefix "user-mentioned-known-person"))
                        (ListLink
                            (VariableNode "$P")
                        )
                    )
                    (ChoiceLink
                        (EvaluationLink
                            (PredicateNode (va-prefix "likes"))
                            (ListLink
                                (VariableNode "$P")
                                (VariableNode "$C")
                            )
                        )
                        (EvaluationLink
                            (PredicateNode (va-prefix "dislikes"))
                            (ListLink
                                (VariableNode "$P")
                                (VariableNode "$C")
                            )
                        )
                    )
                    (InheritanceLink
                        (VariableNode "$C")
                        (WordNode "cuisine")
                    )
                )
                (VariableNode "$P")
            )
        )
    ) (begin
        (let* (
            (known-people (cog-outgoing-set (cog-execute! known-person-query)))
            (known-cuisine-preferences (cog-outgoing-set (cog-execute! known-cuisine-preference-query)))
            (preference-not-known (lset-difference equal? known-people known-cuisine-preferences))
        ) (begin
            (for-each (lambda (x) (begin
                (EvaluationLink
                    (PredicateNode (va-prefix "unknown-cuisine-preference"))
                    (ListLink x)
                )
            )) preference-not-known)
        ))
    ))

    ; Return an Atom
    (True)
))

(define-public (analyze_retrieved_cuisine_preference) (begin
    (let (
        (query-conflict
            (BindLink
                (VariableList
                    (TypedVariableLink
                        (VariableNode "$P1")
                        (TypeNode "PersonNode")
                    )
                    (TypedVariableLink
                        (VariableNode "$P2")
                        (TypeNode "PersonNode")
                    )
                    (TypedVariableLink
                        (VariableNode "$C")
                        (TypeNode "WordNode")
                    )
                )
                (AndLink
                    (ExecutionLink
                        (SchemaNode "scm: retrieve_unknown_cuisine_preference")
                        (EvaluationLink
                            (PredicateNode (va-prefix "likes"))
                            (ListLink
                                (VariableNode "$P1")
                                (VariableNode "$C")
                            )
                        )
                    )
                    (EvaluationLink
                        (PredicateNode (va-prefix "user-mentioned-known-person"))
                        (ListLink
                            (VariableNode "$P2")
                        )
                    )
                    (EvaluationLink
                        (PredicateNode (va-prefix "dislikes"))
                        (ListLink
                            (VariableNode "$P2")
                            (VariableNode "$C")
                        )
                    )
                    (InheritanceLink
                        (VariableNode "$C")
                        (WordNode "cuisine")
                    )
                )
                (EvaluationLink
                    (PredicateNode (va-prefix "conflicted-cuisine-preference"))
                    (ListLink
                        (VariableNode "$P2")
                        (VariableNode "$C")
                    )
                )
            )
        )
        (query-like
            (BindLink
                (VariableList
                    (TypedVariableLink
                        (VariableNode "$P1")
                        (TypeNode "PersonNode")
                    )
                    (TypedVariableLink
                        (VariableNode "$P2")
                        (TypeNode "PersonNode")
                    )
                    (TypedVariableLink
                        (VariableNode "$C")
                        (TypeNode "WordNode")
                    )
                )
                (AndLink
                    (ExecutionLink
                        (SchemaNode "scm: retrieve_unknown_cuisine_preference")
                        (EvaluationLink
                            (PredicateNode (va-prefix "likes"))
                            (ListLink
                                (VariableNode "$P1")
                                (VariableNode "$C")
                            )
                        )
                    )
                    (EvaluationLink
                        (PredicateNode (va-prefix "user-mentioned-known-person"))
                        (ListLink
                            (VariableNode "$P2")
                        )
                    )
                    (EvaluationLink
                        (PredicateNode (va-prefix "likes"))
                        (ListLink
                            (VariableNode "$P2")
                            (VariableNode "$C")
                        )
                    )
                    (InheritanceLink
                        (VariableNode "$C")
                        (WordNode "cuisine")
                    )
                )
                (VariableNode "$C")
            )
        )
        (query-dislike
            (BindLink
                (VariableList
                    (TypedVariableLink
                        (VariableNode "$P1")
                        (TypeNode "PersonNode")
                    )
                    (TypedVariableLink
                        (VariableNode "$P2")
                        (TypeNode "PersonNode")
                    )
                    (TypedVariableLink
                        (VariableNode "$C1")
                        (TypeNode "WordNode")
                    )
                    (TypedVariableLink
                        (VariableNode "$C2")
                        (TypeNode "WordNode")
                    )
                )
                (AndLink
                    (ExecutionLink
                        (SchemaNode "scm: retrieve_unknown_cuisine_preference")
                        (EvaluationLink
                            (PredicateNode (va-prefix "dislikes"))
                            (ListLink
                                (VariableNode "$P1")
                                (VariableNode "$C1")
                            )
                        )
                    )
                    (EvaluationLink
                        (PredicateNode (va-prefix "user-mentioned-known-person"))
                        (ListLink
                            (VariableNode "$P2")
                        )
                    )
                    (EvaluationLink
                        (PredicateNode (va-prefix "dislikes"))
                        (ListLink
                            (VariableNode "$P2")
                            (VariableNode "$C2")
                        )
                    )
                    (InheritanceLink
                        (VariableNode "$C1")
                        (WordNode "cuisine")
                    )
                    (InheritanceLink
                        (VariableNode "$C2")
                        (WordNode "cuisine")
                    )
                )
                (SetLink
                    (VariableNode "$C1")
                    (VariableNode "$C2")
                )
            )
        )
    ) (begin
        (let* (
            (cuisine-conflicted (cog-execute! query-conflict))
            (cuisine-liked (delete-duplicates (va-flat-node-list (cog-execute! query-like) 'WordNode)))
            (cuisine-disliked (delete-duplicates (va-flat-node-list (cog-execute! query-dislike) 'WordNode)))
            (cuisine-inferred (filter (lambda (x) (not (list? (member x cuisine-disliked)))) cuisine-liked))
        ) (begin
            (for-each (lambda (c) (begin
                (EvaluationLink
                    (PredicateNode (va-prefix "inferred-cuisine"))
                    (ListLink c)
                )
            )) cuisine-inferred)
        ))
    ))

    ; Return an Atom
    (True)
))
