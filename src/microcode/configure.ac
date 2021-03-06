dnl Process this file with autoconf to produce a configure script.

AC_INIT([MIT/GNU Scheme microcode], [15.3], [bug-mit-scheme@gnu.org], [mit-scheme])
AC_CONFIG_SRCDIR([boot.c])
AC_CONFIG_HEADERS([config.h])
AC_PROG_MAKE_SET

AC_COPYRIGHT(
[Copyright (C) 1986, 1987, 1988, 1989, 1990, 1991, 1992, 1993, 1994,
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
])

AH_TOP([/*

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

*/

#ifndef SCM_CONFIG_H
#define SCM_CONFIG_H])

AH_BOTTOM(
[#ifndef __unix__
#  define __unix__
#endif

#if defined(_IRIX) || defined(_IRIX4) || defined(_IRIX6)
#  define __IRIX__
#endif

#if defined(__hpux) || defined(hpux)
#  define __HPUX__
#endif

/* If we're running under GNU libc, turn on all the features.
   Otherwise this should be harmless.  */
#define _GNU_SOURCE

#include <sys/types.h>

#ifdef TIME_WITH_SYS_TIME
#  include <sys/time.h>
#  include <time.h>
#else
#  ifdef HAVE_SYS_TIME_H
#    include <sys/time.h>
#  else
#    include <time.h>
#  endif
#endif

#ifdef HAVE_TERMIOS_H
#  include <termios.h>
#else
#  ifdef HAVE_TERMIO_H
#    include <termio.h>
#  endif
#endif

#ifdef HAVE_SYS_MMAN_H
#  include <sys/mman.h>
#endif

#ifdef HAVE_MMAP
#  if defined(MAP_ANON) && !defined(MAP_ANONYMOUS)
#    define MAP_ANONYMOUS MAP_ANON
#  endif
#  ifdef MAP_ANONYMOUS
#    define USE_MMAP_HEAP_MALLOC
#  endif
#endif

/* Include the shared configuration header.  */
#include "confshared.h"

#endif /* SCM_CONFIG_H */])

dnl Feature options
AC_ARG_ENABLE([valgrind-mode],
    AS_HELP_STRING([--enable-valgrind-mode],
	[Support running under valgrind [[no]]]))
: ${enable_valgrind_mode='no'}

AC_ARG_ENABLE([debugging],
    AS_HELP_STRING([--enable-debugging],
	[Compile with debugging support [[no]]]))
: ${enable_debugging='no'}

AC_ARG_ENABLE([native-code],
    AS_HELP_STRING([--enable-native-code],
	[Support native compiled code if available [[yes]]]))
: ${enable_native_code='yes'}

AC_ARG_WITH([openssl],
    AS_HELP_STRING([--with-openssl],
	[Use OpenSSL crypto library if available [[yes]]]))
: ${with_openssl='yes'}

AC_ARG_WITH([mcrypt],
    AS_HELP_STRING([--with-mcrypt],
	[Use mcrypt library if available [[yes]]]))
: ${with_mcrypt='yes'}

AC_ARG_WITH([gdbm],
    AS_HELP_STRING([--with-gdbm],
	[Use gdbm library if available [[yes]]]))
: ${with_gdbm='yes'}

AC_ARG_WITH([db-4],
    AS_HELP_STRING([--with-db-4],
	[Use Berkeley DB v4 library if available [[yes]]]))
: ${with_db_4='yes'}

AC_ARG_WITH([libpq],
    AS_HELP_STRING([--with-libpq],
	[Use PostgreSQL libpq library if available [[yes]]]))
: ${with_libpq='yes'}

AC_ARG_WITH([termcap],
    AS_HELP_STRING([--with-termcap],
	[Use a termcap library if available [[yes]]]))
: ${with_termcap='yes'}

dnl For reasons I don't understand, it is necessary to use
dnl quadigraphs here instead of [[ ... ]].
AC_ARG_WITH([macosx-version],
    AS_HELP_STRING([--with-macosx-version],
	[MacOSX version to compile for @<:@host's version@:>@]))

AC_ARG_WITH([module-loader],
    AS_HELP_STRING([--with-module-loader],
	[Pathname of the Scheme executable, for building modules only]))
: ${with_module_loader='yes'}

dnl Substitution variables to be filled in below.
GC_HEAD_FILES="gccode.h cmpgc.h cmpintmd-config.h cmpintmd.h"
OPTIONAL_BASES=
OPTIONAL_SOURCES=
OPTIONAL_OBJECTS=
PRBFISH_LIBS=
SCHEME_DEFS=-DMIT_SCHEME
SCHEME_LDFLAGS=
MODULE_BASES=
MODULE_AUX_BASES=
MODULE_LIBS=
MODULE_TARGETS=
MODULE_RULES=/dev/null
MODULE_CFLAGS=
MODULE_LDFLAGS=
MODULE_LOADER=
LIARC_VARS=/dev/null
LIARC_RULES=/dev/null
AUX_PROGRAMS=
AUX_DATA=
AUXDIR_NAME=
EXE_NAME=
INSTALL_INCLUDE=

AC_CANONICAL_HOST

dnl Save these prior to running AC_PROG_CC.
SAVED_CFLAGS=${CFLAGS}
SAVED_LDFLAGS=${LDFLAGS}

dnl Checks for programs.
AC_PROG_CC
AC_PROG_CC_STDC
if test "x${ac_cv_prog_cc_c99}" != xno; then
   AC_DEFINE([HAVE_STDC_99], [1], [Does the compiler support C99?])
fi
if test "x${ac_cv_prog_cc_c89}" != xno; then
   AC_DEFINE([HAVE_STDC_89], [1], [Does the compiler support C89?])
fi
AC_C_BACKSLASH_A
AC_C_BIGENDIAN
AC_C_CONST
AC_C_RESTRICT
AC_C_VOLATILE
AC_C_INLINE
AC_C_STRINGIZE
AC_C_PROTOTYPES
AC_PROG_EGREP
AC_PROG_FGREP
AC_PROG_GREP
AC_PROG_INSTALL
AC_PROG_LN_S
AC_PROG_MAKE_SET

if test ${GCC} = yes; then

    dnl Discard flags computed by AC_PROG_CC; we'll use our own.
    CFLAGS=${SAVED_CFLAGS}
    LDFLAGS=${SAVED_LDFLAGS}

    if test ${enable_debugging} = no; then
	CFLAGS="-O3 ${CFLAGS}"
    else
	CFLAGS="-O0 -g -DENABLE_DEBUGGING_TOOLS ${CFLAGS}"
	LDFLAGS="${LDFLAGS} -g"
    fi
    CFLAGS="-Wall -Wundef -Wpointer-arith -Winline ${CFLAGS}"
    CFLAGS="-Wstrict-prototypes -Wnested-externs -Wredundant-decls ${CFLAGS}"

    AC_MSG_CHECKING([for GCC>=4])
    AC_COMPILE_IFELSE(
	[AC_LANG_PROGRAM(
	    [[
	    #if __GNUC__ >= 4
	    ;
	    #else
	    #error "gcc too old"
	    #endif
	    ]],
	    [[]]
	)],
	[
	AC_MSG_RESULT([yes])
	CFLAGS="-Wextra -Wno-sign-compare -Wno-unused-parameter ${CFLAGS}"
	CFLAGS="-Wold-style-definition ${CFLAGS}"
	],
	[AC_MSG_RESULT([no])])

    # other possibilities:
    # -Wmissing-prototypes -Wunreachable-code -Wwrite-strings
fi
FOO=`${INSTALL} --help 2> /dev/null | ${FGREP} -e --preserve-timestamps`
if test "x${FOO}" != x; then
    INSTALL="${INSTALL} --preserve-timestamps"
fi
CCLD=${CC}

MIT_SCHEME_NATIVE_CODE([${enable_native_code}],[${host_cpu}])

AUXDIR_NAME=mit-scheme-${mit_scheme_native_code}
EXE_NAME=mit-scheme-${mit_scheme_native_code}

dnl Add OS-dependent customizations.  This must happen before checking
dnl any headers or library routines, because it may add CFLAGS or
dnl LDFLAGS that the subsequent checks require.

DO_GCC_TESTS=no
GNU_LD=no
case ${host_os} in
linux-gnu)
    M4_FLAGS="${M4_FLAGS} -P __linux__,1"
    DO_GCC_TESTS=yes
    GNU_LD=yes
    ;;
freebsd*)
    M4_FLAGS="${M4_FLAGS} -P SUPPRESS_LEADING_UNDERSCORE,1"
    DO_GCC_TESTS=yes
    GNU_LD=yes
    ;;
dragonfly*)
    M4_FLAGS="${M4_FLAGS} -P SUPPRESS_LEADING_UNDERSCORE,1"
    DO_GCC_TESTS=yes
    GNU_LD=yes
    ;;
darwin*)
    if test -n "${with_macosx_version}"; then
	MACOSX=${with_macosx_version}
	MACOSX_CFLAGS="-mmacosx-version-min=${MACOSX}"
    else
	MACOSX=`sw_vers | ${GREP} ^ProductVersion: \
	    | ${EGREP} -o '[[0-9]+\.[0-9]+]'`
	if test -z "${MACOSX}"; then
	    AC_MSG_ERROR([Unable to determine MacOSX version])
	fi
	MACOSX_CFLAGS=
    fi
    if test "${MACOSX}" = 10.4; then
	SDK=MacOSX${MACOSX}u
    else
	SDK=MacOSX${MACOSX}
    fi
    MACOSX_SDKS=
    for dir in /Developer/SDKs \
    	/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs
    do
	if test -d "${dir}"; then
	    MACOSX_SDKS=${dir}
	    break
	fi
    done
    if test -z "${MACOSX_SDKS}"; then
	AC_MSG_WARN([Can't find SDKs directory, not checking for SDK])
    else
        MACOSX_SYSROOT=
        for sysroot in ${MACOSX_SDKS}/${SDK}.sdk ${MACOSX_SDKS}/MacOSX.sdk; do
            if test -d "${sysroot}"; then
                MACOSX_SYSROOT=${sysroot}
                MACOSX_CFLAGS="${MACOSX_CFLAGS} -isysroot ${sysroot}"
                break
            fi
        done
        if test -z "${MACOSX_SYSROOT}"; then
            AC_MSG_ERROR([No MacOSX SDK for version: ${MACOSX}])
        fi
    fi
    MACOSX_CFLAGS="${MACOSX_CFLAGS} -fconstant-cfstrings"
    MACOSX_CFLAGS="${MACOSX_CFLAGS} -DSIGNAL_HANDLERS_CAN_USE_SCHEME_STACK"
    dnl needed for lgamma_r:
    MACOSX_CFLAGS="${MACOSX_CFLAGS} -D_REENTRANT"
    AC_MSG_NOTICE([Compiling for MacOSX version ${MACOSX}])
    case ${mit_scheme_native_code} in
    i386)
	MACOSX_CFLAGS="-arch i386 ${MACOSX_CFLAGS}"
	AS_FLAGS="-arch i386 ${AS_FLAGS}"
	SCHEME_LDFLAGS="${SCHEME_LDFLAGS} -Wl,-pagezero_size,04000000"
    	;;
    x86-64)
	MACOSX_CFLAGS="-arch x86_64 ${MACOSX_CFLAGS}"
	AS_FLAGS="-arch x86_64 ${AS_FLAGS}"
    	;;
    esac
    if ! cc --version | grep -q clang; then
        dnl -frounding-math not supported by clang.
        MACOSX_CFLAGS="${MACOSX_CFLAGS} -frounding-math"
    fi
    CFLAGS="${CFLAGS} ${MACOSX_CFLAGS}"
    LDFLAGS="${LDFLAGS} ${MACOSX_CFLAGS} -Wl,-syslibroot,${MACOSX_SYSROOT}"
    LDFLAGS="${LDFLAGS} -framework CoreFoundation"
    MODULE_LDFLAGS="${MODULE_LDFLAGS} -bundle"
    if test "${with_module_loader}" != no; then
      if test "${with_module_loader}" = yes; then
	MODULE_LOADER='${SCHEME_EXE}'
      else
	MODULE_LOADER="${with_module_loader}"
      fi
      MODULE_LDFLAGS="${MODULE_LDFLAGS} -bundle_loader ${MODULE_LOADER}"
    fi
    AUX_PROGRAMS="${AUX_PROGRAMS} macosx-starter"
    ;;
netbsd*)
    DO_GCC_TESTS=yes
    GNU_LD=yes
    ;;
openbsd*)
    M4_FLAGS="${M4_FLAGS} -P SUPPRESS_LEADING_UNDERSCORE,1"
    DO_GCC_TESTS=yes
    GNU_LD=yes
    ;;
solaris*)
    # How do we tell whether we're using GNU ld or Solaris ld?
    if test ${GCC} = yes; then
	DO_GCC_TESTS=yes
	M4_FLAGS="${M4_FLAGS} -P SUPPRESS_LEADING_UNDERSCORE,1"
    fi
    LDFLAGS="${LDFLAGS} -lsocket -lnsl"
    ;;
esac

if test "${DO_GCC_TESTS}" = yes; then
    if test "${GNU_LD}" = yes; then
	SCHEME_LDFLAGS="${SCHEME_LDFLAGS} -export-dynamic"
    fi
    MODULE_CFLAGS="-fPIC ${MODULE_CFLAGS}"
    MODULE_LDFLAGS="${MODULE_LDFLAGS} -shared -fPIC"
    AC_MSG_CHECKING([for ELF binaries])
    AC_EGREP_CPP([yes],
	[
	#ifdef __ELF__
	yes
	#endif
	],
	[
	AC_MSG_RESULT([yes])
	M4_FLAGS="${M4_FLAGS} -P SUPPRESS_LEADING_UNDERSCORE,1"
	M4_FLAGS="${M4_FLAGS} -P __ELF__,1"
	],
	[AC_MSG_RESULT([no])])
fi

dnl Checks for libraries.
AC_CHECK_LIB([m], [exp])

dnl Checks for header files.
AC_HEADER_DIRENT
AC_HEADER_STDC
AC_HEADER_STDBOOL
AC_HEADER_SYS_WAIT
AC_HEADER_TIME
AC_CHECK_HEADERS([bsdtty.h fcntl.h fenv.h ieeefp.h limits.h malloc.h poll.h])
AC_CHECK_HEADERS([sgtty.h stropts.h time.h])
AC_CHECK_HEADERS([sys/file.h sys/ioctl.h sys/mount.h sys/param.h])
AC_CHECK_HEADERS([sys/ptyio.h sys/socket.h sys/time.h sys/timex.h sys/un.h])
AC_CHECK_HEADERS([sys/vfs.h])
AC_CHECK_HEADERS([termio.h termios.h unistd.h util.h utime.h])
AC_CHECK_HEADERS([dlfcn.h netdb.h signal.h])
AC_CHECK_HEADERS([sys/mman.h float.h assert.h stdint.h])

define([SCM_INC_TIME],
    [
    #ifdef TIME_WITH_SYS_TIME
    #  include <sys/time.h>
    #  include <time.h>
    #else
    #  ifdef HAVE_SYS_TIME_H
    #    include <sys/time.h>
    #  else
    #    include <time.h>
    #  endif
    #endif
    ])

define([SCM_INC_SYS_TIMEX],
    [
    SCM_INC_TIME
    #ifdef HAVE_SYS_TIMEX_H
    #  include <sys/timex.h>
    #endif
    ])

define([SCM_INC_TERMIO],
    [
    #ifdef HAVE_TERMIOS_H
    #  include <termios.h>
    #else
    #  ifdef HAVE_TERMIO_H
    #    include <termio.h>
    #  endif
    #endif
    ])

define([SCM_INC_NETDB],
    [
    #ifdef HAVE_NETDB_H
    #  include <netdb.h>
    #endif
    ])

define([SCM_INC_SIGNAL],
    [
    #ifdef HAVE_SIGNAL_H
    #  include <signal.h>
    #endif
    ])

define([SCM_INC_SOCKET],
    [
    #include <sys/types.h>
    #ifdef HAVE_SYS_SOCKET_H
    #  include <sys/socket.h>
    #endif
    ])

define([SCM_INC_BSDTTY],
    [
    #ifdef HAVE_BSDTTY_H
    #  include <bsdtty.h>
    #endif
    ])

dnl Checks for types and structs
AC_TYPE_MODE_T
AC_TYPE_OFF_T
AC_TYPE_PID_T
AC_TYPE_SIGNAL
AC_TYPE_SIZE_T
AC_TYPE_UID_T

AC_TYPE_INT8_T
AC_TYPE_INT16_T
AC_TYPE_INT32_T
AC_TYPE_INT64_T
AC_TYPE_INTPTR_T
AC_TYPE_INTMAX_T
AC_TYPE_UINT8_T
AC_TYPE_UINT16_T
AC_TYPE_UINT32_T
AC_TYPE_UINT64_T
AC_TYPE_UINTPTR_T
AC_TYPE_UINTMAX_T

AC_CHECK_SIZEOF([char])
AC_CHECK_SIZEOF([short])
AC_CHECK_SIZEOF([int])
AC_CHECK_SIZEOF([long])
AC_CHECK_SIZEOF([unsigned char])
AC_CHECK_SIZEOF([unsigned short])
AC_CHECK_SIZEOF([unsigned int])
AC_CHECK_SIZEOF([unsigned long])
AC_CHECK_SIZEOF([void *])
AC_CHECK_SIZEOF([intptr_t])
AC_CHECK_SIZEOF([uintptr_t])
AC_CHECK_SIZEOF([intmax_t])
AC_CHECK_SIZEOF([uintmax_t])

if test ${ac_cv_sizeof_char} -ne 1; then
    AC_MSG_ERROR([SIZEOF_CHAR is not 1])
fi

if test ${ac_cv_sizeof_unsigned_char} -ne 1; then
    AC_MSG_ERROR([SIZEOF_UNSIGNED_CHAR is not 1])
fi

AC_CHECK_TYPE([nlink_t],
    [],
    [AC_DEFINE([nlink_t], [short],
	[Define to 'short' if undefined.])])

AC_CHECK_TYPE([clock_t],
    [],
    [AC_DEFINE([clock_t], [unsigned long],
	[Define to `unsigned long' if <time.h> doesn't define.])],
    [SCM_INC_TIME])

AC_CHECK_TYPE([time_t],
    [],
    [AC_DEFINE([time_t], [long],
	[Define to `long' if <time.h> doesn't define.])],
    [SCM_INC_TIME])

AC_CHECK_TYPE([socklen_t],
    [],
    [AC_DEFINE([socklen_t], [int],
	[Define to `int' if <sys/socket.h> doesn't define.])],
    [SCM_INC_SOCKET])

AC_CHECK_TYPE([cc_t],
    [],
    [AC_DEFINE([cc_t], [unsigned char],
	[Define to `unsigned char' if <termios.h> doesn't define.])],
    [SCM_INC_TERMIO])

AC_CHECK_TYPE([speed_t],
    [],
    [AC_DEFINE([speed_t], [short],
	[Define to `short' if <termios.h> doesn't define.])],
    [SCM_INC_TERMIO])

define([SCM_INC_FENV],
    [
    #include <fenv.h>
    ])

if test "x$ac_cv_header_fenv_h" = "xyes"; then
  AC_CHECK_TYPES([fenv_t], [], [], [SCM_INC_FENV])
  AC_CHECK_TYPES([fexcept_t], [], [], [SCM_INC_FENV])
fi

AC_CHECK_SIZEOF([time_t])
AC_CHECK_SIZEOF([off_t])

AC_STRUCT_TM
AC_STRUCT_TIMEZONE

dnl Timezone stuff is hairy; there's no standard.
have_timezone_info=no
val_tm_gmtoff=
val_timezone=

if test ${have_timezone_info} = no; then
    AC_CHECK_MEMBER([struct tm.tm_gmtoff],
	[
	have_timezone_info=yes
	val_tm_gmtoff=tm_gmtoff
	],
	[],
	[SCM_INC_TIME])
fi

if test ${have_timezone_info} = no; then
    AC_CHECK_MEMBER([struct tm.__tm_gmtoff],
	[
	have_timezone_info=yes
	val_tm_gmtoff=__tm_gmtoff
	],
	[],
	[SCM_INC_TIME])
fi

if test ${have_timezone_info} = no; then
    AC_CHECK_DECL([__timezone],
	[
	have_timezone_info=yes
	val_timezone=__timezone
	],
	[],
	[SCM_INC_TIME])
fi

if test ${have_timezone_info} = no; then
    AC_CHECK_DECL([_timezone],
	[
	have_timezone_info=yes
	val_timezone=_timezone
	],
	[],
	[SCM_INC_TIME])
fi

if test ${have_timezone_info} = no; then
    AC_CHECK_DECL([timezone],
	[
	have_timezone_info=yes
	val_timezone=timezone
	],
	[],
	[SCM_INC_TIME])
fi

if test -n "${val_tm_gmtoff}"; then
    AC_DEFINE([HAVE_TM_GMTOFF], [1],
	[Define if `struct tm' has the `tm_gmtoff' member.])
    AC_DEFINE_UNQUOTED([TM_GMTOFF], [${val_tm_gmtoff}],
	[Define to name of `tm_gmtoff' member if available.])
fi

if test -n "${val_timezone}"; then
    AC_DEFINE([HAVE_TIMEZONE], [1],
	[Define if timezone variable is available.])
    AC_DEFINE_UNQUOTED([TIMEZONE], [${val_timezone}],
	[Define to name of timezone variable if available.])
fi

AC_CHECK_TYPE([struct ltchars],
    [AC_DEFINE([HAVE_STRUCT_LTCHARS], [1],
	[Define if `struct ltchars' is defined in <bsdtty.h>.])],
    [],
    [SCM_INC_BSDTTY])

AC_CHECK_MEMBER([struct hostent.h_addr_list],
    [AC_DEFINE([HAVE_HOSTENT_H_ADDR_LIST], [1],
	[Define if `struct hostent' has the `h_addr_list' member.])],
    [],
    [SCM_INC_NETDB])

AC_CHECK_TYPE([struct sigcontext],
    [AC_DEFINE([HAVE_STRUCT_SIGCONTEXT], [1],
	[Define if `struct sigcontext' is defined in <signal.h>.])],
    [],
    [SCM_INC_SIGNAL])

AC_CHECK_TYPE([struct ntptimeval],
    [AC_DEFINE([HAVE_STRUCT_NTPTIMEVAL], [1],
	[Define if `struct ntptimeval' is defined in <sys/timex.h>.])
     AC_CHECK_MEMBER([struct ntptimeval.tai],
	[AC_DEFINE([HAVE_NTPTIMEVAL_TAI], [1],
	    [Define if `struct ntptimeval' has the `tai' member.])],
	[],
	[SCM_INC_SYS_TIMEX])
     AC_CHECK_MEMBER([struct ntptimeval.time.tv_nsec],
	[AC_DEFINE([HAVE_NTPTIMEVAL_TIME_TV_NSEC], [1],
	    [Define if `struct ntptimeval' has the `time.tv_nsec' member.])],
	[],
	[SCM_INC_SYS_TIMEX])],
    [],
    [SCM_INC_SYS_TIMEX])

AC_CHECK_TYPE([struct timex],
    [AC_DEFINE([HAVE_STRUCT_TIMEX], [1],
	[Define if `struct timex' is defined in <sys/timex.h>.])
     AC_CHECK_MEMBER([struct timex.tai],
	[AC_DEFINE([HAVE_TIMEX_TAI], [1],
	    [Define if `struct timex' has the `tai' member.])],
	[],
	[SCM_INC_SYS_TIMEX])
     AC_CHECK_MEMBER([struct timex.time.tv_usec],
	[AC_DEFINE([HAVE_TIMEX_TIME_TV_USEC], [1],
	    [Define if `struct timex' has the `time.tv_usec' member.])],
	[],
	[SCM_INC_SYS_TIMEX])],
    [],
    [SCM_INC_SYS_TIMEX])

dnl Checks for compiler characteristics.
AC_C_BIGENDIAN
AC_C_CHAR_UNSIGNED
AC_C_CONST

dnl Checks for C library functions.
AC_FUNC_GETPGRP
AC_FUNC_MEMCMP
AC_FUNC_MMAP
AC_FUNC_SETPGRP
AC_FUNC_SETVBUF_REVERSED
AC_FUNC_UTIME_NULL
AC_FUNC_VFORK
AC_FUNC_VPRINTF
AC_FUNC_WAIT3
AC_CHECK_FUNCS([clock_gettime closefrom ctermid])
AC_CHECK_FUNCS([dup2])
AC_CHECK_FUNCS([expm1])
AC_CHECK_FUNCS([fcntl fdatasync feclearexcept fedisableexcept feenableexcept])
AC_CHECK_FUNCS([fegetenv fegetexcept fegetexceptflag fegetround feholdexcept])
AC_CHECK_FUNCS([feraiseexcept fesetenv fesetexceptflag fesetround])
AC_CHECK_FUNCS([fetestexcept feupdateenv floor fmod fpathconf fpgetround])
AC_CHECK_FUNCS([fpsetround frexp fsync fsync_range ftruncate])
AC_CHECK_FUNCS([getcwd gethostbyname gethostname getlogin getpagesize getpgrp])
AC_CHECK_FUNCS([getpt gettimeofday getwd grantpt])
AC_CHECK_FUNCS([kill])
AC_CHECK_FUNCS([lgamma_r lockf log1p])
AC_CHECK_FUNCS([madvise memcpy mkdir mktime modf])
AC_CHECK_FUNCS([nice ntp_adjtime ntp_gettime])
AC_CHECK_FUNCS([openpty])
AC_CHECK_FUNCS([poll pollts ppoll posix_madvise posix_openpt prealloc])
AC_CHECK_FUNCS([rename rmdir])
AC_CHECK_FUNCS([pselect select setitimer setpgrp setpgrp2 shmat sigaction])
AC_CHECK_FUNCS([sighold sigsuspend socket statfs strchr strerror strstr strtol])
AC_CHECK_FUNCS([strtoul symlink sync_file_range sysconf])
AC_CHECK_FUNCS([times truncate])
AC_CHECK_FUNCS([uname utime])
AC_CHECK_FUNCS([waitpid])

if test ${ac_cv_type_signal} = void; then
    AC_DEFINE([VOID_SIGNAL_HANDLERS], [1],
	[Define if RETSIGTYPE is `void'.])
fi

dnl Checks for system characteristics.
AC_PATH_X
AC_SYS_LARGEFILE
AC_SYS_LONG_FILE_NAMES

dnl curses/termcap/terminfo support

dnl This is a mess because neither `tparam' nor `tparm' is available
dnl everywhere, but as long as we have some access to the termcap
dnl database, we can emulate `tparam' -- either in terms of `tparm' or
dnl by pretending we know the format -- without bringing in the local
dnl termcap reimplementation.

if test "x${with_termcap}" = xyes; then

    AC_DEFINE([USE_TERMCAP], [1], [Define if termcap should be used.])
    AC_CHECK_HEADERS([ncurses.h curses.h term.h termcap.h])
    AC_CHECK_LIB([ncurses], [tgetent], [have_ncurses=yes])
    AC_CHECK_LIB([ncurses], [tparm], [have_ncurses_tparm=yes])
    AC_CHECK_LIB([ncurses], [tparam], [have_ncurses_tparam=yes])
    AC_CHECK_LIB([curses], [tgetent], [have_curses=yes])
    AC_CHECK_LIB([curses], [tparm], [have_curses_tparm=yes])
    AC_CHECK_LIB([curses], [tparam], [have_curses_tparam=yes])
    AC_CHECK_LIB([termcap], [tgetent], [have_termcap=yes])
    AC_CHECK_LIB([termcap], [tparm], [have_termcap_tparm=yes])
    AC_CHECK_LIB([termcap], [tparam], [have_termcap_tparam=yes])

    if test "x${have_ncurses}" = xyes; then
	with_termcap=ncurses
    elif test "x${have_curses_tparm}" != xyes	\
	    || test "x${have_curses_tparam}" != xyes
    then
	if test "x${have_termcap}" = xyes; then
	    with_termcap=termcap
	elif test "x${have_curses}" = xyes; then
	    with_termcap=curses
	fi
    dnl This is a little unusual (that we have either `tparm' or `tparam'
    dnl from `-lcurses', but not `tgetent'), but we should check anyway.
    elif test "x${have_curses}" = xyes; then
	with_termcap=curses
    elif test "x${have_termcap}" = xyes; then
	with_termcap=termcap
    fi

elif test "x${with_termcap}" != xno; then

    AC_DEFINE([USE_TERMCAP], [1], [Define if termcap should be used.])
    AC_CHECK_HEADERS([ncurses.h curses.h term.h termcap.h])
    lib=${with_termcap}
    AC_CHECK_LIB([${lib}], [tgetent], [eval have_${lib}=yes])
    AC_CHECK_LIB([${lib}], [tparm], [eval have_${lib}_tparm=yes])
    AC_CHECK_LIB([${lib}], [tparam], [eval have_${lib}_tparam=yes])

    if eval test "\"x\${have_${lib}}\"" != xyes; then
	AC_MSG_ERROR([No tgetent in termcap library: ${with_termcap}])
    fi

fi

case "${with_termcap}" in
yes)
    AC_MSG_WARN([No termcap library found; will emulate it])
    OPTIONAL_BASES="${OPTIONAL_BASES} termcap tparam tterm"
    ;;
no)
    AC_MSG_NOTICE([Termcap disabled.])
    ;;
*)
    LIBS="-l${with_termcap} ${LIBS}"
    eval have_tparam=\$have_${with_termcap}_tparam
    if test "x${have_tparam}" != xyes; then
	eval have_tparm=\$have_${with_termcap}_tparm
	if test "x${have_tparm}" = xyes; then
	    AC_MSG_WARN([No tparam found; will emulate it from terminfo tparm])
	    OPTIONAL_BASES="${OPTIONAL_BASES} terminfo tterm"
	else
	    AC_MSG_WARN([No tparam found; will emulate it])
	    OPTIONAL_BASES="${OPTIONAL_BASES} tparam tterm"
	fi
    fi
    ;;
esac

dnl The OpenSSL crypto library provides support for blowfish and MD5.
if test "${with_openssl}" != no; then
    if test "${with_openssl}" != yes; then
	CPPFLAGS="${CPPFLAGS} -I${with_openssl}/include"
	LDFLAGS="${LDFLAGS} -L${with_openssl}/lib"
    fi
    FOUND=
    AC_CHECK_HEADERS([openssl/blowfish.h openssl/md5.h],
	[
	AC_CHECK_LIB([crypto], [BF_set_key],
	    [
	    AC_DEFINE([HAVE_LIBCRYPTO], [1],
		[Define to 1 if you have the `crypto' library (-lcrypto).])
	    FOUND=yes
	    ])
	])
    if test -n "${FOUND}"; then
	MODULE_LIBS="-lcrypto ${MODULE_LIBS}"
	MODULE_BASES="${MODULE_BASES} prbfish"
	PRBFISH_LIBS="-lcrypto"
    fi
fi

dnl These libraries might not be installed, so take care generating
dnl file dependencies using "makegen/makegen.scm" when called on
dnl "makegen/files-optional.scm".  To wit, "prmcrypt.c" must
dnl conditionalize its dependencies on <mcrypt.h>, respectively, to
dnl avoid warnings in "Makefile.deps" and its embeds.

dnl The mcrypt library provides blowfish, but its CFB mode is 8 bit.
dnl We have been using 64-bit CFB, so this isn't really compatible.
dnl But mcrypt provides many ciphers and can be loaded in addition.
if test "${with_mcrypt}" != no; then
    if test "${with_mcrypt}" != yes; then
	CPPFLAGS="${CPPFLAGS} -I${with_mcrypt}/include"
	LDFLAGS="${LDFLAGS} -L${with_mcrypt}/lib"
    fi
    AC_CHECK_HEADER([mcrypt.h],
	[
	AC_DEFINE([HAVE_MCRYPT_H], [1],
	    [Define to 1 if you have the <mcrypt.h> header file.])
	AC_CHECK_LIB([mcrypt], [mcrypt_generic_init],
	    [
	    AC_DEFINE([HAVE_LIBMCRYPT], [1],
		[Define to 1 if you have the `mcrypt' library (-lmcrypt).])
	    MODULE_LIBS="-lmcrypt ${MODULE_LIBS}"
	    MODULE_BASES="${MODULE_BASES} prmcrypt"
	    ])
	])
fi

dnl gdbm support
if test "${with_gdbm}" != no; then
    if test "${with_gdbm}" != yes; then
	CPPFLAGS="${CPPFLAGS} -I${with_gdbm}/include"
	LDFLAGS="${LDFLAGS} -L${with_gdbm}/lib"
    fi
    AC_CHECK_HEADER([gdbm.h],
	[
	AC_DEFINE([HAVE_GDBM_H], [1],
	    [Define to 1 if you have the <gdbm.h> header file.])
	AC_CHECK_LIB([gdbm], [gdbm_open],
	    [
	    AC_DEFINE([HAVE_LIBGDBM], [1],
		[Define to 1 if you have the `gdbm' library (-lgdbm).])
	    MODULE_LIBS="-lgdbm ${MODULE_LIBS}"
	    MODULE_BASES="${MODULE_BASES} prgdbm"
	    ])
	])
fi

dnl DB v4 support
if test "${with_db_4}" != no; then
    if test "${with_db_4}" != yes; then
	CPPFLAGS="${CPPFLAGS} -I${with_db_4}/include"
	LDFLAGS="${LDFLAGS} -L${with_db_4}/lib"
    fi
    AC_CHECK_HEADER([db.h],
	[
	AC_DEFINE([HAVE_DB_H], [1],
	    [Define to 1 if you have the <db.h> header file.])
	AC_MSG_CHECKING([for db_create in -ldb-4])
	save_LIBS=${LIBS}
	LIBS="${LIBS} -ldb-4"
	AC_LINK_IFELSE(
	    [AC_LANG_PROGRAM(
		[[#include <db.h>]],
		[[db_create (0, 0, 0)]])],
	    [
	    AC_MSG_RESULT([yes])
	    AC_DEFINE([HAVE_LIBDB_4], [1],
		[Define to 1 if you have the `db-4' library (-ldb-4).])
	    MODULE_LIBS="-ldb-4 ${MODULE_LIBS}"
	    MODULE_BASES="${MODULE_BASES} prdb4"
	    ],
	    [
	    AC_MSG_RESULT([no])
	    ])
	LIBS=${save_LIBS}
	])
fi

dnl PostgreSQL support
if test "${with_libpq}" != no; then
    if test "${with_libpq}" != yes; then
	libpq_inc=${with_libpq}/include
	libpq_lib=${with_libpq}/lib
    else
	AC_PATH_PROG([PG_CONFIG], [pg_config])
	if test "x${PG_CONFIG}" != x; then
	    libpq_inc=`${PG_CONFIG} --includedir 2>/dev/null`
	    libpq_lib=`${PG_CONFIG} --libdir 2>/dev/null`
	else
	    if test -d /usr/include/postgresql; then
	       libpq_inc=/usr/include/postgresql
	    else
	       libpq_inc=/usr/include
	    fi
	    libpq_lib=/usr/lib
	fi
    fi
    if test "x${libpq_inc}" != x; then
	if test "${libpq_inc}" != /usr/include; then
	    CPPFLAGS="${CPPFLAGS} -I${libpq_inc}"
	fi
    fi
    if test "x${libpq_lib}" != x; then
	if test "${libpq_lib}" != /usr/lib; then
	    LDFLAGS="${LDFLAGS} -L${libpq_lib}"
	fi
    fi
    AC_CHECK_HEADER([libpq-fe.h],
	[
	AC_DEFINE([HAVE_LIBPQ_FE_H], [1],
	    [Define to 1 if you have the <libpq-fe.h> header file.])
	AC_CHECK_LIB([pq], [PQconnectdb],
	    [
	    AC_DEFINE([HAVE_LIBPQ], [1],
		[Define to 1 if you have the `pq' library (-lpq).])
	    MODULE_LIBS="-lpq ${MODULE_LIBS}"
	    MODULE_BASES="${MODULE_BASES} prpgsql"
	    ])
	])
fi

dnl Add support for X if present.
if test "${no_x}" != yes; then
    if test "x${x_includes}" != x; then
	FOO=-I`echo ${x_includes} | sed -e "s/:/ -I/g"`
	CPPFLAGS="${CPPFLAGS} ${FOO}"
    fi
    if test "x${x_libraries}" != x; then
	FOO=-L`echo ${x_libraries} | sed -e "s/:/ -L/g"`
	LDFLAGS="${LDFLAGS} ${FOO}"
    fi
    MODULE_LIBS="-lX11 ${MODULE_LIBS}"
    MODULE_BASES="${MODULE_BASES} prx11"
    MODULE_AUX_BASES="${MODULE_AUX_BASES} x11base x11color x11graph x11term"
fi

dnl Check for dynamic loader support.
AC_CHECK_FUNC([dlopen],
    [],
    [
    AC_CHECK_LIB([dl], [dlopen],
	[
	AC_DEFINE([HAVE_LIBDL], [1],
	    [Define to 1 if you have the `dl' library (-ldl).])
	LIBS="-ldl ${LIBS}"
	],
	[
	if test ${mit_scheme_native_code} = c; then
	    AC_MSG_ERROR(
		[--enable-native-code=c requires dynamic loader support])
	fi
	])
    ])
OPTIONAL_BASES="${OPTIONAL_BASES} pruxdld pruxffi"
AC_DEFINE([UX_DLD_ENABLED], [1],
    [Define to 1 if unix dynamic loading support is enabled.])

if test ${enable_valgrind_mode} != no; then
    SCHEME_DEFS="${SCHEME_DEFS} -DVALGRIND_MODE"
    M4_FLAGS="${M4_FLAGS} -P VALGRIND_MODE,1"
fi

OPTIONAL_BASES="${OPTIONAL_BASES} cmpint cmpintmd comutl"

case ${mit_scheme_native_code} in
none)
    ;;
c)
    AC_CONFIG_LINKS([cmpauxmd.c:cmpauxmd/c.c])
    AC_CONFIG_FILES([liarc-cc], [chmod +x liarc-cc])
    AC_CONFIG_FILES([liarc-ld], [chmod +x liarc-ld])
    OPTIONAL_BASES="${OPTIONAL_BASES} cmpauxmd unstackify compinit"
    LIARC_VARS=liarc-vars
    LIARC_RULES=liarc-rules
    AUX_PROGRAMS="gen-nonce extract-liarc-decls"
    INSTALL_INCLUDE=install-include
    ;;
svm1)
    OPTIONAL_BASES="${OPTIONAL_BASES} svm1-interp"
    ;;
*)
    AC_CHECK_PROG([M4], [m4], [m4])
    if test "x${M4}" = x; then
	AC_MSG_ERROR([m4 not found])
    fi
    AC_CONFIG_LINKS([cmpauxmd.m4:cmpauxmd/${mit_scheme_native_code}.m4])
    OPTIONAL_SOURCES="${OPTIONAL_SOURCES} cmpauxmd.m4"
    OPTIONAL_OBJECTS="${OPTIONAL_OBJECTS} cmpauxmd.o"
    ;;
esac

AC_CONFIG_LINKS([
    cmpintmd.h:cmpintmd/${mit_scheme_native_code}.h
    cmpintmd.c:cmpintmd/${mit_scheme_native_code}.c
    cmpintmd-config.h:cmpintmd/${mit_scheme_native_code}-config.h
    ])

for base in ${OPTIONAL_BASES}; do
    OPTIONAL_SOURCES="${OPTIONAL_SOURCES} ${base}.c"
    OPTIONAL_OBJECTS="${OPTIONAL_OBJECTS} ${base}.o"
done

if test "x${MODULE_BASES}" != x; then
    MODULE_RULES=config-rules.module
    rm -f ${MODULE_RULES}
    for BASE in ${MODULE_BASES}; do
	MODULE_TARGETS="${MODULE_TARGETS} ${BASE}.so"
	MODULE_AUX_BASES="${MODULE_AUX_BASES} ${BASE}"
    done
    for BASE in ${MODULE_AUX_BASES}; do
	echo >> ${MODULE_RULES}
	echo ${BASE}.o: ${BASE}.c >> ${MODULE_RULES}
	echo "	" '$(COMPILE_MODULE)' -c '$*.c' >> ${MODULE_RULES}
    done
fi
if test "x${MODULE_TARGETS}" != x; then
    if test ! -e ../lib/lib; then mkdir ../lib/lib; fi
    for BASE in ${MODULE_TARGETS}; do
	ln -sf ../../microcode/${BASE} ../lib/lib/${BASE}
    done
fi

AC_SUBST([AS_FLAGS])
AC_SUBST([GC_HEAD_FILES])
AC_SUBST([M4_FLAGS])
AC_SUBST([M4])
AC_SUBST([OPTIONAL_SOURCES])
AC_SUBST([OPTIONAL_OBJECTS])
AC_SUBST([PRBFISH_LIBS])
AC_SUBST([SCHEME_DEFS])
AC_SUBST([SCHEME_LDFLAGS])
AC_SUBST([MODULE_TARGETS])
AC_SUBST_FILE([MODULE_RULES])
AC_SUBST([MODULE_CFLAGS])
AC_SUBST([MODULE_LDFLAGS])
AC_SUBST([MODULE_LOADER])
AC_SUBST_FILE([LIARC_VARS])
AC_SUBST_FILE([LIARC_RULES])
AC_SUBST([AUX_PROGRAMS])
AC_SUBST([AUX_DATA])
AC_SUBST([AUXDIR_NAME])
AC_SUBST([EXE_NAME])
AC_SUBST([INSTALL_INCLUDE])
AC_SUBST([CCLD])

AC_CONFIG_FILES([Makefile])
AC_OUTPUT

# Make custom compilation program for "makegen.scm".
rm -f makegen-cc
echo "#!/bin/sh" > makegen-cc
echo exec gcc -MM -MG -DMIT_SCHEME ${CPPFLAGS} '"${1}"' >> makegen-cc
chmod +x makegen-cc

if test ${MODULE_RULES} != /dev/null; then
    rm -f ${MODULE_RULES}
fi
