#| -*-Scheme-*-

$Id: utils.scm,v 1.55 2005/07/31 02:59:37 cph Exp $

Copyright 1986, 1989-2002 Massachusetts Institute of Technology

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

;;;; Editor Utilities

(declare (usual-integrations))

;; Allow gc and after-gc hooks.

(define-integrable interrupt-mask/gc-normal #x0025)

(define (guarantee-heap-available n-words operator old-mask)
  (gc-flip)
  (if (not ((ucode-primitive heap-available? 1) n-words))
      (begin
	(set-interrupt-enables! old-mask)
	(error:allocation-failure n-words operator))))

(define condition-type:allocation-failure
  (make-condition-type 'ALLOCATION-FAILURE condition-type:error
      '(OPERATOR N-WORDS)
    (lambda (condition port)
      (let ((operator (access-condition condition 'OPERATOR)))
	(if operator
	    (begin
	      (write-string "The procedure " port)
	      (write operator port)
	      (write-string " is unable" port))
	    (write-string "Unable" port)))
      (write-string " to allocate " port)
      (write (access-condition condition 'N-WORDS) port)
      (write-string " words of storage." port))))

(define error:allocation-failure
  (condition-signaller condition-type:allocation-failure
		       '(N-WORDS OPERATOR)
		       standard-error-handler))

(define-syntax chars-to-words-shift
  (sc-macro-transformer
   (lambda (form environment)
     form environment
     ;; This is written as a macro so that the shift will be a constant
     ;; in the compiled code.
     ;; It does not work when cross-compiled!
     (let ((chars-per-word (vector-ref (gc-space-status) 0)))
       (case chars-per-word
	 ((4) -2)
	 ((8) -3)
	 (else (error "Can't support this word size:" chars-per-word)))))))

(define (edwin-string-allocate n-chars)
  (if (not (fix:fixnum? n-chars))
      (error:wrong-type-argument n-chars "fixnum" 'STRING-ALLOCATE))
  (if (not (fix:>= n-chars 0))
      (error:bad-range-argument n-chars 'STRING-ALLOCATE))
  (with-interrupt-mask interrupt-mask/none
    (lambda (mask)
      (let ((n-words (fix:+ (fix:lsh n-chars (chars-to-words-shift)) 3)))
	(if (not ((ucode-primitive heap-available? 1) n-words))
	    (with-interrupt-mask interrupt-mask/gc-normal
	      (lambda (ignore)
		ignore			; ignored
		(guarantee-heap-available n-words 'STRING-ALLOCATE mask))))
	(let ((result ((ucode-primitive primitive-get-free 1)
		       (ucode-type string))))
	  ((ucode-primitive primitive-object-set! 3)
	   result
	   0
	   ((ucode-primitive primitive-object-set-type 2)
	    (ucode-type manifest-nm-vector)
	    (fix:- n-words 1)))
	  (set-string-length! result n-chars)
	  ;; This won't work if range-checking is turned on.
	  (string-set! result n-chars #\nul)
	  ((ucode-primitive primitive-increment-free 1) n-words)
	  (set-interrupt-enables! mask)
	  result)))))

(define (edwin-set-string-maximum-length! string n-chars)
  (if (not (string? string))
      (error:wrong-type-argument string "string" 'SET-STRING-MAXIMUM-LENGTH!))
  (if (not (fix:fixnum? n-chars))
      (error:wrong-type-argument n-chars "fixnum" 'SET-STRING-MAXIMUM-LENGTH!))
  (if (not (and (fix:>= n-chars 0)
		(fix:< n-chars
		       (fix:lsh (fix:- (system-vector-length string) 1)
				(fix:- 0 (chars-to-words-shift))))))
      (error:bad-range-argument n-chars 'SET-STRING-MAXIMUM-LENGTH!))
  (let ((mask (set-interrupt-enables! interrupt-mask/none)))
    ((ucode-primitive primitive-object-set! 3)
     string
     0
     ((ucode-primitive primitive-object-set-type 2)
      (ucode-type manifest-nm-vector)
      (fix:+ (fix:lsh n-chars (chars-to-words-shift)) 2)))
    (set-string-length! string n-chars)
    ;; This won't work if range-checking is turned on.
    (string-set! string n-chars #\nul)
    (set-interrupt-enables! mask)
    unspecific))

(define string-allocate
  (if (compiled-procedure? edwin-string-allocate)
      edwin-string-allocate
      (ucode-primitive string-allocate)))

(define set-string-maximum-length!
  (if (compiled-procedure? edwin-set-string-maximum-length!)
      edwin-set-string-maximum-length!
      (ucode-primitive set-string-maximum-length!)))

(define (%substring-move! source start-source end-source
			  target start-target)
  (cond ((not (fix:< start-source end-source))
	 unspecific)
	((not (eq? source target))
	 (if (fix:< (fix:- end-source start-source) 32)
	     (do ((scan-source start-source (fix:+ scan-source 1))
		  (scan-target start-target (fix:+ scan-target 1)))
		 ((fix:= scan-source end-source) unspecific)
	       (string-set! target
			    scan-target
			    (string-ref source scan-source)))
	     (substring-move-left! source start-source end-source
				   target start-target)))
	((fix:< start-source start-target)
	 (if (fix:< (fix:- end-source start-source) 32)
	     (do ((scan-source end-source (fix:- scan-source 1))
		  (scan-target
		   (fix:+ start-target (fix:- end-source start-source))
		   (fix:- scan-target 1)))
		 ((fix:= scan-source start-source) unspecific)
	       (string-set! source
			    (fix:- scan-target 1)
			    (string-ref source (fix:- scan-source 1))))
	     (substring-move-right! source start-source end-source
				    source start-target)))
	((fix:< start-target start-source)
	 (if (fix:< (fix:- end-source start-source) 32)
	     (do ((scan-source start-source (fix:+ scan-source 1))
		  (scan-target start-target (fix:+ scan-target 1)))
		 ((fix:= scan-source end-source) unspecific)
	       (string-set! source
			    scan-target
			    (string-ref source scan-source)))
	     (substring-move-left! source start-source end-source
				   source start-target)))))

(define (string-append-char string char)
  (let ((size (string-length string)))
    (let ((result (string-allocate (fix:+ size 1))))
      (%substring-move! string 0 size result 0)
      (string-set! result size char)
      result)))

(define (string-append-substring string1 string2 start2 end2)
  (let ((length1 (string-length string1)))
    (let ((result (string-allocate (fix:+ length1 (fix:- end2 start2)))))
      (%substring-move! string1 0 length1 result 0)
      (%substring-move! string2 start2 end2 result length1)
      result)))

(define (string-greatest-common-prefix strings)
  (let loop
      ((strings (cdr strings))
       (string (car strings))
       (index (string-length (car strings))))
    (if (null? strings)
	(substring string 0 index)
	(let ((string* (car strings)))
	  (let ((index* (string-match-forward string string*)))
	    (if (< index* index)
		(loop (cdr strings) string* index*)
		(loop (cdr strings) string index)))))))

(define (string-greatest-common-prefix-ci strings)
  (let loop
      ((strings (cdr strings))
       (string (car strings))
       (index (string-length (car strings))))
    (if (null? strings)
	(substring string 0 index)
	(let ((string* (car strings)))
	  (let ((index* (string-match-forward-ci string string*)))
	    (if (< index* index)
		(loop (cdr strings) string* index*)
		(loop (cdr strings) string index)))))))

(define (string-append-separated x y)
  (cond ((string-null? x) y)
	((string-null? y) x)
	(else (string-append x " " y))))

(define (substring->nonnegative-integer line start end)
  (let loop ((index start) (n 0))
    (if (fix:= index end)
	n
	(let ((k (fix:- (vector-8b-ref line index) (char->integer #\0))))
	  (and (fix:>= k 0)
	       (fix:< k 10)
	       (loop (fix:+ index 1) (+ (* n 10) k)))))))

(define char-set:null
  (char-set))

(define char-set:return
  (char-set #\Return))

(define char-set:not-space
  (char-set-invert (char-set #\Space)))

(define (char-controlify char)
  (if (ascii-controlified? char)
      char
      (make-char (char-code char)
		 (let ((bits (char-bits char)))
		   (if (odd? (quotient bits 2)) bits (+ bits 2))))))

(define (char-controlified? char)
  (or (ascii-controlified? char)
      (odd? (quotient (char-bits char) 2))))

(define (char-metafy char)
  (make-char (char-code char)
	     (let ((bits (char-bits char)))
	       (if (odd? bits) bits (1+ bits)))))

(define-integrable (char-metafied? char)
  (odd? (char-bits char)))

(define (char-control-metafy char)
  (char-controlify (char-metafy char)))

(define (char-base char)
  (make-char (char-code char) 0))

(define (y-or-n? . strings)
  (define (loop)
    (let ((char (char-upcase (read-char))))
      (cond ((or (char=? char #\Y)
		 (char=? char #\Space))
	     (write-string "Yes")
	     true)
	    ((or (char=? char #\N)
		 (char=? char #\Rubout))
	     (write-string "No")
	     false)
	    (else
	     (if (not (char=? char #\newline))
		 (beep))
	     (loop)))))
  (newline)
  (for-each write-string strings)
  (loop))

(define (delete-directory-no-errors filename)
  (catch-file-errors (lambda (condition) condition #f)
		     (lambda () (delete-directory filename) #t)))

(define (string-or-false? object)
  ;; Useful as a type for option variables.
  (or (false? object)
      (string? object)))

(define (list-of-strings? object)
  (list-of-type? object string?))

(define (list-of-pathnames? object)
  (list-of-type? object
		 (lambda (object) (or (pathname? object) (string? object)))))

(define (list-of-type? object predicate)
  (and (list? object)
       (for-all? object predicate)))

(define (dotimes n procedure)
  (define (loop i)
    (if (< i n)
	(begin (procedure i)
	       (loop (1+ i)))))
  (loop 0))

(define (split-list elements predicate)
  (let loop ((elements elements) (satisfied '()) (unsatisfied '()))
    (if (pair? elements)
	(if (predicate (car elements))
	    (loop (cdr elements) (cons (car elements) satisfied) unsatisfied)
	    (loop (cdr elements) satisfied (cons (car elements) unsatisfied)))
	(values satisfied unsatisfied))))

(define make-strong-eq-hash-table
  (strong-hash-table/constructor eq-hash-mod eq? #t))

(define make-weak-equal-hash-table
  (weak-hash-table/constructor equal-hash-mod equal? #t))

(define (weak-assq item alist)
  (let loop ((alist alist))
    (and (not (null? alist))
	 (if (eq? (weak-car (car alist)) item)
	     (car alist)
	     (loop (cdr alist))))))

(define (file-time->ls-string time #!optional now)
  ;; Returns a time string like that used by unix `ls -l'.
  (let ((time (file-time->universal-time time))
	(now
	 (if (or (default-object? now) (not now))
	     (get-universal-time)
	     now)))
    (let ((dt (decode-universal-time time))
	  (d2 (lambda (n c) (string-pad-left (number->string n) 2 c))))
      (string-append (month/short-string (decoded-time/month dt))
		     " "
		     (d2 (decoded-time/day dt) #\space)
		     " "
		     (if (<= 0 (- now time) (* 180 24 60 60))
			 (string-append (d2 (decoded-time/hour dt) #\0)
					":"
					(d2 (decoded-time/minute dt) #\0))
			 (string-append " "
					(number->string
					 (decoded-time/year dt))))))))

(define (catch-file-errors if-error thunk)
  (call-with-current-continuation
   (lambda (continuation)
     (bind-condition-handler (list condition-type:file-error
				   condition-type:port-error)
	 (lambda (condition)
	   (continuation (if-error condition)))
       thunk))))