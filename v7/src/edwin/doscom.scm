#| -*-Scheme-*-

$Id: doscom.scm,v 1.5 2003/01/10 20:24:09 cph Exp $

Copyright 1993,2003 Massachusetts Institute of Technology

This file is part of MIT Scheme.

MIT Scheme is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 2 of the License, or (at your
option) any later version.

MIT Scheme is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with MIT Scheme; if not, write to the Free Software Foundation,
Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

|#

;;;; Shell commands for DOS

(declare (usual-integrations))

(load-option 'DOSPROCESS)

(define-command shell-command
  "Execute string COMMAND in inferior shell; display output, if any.
Optional second arg true (prefix arg, if interactive) means
insert output in current buffer after point (leave mark after it)."
  "sShell command\nP"
  (lambda (command insert-at-point?)
    (let ((directory (buffer-default-directory (current-buffer))))
      (if insert-at-point?
	  (begin
	    (if (buffer-read-only? (current-buffer))
		(barf-if-read-only))
	    (let ((point (current-point)))
	      (push-current-mark! point)
	      (shell-command false point directory command))
	    ((ref-command exchange-point-and-mark)))
	  (shell-command-pop-up-output
	   (lambda (output-mark)
	      (shell-command false output-mark directory command)))))))

(define-command shell-command-on-region
  "Execute string COMMAND in inferior shell with region as input.
Normally display output (if any) in temp buffer;
Prefix arg means replace the region with it."
  "r\nsShell command on region\nP"
  (lambda (region command replace-region?)
    (let ((directory (buffer-default-directory (current-buffer))))
      (if replace-region?
	  (let ((point (current-point))
		(mark (current-mark)))
	    (let ((swap? (mark< point mark))
		  (temp))
	      (dynamic-wind
	       (lambda ()
		 (set! temp (temporary-buffer " *shell-output*"))
		 unspecific)
	       (lambda ()
		 (shell-command (make-region point mark)
				(buffer-start temp)
				directory
				command)
		 (without-interrupts
		  (lambda ()
		    (delete-string point mark)
		    (insert-region (buffer-start temp)
				   (buffer-end temp)
				   (current-point)))))
	       (lambda ()
		 (kill-buffer temp)
		 (set! temp)
		 unspecific))
	      (if swap? ((ref-command exchange-point-and-mark)))))
	  (shell-command-pop-up-output
	   (lambda (output-mark)
	     (shell-command region output-mark directory command)))))))

(define (shell-command-pop-up-output generate-output)
  (let ((buffer (temporary-buffer "*Shell Command Output*")))
    (let ((start (buffer-start buffer)))
      (generate-output start)
      (set-buffer-point! buffer start)
      (if (mark< start (buffer-end buffer))
	  (pop-up-buffer buffer false)
	  (message "(Shell Command completed with no output)")))))

(define (shell-command input-region output-mark directory command)
  (with-real-working-directory-pathname directory
    (lambda ()
      (let ((core
	     (lambda (input-port)
	       (run-subprocess command
			       input-port
			       (mark->output-port output-mark)))))
	(if input-region
	    (core (make-buffer-input-port (region-start input-region)
					  (region-end input-region)))
	    (call-with-input-file "\\dev\\nul" core))))))