;;; -*-Scheme-*-
;;;
;;;	$Header: /Users/cph/tmp/foo/mit-scheme/mit-scheme/v7/src/edwin/editor.scm,v 1.187 1989/04/28 22:49:21 cph Rel $
;;;
;;;	Copyright (c) 1986, 1989 Massachusetts Institute of Technology
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

;;;; Editor Top Level

(declare (usual-integrations))

(define edwin-reset-args
  '())

(define (edwin)
  (if (not edwin-editor)
      (apply edwin-reset edwin-reset-args))
  (call-with-current-continuation
   (lambda (continuation)
     (bind-condition-handler
	 '()
	 (lambda (condition)
	   (and (not (condition/internal? condition))
		(error? condition)
		(if (ref-variable debug-on-error)
		    (begin
		     (with-output-to-temporary-buffer "*Error*"
		       (lambda ()
			 (format-error-message (condition/message condition)
					       (condition/irritants condition)
					       (current-output-port))))
		     (editor-error "Scheme error"))
		    (within-continuation continuation
		      (lambda ()
			(signal-error condition))))))
       (lambda ()
	 (using-screen edwin-screen
	  (lambda ()
	    (with-editor-input-port edwin-input-port
	     (lambda ()
	       (with-editor-interrupts
		(lambda ()
		  (within-editor edwin-editor
		   (lambda ()
		     (perform-buffer-initializations! (current-buffer))
		     (dynamic-wind
		      (lambda ()
			(update-screens! true))
		      (lambda ()
			;; Should this be in a dynamic wind? -- Jinx
			(if edwin-initialization (edwin-initialization))
			(let ((message (cmdl-message/null)))
			  (push-cmdl (lambda (cmdl)
				       cmdl	;ignore
				       (top-level-command-reader)
				       message)
				     false
				     message)))
		      (lambda ()
			unspecific))))))))))
	 ;; Should this be here or in a dynamic wind? -- Jinx
	 (if edwin-finalization (edwin-finalization))))))
  unspecific)

(define-variable debug-on-error
  "*True means enter debugger if an error is signalled.
Does not apply to editor errors."
  false)

;; Set this before entering the editor to get something done after the
;; editor's dynamic environment is initialized, but before the command
;; loop is started.  [Should this bind the ^G interrupt also? -- CPH](define edwin-initialization false)

;; Set this while in the editor to get something done after leaving
;; the editor's dynamic environment; for example, this can be used to
;; reset and then reenter the editor.
(define edwin-finalization false)

(define (within-editor editor thunk)
  (call-with-current-continuation
   (lambda (continuation)
     (fluid-let ((editor-continuation continuation)
		 (recursive-edit-continuation false)
		 (recursive-edit-level 0)
		 (current-editor editor)
		 (*auto-save-keystroke-count* 0))
       (thunk)))))

(define editor-continuation)
(define recursive-edit-continuation)
(define recursive-edit-level)
(define current-editor)

(define (enter-recursive-edit)
  (let ((value
	 (call-with-current-continuation
	   (lambda (continuation)
	     (fluid-let ((recursive-edit-continuation continuation)
			 (recursive-edit-level (1+ recursive-edit-level)))
	       (let ((recursive-edit-event!
		      (lambda ()
			(for-each (lambda (window)
				    (window-modeline-event! window
							    'RECURSIVE-EDIT))
				  (window-list)))))
		 (dynamic-wind recursive-edit-event!
			       command-reader
			       recursive-edit-event!)))))))
    (if (eq? value 'ABORT)
	(abort-current-command)
	(begin
	  (reset-command-prompt!)
	  value))))

(define (exit-recursive-edit value)
  (if recursive-edit-continuation
      (recursive-edit-continuation value)
      (editor-error "No recursive edit is in progress")))

(define (editor-abort value)
  (editor-continuation value))

(define *^G-interrupt-continuations*
  '())

(define (^G-signal)
  (let ((continuations *^G-interrupt-continuations*))
    (if (pair? continuations)
	((car continuations))
	(error "can't signal ^G interrupt"))))

(define (intercept-^G-interrupts interceptor thunk)
  (let ((signal-tag "signal-tag"))
    (let ((value
	   (call-with-current-continuation
	     (lambda (continuation)
	       (fluid-let ((*^G-interrupt-continuations*
			    (cons (lambda () (continuation signal-tag))
				  *^G-interrupt-continuations*)))
		 (thunk))))))
      (if (eq? value signal-tag)
	  (interceptor)
	  value))))