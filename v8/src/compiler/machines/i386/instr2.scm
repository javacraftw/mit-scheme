#| -*-Scheme-*-

$Header: /Users/cph/tmp/foo/mit-scheme/mit-scheme/v8/src/compiler/machines/i386/instr2.scm,v 1.1 1995/01/10 20:52:44 adams Exp $

Copyright (c) 1992 Massachusetts Institute of Technology

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

;;;; Intel i386 Instruction Set, part II
;;; package: (compiler lap-syntaxer)

;; Some of the instructions have their operands ill-specified in the
;; i486 book.  Check against the appendices or the i386 book.

(declare (usual-integrations))

;; Utility

(define-macro (define-trivial-instruction mnemonic opcode . extra)
  `(define-instruction ,mnemonic
     (()
      (BYTE (8 ,opcode))
      ,@(map (lambda (extra)
	       `(BYTE (8 ,extra)))
	     extra))))

;;;; Actual instructions

(let-syntax
    ((define-load-segment
       (macro (mnemonic . bytes)
	 `(define-instruction ,mnemonic
	    (((R (? reg)) (? pointer mW))
	     (BYTE ,@(map (lambda (byte)
			    `(8 ,byte))
			  bytes))
	     (ModR/M reg pointer))))))

  (define-load-segment LDS #xc5)
  (define-load-segment LSS #x0f #xb2)
  (define-load-segment LES #xc4)
  (define-load-segment LFS #x0f #xb4)
  (define-load-segment LGS #x0f #xb5))

(define-instruction LSL
  (((R (? reg)) (? source r/mW))
   (BYTE (8 #x0f)
	 (8 #x03))
   (ModR/M reg source)))

(let-syntax
    ((define-data-extension
       (macro (mnemonic opcode)
	 `(define-instruction ,mnemonic
	    ((B (R (? target)) (? source r/mB))
	     (BYTE (8 #x0f)
		   (8 ,opcode))
	     (ModR/M target source))

	    ((H (R (? target)) (? source r/mW))
	     (BYTE (8 #x0f)
		   (8 ,(1+ opcode)))
	     (ModR/M target source))))))

  (define-data-extension MOVSX #xbe)
  (define-data-extension MOVZX #xb6))

(let-syntax
    ((define-unary
       (macro (mnemonic digit)
	 `(define-instruction ,mnemonic
	    ((W (? operand r/mW))
	     (BYTE (8 #xf7))
	     (ModR/M ,digit operand))

	    ((B (? operand r/mB))
	     (BYTE (8 #xf6))
	     (ModR/M ,digit operand))))))

  (define-unary NEG 3)
  (define-unary NOT 2))

(define-instruction MOV
  ((W (R (? target)) (? source r/mW))
   (BYTE (8 #x8b))
   (ModR/M target source))

  ((W (? target r/mW) (R (? source)))
   (BYTE (8 #x89))
   (ModR/M source target))

  ((W (R (? reg)) (& (? value)))
   (BYTE (8 (+ #xb8 reg)))
   (IMMEDIATE value))

  ((W (? target r/mW) (& (? value)))
   (BYTE (8 #xc7))
   (ModR/M 0 target)
   (IMMEDIATE value))

  ((W (R (? reg)) (&U (? value)))
   (BYTE (8 (+ #xb8 reg)))
   (IMMEDIATE value OPERAND UNSIGNED))

  ((W (? target r/mW) (&U (? value)))
   (BYTE (8 #xc7))
   (ModR/M 0 target)
   (IMMEDIATE value OPERAND UNSIGNED))

  ((B (R (? target)) (? source r/mB))
   (BYTE (8 #x8a))
   (ModR/M target source))

  ((B (? target r/mB) (R (? source)))
   (BYTE (8 #x88))
   (ModR/M source target))

  ((B (R (? reg)) (& (? value)))
   (BYTE (8 (+ #xb0 reg))
	 (8 value SIGNED)))

  ((B (? target r/mB) (& (? value)))
   (BYTE (8 #xc6))
   (ModR/M 0 target)
   (BYTE (8 value SIGNED)))

  ((B (R (? reg)) (&U (? value)))
   (BYTE (8 (+ #xb0 reg))
	 (8 value UNSIGNED)))

  ((B (? target r/mB) (&U (? value)))
   (BYTE (8 #xc6))
   (ModR/M 0 target)
   (BYTE (8 value UNSIGNED)))

  ((W (R 0) (@ (? offset)))
   (BYTE (8 #xa1))
   (IMMEDIATE offset))

  ((W (@ (? offset)) (R 0))
   (BYTE (8 #xa3))
   (IMMEDIATE offset))

  ((B (R 0) (@ (? offset)))
   (BYTE (8 #xa0)
	 (8 offset SIGNED)))

  ((B (@ (? offset)) (R 0))
   (BYTE (8 #xa2)
	 (8 offset SIGNED)))

  (((? target r/mW) (SR (? source)))
   (BYTE (8 #x8c))
   (ModR/M source target))

  (((SR (? target)) (? source r/mW))
   (BYTE (8 #x8e))
   (ModR/M target source))

  (((CR (? creg)) (R (? reg)))
   (BYTE (8 #x0f)
	 (8 #x22))
   (ModR/M creg `(R ,reg)))

  (((R (? reg)) (CR (? creg)))
   (BYTE (8 #x0f)
	 (8 #x20))
   (ModR/M creg `(R ,reg)))

  (((DR (? dreg)) (R (? reg)))
   (BYTE (8 #x0f)
	 (8 #x23))
   (ModR/M dreg `(R ,reg)))

  (((R (? reg)) (DR (? dreg)))
   (BYTE (8 #x0f)
	 (8 #x21))
   (ModR/M dreg `(R ,reg)))

  (((TR (? treg)) (R (? reg)))
   (BYTE (8 #x0f)
	 (8 #x26))
   (ModR/M treg `(R ,reg)))

  (((R (? reg)) (TR (? treg)))
   (BYTE (8 #x0f)
	 (8 #x24))
   (ModR/M treg `(R ,reg))))

(define-trivial-instruction NOP #x90)

(define-instruction OUT
  ((W (& (? port)) (R 0))
   (BYTE (8 #xe7)
	 (8 port)))

  ((W (R 2) (R 0))
   (BYTE (8 #xef)))

  ((B (& (? port)) (R 0))
   (BYTE (8 #xe6)
	 (8 port)))

  ((B (R 2) (R 0))
   (BYTE (8 #xee))))

(define-instruction POP
  (((R (? target)))
   (BYTE (8 (+ #x58 target))))

  (((? target mW))
   (BYTE (8 #x8f))
   (ModR/M 0 target))

  ((ES)
   (BYTE (8 #x07)))

  ((SS)
   (BYTE (8 #x17)))

  ((DS)
   (BYTE (8 #x1f)))

  ((FS)
   (BYTE (8 #x0f)
	 (8 #xa1)))

  ((GS)
   (BYTE (8 #x0f)
	 (8 #xa9)))

  (((SR 0))
   (BYTE (8 #x07)))

  (((SR 2))
   (BYTE (8 #x17)))

  (((SR 3))
   (BYTE (8 #x1f)))

  (((SR 4))
   (BYTE (8 #x0f)
	 (8 #xa1)))

  (((SR 5))
   (BYTE (8 #x0f)
	 (8 #xa9))))

(define-trivial-instruction POPA #x61)
(define-trivial-instruction POPAD #x61)
(define-trivial-instruction POPF #x9d)
(define-trivial-instruction POPFD #x9d)

(define-instruction PUSH
  (((R (? source)))
   (BYTE (8 (+ #x50 source))))

  (((? source mW))
   (BYTE (8 #xff))
   (ModR/M 6 source))

  ((W (& (? value)))
   (BYTE (8 #x68))
   (IMMEDIATE value))

  ((W (&U (? value)))
   (BYTE (8 #x68))
   (IMMEDIATE value OPERAND UNSIGNED))

  ((B (& (? value)))
   (BYTE (8 #x6a)
	 (8 value)))

  ((B (&U (? value)))
   (BYTE (8 #x6a)
	 (8 value UNSIGNED)))

  ((ES)
   (BYTE (8 #x06)))

  ((CS)
   (BYTE (8 #x0e)))

  ((SS)
   (BYTE (8 #x16)))

  ((DS)
   (BYTE (8 #x1e)))

  ((FS)
   (BYTE (8 #x0f)
	 (8 #xa0)))

  ((GS)
   (BYTE (8 #x0f)
	 (8 #xa8)))

  (((SR 0))
   (BYTE (8 #x06)))

  (((SR 1))
   (BYTE (8 #x0e)))

  (((SR 2))
   (BYTE (8 #x16)))

  (((SR 3))
   (BYTE (8 #x1e)))

  (((SR 4))
   (BYTE (8 #x0f)
	 (8 #xa0)))

  (((SR 5))
   (BYTE (8 #x0f)
	 (8 #xa8))))

(define-trivial-instruction PUSHA  #x60)
(define-trivial-instruction PUSHAD #x60)
(define-trivial-instruction PUSHF  #x9c)
(define-trivial-instruction PUSHFD #x9c)

(let-syntax
    ((define-rotate/shift
       (macro (mnemonic digit)
	 `(define-instruction ,mnemonic
	   ((W (? operand r/mW) (& 1))
	    (BYTE (8 #xd1))
	    (ModR/M ,digit operand))

	   ((W (? operand r/mW) (& (? value)))
	    (BYTE (8 #xc1))
	    (ModR/M ,digit operand)
	    (BYTE (8 value)))

	   ((W (? operand r/mW) (R 1))
	    (BYTE (8 #xd3))
	    (ModR/M ,digit operand))

	   ((B (? operand r/mB) (& 1))
	    (BYTE (8 #xd0))
	    (ModR/M ,digit operand))

	   ((B (? operand r/mB) (& (? value)))
	    (BYTE (8 #xc0))
	    (ModR/M ,digit operand)
	    (BYTE (8 value)))

	   ((B (? operand r/mB) (R 1))
	    (BYTE (8 #xd2))
	    (ModR/M ,digit operand))))))

  (define-rotate/shift RCL 2)
  (define-rotate/shift RCR 3)
  (define-rotate/shift ROL 0)
  (define-rotate/shift ROR 1)
  (define-rotate/shift SAL 4)
  (define-rotate/shift SAR 7)
  (define-rotate/shift SHL 4)
  (define-rotate/shift SHR 5))

(let-syntax
    ((define-double-shift
       (macro (mnemonic opcode)
	 `(define-instruction ,mnemonic
	    ((W (? target r/mW) (R (? source)) (& (? count)))
	     (BYTE (8 #x0f)
		   (8 ,opcode))
	     (ModR/M target source)
	     (BYTE (8 count)))

	    ((W (? target r/mW) (R (? source)) (R 1))
	     (BYTE (8 #x0f)
		   (8 ,(1+ opcode)))
	     (ModR/M target source))))))

  (define-double-shift SHLD #xa4)
  (define-double-shift SHRD #xac))

(define-instruction RET
  (()
   (BYTE (8 #xc3)))

  ((F)
   (BYTE (8 #xcb)))

  (((& (? frame-size)))
   (BYTE (8 #xc2)
	 (16 frame-size)))

  ((F (& (? frame-size)))
   (BYTE (8 #xca)
	 (16 frame-size))))

(define-trivial-instruction SAHF #x9e)

(let-syntax
    ((define-setcc-instruction
       (macro (mnemonic opcode)
	 `(define-instruction ,mnemonic
	    (((? target r/mB))
	     (BYTE (8 #x0f)
		   (8 ,opcode))
	     (ModR/M 0 target))))))		; 0?

  (define-setcc-instruction SETA   #x97)
  (define-setcc-instruction SETAE  #x93)
  (define-setcc-instruction SETB   #x92)
  (define-setcc-instruction SETBE  #x96)
  (define-setcc-instruction SETC   #x92)
  (define-setcc-instruction SETE   #x94)
  (define-setcc-instruction SETG   #x9f)
  (define-setcc-instruction SETGE  #x9d)
  (define-setcc-instruction SETL   #x9c)
  (define-setcc-instruction SETLE  #x9e)
  (define-setcc-instruction SETNA  #x96)
  (define-setcc-instruction SETNAE #x92)
  (define-setcc-instruction SETNB  #x93)
  (define-setcc-instruction SETNBE #x97)
  (define-setcc-instruction SETNC  #x93)
  (define-setcc-instruction SETNE  #x95)
  (define-setcc-instruction SETNG  #x9e)
  (define-setcc-instruction SETNGE #x9c)
  (define-setcc-instruction SETNL  #x9d)
  (define-setcc-instruction SETNLE #x9f)
  (define-setcc-instruction SETNO  #x91)
  (define-setcc-instruction SETNP  #x9b)
  (define-setcc-instruction SETNS  #x99)
  (define-setcc-instruction SETNZ  #x95)
  (define-setcc-instruction SETO   #x90)
  (define-setcc-instruction SETP   #x9a)
  (define-setcc-instruction SETPE  #x9a)
  (define-setcc-instruction SETPO  #x9b)
  (define-setcc-instruction SETS   #x98)
  (define-setcc-instruction SETZ   #x94))

(define-trivial-instruction STC #xf9)
(define-trivial-instruction STD #xfd)
(define-trivial-instruction STI #xfb)

(define-instruction TEST
  ((W (? op1 r/mW) (R (? op2)))
   (BYTE (8 #x85))
   (ModR/M op2 op1))

  ((W (R 0) (& (? value)))
   (BYTE (8 #xa9))
   (IMMEDIATE value))

  ((W (R 0) (&U (? value)))
   (BYTE (8 #xa9))
   (IMMEDIATE value OPERAND UNSIGNED))

  ((W (? op1 r/mW) (& (? value)))
   (BYTE (8 #xf7))
   (ModR/M 0 op1)
   (IMMEDIATE value))

  ((W (? op1 r/mW) (&U (? value)))
   (BYTE (8 #xf7))
   (ModR/M 0 op1)
   (IMMEDIATE value OPERAND UNSIGNED))

  ((B (? op1 r/mB) (R (? op2)))
   (BYTE (8 #x84))
   (ModR/M op2 op1))

  ((B (R 0) (& (? value)))
   (BYTE (8 #xa8)
	 (8 value SIGNED)))

  ((B (R 0) (&U (? value)))
   (BYTE (8 #xa8)
	 (8 value UNSIGNED)))

  ((B (? op1 r/mB) (& (? value)))
   (BYTE (8 #xf6))
   (ModR/M 0 op1)
   (BYTE (8 value SIGNED)))

  ((B (? op1 r/mB) (&U (? value)))
   (BYTE (8 #xf6))
   (ModR/M 0 op1)
   (BYTE (8 value UNSIGNED))))

(define-trivial-instruction WAIT #x9b)		; = (FWAIT)
(define-trivial-instruction WBINVD #x0f #x09)	; 486 only

(define-instruction XADD			; 486 only
  ((W (? target r/mW) (R (? source)))
   (BYTE (8 #x0f)
	 (8 #xc1))
   (ModR/M source target))

  ((B (? target r/mB) (R (? source)))
   (BYTE (8 #x0f)
	 (8 #xc0))
   (ModR/M source target)))

(define-instruction XCHG
  ((W (R 0) (R (? reg)))
   (BYTE (8 (+ #x90 reg))))

  ((W (R (? reg)) (R 0))
   (BYTE (8 (+ #x90 reg))))

  ((W (R (? reg)) (? op r/mW))
   (BYTE (8 #x87))
   (ModR/M reg op))

  ((W (? op r/mW) (R (? reg)))
   (BYTE (8 #x87))
   (ModR/M reg op))

  ((B (R (? reg)) (? op r/mB))
   (BYTE (8 #x86))
   (ModR/M reg op))

  ((B (? op r/mB) (R (? reg)))
   (BYTE (8 #x86))
   (ModR/M reg op)))

(define-trivial-instruction XLAT #xd7)

;;;; Instruction prefixes.  Treated as separate instructions.

(define-trivial-instruction LOCK #xf0)

(define-trivial-instruction REP   #xf3)		; or #xf2 trust which appendix?
(define-trivial-instruction REPE  #xf3)
(define-trivial-instruction REPNE #xf2)
(define-trivial-instruction REPNZ #xf2)
(define-trivial-instruction REPZ  #xf3)

(define-trivial-instruction CSSEG #x2e)
(define-trivial-instruction SSSEG #x36)
(define-trivial-instruction DSSEG #x3e)
(define-trivial-instruction ESSEG #x26)
(define-trivial-instruction FSSEG #x64)
(define-trivial-instruction GSSEG #x65)

;; **** These are broken.  The assembler needs to change state, i.e.
;; fluid-let *OPERAND-SIZE* or *ADDRESS-SIZE*. ****

(define-trivial-instruction OPSIZE #x66)
(define-trivial-instruction ADSIZE #x67)

;; **** Missing MOV instruction to/from special registers. ****