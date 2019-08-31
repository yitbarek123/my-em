(define (va-request-path-components request) 
    (split-and-decode-uri-path (uri-path (request-uri request)))
)

(define (va-templatize title body)
  `(html (head (title ,title)) (body ,@body))
)

(define* (respond #:optional body #:key
                 (status 200)
                 (title "Virtual Assistant")
                 (doctype "<!DOCTYPE html>\n")
                 (content-type-params '((charset . "utf-8")))
                 (content-type 'text/html)
                 (extra-headers '())
                 (sxml (and body (va-templatize title body))))

    (values (build-response
        #:code status
        #:headers `((content-type . (,content-type ,@content-type-params)) ,@extra-headers))
        (lambda (port)
            (if sxml (begin
                (if doctype (display doctype port))
                (sxml->xml sxml port)
            ))
        )
    )
)

(define (va-debug-request request body)
    (respond `(
        (h1 "Debug request")
        (table
            (tr (th "header") (th "value"))
            ,@(map 
                 (lambda (pair)
                   `(tr (td (tt ,(with-output-to-string
                        (lambda () (display (car pair))))))
                    (td (tt ,(with-output-to-string
                       (lambda () (write (cdr pair)))))))
                 )
                 (request-headers request)
            )
        )
    ))
)

(define (va-debug-page) (begin
    (respond `(
        (style 
"
form {
  /* Just to center the form on the page */
  margin: 0 auto;
  width: 600px;
  /* To see the outline of the form */
  padding: 1em;
  border: 1px solid #CCC;
  border-radius: 1em;
}

form div + div {
  margin-top: 1em;
}

label {
  /* To make sure that all labels have the same size and are properly aligned */
  display: inline-block;
  width: 90px;
  text-align: right;
}

input, textarea {
  /* To make sure that all text fields have the same font settings
     By default, textareas have a monospace font */
  font: 1em sans-serif;

  /* To give the same size to all text fields */
  width: 600px;
  box-sizing: border-box;

  /* To harmonize the look & feel of text field border */
  border: 1px solid #999;
}

input:focus, textarea:focus {
  /* To give a little highlight on active elements */
  border-color: #000;
}

textarea {
  /* To properly align multiline text fields with their labels */
  vertical-align: top;

  /* To give enough room to type some text */
  height: 5em;
}

.button {
  /* To position the buttons to the same position of the text fields */
  padding-left: 90px; /* same size as the label elements */
}

button {
  /* This extra margin represent roughly the same space as the space
     between the labels and their text fields */
  margin-left: .5em;
}

/* Dropdown Button */
.dropbtn {
  background-color: white;
  color: black;
  padding: 6px;
  font-size: 12px;
  border: 1px solid #CCC;
}

/* The container <div> - needed to position the dropdown content */
.dropdown {
  position: relative;
  display: inline-block;
}

/* Dropdown Content (Hidden by Default) */
.dropdown-content {
  display: none;
  position: absolute;
  background-color: #f1f1f1;
  min-width: 160px;
  box-shadow: 0px 8px 16px 0px rgba(0,0,0,0.2);
  z-index: 1;
}

/* Links inside the dropdown */
.dropdown-content a {
  color: black;
  padding: 12px 16px;
  text-decoration: none;
  display: block;
}

/* Change color of dropdown links on hover */
.dropdown-content a:hover {background-color: #ddd;}

/* Show the dropdown menu on hover */
.dropdown:hover .dropdown-content {display: block;}

/* Change the background color of the dropdown button when the dropdown content is shown */
.dropdown:hover .dropbtn {background-color: #707070;}
"
)
        (h2 "Virtual Assistant")
        (form (@ (action "/debug") (method "post"))
            (div (input (@ (id "uttr") (name "uttr")) ""))
            (div (button "Send utterance"))
        )
        (h5 "")
        (div (@ (class "dropdown"))
            (button (@ (class "dropbtn")) "Reset")
            (div (@ (class "dropdown-content"))
                (a (@ (href "/reset")) "Reset session")
                (a (@ (href "/restart")) "Restart server")
            )
        )
        (div (@ (class "dropdown"))
            (button (@ (class "dropbtn")) "Engine")
            (div (@ (class "dropdown-content"))
                (a (@ (href "/engine/echo")) "Echo")
                (a (@ (href "/engine/ghost")) "GHOST")
            )
        )
        (h5 ,(with-output-to-string (lambda () (display (format "Engine mode: ~a" va-engine-mode)))))
        (h4 "Predicates")
        (ol
            ,@(map (lambda (elem)
               `(li ,(with-output-to-string (lambda () (display (format "~a: ~a" (car elem) (if (va-is-predicate-true? (car elem)) "TRUE" "FALSE"))))))
            ) va-monitored-predicates)
        )
        (h4 "Conversation history")
        (ol
            ,@(map (lambda (elem)
               `(li ,(with-output-to-string (lambda () (display elem))))
            ) va-conversation-history)
        )
    ))
))
