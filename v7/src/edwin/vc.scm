;;; -*-Scheme-*-
;;;
;;;	$Id: vc.scm,v 1.1 1994/03/08 20:31:51 cph Exp $
;;;
;;;	Copyright (c) 1994 Massachusetts Institute of Technology
;;;
;;;	This material was developed by the Scheme project at the
;;;	Massachusetts Institute of Technology, Department of
;;;	Electrical Engineering and Computer Science.  Permission to
;;;	copy this software, to redistribute it, and to use it for any
;;;	purpose is granted, subject to the following restrictions and
;;;	understandings.
;;;
;;;	1. Any copy made of this software must include this copyright
;;;	notice in full.
;;;
;;;	2. Users of this software agree to make their best efforts (a)
;;;	to return to the MIT Scheme project any improvements or
;;;	extensions that they make, so that these may be included in
;;;	future releases; and (b) to inform MIT of noteworthy uses of
;;;	this software.
;;;
;;;	3. All materials developed as a consequence of the use of this
;;;	software shall duly acknowledge such use, in accordance with
;;;	the usual standards of acknowledging credit in academic
;;;	research.
;;;
;;;	4. MIT has made no warrantee or representation that the
;;;	operation of this software will be error-free, and MIT is
;;;	under no obligation to provide any services, by way of
;;;	maintenance, update, or otherwise.
;;;
;;;	5. In conjunction with products arising from the use of this
;;;	material, there shall be no use of the name of the
;;;	Massachusetts Institute of Technology nor of any adaptation
;;;	thereof in any advertising, promotional, or sales literature
;;;	without prior written consent from MIT in each case.
;;;
;;; NOTE: Parts of this program (Edwin) were created by translation
;;; from corresponding parts of GNU Emacs.  Users should be aware that
;;; the GNU GENERAL PUBLIC LICENSE may apply to these parts.  A copy
;;; of that license should have been included along with this file.
;;;

;;;; Version Control
;;;  Translated from "vc.el" in Emacs 19.22.

#|

* Modify "dired.scm" -- add new marking stuff.

|#

(declare (usual-integrations))

;;;; Editor Variables

(define-variable vc-make-backup-files
  "If true, backups of registered files are made as with other files.
If false (the default), files covered by version control don't get backups."
  #f
  boolean?)

(define-variable-per-buffer vc-mode-line-status
  "A mode line string showing the version control status of the buffer.
Bound to #F if the buffer is not under version control."
  #f
  string-or-false?)
(let ((variable (ref-variable-object vc-mode-line-status)))
  (variable-permanent-local! variable)
  (set-variable! minor-mode-alist
		 (cons (list variable variable)
		       (ref-variable minor-mode-alist))))

(define-variable vc-suppress-confirm
  "If true, treat user as expert; suppress yes-no prompts on some things."
  #f
  boolean?)

(define-variable vc-keep-workfiles
  "If true, don't delete working files after registering changes."
  #t
  boolean?)

(define-variable vc-initial-comment
  "Prompt for initial comment when a file is registered."
  #f
  boolean?)

(define-variable vc-command-messages
  "If true, display run messages from back-end commands."
  #f
  boolean?)

(define-variable vc-checkin-switches
  "Extra switches passed to the checkin program by \\[vc-checkin]."
  '()
  list-of-strings?)

(define-variable diff-switches
  "A list of strings specifying switches to be be passed to diff."
  '("-c")
  list-of-strings?)

(define-variable vc-checkin-hooks
  "An event distributor that is invoked after a checkin is done."
  (make-event-distributor))

(define-variable vc-checkout-carefully
  "True means be extra-careful in checkout.
Verify that the file really is not locked
and that its contents match what the master file says."
  ;; Default is to be extra careful for super-user.
  (lambda () (= (unix/current-uid) 0))
  (lambda (object)
    (or (boolean? object)
	(and (procedure? object)
	     (procedure-arity-valid? object 0)))))

(define-variable vc-log-mode-hook
  "An event distributor that is invoked when entering VC-log mode."
  (make-event-distributor))

(define-variable vc-rcs-status
  "If true, revision and locks on RCS working file displayed in modeline.
Otherwise, not displayed."
  #t
  boolean?)

(define-variable vc-rcs-preserve-mod-times
  "If true, files checked out from RCS use checkin time for mod time.
Otherwise, the mod time of the file is the checkout time."
  #t
  boolean?)

;;;; Editor Hooks

(define (vc-find-file-hook buffer)
  (let ((master (buffer-vc-master buffer)))
    (vc-mode-line master buffer)
    (if (and master (not (ref-variable vc-make-backup-files buffer)))
	(define-variable-local-value! buffer
	    (ref-variable-object make-backup-files)
	  #f))))
(add-event-receiver! (ref-variable find-file-hooks) vc-find-file-hook)

(define (vc-file-not-found-hook buffer)
  (let ((master (buffer-vc-master buffer)))
    (and master
	 (begin
	   (load-edwin-library 'VC)
	   (call-with-current-continuation
	    (lambda (k)
	      (bind-condition-handler (list condition-type:error)
		  (lambda (condition)
		    condition
		    (k #f))
		(lambda ()
		  (vc-checkout master #f)
		  #t))))))))
(let ((hooks (ref-variable find-file-not-found-hooks)))
  (if (not (memq vc-file-not-found-hook hooks))
      (set-variable! find-file-not-found-hooks
		     (append! hooks (list vc-file-not-found-hook)))))

(define (vc-mode-line master buffer)
  (set-variable-local-value!
   buffer
   (ref-variable-object vc-mode-line-status)
   (and master (string-append " " (vc-mode-line-status master buffer))))
  ;; root shouldn't modify a registered file without locking it first.
  (if (and master
	   (= 0 (unix/current-uid))
	   (not (let ((locking-user (vc-locking-user master #f)))
		  (and locking-user
		       (string=? locking-user (unix/current-user-name))))))
      (set-buffer-read-only! buffer)))

;;;; Primary Commands

(define-command vc-toggle-read-only
  "Change read-only status of current buffer, perhaps via version control.
If the buffer is visiting a file registered with version control,
then check the file in or out.  Otherwise, just change the read-only flag
of the buffer."
  ()
  (lambda ()
    (if (buffer-vc-master (current-buffer))
	((ref-command vc-next-action) #f)
	((ref-command toggle-read-only)))))

(define-command vc-next-action
  "Do the next logical checkin or checkout operation on the current file.
   If the file is not already registered, this registers it for version
control and then retrieves a writable, locked copy for editing.
   If the file is registered and not locked by anyone, this checks out
a writable and locked file ready for editing.
   If the file is checked out and locked by the calling user, this
first checks to see if the file has changed since checkout.  If not,
it performs a revert.
   If the file has been changed, this pops up a buffer for entry
of a log message; when the message has been entered, it checks in the
resulting changes along with the log message as change commentary.  If
the variable `vc-keep-workfiles' is true (which is its default), a
read-only copy of the changed file is left in place afterwards.
   If the file is registered and locked by someone else, you are given
the option to steal the lock.
   If you call this from within a VC dired buffer with no files marked,
it will operate on the file in the current line.
   If you call this from within a VC dired buffer, and one or more
files are marked, it will accept a log message and then operate on
each one.  The log message will be used as a comment for any register
or checkin operations, but ignored when doing checkouts.  Attempted
lock steals will raise an error.

   For checkin, a prefix argument lets you specify the version number to use."
  "P"
  (lambda (revision?)
    (let ((workfile (buffer-pathname (current-buffer))))
      (if (not workfile)
	  (vc-registration-error #f))
      (vc-next-action-on-file workfile revision? #f))
    #|
    (cond ((not (eq? (current-major-mode) (ref-mode-object vc-dired-mode)))
	   (let ((workfile (buffer-pathname (current-buffer))))
	     (if workfile
		 (vc-next-action-on-file workfile revision? #f)
		 (vc-registration-error #f))))
	  ((= (length (dired-get-marked-files)) 1)
	   (let ((workfile (dired-current-pathname)))
	     (find-file-other-window workfile)
	     (vc-next-action-on-file workfile revision? #f)))
	  (else
	   (vc-start-entry #f
			   "Enter a change comment for the marked files."
			   #f
			   vc-next-action-dired
			   #f)))
    |#
    ))

(define-command vc-register
  "Register the current file into your version-control system."
  "P"
  (lambda (revision?)
    (let ((workfile (buffer-pathname (current-buffer))))
      (if (not workfile)
	  (vc-registration-error #f))
      (if (file-vc-master workfile)
	  (editor-error "This file is already registered."))
      (vc-register workfile revision? #f #f))))

(define (vc-next-action-on-file workfile revision comment)
  (let ((master (file-vc-master workfile)))
    (if (not master)
	(vc-register workfile revision comment 'LOCK)
	(let ((revision (vc-get-version revision "Version level to act on")))
	  (let ((owner (vc-locking-user master revision)))
	    (cond ((not owner)
		   (vc-checkout master revision))
		  ((string=? owner (unix/current-user-name))
		   (if (or (let ((buffer (vc-workfile-buffer workfile)))
			     (and buffer
				  (buffer-modified? buffer)))
			   (vc-workfile-modified? master))
		       (vc-checkin master revision comment)
		       (vc-revert master revision)))
		  (else
		   (vc-steal-lock master revision comment owner))))))))

(define (vc-register workfile revision comment keep?)
  (let ((revision
	 (vc-get-version revision
			 (string-append "Initial version level for "
					(vc-workfile-string workfile)))))
    (let ((buffer (vc-workfile-buffer workfile)))
      ;; Watch out for new buffers of size 0: the corresponding file
      ;; does not exist yet, even though buffer-modified? is false.
      (if (and buffer
	       (not (buffer-modified? buffer))
	       (= 0 (buffer-length buffer))
	       (not (file-exists? workfile)))
	  (buffer-modified! buffer)))
    (vc-save-workfile-buffer workfile)
    (let ((keep? (or keep? (vc-keep-workfiles? workfile))))
      (vc-start-entry workfile
		      "Enter initial comment."
		      (or comment
			  (if (ref-variable vc-initial-comment
					    (vc-workfile-buffer workfile))
			      #f
			      ""))
		      (lambda (comment)
			(vc-backend-register workfile revision comment)
			(if keep?
			    (vc-backend-checkout (file-vc-master workfile #t)
						 revision
						 (eq? 'LOCK keep?)
						 #f))
			(vc-update-workfile-buffer workfile keep?))
		      #f))))

(define (vc-checkout master revision)
  (let ((revision
	 (or (vc-get-version revision "Version level to check out")
	     (vc-workfile-version master))))
    (let ((do-it
	   (lambda ()
	     (vc-backend-checkout master revision #t #f)
	     (vc-revert-workfile-buffer master #t))))
      (cond ((or (not (let ((value (ref-variable vc-checkout-carefully)))
			(if (boolean? value)
			    value
			    (value))))
		 (not (vc-workfile-modified? master))
		 (= 0 (vc-backend-diff master #f #f)))
	     (do-it))
	    ((cleanup-pop-up-buffers
	      (lambda ()
		(let ((diff-buffer (get-vc-command-buffer)))
		  (insert-string
		   (string-append "Changes to "
				  (vc-workfile-string master)
				  " since last lock:\n\n")
		   (buffer-start diff-buffer))
		  (set-buffer-point! diff-buffer (buffer-start diff-buffer))
		  (pop-up-buffer diff-buffer #f)
		  (editor-beep)
		  (prompt-for-yes-or-no?
		   (string-append "File has unlocked changes, "
				  "claim lock retaining changes")))))
	     (guarantee-vc-master-valid master)
	     (vc-backend-claim-lock master revision)
	     (let ((buffer (vc-workfile-buffer master)))
	       (if buffer
		   (vc-mode-line master buffer))))
	    ((prompt-for-yes-or-no? "Revert to checked-in version, instead")
	     (do-it))
	    (else
	     (editor-error "Checkout aborted."))))))

(define (vc-checkin master revision comment)
  (let ((revision
	 (or (vc-get-version revision "New version level")
	     (vc-workfile-version master)))
	(keep? (vc-keep-workfiles? master)))
    (vc-save-workfile-buffer master)
    (vc-start-entry master
		    "Enter a change comment."
		    comment
		    (lambda (comment)
		      (vc-backend-checkin master revision comment)
		      (if keep?
			  (vc-backend-checkout master revision #f #f))
		      (vc-update-workfile-buffer master keep?))
		    (lambda ()
		      (event-distributor/invoke!
		       (ref-variable vc-checkin-hooks
				     (vc-workfile-buffer master))
		       master)))))

(define (vc-revert master revision)
  (let ((revision
	 (or (vc-get-version revision "Version level to revert")
	     (vc-workfile-version master))))
    (vc-save-workfile-buffer master)
    (vc-backend-revert master revision)
    (vc-revert-workfile-buffer master #f)))

(define (vc-steal-lock master revision comment owner)
  (let ((filename (vc-workfile-string master)))
    (if comment
	(editor-error "Sorry, you can't steal the lock on "
		      filename
		      " this way."))
    (let ((revision
	   (or (vc-get-version revision "Version level to steal")
	       (vc-workfile-version master))))
      (let ((file:rev
	     (if revision
		 (string-append filename ":" revision)
		 filename)))
	(if (not (prompt-for-confirmation?
		  (string-append "Take the lock on " file:rev " from " owner)))
	    (editor-error "Steal cancelled."))
	(let ((mail-buffer (find-or-create-buffer "*VC-mail*")))
	  (buffer-reset! mail-buffer)
	  (mail-setup mail-buffer owner file:rev #f #f #f)
	  (let ((time (get-decoded-time)))
	    (insert-string (string-append "I stole the lock on "
					  file:rev
					  ", "
					  (decoded-time/date-string time)
					  " at "
					  (decoded-time/time-string time)
					  ".\n")
			   (buffer-end mail-buffer)))
	  (set-buffer-point! mail-buffer (buffer-end mail-buffer))
	  (let ((variable (ref-variable-object send-mail-procedure)))
	    (define-variable-local-value! mail-buffer variable
	      (lambda ()
		(guarantee-vc-master-valid master)
		(vc-backend-steal master revision)
		(vc-revert-workfile-buffer master #t)
		;; Send the mail after the steal has completed
		;; successfully.
		((variable-default-value variable)))))
	  (pop-up-buffer mail-buffer #t)))))
  (message "Please explain why you are stealing the lock."
	   "  Type C-c C-c when done."))

;;;; Auxiliary Commands

(define-command vc-diff
  "Display diffs between file versions.
Normally this compares the current file and buffer with the most recent 
checked in version of that file.  This uses no arguments.
With a prefix argument, it reads the file name to use
and two version designators specifying which versions to compare."
  "P"
  (lambda (revisions?)
    (if revisions?
	(dispatch-on-command (ref-command-object vc-version-diff))
	(vc-diff (buffer-vc-master (current-buffer) #t) #f #f))))

(define-command vc-version-diff
  "For FILE, report diffs between two stored versions REV1 and REV2 of it.
If FILE is a directory, generate diffs between versions for all registered
files in or below it."
  "FFile or directory to diff\nsOlder version\nsNewer version"
  (lambda (workfile rev1 rev2)
    (if (file-directory? workfile)
	(editor-error "Directory diffs not yet supported.")
	(vc-diff (file-vc-master workfile #t) rev1 rev2))))

(define (vc-diff master rev1 rev2)
  (vc-save-workfile-buffer master)
  (let ((rev1 (vc-normalize-version rev1))
	(rev2 (vc-normalize-version rev2)))
    (let ((rev1 (if (or rev1 rev2) rev1 (vc-workfile-version master))))
      (if (or (if (or rev1 rev2)
		  #t
		  (not (vc-workfile-modified? master)))
	      (= 0 (vc-backend-diff master rev1 rev2)))
	  (begin
	    (message "No changes to "
		     (vc-workfile-string master)
		     (if (and rev1 rev2)
			 (string-append " between " rev1 " and " rev2)
			 (string-append " since "
					(or rev1 rev2 "latest version")))
		     ".")
	    #t)
	  (begin
	    (pop-up-vc-command-buffer #f)
	    #f)))))

(define-command vc-version-other-window
  "Visit version REV of the current buffer in another window.
If the current buffer is named `F', the version is named `F.~REV~'.
If `F.~REV~' already exists, it is used instead of being re-created."
  "sVersion to visit (default is latest version)"
  (lambda (revision)
    (let ((master (buffer-vc-master (current-buffer))))
      (let ((revision
	     (or (vc-normalize-version revision)
		 (vc-backend-default-version master))))
	(let ((workfile
	       (string-append (->namestring (vc-master-workfile master))
			      ".~"
			      revision
			      "~")))
	  (if (not (file-exists? workfile))
	      (vc-backend-checkout master revision #f workfile))
	  (find-file-other-window workfile))))))

(define-command vc-insert-headers
  "Insert headers in a file for use with your version-control system.
Headers are inserted at the start of the buffer."
  ()
  (lambda ()
    (editor-error "VC-INSERT-HEADERS not implemented.")))

(define-command vc-print-log
  "List the change log of the current buffer in a window."
  ()
  (lambda ()
    (vc-backend-print-log (buffer-vc-master (current-buffer)))
    (pop-up-vc-command-buffer #f)))

(define-command vc-revert-buffer
  "Revert the current buffer's file back to the latest checked-in version.
This asks for confirmation if the buffer contents are not identical
to that version."
  ()
  (lambda ()
    (let ((buffer (current-buffer)))
      (let ((master (buffer-vc-master buffer)))
	(if (cleanup-pop-up-buffers
	     (lambda ()
	       (or (not (vc-diff master #f #f))
		   (ref-variable vc-suppress-confirm)
		   (prompt-for-yes-or-no? "Discard changes"))))
	    (begin
	      (vc-backend-revert master #f)
	      (vc-revert-buffer buffer #t))
	    (editor-error "Revert cancelled."))))))

(define-command vc-cancel-version
  "Get rid of most recently checked in version of this file.
A prefix argument means do not revert the buffer afterwards."
  "P"
  (lambda (no-revert?)
    no-revert?
    (editor-error "VC-CANCEL-VERSION not implemented.")))

;;;; Log Entries

(define (vc-start-entry master msg comment finish-entry after)
  (if comment
      (begin
	(finish-entry comment)
	(if after (after)))
      (let ((log-buffer (find-or-create-buffer "*VC-log*")))
	(buffer-reset! log-buffer)
	(set-buffer-major-mode! log-buffer (ref-mode-object vc-log))
	(buffer-not-modified! log-buffer)
	(set-buffer-pathname! log-buffer #f)
	(if (vc-master? master)
	    (vc-mode-line master log-buffer))
	(buffer-put! log-buffer
		     'VC-LOG-FINISH-ENTRY
		     (vc-finish-entry master
				      finish-entry
				      after
				      (let ((window
					     (pop-up-buffer log-buffer #t)))
					(and window
					     (hash window)))))
	(message msg "  Type C-c C-c when done."))))

(define (vc-finish-entry master finish-entry after window)
  (lambda (log-buffer)
    ;; If a new window was created to hold the log buffer, and the
    ;; log buffer is still selected in that window, delete it.
    (let ((window (and window (unhash window))))
      (if (and window
	       (window-live? window)
	       (eq? log-buffer (window-buffer window))
	       (not (window-has-no-neighbors? window)))
	  (window-delete! window)))
    (guarantee-newline (buffer-end log-buffer))
    (if (vc-master? master)
	(guarantee-vc-master-valid master))
    ;; Signal error if log entry too long.
    (if (vc-master? master)
	(vc-backend-logentry-check master log-buffer))
    (let ((comment (buffer-string log-buffer)))
      ;; Enter the comment in the comment ring.
      (comint-record-input vc-comment-ring comment)
      ;; We're finished with the log buffer now.
      (kill-buffer log-buffer)
      ;; Perform the log operation.
      (finish-entry comment))
    (if after (after))))

(define vc-comment-ring
  (make-ring 32))

(define-major-mode vc-log text "VC-Log"
  "Major mode for entering a version-control change log message.
In this mode, the following additional bindings will be in effect.

\\[vc-finish-logentry]	proceed with check in, ending log message entry

Whenever you do a checkin, your log comment is added to a ring of
saved comments.  These can be recalled as follows:

\\[comint-previous-input]	replace region with previous message in comment ring
\\[comint-next-input]	replace region with next message in comment ring
\\[comint-history-search-reverse]	search backward for regexp in the comment ring
\\[comint-history-search-forward]	search forward for regexp in the comment ring

Entry to the vc-log submode calls the value of text-mode-hook, then
the value of vc-log-mode-hook."
  (lambda (buffer)
    (define-variable-local-value! buffer
	(ref-variable-object comint-input-ring)
      vc-comment-ring)
    (define-variable-local-value! buffer
	(ref-variable-object comint-last-input-match)
      false)
    (event-distributor/invoke! (ref-variable vc-log-mode-hook buffer) buffer)))

(define-key 'vc-log '(#\C-c #\C-c) 'vc-finish-logentry)
(define-key 'vc-log #\M-p 'comint-previous-input)
(define-key 'vc-log #\M-n 'comint-next-input)
(define-key 'vc-log #\M-r 'comint-history-search-backward)
(define-key 'vc-log #\M-s 'comint-history-search-forward)

(define-command vc-finish-logentry
  "Complete the operation implied by the current log entry."
  ()
  (lambda ()
    (let ((buffer (current-buffer)))
      (let ((finish-entry (buffer-get buffer 'VC-LOG-FINISH-ENTRY)))
	(if (not finish-entry)
	    (error "No log operation is pending."))
	(finish-entry buffer)))))

;;;; Back End

(define (vc-backend-register workfile revision comment)
  ((vc-type-operation
    (if (and (not (null? vc-types))
	     (null? (cdr vc-types)))
	(cdar vc-types)
	(let ((likely-types
	       (list-transform-positive vc-types
		 (lambda (entry)
		   ((vc-type-operation (cdr entry) 'LIKELY-CONTROL-TYPE?)
		    workfile)))))
	  (if (and (not (null? likely-types))
		   (null? (cdr likely-types)))
	      (cdar likely-types)
	      (cleanup-pop-up-buffers
	       (lambda ()
		 (call-with-output-to-temporary-buffer " *VC-types*"
		   (lambda (port)
		     (for-each (lambda (entry)
				 (write-string (car entry) port)
				 (newline port))
			       vc-types)))
		 (prompt-for-alist-value "Version control type"
					 vc-types
					 #f
					 #f))))))
    'REGISTER)
   workfile revision comment))

(define (vc-backend-claim-lock master revision)
  (vc-call 'CLAIM-LOCK master revision))

(define (vc-backend-checkout master revision lock? workfile)
  (let ((workfile
	 (and workfile
	      (not (pathname=? workfile (vc-workfile-pathname master)))
	      workfile)))
    (vc-call 'CHECKOUT master revision lock? workfile)
    (if (and (not revision) (not workfile))
	(set-vc-master-checkout-time!
	 master
	 (file-modification-time-indirect (vc-workfile-pathname master))))))

(define (vc-backend-revert master revision)
  (vc-call 'REVERT master revision))

(define (vc-backend-checkin master revision comment)
  (vc-call 'CHECKIN master revision comment))

(define (vc-backend-steal master revision)
  (vc-call 'STEAL master revision))

(define (vc-backend-logentry-check master log-buffer)
  (vc-call 'LOGENTRY-CHECK master log-buffer))

(define (vc-backend-diff master rev1 rev2)
  (vc-call 'DIFF master rev1 rev2))

(define (vc-backend-print-log master)
  (vc-call 'PRINT-LOG master))

(define (vc-backend-default-version master)
  (vc-call 'DEFAULT-VERSION master))

(define (vc-backend-buffer-version master buffer)
  (vc-call 'BUFFER-VERSION master buffer))

(define (vc-locking-user master revision)
  (vc-call 'LOCKING-USER master revision))

(define (vc-mode-line-status master buffer)
  (vc-call 'MODE-LINE-STATUS master buffer))

(define (vc-admin master)
  (let ((pathname (vc-master-pathname master)))
    (let loop ()
      (let ((time (file-modification-time-indirect pathname)))
	(or (and (eqv? (vc-master-%time master) time)
		 (vc-master-%admin master))
	    (begin
	      (set-vc-master-%time! master time)
	      (set-vc-master-%admin! master (vc-call 'GET-ADMIN master))
	      (loop)))))))

(define-structure (vc-master
		   (constructor make-vc-master (type pathname workfile)))
  (type #f read-only #t)
  (pathname #f read-only #t)
  (workfile #f read-only #t)
  (checkout-time #f)
  (%time #f)
  (%admin #f))

(define-structure (vc-type (constructor %make-vc-type (name header-keyword)))
  (name #f read-only #t)
  (header-keyword #f read-only #t)
  (operations '()))

(define (make-vc-type name header-keyword)
  (let ((type (%make-vc-type name header-keyword))
	(entry (assq name vc-types)))
    (if entry
	(set-cdr! entry type)
	(set! vc-types (cons (cons name type) vc-types)))
    type))

(define vc-types
  '())

(define (define-vc-master-template vc-type pathname-map)
  (set! vc-master-templates
	(cons (cons pathname-map vc-type)
	      vc-master-templates))
  unspecific)

(define vc-master-templates
  '())

(define (define-vc-type-operation name type procedure)
  (let ((entry (assq name (vc-type-operations type))))
    (if entry
	(set-cdr! entry procedure)
	(set-vc-type-operations! type
				 (cons (cons name procedure)
				       (vc-type-operations type))))))

(define (vc-type-operation type name)
  (let ((entry (assq name (vc-type-operations type))))
    (if (not entry)
	(error:bad-range-argument name 'VC-TYPE-OPERATION))
    (cdr entry)))

(define (vc-call name master . arguments)
  (apply (vc-type-operation (vc-master-type master) name) master arguments))

(define (file-vc-master workfile #!optional require-master?)
  (let ((require-master?
	 (if (default-object? require-master?)
	     #f
	     require-master?))
	(buffer (pathname->buffer workfile)))
    (if buffer
	(buffer-vc-master buffer require-master?)
	(%file-vc-master workfile require-master?))))

(define (buffer-vc-master buffer #!optional require-master?)
  (let ((require-master?
	 (if (default-object? require-master?)
	     #f
	     require-master?))
	(workfile (buffer-pathname buffer)))
    (if workfile
	(let ((master (buffer-get buffer 'VC-MASTER)))
	  (if (and master
		   (pathname=? workfile (vc-master-workfile master))
		   (vc-master-valid? master))
	      master
	      (let ((master (%file-vc-master workfile require-master?)))
		(buffer-put! buffer 'VC-MASTER master)
		master)))
	(begin
	  (buffer-put! buffer 'VC-MASTER #f)
	  (if require-master? (vc-registration-error buffer))
	  #f))))

(define (%file-vc-master workfile require-master?)
  (let ((master (hash-table/get vc-master-table workfile #f)))
    (if (and master (vc-master-valid? master))
	master
	(begin
	  (if master
	      (hash-table/remove! vc-master-table workfile))
	  (let loop ((templates vc-master-templates))
	    (if (null? templates)
		(begin
		  (if require-master? (vc-registration-error workfile))
		  #f)
		(let ((master
		       (make-vc-master (cdar templates)
				       ((caar templates) workfile)
				       workfile)))
		  (if (vc-master-valid? master)
		      (begin
			(hash-table/put! vc-master-table workfile master)
			master)
		      (loop (cdr templates))))))))))

(define vc-master-table
  ;; EQUAL-HASH-MOD happens to work correctly here, because a pathname
  ;; has the same hash value as its namestring.
  ((weak-hash-table/constructor equal-hash-mod pathname=? #t)))

(define (guarantee-vc-master-valid master)
  (if (not (vc-master-valid? master))
      (error "VC master file disappeared:" (vc-master-workfile master))))

(define (vc-master-valid? master)
  ;; FILE-EQ? yields #f if either file doesn't exist.
  (let ((pathname (vc-master-pathname master)))
    (and (file-exists? pathname)
	 (not (file-eq? (vc-master-workfile master) pathname)))))

(define (vc-registration-error object)
  (if (or (buffer? object) (not object))
      (editor-error "Buffer "
		    (buffer-name (or object (current-buffer)))
		    " is not associated with a file.")
      (editor-error "File "
		    (vc-workfile-string object)
		    " is not under version control.")))

;;;; RCS Commands

(define vc-type:rcs
  (make-vc-type 'RCS "$Id: vc.scm,v 1.1 1994/03/08 20:31:51 cph Exp $"))

(define-vc-master-template vc-type:rcs
  (lambda (pathname)
    (merge-pathnames (string-append (file-namestring pathname) ",v")
		     (let ((pathname (directory-pathname pathname)))
		       (pathname-new-directory
			pathname
			(append (pathname-directory pathname)
				'("RCS")))))))

(define-vc-master-template vc-type:rcs
  (lambda (pathname)
    (merge-pathnames (string-append (file-namestring pathname) ",v")
		     (directory-pathname pathname))))

(define-vc-master-template vc-type:rcs
  (lambda (pathname)
    (pathname-new-directory pathname
			    (append (pathname-directory pathname)
				    '("RCS")))))

(define-vc-type-operation 'LOCKING-USER vc-type:rcs
  (lambda (master revision)
    (let ((admin (vc-admin master)))
      (let ((delta (rcs-find-delta admin revision)))
	(let loop ((locks (rcs-admin/locks admin)))
	  (and (not (null? locks))
	       (if (eq? delta (cdar locks))
		   (caar locks)
		   (loop (cdr locks)))))))))

(define-vc-type-operation 'MODE-LINE-STATUS vc-type:rcs
  (lambda (master buffer)
    (and (ref-variable vc-rcs-status buffer)
	 (string-append
	  "RCS"
	  (let ((admin (vc-admin master)))
	    (let ((locks (rcs-admin/locks admin)))
	      (if (not (null? locks))
		  (apply string-append
			 (let ((user (unix/current-user-name)))
			   (map (lambda (lock)
				  (string-append
				   ":"
				   (let ((rev (rcs-delta/number (cdr lock))))
				     (if (string=? user (car lock))
					 rev
					 (string-append (car lock) ":" rev)))))
				locks)))
		  (let ((head (rcs-admin/head admin)))
		    (if head
			(string-append "-" (rcs-delta/number head))
			" @@")))))))))

(define-vc-type-operation 'GET-ADMIN vc-type:rcs
  (lambda (master)
    (parse-rcs-admin (vc-master-pathname master))))

(define-vc-type-operation 'LIKELY-CONTROL-TYPE? vc-type:rcs
  (lambda (workfile)
    (file-directory?
     (let ((directory (directory-pathname workfile)))
       (pathname-new-directory directory
			       (append (pathname-directory directory)
				       '("RCS")))))))

(define-vc-type-operation 'REGISTER vc-type:rcs
  (lambda (workfile revision comment)
    (with-vc-command-message workfile "Registering"
      (lambda ()
	(vc-run-command workfile 0 "ci"
			(rcs-rev-switch "-r" revision)
			(string-append "-t-" comment)
			(vc-workfile-pathname workfile))))))

(define-vc-type-operation 'CLAIM-LOCK vc-type:rcs
  (lambda (master revision)
    (vc-run-command master 0 "rcs"
		    (rcs-rev-switch "-l" revision)
		    (vc-workfile-pathname master))))

(define-vc-type-operation 'CHECKOUT vc-type:rcs
  (lambda (master revision lock? workfile)
    (with-vc-command-message master "Checking out"
      (lambda ()
	(if workfile
	    ;; RCS makes it difficult to check a file out into anything
	    ;; but the working file.
	    (begin
	      (delete-file-no-errors workfile)
	      (vc-run-command master 0 "/bin/sh"
			      (reduce string-append-separated
				      ""
				      (vc-command-arguments
				       "co"
				       (rcs-rev-switch "-p" revision)
				       (vc-workfile-pathname master)))
			      ">"
			      (vc-workfile-pathname workfile))
	      (set-file-modes! workfile (if lock? #o644 #o444)))
	    (vc-run-command master 0 "co"
			    (rcs-rev-switch (if lock? "-l" "-r") revision)
			    (rcs-mtime-switch master)
			    (vc-workfile-pathname master)))))))

(define-vc-type-operation 'REVERT vc-type:rcs
  (lambda (master revision)
    (with-vc-command-message master "Reverting"
      (lambda ()
	(vc-run-command master 0 "co"
			"-f"
			(rcs-rev-switch "-u" revision)
			(vc-workfile-pathname master))))))

(define-vc-type-operation 'CHECKIN vc-type:rcs
  (lambda (master revision comment)
    (with-vc-command-message master "Checking in"
      (lambda ()
	(vc-run-command master 0 "ci"
			(rcs-rev-switch "-r" revision)
			(string-append "-m" comment)
			(vc-workfile-pathname master))))))

(define-vc-type-operation 'STEAL vc-type:rcs
  (lambda (master revision)
    (with-vc-command-message master "Stealing lock on"
      (lambda ()
	(vc-run-command master 0 "rcs"
			"-M"
			(rcs-rev-switch "-u" revision)
			(rcs-rev-switch "-l" revision)
			(vc-workfile-pathname master))))))

(define-vc-type-operation 'LOGENTRY-CHECK vc-type:rcs
  (lambda (master log-buffer)
    master log-buffer
    unspecific))

(define-vc-type-operation 'DIFF vc-type:rcs
  (lambda (master rev1 rev2)
    (vc-run-command master 1 "rcsdiff"
		    "-q"
		    (and rev1 (string-append "-r" rev1))
		    (and rev2 (string-append "-r" rev2))
		    (ref-variable diff-switches (vc-workfile-buffer master))
		    (vc-workfile-pathname master))))

(define-vc-type-operation 'PRINT-LOG vc-type:rcs
  (lambda (master)
    (vc-run-command master 0 "rlog" (vc-workfile-pathname master))))

(define-vc-type-operation 'DEFAULT-VERSION vc-type:rcs
  (lambda (master)
    (rcs-delta/number (rcs-find-delta (vc-admin master) #f))))

(define-vc-type-operation 'BUFFER-VERSION vc-type:rcs
  (lambda (master buffer)
    master
    (let ((start (buffer-start buffer))
	  (end (buffer-end buffer)))
      (let ((find-keyword
	     (lambda (keyword)
	       (let ((mark
		      (search-forward (string-append "$" keyword ":")
				      start
				      end
				      #f)))
		 (and mark
		      (skip-chars-forward " " mark end #f)))))
	    (get-version
	     (lambda (start)
	       (let ((end (skip-chars-forward "0-9." start end)))
		 (and (mark< start end)
		      (let ((revision (extract-string start end)))
			(let ((length (rcs-number-length revision)))
			  (and (> length 2)
			       (even? length)
			       (rcs-number-head revision (- length 1))))))))))
	(cond ((or (find-keyword "Id") (find-keyword "Header"))
	       => (lambda (mark)
		    (get-version
		     (skip-chars-forward " "
					 (skip-chars-forward "^ " mark end)
					 end))))
	      ((find-keyword "Revision") => get-version)
	      (else #f))))))

(define (rcs-rev-switch switch revision)
  (if revision
      (string-append switch revision)
      switch))

(define (rcs-mtime-switch master)
  (and (ref-variable vc-rcs-preserve-mod-times (vc-workfile-buffer master))
       "-M"))

;;;; Command Execution

(define (vc-run-command master status-limit command . arguments)
  (let ((command-messages?
	 (ref-variable vc-command-messages (vc-workfile-buffer master)))
	(msg
	 (string-append "Running " command
			" on " (vc-workfile-string master) "..."))
	(command-buffer (get-vc-command-buffer)))
    (if command-messages? (message msg))
    (buffer-reset! command-buffer)
    (bury-buffer command-buffer)
    (let ((result
	   (apply run-synchronous-process
		  #f
		  (buffer-end command-buffer)
		  #f
		  #f
		  (find-program command
				(buffer-default-directory command-buffer))
		  (vc-command-arguments arguments))))
      (if (and (eq? 'EXITED (car result))
	       (<= 0 (cdr result) status-limit))
	  (begin
	    (if command-messages? (message msg "done"))
	    (cdr result))
	  (begin
	    (pop-up-vc-command-buffer #f)
	    (editor-error "Running " command "...FAILED "
			  (list (car result) (cdr result))))))))

(define (vc-command-arguments arguments)
  (append-map (lambda (argument)
		(cond ((string? argument) (list argument))
		      ((pathname? argument) (list (->namestring argument)))
		      ((list? argument) (vc-command-arguments argument))
		      (else (error "Ill-formed command argument:" argument))))
	      arguments))

(define (pop-up-vc-command-buffer select?)
  (let ((command-buffer (get-vc-command-buffer)))
    (set-buffer-point! command-buffer (buffer-start command-buffer))
    (pop-up-buffer command-buffer select?)))

(define (get-vc-command-buffer)
  (find-or-create-buffer "*vc*"))

(define (with-vc-command-message master operation thunk)
  (let ((msg (string-append operation " " (vc-workfile-string master) "...")))
    (message msg)
    (thunk)
    (message msg "done")))

;;;; Workfile Utilities

(define (vc-keep-workfiles? master)
  (ref-variable vc-keep-workfiles (vc-workfile-buffer master)))

(define (vc-update-workfile-buffer master keep?)
  ;; Depending on VC-KEEP-WORKFILES, either revert the workfile
  ;; buffer to show the updated workfile, or kill the buffer.
  (let ((buffer (vc-workfile-buffer master)))
    (if buffer
	(if (or keep? (ref-variable vc-keep-workfiles buffer))
	    (vc-revert-buffer buffer #t)
	    (kill-buffer buffer)))))

(define (vc-get-version revision prompt)
  (vc-normalize-version (if (or (not revision) (string? revision))
			    revision
			    (prompt-for-string prompt #f))))

(define (vc-normalize-version revision)
  (and revision
       (not (string-null? revision))
       revision))

(define (vc-workfile-version master)
  (let ((pathname (vc-workfile-pathname master)))
    (let ((buffer (pathname->buffer pathname)))
      (if buffer
	  (vc-backend-buffer-version master buffer)
	  (call-with-temporary-buffer " *VC-temp*"
	    (lambda (buffer)
	      (catch-file-errors (lambda () #f)
		(lambda ()
		  (read-buffer buffer pathname #f)
		  (vc-backend-buffer-version master buffer)))))))))

(define (vc-workfile-buffer master)
  (pathname->buffer (vc-workfile-pathname master)))

(define (vc-workfile-string master)
  (->namestring (vc-workfile-pathname master)))

(define (vc-workfile-pathname master)
  (if (vc-master? master)
      (vc-master-workfile master)
      master))

(define (vc-workfile-modified? master)
  (let ((mod-time
	 (file-modification-time-indirect (vc-workfile-pathname master))))
    (cond ((not mod-time) #f)
	  ((eqv? (vc-master-checkout-time master) mod-time) #f)
	  ((= 0 (vc-backend-diff master #f #f))
	   (set-vc-master-checkout-time! master mod-time)
	   #f)
	  (else
	   (set-vc-master-checkout-time! master #f)
	   #t))))

(define (vc-save-workfile-buffer master)
  (let ((buffer (vc-workfile-buffer master)))
    (if buffer
	(vc-save-buffer buffer))))

(define (vc-save-buffer buffer)
  (if (buffer-modified? buffer)
      (begin
	(if (not (or (ref-variable vc-suppress-confirm buffer)
		     (prompt-for-confirmation?
		      (string-append "Buffer "
				     (buffer-name buffer)
				     " modified; save it"))))
	    (editor-error "Aborted"))
	(save-buffer buffer #f))))

(define (vc-revert-workfile-buffer master dont-confirm?)
  (let ((buffer (vc-workfile-buffer master)))
    (if buffer
	(vc-revert-buffer buffer dont-confirm?))))

(define (vc-revert-buffer buffer dont-confirm?)
  ;; Revert BUFFER, try to keep point and mark where user expects them
  ;; in spite of changes due to expanded version-control keywords.
  (let ((point-contexts
	 (map (lambda (window)
		(cons window
		      (vc-mark-context (window-point window))))
	      (buffer-windows buffer)))
	(point-context (vc-mark-context (buffer-point buffer)))
	(mark-context (vc-mark-context (buffer-mark buffer))))
    (revert-buffer buffer #t dont-confirm?)
    (let ((point (vc-find-context buffer point-context)))
      (if (null? point-contexts)
	  (if point (set-buffer-point! buffer point))
	  (for-each (lambda (entry)
		      (if (and (window-live? (car entry))
			       (eq? buffer (window-buffer (car entry))))
			  (let ((point (vc-find-context buffer (cdr entry))))
			    (if point
				(set-window-point! (car entry) point)))))
		    point-contexts)))
    (let ((mark (vc-find-context buffer mark-context)))
      (if mark
	  (set-buffer-mark! buffer mark)))))

(define (vc-mark-context mark)
  (let ((group (mark-group mark))
	(index (mark-index mark)))
    (let ((length (group-length group)))
      (vector index
	      length
	      (group-extract-string group index (min length (+ index 100)))))))

(define (vc-find-context buffer context)
  (let ((group (buffer-group buffer))
	(index (vector-ref context 0))
	(string (vector-ref context 2)))
    (let ((length (group-length group)))
      (if (string-null? string)
	  (group-end-mark group)
	  (and (or (and (< index length)
			(search-forward string
					(make-mark group index)
					(make-mark group length)))
		   (let ((index
			  (- index
			     (abs (- (vector-ref context 1) length))
			     (string-length string))))
		     (and (<= 0 index length)
			  (search-forward string
					  (make-mark group index)
					  (make-mark group length)))))
	       (let ((mark (re-match-start 0)))
		 (cond ((mark< mark (group-start-mark group))
			(group-start-mark group))
		       ((mark> mark (group-end-mark group))
			(group-end-mark group))
		       (else mark))))))))