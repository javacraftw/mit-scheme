/* -*-C-*-

$Header: /Users/cph/tmp/foo/mit-scheme/mit-scheme/v7/src/microcode/uxtop.c,v 1.7 1990/11/13 08:45:15 cph Rel $

Copyright (c) 1990 Massachusetts Institute of Technology

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
MIT in each case. */

#include "ux.h"
#include "uxtop.h"
#include "osctty.h"
#include "uxutil.h"
#include "errors.h"
#include "option.h"

extern void EXFUN (UX_initialize_channels, (void));
extern void EXFUN (UX_initialize_ctty, (int interactive));
extern void EXFUN (UX_initialize_directory_reader, (void));
extern void EXFUN (UX_initialize_environment, (void));
extern void EXFUN (UX_initialize_processes, (void));
extern void EXFUN (UX_initialize_signals, (void));
extern void EXFUN (UX_initialize_terminals, (void));
extern void EXFUN (UX_initialize_trap_recovery, (void));
extern void EXFUN (UX_initialize_tty, (void));
extern void EXFUN (UX_initialize_userio, (void));

extern void EXFUN (UX_reset_channels, (void));
extern void EXFUN (UX_reset_processes, (void));
extern void EXFUN (UX_reset_terminals, (void));
extern void EXFUN (execute_reload_cleanups, (void));

extern void EXFUN (UX_ctty_save_external_state, (void));
extern void EXFUN (UX_ctty_save_internal_state, (void));
extern void EXFUN (UX_ctty_restore_internal_state, (void));
extern void EXFUN (UX_ctty_restore_external_state, (void));

/* reset_interruptable_extent */

extern CONST char * OS_Name;
extern CONST char * OS_Variant;

static int interactive;

int
DEFUN_VOID (OS_under_emacs_p)
{
  return (option_emacs_subprocess);
}

void
DEFUN_VOID (OS_initialize)
{
  dstack_initialize ();
  transaction_initialize ();
  initialize_interruptable_extent ();
  {
    interactive =
      (option_force_interactive
       || (isatty (STDIN_FILENO))
       || (isatty (STDOUT_FILENO))
       || (isatty (STDERR_FILENO)));
    /* If none of the stdio streams is a terminal, disassociate us
       from the controlling terminal so that we're not affected by
       keyboard interrupts or hangup signals.  However, if we're
       running under Emacs we don't want to do this, because we want
       to receive a hangup signal if Emacs dies. */
    if ((!interactive) && (!option_emacs_subprocess))
      UX_setsid ();
    /* The argument passed to `UX_ctty_initialize' says whether to
       permit interrupt control, i.e. whether to attempt to setup the
       keyboard interrupt characters. */
    UX_initialize_ctty (interactive);
  }
  UX_initialize_channels ();
  UX_initialize_terminals ();
  UX_initialize_environment ();
  UX_initialize_tty ();
  UX_initialize_userio ();
  UX_initialize_signals ();
  UX_initialize_processes ();
  UX_initialize_trap_recovery ();
  UX_initialize_directory_reader ();
  OS_Name = SYSTEM_NAME;
  OS_Variant = SYSTEM_VARIANT;
  fprintf (stdout, "MIT Scheme running under %s\n", OS_Variant);
  if ((!option_emacs_subprocess) && (OS_ctty_interrupt_control ()))
    {
      fputs ("", stdout);
      fprintf (stdout, "Type %s followed by `H' to obtain information about interrupts.\n",
	       (char_description ((OS_ctty_quit_char ()), 1)));
    }
  fflush (stdout);
#ifdef _SUNOS
  vadvise (VA_ANOM);		/* Anomolous paging, don't try to guess. */
#endif
}

void
DEFUN_VOID (OS_reset)
{
  /*
    There should really be a reset for each initialize above,
    but the rest seem innocuous.
   */

  UX_reset_channels ();
  UX_reset_terminals ();
  UX_reset_processes ();
  execute_reload_cleanups ();
}

void
DEFUN (OS_quit, (code, abnormal_p), int code AND int abnormal_p)
{
  fflush (stdout);
  if (abnormal_p
      && interactive
      && (! ((code == TERM_SIGNAL) || (code == TERM_EOF))))
    {
      fputs ("\nScheme has terminated abnormally!\n", stdout);
      {
	int dump_core =
	  ((!option_disable_core_dump)
	   && (userio_confirm ("Would you like a core dump? [Y or N] "))
	   && (userio_confirm ("Do you really want a core dump? [Y or N] ")));
	putc ('\n', stdout);
	fflush (stdout);
	if (dump_core)
	  UX_dump_core ();
      }
    }
  OS_restore_external_state ();
}

void
DEFUN_VOID (UX_dump_core)
{
  OS_restore_external_state ();
  /* Unmask this too? */
  UX_signal (SIGABRT, SIG_DFL);
  UX_abort ();
}

void
DEFUN_VOID (OS_save_external_state)
{
  UX_ctty_save_external_state ();
}

void
DEFUN_VOID (OS_save_internal_state)
{
  UX_ctty_save_internal_state ();
}

void
DEFUN_VOID (OS_restore_internal_state)
{
  UX_ctty_restore_internal_state ();
}

void
DEFUN_VOID (OS_restore_external_state)
{
  UX_ctty_restore_external_state ();
}

void
DEFUN (error_system_call, (code, name), int code AND CONST char * name)
{
  /* Improve this so that the code and name information is available
     to the Scheme error handler. */
  extern char * sys_errlist [];
  extern int sys_nerr;
  if ((code >= 0) && (code <= sys_nerr))
    fprintf (stderr, "\nerror in system call: %s: %s\n",
	     name, (sys_errlist [code]));
  else
    fprintf (stderr, "\nunknown error %d in system call: %s\n", code, name);
  fflush (stderr);
  error_external_return ();
}
