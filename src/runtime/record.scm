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

;;;; Records
;;; package: (runtime record)

;;; adapted from JAR's implementation
;;; conforms to R4RS proposal

(declare (usual-integrations))

(define-primitives
  (%record -1)
  (%record? 1)
  (%record-length 1)
  (%record-ref 2)
  (%record-set! 3)
  (primitive-object-ref 2)
  (primitive-object-set! 3)
  (primitive-object-set-type 2)
  (vector-cons 2))

(define (%make-record tag length #!optional init-value)
  (let ((record
	 ((ucode-primitive object-set-type)
	  (ucode-type record)
	  (vector-cons length
		       (if (default-object? init-value)
			   #f
			   init-value)))))
    (%record-set! record 0 tag)
    record))

(define-integrable (%record-tag record)
  (%record-ref record 0))

(define-integrable (%tagged-record? tag object)
  (and (%record? object)
       (eq? (%record-tag object) tag)))

(define (%tagged-record-entity? tag object)
  (and (entity? object)
       (%tagged-record? tag (entity-extra object))))

(define (%copy-record record)
  (let ((length (%record-length record)))
    (let ((result (%make-record (%record-tag record) length)))
      (do ((index 1 (fix:+ index 1)))
	  ((fix:= index length))
	(%record-set! result index (%record-ref record index)))
      result)))

(define record-type-type-tag)

(define (initialize-record-type-type!)
  (let* ((type
	  (%record #f
		   #f
		   "record-type"
		   '#(dispatch-tag name field-names default-inits
				   extension tag entity-tag)
		   (vector-cons 7 #f)
		   #f
		   #f
		   #f)))
    (set! record-type-type-tag (make-dispatch-tag type))
    (%record-set! type 0 record-type-type-tag)
    (%record-set! type 1 record-type-type-tag))
  (initialize-structure-type-type!))

(define (initialize-record-procedures!)
  (set! %set-record-type-default-inits!
	%set-record-type-default-inits!/after-boot)
  unspecific)

(define (make-record-type type-name field-names
			  #!optional
			  default-inits unparser-method entity-unparser-method)
  ;; The unparser-method and entity-unparser-method arguments should be removed
  ;; after the 9.3 release.
  (let ((caller 'MAKE-RECORD-TYPE))
    (if (not (list-of-unique-symbols? field-names))
	(error:not-a list-of-unique-symbols? field-names caller))
    (let* ((names ((ucode-primitive list->vector) field-names))
	   (n (vector-length names))
	   (record-type
	    (%record record-type-type-tag
		     #f
		     (->type-name type-name)
		     names
		     (vector-cons n #f)
		     #f
		     #f
		     #f))
	   (tag (make-dispatch-tag record-type)))
      (%record-set! record-type 1 tag)
      (if (not (default-object? default-inits))
	  (%set-record-type-default-inits! record-type default-inits caller))
      (let ((predicate
	     (lambda (object)
	       (%tagged-record? tag object)))
	    (entity-predicate
	     (lambda (object)
	       (%tagged-record-entity? tag object))))
	(%set-record-type-predicate! record-type predicate)
	(%set-record-type-entity-predicate! record-type entity-predicate)
	(if (and unparser-method
		 (not (default-object? unparser-method)))
	    (define-unparser-method predicate unparser-method))
	(if (and entity-unparser-method
		 (not (default-object? entity-unparser-method)))
	    (define-unparser-method entity-predicate entity-unparser-method)))
      record-type)))

(define (record-type? object)
  (%tagged-record? record-type-type-tag object))

(define-integrable (%record-type-descriptor record)
  (dispatch-tag-contents (%record-tag record)))

(define-integrable (%record-type-dispatch-tag record-type)
  (%record-ref record-type 1))

(define-integrable (%record-type-name record-type)
  (%record-ref record-type 2))

(define-integrable (%record-type-field-names record-type)
  (%record-ref record-type 3))

(define-integrable (%record-type-default-inits record-type)
  (%record-ref record-type 4))

(define-integrable (%record-type-extension record-type)
  (%record-ref record-type 5))

(define-integrable (%set-record-type-extension! record-type extension)
  (%record-set! record-type 5 extension))

(define-integrable (%record-type-tag record-type)
  (%record-ref record-type 6))

(define-integrable (%set-record-type-tag! record-type tag)
  (%record-set! record-type 6 tag))

(define-integrable (%record-type-entity-tag record-type)
  (%record-ref record-type 7))

(define-integrable (%set-record-type-entity-tag! record-type tag)
  (%record-set! record-type 7 tag))

(define-integrable (%record-type-n-fields record-type)
  (vector-length (%record-type-field-names record-type)))

(define-integrable (%record-type-length record-type)
  (fix:+ 1 (%record-type-n-fields record-type)))

(define-integrable (%record-type-field-name record-type index)
  (vector-ref (%record-type-field-names record-type)
	      (fix:- index 1)))

(define (record-type-dispatch-tag record-type)
  (guarantee-record-type record-type 'RECORD-TYPE-DISPATCH-TAG)
  (%record-type-dispatch-tag record-type))

(define (record-type-name record-type)
  (guarantee-record-type record-type 'RECORD-TYPE-NAME)
  (%record-type-name record-type))

(define (record-type-field-names record-type)
  (guarantee-record-type record-type 'RECORD-TYPE-FIELD-NAMES)
  ;; Can't use VECTOR->LIST here because it isn't available at cold load.
  (let ((v (%record-type-field-names record-type)))
    ((ucode-primitive subvector->list) v 0 (vector-length v))))

(define (record-type-default-inits record-type)
  (guarantee-record-type record-type 'RECORD-TYPE-DEFAULT-INITS)
  (vector->list (%record-type-default-inits record-type)))

(define (set-record-type-default-inits! record-type default-inits)
  (let ((caller 'SET-RECORD-TYPE-DEFAULT-INITS!))
    (guarantee-record-type record-type caller)
    (%set-record-type-default-inits! record-type default-inits caller)))

(define %set-record-type-default-inits!
  (lambda (record-type default-inits caller)
    caller
    (let ((v (%record-type-default-inits record-type)))
      (do ((values default-inits (cdr values))
	   (i 0 (fix:+ i 1)))
	  ((not (pair? values)))
	(vector-set! v i (car values))))))

(define %set-record-type-default-inits!/after-boot
  (named-lambda (%set-record-type-default-inits! record-type default-inits
						 caller)
    (let ((v (%record-type-default-inits record-type)))
      (if (not (fix:= (guarantee-list-of-type->length
		       default-inits
		       (lambda (init) (or (not init) (thunk? init)))
		       "default initializer" caller)
		      (vector-length v)))
	  (error:bad-range-argument default-inits caller))
      (do ((values default-inits (cdr values))
	   (i 0 (fix:+ i 1)))
	  ((not (pair? values)))
	(vector-set! v i (car values))))))

(define (record-type-default-value record-type field-name)
  (record-type-default-value-by-index
   record-type
   (record-type-field-index record-type field-name #t)))

(define (record-type-default-value-by-index record-type field-name-index)
  (let ((init (vector-ref (%record-type-default-inits record-type)
			  (fix:- field-name-index 1))))
    (and init (init))))

(define (record-type-extension record-type)
  (guarantee-record-type record-type 'RECORD-TYPE-EXTENSION)
  (%record-type-extension record-type))

(define (set-record-type-extension! record-type extension)
  (guarantee-record-type record-type 'SET-RECORD-TYPE-EXTENSION!)
  (%set-record-type-extension! record-type extension))

(define %record-type-predicate
  %record-type-tag)

(define (%set-record-type-predicate! record-type predicate)
  (defer-boot-action 'record-type-predicates
    (lambda ()
      (%set-record-type-predicate! record-type predicate)))
  (%set-record-type-tag! record-type predicate))

(define (%register-record-predicate! predicate record-type)
  (register-predicate! predicate
		       (string->symbol
			(strip-angle-brackets (%record-type-name record-type)))
		       '<= record?))

(define %record-type-entity-predicate
  %record-type-entity-tag)

(define (%set-record-type-entity-predicate! record-type predicate)
  (defer-boot-action 'record-type-predicates
    (lambda ()
      (%set-record-type-entity-predicate! record-type predicate)))
  (%set-record-type-entity-tag! record-type predicate))

(define (%register-record-entity-predicate! predicate record-type)
  (register-predicate! predicate
		       (string->symbol
			(string-append
			 (strip-angle-brackets (%record-type-name record-type))
			 "-entity"))
		       '<= record-entity?))

(define (cleanup-boot-time-record-predicates!)
  (set! %record-type-predicate
	(named-lambda (%record-type-predicate record-type)
	  (tag->predicate (%record-type-tag record-type))))
  (set! %set-record-type-predicate!
	(named-lambda (%set-record-type-predicate! record-type predicate)
	  (%register-record-predicate! predicate record-type)
	  (%set-record-type-tag! record-type (predicate->tag predicate))))
  (set! %record-type-entity-predicate
	(named-lambda (%record-type-entity-predicate record-type)
	  (tag->predicate (%record-type-entity-tag record-type))))
  (set! %set-record-type-entity-predicate!
	(named-lambda (%set-record-type-entity-predicate! record-type predicate)
	  (%register-record-entity-predicate! predicate record-type)
	  (%set-record-type-entity-tag! record-type
					(predicate->tag predicate))))
  (run-deferred-boot-actions 'record-type-predicates))

;;;; Constructors

(define (record-constructor record-type #!optional field-names)
  (guarantee-record-type record-type 'RECORD-CONSTRUCTOR)
  (if (or (default-object? field-names)
	  (equal? field-names (record-type-field-names record-type)))
      (%record-constructor-default-names record-type)
      (begin
	(if (not (list? field-names))
	    (error:not-a list? field-names 'RECORD-CONSTRUCTOR))
	(%record-constructor-given-names record-type field-names))))

(define %record-constructor-default-names
  (let-syntax
      ((expand-cases
	(sc-macro-transformer
	 (lambda (form environment)
	   (let ((tag (close-syntax (list-ref form 1) environment))
		 (n-fields (close-syntax (list-ref form 2) environment))
		 (limit (close-syntax (list-ref form 3) environment))
		 (default (close-syntax (list-ref form 4) environment))
		 (make-name
		  (lambda (i)
		    (intern (string-append "v" (number->string i))))))
	     (let loop ((i 0) (names '()))
	       (if (fix:< i limit)
		   `(IF (FIX:= ,n-fields ,i)
			(LAMBDA (,@names) (%RECORD ,tag ,@names))
			,(loop (fix:+ i 1)
			       (append names (list (make-name i)))))
		   default)))))))
    (lambda (record-type)
      (let ((tag (%record-type-dispatch-tag record-type))
	    (n-fields (%record-type-n-fields record-type)))
	(expand-cases tag n-fields 16
	  (let ((reclen (fix:+ 1 n-fields)))
	    (letrec
		((constructor
		  (lambda field-values
		    (let ((record (%make-record tag reclen))
			  (lose
			   (lambda ()
			     (error:wrong-number-of-arguments constructor
							      n-fields
							      field-values))))
		      (do ((i 1 (fix:+ i 1))
			   (vals field-values (cdr vals)))
			  ((not (fix:< i reclen))
			   (if (not (null? vals)) (lose)))
			(if (not (pair? vals)) (lose))
			(%record-set! record i (car vals)))
		      record))))
	      constructor)))))))

(define (%record-constructor-given-names record-type field-names)
  (let* ((indexes
	  (map (lambda (field-name)
		 (record-type-field-index record-type field-name #t))
	       field-names))
	 (defaults
	   (let* ((n (%record-type-length record-type))
		  (seen? (vector-cons n #f)))
	     (do ((indexes indexes (cdr indexes)))
		 ((not (pair? indexes)))
	       (vector-set! seen? (car indexes) #t))
	     (do ((i 1 (fix:+ i 1))
		  (k 0 (if (vector-ref seen? i) k (fix:+ k 1))))
		 ((not (fix:< i n))
		  (let ((v (vector-cons k #f)))
		    (do ((i 1 (fix:+ i 1))
			 (j 0
			    (if (vector-ref seen? i)
				j
				(begin
				  (vector-set! v j i)
				  (fix:+ j 1)))))
			((not (fix:< i n))))
		    v))))))
    (letrec
	((constructor
	  (lambda field-values
	    (let ((lose
		   (lambda ()
		     (error:wrong-number-of-arguments constructor
						      (length indexes)
						      field-values))))
	      (let ((record
		     (%make-record (%record-type-dispatch-tag record-type)
				   (%record-type-length record-type))))
		(do ((indexes indexes (cdr indexes))
		     (values field-values (cdr values)))
		    ((not (pair? indexes))
		     (if (not (null? values)) (lose)))
		  (if (not (pair? values)) (lose))
		  (%record-set! record (car indexes) (car values)))
		(let ((v (%record-type-default-inits record-type))
		      (n (vector-length defaults)))
		  (do ((i 0 (fix:+ i 1)))
		      ((not (fix:< i n)))
		    (let* ((index (vector-ref defaults i))
			   (init (vector-ref v (fix:- index 1))))
		      (and init (%record-set! record index (init))))))
		record)))))
      constructor)))

(define (record-keyword-constructor record-type)
  (letrec
      ((constructor
	(lambda keyword-list
	  (let ((n (%record-type-length record-type)))
	    (let ((record
                   (%make-record (%record-type-dispatch-tag record-type) n))
		  (seen? (vector-cons n #f)))
	      (do ((kl keyword-list (cddr kl)))
		  ((not (and (pair? kl)
			     (symbol? (car kl))
			     (pair? (cdr kl))))
		   (if (not (null? kl))
		       (error:not-a keyword-list? keyword-list constructor)))
		(let ((i (record-type-field-index record-type (car kl) #t)))
		  (if (not (vector-ref seen? i))
		      (begin
			(%record-set! record i (cadr kl))
			(vector-set! seen? i #t)))))
	      (let ((v (%record-type-default-inits record-type)))
		(do ((i 1 (fix:+ i 1)))
		    ((not (fix:< i n)))
		  (if (not (vector-ref seen? i))
		      (let ((init (vector-ref v (fix:- i 1))))
			(and init (%record-set! record i (init)))))))
	      record)))))
    constructor))

(define (record? object)
  (and (%record? object)
       (dispatch-tag? (%record-tag object))
       (record-type? (dispatch-tag-contents (%record-tag object)))))

(define (record-entity? object)
  (and (entity? object)
       (record? (entity-extra object))))

(define (record-type-descriptor record)
  (guarantee-record record 'RECORD-TYPE-DESCRIPTOR)
  (%record-type-descriptor record))

(define (copy-record record)
  (guarantee-record record 'COPY-RECORD)
  (%copy-record record))

(define (record-predicate record-type)
  (guarantee-record-type record-type 'RECORD-PREDICATE)
  (%record-type-predicate record-type))

(define (record-entity-predicate record-type)
  (guarantee-record-type record-type 'record-entity-predicate)
  (%record-type-entity-predicate record-type))

(define (record-accessor record-type field-name)
  (guarantee-record-type record-type 'RECORD-ACCESSOR)
  (let ((tag (record-type-dispatch-tag record-type))
	(index (record-type-field-index record-type field-name #t)))
    (letrec ((accessor
	      (lambda (record)
		(if (not (%tagged-record? tag record))
		    (error:not-tagged-record record record-type accessor))
		(%record-ref record index))))
      accessor)))

(define (record-modifier record-type field-name)
  (guarantee-record-type record-type 'RECORD-MODIFIER)
  (let ((tag (record-type-dispatch-tag record-type))
	(index (record-type-field-index record-type field-name #t)))
    (letrec ((modifier
	      (lambda (record field-value)
		(if (not (%tagged-record? tag record))
		    (error:not-tagged-record record record-type modifier))
		(%record-set! record index field-value))))
      modifier)))

(define (error:not-tagged-record record record-type modifier)
  (error:wrong-type-argument record
			     (string-append "record of type "
					    (%record-type-name record-type))
			     modifier))

(define record-copy copy-record)
(define record-updater record-modifier)

(define (record-type-field-index record-type name error?)
  ;; Can't use VECTOR->LIST here because it isn't available at cold load.
  (let* ((names (%record-type-field-names record-type))
	 (n (vector-length names)))
    (let loop ((i 0))
      (if (fix:< i n)
	  (if (eq? (vector-ref names i) name)
	      (fix:+ i 1)
	      (loop (fix:+ i 1)))
	  (and error?
	       (record-type-field-index record-type
					(error:no-such-slot record-type name)
					error?))))))

(define (->type-name object)
  (cond ((string? object) (string->immutable object))
	((symbol? object) (symbol->string object))
	(else (error:wrong-type-argument object "type name" #f))))

(define (list-of-unique-symbols? object)
  (and (list-of-type? object symbol?)
       (let loop ((elements object))
	 (if (pair? elements)
	     ;; No memq in the cold load.
	     (let memq ((item (car elements))
			(tail (cdr elements)))
	       (cond ((pair? tail) (if (eq? item (car tail))
				       #f
				       (memq item (cdr tail))))
		     ((null? tail) (loop (cdr elements)))
		     (else (error "Improper list."))))
	     #t))))

(define-guarantee record-type "record type")
(define-guarantee record "record")

;;;; Printing

(define-unparser-method %record?
 (standard-unparser-method 'record #f))

(define-unparser-method record?
  (standard-unparser-method
   (lambda (record)
     (strip-angle-brackets
      (%record-type-name (%record-type-descriptor record))))
   #f))

(define-unparser-method record-type?
  (standard-unparser-method 'record-type
    (lambda (type port)
      (write-char #\space port)
      (display (%record-type-name type) port))))

(define-unparser-method dispatch-tag?
  (simple-unparser-method 'dispatch-tag
    (lambda (tag)
      (list (dispatch-tag-contents tag)))))

(define (set-record-type-unparser-method! record-type method)
  (define-unparser-method (record-predicate record-type)
    method))

(define-pp-describer %record?
  (lambda (record)
    (let loop ((i (fix:- (%record-length record) 1)) (d '()))
      (if (fix:< i 0)
	  d
	  (loop (fix:- i 1)
		(cons (list i (%record-ref record i)) d))))))

(define-pp-describer record?
  (lambda (record)
    (let ((type (%record-type-descriptor record)))
      (map (lambda (field-name)
	     `(,field-name
	       ,((record-accessor type field-name) record)))
	   (record-type-field-names type)))))

(define (set-record-type-describer! record-type describer)
  (define-pp-describer (record-predicate record-type)
    describer))

(define (set-record-type-entity-unparser-method! record-type method)
  (define-unparser-method (record-entity-predicate record-type)
    method))

(define (set-record-type-entity-describer! record-type describer)
  (define-pp-describer (record-entity-predicate record-type)
    describer))

;;;; Runtime support for DEFINE-STRUCTURE

(define (initialize-structure-type-type!)
  (set! rtd:structure-type
	(make-record-type "structure-type"
			  '(PHYSICAL-TYPE NAME FIELD-NAMES FIELD-INDEXES
					  DEFAULT-INITS TAG LENGTH)))
  (set! make-define-structure-type
	(let ((constructor (record-constructor rtd:structure-type)))
	  (lambda (physical-type name field-names field-indexes default-inits
				 unparser-method tag length)
	    ;; unparser-method arg should be removed after 9.3 is released.
	    (declare (ignore unparser-method))
	    (constructor physical-type
			 name
			 field-names
			 field-indexes
			 default-inits
			 tag
			 length))))
  (set! structure-type?
	(record-predicate rtd:structure-type))
  (set! structure-type/physical-type
	(record-accessor rtd:structure-type 'PHYSICAL-TYPE))
  (set! structure-type/name
	(record-accessor rtd:structure-type 'NAME))
  (set! structure-type/field-names
	(record-accessor rtd:structure-type 'FIELD-NAMES))
  (set! structure-type/field-indexes
	(record-accessor rtd:structure-type 'FIELD-INDEXES))
  (set! structure-type/default-inits
	(record-accessor rtd:structure-type 'DEFAULT-INITS))
  (set! structure-type/tag
	(record-accessor rtd:structure-type 'TAG))
  (set! structure-type/length
	(record-accessor rtd:structure-type 'LENGTH))
  unspecific)

(define rtd:structure-type)
(define make-define-structure-type)
(define structure-type?)
(define structure-type/physical-type)
(define structure-type/name)
(define structure-type/field-names)
(define structure-type/field-indexes)
(define structure-type/default-inits)
(define structure-type/unparser-method)
(define set-structure-type/unparser-method!)
(define structure-type/tag)
(define structure-type/length)

(define-integrable (structure-type/field-index type field-name)
  (vector-ref (structure-type/field-indexes type)
	      (structure-type/field-name-index type field-name)))

(define-integrable (structure-type/default-init type field-name)
  (structure-type/default-init-by-index
   type
   (structure-type/field-name-index type field-name)))

(define-integrable (structure-type/default-init-by-index type field-name-index)
  (vector-ref (structure-type/default-inits type) field-name-index))

(define (structure-type/field-name-index type field-name)
  (let ((names (structure-type/field-names type)))
    (let ((n (vector-length names)))
      (let loop ((i 0))
	(if (not (fix:< i n))
	    (error:no-such-slot type field-name))
	(if (eq? (vector-ref names i) field-name)
	    i
	    (loop (fix:+ i 1)))))))

(define (named-structure? object)
  (or (named-list? object)
      (named-vector? object)
      (record? object)))

(define (named-list? object)
  (and (pair? object)
       (structure-type-tag? (car object) 'list)
       (list? (cdr object))))

(define (named-vector? object)
  (and (vector? object)
       (fix:> (vector-length object) 0)
       (structure-type-tag? (vector-ref object 0) 'vector)))

(define (structure-type-tag? tag physical-type)
  (let ((type (tag->structure-type tag)))
    (and type
	 (eq? (structure-type/physical-type type) physical-type))))

(define (tag->structure-type tag)
  (if (structure-type? tag)
      tag
      (let ((type (named-structure/get-tag-description tag)))
	(and (structure-type? type)
	     type))))

(define-pp-describer named-list?
  (lambda (pair)
    (let ((type (tag->structure-type (car pair))))
      (map (lambda (field-name index)
	     `(,field-name ,(list-ref pair index)))
	   (vector->list (structure-type/field-names type))
	   (vector->list (structure-type/field-indexes type))))))

(define-pp-describer named-vector?
  (lambda (vector)
    (let ((type (tag->structure-type (vector-ref vector 0))))
      (map (lambda (field-name index)
	     `(,field-name ,(vector-ref vector index)))
	   (vector->list (structure-type/field-names type))
	   (vector->list (structure-type/field-indexes type))))))

(define (define-structure/default-value type field-name)
  ((structure-type/default-init type field-name)))

(define (define-structure/default-value-by-index type field-name-index)
  ((structure-type/default-init-by-index type field-name-index)))

(define (define-structure/keyword-constructor type)
  (let ((names (structure-type/field-names type))
	(indexes (structure-type/field-indexes type))
	(inits (structure-type/default-inits type))
	(tag (structure-type/tag type))
	(len (structure-type/length type)))
    (let ((n (vector-length names)))
      (lambda arguments
	(let ((v (vector-cons len #f)))
	  (if tag
	      (vector-set! v 0 tag))
	  (let ((seen? (make-vector n #f)))
	    (do ((args arguments (cddr args)))
		((not (pair? args)))
	      (if (not (pair? (cdr args)))
		  (error:not-a keyword-list? arguments #f))
	      (let ((field-name (car args)))
		(let loop ((i 0))
		  (if (not (fix:< i n))
		      (error:no-such-slot type field-name))
		  (if (eq? (vector-ref names i) field-name)
		      (if (not (vector-ref seen? i))
			  (begin
			    (vector-set! v
					 (vector-ref indexes i)
					 (cadr args))
			    (vector-set! seen? i #t)))
		      (loop (fix:+ i 1))))))
	    (do ((i 0 (fix:+ i 1)))
		((not (fix:< i n)))
	      (if (not (vector-ref seen? i))
		  (let ((init (vector-ref inits i)))
		    (and init (vector-set! v (vector-ref indexes i) (init)))))))
	  (if (eq? (structure-type/physical-type type) 'LIST)
	      (do ((i (fix:- len 1) (fix:- i 1))
		   (list '() (cons (vector-ref v i) list)))
		  ((not (fix:>= i 0)) list))
	      v))))))

;;;; Support for safe accessors

(define (define-structure/vector-accessor type field-name)
  (let ((index (structure-type/field-index type field-name)))
    (if (structure-type/tag type)
	(lambda (structure)
	  (check-vector-tagged structure type)
	  (vector-ref structure index))
	(lambda (structure)
	  (check-vector-untagged structure type)
	  (vector-ref structure index)))))

(define (define-structure/vector-modifier type field-name)
  (let ((index (structure-type/field-index type field-name)))
    (if (structure-type/tag type)
	(lambda (structure value)
	  (check-vector-tagged structure type)
	  (vector-set! structure index value))
	(lambda (structure value)
	  (check-vector-untagged structure type)
	  (vector-set! structure index value)))))

(define (define-structure/list-accessor type field-name)
  (let ((index (structure-type/field-index type field-name)))
    (if (structure-type/tag type)
	(lambda (structure)
	  (check-list-tagged structure type)
	  (list-ref structure index))
	(lambda (structure)
	  (check-list-untagged structure type)
	  (list-ref structure index)))))

(define (define-structure/list-modifier type field-name)
  (let ((index (structure-type/field-index type field-name)))
    (if (structure-type/tag type)
	(lambda (structure value)
	  (check-list-tagged structure type)
	  (set-car! (list-tail structure index) value))
	(lambda (structure value)
	  (check-list-untagged structure type)
	  (set-car! (list-tail structure index) value)))))

(define-integrable (check-vector-tagged structure type)
  (if (not (and (vector? structure)
		(fix:= (vector-length structure)
		       (structure-type/length type))
		(eq? (vector-ref structure 0) (structure-type/tag type))))
      (error:wrong-type-argument structure type #f)))

(define-integrable (check-vector-untagged structure type)
  (if (not (and (vector? structure)
		(fix:= (vector-length structure)
		       (structure-type/length type))))
      (error:wrong-type-argument structure type #f)))

(define-integrable (check-list-tagged structure type)
  (if (not (and (eq? (list?->length structure) (structure-type/length type))
		(eq? (car structure) (structure-type/tag type))))
      (error:wrong-type-argument structure type #f)))

(define-integrable (check-list-untagged structure type)
  (if (not (eq? (list?->length structure) (structure-type/length type)))
      (error:wrong-type-argument structure type #f)))

;;;; Conditions

(define condition-type:slot-error)
(define condition-type:uninitialized-slot)
(define condition-type:no-such-slot)
(define error:uninitialized-slot)
(define error:no-such-slot)

(define (initialize-conditions!)
  (set! condition-type:slot-error
	(make-condition-type 'SLOT-ERROR condition-type:cell-error
	    '()
	  (lambda (condition port)
	    (write-string "Anonymous error for slot " port)
	    (write (access-condition condition 'LOCATION) port)
	    (write-string "." port))))
  (set! condition-type:uninitialized-slot
	(make-condition-type 'UNINITIALIZED-SLOT condition-type:slot-error
	    '(RECORD)
	  (lambda (condition port)
	    (write-string "Attempt to reference slot " port)
	    (write (access-condition condition 'LOCATION) port)
	    (write-string " in record " port)
	    (write (access-condition condition 'RECORD) port)
	    (write-string " failed because the slot is not initialized."
			  port))))
  (set! condition-type:no-such-slot
	(make-condition-type 'NO-SUCH-SLOT condition-type:slot-error
	    '(RECORD-TYPE)
	  (lambda (condition port)
	    (write-string "No slot named " port)
	    (write (access-condition condition 'LOCATION) port)
	    (write-string " in records of type " port)
	    (write (access-condition condition 'RECORD-TYPE) port)
	    (write-string "." port))))
  (set! error:uninitialized-slot
	(let ((signal
	       (condition-signaller condition-type:uninitialized-slot
				    '(RECORD LOCATION)
				    standard-error-handler)))
	  (lambda (record index)
	    (let* ((location (%record-field-name record index))
		   (ls (write-to-string location)))
	      (call-with-current-continuation
	       (lambda (k)
		 (store-value-restart ls
				      (lambda (value)
					(%record-set! record index value)
					(k value))
		   (lambda ()
		     (use-value-restart
		      (string-append
		       "value to use instead of the contents of slot "
		       ls)
		      k
		      (lambda () (signal record location)))))))))))
  (set! error:no-such-slot
	(let ((signal
	       (condition-signaller condition-type:no-such-slot
				    '(RECORD-TYPE LOCATION)
				    standard-error-handler)))
	  (lambda (record-type name)
	    (call-with-current-continuation
	     (lambda (k)
	       (use-value-restart
		(string-append "slot name to use instead of "
			       (write-to-string name))
		k
		(lambda () (signal record-type name))))))))
  unspecific)

(define (%record-field-name record index)
  (or (and (fix:> index 0)
	   (record? record)
	   (let ((names
		  (%record-type-field-names (%record-type-descriptor record))))
	     (and (fix:<= index (vector-length names))
		  (vector-ref names (fix:- index 1)))))
      index))

(define (record-type-field-name record-type index)
  (guarantee record-type? record-type 'record-type-field-name)
  (%record-type-field-name record-type index))

(define (store-value-restart location k thunk)
  (let ((location (write-to-string location)))
    (with-restart 'store-value
	(string-append "Initialize slot " location " to a given value.")
	k
	(string->interactor (string-append "Set " location " to"))
      thunk)))

(define (use-value-restart noun-phrase k thunk)
  (with-restart 'use-value
      (string-append "Specify a " noun-phrase ".")
      k
      (string->interactor (string-titlecase noun-phrase))
    thunk))

(define ((string->interactor string))
  (values (prompt-for-evaluated-expression string)))