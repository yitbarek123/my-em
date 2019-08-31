(define va-predicates-hashtable (make-hash-table 1000))

(define (va-set-predicate name value) (begin
    ;(StateLink (AnchorNode (va-predicate-prefix name)) (if value va-true va-false))
    (hash-set! va-predicates-hashtable name value)
))

(define (va-is-predicate-true? name) (begin
    (cdr (hash-get-handle va-predicates-hashtable name))
))

(define (va-add-monitored-predicate predicate evaluator) (begin
    (va-set-predicate predicate #f)
    (set! va-monitored-predicates (append va-monitored-predicates
        (list (list predicate evaluator))
    ))
))

(define (va-add-rule test action) (begin
    (set! va-rules (append va-rules
        (list (list test action))
    ))
))

(define (va-current-timestamp)
    (strftime "%b %d - %H:%M" (localtime (current-time)))
)

(define (va-add-to-conversation-history who utterance)
    (set! va-conversation-history (append va-conversation-history
        (list (format "(~a) ~a: ~s" (va-current-timestamp) who utterance))
    ))
)

(define (va-get-one-level-inherits-from base)
    (let ((answer (list))) (begin
        (for-each (lambda (link) (begin
            (if (and (equal? (cog-type link) 'InheritanceLink) (equal? (car (cog-outgoing-set link)) base)) (begin
                (set! answer (append answer (cdr (cog-outgoing-set link))))
            ))
        )) (cog-incoming-set base))
        answer
    ))
)

(define (va-is-a base target)
    (if (equal? base target) (begin
        #t
    ) (begin
        (let ((answer #f)) (begin
            (for-each (lambda (node) (begin
                (if (va-is-a node target) (set! answer #t))
            )) (va-get-one-level-inherits-from base))
            answer
        ))
    ))
)

(define (va-flat-list arg)
    (let (
        (answer (list))
    ) (begin
        (if (list? arg) (begin
            (for-each (lambda (atom) (begin
                (set! answer (append answer (va-flat-list atom)))
            )) arg)
        ) (begin
            (set! answer (append answer (list arg)))
        ))
        answer
    ))
)

(define (va-flat-node-list arg type)
    (let (
        (answer (list))
    ) (begin
        (if (list? arg) (begin
            (for-each (lambda (atom) (begin
                (set! answer (append answer (va-flat-node-list atom type)))
            )) arg)
        ) (begin
            (if (cog-link? arg) (begin
                (for-each (lambda (atom) (begin
                    (set! answer (append answer (va-flat-node-list atom type)))
                )) (cog-outgoing-set arg))
            ) (begin
                (if (cog-subtype? type (cog-type arg)) (begin
                    (set! answer (append answer (list arg)))
                ))
            ))
        ))
        answer
    ))
)

(define (va-chase-link path seed-anchor-list)
    (fold (lambda (pair anchor-list) (begin
        (va-flat-list (map (lambda (anchor-node) (cog-chase-link (car pair) (cadr pair) anchor-node)) anchor-list))
    )) seed-anchor-list path)
)

(define (nocase=? str1 str2)
    (string=? (string-downcase str1) (string-downcase str2))
)


(define (va-random-select elements)
    (if (list? elements) (begin
        (let* (
            (N (length elements))
            (s (random N))
        ) (begin
            (car (list-tail elements s))
        ))
    ) (begin
        elements
    ))
)

(define (va-random-select-up-to-n n elements)
    (if (list? elements) (begin
        (let* (
            (N (length elements))
            (selected '())
        ) (begin
            (if (> n N) (begin
                elements
            ) (begin
                (while (< (length selected) n) (begin
                    (set! selected (append selected (list (va-random-select elements))))
                ))
                (delete-duplicates selected)
            ))
        ))
    ) (begin
        '()
    ))
)

(define (va-add-generic-fact-2 tag tgt1 tgt2) (begin
    (EvaluationLink
        (PredicateNode (va-prefix tag))
        (ListLink
            tgt1
            tgt2
        )
    )
))

(define (va-add-generic-fact-1 tag tgt) (begin
    (EvaluationLink
        (PredicateNode (va-prefix tag))
        (ListLink
            tgt
        )
    )
))

(define (va-add-generic-fact-0 tag) (begin
    (EvaluationLink
        (PredicateNode (va-prefix tag))
        (ListLink
        )
    )
))

(define (va-remove-generic-fact tag) (begin
    (for-each (lambda (filtered-elink) (begin
        (cog-delete-recursive filtered-elink)
    )) (begin
        (filter (lambda (elink) (begin
            (every (lambda (node) (begin
                (and (not (equal? 'VariableNode (cog-type node))) (not (equal? 'GlobNode (cog-type node))))
            )) (cog-outgoing-set (gdr elink)))
        )) (cog-incoming-by-type (PredicateNode (va-prefix tag)) 'EvaluationLink))
    ))
))

(define (va-is-fact-in-context? tag) (begin
    (not (null-list?
        (cog-chase-link 'EvaluationLink 'ListLink (PredicateNode (va-prefix tag)))
    ))
))

(define (va-fact-exist? tag . var-types) (begin
    (equal?
        va-true
        (cog-evaluate!
            (SatisfactionLink
                (TypedVariableLink
                    (GlobNode "$X")
                    (TypeChoice
                        (map (lambda (type) (begin
                            (TypeNode (symbol->string type))
                        )) var-types)
                    )
                )
                (EvaluationLink
                    (PredicateNode (va-prefix tag))
                    (ListLink
                        (GlobNode "$X")
                    )
                )
            )
        )
    )
))

(define (va-debug str)
    (cog-logger-debug str)
    (if va-debug-flag (display str))
)

(define (va-split-phrase s)
    (string-tokenize s char-set:letter+digit)
)

(define (va-eval-sentiment word-node) (begin
    (let* (
        (wi-node (car (cog-chase-link 'ReferenceLink 'WordInstanceNode word-node)))
        (query-links (list
            ; e.g. no $(wi-node)
            (AndLink
                (ListLink
                    (VariableNode "$Y")
                    wi-node
                )
                (ReferenceLink
                    (VariableNode "$Y")
                    (WordNode "no")
                )
            )
            ; e.g. anything but/except $(wi-node)
            (AndLink
                (ListLink
                    (VariableNode "$Y")
                    wi-node
                )
                (ChoiceLink
                    (ReferenceLink
                        (VariableNode "$Y")
                        (WordNode "but")
                    )
                    (ReferenceLink
                        (VariableNode "$Y")
                        (WordNode "except")
                    )
                )
            )
            ; e.g. except for $(wi-node)
            (AndLink
                (ListLink
                    (VariableNode "$X")
                    (VariableNode "$Y")
                )
                (ListLink
                    (VariableNode "$Y")
                    wi-node
                )
                (ReferenceLink
                    (VariableNode "$X")
                    (WordNode "except")
                )
                (ReferenceLink
                    (VariableNode "$Y")
                    (WordNode "for")
                )
            )
            ; e.g. anything other than $(wi-node)
            (AndLink
                (ListLink
                    (VariableNode "$Y")
                    (VariableNode "$Z")
                )
                (ListLink
                    (VariableNode "$Z")
                    wi-node
                )
                (ReferenceLink
                    (VariableNode "$Y")
                    (WordNode "other")
                )
                (ReferenceLink
                    (VariableNode "$Z")
                    (WordNode "than")
                )
            )
            ; e.g. not want/like $(wi-node)
            (AndLink
                (ListLink
                    (VariableNode "$X")
                    (VariableNode "$Y")
                )
                (ListLink
                    (VariableNode "$X")
                    (VariableNode "$Z")
                )
                (ListLink
                    (VariableNode "$Z")
                    wi-node
                )
                (ChoiceLink
                    (ReferenceLink
                        (VariableNode "$X")
                        (WordNode "do")
                    )
                    (ReferenceLink
                        (VariableNode "$X")
                        (WordNode "does")
                    )
                )
                (ReferenceLink
                    (VariableNode "$Y")
                    (WordNode "not")
                )
                (ChoiceLink
                    (ReferenceLink
                        (VariableNode "$Z")
                        (WordNode "want")
                    )
                    (ReferenceLink
                        (VariableNode "$Z")
                        (WordNode "like")
                    )
                )
            )
            ; e.g. don't/doesn't want/like $(wi-node)
            (AndLink
                (ListLink
                    (VariableNode "$Y")
                    (VariableNode "$Z")
                )
                (ListLink
                    (VariableNode "$Z")
                    wi-node
                )
                (ChoiceLink
                    (ReferenceLink
                        (VariableNode "$Y")
                        (WordNode "don't")
                    )
                    (ReferenceLink
                        (VariableNode "$Y")
                        (WordNode "doesn't")
                    )
                )
                (ChoiceLink
                    (ReferenceLink
                        (VariableNode "$Z")
                        (WordNode "want")
                    )
                    (ReferenceLink
                        (VariableNode "$Z")
                        (WordNode "like")
                    )
                )
            )
            ; e.g. I've had too much/many $(wi-node)
            (AndLink
                (ListLink
                    (VariableNode "$X")
                    wi-node
                )
                (ListLink
                    (VariableNode "$Y")
                    (VariableNode "$Z")
                )
                (ListLink
                    (VariableNode "$Z")
                    wi-node
                )
                (ReferenceLink
                    (VariableNode "$X")
                    (WordNode "had")
                )
                (ReferenceLink
                    (VariableNode "$Y")
                    (WordNode "too")
                )
                (ChoiceLink
                    (ReferenceLink
                        (VariableNode "$Z")
                        (WordNode "much")
                    )
                    (ReferenceLink
                        (VariableNode "$Z")
                        (WordNode "many")
                    )
                )
            )
        ))
    ) (begin
        (not (fold
            ;(lambda (link flag) (begin
            ;    (display "=========================================\n")
            ;    (display link)
            ;    (if flag
            ;        (begin (display "shortcut TRUE\n") #t)
            ;        (begin (display (> (length (cog-outgoing-set (cog-execute! (GetLink link)))) 0)) (newline) (> (length (cog-outgoing-set (cog-execute! (GetLink link)))) 0))
            ;    )
            ;))
            (lambda (link flag)
                (if flag
                    #t
                    (> (length (cog-outgoing-set (cog-execute! (GetLink link)))) 0)
                )
            )
            #f
            query-links
        ))
    ))
))

(define (va-str-list word-node-list separator last-separator) (begin
    (let* (
        (count 0)
        (n (length word-node-list))
        (nm1 (- n 1))
        (nm2 (- n 2))
        (answer '())
        (word-list (map (lambda (wn) (cog-name wn)) word-node-list))
    ) (begin
        (while (< count n) (begin
            (if (< count nm1)
                (if (< count nm2)
                    (set! answer (append answer (list (car word-list) separator)))
                    (set! answer (append answer (list (car word-list) last-separator)))
                )
                (set! answer (append answer (list (car word-list))))
            )
            (set! count (+ count 1))
            (set! word-list (cdr word-list))
        ))
        (string-join answer "")
    ))
))


(define (va-sort-weighted-pair pairs)
    (sort-list pairs
        (lambda (pair1 pair2) (begin
            (> (car pair1) (car pair2))
        ))
    )
)

(define (va-reversed-sort-weighted-pair pairs)
    (sort-list pairs
        (lambda (pair1 pair2) (begin
            (< (car pair1) (car pair2))
        ))
    )
)

(define (va-get-mapped-value anchor predicate) (begin
    (car (va-flat-node-list (cog-execute! (GetLink
        (EvaluationLink
            (PredicateNode (va-prefix predicate))
            (ListLink
                anchor
                (VariableNode "$X")
            )
        )
    )) 'Node))
))

(define (va-get-restaurant-name restaurant) (begin
    (define name-chinese
        (cog-outgoing-set (cog-execute!
            (GetLink
                (TypedVariableLink
                    (VariableNode "$CN")
                    (TypeNode "PhraseNode")
                )
                (EvaluationLink
                    (PredicateNode "VA: name-chinese")
                    (ListLink
                        restaurant
                        (VariableNode "$CN")
                    )
                )
            )
        ))
    )

    ; TODO: Here it just assumes that a name in Chinese is preferred, so we'll need to find a good way
    ;       to make it more generic in the long run...
    (if (null? name-chinese)
        (va-get-mapped-value restaurant "name")
        (car name-chinese)
    )
))

(define-public (va-is-time? word) (begin
    (if (string-match "^[0-9]+:*[0-9]*$" (cog-name word))
        (stv 1 1)
        (stv 0 1)
    )
))

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
        (if (null? results) ("") results)
    ))
))
