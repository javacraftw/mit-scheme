#| -*-Scheme-*-

$Id: closconv.scm,v 1.5 1995/04/17 03:55:03 adams Exp $

Copyright (c) 1994 Massachusetts Institute of Technology

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

;;;; Closure converter
;;; package: (compiler midend)

(declare (usual-integrations))

(define *closconv-operator-and-operand-illegal?* true)

(define (closconv/top-level program #!optional after-cps?)
  (closconv/bind-parameters
   (and (not (default-object? after-cps?))
	after-cps?)
   (lambda ()
     (let* ((env (closconv/env/%make 'STATIC false))
	    (program* (closconv/expr env (lifter/letrecify program))))
       (closconv/analyze! env program*)))))

;;(define-macro (define-closure-converter keyword bindings . body)
;;  (let ((proc-name (symbol-append 'CLOSCONV/ keyword)))
;;    (call-with-values
;;     (lambda () (%matchup (cdr bindings) '(handler env) '(cdr form)))
;;     (lambda (names code)
;;       `(DEFINE ,proc-name
;;	  (LET ((HANDLER (LAMBDA ,(cons (car bindings) names) ,@body)))
;;	    (NAMED-LAMBDA (,proc-name ENV FORM)
;;	      (CLOSCONV/REMEMBER ,code
;;				 FORM))))))))

(define-macro (define-closure-converter keyword bindings . body)
  (let ((proc-name (symbol-append 'CLOSCONV/ keyword)))
    (call-with-values
     (lambda () (%matchup (cdr bindings) '(handler env) '(cdr form)))
     (lambda (names code)
       `(DEFINE ,proc-name
	  (LET ((HANDLER (LAMBDA ,(cons (car bindings) names) ,@body)))
	    (NAMED-LAMBDA (,proc-name ENV FORM)
	      (LET ((INFO (CLOSCONV/GET-DBG-INFO ENV FORM)))
		(LET ((CODE ,code))
		  (IF INFO
		      (CODE-REWRITE/REMEMBER* CODE INFO))
		  CODE)))))))))


(define-closure-converter LOOKUP (env name)
  (closconv/lookup* env name 'ORDINARY))

(define-closure-converter LAMBDA (env lambda-list body)
  (call-with-values
   (lambda () (closconv/lambda* 'DYNAMIC env lambda-list body))
   (lambda (expr* env*)
     (set-closconv/env/close?! env* true)
     expr*)))

(define-closure-converter LET (env bindings body)
  (let* ((env* (closconv/env/make
		(binding-context-type 'LET
				      (closconv/env/context env)
				      bindings)
		env
		(lmap car bindings)))
	 (expr* `(LET ,(closconv/bindings env* env bindings)
		   ,(closconv/expr env* body))))
    (set-closconv/env/form! env* expr*)
    expr*))

(define-closure-converter LETREC (env bindings body)
  (let* ((env* (closconv/env/make
		(binding-context-type 'LETREC
				      (closconv/env/context env)
				      bindings)
		env
		(lmap car bindings)))
	 (expr* `(LETREC ,(closconv/bindings env* env* bindings)
		   ,(closconv/expr env* body))))
    (set-closconv/env/form! env* expr*)
    expr*))

(define-closure-converter CALL (env rator cont #!rest rands)
  (let* ((rands (cons cont rands))
	 (default
	   (lambda ()
	     `(CALL ,(closconv/expr env rator)
		    ,@(closconv/expr* env rands)))))
    (cond ((LOOKUP/? rator)
	   (let* ((name (lookup/name rator))
		  (rator* (closconv/remember
			   (closconv/lookup* env name 'OPERATOR)
			   rator)))
	     `(CALL ,rator*
		    ,@(closconv/expr* env rands))))
	  ((LAMBDA/? rator)
	   (let ((ll   (lambda/formals rator))
		 (body (lambda/body rator)))
	     (guarantee-simple-lambda-list ll)
	     (guarantee-argument-list rands (length ll))
	     (let ((bindings (map list ll rands)))
	       (call-with-values
		   (lambda ()
		     (closconv/lambda*
		      (binding-context-type 'CALL
					    (closconv/env/context env)
					    bindings)
		      env ll body))
		 (lambda (rator* env*)
		   (let ((bindings* (closconv/bindings env* env bindings)))
		     `(CALL ,(closconv/remember rator* rator)
			    ,@(lmap cadr bindings*))))))))
	  (else
	   (default)))))

(define-closure-converter QUOTE (env object)
  env
  `(QUOTE ,object))

(define-closure-converter DECLARE (env #!rest anything)
  env					; ignored
  `(DECLARE ,@anything))

(define-closure-converter BEGIN (env #!rest actions)
  `(BEGIN ,@(closconv/expr* env actions)))

(define-closure-converter IF (env pred conseq alt)
  `(IF ,(closconv/expr env pred)
       ,(closconv/expr env conseq)
       ,(closconv/expr env alt)))

(define (closconv/expr env expr)
  ;; This copies the expression and returns the copy.  It
  ;; simultaneously builds an environment representation (see the data
  ;; structure closconv/expr, below) by mutating the ENV argument.
  (if (not (pair? expr))
      (illegal expr))
  (case (car expr)
    ((QUOTE)
     (closconv/quote env expr))
    ((LOOKUP)
     (closconv/lookup env expr))
    ((LAMBDA)
     (closconv/lambda env expr))
    ((LET)
     (closconv/let env expr))
    ((DECLARE)
     (closconv/declare env expr))
    ((CALL)
     (closconv/call env expr))
    ((BEGIN)
     (closconv/begin env expr))
    ((IF)
     (closconv/if env expr))
    ((LETREC)
     (closconv/letrec env expr))
    ((SET! UNASSIGNED? OR DELAY
	   ACCESS DEFINE IN-PACKAGE THE-ENVIRONMENT)
     (no-longer-legal expr))
    (else
     (illegal expr))))

(define (closconv/expr* env exprs)
  (lmap (lambda (expr)
	  (closconv/expr env expr))
	exprs))

(define (closconv/remember new old)
  (code-rewrite/remember new old))

(define (closconv/remember* new old)
  (code-rewrite/remember* new (code-rewrite/original-form old))
  new)

(define (closconv/remember*! new old)
  (code-rewrite/remember*! new (code-rewrite/original-form old))
  new)

(define (closconv/new-name prefix)
  (new-variable prefix))

(define (closconv/get-dbg-info env expr)
  (cond ((code-rewrite/original-form/previous expr)
         => (lambda (dbg-info)
              ;; Copy the dbg info, keeping dbg-references in the
	      ;; environment which will later be overwritten
              (let* ((block     (new-dbg-form/block dbg-info))
                     (block*    (new-dbg-block/copy-transforming
                                 (lambda (expr)
                                   (closconv/copy-dbg-kmp expr env))
                                 block))
                     (dbg-info* (new-dbg-form/new-block dbg-info block*)))
                dbg-info*)))
        (else #F)))

(define (closconv/copy-dbg-kmp expr env)
  (form/copy-transforming
   (lambda (form copy uninteresting)
     copy
     (or (and (LOOKUP/? form)
	      (closconv/lookup*/dbg env (lookup/name form)))
	 (uninteresting form)))
   expr))

;;;; Parameterization for invocation before and after cps conversion

;; Before CPS

(define (closconv/closure/new-name/pre-cps)
  (new-closure-variable))

(define (closconv/closure/sort-variables/pre-cps variable-refs)
  (if (there-exists? variable-refs continuation-variable?)
      (internal-error "Closing over continuation variable before CPS"
		      variable-refs))
  variable-refs)

(define (closconv/closure/make-handler/pre-cps closure-name params body
					       captured)
  captured				; ignored
  `(LAMBDA (,(car params) ,closure-name ,@(cdr params))
     ,body))

(define (closconv/closure/make-trivial/pre-cps handler)
  `(CALL (QUOTE ,%make-trivial-closure) (QUOTE #F) ,handler))

(define (closconv/closure/make-set!/pre-cps closure-name index name*)
  `(CALL (QUOTE ,%heap-closure-set!) (QUOTE #F) (LOOKUP ,closure-name)
	 ,index (LOOKUP ,name*) (QUOTE ,name*)))

;; After CPS

(define (closconv/closure/new-name/post-cps)
  (let ((name (closconv/new-name 'FRAME)))
    (declare-variable-property! name '(FRAME-VARIABLE))
    name))

(define (closconv/closure/sort-variables/post-cps variable-refs)
  (call-with-values
   (lambda ()
     (list-split variable-refs
		 (lambda (free-ref)
		   (continuation-variable?
		    (closconv/binding/name (car free-ref))))))
   (lambda (cont-refs non-cont-refs)
     (append cont-refs non-cont-refs))))

(define (closconv/closure/make-handler/post-cps closure-name params body
						captured)
  `(LAMBDA ,params
     (LET ((,closure-name
	    (CALL (QUOTE ,%fetch-stack-closure)
		  (QUOTE #F)
		  (QUOTE ,captured))))
       ,body)))

(define (closconv/closure/make-trivial/post-cps handler)
  ;; This gets invoked on lambda expressions that appear in several
  ;; places (e.g. args to %make-heap-closure, %make-trivial-closure, etc.)
  handler)

(define (closconv/closure/make-set!/post-cps closure-name index name*)
  closure-name index			; ignored
  (internal-error "Assigning closure after CPS conversion?" name*))

(define %make-closure %make-heap-closure)
(define %closure-ref %heap-closure-ref)

(let-syntax ((define-closconv-parameter
	       (macro (name)
		 `(define ,name ,(symbol-append name '/pre-cps)))))
  (define-closconv-parameter closconv/closure/sort-variables)
  (define-closconv-parameter closconv/closure/make-handler)
  (define-closconv-parameter closconv/closure/make-trivial)
  (define-closconv-parameter closconv/closure/make-set!)
  (define-closconv-parameter closconv/closure/new-name))

(define (closconv/bind-parameters after-cps? thunk)
  (let ((bind-parameters
	 (lambda (lift? sort handler trivial
			constructor refer
			set new-name)
	   (fluid-let ((*lift-closure-lambdas?* lift?)
		       (closconv/closure/sort-variables sort)
		       (closconv/closure/make-handler handler)
		       (closconv/closure/make-trivial trivial)
		       (%make-closure constructor)
		       (%closure-ref refer)
		       (closconv/closure/make-set! set)
		       (closconv/closure/new-name new-name))
	     (thunk)))))
    (if after-cps?
	(bind-parameters false
			 closconv/closure/sort-variables/post-cps
			 closconv/closure/make-handler/post-cps
			 closconv/closure/make-trivial/post-cps
			 %make-stack-closure
			 %stack-closure-ref
			 closconv/closure/make-set!/post-cps
			 closconv/closure/new-name/post-cps)
	(bind-parameters *lift-closure-lambdas?*
			 closconv/closure/sort-variables/pre-cps
			 closconv/closure/make-handler/pre-cps
			 closconv/closure/make-trivial/pre-cps
			 %make-heap-closure
			 %heap-closure-ref
			 closconv/closure/make-set!/pre-cps
			 closconv/closure/new-name/pre-cps))))

(define-structure (closconv/env
		   (conc-name closconv/env/)
		   (constructor closconv/env/%make (context parent)))
  (context false read-only true)	; Dynamic or static
  (parent false read-only true)
  (children '() read-only false)
  (bound '() read-only false)		; list of closconv/binding structures

  ;; a list of (closconv/binding reference reference ...)
  (free '() read-only false)
  ;; like FREE, but in debugging info.  Held separately as not to affect
  ;; the algorithm.
  (dbg-free '())

  (form false read-only false)

  ;; should be considered for having its form closed (i.e. converted to a
  ;; %make-xxx-closure)
  (close? false read-only false)

  ;;  slots required in closure object: either #F, #T (closed, but no
  ;;  slots), or a list of (closconv/binding reference) elements from
  ;;  free
  (closed-over false read-only false)

  (binding false read-only false))      ; known self-reference binding

(define-structure
    (closconv/binding
     (conc-name closconv/binding/)
     (constructor closconv/binding/make (name env))
     (print-procedure
      (standard-unparser-method 'CLOSCONV/BINDING
	(lambda (binding port)
	  (write-char #\space port)
	  (write (closconv/binding/name binding) port)))))
      
  (name false read-only true)
  (env false read-only true)
  (operator-refs '())
  (ordinary-refs '())
  ;;(dbg-info-refs '())
  (value false))

(define (closconv/env/make context parent bound-names)
  (let ((env (closconv/env/%make context parent)))
    (set-closconv/env/bound!
     env
     (lmap (lambda (name)
	     (closconv/binding/make name env))
	   bound-names))
    (set-closconv/env/children! parent
				(cons env (closconv/env/children parent)))
    env))

(define (closconv/lookup* env name kind)
  ;; kind = 'OPERATOR or 'ORDINARY
  (let ((ref `(LOOKUP ,name)))
    (let walk-spine ((env env))
      (cond ((not env)
	     (free-var-error name))
	    ((closconv/binding/find (closconv/env/bound env) name)
	     => (lambda (binding)
		  (case kind
		    ((ORDINARY)
		     (set-closconv/binding/ordinary-refs!
		      binding
		      (cons ref (closconv/binding/ordinary-refs binding))))
		    ((OPERATOR)
		     (set-closconv/binding/operator-refs!
		      binding
		      (cons ref (closconv/binding/operator-refs binding))))
		    (else
		     (internal-error "closconv/lookup* Illegal kind" kind)))
		  binding))
	    (else
	     (let* ((binding (walk-spine (closconv/env/parent env)))
		    (free    (closconv/env/free env))
		    (place   (assq binding free)))
	       (if (not place)
		   (set-closconv/env/free! env (cons (list binding ref) free))
		   (set-cdr! place (cons ref (cdr place))))
	       binding))))
    ref))

(define (closconv/lookup*/dbg env name)
  (let ((ref `(LOOKUP ,name)))
    (let walk-spine ((env env))
      (cond ((not env) #F)
	    ((closconv/binding/find (closconv/env/bound env) name)
	     => (lambda (binding) binding))
	    (else
	     (let ((binding (walk-spine (closconv/env/parent env))))
	       (if binding
		   (let* ((free    (closconv/env/dbg-free env))
			  (place   (assq binding free)))
		     (if (not place)
			 (set-closconv/env/dbg-free!
			  env
			  (cons (list binding ref) free))
			 (set-cdr! place (cons ref (cdr place)))))
		   binding)))))
    ref))

(define (closconv/binding/find bindings name)
  (let find ((bindings bindings))
    (and (not (null? bindings))
	 (let ((binding (car bindings)))
	   (if (not (eq? name (closconv/binding/name (car bindings))))
	       (find (cdr bindings))
	       binding)))))

(define (closconv/lambda* context env lambda-list body)
  ;; (values expr* env*)
  (let* ((env* (closconv/env/make context
				  env
				  (lambda-list->names lambda-list)))
	 (expr* `(LAMBDA ,lambda-list
		   ,(closconv/expr env* body))))
    (set-closconv/env/form! env* expr*)
    (values expr* env*)))

(define (closconv/lambda** context env lam-expr)
  ;; (values expr* env*)
  (call-with-values
   (lambda ()
     (closconv/lambda* context
		       env
		       (lambda/formals lam-expr)
		       (lambda/body lam-expr)))
   (lambda (expr* env*)
     (values (closconv/remember expr* lam-expr)
	     env*))))

(define (closconv/bindings env* env bindings)
  ;; ENV* is the environment to which the bindings are being added
  ;; ENV is the environment in which the form part of the binding is
  ;;     to be evaluated (i.e. it will be EQ? to ENV* for LETREC but
  ;;     not for LET)
  (lmap (lambda (binding)
	  (let ((name (car binding))
		(value (cadr binding)))
	    (list
	     name
	     (if (or (not (pair? value))
		     (not (eq? (car value) 'LAMBDA)))
		 (closconv/expr env value)
		 (call-with-values
		  (lambda ()
		    (closconv/lambda** 'DYNAMIC ; bindings are dynamic
				       env
				       value))
		  (lambda (value* env**)
		    (let ((binding
			   (or (closconv/binding/find (closconv/env/bound env*)
						      name)
			       (internal-error "Missing binding" name))))
		      (set-closconv/env/binding! env** binding)
		      (set-closconv/binding/value! binding env**)
		      value*)))))))
	bindings))

;;;; The Analyzer/Converter Proper

(define (closconv/analyze! env program)
  (closconv/contaminate! env)
  (closconv/rewrite! env)
  program)

(define (closconv/contaminate! env)
  (cond ((closconv/env/closed-over env))   ; Already figured out
	((closconv/env/close? env)
	 (closconv/close! env))
	((not (closconv/env/binding env))) ; No known self-binding
	((not (null? (closconv/binding/ordinary-refs
		      (closconv/env/binding env))))
	 ;; Self-binding is referenced other than by a call
	 (closconv/close! env)))
  (for-each closconv/contaminate! (closconv/env/children env)))

(define (closconv/close! env)
  (let ((closed-over
	 (list-transform-negative (closconv/env/free env)
	   (lambda (free-ref)
	     (closconv/static-binding? (car free-ref))))))
    (set-closconv/env/closed-over!
     env
     (if (or (null? closed-over)
	     ;; Do not close if only free reference is self!
	     (and (null? (cdr closed-over))
		  (closconv/self-reference? env (car (car closed-over)))))
	 true
	 closed-over))
    (for-each (lambda (free-ref)
		(let* ((binding (car free-ref))
		       (env* (closconv/binding/value binding)))
		  (if (and env*
			   (not (closconv/env/closed-over env*)))
		      (closconv/close! env*))))
	      closed-over)))

(define (closconv/static-binding? binding)
  (and (eq? (closconv/env/context (closconv/binding/env binding)) 'STATIC)
       (not (pseudo-static-variable? (closconv/binding/name binding)))))

(define (closconv/self-reference? env binding)
  (let ((value (closconv/binding/value binding)))
    (and value
	 (eq? value env))))

(define (closconv/rewrite! env)
  ;; This must work from the root to the leaves, because a reference
  ;; may be rewritten multiple times as it is copied from closure
  ;; to closure.
  (let ((form (closconv/env/form env))
	(closed-over (closconv/env/closed-over env)))
    (cond ((or (not form)
	       (LET/? form))
	   (if closed-over
	       (internal-error "Form can't be closed" form))
	   (for-each closconv/rewrite! (closconv/env/children env)))
	  ((LETREC/? form)
	   ;; Handled specially because it must ensure that recursive
	   ;; references work, and the LETREC must remain syntactically
	   ;; acceptable (only lambda bindings allowed).
	   (if closed-over
	       (internal-error "Form can't be closed" form))
	   (let ((closed
		  (list-transform-positive (closconv/env/bound env)
		    (lambda (binding)
		      (let ((value (closconv/binding/value binding)))
			(and value
			     (closconv/env/closed-over value)))))))
	     (if (null? closed)
		 (closconv/rewrite/letrec/trivial! env)
		 (closconv/rewrite/letrec! env closed))))
	  ((LAMBDA/? form)
	   (cond ((closconv/env/binding env) => closconv/verify-binding))
	   (cond ((pair? closed-over)
		  (closconv/rewrite/lambda! env '()))
		 (closed-over
		  (closconv/rewrite/lambda/trivial! env)))
	   (for-each closconv/rewrite! (closconv/env/children env)))
	  (else
	   (internal-error "Unknown binding form" form)))))

(define (closconv/rewrite/lambda/trivial! env)
  (closconv/maybe-lift! env
			(let ((form (closconv/env/form env)))
			  (closconv/remember* (form/preserve form)
					      form))
			closconv/closure/make-trivial))

(define (closconv/verify-binding binding)
  (if (and (not (null? (closconv/binding/operator-refs binding)))
	   (not (null? (closconv/binding/ordinary-refs binding)))
	   *closconv-operator-and-operand-illegal?*)
      (internal-error "Binding is both operator and operand" binding)))

(define (closconv/rewrite/lambda! env circular)
  ;; Env is a LAMBDA env
  (let ((closure-name (closconv/closure/new-name))
	(closed-over*
	 (closconv/closure/sort-variables (closconv/env/closed-over env))))
    (let* ((self-binding  (closconv/env/binding env)) ;possibly #F
	   (closed-over			; Remove self-reference if present
	    (cond ((and self-binding (assq self-binding closed-over*))
		   => (lambda (free-ref)
			(delq free-ref closed-over*)))
		  (else
		   closed-over*)))
	   (closed-over-names
	    (list->vector (lmap (lambda (binding.refs)
				  (closconv/binding/name (car binding.refs)))
				closed-over)))
	   (captured
	    (lmap (lambda (binding.refs)
		    (if (memq (car binding.refs) circular)
			`(QUOTE ,#f)
			(form/preserve (cadr binding.refs))))
		  closed-over))
	   (form (closconv/env/form env)))

      ;; Rewrite references to closed variables and self
      (for-each
       (lambda (free-ref)
	 (let* ((binding    (car free-ref))
		(name       (closconv/binding/name binding))
		(references (cdr free-ref))
		(references-and-dbg-references
		 (cond ((assq binding (closconv/env/dbg-free env))
			=> (lambda (dbg-ref)
			     (append references (cdr dbg-ref))))
		       (else  references))))

	   (define (rewrite-self-reference! ref)
	     (form/rewrite! ref
	       `(LOOKUP ,closure-name)))
	   (define (rewrite-other-reference! ref)
	     (form/rewrite! ref
	       `(CALL (QUOTE ,%closure-ref)
		      (QUOTE #F)
		      (LOOKUP ,closure-name)
		      (CALL (QUOTE ,%vector-index)
			    (QUOTE #F)
			    (QUOTE ,closed-over-names)
			    (QUOTE ,name))
		      (QUOTE ,name))))

	   (for-each (if (eq? (car free-ref) self-binding)
			 rewrite-self-reference!
			 rewrite-other-reference!)
		     references-and-dbg-references)))
       closed-over*)

      ;; Convert to closure and maybe lift to top level
      (closconv/maybe-lift!
       env
       (closconv/remember*
	(closconv/closure/make-handler closure-name
				       (lambda/formals form)
				       (lambda/body form)
				       closed-over-names)
	form)
       (lambda (handler)
	 `(CALL (QUOTE ,%make-closure)
		(QUOTE #F)
		,handler
		(QUOTE ,closed-over-names)
		,@captured)))
      closed-over-names)))

(define (closconv/maybe-lift! env handler transform)
  (form/rewrite! (closconv/env/form env)
		 (if *lift-closure-lambdas?*
		     (let ((handler-name
			    (let ((binding (closconv/env/binding env)))
			      (or (and binding
				       (variable/rename
					(closconv/binding/name binding)))
				  (closconv/new-name 'LAMBDA)))))
		       (closconv/lift! env handler-name handler)
		       (transform `(LOOKUP ,handler-name)))
		     (transform handler))))

(define (closconv/rewrite/letrec/trivial! env)
  (for-each closconv/rewrite! (closconv/env/children env)))

(define (closconv/rewrite/letrec! env closed*)
  ;; Env is a LETREC env
  (for-each closconv/verify-binding closed*)
  (call-with-values
   (lambda ()
     (list-split closed*
		 (lambda (binding)
		   (let ((value (closconv/binding/value binding)))
		     (pair? (closconv/env/closed-over value))))))
   (lambda (closed trivial)
     ;; IMPORTANT: This assumes that make-trivial-closure can be called
     ;; multiple times for the same lambda expression and returns
     ;; EQ? results!
     (for-each
      (lambda (binding)
	(let ((val-form
	       (closconv/env/form (closconv/binding/value binding))))
	  (for-each (lambda (ref)
		      (let* ((ref* (form/preserve ref))
			     (new (closconv/closure/make-trivial ref*)))
			(form/rewrite! ref new)
			(closconv/remember*! ref val-form)))
		    (closconv/binding/ordinary-refs binding))))
      trivial)
     (let* ((envs (lmap closconv/binding/value closed))
	    (circular
	     (lmap
	      (lambda (env)
		(let ((closed-over (closconv/env/closed-over env)))
		  (list-transform-positive closed
		    (lambda (binding)
		      (assq binding closed-over)))))
	      envs)))
       (let* ((circ-results (map closconv/rewrite/lambda! envs circular))
	      (form (closconv/env/form env)))
	 (form/rewrite!
	  form

	  (bind* (lmap closconv/binding/name closed)
		 (lmap closconv/env/form envs)
		 (beginnify
		  (append-map*
		   (list
		    (let ((ok (delq* closed (closconv/env/bound env))))
		      (if (null? ok)
			  (caddr form)
			  (let ((ok-names (lmap closconv/binding/name ok)))
			    `(LETREC ,(list-transform-positive (cadr form)
					(lambda (binding)
					  (memq (car binding) ok-names)))
			       ,(caddr form))))))
		   (lambda (binding captured-names circular)
		     (let ((name (closconv/binding/name binding))
			   (l (vector->list captured-names)))
		       (append-map
			(lambda (binding)
			  (let ((name* (closconv/binding/name binding)))
			    (if (not (memq name* l))
				'()
				(list
				 (closconv/closure/make-set!
				  name
				  `(CALL (QUOTE ,%vector-index)
					 (QUOTE #F)
					 (QUOTE ,captured-names)
					 (QUOTE ,name*))
				  name*)))))
			circular)))
		   closed circ-results circular)))))
       (let ((envs (map* envs closconv/binding/value trivial)))
	 (for-each (lambda (closed-env)
		     (for-each closconv/rewrite!
			       (closconv/env/children closed-env)))
		   envs)
	 (for-each closconv/rewrite!
		   (delq* envs (closconv/env/children env))))))))

(define closconv/lift!
  (lifter/make (lambda (env)
		 (let loop ((env env))
		   (cond ((not env)
			  (internal-error "No static frame" env))
			 ((eq? (closconv/env/context env) 'STATIC)
			  (closconv/env/form env))
			 (else
			  (loop (closconv/env/parent env))))))))