#| -*-Scheme-*-

$Id: char.scm,v 14.19 2003/07/25 23:03:57 cph Exp $

Copyright 1986,1987,1988,1991,1995,1997 Massachusetts Institute of Technology
Copyright 1998,2001,2003 Massachusetts Institute of Technology

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

;;;; Character Abstraction
;;; package: (runtime character)

(declare (usual-integrations))

(define-primitives
  (char? 1)
  char->integer
  integer->char)

(define-integrable char-code-limit #x110000)
(define-integrable char-bits-limit #x10)
(define-integrable char-integer-limit #x2000000)

(define-integrable (%make-char code bits)
  (integer->char (fix:or (fix:lsh bits 21) code)))

(define-integrable (%char-code char)
  (fix:and (char->integer char) #x1FFFFF))

(define-integrable (%char-bits char)
  (fix:lsh (char->integer char) -21))

(define-integrable (guarantee-char char procedure)
  (if (not (char? char))
      (error:wrong-type-argument char "character" procedure)))

(define (make-char code bits)
  (guarantee-limited-index-fixnum code char-code-limit 'MAKE-CHAR)
  (guarantee-limited-index-fixnum bits char-bits-limit 'MAKE-CHAR)
  (%make-char code bits))

(define (code->char code)
  (guarantee-limited-index-fixnum code char-code-limit 'CODE->CHAR)
  (integer->char code))

(define (char-code char)
  (guarantee-char char 'CHAR-CODE)
  (%char-code char))

(define (char-bits char)
  (guarantee-char char 'CHAR-BITS)
  (%char-bits char))

(define (char-ascii? char)
  (guarantee-char char 'CHAR-ASCII?)
  (let ((n (char->integer char)))
    (and (fix:< n 256)
	 n)))

(define (char->ascii char)
  (guarantee-char char 'CHAR->ASCII)
  (let ((n (char->integer char)))
    (if (not (fix:< n 256))
	(error:bad-range-argument char 'CHAR->ASCII))
    n))

(define (ascii->char code)
  (guarantee-limited-index-fixnum code 256 'ASCII->CHAR)
  (%make-char code 0))

(define (chars->ascii chars)
  (map char->ascii chars))

(define (char=? x y)
  ;; There's no %CHAR=? because the compiler recodes CHAR=? as EQ?.
  (guarantee-char x 'CHAR=?)
  (guarantee-char y 'CHAR=?)
  (fix:= (char->integer x) (char->integer y)))

(define (char<? x y)
  (guarantee-char x 'CHAR<?)
  (guarantee-char y 'CHAR<?)
  (%char<? x y))

(define-integrable (%char<? x y)
  (fix:< (char->integer x) (char->integer y)))

(define (char<=? x y)
  (guarantee-char x 'CHAR<=?)
  (guarantee-char y 'CHAR<=?)
  (%char<=? x y))

(define-integrable (%char<=? x y)
  (fix:<= (char->integer x) (char->integer y)))

(define (char>? x y)
  (guarantee-char x 'CHAR>?)
  (guarantee-char y 'CHAR>?)
  (%char>? x y))

(define-integrable (%char>? x y)
  (fix:> (char->integer x) (char->integer y)))

(define (char>=? x y)
  (guarantee-char x 'CHAR>=?)
  (guarantee-char y 'CHAR>=?)
  (%char>=? x y))

(define-integrable (%char>=? x y)
  (fix:>= (char->integer x) (char->integer y)))

(define (char-ci=? x y)
  (fix:= (char-ci->integer x) (char-ci->integer y)))

(define (char-ci<? x y)
  (fix:< (char-ci->integer x) (char-ci->integer y)))

(define (char-ci<=? x y)
  (fix:<= (char-ci->integer x) (char-ci->integer y)))

(define (char-ci>? x y)
  (fix:> (char-ci->integer x) (char-ci->integer y)))

(define (char-ci>=? x y)
  (fix:>= (char-ci->integer x) (char-ci->integer y)))

(define-integrable (char-ci->integer char)
  (char->integer (char-upcase char)))

(define (char-downcase char)
  (guarantee-char char 'CHAR-DOWNCASE)
  (%char-downcase char))

(define (%char-downcase char)
  (if (fix:< (%char-code char) 256)
      (%make-char (vector-8b-ref downcase-table (%char-code char))
		  (%char-bits char))
      char))

(define (char-upcase char)
  (guarantee-char char 'CHAR-UPCASE)
  (%char-upcase char))

(define (%char-upcase char)
  (if (fix:< (%char-code char) 256)
      (%make-char (vector-8b-ref upcase-table (%char-code char))
		  (%char-bits char))
      char))

(define downcase-table)
(define upcase-table)

(define (initialize-case-conversions!)
  (set! downcase-table (make-string 256))
  (set! upcase-table (make-string 256))
  (do ((i 0 (fix:+ i 1)))
      ((fix:= i 256))
    (vector-8b-set! downcase-table i i)
    (vector-8b-set! upcase-table i i))
  (let ((case-range
	 (lambda (uc-low uc-high lc-low)
	   (do ((i uc-low (fix:+ i 1))
		(j lc-low (fix:+ j 1)))
	       ((fix:> i uc-high))
	     (vector-8b-set! downcase-table i j)
	     (vector-8b-set! upcase-table j i)))))
    (case-range 65 90 97)
    (case-range 224 246 192)
    (case-range 248 254 216)))

(define 0-code)
(define upper-a-code)
(define lower-a-code)

(define (initialize-package!)
  (set! 0-code (char->integer #\0))
  ;; Next two codes are offset by 10 to speed up CHAR->DIGIT.
  (set! upper-a-code (fix:- (char->integer #\A) 10))
  (set! lower-a-code (fix:- (char->integer #\a) 10))
  (initialize-case-conversions!))

(define (radix? object)
  (and (index-fixnum? object)
       (fix:<= 2 object)
       (fix:<= object 36)))

(define (guarantee-radix object caller)
  (if (not (radix? object))
      (error:wrong-type-argument object "radix" caller)))

(define (digit->char digit #!optional radix)
  (guarantee-limited-index-fixnum digit
				  (if (default-object? radix)
				      10
				      (begin
					(guarantee-radix radix 'DIGIT->CHAR)
					radix))
				  'DIGIT->CHAR)
  (string-ref "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ" digit))

(define (char->digit char #!optional radix)
  (guarantee-char char 'CHAR->DIGIT)
  (let ((code (char->integer char))
	(radix
	 (cond ((default-object? radix)
		10)
	       ((and (fix:fixnum? radix)
		     (fix:<= 2 radix) (fix:<= radix 36))
		radix)
	       (else
		(error:wrong-type-argument radix "radix" 'CHAR->DIGIT)))))
    (let ((n (fix:- code 0-code)))
      (if (and (fix:<= 0 n) (fix:< n radix))
	  n
	  (let ((n (fix:- code upper-a-code)))
	    (if (and (fix:<= 10 n) (fix:< n radix))
		n
		(let ((n (fix:- code lower-a-code)))
		  (if (and (fix:<= 10 n) (fix:< n radix))
		      n
		      #f))))))))

;;;; Character Names

(define (name->char string)
  (let ((end (string-length string)))
    (let loop ((start 0) (bits 0))
      (let ((left (fix:- end start)))
	(if (fix:= 0 left)
	    (error:bad-range-argument string 'NAME->CHAR))
	(if (fix:= 1 left)
	    (let ((char (string-ref string start)))
	      (if (not (char-graphic? char))
		  (error:bad-range-argument string 'NAME->CHAR))
	      (make-char (char-code char) bits))
	    (let ((hyphen (substring-find-next-char string start end #\-)))
	      (if hyphen
		  (let ((bit (-map-> named-bits string start hyphen)))
		    (if bit
			(loop (fix:+ hyphen 1) (fix:or bit bits))
			(make-char (name->code string start end) bits)))
		  (make-char (name->code string start end) bits))))))))

(define (name->code string start end)
  (if (substring-ci=? string start end "newline" 0 7)
      (char-code char:newline)
      (or (-map-> named-codes string start end)
	  (numeric-name->code string start end)
	  (error "Unknown character name:" (substring string start end)))))

(define (numeric-name->code string start end)
  (and (> (- end start) 6)
       (substring-ci=? string start (+ start 5) "<code" 0 5)
       (substring-ci=? string (- end 1) end ">" 0 1)
       (string->number (substring string (+ start 5) (- end 1)) 10)))

(define (char->name char #!optional slashify?)
  (let ((code (char-code char))
	(bits (char-bits char)))
    (string-append
     (bucky-bits->prefix bits)
     (let ((base-char (if (fix:= 0 bits) char (integer->char code))))
       (cond ((<-map- named-codes code))
	     ((and (if (default-object? slashify?) #f slashify?)
		   (not (fix:= 0 bits))
		   (or (char=? base-char #\\)
		       (char-set-member? char-set/atom-delimiters base-char)))
	      (string-append "\\" (string base-char)))
	     ((char-graphic? base-char)
	      (string base-char))
	     (else
	      (string-append "<code" (number->string code 10) ">")))))))

(define (bucky-bits->prefix bits)
  (let loop ((bits bits) (weight 1))
    (if (fix:= 0 bits)
	""
	(let ((rest (loop (fix:lsh bits -1) (fix:lsh weight 1))))
	  (if (fix:= 0 (fix:and bits 1))
	      rest
	      (string-append (or (<-map- named-bits weight)
				 (string-append "<bits-"
						(number->string weight 10)
						">"))
			     "-"
			     rest))))))

(define (-map-> alist string start end)
  (and (not (null? alist))
       (let ((key (caar alist)))
	 (if (substring-ci=? string start end
			     key 0 (string-length key))
	     (cdar alist)
	     (-map-> (cdr alist) string start end)))))

(define (<-map- alist n)
  (and (not (null? alist))
       (if (fix:= n (cdar alist))
	   (caar alist)
	   (<-map- (cdr alist) n))))

(define named-codes
  '(
    ;; Some are aliases for previous definitions, and will not appear
    ;; as output.

    ("Backspace" . #x08)
    ("Tab" . #x09)
    ("Linefeed" . #x0A)
    ("Newline" . #x0A)
    ("Page" . #x0C)
    ("Return" . #x0D)
    ("Call" . #x1A)
    ("Altmode" . #x1B)
    ("Escape" . #x1B)
    ("Backnext" . #x1F)
    ("Space" . #x20)
    ("Rubout" . #x7F)

    ;; ASCII codes

    ("NUL" . #x0)			; ^@
    ("SOH" . #x1)			; ^A
    ("STX" . #x2)			; ^B
    ("ETX" . #x3)			; ^C
    ("EOT" . #x4)			; ^D
    ("ENQ" . #x5)			; ^E
    ("ACK" . #x6)			; ^F
    ("BEL" . #x7)			; ^G
    ("BS" . #x8)			; ^H <Backspace>
    ("HT" . #x9)			; ^I <Tab>
    ("LF" . #xA)			; ^J <Linefeed> <Newline>
    ("NL" . #xA)			; ^J <Linefeed> <Newline>
    ("VT" . #xB)			; ^K
    ("FF" . #xC)			; ^L <Page>
    ("NP" . #xC)			; ^L <Page>
    ("CR" . #xD)			; ^M <Return>
    ("SO" . #xE)			; ^N
    ("SI" . #xF)			; ^O
    ("DLE" . #x10)			; ^P
    ("DC1" . #x11)			; ^Q
    ("DC2" . #x12)			; ^R
    ("DC3" . #x13)			; ^S
    ("DC4" . #x14)			; ^T
    ("NAK" . #x15)			; ^U
    ("SYN" . #x16)			; ^V
    ("ETB" . #x17)			; ^W
    ("CAN" . #x18)			; ^X
    ("EM" . #x19)			; ^Y
    ("SUB" . #x1A)			; ^Z <Call>
    ("ESC" . #x1B)			; ^[ <Altmode> <Escape>
    ("FS" . #x1C)			; ^\
    ("GS" . #x1D)			; ^]
    ("RS" . #x1E)			; ^^
    ("US" . #x1F)			; ^_ <Backnext>
    ("SP" . #x20)			; <Space>
    ("DEL" . #x7F)			; ^? <Rubout>
    ))

(define named-bits
  '(("M" . #x01)
    ("Meta" . #x01)
    ("C" . #x02)
    ("Control" . #x02)
    ("S" . #x04)
    ("Super" . #x04)
    ("H" . #x08)
    ("Hyper" . #x08)))