#| -*-Scheme-*-

$Id: assmd.scm,v 1.2 1999/01/02 06:06:43 cph Exp $
$MC68020-Header: assmd.scm,v 1.36 89/08/28 18:33:33 GMT cph Exp $

Copyright (c) 1992, 1999 Massachusetts Institute of Technology

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or (at
your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
|#

;;;; Assembler Machine Dependencies.  Intel 386 version

(declare (usual-integrations))

(let-syntax ((ucode-type (macro (name) `',(microcode-type name))))

(define-integrable maximum-padding-length
  ;; Instructions can be any number of bytes long.
  ;; Thus the maximum padding is 3 bytes.
  24)

(define-integrable padding-string
  ;; Pad with HLT instructions
  (unsigned-integer->bit-string 8 #xf4))

(define-integrable block-offset-width
  ;; Block offsets are encoded words
  16)

(define maximum-block-offset
  (- (expt 2 (-1+ block-offset-width)) 1))

(define-integrable (block-offset->bit-string offset start?)
  (unsigned-integer->bit-string block-offset-width
				(+ (* 2 offset)
				   (if start? 0 1))))


(define-integrable nmv-type-string
  (unsigned-integer->bit-string scheme-type-width
				(ucode-type manifest-nm-vector)))

(define (make-nmv-header n)
  (bit-string-append (unsigned-integer->bit-string scheme-datum-width n)
		     nmv-type-string))

;;; Machine dependent instruction order

(define (instruction-insert! bits block position receiver)
  (let ((l (bit-string-length bits)))
    (bit-substring-move-right! bits 0 l block position)
    (receiver (+ position l))))

(define-integrable (instruction-initial-position block)
  block					; ignored
  0)

(define-integrable instruction-append bit-string-append)

;;; end let-syntax
)