(va-add-rule
    (lambda () 
        (and
            (not (va-is-fact-in-context? "va-recommended-restaurant"))
            (va-is-predicate-true? "user-requested-restaurant-recommendation")
            (or
                (va-is-predicate-true? "user-mentioned-cuisine")
                (va-is-fact-in-context? "va-asked-cuisine")
            )
        )
    )
    (lambda () (begin
        ;(va-push-vauttr "I'm ready to make a recommendation")
        (let (
            (restaurant-list (va-make-restaurant-recommendation))
        ) (begin
            (va-debug (format "~s" restaurant-list))
            (va-add-generic-fact-1 "va-recommended-restaurant" (AnchorNode "restaurant1"))
        ))
        #t
    ))
)

(va-add-rule
    (lambda () 
        (and
            (not (va-is-fact-in-context? "va-asked-cuisine"))
            (va-is-predicate-true? "user-requested-restaurant-recommendation")
            (not (va-is-fact-in-context? "va-recommended-restaurant"))
            (not (va-is-predicate-true? "user-mentioned-cuisine"))
        )
    )
    (lambda () (begin
        (let* (
            (cuisines (va-infer-cuisines))
            (selected (va-random-select-up-to-n 3 cuisines))
        ) (begin
            (if (null? selected)
                (va-push-vauttr "What do you want to eat?")
                (va-push-vauttr (string-append (va-str-list selected ", " " or ") "? Or something different?"))
            )
        ))
        (va-add-generic-fact-0 "va-asked-cuisine")
        #t
    ))
)
