;;; -*-Scheme-*-
;;;
;;; $Id: imail-imap.scm,v 1.18 2000/05/05 17:18:14 cph Exp $
;;;
;;; Copyright (c) 1999-2000 Massachusetts Institute of Technology
;;;
;;; This program is free software; you can redistribute it and/or
;;; modify it under the terms of the GNU General Public License as
;;; published by the Free Software Foundation; either version 2 of the
;;; License, or (at your option) any later version.
;;;
;;; This program is distributed in the hope that it will be useful,
;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;;; General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with this program; if not, write to the Free Software
;;; Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

;;;; IMAIL mail reader: IMAP back end

(declare (usual-integrations))

;;;; URL

(define-class (<imap-url>
	       (constructor (user-id auth-type host port mailbox uid)))
    (<url>)
  ;; User name to connect as.
  (user-id define accessor)
  ;; Type of authentication to use.  Ignored.
  (auth-type define accessor)
  ;; Name or IP address of host to connect to.
  (host define accessor)
  ;; Port number to connect to.
  (port define accessor)
  ;; Name of mailbox to access.
  (mailbox define accessor)
  ;; Unique ID specifying a message.  Ignored.
  (uid define accessor))

(define-url-protocol "imap" <imap-url>
  (let ((//server/
	 (optional-parser
	  (sequence-parser (noise-parser (string-matcher "//"))
			   imap:parse:server
			   (noise-parser (string-matcher "/")))))
	(mbox (optional-parser imap:parse:simple-message)))
    (lambda (string)
      (let ((end (string-length string)))
	(let ((pv1 (//server/ string 0 end)))
	  (let ((pv2
		 (or (parse-substring mbox string (car pv1) end)
		     (error:bad-range-argument string 'STRING->URL))))
	    (make-imap-url (parser-token pv1 'USER-ID)
			   (parser-token pv1 'AUTH-TYPE)
			   (parser-token pv1 'HOST)
			   (let ((port (parser-token pv1 'PORT)))
			     (and port
				  (string->number port)))
			   (parser-token pv2 'MAILBOX)
			   (parser-token pv2 'UID))))))))

(define-method url-body ((url <imap-url>))
  (string-append
   (let ((user-id (imap-url-user-id url))
	 (auth-type (imap-url-auth-type url))
	 (host (imap-url-host url))
	 (port (imap-url-port url)))
     (if (or user-id auth-type host port)
	 (string-append
	  "//"
	  (if (or user-id auth-type)
	      (string-append (if user-id
				 (url:encode-string user-id)
				 "")
			     (if auth-type
				 (string-append
				  ";auth="
				  (if (string=? auth-type "*")
				      auth-type
				      (url:encode-string auth-type)))
				 "")
			     "@")
	      "")
	  host
	  (if port
	      (string-append ":" (number->string port))
	      "")
	  "/")
	 ""))
   (url:encode-string (imap-url-mailbox url))
   (let ((uid (imap-url-uid url)))
     (if uid
	 (string-append "/;uid=" uid)
	 ""))))

;;;; Server connection

(define-class (<imap-connection> (constructor (host ip-port user-id))) ()
  (host define accessor)
  (ip-port define accessor)
  (user-id define accessor)
  (port define standard
	initial-value #f)
  (sequence-number define standard
		   initial-value 0)
  (response-queue define accessor
		  initializer (lambda () (cons '() '())))
  (folder define standard
	  accessor selected-imap-folder
	  modifier select-imap-folder
	  initial-value #f))

(define (reset-imap-connection connection)
  (without-interrupts
   (lambda ()
     (set-imap-connection-sequence-number! connection 0)
     (let ((queue (imap-connection-response-queue connection)))
       (set-car! queue '())
       (set-cdr! queue '()))
     (select-imap-folder connection #f))))

(define (next-imap-command-tag connection)
  (let ((n (imap-connection-sequence-number connection)))
    (set-imap-connection-sequence-number! connection (+ n 1))
    (nonnegative-integer->base26-string n 3)))

(define (nonnegative-integer->base26-string n min-length)
  (let ((s
	 (make-string (max (ceiling->exact (/ (log (+ n 1)) (log 26)))
			   min-length)
		      #\A)))
    (let loop ((n n) (i (fix:- (string-length s) 1)))
      (let ((q.r (integer-divide n 26)))
	(string-set! s i (string-ref "ABCDEFGHIJKLMNOPQRSTUVWXYZ" (cdr q.r)))
	(if (not (= (car q.r) 0))
	    (loop (car q.r) (fix:- i 1)))))
    s))

(define (enqueue-imap-response connection response)
  (let ((queue (imap-connection-response-queue connection)))
    (let ((next (cons response '())))
      (without-interrupts
       (lambda ()
	 (if (pair? (cdr queue))
	     (set-cdr! (cdr queue) next)
	     (set-car! queue next))
	 (set-cdr! queue next))))))

(define (dequeue-imap-responses connection)
  (let ((queue (imap-connection-response-queue connection)))
    (without-interrupts
     (lambda ()
       (let ((responses (car queue)))
	 (set-car! queue '())
	 (set-cdr! queue '())
	 responses)))))

(define (get-imap-connection url)
  (let ((host (imap-url-host url))
	(ip-port (imap-url-port url))
	(user-id (or (imap-url-user-id url) (imail-default-user-id))))
    (let loop ((connections memoized-imap-connections) (prev #f))
      (if (weak-pair? connections)
	  (let ((connection (weak-car connections)))
	    (if connection
		(if (and (string-ci=? (imap-connection-host connection) host)
			 (eqv? (imap-connection-ip-port connection) ip-port)
			 (string=? (imap-connection-user-id connection)
				   user-id))
		    (begin
		      (guarantee-imap-connection-open connection)
		      connection)
		    (loop (weak-cdr connections) connections))
		(let ((next (weak-cdr connections)))
		  (if prev
		      (weak-set-cdr! prev next)
		      (set! memoized-imap-connections next))
		  (loop next prev))))
	  (let ((connection (make-imap-connection host ip-port user-id)))
	    (set! memoized-imap-connections
		  (weak-cons connection memoized-imap-connections))
	    (guarantee-imap-connection-open connection)
	    connection)))))

(define memoized-imap-connections '())

(define (guarantee-imap-connection-open connection)
  (if (imap-connection-port connection)
      #f
      (let ((host (imap-connection-host connection))
	    (ip-port (imap-connection-ip-port connection))
	    (user-id (imap-connection-user-id connection)))
	(let ((port
	       (open-tcp-stream-socket host (or ip-port "imap2") #f "\n")))
	  (read-line port)	;discard server announcement
	  (set-imap-connection-port! connection port)
	  (reset-imap-connection connection)
	  (let ((response
		 (authenticate host user-id
		   (lambda (passphrase)
		     (imap:command:login connection user-id passphrase)))))
	    (if (imap:response:no? response)
		(begin
		  (close-imap-connection connection)
		  (error "Unable to log in:" response))))
	  (if (not (memq 'IMAP4REV1 (imap:command:capability connection)))
	      (begin
		(close-imap-connection connection)
		(error "Server doesn't support IMAP4rev1:" host))))
	#t)))

(define (close-imap-connection connection)
  (let ((port (imap-connection-port connection)))
    (if port
	(begin
	  (close-port port)
	  (set-imap-connection-port! connection #f))))
  (reset-imap-connection connection))

(define (imap-connection-open? connection)
  (imap-connection-port connection))

;;;; Folder datatype

(define-class (<imap-folder> (constructor (url connection))) (<folder>)
  (connection define accessor)
  (allowed-flags define standard)
  (permanent-flags define standard)
  (permanent-keywords? define standard)
  (uidvalidity define standard)
  (first-unseen define standard)
  (messages define standard initial-value '#()))

(define-class <imap-message> (<message>)
  (uid define accessor)
  (length define accessor)
  (envelope define accessor))

(define make-imap-message
  (let ((constructor
	 (instance-constructor <imap-message>
			       '(HEADER-FIELDS BODY FLAGS PROPERTIES
					       UID LENGTH ENVELOPE))))
    (lambda (uid flags length envelope)
      (constructor 'UNCACHED 'UNCACHED (map imap-flag->imail-flag flags)
		   '() uid length envelope))))

(let ((demand-loader
       (lambda (generic slot-name item-name noun transform)
	 (let ((modifier (slot-modifier <imap-message> slot-name)))
	   (define-method generic ((message <imap-message>))
	     (if (eq? 'UNCACHED (call-next-method message))
		 (modifier
		  message
		  (transform
		   (translate-string-line-endings
		    (car
		     (let ((index (message-index message)))
		       ((imail-message-wrapper "Reading " noun
					       " for message "
					       (number->string (+ index 1)))
			(lambda ()
			  (imap:command:fetch (imap-folder-connection
					       (message-folder message))
					      index
					      (list item-name))))))))))
	     (call-next-method message))))))
  (demand-loader message-header-fields 'HEADER-FIELDS 'RFC822.HEADER "headers"
		 (lambda (string)
		   (lines->header-fields
		    (except-last-pair! (string->lines string)))))
  (demand-loader message-body 'BODY 'RFC822.TEXT "body" identity-procedure))

(define-method set-message-flags! ((message <imap-message>) flags)
  (call-next-method message flags)
  (let ((old-flags (message-flags message))
	(folder (message-folder message))
	(index (message-index message)))
    (let ((connection (imap-folder-connection folder))
	  (diff
	   (lambda (f1 f2)
	     (map imail-flag->imap-flag
		  (list-transform-positive (flags-difference f1 f2)
		    (let ((flags (imap-folder-permanent-flags folder))
			  (keywords? (imap-folder-permanent-keywords? folder)))
		      (lambda (flag)
			(if (string-prefix? "\\" flag)
			    (flags-member? flag flags)
			    keywords?))))))))
      (imap:command:store-flags+ connection index (diff flags old-flags))
      (imap:command:store-flags- connection index (diff old-flags flags)))))

(define (flags-difference f1 f2)
  (if (pair? f1)
      (if (flags-member? (car f1) f2)
	  (flags-difference (cdr f1) f2)
	  (cons (car f1) (flags-difference (cdr f1) f2)))
      '()))

(define (imap-flag->imail-flag flag)
  (case flag
    ((\ANSWERED) "answered")
    ((\DELETED) "deleted")
    ((\SEEN) "seen")
    (else (symbol->string flag))))

(define (imail-flag->imap-flag flag)
  (cond ((string-ci=? flag "answered") '\ANSWERED)
	((string-ci=? flag "deleted") '\DELETED)
	((string-ci=? flag "seen") '\SEEN)
	(else (intern flag))))

(define (reset-imap-folder! folder)
  (without-interrupts
   (lambda ()
     (for-each-vector-element (imap-folder-messages folder) detach-message)
     (set-imap-folder-allowed-flags! folder '())
     (set-imap-folder-permanent-flags! folder '())
     (set-imap-folder-permanent-keywords?! folder #f)
     (set-imap-folder-uidvalidity! folder #f)
     (set-imap-folder-first-unseen! folder #f)
     (set-imap-folder-messages! folder '#()))))

(define (set-imap-folder-length! folder count)
  (let ((v (imap-folder-messages folder)))
    (let ((v* (vector-grow v count #f)))
      (fill-messages-vector folder v* (vector-length v))
      (set-imap-folder-messages! folder v*)))
  (folder-modified! folder))

(define (forget-imap-folder-messages! folder)
  (let ((v (imap-folder-messages folder)))
    (for-each-vector-element v detach-message)
    (fill-messages-vector folder v 0))
  (folder-modified! folder))

(define (fill-messages-vector folder messages start)
  (let ((connection (imap-folder-connection folder))
	(end (vector-length messages)))
    (do ((responses
	  ((imail-message-wrapper "Reading message outlines")
	   (lambda ()
	     (imap:command:fetch-range connection 0 end
				       '(UID FLAGS RFC822.SIZE ENVELOPE))))
	  (cdr responses))
	 (index start (fix:+ index 1)))
	((fix:= index end))
      (let ((message (apply make-imap-message (car responses))))
	(set-message-folder! message folder)
	(set-message-index! message index)
	(vector-set! messages index message)))))

(define (remove-imap-folder-message folder index)
  (let ((v (imap-folder-messages folder)))
    (detach-message (vector-ref v index))
    (let ((end (vector-length v)))
      (let ((v* (make-vector (fix:- end 1))))
	(subvector-move-left! v 0 index v* 0)
	(subvector-move-left! v (fix:+ index 1) end v* index)
	(set-imap-folder-messages! folder v*))))
  (folder-modified! folder))

;;;; Server operations

(define-method %new-folder ((url <imap-url>))
  ???)

(define-method %delete-folder ((url <imap-url>))
  ???)

(define-method %move-folder ((url <imap-url>) (new-url <imap-url>))
  ???)

(define-method %copy-folder ((url <imap-url>) (new-url <imap-url>))
  ???)

(define-method available-folder-names ((url <imap-url>))
  ???)

;;;; Folder operations

(define-method %open-folder ((url <imap-url>))
  (let ((folder (make-imap-folder url (get-imap-connection url))))
    (guarantee-imap-folder-open folder)
    folder))

(define (guarantee-imap-folder-open folder)
  (let ((connection (imap-folder-connection folder)))
    (and (guarantee-imap-connection-open connection)
	 (begin
	   (reset-imap-folder! folder)
	   (select-imap-folder connection folder)
	   (if (not
		(imap:command:select connection
				     (imap-url-mailbox (folder-url folder))))
	       (select-imap-folder connection #f))
	   #t))))

(define-method close-folder ((folder <imap-folder>))
  (close-imap-connection (imap-folder-connection folder))
  (reset-imap-folder! folder))

(define-method folder-presentation-name ((folder <imap-folder>))
  (imap-url-mailbox (folder-url folder)))

(define-method %folder-valid? ((folder <imap-folder>))
  folder
  #t)

(define-method folder-length ((folder <imap-folder>))
  (guarantee-imap-folder-open folder)
  (vector-length (imap-folder-messages folder)))

(define-method %get-message ((folder <imap-folder>) index)
  (guarantee-imap-folder-open folder)
  (vector-ref (imap-folder-messages folder) index))

(define-method first-unseen-message ((folder <imap-folder>))
  (guarantee-imap-folder-open folder)
  (let ((unseen (imap-folder-first-unseen folder)))
    (and unseen
	 (get-message folder unseen))))

(define-method append-message ((folder <imap-folder>) (message <message>))
  (guarantee-imap-folder-open folder)
  ???)

(define-method expunge-deleted-messages ((folder <imap-folder>))
  (guarantee-imap-folder-open folder)
  (imap:command:expunge (imap-folder-connection folder)))

(define-method search-folder ((folder <imap-folder>) criteria)
  (guarantee-imap-folder-open folder)
  ???)

(define-method folder-sync-status ((folder <imap-folder>))
  ;; Changes are always written through.
  folder
  'SYNCHRONIZED)

(define-method save-folder ((folder <imap-folder>))
  ;; Changes are always written through.
  folder
  unspecific)

(define-method discard-folder-cache ((folder <imap-folder>))
  (close-imap-connection (imap-folder-connection folder))
  (reset-imap-folder! folder))

;;;; IMAP command invocation

(define (imap:command:capability connection)
  (imap:response:capabilities
   (imap:command:single-response imap:response:capability?
				 connection 'CAPABILITY)))

(define (imap:command:login connection user-id passphrase)
  ((imail-message-wrapper "Logging in as " user-id)
   (lambda ()
     (imap:command:no-response connection 'LOGIN user-id passphrase))))

(define (imap:command:select connection mailbox)
  ((imail-message-wrapper "Select mailbox " mailbox)
   (lambda ()
     (imap:response:ok?
      (imap:command:no-response connection 'SELECT mailbox)))))

(define (imap:command:fetch connection index items)
  (let ((response
	 (imap:command:single-response imap:response:fetch?
				       connection 'FETCH (+ index 1) items)))
    (map (lambda (item)
	   (imap:response:fetch-attribute response item))
	 items)))

(define (imap:command:fetch-range connection start end items)
  (if (fix:< start end)
      (map (lambda (response)
	     (map (lambda (item)
		    (imap:response:fetch-attribute response item))
		  items))
	   (imap:command:multiple-response imap:response:fetch?
					   connection 'FETCH
					   (cons 'ATOM
						 (string-append
						  (number->string (+ start 1))
						  ":"
						  (number->string end)))
					   items))
      '()))

(define (imap:command:uid-fetch connection uid items)
  (let ((response
	 (imap:command:single-response imap:response:fetch?
				       connection 'UID 'FETCH uid items)))
    (map (lambda (item)
	   (imap:response:fetch-attribute response item))
	 items)))

(define (imap:command:store-flags+ connection index flags)
  (if (pair? flags)
      (imap:command:no-response connection 'STORE index '+FLAGS.SILENT flags)))

(define (imap:command:store-flags- connection index flags)
  (if (pair? flags)
      (imap:command:no-response connection 'STORE index '-FLAGS.SILENT flags)))

(define (imap:command:expunge connection)
  ((imail-message-wrapper "Expunging messages")
   (lambda ()
     (imap:command:no-response connection 'EXPUNGE))))

(define (imap:command:noop connection)
  (imap:command:no-response connection 'NOOP))

(define (imap:command:no-response connection command . arguments)
  (let ((responses (apply imap:command connection command arguments)))
    (if (not (null? (cdr responses)))
	(error "Malformed response from IMAP server:" responses))
    (car responses)))

(define (imap:command:single-response predicate connection command . arguments)
  (let ((responses (apply imap:command connection command arguments)))
    (if (imap:response:ok? (car responses))
	(if (and (pair? (cdr responses))
		 (predicate (cadr responses))
		 (null? (cddr responses)))
	    (cadr responses)
	    (error "Malformed response from IMAP server:" responses))
	(error "Server signalled a command error:" (car responses)))))

(define (imap:command:multiple-response predicate
					connection command . arguments)
  (let ((responses (apply imap:command connection command arguments)))
    (if (imap:response:ok? (car responses))
	(if (for-all? (cdr responses) predicate)
	    (cdr responses)
	    (error "Malformed response from IMAP server:" responses))
	(error "Server signalled a command error:" (car responses)))))

(define (imap:command connection command . arguments)
  (imap:wait-for-tagged-response connection
				 (imap:send-command connection
						    command arguments)
				 command))

(define (imap:send-command connection command arguments)
  (let ((tag (next-imap-command-tag connection))
	(port (imap-connection-port connection)))
    (write-string tag port)
    (write-char #\space port)
    (write command port)
    (for-each (lambda (argument)
		(write-char #\space port)
		(imap:send-command-argument connection tag argument))
	      arguments)
    (write-char #\return port)
    (write-char #\linefeed port)
    (flush-output port)
    tag))

(define (imap:send-command-argument connection tag argument)
  (let ((port (imap-connection-port connection)))
    (let loop ((argument argument))
      (cond ((or (symbol? argument)
		 (exact-nonnegative-integer? argument))
	     (write argument port))
	    ((and (pair? argument)
		  (eq? (car argument) 'ATOM)
		  (string? (cdr argument)))
	     (write-string (cdr argument) port))
	    ((string? argument)
	     (if (imap:string-may-be-quoted? argument)
		 (imap:write-quoted-string argument port)
		 (imap:write-literal-string connection tag argument)))
	    ((list? argument)
	     (write-char #\( port)
	     (if (pair? argument)
		 (begin
		   (loop (car argument))
		   (for-each (lambda (object)
			       (write-char #\space port)
			       (loop object))
			     (cdr argument))))
	     (write-char #\) port))
	    (else (error "Illegal IMAP syntax:" argument))))))

(define (imap:write-literal-string connection tag string)
  (let ((port (imap-connection-port connection)))
    (imap:write-literal-string-header string port)
    (flush-output port)
    (let loop ()
      (let ((response (imap:read-server-response port)))
	(cond ((imap:response:continue? response)
	       (imap:write-literal-string-body string port))
	      ((and (imap:response:tag response)
		    (string-ci=? tag (imap:response:tag response)))
	       (error "Unable to finish continued command:" response))
	      (else
	       (enqueue-imap-response connection response)
	       (loop)))))))

(define (imap:wait-for-tagged-response connection tag command)
  (let ((port (imap-connection-port connection)))
    (let loop ()
      (let ((response (imap:read-server-response port)))
	(if (imap:response:tag response)
	    (let ((responses
		   (process-responses
		    connection command
		    (dequeue-imap-responses connection))))
	      (cond ((not (string-ci=? tag (imap:response:tag response)))
		     (error "Out-of-sequence tag:"
			    (imap:response:tag response) tag))
		    ((or (imap:response:ok? response)
			 (imap:response:no? response))
		     (cons response responses))
		    (else
		     (error "IMAP protocol error:" response))))
	    (begin
	      (enqueue-imap-response connection response)
	      (loop)))))))

(define (process-responses connection command responses)
  (if (pair? responses)
      (if (process-response connection command (car responses))
	  (cons (car responses)
		(process-responses connection command (cdr responses)))
	  (process-responses connection command (cdr responses)))
      '()))

(define (process-response connection command response)
  (cond ((imap:response:status-response? response)
	 (let ((code (imap:response:response-text-code response))
	       (string (imap:response:response-text-string response)))
	   (if code
	       (process-response-text connection code string))
	   (if (and (imap:response:bye? response)
		    (not (eq? command 'LOGOUT)))
	       (begin
		 (close-imap-connection connection)
		 (error "Server shut down connection:" string))))
	 (imap:response:preauth? response))
	((imap:response:exists? response)
	 (let ((count (imap:response:exists-count response))
	       (folder (selected-imap-folder connection)))
	   (if (> count (folder-length folder))	;required to be >=
	       (set-imap-folder-length! folder count)))
	 #f)
	((imap:response:expunge? response)
	 (let ((folder (selected-imap-folder connection)))
	   (remove-imap-folder-message folder
				       (imap:response:expunge-index response))
	   (folder-modified! folder))
	 #f)
	((imap:response:flags? response)
	 (let ((folder (selected-imap-folder connection)))
	   (set-imap-folder-allowed-flags!
	    folder
	    (map imap-flag->imail-flag (imap:response:flags response)))
	   (folder-modified! folder))
	 #f)
	((imap:response:recent? response)
	 #f)
	((or (imap:response:capability? response)
	     (imap:response:fetch? response)
	     (imap:response:list? response)
	     (imap:response:lsub? response)
	     (imap:response:search? response)
	     (imap:response:status? response))
	 #t)
	(else
	 (error "Illegal server response:" response))))

(define (process-response-text connection code text)
  (cond ((imap:response-code:uidvalidity? code)
	 (let ((folder (selected-imap-folder connection))
	       (uidvalidity (imap:response-code:uidvalidity code)))
	   (if (let ((uidvalidity* (imap-folder-uidvalidity folder)))
		 (or (not uidvalidity*)
		     (> uidvalidity uidvalidity*)))
	       (forget-imap-folder-messages! folder))
	   (set-imap-folder-uidvalidity! folder uidvalidity)
	   (folder-modified! folder)))
	((imap:response-code:unseen? code)
	 (let ((folder (selected-imap-folder connection)))
	   (set-imap-folder-first-unseen!
	    folder
	    (- (imap:response-code:unseen code) 1))
	   (folder-modified! folder)))
	((imap:response-code:permanentflags? code)
	 (let ((pflags (imap:response-code:permanentflags code))
	       (folder (selected-imap-folder connection)))
	   (set-imap-folder-permanent-keywords?!
	    folder
	    (if (memq '\* pflags) #t #f))
	   (set-imap-folder-permanent-flags!
	    folder
	    (map imap-flag->imail-flag (delq '\* pflags)))
	   (folder-modified! folder)))
	((imap:response-code:alert? code)
	 (imail-present-user-alert
	  (lambda (port)
	    (write-string "Alert from IMAP server:" port)
	    (newline port)
	    (display text port)
	    (newline port))))
	#|
	((or (imap:response-code:newname? code)
	     (imap:response-code:parse? code)
	     (imap:response-code:read-only? code)
	     (imap:response-code:read-write? code)
	     (imap:response-code:trycreate? code))
	 unspecific)
	|#
	))