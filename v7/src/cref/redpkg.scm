#| -*-Scheme-*-

$Id: redpkg.scm,v 1.8 1995/01/10 20:38:00 cph Exp $

Copyright (c) 1988-95 Massachusetts Institute of Technology

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

;;;; Package Model Reader

(declare (usual-integrations)
	 (integrate-external "object"))

(define (read-package-model filename)
  (let ((model-pathname (merge-pathnames filename)))
    (with-values
	(lambda ()
	  (sort-descriptions (read-and-parse-model model-pathname)))
      (lambda (packages extensions globals)
	(descriptions->pmodel
	 packages
	 extensions
	 (map (lambda (pathname)
		(cons
		 (->namestring pathname)
		 (let ((pathname
			(pathname-new-type (merge-pathnames pathname
							    model-pathname)
					   "glo")))
		   (if (file-exists? pathname)
		       (let ((contents (fasload pathname)))
			 (cond ((check-list contents symbol?)
				(list (cons '() contents)))
			       ((check-list contents
				  (lambda (element)
				    (and (pair? element)
					 (check-list (car element) symbol?)
					 (check-list (cdr element) symbol?))))
				contents)
			       (else
				(warn "Malformed globals file:" pathname)
				'())))
		       (begin
			 (warn "Can't find globals file:" pathname)
			 '())))))
	      globals)
	 model-pathname)))))

(define (sort-descriptions descriptions)
  (let ((packages '())
	(extensions '())
	(globals '()))
    (let loop ((descriptions descriptions))
      (for-each (lambda (description)
		  (case (car description)
		    ((DEFINE-PACKAGE)
		     (set! packages (cons (cdr description) packages)))
		    ((EXTEND-PACKAGE)
		     (set! extensions (cons (cdr description) extensions)))
		    ((GLOBAL-DEFINITIONS)
		     (set! globals
			   (append! globals (list-copy (cdr description)))))
		    ((NESTED-DESCRIPTIONS)
		     (loop (cdr description)))
		    (else
		     (error "Unknown description keyword:"
			    (car description)))))
		descriptions))
    (values (reverse! packages)
	    (reverse! extensions)
	    globals)))

(define (read-file-analyses! pmodel)
  (for-each (lambda (p&c)
	      (record-file-analysis! pmodel
				     (car p&c)
				     (analysis-cache/pathname (cdr p&c))
				     (analysis-cache/data (cdr p&c))))
	    (cache-file-analyses! pmodel)))

(define-structure (analysis-cache
		   (type vector)
		   (constructor make-analysis-cache (pathname time data))
		   (conc-name analysis-cache/))
  (pathname false read-only true)
  (time false)
  (data false))

(define (cache-file-analyses! pmodel)
  (let ((pathname (pathname-new-type (pmodel/pathname pmodel) "fre")))
    (let ((result
	   (let ((caches (if (file-exists? pathname) (fasload pathname) '())))
	     (append-map! (lambda (package)
			    (map (lambda (pathname)
				   (cons package
					 (cache-file-analysis! pmodel
							       caches
							       pathname)))
				 (package/files package)))
			  (pmodel/packages pmodel)))))
      (fasdump (map cdr result) pathname)
      result)))

(define (cache-file-analysis! pmodel caches pathname)
  (let ((cache (analysis-cache/lookup caches pathname))
	(full-pathname
	 (merge-pathnames (pathname-new-type pathname "bin")
			  (pmodel/pathname pmodel))))
    (let ((time (file-modification-time full-pathname)))
      (if (not time)
	  (error "unable to open file" full-pathname))
      (if cache
	  (begin
	    (if (> time (analysis-cache/time cache))
		(begin
		  (set-analysis-cache/data! cache (analyze-file full-pathname))
		  (set-analysis-cache/time! cache time)))
	    cache)
	  (make-analysis-cache pathname time (analyze-file full-pathname))))))

(define (analysis-cache/lookup caches pathname)
  (let loop ((caches caches))
    (and (not (null? caches))
	 (if (pathname=? pathname (analysis-cache/pathname (car caches)))
	     (car caches)
	     (loop (cdr caches))))))

(define (record-file-analysis! pmodel package pathname entries)
  (for-each
   (let ((filename (->namestring pathname))
	 (root-package (pmodel/root-package pmodel))
	 (primitive-package (pmodel/primitive-package pmodel)))
     (lambda (entry)
       (let ((name (vector-ref entry 0))
	     (expression
	      (make-expression package filename (vector-ref entry 1))))
	 (for-each-vector-element (vector-ref entry 2)
	   (lambda (name)
	     (cond ((symbol? name)
		    (make-reference package name expression))
		   ((primitive-procedure? name)
		    (make-reference primitive-package
				    (primitive-procedure-name name)
				    expression))
		   ((access? name)
		    (if (access-environment name)
			(error "Non-root access" name))
		    (make-reference root-package
				    (access-name name)
				    expression))
		   (else
		    (error "Illegal reference name" name)))))
	 (if name
	     (bind! package name expression)))))
   entries))

(define (resolve-references! pmodel)
  (for-each (lambda (package)
	      (for-each resolve-reference!
			(package/sorted-references package)))
	    (pmodel/packages pmodel)))

(define (resolve-reference! reference)
  (let ((binding
	 (package-lookup (reference/package reference)
			 (reference/name reference))))
    (if binding
	(begin
	  (set-reference/binding! reference binding)
	  (set-binding/references! binding
				   (cons reference
					 (binding/references binding)))))))

;;;; Package Descriptions

(define (read-and-parse-model pathname)
  (parse-package-expressions
   (read-file (pathname-default-type pathname "pkg"))
   pathname))

(define (parse-package-expressions expressions pathname)
  (map (lambda (expression)
	 (parse-package-expression expression pathname))
       expressions))

(define (parse-package-expression expression pathname)
  (let ((lose
	 (lambda ()
	   (error "Ill-formed package expression:" expression))))
    (if (not (and (pair? expression)
		  (symbol? (car expression))
		  (list? (cdr expression))))
	(lose))
    (case (car expression)
      ((DEFINE-PACKAGE)
       (cons 'DEFINE-PACKAGE
	     (parse-package-definition (parse-name (cadr expression))
				       (cddr expression))))
      ((EXTEND-PACKAGE)
       (cons 'EXTEND-PACKAGE
	     (parse-package-extension (parse-name (cadr expression))
				      (cddr expression))))
      ((GLOBAL-DEFINITIONS)
       (let ((filenames (cdr expression)))
	 (if (not (for-all? filenames string?))
	     (lose))
	 (cons 'GLOBAL-DEFINITIONS (map parse-filename filenames))))
      ((OS-TYPE-CASE)
       (if (not (and (list? (cdr expression))
		     (for-all? (cdr expression)
		       (lambda (clause)
			 (and (or (eq? 'ELSE (car clause))
				  (and (list? (car clause))
				       (for-all? (car clause) symbol?)))
			      (list? (cdr clause)))))))
	   (lose))
       (cons 'NESTED-DESCRIPTIONS
	     (let loop ((clauses (cdr expression)))
	       (cond ((null? clauses)
		      '())
		     ((or (eq? 'ELSE (caar clauses))
			  (memq microcode-id/operating-system (caar clauses)))
		      (parse-package-expressions (cdar clauses) pathname))
		     (else
		      (loop (cdr clauses)))))))
      ((INCLUDE)
       (cons 'NESTED-DESCRIPTIONS
	     (let ((filenames (cdr expression)))
	       (if (not (for-all? filenames string?))
		   (lose))
	       (append-map (lambda (filename)
			     (read-and-parse-model
			      (merge-pathnames filename pathname)))
			   filenames))))
      (else
       (lose)))))

(define (parse-package-definition name options)
  (check-package-options options)
  (call-with-values
      (lambda ()
	(let ((option (assq 'PARENT options)))
	  (if option
	      (let ((options (delq option options)))
		(if (not (and (pair? (cdr option))
			      (null? (cddr option))))
		    (error "Ill-formed PARENT option:" option))
		(if (assq 'PARENT options)
		    (error "Multiple PARENT options."))
		(values (parse-name (cadr option)) options))
	      (values 'NONE options))))
    (lambda (parent options)
      (let ((package (make-package-description name parent)))
	(process-package-options package options)
	package))))

(define (parse-package-extension name options)
  (check-package-options options)
  (let ((option (assq 'PARENT options)))
    (if option
	(error "PARENT option illegal in package extension:" option)))
  (let ((package (make-package-description name 'NONE)))
    (process-package-options package options)
    package))

(define (check-package-options options)
  (if (not (list? options))
      (error "Package options must be a list:" options))
  (for-each (lambda (option)
	      (if (not (and (pair? option)
			    (symbol? (car option))
			    (list? (cdr option))))
		  (error "Ill-formed package option:" option)))
	    options))

(define (process-package-options package options)
  (for-each (lambda (option)
	      (case (car option)
		((FILES)
		 (set-package-description/file-cases!
		  package
		  (append (package-description/file-cases package)
			  (list (parse-filenames (cdr option))))))
		((FILE-CASE)
		 (set-package-description/file-cases!
		  package
		  (append (package-description/file-cases package)
			  (list (parse-file-case (cdr option))))))
		((EXPORT)
		 (set-package-description/exports!
		  package
		  (append (package-description/exports package)
			  (list (parse-export (cdr option))))))
		((IMPORT)
		 (set-package-description/imports!
		  package
		  (append (package-description/imports package)
			  (list (parse-import (cdr option))))))
		((INITIALIZATION)
		 (if (package-description/initialization package)
		     (error "Multiple INITIALIZATION options:" option))
		 (set-package-description/initialization!
		  package
		  (parse-initialization (cdr option))))
		(else
		 (error "Unrecognized option keyword:" (car option)))))
	    options))

(define (parse-name name)
  (if (not (check-list name symbol?))
      (error "illegal name" name))
  name)

(define (parse-filenames filenames)
  (if (not (check-list filenames string?))
      (error "illegal filenames" filenames))
  (list #F (cons 'ELSE (map parse-filename filenames))))

(define (parse-file-case file-case)
  (if (not (and (pair? file-case)
		(symbol? (car file-case))
		(check-list (cdr file-case)
		  (lambda (clause)
		    (and (pair? clause)
			 (or (eq? 'ELSE (car clause))
			     (check-list (car clause) symbol?))
			 (check-list (cdr clause) string?))))))
      (error "Illegal file-case" file-case))
  (cons (car file-case)
	(map (lambda (clause)
	       (cons (car clause)
		     (map parse-filename (cdr clause))))
	     (cdr file-case))))

(define-integrable (parse-filename filename)
  (->pathname filename))

(define (parse-initialization initialization)
  (if (not (and (pair? initialization) (null? (cdr initialization))))
      (error "illegal initialization" initialization))
  (car initialization))

(define (parse-import import)
  (if (not (and (pair? import) (check-list (cdr import) symbol?)))
      (error "illegal import" import))
  (cons (parse-name (car import)) (cdr import)))

(define (parse-export export)
  (if (not (and (pair? export) (check-list (cdr export) symbol?)))
      (error "illegal export" export))
  (cons (parse-name (car export)) (cdr export)))

(define (check-list items predicate)
  (and (list? items)
       (for-all? items predicate)))

;;;; Packages

(define (descriptions->pmodel descriptions extensions globals pathname)
  (let ((packages
	 (map (lambda (description)
		(make-package (package-description/name description) 'UNKNOWN))
	      descriptions))
	(extra-packages '()))
    (let ((root-package
	   (or (name->package packages '())
	       (make-package '() #f))))
      (let ((get-package
	     (lambda (name intern?)
	       (if (null? name)
		   root-package
		   (or (name->package packages name)
		       (name->package extra-packages name)
		       (if intern?
			   (let ((package (make-package name 'UNKNOWN)))
			     (set! extra-packages
				   (cons package extra-packages))
			     package)
			   (error "Unknown package name:" name)))))))
	;; GLOBALS is a list of the bindings supplied externally.
	(for-each
	 (lambda (global)
	   (for-each
	    (let ((namestring (->namestring (car global))))
	      (lambda (entry)
		(for-each
		 (let ((package (get-package (car entry) #t)))
		   (lambda (name)
		     (bind! package
			    name
			    (make-expression package namestring #f))))
		 (cdr entry))))
	    (cdr global)))
	 globals)
	(for-each
	 (lambda (package description)
	   (let ((parent
		  (let ((parent-name (package-description/parent description)))
		    (and (not (eq? parent-name 'NONE))
			 (get-package parent-name #t)))))
	     (set-package/parent! package parent)
	     (if parent
		 (set-package/children!
		  parent
		  (cons package (package/children parent)))))
	   (process-package-description package description get-package))
	 packages
	 descriptions)
	(for-each
	 (lambda (extension)
	   (process-package-description
	    (get-package (package-description/name extension) #f)
	    extension
	    get-package))
	 extensions))
      (make-pmodel root-package
		   (make-package primitive-package-name #f)
		   packages
		   extra-packages
		   pathname))))

(define (package-lookup package name)
  (let package-loop ((package package))
    (or (package/find-binding package name)
	(and (package/parent package)
	     (package-loop (package/parent package))))))

(define (name->package packages name)
  (list-search-positive packages
    (lambda (package)
      (symbol-list=? name (package/name package)))))

(define (process-package-description package description get-package)
  (let ((file-cases (package-description/file-cases description)))
    (set-package/file-cases! package
			     (append! (package/file-cases package)
				      (list-copy file-cases)))
    (set-package/files!
     package
     (append! (package/files package)
	      (append-map! (lambda (file-case)
			     (append-map cdr (cdr file-case)))
			   file-cases))))
  (let ((initialization (package-description/initialization description)))
    (if (and initialization
	     (package/initialization package))
	(error "Multiple package initializations:" initialization))
    (set-package/initialization! package initialization))
  (for-each (lambda (export)
	      (let ((destination (get-package (car export) #t)))
		(for-each (lambda (name)
			    (link! package name destination name))
			  (cdr export))))
	    (package-description/exports description))
  (for-each (lambda (import)
	      (let ((source (get-package (car import) #t)))
		(for-each (lambda (name)
			    (link! source name package name))
			  (cdr import))))
	    (package-description/imports description)))

(define primitive-package-name
  (list (string->symbol "#[(cross-reference reader)primitives]")))

;;;; Binding and Reference

(define (bind! package name expression)
  (let ((value-cell (binding/value-cell (intern-binding! package name))))
    (set-expression/value-cell! expression value-cell)
    (set-value-cell/expressions!
     value-cell
     (cons expression (value-cell/expressions value-cell)))))

(define (link! source-package source-name destination-package destination-name)
  (if (package/find-binding destination-package destination-name)
      (error "Attempt to reinsert binding" destination-name))
  (let ((source-binding (intern-binding! source-package source-name)))
    (let ((destination-binding
	   (make-binding destination-package
			 destination-name
			 (binding/value-cell source-binding))))
      (rb-tree/insert! (package/bindings destination-package)
		       destination-name
		       destination-binding)
      (make-link source-binding destination-binding))))

(define (intern-binding! package name)
  (or (package/find-binding package name)
      (let ((binding
	     (let ((value-cell (make-value-cell)))
	       (let ((binding (make-binding package name value-cell)))
		 (set-value-cell/source-binding! value-cell binding)
		 binding))))
	(rb-tree/insert! (package/bindings package) name binding)
	binding)))

(define (make-reference package name expression)
  (let ((references (package/references package))
	(add-reference!
	 (lambda (reference)
	   (set-reference/expressions!
	    reference
	    (cons expression (reference/expressions reference)))
	   (set-expression/references!
	    expression
	    (cons reference (expression/references expression))))))
    (let ((reference (rb-tree/lookup references name #f)))
      (if reference
	  (begin
	    (if (not (memq expression (reference/expressions reference)))
		(add-reference! reference))
	    reference)
	  (let ((reference (%make-reference package name)))
	    (rb-tree/insert! references name reference)
	    (add-reference! reference)
	    reference)))))