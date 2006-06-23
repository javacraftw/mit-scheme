#| -*-Scheme-*-

$Id: make.scm,v 15.38 2005/03/30 03:52:20 cph Exp $

Copyright 1991,1992,1993,1995,1996,1998 Massachusetts Institute of Technology
Copyright 1999,2001,2002,2004,2005 Massachusetts Institute of Technology

This file is part of MIT/GNU Scheme.

MIT/GNU Scheme is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or (at
your option) any later version.

MIT/GNU Scheme is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with MIT/GNU Scheme; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307,
USA.

|#

;;;; 6.001: System Construction

(declare (usual-integrations))

(with-working-directory-pathname (directory-pathname (current-load-pathname))
  (lambda ()
    ((access with-directory-rewriting-rule
	     (->environment '(RUNTIME COMPILER-INFO)))
     (working-directory-pathname)
     (pathname-as-directory "6001")
     (lambda ()
       (load-package-set "6001")
       (if (and (eq? 'UNIX microcode-id/operating-system)
		(string-ci=? "HP-UX" microcode-id/operating-system-variant))
	   (load "floppy" (->environment '(EDWIN))))))))
(add-subsystem-identification! "6.001" '(15 31))

;;; Customize the runtime system:
(set! repl:allow-restart-notifications? #f)
(set! repl:write-result-hash-numbers? #f)
(set! *pp-default-as-code?* #t)
(set! *pp-named-lambda->define?* 'LAMBDA)
(set! x-graphics:auto-raise? #t)
(set! (access write-result:undefined-value-is-special?
	      (->environment '(RUNTIME USER-INTERFACE)))
      #f)
(set! hook/exit (lambda (integer) integer (warn "EXIT has been disabled.")))
(set! hook/quit (lambda () (warn "QUIT has been disabled.")))

(let ((edwin-env (->environment '(EDWIN)))
      (student-env (->environment '(STUDENT))))

  ;; These defaults will be overridden when the editor is started.
  (set! (access student-root-directory edwin-env) "~u6001/")
  (set! (access student-work-directory edwin-env) "~/work/")
  (set! (access pset-directory edwin-env) "~u6001/psets/")
  (set! (access pset-list-file edwin-env) "~u6001/psets/probsets.scm")

  (environment-define student-env 'U6001-DIR
    (lambda (filename)
      (->namestring
       (merge-pathnames filename (access student-root-directory edwin-env)))))
  (environment-define student-env 'NIL #f)

  (set! user-initial-environment student-env))

(ge user-initial-environment)