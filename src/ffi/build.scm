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

;;;; Build Utilities
;;; package: (ffi build)

(define (add-plugin name project infodir scmlibdir scmdocdir)
  (update-plugin 'add name project infodir scmlibdir scmdocdir))

(define (remove-plugin name project infodir scmlibdir scmdocdir)
  (update-plugin 'remove name project infodir scmlibdir scmdocdir))

(define (update-plugin operation name project infodir scmlibdir scmdocdir)
  (let ((scmlibdir (->namestring (pathname-as-directory scmlibdir)))
	(infodir (and (not (string-null? infodir))
		      (->namestring (pathname-as-directory infodir))))
	(scmdocdir (and (not (string-null? scmdocdir))
			(->namestring (pathname-as-directory scmdocdir)))))
    (let ((plugins (updated-plugin-list operation name scmlibdir)))
      (update-optiondb plugins scmlibdir)
      (update-info-index project plugins infodir scmdocdir)
      (update-html-index plugins scmdocdir))))

(define (updated-plugin-list operation plugin scmlibdir)
  (let ((filename (string scmlibdir"plugins.scm")))
    (if (file-exists? filename)	 ;i.e. NOT in dpkg-buildpackage chroot
	(rewrite-file
	 filename
	 (lambda (in out)
	   (cond ((eq? operation 'add)
		  (let ((new (cons plugin (delete! plugin (read in)))))
		    (write new out)
		    new))
		 ((eq? operation 'remove)
		  (let ((new (delete! plugin (read in))))
		    (write new out)
		    new))
		 (else
		  (error "Unexpected plugin-list operation:" operation)))))
	(begin
	  (warn "plugin list not found:" filename)
	  '()))))

(define (update-optiondb plugins scmlibdir)
  (let ((filename (string scmlibdir"optiondb.scm")))
    (if (file-exists? filename)		;i.e. NOT in dpkg-buildpackage chroot
	(rewrite-file
	 filename
	 (lambda (in out)
	   (copy-to+line "(further-load-options" in out)
	   (write-string (string ";;; DO NOT EDIT the remainder of this file."
				 "  Any edits will be clobbered."
				 "\n") out)
	   (for-each
	     (lambda (name)
	       (write-string "\n(define-load-option '" out)
	       (write-string name out)
	       (write-string "\n  (standard-system-loader \"" out)
	       (write-string name out)
	       (write-string "\"))\n" out))
	     (sort plugins string<?))))
	(warn "optiondb not found:" filename))))

(define (update-info-index project plugins infodir scmdocdir)
  (if infodir
      (let ((filename (string infodir project".info")))
	(if (file-exists-or-compressed? filename)
	    (rewrite-file
	     filename
	     (lambda (in out)
	       (copy-to+line "Plugin Manuals" in out)
	       (newline out)
	       (for-each (lambda (plugin)
			   (write-direntry project plugin scmdocdir out))
			 (sort plugins string<?))))
	    (warn "Scheme Info index not found:" filename)))))

(define (write-direntry project plugin scmdocdir out)
  (let ((filename (string scmdocdir"info/"plugin".info")))
    (if (file-exists-or-compressed? filename)
	(call-with-input-file-uncompressed
	 filename
	 (lambda (in)
	   (skip-to-line "START-INFO-DIR-ENTRY" in)
	   (transform-to-line
	    "END-INFO-DIR-ENTRY" in out #f
	    (let* ((str (string "("project"/"))
		   (str-len (string-length str)))
	      (lambda (line)
		(let ((index (string-search-forward str line)))
		  (if index
		      (string (substring line 0 index)
			      "("scmdocdir"info/"
			      (substring line (fix:+ index str-len)))
		      line))))))))))

(define (update-html-index plugins scmdocdir)
  (let* ((scmhtmldir (if (file-exists? (string scmdocdir"html/index.html"))
			 (string scmdocdir"html/")
			 scmdocdir))
	 (filename (string scmhtmldir"index.html")))
    (if (file-exists? filename)
	(rewrite-file
	 filename
	 (lambda (in out)
	   (copy-to+line "<ul id=\"plugins\"" in out)
	   (newline out)
	   (write-string (string-append "<!-- DO NOT EDIT this list."
					"  Any edits will be clobbered. -->"
					"\n") out)

	   ;; Write new list.
	   (let ((names.titles (html-names.titles plugins scmhtmldir)))
	     (for-each
	       (lambda (name.title)
		 (write-string "<li><a href=\"" out)
		 (write-string (car name.title) out)
		 (write-string ".html\">" out)
		 (write-string (cdr name.title) out)
		 (write-string "</a></li>\n" out))
	       names.titles)
	     (if (null? names.titles)
		 (write-string "<i>None currently installed.</i>\n" out)))

	   ;; Skip old list.
	   (do ((line (read-line in) (read-line in)))
	       ((or (eof-object? line)
		    (string-prefix? "</ul>" line))
		(if (eof-object? line)
		    (error "Premature end of HTML index.")
		    (begin
		      (write-string line out)
		      (newline out)))))

	   ;; Copy the rest.
	   (do ((line (read-line in) (read-line in)))
	       ((eof-object? line))
	     (write-string line out)
	     (newline out))))
	(warn "Scheme html index not found:" filename))))

(define (html-names.titles plugins scmhtmldir)
  (append-map! (lambda (plugin)
		 (let ((filename (string scmhtmldir plugin".html")))
		   (if (file-exists? filename)
		       (list (cons plugin (read-html-title filename)))
		       '())))
	       plugins))

(define (read-html-title filename)
  (let ((patt (compile-regsexp '(seq "<title>"
				     (group title (* (any-char)))
				     "</title>"))))
    (call-with-input-file filename
      (lambda (in)
	(let loop ()
	  (let ((line (read-line in)))
	    (if (eof-object? line)
		(error "Could not find HTML title:" filename)
		(let ((match (regsexp-match-string patt line)))
		  (if (not match)
		      (loop)
		      (match-ref match 'title))))))))))

(define (match-ref match key)
  (let ((entry (assq key (cddr match))))
    (if entry
	(cdr entry)
	(error "Match group not found:" key match))))

(define (copy-to+line prefix in out)
  (transform-to-line prefix in out #t #f))

(define (copy-to-line prefix in out)
  (transform-to-line prefix in out #f #f))

(define (transform-to-line prefix in out inclusive? transform)
  (do ((line (read-line in) (read-line in)))
      ((or (eof-object? line)
	   (string-prefix? prefix line))
       (if (eof-object? line)
	   (error "Copied to eof without seeing line:" prefix))
       (if inclusive?
	   (let ((line* (if transform (transform line) line)))
	     (write-string line* out)
	     (newline out))))
    (write-string (if transform (transform line) line) out)
    (newline out)))

(define (skip-to-line prefix in)
  (do ((line (read-line in) (read-line in)))
      ((or (eof-object? line)
	   (string-prefix? prefix line))
       (if (eof-object? line)
	   (error "Skipped to eof without seeing line:" prefix)))))

(define (rewrite-file filename rewriter)
  (let ((suffix.progs (compressed? filename)))
    (if suffix.progs
	(rewrite-compressed-file filename suffix.progs rewriter)
	(rewrite-simple-file filename rewriter))))

(define (rewrite-simple-file filename rewriter)
  (let ((replacement (replacement-filename filename)))
    (if (file-exists? replacement)
	(delete-file replacement))
    (with-temporary-file
     replacement
     (lambda ()
       (let ((value (call-with-exclusive-output-file
		     replacement
		     (lambda (out)
		       (call-with-input-file filename
			 (lambda (in)
			   (rewriter in out)))))))
	 (rename-file replacement filename)
	 value)))))

(define (rewrite-compressed-file filename suffix.progs rewriter)
  (load-option-quietly 'synchronous-subprocess)
  (let ((compressed (string filename"."(car suffix.progs))))
    (call-with-temporary-file-pathname
     (lambda (uncompressed)
       (un/compress-file (cddr suffix.progs)
			 compressed
			 (->namestring uncompressed))
       (call-with-temporary-file-pathname
	(lambda (transformed)
	  (let ((value
		 (call-with-input-file uncompressed
		   (lambda (in)
		     (call-with-output-file transformed
		       (lambda (out)
			 (rewriter in out)))))))
	    (let ((replacement (replacement-filename filename)))
	      (if (file-exists? replacement)
		  (delete-file replacement))
	      (with-temporary-file
	       replacement
	       (lambda ()
		 (un/compress-file (cadr suffix.progs)
				   (->namestring transformed)
				   replacement)
		 (rename-file replacement compressed))))
	    value)))))))

(define (call-with-input-file-uncompressed filename receiver)
  (let ((suffix.progs (compressed? filename)))
    (if suffix.progs
	(let ((compressed (string filename"."(car suffix.progs))))
	  (call-with-temporary-file-pathname
	   (lambda (uncompressed)
	     (un/compress-file (cddr suffix.progs)
			       compressed
			       (->namestring uncompressed))
	     (call-with-input-file uncompressed receiver))))
	(call-with-input-file filename receiver))))

(define compressed-file-suffixes.progs
  '(("gz" "gzip" . "gunzip")
    ("bz2" "bzip2" . "bunzip2")
    ("Z" "compress" . "uncompress")))

(define (file-exists-or-compressed? filename)
  (or (file-exists? filename)
      (find-compressed-suffix.progs filename)))

(define (compressed? filename)
  (and (not (file-exists? filename))
       (find-compressed-suffix.progs filename)))

(define (find-compressed-suffix.progs filename)
  (find (lambda (suffix.progs)
	  (file-exists? (string filename"."(car suffix.progs))))
	compressed-file-suffixes.progs))

(define (un/compress-file program infile outfile)
  (load-option-quietly 'synchronous-subprocess)
  (let ((cmdline (string program" < "infile" > "outfile)))
    (if (not (zero? (run-shell-command cmdline)))
	(error "File un/compress failed:" cmdline))))

(define (replacement-filename filename)
  (let ((pathname (->pathname filename)))
    (string (directory-namestring pathname)
	    "."(file-namestring pathname)"."(random-alphanumeric-string 6))))

(define (random-alphanumeric-string length)
  (list->string (map (lambda (i) i (random-alphanumeric-character))
		     (iota length))))

(define (random-alphanumeric-character)
  (integer->char
   (let ((n (random 62)))
    (cond ((< n 26) (+ (char->integer #\a) n))
	  ((< n 52) (+ (char->integer #\A) (- n 26)))
	  (else     (+ (char->integer #\0) (- n 52)))))))

(define (load-option-quietly name)
  (if (not (option-loaded? name))
      (let ((kernel
	     (lambda ()
	       (parameterize* (list (cons param:suppress-loading-message? #t))
		 (lambda ()
		   (load-option name))))))
	(if (nearest-cmdl/batch-mode?)
	    (kernel)
	    (with-notification
	     (lambda (port)
	       (write-string "Loading " port)
	       (write-string (symbol->string name) port)
	       (write-string " option" port))
	     kernel)))))