#| -*-Scheme-*-

$Header: /Users/cph/tmp/foo/mit-scheme/mit-scheme/v7/src/runtime/sysclk.scm,v 14.3 1995/08/08 15:31:05 adams Exp $

Copyright (c) 1988, 1989 Massachusetts Institute of Technology

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

;;;; System Clock
;;; package: (runtime system-clock)

(declare (usual-integrations))

(define (initialize-package!)
  (reset-system-clock!)
  (add-event-receiver! event:after-restore reset-system-clock!))

(define (reset-system-clock!)
  (set! offset-time (process-time-clock))
  (set! non-runtime 0))

(define offset-time)
(define non-runtime)

(define-integrable process-time-clock
  (ucode-primitive system-clock 0))

(define-integrable real-time-clock
  (ucode-primitive real-time-clock 0))

(define (system-clock)
  (process->system-time (process-time-clock)))

(define (runtime)
  (process->system-time (- (process-time-clock) non-runtime)))

(define (increment-non-runtime! ticks)
  (set! non-runtime (+ non-runtime ticks)))

(define (measure-interval runtime? thunk)
  (let ((start (process-time-clock)))
    (let ((receiver (thunk (process->system-time start))))
      (let ((end (process-time-clock)))
	(if (not runtime?)
	    (increment-non-runtime! (- end start)))
	(receiver (process->system-time end))))))

(define (process->system-time ticks)
  (internal-time/ticks->seconds (- ticks offset-time)))

(define (internal-time/ticks->seconds ticks)
  (/ (exact->inexact ticks) 1000))

(define (internal-time/seconds->ticks seconds)
  (round->exact (* seconds 1000)))

(define (with-timings thunk receiver)
  (let ((process-start  (process-time-clock))
	(gc-time-start  non-runtime)
	(real-start     (real-time-clock)))
    (let ((value (thunk)))
      (let ((process-end  (process-time-clock))
	    (gc-time-end  non-runtime)
	    (real-end     (real-time-clock)))
	(let ((process-time (- process-end process-start))
	      (gc-time      (- gc-time-end gc-time-start))
	      (real-time    (- real-end real-start)))
	  (receiver (- process-time gc-time)
		    gc-time
		    real-time)
	  value)))))