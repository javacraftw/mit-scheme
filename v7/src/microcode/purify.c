/* -*-C-*-

Copyright (c) 1987 Massachusetts Institute of Technology

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

/* $Header: /Users/cph/tmp/foo/mit-scheme/mit-scheme/v7/src/microcode/purify.c,v 9.27 1987/06/02 00:17:36 jinx Exp $
 *
 * This file contains the code that copies objects into pure
 * and constant space.
 *
 */

#include "scheme.h"
#include "primitive.h"
#include "gccode.h"
#include "zones.h"

/* Imports */

extern void GCFlip(), GC();
extern Pointer *GCLoop();

/* This is a copy of GCLoop, with GC_Mode handling added, and
   debugging printout removed.
*/

#define Purify_Pointer(Code)					\
Old = Get_Pointer(Temp);					\
if ((GC_Mode == CONSTANT_COPY) &&				\
    (Old > Low_Constant))					\
  continue;							\
Code

#define Setup_Pointer_for_Purify(Extra_Code)			\
Purify_Pointer(Setup_Pointer(false, Extra_Code))

#define Indirect_BH(In_GC)					\
if (Type_Code(*Old) == TC_BROKEN_HEART) continue;	  

#define Transport_Vector_Indirect()				\
Real_Transport_Vector();					\
*Get_Pointer(Temp) = New_Address

Pointer *
PurifyLoop(Scan, To_Pointer, GC_Mode)
     fast Pointer *Scan;
     Pointer **To_Pointer;
     int GC_Mode;
{
  fast Pointer *To, *Old, Temp, *Low_Constant, New_Address;

  To = *To_Pointer;
  Low_Constant = Constant_Space;
  for ( ; Scan != To; Scan++)
  {
    Temp = *Scan;
    Switch_by_GC_Type(Temp)
    {
      case TC_BROKEN_HEART:
        if (Scan == (Get_Pointer(Temp)))
	{
	  *To_Pointer = To;
	  return Scan;
	}
        fprintf(stderr, "Purify: Broken heart in scan.\n");
	Microcode_Termination(TERM_BROKEN_HEART);

      case TC_MANIFEST_NM_VECTOR:
      case TC_MANIFEST_SPECIAL_NM_VECTOR:
	Scan += Get_Integer(Temp);
	break;

      case_Non_Pointer:
	break;

      case_compiled_entry_point:
	if (GC_Mode == PURE_COPY)
	  break;
	Purify_Pointer(Setup_Internal(false,
				      Transport_Compiled(),
				      Compiled_BH(false, continue)));

      case_Cell:
	Setup_Pointer_for_Purify(Transport_Cell());

/* PurifyLoop continues on the next page */

/* PurifyLoop, continued */

      /*
	Symbols, variables, and reference traps cannot be put into
	pure space.  The strings contained in the first two can, on the
	other hand.
       */

      case TC_REFERENCE_TRAP:
	if ((Datum(Temp) <= TRAP_MAX_IMMEDIATE) || (GC_Mode == PURE_COPY))
	{
	  /* It is a non pointer. */
	  break;
	}
	goto purify_pair;

      case TC_INTERNED_SYMBOL:
      case TC_UNINTERNED_SYMBOL:
	if (GC_Mode == PURE_COPY)
        {
	  Temp = Vector_Ref(Temp, SYMBOL_NAME);
	  Purify_Pointer(Setup_Internal(false,
					Transport_Vector_Indirect(),
					Indirect_BH(false)));
	}
	/* Fall through */
      case_Fasdump_Pair:
      purify_pair:
	Setup_Pointer_for_Purify(Transport_Pair());

      case TC_WEAK_CONS:
	Setup_Pointer_for_Purify(Transport_Weak_Cons());

      case TC_VARIABLE:
      case_Triple:
	Setup_Pointer_for_Purify(Transport_Triple());

/* PurifyLoop continues on the next page */

/* PurifyLoop, continued */

      case_Quadruple:
	Setup_Pointer_for_Purify(Transport_Quadruple());

	/* No need to handle futures specially here, since PurifyLoop
	   is always invoked after running GCLoop, which will have
	   spliced all spliceable futures unless the GC itself of the
	   GC dameons spliced them, but this should not occur.
	 */

      case TC_FUTURE:
      case TC_ENVIRONMENT:
	if (GC_Mode == PURE_COPY)
	{
	  /* This should actually do an indirect pair transport of
	     the procedure, at least.
	   */
	  break;
	}
	/* Fall through */
#ifndef FLOATING_ALIGNMENT
      case TC_BIG_FLONUM:
	/* Fall through */
#endif
      case_Purify_Vector:
      purify_vector:
	Setup_Pointer_for_Purify(Transport_Vector());

#ifdef FLOATING_ALIGNMENT
      case TC_BIG_FLONUM:
        Setup_Pointer_for_Purify(Transport_Flonum());
#endif

      default:
	fprintf(stderr,
		"PurifyLoop: Bad type code = 0x%02x\n",
		Type_Code(Temp));
	Invalid_Type_Code();
      } /* Switch_by_GC_Type */
  } /* For loop */
  *To_Pointer = To;
  return To;
} /* PurifyLoop */

/* Description of the algorithm for PURIFY:

   The algorithm is trickier than would first appear necessary.  This
   is because the size of the object being purified must be
   calculated.  The idea is that the entire object is copied into the
   new heap, and then a normal GC is done (the broken hearts created
   by the copy will, of course, now be used to relocate references to
   parts of the object).  If there is not enough room in constant
   space for the object, processing stops with a #!false return and
   the world flipped into the new heap.  Otherwise, the
   process is repeated, moving the object into constant space on the
   first pass and then doing a GC back into the original heap.

   Notice that in order to make a pure object, the copy process
   proceeds in two halves.  During the first half (which collects the
   pure part) Compiled Code, Environments, Symbols, and Variables
   (i.e.  things whose contents change) are NOT copied.  Then a header
   is put down indicating constant (not pure) area, and then they ARE
   copied.

   The constant area contains a contiguous set of blocks of the
   following format:

  >>Top of Memory (Stack above here)<<

                   . (direction of growth)
                   .  ^
                   . / \
                   .  |
                   .  |
        |----------------------|...
        | END   | Total Size M |   . Where END   = TC_FIXNUM
        |----------------------|    .      SNMH  = TC_MANIFEST_SPECIAL_...
        | SNMH  |      1       |    |      CONST = TC_TRUE
        |----------------------|    |      PURE  = TC_FALSE
        |                      |    |
        |                      |    |
        |    CONSTANT AREA     |    |
        |                      |    |
        |                      |     .
     ...|----------------------|      >  M
    .   | CONST | Pure Size N  |     .
   .    |----------------------|    |
   |    | SNMH  |      1       |    |
   |    |----------------------|    |
   |    |                      |    |
N <     |                      |    |
   |    |      PURE AREA       |    |
   |    |                      |    |
   .    |                      |    .
    .   |----------------------|   .
     ...| PURE  | Total Size M |...
        |----------------------|
        | SNMH  | Pure Size N  |
        |----------------------|

  >>Base of Memory (Heap below here)<<
*/

/* The result returned by Purify is a vector containing this data */

#define Purify_Vector_Header	0
#define Purify_Length		1
#define Purify_Really_Pure	2
#define Purify_N_Slots		2

Pointer Purify(Object, Purify_Object)
Pointer Object, Purify_Object;
{ long Length;
  Pointer *Heap_Start, *Result, Answer;

/* Pass 1 -- Copy object to new heap, then GC into that heap */

  GCFlip();
  Heap_Start = Free;
  *Free++ = Object;
  Result = GCLoop(Heap_Start, &Free);
  if (Free != Result)
  { fprintf(stderr, "\Purify: Pure Scan ended too early.\n");
    Microcode_Termination(TERM_BROKEN_HEART);
  }
  Length = (Free-Heap_Start)-1;		/* Length of object */
  GC();
  Free[Purify_Vector_Header] =
    Make_Non_Pointer(TC_MANIFEST_VECTOR, Purify_N_Slots);
  Free[Purify_Length] = Make_Unsigned_Fixnum(Length);
  Free[Purify_Really_Pure] = Purify_Object;
  Answer =  Make_Pointer(TC_VECTOR, Free);
  Free += Purify_N_Slots+1;
  return Answer;
}

Pointer Purify_Pass_2(Info)
Pointer Info;
{
  long Length;
  Boolean Purify_Object;
  Pointer *New_Object, Relocated_Object, *Result, Answer;
  long Pure_Length, Recomputed_Length;

  Length = Get_Integer(Fast_Vector_Ref(Info, Purify_Length));
  if (Fast_Vector_Ref(Info, Purify_Really_Pure) == NIL)
    Purify_Object =  false;
  else
    Purify_Object = true;
  Relocated_Object = *Heap_Bottom;
  if (!Test_Pure_Space_Top(Free_Constant+Length+6))
    return NIL;
  New_Object = Free_Constant;
  GCFlip();
  *Free_Constant++ = NIL;	/* Will hold pure space header */
  *Free_Constant++ = Relocated_Object;
  if (Purify_Object)
  {
    Result = PurifyLoop(New_Object+1, &Free_Constant, PURE_COPY);

    if (Free_Constant != Result)
    {
      fprintf(stderr, "\nPurify: Pure Copy ended too early.\n");
      Microcode_Termination(TERM_BROKEN_HEART);
    }
    Pure_Length = (Free_Constant-New_Object) + 1;
  }
  else
    Pure_Length = 3;
  *Free_Constant++ = Make_Non_Pointer(TC_MANIFEST_SPECIAL_NM_VECTOR, 1);
  *Free_Constant++ = Make_Non_Pointer(CONSTANT_PART, Pure_Length);
  if (Purify_Object)
  {
    Result = PurifyLoop(New_Object + 1, &Free_Constant, CONSTANT_COPY);
    if (Result != Free_Constant)
    {
      fprintf(stderr, "\nPurify: Pure Copy ended too early.\n");
      Microcode_Termination(TERM_BROKEN_HEART);
    }
  }

/* Purify_Pass_2 continues on the next page */

/* Purify_Pass_2, continued */

  else
  {
    Result = GCLoop(New_Object + 1, &Free_Constant);
    if (Result != Free_Constant)
    {
      fprintf(stderr, "\nPurify: Constant Copy ended too early.\n");
      Microcode_Termination(TERM_BROKEN_HEART);
    }
  }
  Recomputed_Length = (Free_Constant-New_Object)-4;
  *Free_Constant++ = Make_Non_Pointer(TC_MANIFEST_SPECIAL_NM_VECTOR, 1);
  *Free_Constant++ = Make_Non_Pointer(END_OF_BLOCK, Recomputed_Length+5);
  if (Length > Recomputed_Length)
  {
    fprintf(stderr, "\nPurify phase error %x, %x\n",
	    Length, Recomputed_Length);
    Microcode_Termination(TERM_EXIT);
  }
  *New_Object++ =
    Make_Non_Pointer(TC_MANIFEST_SPECIAL_NM_VECTOR, Pure_Length);
  *New_Object = Make_Non_Pointer(PURE_PART, Recomputed_Length+5);
  GC();
  Set_Pure_Top();
  return TRUTH;
}

/* (PRIMITIVE-PURIFY OBJECT PURE?)
   Copy an object from the heap into constant space.  This requires
   a spare heap, and is tricky to use -- it should only be used
   through the wrapper provided in the Scheme runtime system.

   To purify an object we just copy it into Pure Space in two
   parts with the appropriate headers and footers.  The actual
   copying is done by PurifyLoop above.

   Once the copy is complete we run a full GC which handles the
   broken hearts which now point into pure space.  On a 
   multiprocessor, this primitive uses the master-gc-loop and it
   should only be used as one would use master-gc-loop i.e. with
   everyone else halted.

   This primitive does not return normally.  It always escapes into
   the interpreter because some of its cached registers (eg. History)
   have changed.
*/

Built_In_Primitive(Prim_Primitive_Purify, 2, "PRIMITIVE-PURIFY", 0xB4)
{
  long Saved_Zone;
  Pointer Object, Lost_Objects, Purify_Result, Daemon;
  Primitive_2_Args();

  Save_Time_Zone(Zone_Purify);
  if ((Arg2 != TRUTH) && (Arg2 != NIL))
    Primitive_Error(ERR_ARG_2_WRONG_TYPE);

  /* Pass 1 (Purify, above) does a first copy.  Then any GC daemons
     run, and then Purify_Pass_2 is called to copy back.
  */

  Touch_In_Primitive(Arg1, Object);
  Purify_Result = Purify(Object, Arg2);
  Pop_Primitive_Frame(2);
  Daemon = Get_Fixed_Obj_Slot(GC_Daemon);
  if (Daemon == NIL)
  {
    Val = Purify_Pass_2(Purify_Result);
    PRIMITIVE_ABORT(PRIM_POP_RETURN);
    /*NOTREACHED*/
  }
  Store_Expression(Purify_Result);
  Store_Return(RC_PURIFY_GC_1);
 Will_Push(CONTINUATION_SIZE + STACK_ENV_EXTRA_SLOTS + 1);
  Save_Cont();
  Push(Daemon);
  Push(STACK_FRAME_HEADER);
 Pushed();
  PRIMITIVE_ABORT(PRIM_APPLY);
  /*NOTREACHED*/
}
