#| -*-Scheme-*-

$Header: /Users/cph/tmp/foo/mit-scheme/mit-scheme/v7/src/runtime/hash.scm,v 14.3 1991/08/16 15:40:17 jinx Exp $

Copyright (c) 1988-91 Massachusetts Institute of Technology

This material was developed by the Scheme project at the Massachusetts
Institute of Technology, Department of Electrical Engineering and
Computer Science.  Permission to copy this software, to redistribute
it, and to use it for any purpose is granted, subject to the following
restrictions and understandings.

1. Any copy made of this software must include this copyright notice
in full.

2. Users of this software agree to make their best efforts (a) to
return to the MIT Scheme project any improvements or extensions that
they make, so that these may be included in future releases; and (b)
to inform MIT of noteworthy uses of this software.

3. All materials developed as a consequence of the use of this
software shall duly acknowledge such use, in accordance with the usual
standards of acknowledging credit in academic research.

4. MIT has made no warrantee or representation that the operation of
this software will be error-free, and MIT is under no obligation to
provide any services, by way of maintenance, update, or otherwise.

5. In conjunction with products arising from the use of this material,
there shall be no use of the name of the Massachusetts Institute of
Technology nor of any adaptation thereof in any advertising,
promotional, or sales literature without prior written consent from
MIT in each case. |#

;;;; Object Hashing
;;; package: (runtime hash)

(declare (usual-integrations))

;;;; Object hashing

;;; The hashing code depends on weak conses supported by the
;;; microcode.  In particular, it depends on the fact that the car of
;;; a weak cons becomes #F if the object is garbage collected.

;;; Important: This code must be rewritten for a parallel processor,
;;; since two processors may be updating the data structures
;;; simultaneously.

;;; How this works:

;;; There are two tables, the hash table and the unhash table:

;;; - The hash table associates objects to their hash numbers.  The
;;; entries are keyed according to the address (datum) of the object,
;;; and thus must be recomputed after every relocation (ie. band
;;; loading, garbage collection, etc.).

;;; - The unhash table associates the hash numbers with the
;;; corresponding objects.  It is keyed according to the numbers
;;; themselves.

;;; In order to make the hash and unhash tables weakly hold the
;;; objects hashed, the following mechanism is used:

;;; The hash table, a vector, has a SNMV header before all the
;;; buckets, and therefore the garbage collector will skip it and will
;;; not relocate its buckets.  It becomes invalid after a garbage
;;; collection and the first thing the daemon does is clear it.  Each
;;; bucket is a normal alist with the objects in the cars, and the
;;; numbers in the cdrs, thus assq can be used to find an object in
;;; the bucket.

;;; The unhash table, also a vector, holds the objects by means of
;;; weak conses.  These weak conses are the same as the pairs in the
;;; buckets in the hash table, but with their type codes changed.
;;; Each of the buckets in the unhash table is headed by an extra pair
;;; whose car is usually #T.  This pair is used by the splicing code.
;;; The daemon treats buckets headed by #F differently from buckets
;;; headed by #T.  A bucket headed by #T is compressed: Those pairs
;;; whose cars have disappeared are spliced out from the bucket.  On
;;; the other hand, buckets headed by #F are not compressed.  The
;;; intent is that while object-unhash is traversing a bucket, the
;;; bucket is locked so that the daemon will not splice it out behind
;;; object-unhash's back.  Then object-unhash does not need to be
;;; locked against garbage collection.

(define default/hash-table-size 313)
(define default-hash-table)
(define all-hash-tables)

(define (initialize-package!)
  (set! all-hash-tables (weak-cons 0 '()))
  (set! default-hash-table (hash-table/make))
  (add-event-receiver! event:after-restore (lambda () (gc-flip)))
  (add-gc-daemon! rehash-all-gc-daemon))

(define-structure (hash-table
		   (conc-name hash-table/)
		   (constructor %hash-table/make))
  (size)
  (next-number)
  (hash-table)
  (unhash-table))

(define (hash-table/make #!optional size)
  (let* ((size (if (default-object? size)
		   default/hash-table-size
		   size))
	 (table
	  (%hash-table/make
	   size
	   1
	   (let ((table (make-vector (1+ size) '())))
	     (vector-set! table
			  0
			  ((ucode-primitive primitive-object-set-type)
			   (ucode-type manifest-special-nm-vector)
			   (make-non-pointer-object size)))
	     ((ucode-primitive primitive-object-set-type)
	      (ucode-type non-marked-vector)
	      table))
	   (let ((table (make-vector size '())))
	     (let loop ((n 0))
	       (if (fix:< n size)
		   (begin
		     (vector-set! table n (cons true '()))
		     (loop (fix:+ n 1)))))
	     table))))
    (weak-set-cdr! all-hash-tables
		   (weak-cons table (weak-cdr all-hash-tables)))
    table))

(define (hash x #!optional table)
  (if (eq? x false)
      0
      (object-hash x
		   (if (default-object? table)
		       default-hash-table
		       table)
		   true)))

(define (unhash n #!optional table)
  (if (zero? n)
      false
      (let ((table (if (default-object? table)
		       default-hash-table
		       table)))
	(or (object-unhash n table)
	    (error "unhash: Not a valid hash number" n table)))))

(define (valid-hash-number? n #!optional table)
  (or (zero? n)
      (object-unhash n (if (default-object? table)
			   default-hash-table
			   table))))

(define (object-hashed? n #!optional table)
  (or (eq? x false)
      (object-hash x
		   (if (default-object? table)
		       default-hash-table
		       table)
		   false)))  

;;; This is not dangerous because assq is a primitive and does not
;;; cons.  The rest of the consing (including that by the interpreter)
;;; is a small bounded amount.
;;;
;;; NOTE: assq is no longer a primitive.  This works fine if assq is
;;; compiled, but can lose if it is interpreted.

(define (object-hash object #!optional table insert?)
  (let ((table (cond ((default-object? table)
		      default-hash-table)
		     ((hash-table? table)
		      table)
		     (else
		      (error "object-hash: Not a hash table" table))))
	(insert? (or (default-object? insert?)
		     insert?)))
    (with-absolutely-no-interrupts
      (lambda ()
	(let* ((hash-index (fix:+ 1
				  (modulo (object-datum object)
					  (hash-table/size table))))
	       (the-hash-table
		((ucode-primitive primitive-object-set-type)
		 (ucode-type vector)
		 (hash-table/hash-table table)))
	       (bucket (vector-ref the-hash-table hash-index))
	       (association (assq object bucket)))
	  (cond (association
		 (cdr association))
		((not insert?)
		 false)
		(else
		 (let ((result (hash-table/next-number table)))
		   (let ((pair (cons object result))
			 (unhash-bucket
			  (vector-ref (hash-table/unhash-table table)
				      (modulo result
					      (hash-table/size table)))))
		     (set-hash-table/next-number! table (1+ result))
		     (vector-set! the-hash-table
				  hash-index
				  (cons pair bucket))
		     (set-cdr! unhash-bucket
			       (cons (object-new-type (ucode-type weak-cons) pair)
				     (cdr unhash-bucket)))
		     result)))))))))

;;; This is safe because it locks the garbage collector out only for a
;;; little time, enough to tag the bucket being searched, so that the
;;; daemon will not splice that bucket.

(define (object-unhash number #!optional table)
  (let* ((table (cond ((default-object? table)
		       default-hash-table)
		      ((hash-table? table)
		       table)
		      (else
		       (error "object-hash: Not a hash table" table))))
	 (index (modulo number (hash-table/size table))))
    (with-absolutely-no-interrupts
      (lambda ()
	(let ((bucket (vector-ref (hash-table/unhash-table table) index)))
	  (set-car! bucket false)
	  (let ((result
		 (without-interrupts
		   (lambda ()
		     (let loop ((l (cdr bucket)))
		       (cond ((null? l) false)
			     ((= number (system-pair-cdr (car l)))
			      (system-pair-car (car l)))
			     (else (loop (cdr l)))))))))
	    (set-car! bucket true)
	    result))))))

;;;; Rehash daemon

;;; The following is dangerous because of the (unnecessary) consing
;;; done by the interpreter while it executes the loops.  It runs with
;;; interrupts turned off.  The (necessary) consing done by rehash is
;;; not dangerous because at least that much storage was freed by the
;;; garbage collector.  To understand this, notice that the hash table
;;; has a SNMV header, so the garbage collector does not trace the
;;; hash table buckets, therefore freeing their storage.  The header
;;; is SNM rather than NM to make the buckets be relocated at band
;;; load/restore time.

;;; Until this code is compiled, and therefore safe, it is replaced by
;;; a primitive.  See the installation code below.
#|
(define (hash-table/rehash table)
  (let ((hash-table-size (hash-table/size table))
	(hash-table ((ucode-primitive primitive-object-set-type)
		     (ucode-type vector)
		     (hash-table/hash-table table)))
	(unhash-table (hash-table/unhash-table table)))

    (define (rehash weak-pair)
      (let ((index
	     (fix:+ 1 (modulo (object-datum (system-pair-car weak-pair))
			      hash-table-size))))
	(vector-set! hash-table
		     index
		     (cons (object-new-type (ucode-type pair) weak-pair)
			   (vector-ref hash-table index)))
	unspecific))

    (let cleanup ((n hash-table-size))
      (if (not (fix:= n 0))
	  (begin
	    (vector-set! hash-table n '())
	    (cleanup (fix:- n 1)))))

    (let outer ((n (fix:- hash-table-size 1)))
      (if (not (fix:< n 0))
	  (let ((bucket (vector-ref unhash-table n)))
	    (if (car bucket)
		(let inner1 ((l1 bucket) (l2 (cdr bucket)))
		  (cond ((null? l2)
			 (outer (fix:- n 1)))
			((eq? (system-pair-car (car l2)) false)
			 (set-cdr! l1 (cdr l2))
			 (inner1 l1 (cdr l1)))
			(else
			 (rehash (car l2))
			 (inner1 l2 (cdr l2)))))
		(let inner2 ((l (cdr bucket)))
		  (cond ((null? l)
			 (outer (fix:- n 1)))
			((eq? (system-pair-car (car l)) false)
			 (inner2 (cdr l)))
			(else
			 (rehash (car l))
			 (inner2 (cdr l)))))))))))
|#

(define-integrable (hash-table/rehash table)
  ((ucode-primitive rehash) (hash-table/unhash-table table)
			    (hash-table/hash-table table)))

(define (rehash-all-gc-daemon)
  (let loop ((l all-hash-tables)
	     (n (weak-cdr all-hash-tables)))
    (cond ((null? n)
	   (weak-set-cdr! l n))
	  ((not (weak-pair/car? n))
	   (loop l (weak-cdr n)))
	  (else
	   (weak-set-cdr! l n)
	   (hash-table/rehash (weak-car n))
	   (loop n (weak-cdr n))))))