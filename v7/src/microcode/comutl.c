/* -*-C-*-

$Id: comutl.c,v 1.33.2.4 2006/10/05 19:37:47 cph Exp $

Copyright 1987,1988,1989,1991,1993,1997 Massachusetts Institute of Technology
Copyright 2005,2006 Massachusetts Institute of Technology

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

/* Compiled Code Utilities */

#include "scheme.h"
#include "prims.h"

DEFINE_PRIMITIVE ("COMPILED-CODE-ADDRESS->BLOCK", Prim_comp_code_address_block,
		  1, 1, "(ADDRESS)\n\
Given a compiled-code entry ADDRESS, return its block.")
{
  PRIMITIVE_HEADER (1);
  CHECK_ARG (1, CC_ENTRY_P);
  PRIMITIVE_RETURN (cc_entry_to_block (ARG_REF (1)));
}

DEFINE_PRIMITIVE ("COMPILED-CODE-ADDRESS->OFFSET",
		  Prim_comp_code_address_offset, 1, 1, "(ADDRESS)\n\
Given a compiled-code entry ADDRESS, return its offset into its block.")
{
  PRIMITIVE_HEADER (1);
  CHECK_ARG (1, CC_ENTRY_P);
  PRIMITIVE_RETURN (ULONG_TO_FIXNUM (cc_entry_to_block_offset (ARG_REF (1))));
}

DEFINE_PRIMITIVE ("STACK-TOP-ADDRESS", Prim_stack_top_address, 0, 0, 0)
{
  PRIMITIVE_HEADER (0);
  PRIMITIVE_RETURN (ulong_to_integer (ADDRESS_TO_DATUM (STACK_BOTTOM)));
}

DEFINE_PRIMITIVE ("STACK-ADDRESS-OFFSET", Prim_stack_address_offset, 1, 1, 0)
{
  PRIMITIVE_HEADER (1);

  CHECK_ARG (1, CC_STACK_ENV_P);
  {
    SCHEME_OBJECT * address = (OBJECT_ADDRESS (ARG_REF (1)));
    if (!ADDRESS_IN_STACK_P (address))
      error_bad_range_arg (1);
    PRIMITIVE_RETURN
      (ulong_to_integer (SP_TO_N_PUSHED (address, stack_start, stack_end)));
  }
}

DEFINE_PRIMITIVE ("COMPILED-ENTRY-KIND", Prim_compiled_entry_kind, 1, 1, 0)
{
  PRIMITIVE_HEADER (1);
  CHECK_ARG (1, CC_ENTRY_P);
  {
    cc_entry_type_t cet;
    unsigned long kind = 4;
    unsigned long field1 = 0;
    long field2 = 0;

    if (!read_cc_entry_type ((&cet), (CC_ENTRY_ADDRESS (ARG_REF (1)))))
      switch (cet.marker)
	{
	case CET_PROCEDURE:
	  kind = 0;
	  field1 = (1 + (cet.args.for_procedure.n_required));
	  field2 = (field1 + (cet.args.for_procedure.n_optional));
	  if (cet.args.for_procedure.rest_p)
	    field2 = (- (field2 + 1));
	  break;

	case CET_CONTINUATION:
	  kind = 1;
	  field1 = 0;
	  field2 = (cet.args.for_continuation.offset);
	  break;

	case CET_EXPRESSION:
	  kind = 2;
	  field1 = 0;
	  field2 = 0;
	  break;

	case CET_INTERNAL_CONTINUATION:
	  kind = 1;
	  field1 = 1;
	  field2 = (-1);
	  break;

	case CET_INTERNAL_PROCEDURE:
	case CET_TRAMPOLINE:
	  kind = 3;
	  field1 = 1;
	  field2 = 0;
	  break;

	case CET_RETURN_TO_INTERPRETER:
	  kind = 1;
	  field1 = 2;
	  field2 = ((ARG_REF (1)) != return_to_interpreter);
	  break;

	case CET_CLOSURE:
	  kind = 3;
	  field1 = 0;
	  field2 = 0;
	  break;
	}
    PRIMITIVE_RETURN
      (hunk3_cons ((ULONG_TO_FIXNUM (kind)),
		   (ULONG_TO_FIXNUM (field1)),
		   (LONG_TO_FIXNUM (field2))));
  }
}

DEFINE_PRIMITIVE ("COERCE-TO-COMPILED-PROCEDURE", Prim_coerce_to_closure, 2, 2,
		  0)
{
  PRIMITIVE_HEADER (2);
  {
    SCHEME_OBJECT temp;
    long result
      = (coerce_to_compiled ((ARG_REF (1)), (arg_ulong_integer (2)), (&temp)));
    switch (result)
      {
      case PRIM_DONE:
	break;

      case PRIM_INTERRUPT:
	Primitive_GC (10);
	/*NOTREACHED*/
	break;

      default:
	error_bad_range_arg (2);
	/*NOTREACHED*/
	break;
      }
    PRIMITIVE_RETURN (temp);
  }
}

DEFINE_PRIMITIVE ("COMPILED-CLOSURE->ENTRY", Prim_cc_closure_to_entry, 1, 1,
  "Given a compiled closure, return the entry point which it invokes.")
{
  PRIMITIVE_HEADER (1);
  CHECK_ARG (1, CC_ENTRY_P);
  if (!cc_entry_closure_p (ARG_REF (1)))
    error_bad_range_arg (1);
  PRIMITIVE_RETURN (cc_closure_to_entry (ARG_REF (1)));
}

DEFINE_PRIMITIVE ("UTILITY-INDEX->NAME", Prim_utility_index_to_name, 1, 1, 0)
{
  PRIMITIVE_HEADER (1);
  {
    const char * name = (utility_index_to_name (arg_ulong_integer (1)));
    PRIMITIVE_RETURN ((name == 0) ? SHARP_F : (char_pointer_to_string (name)));
  }
}

DEFINE_PRIMITIVE ("BUILTIN-INDEX->NAME", Prim_builtin_index_to_name, 1, 1, 0)
{
  PRIMITIVE_HEADER (1);
  {
    const char * name = (builtin_index_to_name (arg_ulong_integer (1)));
    PRIMITIVE_RETURN ((name == 0) ? SHARP_F : (char_pointer_to_string (name)));
  }
}

#ifdef CC_IS_C
   extern SCHEME_OBJECT initialize_C_compiled_block (int, const char *);
#endif

DEFINE_PRIMITIVE ("INITIALIZE-C-COMPILED-BLOCK",
		  Prim_initialize_C_compiled_block, 1, 1,
  "Given the tag of a compiled object, return the object.")
{
  PRIMITIVE_HEADER (1);
#ifdef CC_IS_C
  PRIMITIVE_RETURN (initialize_C_compiled_block (1, (STRING_ARG (1))));
#else
  PRIMITIVE_RETURN (SHARP_F);
#endif
}

DEFINE_PRIMITIVE ("DECLARE-COMPILED-CODE-BLOCK",
		  Prim_declare_compiled_code_block, 1, 1,
  "Ensure cache coherence for a compiled-code block newly constructed.")
{
  PRIMITIVE_HEADER (1);
  {
    SCHEME_OBJECT new_cc_block = (ARG_REF (1));
    if (!CC_BLOCK_P (new_cc_block))
      error_wrong_type_arg (1);
    declare_compiled_code_block (new_cc_block);
    PRIMITIVE_RETURN (SHARP_T);
  }
}

DEFINE_PRIMITIVE ("BKPT/INSTALL", Prim_install_bkpt, 1, 1,
		  "(compiled-entry-object)\n\
Install a breakpoint trap in a compiled code object.\n\
Returns false or a handled needed by REMOVE-BKPT and ONE-STEP-PROCEED.")
{
  PRIMITIVE_HEADER (1);
  CHECK_ARG (1, CC_ENTRY_P);

  {
    SCHEME_OBJECT * entry = (OBJECT_ADDRESS (ARG_REF (1)));
    SCHEME_OBJECT * block;

    if (bkpt_p ((void *) entry))
      error_bad_range_arg (1);

    block = (cc_entry_to_block_address (ARG_REF (1)));
    if ((OBJECT_TYPE (block[0])) == TC_MANIFEST_CLOSURE)
      PRIMITIVE_RETURN (bkpt_closure_install ((void *) entry));
    else
      PRIMITIVE_RETURN (bkpt_install ((void *) entry));
  }
}

DEFINE_PRIMITIVE ("BKPT/REMOVE", Prim_remove_bkpt, 2, 2,
		  "(compiled-entry-object handle)\n\
Remove a breakpoint trap installed by INSTALL-BKPT.")
{
  PRIMITIVE_HEADER (2);
  CHECK_ARG (1, CC_ENTRY_P);
  CHECK_ARG (2, NON_MARKED_VECTOR_P);

  {
    SCHEME_OBJECT * entry = (OBJECT_ADDRESS (ARG_REF (1)));
    SCHEME_OBJECT handle = (ARG_REF (2));

    if (! (bkpt_p ((void *) entry)))
      error_bad_range_arg (1);
    bkpt_remove (((void *) entry), handle);
    PRIMITIVE_RETURN (UNSPECIFIC);
  }
}

DEFINE_PRIMITIVE ("BKPT?", Prim_bkpt_p, 1, 1,
		  "(compiled-entry-object)\n\
True if there is a breakpoint trap in compiled-entry-object.")
{
  PRIMITIVE_HEADER (1);
  CHECK_ARG (1, CC_ENTRY_P);

  PRIMITIVE_RETURN (BOOLEAN_TO_OBJECT
		    (bkpt_p ((void *) (OBJECT_ADDRESS (ARG_REF (1))))));
}

DEFINE_PRIMITIVE ("BKPT/PROCEED", Prim_bkpt_proceed, 3, 3,
		  "(compiled-entry-object handle state)\n\
Proceed the computation from the current breakpoint.")
{
  PRIMITIVE_HEADER (3);
  CHECK_ARG (1, CC_ENTRY_P);
  CHECK_ARG (2, NON_MARKED_VECTOR_P);

  PRIMITIVE_RETURN (bkpt_proceed (((void *) (OBJECT_ADDRESS (ARG_REF (1)))),
				  (ARG_REF (2)),
				  (ARG_REF (3))));
}
