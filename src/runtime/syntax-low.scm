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

;;;; Syntax -- cold-load support

;;; Procedures to convert transformers to internal form.  Required
;;; during cold load, so must be loaded very early in the sequence.

(declare (usual-integrations))

;;; These optional arguments are needed for cross-compiling 9.2->9.3.
;;; They can become required after 9.3 release.

(define (sc-macro-transformer->expander transformer env #!optional expr)
  (expander-item (sc-wrapper transformer (runtime-getter env))
		 expr))

(define (sc-macro-transformer->keyword-item transformer closing-senv expr)
  (expander-item (sc-wrapper transformer (lambda () closing-senv))
		 expr))

(define (sc-wrapper transformer get-closing-senv)
  (wrap-no-hist
   (lambda (form use-senv)
     (close-syntax (transformer form use-senv)
		   (get-closing-senv)))))

(define (rsc-macro-transformer->expander transformer env #!optional expr)
  (expander-item (rsc-wrapper transformer (runtime-getter env))
		 expr))

(define (rsc-macro-transformer->keyword-item transformer closing-senv expr)
  (expander-item (rsc-wrapper transformer (lambda () closing-senv))
		 expr))

(define (rsc-wrapper transformer get-closing-senv)
  (wrap-no-hist
   (lambda (form use-senv)
     (close-syntax (transformer form (get-closing-senv))
		   use-senv))))

(define (er-macro-transformer->expander transformer env #!optional expr)
  (expander-item (er-wrapper transformer (runtime-getter env))
		 expr))

(define (er-macro-transformer->keyword-item transformer closing-senv expr)
  (expander-item (er-wrapper transformer (lambda () closing-senv))
		 expr))

(define (er-wrapper transformer get-closing-senv)
  (wrap-no-hist
   (lambda (form use-senv)
     (close-syntax (transformer form
				(make-er-rename (get-closing-senv))
				(make-er-compare use-senv))
		   use-senv))))

(define (make-er-rename closing-senv)
  (lambda (identifier)
    (close-syntax identifier closing-senv)))

(define (make-er-compare use-senv)
  (lambda (x y)
    (identifier=? use-senv x use-senv y)))

(define (spar-macro-transformer->expander spar env expr)
  (expander-item (spar-wrapper spar (runtime-getter env))
		 expr))

(define (spar-macro-transformer->keyword-item spar closing-senv expr)
  (expander-item (spar-wrapper spar (lambda () closing-senv))
		 expr))

(define (spar-wrapper spar get-closing-senv)
  (spar-transformer-promise-caller (delay spar) get-closing-senv))

(define (runtime-getter env)
  (lambda ()
    (runtime-environment->syntactic env)))

;;; Keyword items represent syntactic keywords.

(define (keyword-item impl #!optional expr)
  (%keyword-item impl expr))

(define-record-type <keyword-item>
    (%keyword-item impl expr)
    keyword-item?
  (impl keyword-item-impl)
  (expr keyword-item-expr))

(define (keyword-item-has-expr? item)
  (not (default-object? (keyword-item-expr item))))

(define (expander-item transformer expr)
  (keyword-item (transformer->classifier transformer)
		expr))

(define (transformer->classifier transformer)
  (lambda (form senv hist)
    (reclassify (transformer form senv hist)
		senv
		hist)))

(define (wrap-no-hist transformer)
  (lambda (form senv hist)
    (with-error-context form senv hist
      (lambda ()
	(transformer form senv)))))

(define (classifier->runtime classifier)
  (make-unmapped-macro-reference-trap (keyword-item classifier)))

(define (classifier->keyword classifier)
  (close-syntax 'keyword
		(make-keyword-senv 'keyword
				   (keyword-item classifier))))

(define (spar-classifier->runtime promise)
  (classifier->runtime (spar-classifier-promise-caller promise)))

(define (spar-classifier->keyword promise)
  (classifier->keyword (spar-classifier-promise-caller promise)))

(define (spar-classifier-promise-caller promise)
  (lambda (form senv hist)
    (spar-call (force promise) form senv hist senv)))

(define (spar-transformer->runtime promise get-closing-senv)
  (classifier->runtime
   (transformer->classifier
    (spar-transformer-promise-caller promise get-closing-senv))))

(define (spar-transformer-promise-caller promise get-closing-senv)
  (lambda (form use-senv hist)
    (spar-call (force promise) form use-senv hist (get-closing-senv))))

(define (syntactic-keyword->item keyword environment)
  (let ((item (environment-lookup-macro environment keyword)))
    (if (not item)
	(error:bad-range-argument keyword 'syntactic-keyword->item))
    item))