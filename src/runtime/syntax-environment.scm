#| -*-Scheme-*-

Copyright (C) 1986, 1987, 1988, 1989, 1990, 1991, 1992, 1993, 1994,
    1995, 1996, 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
    2006, 2007, 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016,
    2017 Massachusetts Institute of Technology

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
Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301,
USA.

|#

;;;; Syntactic Environments

(declare (usual-integrations))

(define (runtime-environment->syntactic env)
  (cond ((interpreter-environment? env) (%top-level-runtime-senv env))
	((environment? env) (%internal-runtime-senv env))
	(else (error:not-a environment? env 'runtime-environment->syntactic))))

(define (senv->runtime senv)
  ((senv-get-runtime senv)))

(define (senv-top-level? senv)
  (eq? 'top-level ((senv-get-type senv))))

(define ((id-dispatcher handle-raw caller) identifier senv)
  (cond ((raw-identifier? identifier)
	 (handle-raw identifier senv))
	((closed-identifier? identifier)
	 (handle-raw (syntactic-closure-form identifier)
		     (syntactic-closure-senv identifier)))
	(else
	 (error:not-a identifier? identifier caller))))

(define lookup-identifier
  (id-dispatcher (lambda (identifier senv)
		   (or ((senv-lookup senv) identifier)
		       (var-item identifier)))
		 'lookup-identifier))

(define reserve-identifier
  (id-dispatcher (lambda (identifier senv)
		   ((senv-store senv) identifier (reserved-name-item)))
		 'reserve-identifier))

(define (bind-keyword identifier senv item)
  (guarantee keyword-item? item 'bind-keyword)
  ((id-dispatcher (lambda (identifier senv)
		    ((senv-store senv) identifier item))
		  'bind-keyword)
   identifier
   senv))

(define bind-variable
  (id-dispatcher (lambda (identifier senv)
		   (let ((rename ((senv-rename senv) identifier)))
		     ((senv-store senv) identifier (var-item rename))
		     rename))
		 'bind-variable))

(define-record-type <syntactic-environment>
    (make-senv get-type get-runtime lookup store rename describe)
    syntactic-environment?
  (get-type senv-get-type)
  (get-runtime senv-get-runtime)
  (lookup senv-lookup)
  (store senv-store)
  (rename senv-rename)
  (describe senv-describe))

(define-unparser-method syntactic-environment?
  (simple-unparser-method 'syntactic-environment
    (lambda (senv)
      (list ((senv-get-type senv))))))

(define-pp-describer syntactic-environment?
  (lambda (senv)
    ((senv-describe senv))))

;;; Runtime syntactic environments are wrappers around runtime environments.

;;; Wrappers around top-level runtime environments.
(define (%top-level-runtime-senv env)
  (let ((bound '()))

    (define (get-type)
      'top-level)

    (define (get-runtime)
      env)

    (define (lookup identifier)
      (let ((binding (assq identifier bound)))
	(if binding
	    (cdr binding)
	    (environment-lookup-macro env identifier))))

    (define (store identifier item)
      (let ((binding (assq identifier bound)))
	(if binding
	    (set-cdr! binding item)
	    (begin
	      (set! bound (cons (cons identifier item) bound))
	      unspecific))))

    (define (rename identifier)
      identifier)

    (define (describe)
      `((env ,env)
	(bound ,bound)))

    (make-senv get-type get-runtime lookup store rename describe)))

;;; Wrappers around internal runtime environments.
(define (%internal-runtime-senv env)

  (define (get-type)
    'internal-runtime)

  (define (get-runtime)
    env)

  (define (lookup identifier)
    (environment-lookup-macro env identifier))

  (define (store identifier item)
    (error "Can't bind in non-top-level runtime environment:" identifier item))

  (define (rename identifier)
    (error "Can't rename in non-top-level runtime environment:" identifier))

  (define (describe)
    `((env ,env)))

  (make-senv get-type get-runtime lookup store rename describe))

;;; Keyword environments are used to make keywords that represent items.

(define (make-keyword-senv name item)

  (define (get-type)
    'keyword)

  (define (get-runtime)
    (error "Can't evaluate in keyword environment."))

  (define (lookup identifier)
    (and (eq? name identifier)
	 item))

  (define (store identifier item)
    (error "Can't bind in keyword environment:" identifier item))

  (define (rename identifier)
    (error "Can't rename in keyword environment:" identifier))

  (define (describe)
    `((name ,name)
      (item ,item)))

  (guarantee raw-identifier? name 'make-keyword-environment)
  (guarantee keyword-item? item 'make-keyword-environment)
  (make-senv get-type get-runtime lookup store rename describe))

;;; Internal syntactic environments represent environments created by
;;; procedure application.

(define (make-internal-senv parent)
  (guarantee syntactic-environment? parent 'make-internal-senv)
  (let ((bound '())
	(free '())
	(get-runtime (senv-get-runtime parent))
	(rename (make-local-identifier-renamer)))

    (define (get-type)
      'internal)

    (define (lookup identifier)
      (let ((binding
	     (or (assq identifier bound)
		 (assq identifier free))))
	(if binding
	    (cdr binding)
	    (let ((item ((senv-lookup parent) identifier)))
	      (set! free (cons (cons identifier item) free))
	      item))))

    (define (store identifier item)
      (cond ((assq identifier bound)
	     => (lambda (binding)
		  (set-cdr! binding item)))
	    ((assq identifier free)
	     (error "Can't define name; already free:" identifier))
	    (else
	     (set! bound (cons (cons identifier item) bound))
	     unspecific)))

    (define (describe)
      `((bound ,bound)
	(free ,free)
	(parent ,parent)))

    (make-senv get-type get-runtime lookup store rename describe)))

;;; Partial syntactic environments are used to implement syntactic
;;; closures that have free names.

(define (make-partial-senv free-ids free-senv bound-senv)
  (let ((caller 'make-partial-senv))
    (guarantee list-of-unique-symbols? free-ids caller)
    (guarantee syntactic-environment? free-senv caller)
    (guarantee syntactic-environment? bound-senv caller))
  (if (or (null? free-ids)
	  (eq? free-senv bound-senv))
      bound-senv
      (let ()
	(define (get-type)
	  'partial)

	(define (get-runtime)
	  ;; **** Shouldn't this be a syntax error?  It can happen as the
	  ;; result of a partially-closed transformer.  ****
	  (error "Can't evaluate in partial syntactic environment"))

	(define (lookup identifier)
	  ((senv-lookup (select-env identifier)) identifier))

	(define (store identifier item)
	  ;; **** Shouldn't this be a syntax error?  It can happen as the
	  ;; result of a misplaced definition.  ****
	  (error "Can't bind identifier in partial syntactic environment:"
		 identifier item))

	(define (rename identifier)
	  ((senv-rename (select-env identifier)) identifier))

	(define (select-env identifier)
	  (if (memq identifier free-ids) free-senv bound-senv))

	(define (describe)
	  `((free-ids ,free-ids)
	    (free-senv ,free-senv)
	    (bound-senv ,bound-senv)))

	(make-senv get-type get-runtime lookup store rename describe))))