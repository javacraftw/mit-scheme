#| -*-Scheme-*-

$Id: ed-ffi.scm,v 1.44 1998/08/31 04:14:51 cph Exp $

Copyright (c) 1990-98 Massachusetts Institute of Technology

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
MIT in each case.

NOTE: Parts of this program (Edwin) were created by translation
from corresponding parts of GNU Emacs.  Users should be aware that
the GNU GENERAL PUBLIC LICENSE may apply to these parts.  A copy
of that license should have been included along with this file.
|#

(declare (usual-integrations))

;; This list must be kept in alphabetical order by filename.

(standard-scheme-find-file-initialization
 '#(("ansi"	(edwin screen console-screen)
		syntax-table/system-internal)
    ("argred"	(edwin command-argument)
		edwin-syntax-table)
    ("artdebug"	(edwin debugger)
		edwin-syntax-table)
    ("autold"	(edwin)
		edwin-syntax-table)
    ("autosv"	(edwin)
		edwin-syntax-table)
    ("basic"	(edwin)
		edwin-syntax-table)
    ("bios"	(edwin screen console-screen)
		syntax-table/system-internal)
    ("bufcom"	(edwin)
		edwin-syntax-table)
    ("buffer"	(edwin)
		edwin-syntax-table)
    ("buffrm"	(edwin window)
		class-syntax-table)
    ("bufinp"	(edwin buffer-input-port)
		syntax-table/system-internal)
    ("bufmnu"	(edwin buffer-menu)
		edwin-syntax-table)
    ("bufout"	(edwin buffer-output-port)
		syntax-table/system-internal)
    ("bufset"	(edwin)
		edwin-syntax-table)
    ("bufwfs"	(edwin window)
		class-syntax-table)
    ("bufwin"	(edwin window)
		class-syntax-table)
    ("bufwiu"	(edwin window)
		class-syntax-table)
    ("bufwmc"	(edwin window)
		class-syntax-table)
    ("c-mode"	(edwin)
		edwin-syntax-table)
    ("calias"	(edwin)
		edwin-syntax-table)
    ("cinden"	(edwin c-indentation)
		edwin-syntax-table)
    ("class"	(edwin)
		syntax-table/system-internal)
    ("clscon"	(edwin class-constructor)
		syntax-table/system-internal)
    ("clsmac"	(edwin class-macros)
		syntax-table/system-internal)
    ("comhst"	(edwin)
		edwin-syntax-table)
    ("comint"	(edwin)
		edwin-syntax-table)
    ("comatch"	(edwin)
		syntax-table/system-internal)
    ("comman"	(edwin)
		edwin-syntax-table)
    ("compile"	(edwin)
		edwin-syntax-table)
    ("comred"	(edwin command-reader)
		edwin-syntax-table)
    ("comtab"	(edwin comtab)
		edwin-syntax-table)
    ("comwin"	(edwin window combination)
		class-syntax-table)
    ("curren"	(edwin)
		edwin-syntax-table)
    ("dabbrev"	(edwin)
		edwin-syntax-table)
    ("debug"	(edwin debugger)
		edwin-syntax-table)
    ("debuge"	(edwin)
		edwin-syntax-table)
    ("dired"	(edwin dired)
		edwin-syntax-table)
    ("diros2"	(edwin dired)
		edwin-syntax-table)
    ("dirunx"	(edwin dired)
		edwin-syntax-table)
    ("dirw32"	(edwin dired)
		edwin-syntax-table)
    ("display"	(edwin display-type)
		syntax-table/system-internal)
    ("docstr"	(edwin)
		edwin-syntax-table)
    ("dos"	(edwin)
		edwin-syntax-table)
    ("doscom"	(edwin dosjob)
		edwin-syntax-table)
    ("dosfile"	(edwin)
		edwin-syntax-table)
    ("dosproc"	(edwin process)
		edwin-syntax-table)
    ("dosshell"	(edwin dosjob)
		edwin-syntax-table)
    ("editor"	(edwin)
		edwin-syntax-table)
    ("edtfrm"	(edwin window)
		class-syntax-table)
    ("edtstr"	(edwin)
		edwin-syntax-table)
    ("evlcom"	(edwin)
		edwin-syntax-table)
    ("eystep"	(edwin stepper)
		edwin-syntax-table)
    ("filcom"	(edwin)
		edwin-syntax-table)
    ("fileio"	(edwin)
		edwin-syntax-table)
    ("fill"	(edwin)
		edwin-syntax-table)
    ("grpops"	(edwin group-operations)
		syntax-table/system-internal)
    ("hlpcom"	(edwin)
		edwin-syntax-table)
    ("image"	(edwin)
		syntax-table/system-internal)
    ("info"	(edwin info)
		edwin-syntax-table)
    ("input"	(edwin keyboard)
		edwin-syntax-table)
    ("intmod"	(edwin inferior-repl)
		edwin-syntax-table)
    ("iserch"	(edwin incremental-search)
		edwin-syntax-table)
    ("javamode"	(edwin)
		edwin-syntax-table)
    ("key-w32"	(edwin win32-keys)
		edwin-syntax-table)
    ("key-x11"	(edwin x-keys)
		edwin-syntax-table)
    ("keymap"	(edwin command-summary)
		edwin-syntax-table)
    ("keyparse"	(edwin keyparser)
		edwin-syntax-table)
    ("kilcom"	(edwin)
		edwin-syntax-table)
    ("kmacro"	(edwin)
		edwin-syntax-table)
    ("lincom"	(edwin)
		edwin-syntax-table)
    ("linden"	(edwin lisp-indentation)
		edwin-syntax-table)
    ("loadef"	(edwin)
		edwin-syntax-table)
    ("lspcom"	(edwin)
		edwin-syntax-table)
    ("macros"	(edwin macros)
		syntax-table/system-internal)
    ("make"	()
		syntax-table/system-internal)
    ("malias"	(edwin mail-alias)
		edwin-syntax-table)
    ("manual"	(edwin)
		edwin-syntax-table)
    ("midas"	(edwin)
		edwin-syntax-table)
    ("modefs"	(edwin)
		edwin-syntax-table)
    ("modes"	(edwin)
		edwin-syntax-table)
    ("modlin"	(edwin modeline-string)
		edwin-syntax-table)
    ("modwin"	(edwin window)
		class-syntax-table)
    ("motcom"	(edwin)
		edwin-syntax-table)
    ("motion"	(edwin)
		syntax-table/system-internal)
    ("mousecom"	(edwin)
		edwin-syntax-table)
    ("nntp"	(edwin nntp)
		syntax-table/system-internal)
    ("notify"	(edwin)
		edwin-syntax-table)
    ("nvector"	(edwin)
		syntax-table/system-internal)
    ("occur"	(edwin occurrence)
		edwin-syntax-table)
    ("os2"	(edwin)
		edwin-syntax-table)
    ("os2com"	(edwin os2-commands)
		edwin-syntax-table)
    ("os2term"	(edwin screen os2-screen)
		syntax-table/system-internal)
    ("outline"	(edwin)
		edwin-syntax-table)
    ("pasmod"	(edwin)
		edwin-syntax-table)
    ("paths"	(edwin)
		syntax-table/system-internal)
    ("print"	(edwin)
		edwin-syntax-table)
    ("process"	(edwin process)
		edwin-syntax-table)
    ("prompt"	(edwin prompt)
		edwin-syntax-table)
    #|("rcs"	(edwin rcs)
	       edwin-syntax-table)|#
    ("rcsparse"	(edwin rcs-parse)
		syntax-table/system-internal)
    ("reccom"	(edwin rectangle)
		edwin-syntax-table)
    ("regcom"	(edwin register-command)
		edwin-syntax-table)
    ("regexp"	(edwin regular-expression)
		edwin-syntax-table)
    ("regops"	(edwin)
		syntax-table/system-internal)
    ("rename"	()
		syntax-table/system-internal)
    ("replaz"	(edwin)
		edwin-syntax-table)
    ("rgxcmp"	(edwin regular-expression-compiler)
		syntax-table/system-internal)
    ("ring"	(edwin)
		syntax-table/system-internal)
    ("rmail"	(edwin rmail)
		edwin-syntax-table)
    ("rmailsrt"	(edwin rmail)
		edwin-syntax-table)
    ("rmailsum"	(edwin rmail)
		edwin-syntax-table)
    ("schmod"	(edwin)
		edwin-syntax-table)
    ("scrcom"	(edwin)
		edwin-syntax-table)
    ("screen"	(edwin screen)
		edwin-syntax-table)
    ("search"	(edwin)
		syntax-table/system-internal)
    ("sendmail"	(edwin sendmail)
		edwin-syntax-table)
    ("sercom"	(edwin)
		edwin-syntax-table)
    ("shell"	(edwin)
		edwin-syntax-table)
    ("simple"	(edwin)
		syntax-table/system-internal)
    ("snr"	(edwin news-reader)
		edwin-syntax-table)
    ("sort"	(edwin)
		edwin-syntax-table)
    ("strpad"	(edwin)
		syntax-table/system-internal)
    ("strtab"	(edwin)
		syntax-table/system-internal)
    ("struct"	(edwin)
		edwin-syntax-table)
    ("syntax"	(edwin)
		edwin-syntax-table)
    ("tagutl"	(edwin tags)
		edwin-syntax-table)
    ("techinfo"	(edwin)
		edwin-syntax-table)
    ("telnet"	(edwin)
		edwin-syntax-table)
    ("termcap"	(edwin screen console-screen)
		syntax-table/system-internal)
    ("texcom"	(edwin)
		edwin-syntax-table)
    ("things"	(edwin)
		edwin-syntax-table)
    ("tparse"	(edwin)
		edwin-syntax-table)
    ("tterm"	(edwin screen console-screen)
		syntax-table/system-internal)
    ("tximod"	(edwin)
		edwin-syntax-table)
    ("txtprp"	(edwin text-properties)
		edwin-syntax-table)
    ("undo"	(edwin undo)
		edwin-syntax-table)
    ("unix"	(edwin)
		edwin-syntax-table)
    ("utils"	(edwin)
		syntax-table/system-internal)
    ("utlwin"	(edwin window)
		class-syntax-table)
    ("vc"	(edwin vc)
		edwin-syntax-table)
    ("verilog"	(edwin verilog)
		edwin-syntax-table)
    ("vhdl"	(edwin vhdl)
		edwin-syntax-table)
    ("webster"	(edwin)
		edwin-syntax-table)
    ("win32"	(edwin screen win32)
		edwin-syntax-table)
    ("win32com"	(edwin win-commands)
		edwin-syntax-table)
    ("wincom"	(edwin)
		edwin-syntax-table)
    ("window"	(edwin window)
		class-syntax-table)
    ("winout"	(edwin window-output-port)
		syntax-table/system-internal)
    ("winren"	(edwin)
		syntax-table/system-internal)
    ("xcom"	(edwin x-commands)
		edwin-syntax-table)
    ("xform"	(edwin class-macros transform-instance-variables)
		syntax-table/system-internal)
    ("xmodef"	(edwin)
		edwin-syntax-table)
    ("xterm"	(edwin screen x-screen)
		syntax-table/system-internal)))