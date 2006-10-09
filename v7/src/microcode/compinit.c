/* -*-C-*-

$Id: compinit.c,v 1.6.2.3 2006/10/09 07:02:04 cph Exp $

Copyright 1993,2002,2006 Massachusetts Institute of Technology

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

#define LIARC_IN_MICROCODE
#include "liarc.h"

#undef DECLARE_COMPILED_CODE
#undef DECLARE_COMPILED_DATA
#undef DECLARE_COMPILED_DATA_NS
#undef DECLARE_DATA_OBJECT

#define DECLARE_COMPILED_CODE(name, nentries, decl_code, code)		\
extern int decl_code (void);						\
extern SCHEME_OBJECT * code (SCHEME_OBJECT *, entry_count_t);

#define DECLARE_COMPILED_DATA(name, decl_data, data)			\
extern int decl_data (void);						\
extern SCHEME_OBJECT * data (entry_count_t);

#define DECLARE_COMPILED_DATA_NS(name, data)				\
extern SCHEME_OBJECT * data (entry_count_t);

#define DECLARE_DATA_OBJECT(name, data)					\
extern SCHEME_OBJECT data (void);

#include "compinit.h"

#undef DECLARE_COMPILED_CODE
#undef DECLARE_COMPILED_DATA
#undef DECLARE_COMPILED_DATA_NS
#undef DECLARE_DATA_OBJECT

#define DECLARE_COMPILED_CODE(name, nentries, decl_code, code)		\
  result = (declare_compiled_code (name, nentries, decl_code, code));	\
  if (result != 0)							\
    return (result);

#define DECLARE_COMPILED_DATA(name, decl_data, data)			\
  result = (declare_compiled_data (name, decl_data, data));		\
  if (result != 0)							\
    return (result);

#define DECLARE_COMPILED_DATA_NS(name, data)				\
  result = (declare_compiled_data_ns (name, data));			\
  if (result != 0)							\
    return (result);

#define DECLARE_DATA_OBJECT(name, data)					\
  result = (declare_data_object (name, data));				\
  if (result != 0)							\
    return (result);

int
initialize_compiled_code_blocks (void)
{
  int result;
#include "compinit.h"
  return (false);
}
