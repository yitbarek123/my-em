
(define-public (is_reserved_before) (begin
(define z(SetLink(ListLink )) )
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

(define satlink (Satisfaction (Evaluation (Predicate "em-reservation")(List (Variable "$x") (PersonNode (get-detail "user-mentioned-known-person" 'PersonNode))))))

(cog-evaluate! satlink)
    
))

(define-public (is_cuisine_missing) (begin
    (if (va-fact-exist? "user-mentioned-cuisine" 'WordNode 'ConceptNode)
        va-false
        va-true
    )
))

(define-public (is_date_missing) (begin
    (if (va-fact-exist? "user-mentioned-date" 'WordNode)
        va-false
        va-true
    )
))

(define-public (is_pax_missing) (begin
    (if (va-fact-exist? "user-mentioned-pax" 'NumberNode)
        va-false
        va-true
    )
))

(define-public (is_unknown_cuisine_preference) (begin
    (if (va-fact-exist? "unknown-cuisine-preference" 'PersonNode)
        va-true
        va-false
    )
))

(define-public (is_no_unknown_cuisine_preference) (begin
    (if (va-fact-exist? "unknown-cuisine-preference" 'PersonNode)
        va-false
        va-true
    )
))

(define-public (is_conflicted_cuisine_preference) (begin
    (if (va-fact-exist? "conflicted-cuisine-preference")
        va-true
        va-false
    )
))

(define-public (is_no_conflicted_cuisine_preference) (begin
    (if (va-fact-exist? "conflicted-cuisine-preference")
        va-false
        va-true
    )
))

(define-public (is_inferred_cuisine) (begin
    (if (va-fact-exist? "inferred-cuisine")
        va-true
        va-false
    )
))

(define-public (is_restaurant_missing) (begin
    (if (va-fact-exist? "user-mentioned-restaurant" 'RestaurantNode)
        va-false
        va-true
    )
))

(define-public (is_time_missing) (begin
    (if (va-fact-exist? "user-mentioned-time" 'WordNode)
        va-false
        va-true
    )
))

(define-public (is_recommendation_available) (begin
    (if (va-fact-exist? "restaurant recommendation" 'RestaurantNode)
        va-true
        va-false
    )
))

(define-public (is_review_available) (begin
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
        (reviews (cog-outgoing-set (cog-execute! (GetLink query))))
    ) (begin
        (if (null? reviews)
            va-false
            va-true
        )
    ))
))

(define-public (is_reserved_successfully) (begin
    va-true
))

(define-public (isa var-grounding target) (begin
    (if (and (null?
                 (cog-link 'EvaluationLink
                     (PredicateNode "IsA")
                     (ListLink
                         var-grounding
                         (WordNode (cog-name target))
                     )
                 )
             )
             (null?
                 (cog-link 'InheritanceLink
                     var-grounding
                     (WordNode (cog-name target))
                 )
             )
        )
        va-false
        va-true
    )
))

(define-public (synonym var-grounding target) (begin
    (if (null?
            (cog-link 'EvaluationLink
                (PredicateNode "Synonym")
                (ListLink
                    var-grounding
                    (WordNode (cog-name target))
                )
            )
        )
        va-false
        va-true
    )
))

(define-public (is_restaurant var-grounding) (begin
    (let (
        (vg-str-cap (map string-capitalize (map cog-name (cog-outgoing-set var-grounding))))
    ) (begin
        (if (null?
                (cog-link 'EvaluationLink
                    (PredicateNode (va-prefix "name-in-words"))
                    (ListLink
                        (PhraseNode (string-join vg-str-cap))
                        (ListLink (map WordNode vg-str-cap))
                    )
                )
            )
            va-false
            va-true
        )
    ))
))
