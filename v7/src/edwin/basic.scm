;;; -*-Scheme-*-
;;;
;;;	$Header: /Users/cph/tmp/foo/mit-scheme/mit-scheme/v7/src/edwin/basic.scm,v 1.98 1989/04/28 22:47:05 cph Rel $
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

;;;; Basic Commands

(declare (usual-integrations))

(define-command self-insert-command
  "Insert the character used to invoke this.
With an argument, insert the character that many times."
  "P"
  (lambda (argument)
    (insert-chars (current-command-char) (or argument 1))))

(define-command quoted-insert
  "Reads a character and inserts it."
  "P"
  (lambda (argument)
    (let ((read-char
	   (lambda ()
	     (let ((char (with-editor-interrupts-disabled keyboard-read-char)))
	       (set-command-prompt!
		(string-append (command-prompt) (char-name char)))
	       char))))
      (let ((read-digit
	     (lambda ()
	       (or (char->digit (read-char) 8)
		   (editor-error "Not an octal digit")))))
	(set-command-prompt! "Quote Character: ")
	(insert-chars (let ((char (read-char)))
			(let ((digit (char->digit char 4)))
			  (if digit
			      (ascii->char
			       (let ((digit2 (read-digit)))
				 (let ((digit3 (read-digit)))
				   (+ (* (+ (* digit 8) digit2) 8) digit3))))
			      char)))
		      (or argument 1))))))

(define-command open-line
  "Insert a newline after point.
Differs from ordinary insertion in that point remains
before the inserted characters.
With an argument, inserts several newlines."
  "P"
  (lambda (argument)
    (let ((m* (mark-right-inserting (current-point))))
      (insert-newlines (or argument 1))
      (set-current-point! m*))))

(define-command keyboard-quit
  "Signals a quit condition."
  ()
  (lambda ()
    (editor-beep)
    (temporary-message "Quit")
    (^G-signal)))

(define-command ^r-bad-command
  "This command is used to capture undefined keys.
It is usually called directly by the command lookup
procedure when it fails to find a command."
  ()
  (lambda ()
    (editor-error "Undefined command: " (xchar->name (current-command-char)))))

(define (barf-if-read-only)
  (editor-error "Trying to modify read only text."))

(define (editor-error . strings)
  (if (not (null? strings)) (apply temporary-message strings))
  (editor-beep)
  (abort-current-command))
(define (editor-failure . strings)
  (cond ((not (null? strings)) (apply temporary-message strings))
	(*defining-keyboard-macro?* (clear-message)))
  (editor-beep)
  (keyboard-macro-disable))

(define-integrable (editor-beep)
  (screen-beep (current-screen)))

(define (not-implemented)
  (editor-error "Not yet implemented"))

(define-command control-prefix
  "Sets Control-bit of following character.
This command followed by an = is equivalent to a Control-=."
  ()
  (lambda ()
    (read-extension-char "C-" char-controlify)))

(define-command meta-prefix
  "Sets Meta-bit of following character. 
Turns a following A into a Meta-A.
If the Metizer character is Altmode, it turns ^A
into Control-Meta-A.  Otherwise, it turns ^A into plain Meta-A."
  ()
  (lambda ()
    (read-extension-char "M-"
			 (if (let ((char (current-command-char)))
			       (and (char? char)
				    (char=? #\Altmode char)))
			     char-metafy
			     (lambda (char)
			       (char-metafy (char-base char)))))))

(define-command control-meta-prefix
  "Sets Control- and Meta-bits of following character.
Turns a following A (or C-A) into a Control-Meta-A."
  ()
  (lambda ()
    (read-extension-char "C-M-" char-control-metafy)))

(define execute-extended-chars?
  true)

(define extension-commands
  (list (name->command 'control-prefix)
	(name->command 'meta-prefix)
	(name->command 'control-meta-prefix)))

(define (read-extension-char prefix-string modifier)
  (if execute-extended-chars?
      (set-command-prompt-prefix! prefix-string))
  (let ((char (modifier (with-editor-interrupts-disabled keyboard-read-char))))
    (if execute-extended-chars?
	(dispatch-on-char (current-comtabs) char)
	char)))

(define (set-command-prompt-prefix! prefix-string)
  (set-command-prompt!
   (string-append-separated (command-argument-prompt)
			    prefix-string)))

(define-command prefix-char
  "This is a prefix for more commands.
It reads another character (a subcommand) and dispatches on it."
  ()
  (lambda ()
    (let ((prefix-char (current-command-char)))
      (set-command-prompt-prefix!
       (string-append (xchar->name prefix-char) " "))
      (dispatch-on-char
       (current-comtabs)
       ((if (pair? prefix-char) append cons)
	prefix-char
	(list (with-editor-interrupts-disabled keyboard-read-char)))))))

(define-command execute-extended-command
  "Read an extended command from the terminal with completion.
This command reads the name of a function, with completion.  Then the
function is called.  Completion is done as the function name is typed
For more information type the HELP key while entering the name."
  ()
  (lambda ()
    (dispatch-on-command (prompt-for-command "Extended Command") true)))

(define-command suspend-scheme
  "Go back to Scheme's superior job.
With argument, saves visited file first."
  "P"
  (lambda (argument)
    (if argument ((ref-command save-buffer) false))
    (quit)
    (update-screens! true)))

(define-command suspend-edwin
  "Stop Edwin and return to Scheme."
  ()
  (lambda ()
    (editor-abort *the-non-printing-object*)))
(define-command exit-recursive-edit
  "Exit normally from a subsystem of a level of editing.
At top level, exit from Edwin like \\[suspend-scheme]."  ()
  (lambda ()
    (exit-recursive-edit 'EXIT)))

(define-command abort-recursive-edit
  "Abnormal exit from recursive editing command.
The recursive edit is exited and the command that invoked it is aborted.
For a normal exit, you should use \\[exit-recursive-edit], NOT this command."
  ()
  (lambda ()
    (exit-recursive-edit 'ABORT)))

(define-command narrow-to-region
  "Restrict editing in current buffer to text between point and mark.
Use \\[widen] to undo the effects of this command."
  ()
  (lambda ()
    (region-clip! (current-region))))

(define-command widen
  "Remove restrictions from current buffer.
Allows full text to be seen and edited."
  ()
  (lambda ()
    (buffer-widen! (current-buffer))))

(define-command set-key
  "Define a key binding from the keyboard.
Prompts for a command and a key, and sets the key's binding.
The key is bound in fundamental mode."
  (lambda ()
    (let ((command (prompt-for-command "Command")))
      (list command
	    (prompt-for-key (string-append "Put \""
					   (command-name-string command)
					   "\" on key")
			    (mode-comtabs (ref-mode-object fundamental))))))
  (lambda (command key)
    (if (prompt-for-confirmation? "Go ahead")
	(define-key 'fundamental key (command-name command)))))
;;;; Comment Commands

(define-variable comment-column
  "Column to indent right-margin comments to."
  32)

(define-variable comment-locator-hook
  "Procedure to find a comment, or false if no comment syntax defined.
The procedure is passed a mark, and should return false if it cannot
find a comment, or a pair of marks.  The car should be the start of
the comment, and the cdr should be the end of the comment's starter."
  false)

(define-variable comment-indent-hook
  "Procedure to compute desired indentation for a comment.
The procedure is passed the start mark of the comment
and should return the column to indent the comment to."
  false)

(define-variable comment-start
  "String to insert to start a new comment."
  "")

(define-variable comment-end
  "String to insert to end a new comment.
This should be a null string if comments are terminated by Newline."
  "")

(define-command set-comment-column
  "Set the comment column based on point.
With no arg, set the comment column to the current column.
With just minus as an arg, kill any comment on this line.
Otherwise, set the comment column to the argument."
  "P"
  (lambda (argument)
    (cond ((command-argument-negative-only?)
	   ((ref-command kill-comment)))
	  (else
	   (set-variable! comment-column (or argument (current-column)))
	   (message "Comment column set to " (ref-variable comment-column))))))

(define-command indent-for-comment
  "Indent this line's comment to comment column, or insert an empty comment."
  ()
  (lambda ()
    (if (not (ref-variable comment-locator-hook))
	(editor-error "No comment syntax defined")
	(let ((start (line-start (current-point) 0))
	      (end (line-end (current-point) 0)))
	  (let ((com ((ref-variable comment-locator-hook) start)))
	    (set-current-point! (if com (car com) end))
	    (let ((comment-end (and com (mark-permanent! (cdr com)))))
	      (let ((indent
		     ((ref-variable comment-indent-hook) (current-point))))
		(maybe-change-column indent)
		(if comment-end
		    (set-current-point! comment-end)
		    (begin
		      (insert-string (ref-variable comment-start))
		      (insert-comment-end))))))))))

(define-variable comment-multi-line
  "If true, means \\[indent-new-comment-line] should continue same comment
on new line, with no new terminator or starter."
  false)

(define-command indent-new-comment-line
  "Break line at point and indent, continuing comment if presently within one."
  ()
  (lambda ()
    (delete-horizontal-space)
    (insert-newlines 1)
    (let ((if-not-in-comment
	   (lambda ()
	     (if (ref-variable fill-prefix)
		 (insert-string (ref-variable fill-prefix))
		 ((ref-command indent-according-to-mode))))))
      (if (ref-variable comment-locator-hook)
	  (let ((com ((ref-variable comment-locator-hook)
		      (line-start (current-point) -1))))
	    (if com
		(let ((start-column (mark-column (car com)))
		      (end-column (mark-column (cdr com)))
		      (comment-start (extract-string (car com) (cdr com))))
		  (if (ref-variable comment-multi-line)
		      (maybe-change-column end-column)
		      (begin (insert-string (ref-variable comment-end)
					    (line-end (current-point) -1))
			     (maybe-change-column start-column)
			     (insert-string comment-start)))
		  (if (line-end? (current-point))
		      (insert-comment-end)))
		(if-not-in-comment)))
	  (if-not-in-comment)))))

(define (insert-comment-end)
  (let ((point (mark-right-inserting (current-point))))
    (insert-string (ref-variable comment-end))
    (set-current-point! point)))

(define-command kill-comment
  "Kill the comment on this line, if any."
  ()
  (lambda ()
    (if (not (ref-variable comment-locator-hook))
	(editor-error "No comment syntax defined")
	(let ((start (line-start (current-point) 0))
	      (end (line-end (current-point) 0)))
	  (let ((com ((ref-variable comment-locator-hook) start)))
	    (if com
		(kill-string (horizontal-space-start (car com)) end)))))))