;;; -*-Scheme-*-
;;;
;;; $Id: mit-syntax.scm,v 1.1.2.6 2002/01/17 17:35:59 cph Exp $
;;;
;;; Copyright (c) 1989-1991, 2001, 2002 Massachusetts Institute of Technology
;;;
;;; This program is free software; you can redistribute it and/or
;;; modify it under the terms of the GNU General Public License as
;;; published by the Free Software Foundation; either version 2 of the
;;; License, or (at your option) any later version.
;;;
;;; This program is distributed in the hope that it will be useful,
;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;;; General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with this program; if not, write to the Free Software
;;; Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
;;; 02111-1307, USA.

;;;; MIT Scheme Syntax

(declare (usual-integrations))

;;;; Macro transformers

(define (sc-macro-transformer->expander transformer)
  (lambda (form environment closing-environment)
    (make-syntactic-closure closing-environment '()
      (transformer form environment))))

(define (rsc-macro-transformer->expander transformer)
  (lambda (form environment closing-environment)
    (make-syntactic-closure environment '()
      (transformer form closing-environment))))

(define (er-macro-transformer->expander transformer)
  (lambda (form environment closing-environment)
    (make-syntactic-closure environment '()
      (transformer form
		   (let ((renames '()))
		     (lambda (identifier)
		       (let ((association (assq identifier renames)))
			 (if association
			     (cdr association)
			     (let ((rename
				    (make-syntactic-closure closing-environment
					'()
				      identifier)))
			       (set! renames
				     (cons (cons identifier rename)
					   renames))
			       rename)))))
		   (lambda (x y)
		     (identifier=? environment x
				   environment y))))))

(define (non-hygienic-macro-transformer->expander transformer)
  (lambda (form environment closing-environment)
    closing-environment
    (make-syntactic-closure environment '()
      (apply transformer (cdr form)))))

(define (define-er-macro-transformer keyword environment transformer)
  (define-expander keyword environment
    (er-macro-transformer->expander transformer)))

(define (transformer-keyword transformer->expander-name)
  (lambda (form environment definition-environment history)
    definition-environment		;ignore
    (syntax-check '(KEYWORD EXPRESSION) form history)
    (let ((item
	   (classify/subexpression
	    `(,(make-syntactic-closure system-global-environment '()
		 transformer->expander-name)
	      ,(cadr form))
	    environment
	    history
	    select-cadr)))
      (make-transformer-item
       (make-expander-item
	(transformer-eval (compile-item/expression item)
			  (syntactic-environment->environment environment))
	environment)
       item))))

(define-classifier 'SC-MACRO-TRANSFORMER system-global-environment
  ;; "Syntactic Closures" transformer
  (transformer-keyword 'SC-MACRO-TRANSFORMER->EXPANDER))

(define-classifier 'RSC-MACRO-TRANSFORMER system-global-environment
  ;; "Reversed Syntactic Closures" transformer
  (transformer-keyword 'RSC-MACRO-TRANSFORMER->EXPANDER))

(define-classifier 'ER-MACRO-TRANSFORMER system-global-environment
  ;; "Explicit Renaming" transformer
  (transformer-keyword 'ER-MACRO-TRANSFORMER->EXPANDER))

(define-classifier 'NON-HYGIENIC-MACRO-TRANSFORMER system-global-environment
  (transformer-keyword 'NON-HYGIENIC-MACRO-TRANSFORMER->EXPANDER))

;;;; Core primitives

(define-compiler 'LAMBDA system-global-environment
  (lambda (form environment history)
    (syntax-check '(KEYWORD MIT-BVL + FORM) form history)
    (call-with-values
	(lambda ()
	  (compile/lambda (cadr form)
			  (cddr form)
			  select-cddr
			  environment
			  history))
      (lambda (bvl body)
	(output/lambda bvl body)))))

(define-compiler 'NAMED-LAMBDA system-global-environment
  (lambda (form environment history)
    (syntax-check '(KEYWORD (IDENTIFIER . MIT-BVL) + FORM) form history)
    (call-with-values
	(lambda ()
	  (compile/lambda (cdadr form)
			  (cddr form)
			  select-cddr
			  environment
			  history))
      (lambda (bvl body)
	(output/named-lambda (identifier->symbol (caadr form)) bvl body)))))

(define (compile/lambda bvl body select-body environment history)
  (let ((environment (make-internal-syntactic-environment environment)))
    ;; Force order -- bind names before classifying body.
    (let ((bvl
	   (map-mit-lambda-list (lambda (identifier)
				  (bind-variable! environment identifier))
				bvl)))
      (values bvl
	      (compile-body-item
	       (classify/body body
			      environment
			      environment
			      history
			      select-body))))))

(define (map-mit-lambda-list procedure bvl)
  (let loop ((bvl bvl))
    (if (pair? bvl)
	(cons (if (or (eq? (car bvl) lambda-optional-tag)
		      (eq? (car bvl) lambda-rest-tag))
		  (car bvl)
		  (procedure (car bvl)))
	      (loop (cdr bvl)))
	(if (identifier? bvl)
	    (procedure bvl)
	    '()))))

(define-classifier 'BEGIN system-global-environment
  (lambda (form environment definition-environment history)
    (syntax-check '(KEYWORD * FORM) form history)
    (make-body-item history
		    (classify/subforms (cdr form)
				       environment
				       definition-environment
				       history
				       select-cdr))))

(define-compiler 'IF system-global-environment
  (lambda (form environment history)
    (syntax-check '(KEYWORD EXPRESSION EXPRESSION ? EXPRESSION)
		  form history)
    (output/conditional
     (compile/subexpression (cadr form) environment history select-cadr)
     (compile/subexpression (caddr form) environment history select-caddr)
     (if (pair? (cdddr form))
	 (compile/subexpression (cadddr form)
				environment
				history
				select-cadddr)
	 (output/unspecific)))))

(define-compiler 'QUOTE system-global-environment
  (lambda (form environment history)
    environment			;ignore
    (syntax-check '(KEYWORD DATUM) form history)
    (output/constant (strip-syntactic-closures (cadr form)))))

(define-compiler 'SET! system-global-environment
  (lambda (form environment history)
    (syntax-check '(KEYWORD FORM ? EXPRESSION) form history)
    (call-with-values
	(lambda ()
	  (classify/sublocation (cadr form) environment history select-cadr))
      (lambda (name environment-item)
	(let ((value
	       (if (pair? (cddr form))
		   (compile/subexpression (caddr form)
					  environment
					  history
					  select-caddr)
		   (output/unassigned))))
	  (if environment-item
	      (output/access-assignment
	       name
	       (compile-item/expression environment-item)
	       value)
	      (output/assignment name value)))))))

(define (classify/sublocation form environment history selector)
  (classify/location form
		     environment
		     (history/add-subproblem form
					     environment
					     history
					     selector)))

(define (classify/location form environment history)
  (let ((item (classify/expression form environment history)))
    (cond ((variable-item? item)
	   (values (variable-item/name item) #f))
	  ((access-item? item)
	   (values (access-item/name item) (access-item/environment item)))
	  (else
	   (syntax-error history "Variable required in this context:" form)))))

(define-compiler 'DELAY system-global-environment
  (lambda (form environment history)
    (syntax-check '(KEYWORD EXPRESSION) form history)
    (output/delay
     (compile/subexpression (cadr form)
			    environment
			    history
			    select-cadr))))

;;;; Definitions

(define-er-macro-transformer 'DEFINE system-global-environment
  (let ((keyword
	 (classifier->keyword
	  (lambda (form environment definition-environment history)
	    (classify/define form environment definition-environment history
			     variable-binding-theory)))))
    (lambda (form rename compare)
      compare				;ignore
      (cond ((syntax-match? '((IDENTIFIER . MIT-BVL) + FORM) (cdr form))
	     `(,(car form) ,(caadr form)
			   (,(rename 'NAMED-LAMBDA) ,@(cdr form))))
	    ((syntax-match? '((DATUM . MIT-BVL) + FORM) (cdr form))
	     `(,(car form) ,(caadr form)
			   (,(rename 'LAMBDA) ,(cdadr form) ,@(cddr form))))
	    ((syntax-match? '(IDENTIFIER) (cdr form))
	     `(,keyword ,(cadr form) ,(unassigned-expression)))
	    ((syntax-match? '(IDENTIFIER EXPRESSION) (cdr form))
	     `(,keyword ,(cadr form) ,(caddr form)))
	    (else
	     (ill-formed-syntax form))))))

(define-classifier 'DEFINE-SYNTAX system-global-environment
  (lambda (form environment definition-environment history)
    (syntax-check '(KEYWORD IDENTIFIER EXPRESSION) form history)
    (classify/define form environment definition-environment history
		     syntactic-binding-theory)))

(define (classify/define form environment definition-environment history
			 binding-theory)
  (syntactic-environment/define definition-environment
				(cadr form)
				(make-reserved-name-item history))
  (binding-theory definition-environment
		  (cadr form)
		  (classify/subexpression (caddr form)
					  environment
					  history
					  select-caddr)
		  history))

(define (syntactic-binding-theory environment name item history)
  (if (not (keyword-item? item))
      (let ((history (item/history item)))
	(syntax-error history
		      "Syntactic binding value must be a keyword:"
		      (history/original-form history))))
  (overloaded-binding-theory environment name item history))

(define (variable-binding-theory environment name item history)
  (if (keyword-item? item)
      (let ((history (item/history item)))
	(syntax-error history
		      "Binding value may not be a keyword:"
		      (history/original-form history))))
  (overloaded-binding-theory environment name item history))

(define (overloaded-binding-theory environment name item history)
  (if (keyword-item? item)
      (begin
	(syntactic-environment/define environment
				      name
				      (item/new-history item #f))
	;; User-defined macros at top level are preserved in the output.
	(if (and (transformer-item? item)
		 (syntactic-environment/top-level? environment))
	    (make-binding-item history name (transformer-item/expression item))
	    (make-null-binding-item history)))
      (make-binding-item history (bind-variable! environment name) item)))

;;;; LET-like

(define-er-macro-transformer 'LET system-global-environment
  (let ((keyword
	 (classifier->keyword
	  (lambda (form environment definition-environment history)
	    definition-environment
	    (let ((body-environment
		   (make-internal-syntactic-environment environment)))
	      (classify/let-like form
				 environment
				 body-environment
				 body-environment
				 history
				 variable-binding-theory
				 output/let))))))
    (lambda (form rename compare)
      compare				;ignore
      (cond ((syntax-match? '(IDENTIFIER (* (IDENTIFIER EXPRESSION)) + FORM)
			    (cdr form))
	     (let ((name (cadr form))
		   (bindings (caddr form))
		   (body (cdddr form)))
	       `((,(rename 'LETREC)
		  ((,name (,(rename 'LAMBDA) ,(map car bindings) ,@body)))
		  ,name)
		 ,@(map cadr bindings))))
	    ((syntax-match? '((* (IDENTIFIER ? EXPRESSION)) + FORM) (cdr form))
	     `(,keyword ,@(cdr (normalize-let-bindings form))))
	    (else
	     (ill-formed-syntax form))))))

(define-er-macro-transformer 'LET* system-global-environment
  (lambda (form rename compare)
    compare			;ignore
    (expand/let* form rename 'LET)))

(define-classifier 'LETREC system-global-environment
  (lambda (form environment definition-environment history)
    definition-environment
    (syntax-check '(KEYWORD (* (IDENTIFIER ? EXPRESSION)) + FORM) form history)
    (let ((body-environment (make-internal-syntactic-environment environment)))
      (for-each (let ((item (make-reserved-name-item history)))
		  (lambda (binding)
		    (syntactic-environment/define body-environment
						  (car binding)
						  item)))
		(cadr form))
      (classify/let-like form
			 body-environment
			 body-environment
			 body-environment
			 history
			 variable-binding-theory
			 output/letrec))))

(define (normalize-let-bindings form)
  `(,(car form) ,(map (lambda (binding)
			(if (pair? (cdr binding))
			    binding
			    (list (car binding) (unassigned-expression))))
		      (cadr form))
		,@(cddr form)))

(define-classifier 'LET-SYNTAX system-global-environment
  (lambda (form environment definition-environment history)
    definition-environment
    (syntax-check '(KEYWORD (* (IDENTIFIER EXPRESSION)) + FORM) form history)
    (classify/let-like form
		       environment
		       definition-environment
		       (make-internal-syntactic-environment environment)
		       history
		       syntactic-binding-theory
		       output/let)))

(define-er-macro-transformer 'LET*-SYNTAX system-global-environment
  (lambda (form rename compare)
    compare			;ignore
    (expand/let* form rename 'LET-SYNTAX)))

(define-classifier 'LETREC-SYNTAX system-global-environment
  (lambda (form environment definition-environment history)
    definition-environment
    (syntax-check '(KEYWORD (* (IDENTIFIER EXPRESSION)) + FORM) form history)
    (let ((body-environment (make-internal-syntactic-environment environment)))
      (for-each (let ((item (make-reserved-name-item history)))
		  (lambda (binding)
		    (syntactic-environment/define body-environment
						  (car binding)
						  item)))
		(cadr form))
      (classify/let-like form
			 body-environment
			 definition-environment
			 body-environment
			 history
			 syntactic-binding-theory
			 output/letrec))))

(define (classify/let-like form environment definition-environment
			   body-environment history binding-theory output/let)
  ;; Classify right-hand sides first, in order to catch references to
  ;; reserved names.  Then bind names prior to classifying body.
  (let* ((bindings
	  (delete-matching-items!
	      (map (lambda (binding item)
		     (binding-theory body-environment
				     (car binding)
				     item
				     history))
		   (cadr form)
		   (select-map (lambda (binding selector)
				 (classify/subexpression (cadr binding)
							 environment
							 history
							 (selector/add-cadr
							  selector)))
			       (cadr form)
			       select-cadr))
	    null-binding-item?))
	 (body
	  (classify/body (cddr form)
			 body-environment
			 definition-environment
			 history
			 select-cddr)))
    (if (eq? binding-theory syntactic-binding-theory)
	body
	(make-expression-item history
	 (lambda ()
	   (output/let (map binding-item/name bindings)
		       (map (lambda (binding)
			      (compile-item/expression
			       (binding-item/value binding)))
			    bindings)
		       (compile-body-item body)))))))

(define (expand/let* form rename let-keyword)
  (capture-expansion-history
   (lambda (history)
     (syntax-check '(KEYWORD (* DATUM) + FORM) form history)
     (let ((bindings (cadr form))
	   (body (cddr form))
	   (keyword (rename let-keyword)))
       (if (pair? bindings)
	   (let loop ((bindings bindings))
	     (if (pair? (cdr bindings))
		 `(,keyword (,(car bindings)) ,(loop (cdr bindings)))
		 `(,keyword ,bindings ,@body)))
	   `(,keyword ,bindings ,@body))))))

;;;; Bodies

(define (compile-body-item item)
  (call-with-values
      (lambda ()
	(extract-declarations-from-body (body-item/components item)))
    (lambda (declaration-items items)
      (call-with-values (lambda () (split-body-items items))
	(lambda (names items)
	  (output/body names
		       (map declaration-item/text declaration-items)
		       (compile-body-items item items)))))))

(define (split-body-items items)
  (let loop ((items items) (names '()) (items* '()))
    (cond ((not (pair? items))
	   (values (reverse! names)
		   (reverse! items*)))
	  ((binding-item? (car items))
	   (let ((history (item/history (car items)))
		 (name (binding-item/name (car items)))
		 (value (binding-item/value (car items))))
	     (loop (cdr items)
		   (cons name names)
		   (cons (make-expression-item history
			   (lambda ()
			     (output/assignment
			      name
			      (compile-item/expression value))))
			 items*))))
	  (else
	   (loop (cdr items)
		 names
		 (cons (car items) items*))))))

;;;; Derived syntax

(define-er-macro-transformer 'AND system-global-environment
  (lambda (form rename compare)
    compare				;ignore
    (capture-expansion-history
     (lambda (history)
       (syntax-check '(KEYWORD * EXPRESSION) form history)
       (let ((operands (cdr form)))
	 (if (pair? operands)
	     (let ((if-keyword (rename 'IF)))
	       (let loop ((operands operands))
		 (if (pair? (cdr operands))
		     `(,if-keyword ,(car operands)
				   ,(loop (cdr operands))
				   #F)
		     (car operands))))
	     `#T))))))

(define-er-macro-transformer 'OR system-global-environment
  (lambda (form rename compare)
    compare				;ignore
    (capture-expansion-history
     (lambda (history)
       (syntax-check '(KEYWORD * EXPRESSION) form history)
       (let ((operands (cdr form)))
	 (if (pair? operands)
	     (let ((let-keyword (rename 'LET))
		   (if-keyword (rename 'IF))
		   (temp (rename 'TEMP)))
	       (let loop ((operands operands))
		 (if (pair? (cdr operands))
		     `(,let-keyword ((,temp ,(car operands)))
				    (,if-keyword ,temp
						 ,temp
						 ,(loop (cdr operands))))
		     (car operands))))
	     `#F))))))

(define-er-macro-transformer 'CASE system-global-environment
  (lambda (form rename compare)
    (capture-expansion-history
     (lambda (history)
       (syntax-check '(KEYWORD EXPRESSION + (DATUM + EXPRESSION)) form history)
       (call-with-syntax-error-procedure
	(lambda (syntax-error)
	  (letrec
	      ((process-clause
		(lambda (clause rest)
		  (cond ((null? (car clause))
			 (process-rest rest))
			((and (identifier? (car clause))
			      (compare (rename 'ELSE) (car clause))
			      (null? rest))
			 `(,(rename 'BEGIN) ,@(cdr clause)))
			((list? (car clause))
			 `(,(rename 'IF) (,(rename 'MEMV) ,(rename 'TEMP)
							  ',(car clause))
					 (,(rename 'BEGIN) ,@(cdr clause))
					 ,(process-rest rest)))
			(else
			 (syntax-error "Ill-formed clause:" clause)))))
	       (process-rest
		(lambda (rest)
		  (if (pair? rest)
		      (process-clause (car rest) (cdr rest))
		      (unspecific-expression)))))
	    `(,(rename 'LET) ((,(rename 'TEMP) ,(cadr form)))
			     ,(process-clause (caddr form)
					      (cdddr form))))))))))

(define-er-macro-transformer 'COND system-global-environment
  (lambda (form rename compare)
    (capture-expansion-history
     (lambda (history)
       (let ((clauses (cdr form)))
	 (if (not (pair? clauses))
	     (syntax-error history "Form must have at least one clause:" form))
	 (let loop ((clause (car clauses)) (rest (cdr clauses)))
	   (expand/cond-clause clause rename compare history (null? rest)
			       (if (pair? rest)
				   (loop (car rest) (cdr rest))
				   (unspecific-expression)))))))))

(define-er-macro-transformer 'DO system-global-environment
  (lambda (form rename compare)
    (capture-expansion-history
     (lambda (history)
       (syntax-check '(KEYWORD (* (IDENTIFIER EXPRESSION ? EXPRESSION))
			       (+ FORM)
			       * FORM)
		      form history)
       (let ((bindings (cadr form))
	     (r-loop (rename 'DO-LOOP)))
	 `(,(rename 'LET)
	   ,r-loop
	   ,(map (lambda (binding)
		   (list (car binding) (cadr binding)))
		 bindings)
	   ,(expand/cond-clause (caddr form) rename compare history #f
				`(,(rename 'BEGIN)
				  ,@(cdddr form)
				  (,r-loop ,@(map (lambda (binding)
						    (if (pair? (cddr binding))
							(caddr binding)
							(car binding)))
						  bindings))))))))))

(define (expand/cond-clause clause rename compare history else-allowed?
			    alternative)
  (if (not (and (pair? clause) (list? (cdr clause))))
      (syntax-error history "Ill-formed clause:" clause))
  (cond ((and (identifier? (car clause))
	      (compare (rename 'ELSE) (car clause)))
	 (if (not else-allowed?)
	     (syntax-error history "Misplaced ELSE clause:" clause))
	 (if (or (not (pair? (cdr clause)))
		 (and (identifier? (cadr clause))
		      (compare (rename '=>) (cadr clause))))
	     (syntax-error history "Ill-formed ELSE clause:" clause))
	 `(,(rename 'BEGIN) ,@(cdr clause)))
	((not (pair? (cdr clause)))
	 (let ((r-temp (rename 'TEMP)))
	   `(,(rename 'LET) ((,r-temp ,(car clause)))
			    (,(rename 'IF) ,r-temp ,r-temp ,alternative))))
	((and (identifier? (cadr clause))
	      (compare (rename '=>) (cadr clause)))
	 (if (not (and (pair? (cddr clause))
		       (null? (cdddr clause))))
	     (syntax-error history "Ill-formed => clause:" clause))
	 (let ((r-temp (rename 'TEMP)))
	   `(,(rename 'LET) ((,r-temp ,(car clause)))
			    (,(rename 'IF) ,r-temp
					   (,(caddr clause) ,r-temp)
					   ,alternative))))
	(else
	 `(,(rename 'IF) ,(car clause)
			 (,(rename 'BEGIN) ,@(cdr clause))
			 ,alternative))))

(define-er-macro-transformer 'QUASIQUOTE system-global-environment
  (lambda (form rename compare)
    (call-with-syntax-error-procedure
     (lambda (syntax-error)
       (define (descend-quasiquote x level return)
	 (cond ((pair? x) (descend-quasiquote-pair x level return))
	       ((vector? x) (descend-quasiquote-vector x level return))
	       (else (return 'QUOTE x))))
       (define (descend-quasiquote-pair x level return)
	 (cond ((not (and (pair? x)
			  (identifier? (car x))
			  (pair? (cdr x))
			  (null? (cddr x))))
		(descend-quasiquote-pair* x level return))
	       ((compare (rename 'QUASIQUOTE) (car x))
		(descend-quasiquote-pair* x (+ level 1) return))
	       ((compare (rename 'UNQUOTE) (car x))
		(if (zero? level)
		    (return 'UNQUOTE (cadr x))
		    (descend-quasiquote-pair* x (- level 1) return)))
	       ((compare (rename 'UNQUOTE-SPLICING) (car x))
		(if (zero? level)
		    (return 'UNQUOTE-SPLICING (cadr x))
		    (descend-quasiquote-pair* x (- level 1) return)))
	       (else
		(descend-quasiquote-pair* x level return))))
       (define (descend-quasiquote-pair* x level return)
	 (descend-quasiquote (car x) level
	   (lambda (car-mode car-arg)
	     (descend-quasiquote (cdr x) level
	       (lambda (cdr-mode cdr-arg)
		 (cond ((and (eq? car-mode 'QUOTE) (eq? cdr-mode 'QUOTE))
			(return 'QUOTE x))
		       ((eq? car-mode 'UNQUOTE-SPLICING)
			(if (and (eq? cdr-mode 'QUOTE) (null? cdr-arg))
			    (return 'UNQUOTE car-arg)
			    (return 'APPEND
				    (list car-arg
					  (finalize-quasiquote cdr-mode
							       cdr-arg)))))
		       ((and (eq? cdr-mode 'QUOTE) (list? cdr-arg))
			(return 'LIST
				(cons (finalize-quasiquote car-mode car-arg)
				      (map (lambda (element)
					     (finalize-quasiquote 'QUOTE
								  element))
					   cdr-arg))))
		       ((eq? cdr-mode 'LIST)
			(return 'LIST
				(cons (finalize-quasiquote car-mode car-arg)
				      cdr-arg)))
		       (else
			(return
			 'CONS
			 (list (finalize-quasiquote car-mode car-arg)
			       (finalize-quasiquote cdr-mode cdr-arg))))))))))
       (define (descend-quasiquote-vector x level return)
	 (descend-quasiquote (vector->list x) level
	   (lambda (mode arg)
	     (case mode
	       ((QUOTE) (return 'QUOTE x))
	       ((LIST) (return 'VECTOR arg))
	       (else
		(return 'LIST->VECTOR
			(list (finalize-quasiquote mode arg))))))))
       (define (finalize-quasiquote mode arg)
	 (case mode
	   ((QUOTE) `(,(rename 'QUOTE) ,arg))
	   ((UNQUOTE) arg)
	   ((UNQUOTE-SPLICING) (syntax-error ",@ in illegal context:" arg))
	   (else `(,(rename mode) ,@arg))))
       (capture-expansion-history
	(lambda (history)
	  (syntax-check '(KEYWORD EXPRESSION) form history)
	  (descend-quasiquote (cadr form) 0 finalize-quasiquote)))))))

;;;; MIT-specific syntax

(define-er-macro-transformer 'ACCESS system-global-environment
  (let ((keyword
	 (classifier->keyword
	  (lambda (form environment definition-environment history)
	    definition-environment
	    (make-access-item history
			      (cadr form)
			      (classify/subexpression (caddr form)
						      environment
						      history
						      select-caddr))))))
    (lambda (form rename compare)
      rename compare			;ignore
      (cond ((syntax-match? '(IDENTIFIER EXPRESSION) (cdr form))
	     `(,keyword ,@(cdr form)))
	    ((syntax-match? '(IDENTIFIER IDENTIFIER + FORM) (cdr form))
	     `(,keyword ,(cadr form) (,(car form) ,@(cddr form))))
	    (else
	     (ill-formed-syntax form))))))

(define access-item-rtd
  (make-item-type "access-item" '(NAME ENVIRONMENT)
    (lambda (item)
      (output/access-reference
       (access-item/name item)
       (compile-item/expression (access-item/environment item))))))

(define make-access-item
  (item-constructor access-item-rtd '(NAME ENVIRONMENT)))

(define access-item?
  (item-predicate access-item-rtd))

(define access-item/name
  (item-accessor access-item-rtd 'NAME))

(define access-item/environment
  (item-accessor access-item-rtd 'ENVIRONMENT))

(define-er-macro-transformer 'CONS-STREAM system-global-environment
  (lambda (form rename compare)
    compare				;ignore
    (capture-expansion-history
     (lambda (history)
       (syntax-check '(KEYWORD EXPRESSION EXPRESSION) form history)
       `(,(rename 'CONS) ,(cadr form)
			 (,(rename 'DELAY) ,(caddr form)))))))

(define-compiler 'DEFAULT-OBJECT? system-global-environment
  (lambda (form environment history)
    (syntax-check '(KEYWORD IDENTIFIER) form history)
    (let ((item
	   (classify/subexpression (cadr form)
				   environment
				   history
				   select-cadr)))
      (if (not (variable-item? item))
	  (syntax-error history "Variable required in this context:" form))
      (output/unassigned-test (variable-item/name item)))))

(define-er-macro-transformer 'DEFINE-INTEGRABLE system-global-environment
  (lambda (form rename compare)
    compare				;ignore
    (let ((r-declare (rename 'DECLARE)))
      (cond ((syntax-match? '(IDENTIFIER EXPRESSION) (cdr form))
	     `(,(rename 'BEGIN)
	       (,r-declare (INTEGRATE ,(cadr form)))
	       (,(rename 'DEFINE) ,@(cdr form))))
	    ((syntax-match? '((IDENTIFIER * IDENTIFIER) + FORM) (cdr form))
	     `(,(rename 'BEGIN)
	       (,r-declare (INTEGRATE-OPERATOR ,(caadr form)))
	       (,(rename 'DEFINE) ,(cadr form)
				  (,r-declare (INTEGRATE ,@(cdadr form)))
				  ,@(cddr form))))
	    (else
	     (ill-formed-syntax form))))))

(define-er-macro-transformer 'FLUID-LET system-global-environment
  (lambda (form rename compare)
    compare
    (capture-expansion-history
     (lambda (history)
       (syntax-check '(KEYWORD (* (IDENTIFIER ? EXPRESSION)) + FORM)
		     form history)
       (let ((names (map car (cadr form)))
	     (r-let (rename 'LET))
	     (r-lambda (rename 'LAMBDA))
	     (r-set! (rename 'SET!)))
	 (let ((out-temps (map (make-name-generator) names))
	       (in-temps (map (make-name-generator) names))
	       (swap
		(lambda (tos names froms)
		  `(,r-lambda ()
			      ,@(map (lambda (to name from)
				       `(,r-set! ,to
						 (,r-set! ,name
							  (,r-set! ,from))))
				     tos
				     names
				     froms)
			      ,(unspecific-expression)))))
	   `(,r-let (,@(map cons in-temps (map cdr (cadr form)))
		     ,@(map list out-temps))
		    (,(rename 'SHALLOW-FLUID-BIND)
		     ,(swap out-temps names in-temps)
		     (,r-lambda () ,@(cddr form))
		     ,(swap in-temps names out-temps)))))))))

(define-compiler 'THE-ENVIRONMENT system-global-environment
  (lambda (form environment history)
    environment
    (syntax-check '(KEYWORD) form history)
    (if (not (syntactic-environment/top-level? environment))
	(syntax-error history "This form allowed only at top level:" form))
    (output/the-environment)))

(define (unspecific-expression)
  (compiler->form
   (lambda (form environment history)
     form environment history		;ignore
     (output/unspecific))))

(define (unassigned-expression)
  (compiler->form
   (lambda (form environment history)
     form environment history		;ignore
     (output/unassigned))))

;;;; Declarations

(define-classifier 'DECLARE system-global-environment
  (lambda (form environment definition-environment history)
    definition-environment
    (syntax-check '(KEYWORD * (SYMBOL * DATUM)) form history)
    (make-declaration-item history
			   (lambda ()
			     (map-declaration-references (cdr form)
							 environment
							 history
							 select-cdr)))))

(define-classifier 'LOCAL-DECLARE system-global-environment
  (lambda (form environment definition-environment history)
    (syntax-check '(KEYWORD (* (SYMBOL * DATUM)) + FORM) form history)
    (let ((body
	   (classify/body (cddr form)
			  environment
			  definition-environment
			  history
			  select-cddr)))
      (make-expression-item history
	(lambda ()
	  (output/local-declare (map-declaration-references (cadr form)
							    environment
							    history
							    select-cadr)
				(compile-body-item body)))))))

(define (map-declaration-references declarations environment history selector)
  (select-map (lambda (declaration selector)
		(let ((entry (assq (car declaration) known-declarations)))
		  (if entry
		      ((cdr entry) declaration environment history selector)
		      (begin
			(warn "Ill-formed declaration:" declaration)
			declaration))))
	      declarations
	      selector))

(define (define-declaration name mapper)
  (let ((entry (assq name known-declarations)))
    (if entry
	(set-cdr! entry mapper)
	(begin
	  (set! known-declarations
		(cons (cons name mapper) known-declarations))
	  unspecific))))

(define known-declarations '())

(define (classify/variable-subexpressions forms environment history selector)
  (select-map (lambda (form selector)
		(classify/variable-subexpression form
						 environment
						 history
						 selector))
	      forms
	      selector))

(define (classify/variable-subexpression form environment history selector)
  (let ((item (classify/subexpression form environment history selector)))
    (if (not (variable-item? item))
	(syntax-error history "Variable required in this context:" form))
    (variable-item/name item)))

(let ((ignore
       (lambda (declaration environment history selector)
	 environment history selector
	 declaration)))
  ;; The names in USUAL-INTEGRATIONS are always global.
  (define-declaration 'USUAL-INTEGRATIONS ignore)
  (define-declaration 'AUTOMAGIC-INTEGRATIONS ignore)
  (define-declaration 'ETA-SUBSTITUTION ignore)
  (define-declaration 'OPEN-BLOCK-OPTIMIZATIONS ignore)
  (define-declaration 'NO-AUTOMAGIC-INTEGRATIONS ignore)
  (define-declaration 'NO-ETA-SUBSTITUTION ignore)
  (define-declaration 'NO-OPEN-BLOCK-OPTIMIZATIONS ignore))

(let ((tail-identifiers
       (lambda (declaration environment history selector)
	 (if (not (syntax-match? '(* IDENTIFIER) (cdr declaration)))
	     (syntax-error history "Ill-formed declaration:" declaration))
	 `(,(car declaration)
	   ,@(classify/variable-subexpressions (cdr declaration)
					       environment
					       history
					       (selector/add-cdr selector))))))
  (define-declaration 'INTEGRATE tail-identifiers)
  (define-declaration 'INTEGRATE-OPERATOR tail-identifiers)
  (define-declaration 'INTEGRATE-SAFELY tail-identifiers)
  (define-declaration 'IGNORE tail-identifiers))

(define-declaration 'INTEGRATE-EXTERNAL
  (lambda (declaration environment history selector)
    environment selector
    (if (not (list-of-type? (cdr declaration) string?))
	(syntax-error history "Ill-formed declaration:" declaration))
    declaration))

(let ((varset
       (lambda (declaration environment history selector)
	 (if (not (syntax-match? '(DATUM) (cdr declaration)))
	     (syntax-error history "Ill-formed declaration:" declaration))
	 `(,(car declaration)
	   ,(let loop
		((varset (cadr declaration))
		 (selector (selector/add-cadr selector)))
	      (cond ((syntax-match? '('SET * IDENTIFIER) varset)
		     `(,(car varset)
		       ,@(classify/variable-subexpressions
			  (cdr varset)
			  environment
			  history
			  (selector/add-cdr selector))))
		    ((or (syntax-match? '('UNION * DATUM) varset)
			 (syntax-match? '('INTERSECTION * DATUM) varset)
			 (syntax-match? '('DIFFERENCE DATUM DATUM) varset))
		     `(,(car varset)
		       ,@(select-map loop
				     (cdr varset)
				     (selector/add-cdr selector))))
		    (else varset)))))))
  (define-declaration 'IGNORE-REFERENCE-TRAPS varset)
  (define-declaration 'IGNORE-ASSIGNMENT-TRAPS varset))

(define-declaration 'REPLACE-OPERATOR
  (lambda (declaration environment history selector)
    (if (not (syntax-match? '(* DATUM) (cdr declaration)))
	(syntax-error history "Ill-formed declaration:" declaration))
    `(,(car declaration)
      ,@(select-map
	 (lambda (rule selector)
	   (if (not (syntax-match? '(IDENTIFIER * (DATUM DATUM)) rule))
	       (syntax-error history "Ill-formed declaration:" declaration))
	   `(,(classify/variable-subexpression (car rule)
					       environment
					       history
					       (selector/add-car selector))
	     ,@(select-map
		(lambda (clause selector)
		  `(,(car clause)
		    ,(if (identifier? (cadr clause))
			 (classify/variable-subexpression (cadr clause)
							  environment
							  history
							  (selector/add-cadr
							   selector))
			 (cadr clause))))
		(cdr rule)
		(selector/add-cdr selector))))
	 (cdr declaration)
	 (selector/add-cdr selector)))))

(define-declaration 'REDUCE-OPERATOR
  (lambda (declaration environment history selector)
    `(,(car declaration)
      ,@(select-map
	 (lambda (rule selector)
	   (if (not (syntax-match? '(IDENTIFIER DATUM * DATUM) rule))
	       (syntax-error history "Ill-formed declaration:" declaration))
	   `(,(classify/variable-subexpression (car rule)
					       environment
					       history
					       (selector/add-car selector))
	     ,(if (identifier? (cadr rule))
		  (classify/variable-subexpression (cadr rule)
						   environment
						   history
						   (selector/add-cadr
						    selector))
		  (cadr rule))
	     ,@(select-map
		(lambda (clause selector)
		  (if (or (syntax-match? '('NULL-VALUE IDENTIFIER DATUM)
					 clause)
			  (syntax-match? '('SINGLETON IDENTIFIER) clause)
			  (syntax-match? '('WRAPPER IDENTIFIER ? DATUM)
					 clause))
		      `(,(car clause)
			,(classify/variable-subexpression (cadr clause)
							  environment
							  history
							  (selector/add-cadr
							   selector))
			,@(cddr clause))
		      clause))
		(cddr rule)
		(selector/add-cddr selector))))
	 (cdr declaration)
	 (selector/add-cdr selector)))))