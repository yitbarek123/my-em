(va-add-monitored-predicate "user-mentioned-cuisine" (lambda () (begin
    (cog-logger-info "Evaluating predicate: user-mentioned-cuisine\n")
    (va-debug "Evaluating user-mentioned-cuisine\n")
    (user-mentioned-cuisine?)
)))

(va-add-monitored-predicate "user-mentioned-date" (lambda () (begin
    (cog-logger-info "Evaluating predicate: user-mentioned-date\n")
    (va-debug "Evaluating user-mentioned-date\n")
    (user-mentioned-date?)
)))

(va-add-monitored-predicate "user-mentioned-location" (lambda () (begin
    (cog-logger-info "Evaluating predicate: user-mentioned-location\n")
    (va-debug "Evaluating user-mentioned-location\n")
    (user-mentioned-location?)
)))

(va-add-monitored-predicate "user-mentioned-pax" (lambda () (begin
    (cog-logger-info "Evaluating predicate: user-mentioned-pax\n")
    (va-debug "Evaluating user-mentioned-pax\n")
    (user-mentioned-pax?)
)))

(va-add-monitored-predicate "user-mentioned-restaurant" (lambda () (begin
    (cog-logger-info "Evaluating predicate: user-mentioned-restaurant\n")
    (va-debug "Evaluating user-mentioned-restaurant\n")
    (user-mentioned-restaurant?)
)))

(va-add-monitored-predicate "user-mentioned-time" (lambda () (begin
    (cog-logger-info "Evaluating predicate: user-mentioned-time\n")
    (va-debug "Evaluating user-mentioned-time\n")
    (user-mentioned-time?)
)))

(define* (user-mentioned-cuisine? #:optional sentence-node) (begin
    (let (
        (query-links (list
            (AndLink
                (if sentence-node (begin (list
                    (ParseLink
                        (VariableNode "$P")
                        sentence-node
                    )
                    (WordInstanceLink
                        (VariableNode "$X")
                        (VariableNode "$P")
                    )
                )) (begin
                    (list)
                ))
                (ReferenceLink
                    (VariableNode "$X")
                    (VariableNode "$Y")
                )
                (InheritanceLink
                    (VariableNode "$Y")
                    (WordNode "cuisine")
                )
            )
            (AndLink
                (if sentence-node (begin (list
                    (ParseLink
                        (VariableNode "$P")
                        sentence-node
                    )
                    (WordInstanceLink
                        (VariableNode "$X")
                        (VariableNode "$P")
                    )
                )) (begin
                    (list)
                ))
                (ReferenceLink
                    (VariableNode "$X")
                    (VariableNode "$Y")
                )
                (EvaluationLink
                    (PredicateNode "IsA")
                    (ListLink
                        (VariableNode "$Y")
                        (WordNode "food")
                    )
                )
            )
            (AndLink
                (if sentence-node (begin (list
                    (ParseLink
                        (VariableNode "$P")
                        sentence-node
                    )
                    (WordInstanceLink
                        (VariableNode "$X")
                        (VariableNode "$P")
                    )
                )) (begin
                    (list)
                ))
                (ReferenceLink
                    (VariableNode "$X")
                    (VariableNode "$Y")
                )
                (EvaluationLink
                    (PredicateNode "IsA")
                    (ListLink
                        (VariableNode "$Y")
                        (WordNode "dish")
                    )
                )
            )
            (AndLink
                (if sentence-node (begin (list
                    (ParseLink
                        (VariableNode "$P")
                        sentence-node
                    )
                    (WordInstanceLink
                        (VariableNode "$X")
                        (VariableNode "$P")
                    )
                )) (begin
                    (list)
                ))
                (ReferenceLink
                    (VariableNode "$X")
                    (VariableNode "$Y")
                )
                (EvaluationLink
                    (PredicateNode "IsA")
                    (ListLink
                        (VariableNode "$Y")
                        (VariableNode "$Z")
                    )
                )
                (EvaluationLink
                    (PredicateNode "IsA")
                    (ListLink
                        (VariableNode "$Z")
                        (WordNode "food")
                    )
                )
            )
            (AndLink
                (if sentence-node (begin (list
                    (ParseLink
                        (VariableNode "$P")
                        sentence-node
                    )
                    (WordInstanceLink
                        (VariableNode "$X")
                        (VariableNode "$P")
                    )
                )) (begin
                    (list)
                ))
                (ReferenceLink
                    (VariableNode "$X")
                    (VariableNode "$Y")
                )
                (EvaluationLink
                    (PredicateNode "IsA")
                    (ListLink
                        (VariableNode "$Y")
                        (VariableNode "$Z")
                    )
                )
                (EvaluationLink
                    (PredicateNode "IsA")
                    (ListLink
                        (VariableNode "$Z")
                        (WordNode "dish")
                    )
                )
            )
            (AndLink
                (if sentence-node (begin (list
                    (ParseLink
                        (VariableNode "$P")
                        sentence-node
                    )
                    (WordInstanceLink
                        (VariableNode "$X")
                        (VariableNode "$P")
                    )
                )) (begin
                    (list)
                ))
                (ReferenceLink
                    (VariableNode "$X")
                    (VariableNode "$Y")
                )
                (EvaluationLink
                    (PredicateNode "InstanceOf")
                    (ListLink
                        (VariableNode "$Y")
                        (VariableNode "$Z")
                    )
                )
                (EvaluationLink
                    (PredicateNode "IsA")
                    (ListLink
                        (VariableNode "$Z")
                        (WordNode "food")
                    )
                )
            )
            (AndLink
                (if sentence-node (begin (list
                    (ParseLink
                        (VariableNode "$P")
                        sentence-node
                    )
                    (WordInstanceLink
                        (VariableNode "$X")
                        (VariableNode "$P")
                    )
                )) (begin
                    (list)
                ))
                (ReferenceLink
                    (VariableNode "$X")
                    (VariableNode "$Y")
                )
                (EvaluationLink
                    (PredicateNode "InstanceOf")
                    (ListLink
                        (VariableNode "$Y")
                        (VariableNode "$Z")
                    )
                )
                (EvaluationLink
                    (PredicateNode "IsA")
                    (ListLink
                        (VariableNode "$Z")
                        (WordNode "dish")
                    )
                )
            )
        ))
    ) (begin
        (let (
            (positive-mentions '())
            (negative-mentions '())
            (sentiment #t)
        ) (begin
            (for-each (lambda (word-node) (begin
                (set! sentiment (va-eval-sentiment word-node))
                (if (null? (cog-link 'InheritanceLink word-node (WordNode "cuisine")))
                    (let* (
                        (query-links (list
                                         (EvaluationLink
                                             (PredicateNode "AtLocation")
                                             (ListLink
                                                 word-node
                                                 (VariableNode "$X")
                                             )
                                         )
                                         (EvaluationLink
                                             (PredicateNode "IsA")
                                             (ListLink
                                                 word-node
                                                 (VariableNode "$X")
                                             )
                                         )
                                     )
                        )
                        (candidates (va-flat-node-list (map (lambda (query) (cog-execute! (GetLink query))) query-links) 'Node))
                    ) (begin
                        (for-each (lambda (node) (begin
                            (for-each (lambda (word) (begin
                                (if (not (null? (cog-link 'InheritanceLink (WordNode word) (WordNode "cuisine"))))
                                    (if sentiment
                                        (set! positive-mentions (append positive-mentions (list (WordNode word))))
                                        (set! negative-mentions (append negative-mentions (list (WordNode word))))
                                    )
                                )
                            )) (va-split-phrase (cog-name node)))
                        )) candidates)
                    ))
                    (if sentiment
                        (set! positive-mentions (append positive-mentions (list word-node)))
                        (set! negative-mentions (append negative-mentions (list word-node)))
                    )
                )
            )) (va-flat-node-list (map (lambda (query) (cog-execute! (GetLink query))) query-links) 'WordNode))
            (map (lambda (word-node) (begin
                (va-add-generic-fact-2 "user-mentioned-cuisine" word-node va-positive)
            )) positive-mentions)
            (map (lambda (word-node) (begin
                (va-add-generic-fact-2 "user-mentioned-cuisine" word-node va-negative)
            )) negative-mentions)
            (or (not (null? positive-mentions)) (not (null? negative-mentions)))
        ))
    ))
))

(define* (user-mentioned-date? #:optional sentence-node) (begin
    (let (
        (query-links (list
            (AndLink
                (if sentence-node (begin (list
                    (ParseLink
                        (VariableNode "$P")
                        sentence-node
                    )
                    (WordInstanceLink
                        (VariableNode "$X")
                        (VariableNode "$P")
                    )
                )) (begin
                    (list)
                ))
                (ReferenceLink
                    (VariableNode "$X")
                    (VariableNode "$Y")
                )
                ; To exclude e.g. morning, afternoon, evening etc
                ; that also happen to be a "day" in ConceptNet
                (AbsentLink
                    (EvaluationLink
                        (PredicateNode "IsA")
                        (ListLink
                            (VariableNode "$Y")
                            (PhraseNode "time of day")
                        )
                    )
                )
                ; e.g. monday, tuesday, wednesday etc
                (EvaluationLink
                    (PredicateNode "IsA")
                    (ListLink
                        (VariableNode "$Y")
                        (WordNode "day")
                    )
                )
            )
        ))
    ) (begin
        (let (
            (dates (va-flat-node-list (map (lambda (query) (cog-execute! (GetLink query))) query-links) 'WordNode))
        ) (begin
            (if (not (null? dates)) (va-remove-generic-fact "user-mentioned-date"))
            (map (lambda (date-node) (begin
                (va-add-generic-fact-1 "user-mentioned-date" date-node)
            )) dates)
            (not (null? dates))
        ))
    ))
))

(define* (user-mentioned-location? #:optional sentence-node) (begin
    (let (
        ; To handle cases where user specifically requested a particular location, e.g.
        ;            +--------------------+--------+
        ;            |                    |        |
        ; could you look for restaurants near Embankment at 6:30pm please
        (location-requested-query
            (AndLink
                (if sentence-node (begin (list
                    (ParseLink
                        (VariableNode "$P")
                        sentence-node
                    )
                    (WordInstanceLink
                        (VariableNode "$Q")
                        (VariableNode "$P")
                    )
                    (WordInstanceLink
                        (VariableNode "$X")
                        (VariableNode "$P")
                    )
                    (WordInstanceLink
                        (VariableNode "$Y")
                        (VariableNode "$P")
                    )
                )) (begin
                    (list)
                ))
                (ChoiceLink
                    (ReferenceLink
                        (VariableNode "$Q")
                        (WordNode "look")
                    )
                    (ReferenceLink
                        (VariableNode "$Q")
                        (WordNode "find")
                    )
                )
                (EvaluationLink
                    (LinkGrammarRelationshipNode "MVp")
                    (ListLink
                        (VariableNode "$Q")
                        (VariableNode "$X")
                    )
                )
                (EvaluationLink
                    (LinkGrammarRelationshipNode "Js")
                    (ListLink
                        (VariableNode "$X")
                        (VariableNode "$Y")
                    )
                )
                (ChoiceLink
                    (ReferenceLink
                        (VariableNode "$X")
                        (WordNode "near")
                    )
                    (ReferenceLink
                        (VariableNode "$X")
                        (WordNode "around")
                    )
                )
                (ReferenceLink
                    (VariableNode "$Y")
                    (VariableNode "$Z")
                )
                (ChoiceLink
                    (EvaluationLink
                        (PredicateNode "IsA")
                        (ListLink
                            (VariableNode "$Z")
                            (WordNode "city")
                        )
                    )
                    (EvaluationLink
                        (PredicateNode "IsA")
                        (ListLink
                            (VariableNode "$Z")
                            (PhraseNode "a place name")
                        )
                    )
                )
            )
        )
        (query-links (list
            ; e.g. near Embankment
            (AndLink
                (if sentence-node (begin (list
                    (ParseLink
                        (VariableNode "$P")
                        sentence-node
                    )
                    (WordInstanceLink
                        (VariableNode "$Y")
                        (VariableNode "$P")
                    )
                )) (begin
                    (list)
                ))
                (ReferenceLink
                    (VariableNode "$Y")
                    (VariableNode "$Z")
                )
                (ChoiceLink
                    (EvaluationLink
                        (PredicateNode "IsA")
                        (ListLink
                            (VariableNode "$Z")
                            (WordNode "city")
                        )
                    )
                    (EvaluationLink
                        (PredicateNode "IsA")
                        (ListLink
                            (VariableNode "$Z")
                            (PhraseNode "a place name")
                        )
                    )
                )
            )
        ))
    ) (begin
        (let* (
            (location-in-request (va-flat-node-list (cog-execute! (GetLink location-requested-query)) 'WordNode))
            (locations
                (if (null? location-in-request) (begin
                    (va-flat-node-list (map (lambda (query) (cog-execute! (GetLink query))) query-links) 'WordNode)
                ) (begin
                    location-in-request
                ))
            )
        ) (begin
            (if (not (null? locations)) (va-remove-generic-fact "user-mentioned-location"))
            (map (lambda (location-node) (begin
                (va-add-generic-fact-1 "user-mentioned-location" location-node)
            )) locations)
            (not (null? locations))
        ))
    ))
))

(define* (user-mentioned-pax? #:optional sentence-node) (begin
    (let (
        (query-known-person (list
            (AndLink
                (EvaluationLink
                    (PredicateNode (va-prefix "user-mentioned-known-person"))
                    (ListLink
                        (VariableNode "$X")
                    )
                )
            )
        ))
        (query-self (list
            ; e.g. just me
            (AndLink
                (if sentence-node (begin (list
                    (ParseLink
                        (VariableNode "$P")
                        sentence-node
                    )
                )) (begin
                    (list)
                ))
                (WordInstanceLink
                    (VariableNode "$X")
                    (VariableNode "$P")
                )
                (WordInstanceLink
                    (VariableNode "$Y")
                    (VariableNode "$P")
                )
                (ChoiceLink
                    (ReferenceLink
                        (VariableNode "$X")
                        (WordNode "just")
                    )
                    (ReferenceLink
                        (VariableNode "$X")
                        (WordNode "only")
                    )
                )
                (ChoiceLink
                    (ReferenceLink
                        (VariableNode "$Y")
                        (WordNode "me")
                    )
                    (ReferenceLink
                        (VariableNode "$Y")
                        (WordNode "I")
                    )
                    (ReferenceLink
                        (VariableNode "$Y")
                        (WordNode "myself")
                    )
                )
            )
        ))
    ) (begin
        (let (
            (known-people (delete-duplicates (va-flat-node-list (map (lambda (query) (cog-execute! (GetLink query))) query-known-person) 'PersonNode)))
            (self (va-flat-node-list (map (lambda (query) (cog-execute! (GetLink query))) query-self) 'WordInstanceNode))
        ) (begin
            (cond
                ; Just the user is going
                ((and (null? known-people) (not (null? self))) (begin
                    (va-remove-generic-fact "user-mentioned-pax")
                    (va-add-generic-fact-1 "user-mentioned-pax" (NumberNode 1))
                    #t
                ))
                ; Assume the user will always go if there is any mentioned of one or more known people
                ((not (null? known-people)) (begin
                    (va-remove-generic-fact "user-mentioned-pax")
                    (va-add-generic-fact-1 "user-mentioned-pax" (NumberNode (1+ (length known-people))))
                    #t
                ))
                (else #f)
            )
        ))
    ))
))

(define* (user-mentioned-restaurant? #:optional sentence-node) (begin
    (let (
        (query-var
            (VariableList
                (TypedVariableLink
                    (VariableNode "$R")
                    (TypeNode "RestaurantNode")
                )
                (TypedVariableLink
                    (VariableNode "$P")
                    (TypeNode "PhraseNode")
                )
                (if sentence-node (begin
                    (list)
                ) (begin
                    (TypedVariableLink
                        (VariableNode "$S")
                        (TypeNode "SentenceNode")
                    )
                ))
                (TypedVariableLink
                    (GlobNode "$G1")
                    (TypeSetLink
                        (IntervalLink
                            (NumberNode 1)
                            (NumberNode -1)
                        )
                        (TypeNode "WordNode")
                    )
                )
                (TypedVariableLink
                    (GlobNode "$G2")
                    (TypeSetLink
                        (IntervalLink
                            (NumberNode 1)
                            (NumberNode -1)
                        )
                        (TypeNode "WordNode")
                    )
                )
                (TypedVariableLink
                    (GlobNode "$wildcard-1")
                    (TypeSetLink
                        (IntervalLink
                            (NumberNode 0)
                            (NumberNode -1)
                        )
                        (TypeNode "WordNode")
                    )
                )
                (TypedVariableLink
                    (GlobNode "$wildcard-2")
                    (TypeSetLink
                        (IntervalLink
                            (NumberNode 0)
                            (NumberNode -1)
                        )
                        (TypeNode "WordNode")
                    )
                )
            )
        )
        (query-pat
            (AndLink
                (EvaluationLink
                    (PredicateNode (va-prefix "name"))
                    (ListLink
                        (VariableNode "$R")
                        (VariableNode "$P")
                    )
                )
                (EvaluationLink
                    (PredicateNode (va-prefix "name-in-words"))
                    (ListLink
                        (VariableNode "$P")
                        (ListLink
                            (GlobNode "$G1")
                        )
                    )
                )
                (EvaluationLink
                    (PredicateNode (va-prefix "word sequence"))
                    (ListLink
                        (if sentence-node (begin
                            sentence-node
                        ) (begin
                            (VariableNode "$S")
                        ))
                        (ListLink
                            (GlobNode "$wildcard-1")
                            (GlobNode "$G2")
                            (GlobNode "$wildcard-2")
                        )
                    )
                )
                (EqualLink (Link (GlobNode "$G1")) (Link (GlobNode "$G2")))
            )
        )
    ) (begin
        (let (
            (restaurants (va-flat-node-list (cog-outgoing-set (cog-execute! (GetLink query-var query-pat))) 'RestaurantNode))
        ) (begin
            (if (not (null? restaurants)) (va-remove-generic-fact "user-mentioned-restaurant"))
            (map (lambda (restaurant) (begin
                (va-add-generic-fact-1 "user-mentioned-restaurant" restaurant)
            )) restaurants)
            (not (null? restaurants))
        ))
    ))
))

(define* (user-mentioned-time? #:optional sentence-node) (begin
    (let (
        ; To handle cases where user specifically requested a particular time, e.g.
        ;            +------------------------------------+-----+
        ;            |                                    |     |
        ; could you look for restaurants near Embankment at 6:30pm please
        (time-requested-query-1
            (AndLink
                (if sentence-node (begin (list
                    (ParseLink
                        (VariableNode "$P")
                        sentence-node
                    )
                    (WordInstanceLink
                        (VariableNode "$Q")
                        (VariableNode "$P")
                    )
                    (WordInstanceLink
                        (VariableNode "$V")
                        (VariableNode "$P")
                    )
                    (WordInstanceLink
                        (VariableNode "$X")
                        (VariableNode "$P")
                    )
                    (WordInstanceLink
                        (VariableNode "$W")
                        (VariableNode "$P")
                    )
                    (WordInstanceLink
                        (VariableNode "$Y")
                        (VariableNode "$P")
                    )
                )) (begin
                    (list)
                ))
                ; look <-> at
                (EvaluationLink
                    (LinkGrammarRelationshipNode "MVp")
                    (ListLink
                        (VariableNode "$Q")
                        (VariableNode "$V")
                    )
                )
                ; at <-> pm
                (EvaluationLink
                    (LinkGrammarRelationshipNode "Js")
                    (ListLink
                        (VariableNode "$V")
                        (VariableNode "$Y")
                    )
                )
                ; 6:30 <-> pm
                (EvaluationLink
                    (LinkGrammarRelationshipNode "ND")
                    (ListLink
                        (VariableNode "$W")
                        (VariableNode "$Y")
                    )
                )
                (ChoiceLink
                    (ReferenceLink
                        (VariableNode "$Q")
                        (WordNode "look")
                    )
                    (ReferenceLink
                        (VariableNode "$Q")
                        (WordNode "find")
                    )
                )
                (ChoiceLink
                    (ReferenceLink
                        (VariableNode "$V")
                        (WordNode "at")
                    )
                    (ReferenceLink
                        (VariableNode "$V")
                        (WordNode "around")
                    )
                )
                (ReferenceLink
                    (VariableNode "$W")
                    (VariableNode "$X")
                )
                (ReferenceLink
                    (VariableNode "$Y")
                    (VariableNode "$Z")
                )
                (EvaluationLink
                    (PredicateNode "IsA")
                    (ListLink
                        (VariableNode "$Z")
                        (PhraseNode "time of day")
                    )
                )
            )
        )
        (time-requested-rewrite (ListLink (VariableNode "$X") (VariableNode "$Z")))
        ; To handle cases where a time is mentioned without "am" or "pm",
        ; e.g. 7:30 in the evening
        ; TODO: It's written in this slightly weird way as it seems that LG doesn't
        ; always give the same parse for the Chinese->English translated sentence,
        ; will investigate more and see if this can be improved
        (time-requested-query-2
            (BindLink
                (AndLink
                    (EvaluationLink
                        (PredicateNode (va-prefix "word sequence"))
                        (ListLink
                            (if sentence-node (begin
                                sentence-node
                            ) (begin
                                (VariableNode "$S")
                            ))
                            (ListLink
                                (GlobNode "$wildcard-1")
                                (VariableNode "$verb")
                                (GlobNode "$wildcard-2")
                                (VariableNode "$time")
                                (WordNode "in")
                                (WordNode "the")
                                (VariableNode "$time-period")
                                (GlobNode "$wildcard-3")
                            )
                        )
                    )
                    (EvaluationLink
                        (PredicateNode "IsA")
                        (ListLink
                            (VariableNode "$time-period")
                            (PhraseNode "time of day")
                        )
                    )
                    ; e.g. find
                    (ReferenceLink
                        (VariableNode "$verb-word-inst")
                        (VariableNode "$verb")
                    )
                    (ReferenceLink
                        (VariableNode "$in-word-inst")
                        (WordNode "in")
                    )
                    ; e.g. evening
                    (ReferenceLink
                        (VariableNode "$time-period-word-inst")
                        (VariableNode "$time-period")
                    )
                    (ChoiceLink
                        (ListLink
                            (VariableNode "$verb-word-inst")
                            (VariableNode "$in-word-inst")
                        )
                        (ListLink
                            (VariableNode "$in-word-inst")
                            (VariableNode "$time-period-word-inst")
                        )
                        (ListLink
                            (VariableNode "$time-word-inst")
                            (VariableNode "$in-word-inst")
                        )
                    )
                    (EvaluationLink
                        (GroundedPredicateNode "scm: va-is-time?")
                        (ListLink
                            (VariableNode "$time")
                        )
                    )
                )
                (ListLink
                    (VariableNode "$time")
                    (VariableNode "$time-period")
                )
            )
        )
        (specific-time-query
            ; To handle e.g.
            ;   +-ND-+
            ;   |    |
            ;   5:30 pm
            (AndLink
                (if sentence-node (begin (list
                    (ParseLink
                        (VariableNode "$P")
                        sentence-node
                    )
                    (WordInstanceLink
                        (VariableNode "$W")
                        (VariableNode "$P")
                    )
                    (WordInstanceLink
                        (VariableNode "$Y")
                        (VariableNode "$P")
                    )
                )) (begin
                    (list)
                ))
                (ReferenceLink
                    (VariableNode "$W")
                    (VariableNode "$X")
                )
                (ReferenceLink
                    (VariableNode "$Y")
                    (VariableNode "$Z")
                )
                (EvaluationLink
                    (LinkGrammarRelationshipNode "ND")
                    (ListLink
                        (VariableNode "$W")
                        (VariableNode "$Y")
                    )
                )
                (EvaluationLink
                    (PredicateNode "IsA")
                    (ListLink
                        (VariableNode "$Z")
                        (PhraseNode "time of day")
                    )
                )
            )
        )
        (time-query
            ; e.g. morning, afternoon, evening, night etc
            (AndLink
                (if sentence-node (begin (list
                    (ParseLink
                        (VariableNode "$P")
                        sentence-node
                    )
                    (WordInstanceLink
                        (VariableNode "$X")
                        (VariableNode "$P")
                    )
                )) (begin
                    (list)
                ))
                (ReferenceLink
                    (VariableNode "$X")
                    (VariableNode "$Y")
                )
                (EvaluationLink
                    (PredicateNode "IsA")
                    (ListLink
                        (VariableNode "$Y")
                        (PhraseNode "time of day")
                    )
                )
            )
        )
        (indirect-time-query
            ; e.g. dinner -> evening etc
            (BindLink
                (AndLink
                    (if sentence-node (begin (list
                        (ParseLink
                            (VariableNode "$P")
                            sentence-node
                        )
                        (WordInstanceLink
                            (VariableNode "$X")
                            (VariableNode "$P")
                        )
                    )) (begin
                        (list)
                    ))
                    (ReferenceLink
                        (VariableNode "$X")
                        (VariableNode "$Y")
                    )
                    (EvaluationLink
                        (PredicateNode "RelatedTo")
                        (ListLink
                            (VariableNode "$Y")
                            (VariableNode "$Z")
                        )
                    )
                    (EvaluationLink
                        (PredicateNode "IsA")
                        (ListLink
                            (VariableNode "$Z")
                            (PhraseNode "time of day")
                        )
                    )
                )
                (VariableNode "$Z")
            )
        )
    ) (begin
        (let* (
            (time-in-request-1 (va-flat-node-list (cog-execute! (BindLink time-requested-query-1 time-requested-rewrite)) 'WordNode))
            (time-in-request-2
                (if (null? time-in-request-1) (begin
                    (va-flat-node-list (cog-execute! time-requested-query-2) 'WordNode)
                ) (begin
                    (list)
                ))
            )
            (specific-time
                (if (null? time-in-request-2) (begin
                    (va-flat-node-list (cog-execute! (GetLink specific-time-query)) 'WordNode)
                ) (begin
                    (list)
                ))
            )
            (time-period-1
                (if (null? specific-time) (begin
                    (va-flat-node-list (cog-execute! (GetLink time-query)) 'WordNode)
                ) (begin
                    (list)
                ))
            )
            (time-period-2
                (if (null? time-period-1) (begin
                    (cog-outgoing-set (cog-execute! indirect-time-query))
                ) (begin
                    (list)
                ))
            )
        ) (begin
            (cond
                ((not (null? time-in-request-1)) (begin
                    (va-remove-generic-fact "user-mentioned-time")
                    (va-add-generic-fact-1 "user-mentioned-time"
                        (WordNode (string-append (cog-name (list-ref time-in-request-1 0)) (cog-name (list-ref time-in-request-1 1)))))
                ))
                ((not (null? time-in-request-2)) (begin
                    (va-remove-generic-fact "user-mentioned-time")
                    (va-add-generic-fact-1 "user-mentioned-time"
                        (WordNode
                            (let ((time (cog-name (car time-in-request-2)))
                                  (time-period (cog-name (cadr time-in-request-2))))
                                (if (string=? "morning" time-period)
                                    (string-append time "am")
                                    (string-append time "pm")
                                )
                            )
                    ))
                ))
                ((not (null? specific-time)) (begin
                    (va-remove-generic-fact "user-mentioned-time")
                    (do ((i 0 (+ i 2))) ((> (+ i 2) (length specific-time)))
                        (va-add-generic-fact-1 "user-mentioned-time"
                            (if (string->number (cog-name (list-ref specific-time i))) (begin
                                (WordNode (string-append (cog-name (list-ref specific-time i)) (cog-name (list-ref specific-time (1+ i)))))
                            ) (begin
                                (WordNode (string-append (cog-name (list-ref specific-time (1+ i))) (cog-name (list-ref specific-time i))))
                            ))
                        )
                    )
                ))
                ((not (null? time-period-1)) (begin
                    (va-remove-generic-fact "user-mentioned-time")
                    (map (lambda (time) (begin
                        (va-add-generic-fact-1 "user-mentioned-time" time)
                    )) time-period-1)
                ))
                ((not (null? time-period-2)) (begin
                    (va-remove-generic-fact "user-mentioned-time")
                    (map (lambda (time) (begin
                        (va-add-generic-fact-1 "user-mentioned-time" time)
                    )) time-period-2)
                ))
            )
            (not (null? (append time-in-request-1 time-in-request-2 specific-time time-period-1 time-period-2)))
        ))
    ))
))
