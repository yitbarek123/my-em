(add-to-load-path "/usr/local/share/opencog/scm")
(add-to-load-path "/opencog/build/opencog/scm/opencog/")
(add-to-load-path "/virtual-assistant/lib/conceptnet")
(add-to-load-path "/virtual-assistant/lib/sumo")

(define-module (virtual-assistant virtual-assistant)
    #:use-module (srfi srfi-1)
    #:use-module (system repl server)
    #:use-module (web server)
    #:use-module (web request)
    #:use-module (web response)
    #:use-module (web uri)
    #:use-module (sxml simple)
    #:use-module (rnrs bytevectors)
    #:use-module (opencog)
    #:use-module (opencog nlp)
    #:use-module (opencog nlp relex2logic)
    #:use-module (opencog openpsi)
    #:use-module (opencog ghost)
    #:use-module (opencog ghost procedures)
    #:use-module (opencog exec)
    #:use-module (opencog logger)
    #:use-module (opencog persist-sql)
    #:use-module (conceptnet)
    #:use-module (sumo)
    #:export (
        va-push-vauttr
        va-pop-vauttr
        va-push-request
        va-setup
        va-prefix
        va-http-port
        request-queue
        vauttr-queue
        va-request-queue-mutex
        va-vauttr-queue-mutex
        va-conversation-history
        va-monitored-predicates
        va-rules
        va-engine-module
        va-debug-flag
        va-command-queue-processing
        va-dialogue-engine-timeout
        va-prefix
        va-true
        va-false
        va-positive
        va-negative
        va-finalize
    )
)

; load dependencies for this module
(load "/virtual-assistant/utils.scm")
(load "/virtual-assistant/web-utils.scm")
(load "/virtual-assistant/http-requests.scm")
(load "/virtual-assistant/language-understanding.scm")

; ----------------------------------------------------------------------
; Helper functions and variables

(define va-http-port 8080)
(define request-queue (list))
(define vauttr-queue (list))
(define va-request-queue-mutex (make-arbiter "va-request-queue-mutex"))
(define va-vauttr-queue-mutex (make-arbiter "va-vauttr-queue-mutex"))
(define va-conversation-history (list))
(define va-monitored-predicates (list))
(define va-rules (list))

(define va-engine-mode "ghost")
(define va-debug-flag #f)
(define va-command-queue-processing #t)
(define va-dialogue-engine-timeout 30) ; seconds

; ----------------------------------------------------------------------
; Logger setup

(cog-logger-set-level! "debug")
(cog-logger-set-filename! "/tmp/virtual-assistant.log")
(cog-logger-set-stdout! #f)

(define (va-prefix node-name) (string-append "VA: " node-name))

; ----------------------------------------------------------------------
; Helper concepts

(define va-true (stv 1 1))
(define va-false (stv 0 1))
(define va-positive (ConceptNode (va-prefix "positive")))
(define va-negative (ConceptNode (va-prefix "negative")))

(define (va-load-action-plan name) (begin
    (load (format "/virtual-assistant/plans/~a/predicates.scm" name))
    (load (format "/virtual-assistant/plans/~a/actions.scm" name))
    (load (format "/virtual-assistant/plans/~a/rules.scm" name))
    (load (format "/virtual-assistant/plans/~a/knowledge.scm" name))
))

(define (va-load-knowledge-bases) (begin
    (load "/virtual-assistant/knowledge/demo.scm")
    (load "/virtual-assistant/knowledge/belo_horizonte/restaurants.scm")
))

(define (va-load-ghost-plan name) (begin
    (load (format "/virtual-assistant/ghost/~a/predicates.scm" name))
    (load (format "/virtual-assistant/ghost/~a/schemas.scm" name))
    (load (format "/virtual-assistant/ghost/~a/rules.scm" name))
))

(define (va-http-handler request body-utf8) (begin
    (let (
        (commands (va-request-path-components request))
        (body (if (equal? body-utf8 #f) "" (utf8->string body-utf8)))
    ) (begin
        (cog-logger-info "New HTTP request - ~s - Commands: ~s - Body: ~s" (request-method request) commands body)
        (cond
            ((equal? commands '()) (begin
                (va-debug-page)
            ))
            ((equal? commands '("restart")) (begin
                (va-restart-server)
            ))
            ((equal? commands '("utterance")) (begin
                (va-process-utterance body #false)
            ))
            ((equal? commands '("debug")) (begin
                (va-process-utterance body #true)
            ))
            ((equal? commands '("echo")) (begin
                (va-process-echo body)
            ))
            ((equal? (car commands) "engine") (begin
                (va-set-engine-mode (cadr commands))
                (va-debug-page)
            ))
            (else (begin
                (va-not-found-404 request)
            ))
        )
    ))
))

(define (spawn-http-server)
    (run-server va-http-handler 'http (list #:addr 0 #:port va-http-port))
)


(define (va-lock mutex)
    (while (not (try-arbiter mutex)) (begin
        (sleep 1)
    ))
)

(define (va-unlock mutex)
    (release-arbiter mutex)
)

(define (va-push-request request)
    (va-lock va-request-queue-mutex)
    (set! request-queue (append request-queue (list request)))
    (va-unlock va-request-queue-mutex)
)

(define (va-pop-request)
    (let (
        (answer '())
    ) (begin
        (va-lock va-request-queue-mutex)
        (if (not (null? request-queue)) (begin
            (set! answer (car request-queue))
            (set! request-queue (cdr request-queue))
        ))
        (va-unlock va-request-queue-mutex)
        answer
    ))
)

(define (va-push-vauttr vauttr)
    (va-debug (format "push utterance: ~s" vauttr))
    (va-lock va-vauttr-queue-mutex)
    (set! vauttr-queue (append vauttr-queue (list vauttr)))
    (va-unlock va-vauttr-queue-mutex)
)

(define (va-pop-vauttr)
    (let (
        (answer "")
    ) (begin
        (va-lock va-vauttr-queue-mutex)
        (if (not (null? vauttr-queue)) (begin
            (set! answer (car vauttr-queue))
            (set! vauttr-queue (cdr vauttr-queue))
            (va-debug (format "pop answer: ~s" answer))
        ))
        (va-unlock va-vauttr-queue-mutex)
        answer
    ))
)

(define (va-request-queue-processing-loop)
    (cog-logger-info "Started request queue processing thread")
    (while va-command-queue-processing (begin
        (let (
            (request (list))
        ) (begin
            (set! request (va-pop-request))
            (if (null? request) (begin
                ;(cog-logger-debug "Request queue empty")
                (sleep 1)
            ) (begin
                (let (
                    (command (car request))
                ) (begin
                    (cond 
                        ((nocase=? command "restart") (begin
                            (set! va-command-queue-processing #f)
                        ))
                        ((nocase=? command "utterance") (begin
                            (va-nlp-process (cadr request))
                        ))
                        (else
                            (cog-logger-warn "Unknown command: ~s" command)
                        )
                    )
                ))
            ))
        ))
    ))
)

(define (va-ghost-setup) (begin
    ; Disable ECAN
    (ghost-set-sti-weight 0)
    (ghost-af-only #f)

    ; Load skill plans
    ;(ghost-debug-mode)
    (va-load-ghost-plan "restaurant-recommendation")
))

(define (va-set-engine-mode mode) (begin
    (if (equal? va-engine-mode "ghost") (begin
        (cog-logger-info "Stopping GHOST engine")
        (ghost-halt)
    ))
    (set! va-engine-mode mode)
    (if (equal? va-engine-mode "ghost") (begin
        (cog-logger-info "Starting GHOST engine")
        (ghost-run)
    ))
))

(define (va-get-host host-name)
	(define hosty (gethost host-name))
    (inet-ntop (hostent:addrtype hosty) (car (hostent:addr-list hosty)))
)

; finalize all engine's procedures
(define (va-finalize)
    ; halt ghost loop
    (ghost-halt)
)

; the includes and loads called here will work in a separate environment and not this module itself
(define (va-setup)

    (use-modules
        (srfi srfi-1)
        (system repl server)
        (web server)
        (web request)
        (web response)
        (web uri)
        (sxml simple)
        (rnrs bytevectors)
        (opencog)
        (opencog nlp)
        (opencog nlp relex2logic)
        (opencog openpsi)
        (opencog ghost)
        (opencog ghost procedures)
        (opencog exec)
        (opencog logger)
        (opencog persist-sql)
        (conceptnet)
        (sumo)
    )

    (load "/virtual-assistant/utils.scm")
    (load "/virtual-assistant/web-utils.scm")
    (load "/virtual-assistant/http-requests.scm")
    (load "/virtual-assistant/language-understanding.scm")

    ; configure conceptnet host address and port
    (cn5-set-conceptnet-server-host (va-get-host (getenv "CONCEPTNET_HOSTNAME")) #:port (string->number (getenv "PORT_CONCEPTNET_SERVER")))

    ; configure opencog relex dependency host address and port
    (use-relex-server (getenv "CONTAINER_RELEX_HOSTNAME") (string->number (getenv "PORT_RELEX_SERVER")))

    ; load ghost only after setting relex and conceptnet servers address
    (va-ghost-setup)

    ; configure va state and variables
    (set! *random-state* (random-state-from-platform))

    ; load knowledge and action plans
    (va-load-knowledge-bases)
    (va-load-action-plan "restaurant-recommendation")
    (va-load-action-plan "known-people-info")

    ; call main loop
    (call-with-new-thread va-request-queue-processing-loop)

    ; call http server
    ; (call-with-new-thread spawn-http-server)

    ; runs ghost
    (ghost-run)
)
