(define (va-not-found-404 request)
    (values 
        (build-response #:code 404)
        (string-append "Resource not found: " (uri->string (request-uri request)))
    )
)

(define (va-restart-server) (begin
    (va-push-request (list "restart"))
    (values 
        (build-response)
        (string-append "Server restarting. Wait 10 seconds before reloading.")
    )
))

(define (va-process-utterance body debug?) (begin
    (let (
        (utterance (uri-decode (substring body 5)))
    ) (begin
        (cog-logger-info "User utterance: ~s" utterance)
        (va-push-request (list "utterance" utterance))

        (let (
            (vauttr (va-pop-vauttr))
            (timeout va-dialogue-engine-timeout)
        ) (begin
            (while (null? vauttr) (begin
                (if (equal? timeout 0) (begin
                    (set! vauttr "OK")
                ) (begin
                    (sleep 1)
                    (set! vauttr (va-pop-vauttr))
                    (set! timeout (- timeout 1))
                ))
            ))
            (va-add-to-conversation-history "user" utterance)
            (va-add-to-conversation-history "VA" vauttr)
            (cog-logger-info "VA utterance: ~s" vauttr)
            (if debug? 
                (va-debug-page) 
                (values '((content-type . (text/plain))) vauttr)
            )
        ))
    ))
))

(define (va-process-echo body) (begin
    (let (
        (utterance (uri-decode (substring body 5)))
    ) (begin
        (cog-logger-info "Echo request: ~s" utterance)
        (va-add-to-conversation-history "user" utterance)
        (va-add-to-conversation-history "VA" utterance)
        (values '((content-type . (text/plain))) utterance)
    ))
))
