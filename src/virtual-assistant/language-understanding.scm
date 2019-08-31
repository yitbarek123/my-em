(define (va-nlp-process utterance) (begin
    (cond
        ((equal? va-engine-mode "ghost") (begin
            (set! utterance (va-capitalize (string-downcase utterance)))
            (cog-logger-debug "RELEX")
            (release-new-parsed-sents)
            (if (relex-parse utterance) (begin
                (cog-logger-debug "va-enhance-info")
                (va-enhance-info)
                (cog-logger-debug "va-generate-word-sequence")
                (va-generate-word-sequence)
                (cog-logger-debug "va-process-predicates")
                (va-process-predicates)
            ))
            (cog-logger-debug "ghost")
            (ghost utterance)
            (cog-logger-debug "DONE")
        ))
        ((equal? va-engine-mode "action-plans") (begin
            (set! utterance (va-capitalize (string-downcase utterance)))
            (release-new-parsed-sents)
            (if (relex-parse utterance) (begin
                (va-enhance-info)
                (va-generate-word-sequence)
                (va-process-predicates)
            ))
            (if (not (va-process-rules)) (va-push-vauttr "OK"))
        ))
        ((equal? va-engine-mode "echo") (begin
            (va-push-vauttr utterance)
        ))
    )
))

(define (va-capitalize utterance) (begin
    (define (is-known-name? word-lst l-idx r-idx) (begin
        (let* (
            (one-word (string-capitalize (list-ref word-lst l-idx)))
            (multi-word (map string-capitalize (lset-intersection equal? (list-tail (list-head word-lst (1+ r-idx)) l-idx))))
            (candidates (append
                (if (= l-idx r-idx) (append
                    (if (null? (cog-node 'WordNode one-word)) (list) (list (WordNode one-word)))
                    (if (null? (cog-node 'PhraseNode one-word)) (list) (list (PhraseNode one-word)))
                ) (append
                    (if (null? (cog-link 'ListLink (map WordNode multi-word))) (list) (list (ListLink (map WordNode multi-word))))
                    (if (null? (cog-node 'PhraseNode (string-join multi-word))) (list) (list (PhraseNode (string-join multi-word))))
                ))
            ))
        ) (begin
            (or
                (any (lambda (list-link) (begin
                    (or
                        (not (null?
                            (cog-link 'EvaluationLink
                                (PredicateNode (va-prefix "name"))
                                list-link
                            )
                        ))
                        (not (null?
                            (cog-link 'EvaluationLink
                                (PredicateNode (va-prefix "name-in-words"))
                                list-link
                            )
                        ))
                    )
                )) (append-map (lambda (x) (cog-incoming-by-type x 'ListLink)) candidates))
                (any (lambda (node) (begin
                    (or
                        (not (null?
                            (cog-link 'EvaluationLink
                                (PredicateNode "IsA")
                                (ListLink
                                    node
                                    (WordNode "city")
                                )
                            )
                        ))
                        (not (null?
                            (cog-link 'EvaluationLink
                                (PredicateNode "IsA")
                                (ListLink
                                    node
                                    (PhraseNode "a place name")
                                )
                            )
                        ))
                    )
                )) candidates)
            )
        ))
    ))

    (let* (
        (words (string-split utterance #\sp))
        (name-indexes (list))
    ) (begin
        (do ((i 0 (1+ i))) ((= i (length words))) (begin
            (do ((j i (1+ j))) ((= j (length words))) (begin
                (if (is-known-name? words i j) (set! name-indexes (cons (cons i j) name-indexes)))
            ))
        ))

        (va-debug (format #f "Before capitalization: ~s\n" words))

        (for-each (lambda (x) (begin
            (do ((i (car x) (1+ i))) ((> i (cdr x)))
                (list-set! words i (string-capitalize (list-ref words i)))
            )
        )) name-indexes)

        (va-debug (format #f "After capitalization: ~s\n" words))

        (string-join words)
    ))
))

(define (va-generate-word-sequence) (begin
    (for-each (lambda (sentence-node) (begin
        (let* (
            (word-instances (car (sent-get-words-in-order sentence-node)))
            (word-seq
                (append-map (lambda (word-inst) (begin
                    ; Ignore LEFT-WALL and punctuations
                    (if (or (string-prefix? "LEFT-WALL" (cog-name word-inst))
                            (word-inst-match-pos? word-inst "punctuation")
                            (null? (cog-chase-link 'ReferenceLink 'WordNode word-inst)))
                        (list)
                        (cog-chase-link 'ReferenceLink 'WordNode word-inst)
                    )
                )) word-instances)
            )
        ) (begin
            (EvaluationLink
                (PredicateNode (va-prefix "word sequence"))
                (ListLink
                    sentence-node
                    (ListLink word-seq)
                )
            )
        ))
    )) (get-new-parsed-sentences))
))

(define (va-process-predicates) (begin
    (for-each (lambda (pair) (begin
        (let (
            (predicate (car pair))
            (evaluator (cadr pair))
        ) (begin
            (va-set-predicate predicate (evaluator))
            (if (va-is-predicate-true? predicate) (va-debug "true\n") (va-debug "false\n"))
        ))
    )) va-monitored-predicates)
))

(define (va-process-rules) (begin
    (let* (
        (triggered-rules
            (filter-map (lambda (rule) (begin
                (let (
                    (test (car rule))
                    (action (cadr rule))
                ) (begin
                    (if (test) action #f)
                ))
            )) va-rules)
        )
        (selected-rule
            (if (> (length triggered-rules) 0)
                (va-random-select triggered-rules)
                #f
            )
        )
    ) (begin
        (if selected-rule (selected-rule) #f)
    ))
))

(define (va-enhance-info) (begin
    (for-each (lambda (sentence-node) (begin
        (let* (
            (all-categories (split-words-by-syntax-categories sentence-node (list
                ;(list (list "noun") (list "numeric" "pronoun"))
                ;(list (list "verb") (list))
                ;(list (list "adj") (list "numeric"))
                ;(list (list "WORD") (list))
                (list (list "noun") (list))
                (list (list "verb") (list))
                (list (list "adj") (list))
                (list (list "WORD") (list))
            )))
            (nouns (car all-categories))
            (verbs (cadr all-categories))
            (adjs (caddr all-categories))
            (words (cadddr all-categories))
            (word-instance-nodes (va-chase-link (list (list 'ParseLink 'ParseNode) (list 'WordInstanceLink 'WordInstanceNode)) (list sentence-node)))
            (list-links (va-flat-list (map (lambda (w) (cog-get-link 'ListLink 'WordInstanceNode w)) word-instance-nodes)))
        ) (begin
            (va-debug (format "Nouns: ~s\n" nouns))
            (va-debug (format "Verbs: ~s\n" verbs))
            (va-debug (format "Adjs ~s\n" adjs))
            (va-debug (format "Words ~s\n" words))
            (for-each (lambda (node) (begin
                (let* (
                    (link-list
                        (cn5-query node #:language "en" #:languageFilter (list "en"))
                        ;(append
                        ;    (cn5-query node #:language "en" #:languageFilter (list "en"))
                        ;    (sumo-subclasses node)
                        ;    (sumo-superclasses node))
                    )
                ) (begin
                    (for-each (lambda (link) (begin
                        (va-debug (string-delete #\newline (format "~s" link))) (newline)
                        #t
                    )) link-list)
                ))
            )) (append nouns verbs adjs words))
            ;(va-debug word-instance-nodes)
            ;(va-debug "---\n")
            ;(va-debug list-links)
            ;(for-each (lambda (link) (begin
            ;    (va-debug "-----------------------------------------------------\n")
            ;    (va-debug link)
            ;    (va-debug (map (lambda (w) (cog-chase-link 'ReferenceLink 'WordNode w)) (cog-outgoing-set link)))
            ;    (va-debug (cog-chase-link 'EvaluationLink 'DefinedLinguisticRelationshipNode link))
            ;)) list-links)
        ))
    )) (get-new-parsed-sentences))
))

(define (va-is-instance-of-dlcn? word-instance-node concepts)
    (if (null? concepts) (begin
        #f
    ) (begin
        (if (list? concepts) (begin
            (or
                (va-is-instance-of-dlcn? word-instance-node (car concepts))
                (va-is-instance-of-dlcn? word-instance-node (cdr concepts))
            )
        ) (begin
            (if (va-is-a word-instance-node (DefinedLinguisticConceptNode concepts)) (begin
                #t
            ) (begin
                (let (
                    (answer #f)
                ) (begin
                    (for-each (lambda (node) (begin
                        (if (equal? (cog-name node) concepts) (begin
                            (set! answer #t)
                        ))
                    )) (cog-chase-link 'PartOfSpeechLink 'DefinedLinguisticConceptNode word-instance-node))
                    answer
                ))
            ))
        ))
    ))
)

(define (split-words-by-syntax-categories sentence-node category-pairs)
    (let*
        (
            (word-instance-nodes (va-chase-link (list (list 'ParseLink 'ParseNode) (list 'WordInstanceLink 'WordInstanceNode)) (list sentence-node)))
        )
        (begin
            (map (lambda (pair) (begin
                (filter-map (lambda (word-instance-node) (begin
                    (if (and
                            (va-is-instance-of-dlcn? word-instance-node (car pair))
                            (not (va-is-instance-of-dlcn? word-instance-node (cadr pair)))
                        ) (begin
                            (let (
                                (lemmas (cog-chase-link 'LemmaLink 'WordNode word-instance-node))
                            ) (begin
                                (if (null? lemmas) #f (car lemmas))
                            ))
                        ) (begin
                            #f
                        )
                    )
                )) word-instance-nodes)
            )) category-pairs)
        )
    )
)
