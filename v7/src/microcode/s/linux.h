/* -*-C-*-
   System file for Linux

$Id: linux.h,v 1.13 1997/10/02 19:52:53 adams Exp $

Copyright (c) 1995-97 Massachusetts Institute of Technology

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

#define LIBX11_MACHINE -L/usr/X11R6/lib

#define LIB_DEBUG

#define ALTERNATE_M4 s/ultrix.m4

#ifdef __ELF__
#define M4_SWITCH_SYSTEM -P "define(LINUX_ELF,1)"
/* This is kind of random -- the only system that I've tried this on
   is Debian 1.1, which uses ncurses for its termcap support (Debian
   0.93R6 used termcap instead).  Debian can have -ltermcap, but it's
   an optional package and often not installed.  */
#define LIBS_TERMCAP -lncurses
#else
#define M4_SWITCH_SYSTEM
#define LIBS_TERMCAP -ltermcap
#endif

#define LD_SWITCH_SYSTEM -export-dynamic

#ifndef DISABLE_DLD_SUPPORT
/* These definitions configure the microcode to support dynamic loading. */
#define SOURCES_SYSTEM pruxdld.c
#define OBJECTS_SYSTEM pruxdld.o
#define LIBS_SYSTEM -ldl
#endif

/* Use the built-in files <limits.h> and <float.h> rather than those
   generated by the "hard-par" program.  */
#define USE_BUILT_IN_LIMITS_FILES
