(va-add-monitored-predicate "user-mentioned-known-person" (lambda () (begin
    (cog-logger-info "Evaluating predicate: user-mentioned-known-person\n")
    (va-debug "Evaluating user-mentioned-known-person\n")
    (let (
        (query-links (list
            (AndLink
                (ReferenceLink
                    (VariableNode "$X")
                    (VariableNode "$Y")
                )
                (EvaluationLink
                    (PredicateNode (va-prefix "name"))
                    (ListLink
                        (VariableNode "$Z")
                        (VariableNode "$Y")
                    )
                )
            )
        ))
    ) (begin
        (let (
            (people (va-flat-node-list (map (lambda (query) (cog-execute! (GetLink query))) query-links) 'PersonNode))
        ) (begin
            (map (lambda (person-node) (begin
                (va-add-generic-fact-1 "user-mentioned-known-person" person-node)
            )) people)
            (not (null? people))
        ))
    ))
)))
