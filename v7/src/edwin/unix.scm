;;; -*-Scheme-*-
;;;
;;;	$Header: /Users/cph/tmp/foo/mit-scheme/mit-scheme/v7/src/edwin/unix.scm,v 1.6 1989/04/28 22:54:18 cph Rel $
;;;
;;;	Copyright (c) 1989 Massachusetts Institute of Technology
;;;
;;;	This material was developed by the Scheme project at the
;;;	Massachusetts Institute of Technology, Department of
;;;	Electrical Engineering and Computer Science.  Permission to
;;;	copy this software, to redistribute it, and to use it for any
;;;	purpose is granted, subject to the following restrictions and
;;;	understandings.
;;;
;;;	1. Any copy made of this software must include this copyright
;;;	notice in full.
;;;
;;;	2. Users of this software agree to make their best efforts (a)
;;;	to return to the MIT Scheme project any improvements or
;;;	extensions that they make, so that these may be included in
;;;	future releases; and (b) to inform MIT of noteworthy uses of
;;;	this software.
;;;
;;;	3. All materials developed as a consequence of the use of this
;;;	software shall duly acknowledge such use, in accordance with
;;;	the usual standards of acknowledging credit in academic
;;;	research.
;;;
;;;	4. MIT has made no warrantee or representation that the
;;;	operation of this software will be error-free, and MIT is
;;;	under no obligation to provide any services, by way of
;;;	maintenance, update, or otherwise.
;;;
;;;	5. In conjunction with products arising from the use of this
;;;	material, there shall be no use of the name of the
;;;	Massachusetts Institute of Technology nor of any adaptation
;;;	thereof in any advertising, promotional, or sales literature
;;;	without prior written consent from MIT in each case.
;;;
;;; NOTE: Parts of this program (Edwin) were created by translation
;;; from corresponding parts of GNU Emacs.  Users should be aware that
;;; the GNU GENERAL PUBLIC LICENSE may apply to these parts.  A copy
;;; of that license should have been included along with this file.
;;;

;;;; Unix Customizations for Edwin

(declare (usual-integrations))

(define (os/trim-pathname-string string)
  (let ((end (string-length string)))    (let loop ((index end))
      (let ((slash (substring-find-previous-char string 0 index #\/)))
	(cond ((or (not slash) (= slash end))
	       string)
	      ((memv (string-ref string (1+ slash)) '(#\~ #\$))
	       (string-tail string (1+ slash)))
	      ((zero? slash)
	       string)
	      ((char=? #\/ (string-ref string (-1+ slash)))
	       (string-tail string slash))
	      (else
	       (loop (-1+ slash))))))))

(define (os/auto-save-pathname pathname buffer-name)
  (let ((wrap
	 (lambda (name directory)
	   (merge-pathnames (string->pathname (string-append "#" name "#"))
			    directory))))
    (if (not pathname)
	(wrap (string-append "%" buffer-name)
	      (working-directory-pathname))
	(wrap (pathname-name-string pathname)
	      (pathname-directory-path pathname)))))

(define-variable backup-by-copying-when-linked
  "*Non-false means use copying to create backups for files with multiple names.
This causes the alternate names to refer to the latest version as edited.
This variable is relevant only if  Backup By Copying  is false."
 false)

(define-variable backup-by-copying-when-mismatch
  "*Non-false means create backups by copying if this preserves owner or group.
Renaming may still be used (subject to control of other variables)
when it would not result in changing the owner or group of the file;
that is, for files which are owned by you and whose group matches
the default for a new file created there by you.
This variable is relevant only if  Backup By Copying  is false."
  false)

(define-variable version-control
  "*Control use of version numbers for backup files.
#T means make numeric backup versions unconditionally.
#F means make them for files that have some already.
'NEVER means do not make them."
  false)

(define-variable kept-old-versions
  "*Number of oldest versions to keep when a new numbered backup is made."
  2)

(define-variable kept-new-versions
  "*Number of newest versions to keep when a new numbered backup is made.
Includes the new backup.  Must be > 0"
  2)

(define (os/backup-buffer? truename)
  (and (memv (string-ref (vector-ref (file-attributes truename) 8) 0)
	     '(#\- #\l))
       (not
	(let ((directory (pathname-directory truename)))
	  (and (pair? directory)
	       (eq? 'ROOT (car directory))
	       (pair? (cdr directory))
	       (eqv? "tmp" (cadr directory)))))))

(define (os/default-backup-filename)
  "~/%backup%~")

(define (os/backup-by-copying? truename)
  (let ((attributes (file-attributes truename)))
    (and (ref-variable backup-by-copying-when-linked)
	 (> (file-attributes/n-links attributes) 1))
    (and (ref-variable backup-by-copying-when-mismatch)
	 (not (and (= (file-attributes/uid attributes) (unix/current-uid))
		   (= (file-attributes/gid attributes) (unix/current-gid)))))))

(define (os/buffer-backup-pathname truename)
  (let ((no-versions
	 (lambda ()
	   (values
	    (string->pathname (string-append (pathname->string truename) "~"))
	    '()))))
    (if (eq? 'NEVER (ref-variable version-control))
	(no-versions)
	(let ((prefix (string-append (pathname-name-string truename) ".~")))
	  (let ((filenames
		 (os/directory-list-completions
		  (pathname-directory-string truename)
		  prefix))
		(prefix-length (string-length prefix)))
	    (let ((possibilities
		   (list-transform-positive filenames
		     (let ((non-numeric (char-set-invert char-set:numeric)))
		       (lambda (filename)
			 (let ((end (string-length filename)))
			   (let ((last (-1+ end)))
			     (and (char=? #\~ (string-ref filename last))
				  (eqv? last
					(substring-find-next-char-in-set
					 filename
					 prefix-length
					 end
					 non-numeric))))))))))
	      (let ((versions
		     (sort (map (lambda (filename)
				  (string->number
				   (substring filename
					      prefix-length
					      (-1+ (string-length filename)))))
				possibilities)
			   <)))
		(let ((high-water-mark (apply max (cons 0 versions))))
		  (if (or (ref-variable version-control)
			  (positive? high-water-mark))
		      (let ((version->pathname
			     (let ((directory
				    (pathname-directory-path truename)))
			       (lambda (version)
				 (merge-pathnames
				  (string->pathname
				   (string-append prefix
						  (number->string version)
						  "~"))
				  directory)))))
			(values
			 (version->pathname (1+ high-water-mark))
			 (let ((start (ref-variable kept-old-versions))
			       (end
				(- (length versions)
				   (-1+ (ref-variable kept-new-versions)))))
			   (if (< start end)
			       (map version->pathname
				    (sublist versions start end))
			       '()))))
		      (no-versions))))))))))

(define (os/make-dired-line pathname)
  (let ((attributes (file-attributes pathname)))
    (and attributes
	 (string-append
	  "  "
	  (file-attributes/mode-string attributes)
	  " "
	  (pad-on-left-to
	   (number->string (file-attributes/n-links attributes) 10)
	   3)
	  " "
	  (pad-on-right-to (unix/uid->string (file-attributes/uid attributes))
			   8)
	  " "
	  (pad-on-right-to (unix/gid->string (file-attributes/gid attributes))
			   8)
	  " "
	  (pad-on-left-to
	   (number->string (file-attributes/length attributes) 10)
	   7)
	  " "
	  (substring (unix/file-time->string
		      (file-attributes/modification-time attributes))
		     4
		     16)
	  " "
	  (pathname-name-string pathname)))))

(define (os/dired-filename-region lstart)
  (let ((lend (line-end lstart 0)))
    (char-search-backward #\Space lend lstart 'LIMIT)    (make-region (re-match-end 0) lend)))

(define (os/directory-list directory)
  (let loop
      ((name ((ucode-primitive open-directory) directory))
       (result '()))
    (if name
	(loop ((ucode-primitive directory-read)) (cons name result))
	result)))

(define (os/directory-list-completions directory prefix)
  (if (string-null? prefix)
      (os/directory-list directory)
      (let loop
	  ((name ((ucode-primitive open-directory) directory))
	   (result '()))
	(if name
	    (loop ((ucode-primitive directory-read))
		  (if (string-prefix? prefix name) (cons name result) result))
	    result))))
(define-integrable os/file-directory?
  (ucode-primitive file-directory?))

(define-integrable (os/make-filename directory filename)
  (string-append directory filename))

(define-integrable (os/filename-as-directory filename)
  (string-append filename "/"))

(define (os/completion-ignored-extensions)
  (list-copy
   '(".o" ".elc" "~" ".bin" ".lbin" ".fasl"
     ".dvi" ".toc" ".log" ".aux"
     ".lof" ".blg" ".bbl" ".glo" ".idx" ".lot")))