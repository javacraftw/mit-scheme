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

/* $Header: /Users/cph/tmp/foo/mit-scheme/mit-scheme/v7/src/microcode/prim.c,v 9.25 1987/04/16 23:20:46 jinx Rel $
 *
 * The leftovers ... primitives that don't seem to belong elsewhere.
 *
 */

#include "scheme.h"
#include "primitive.h"

/* Random predicates: */

/* (NULL? OBJECT)
   Returns #!TRUE if OBJECT is NIL.  Otherwise returns NIL.  This is
   the primitive known as NOT, NIL?, and NULL? in Scheme.
*/
Built_In_Primitive(Prim_Null, 1, "NULL?", 0xC)
{
  Primitive_1_Arg();

  Touch_In_Primitive(Arg1, Arg1);
  return (Arg1 == NIL) ? TRUTH : NIL;
}

/* (EQ? OBJECT-1 OBJECT-2)
   Returns #!TRUE if the two objects have the same type code
   and datum.  Returns NIL otherwise.
*/
Built_In_Primitive(Prim_Eq, 2, "EQ?", 0xD)
{
  Primitive_2_Args();

  if (Arg1 == Arg2)
    return TRUTH;
  Touch_In_Primitive(Arg1, Arg1);
  Touch_In_Primitive(Arg2, Arg2);
  return ((Arg1 == Arg2) ? TRUTH : NIL);
}

/* Pointer manipulation */

/* (MAKE-NON-POINTER-OBJECT NUMBER)
   Returns an (extended) fixnum with the same value as NUMBER.  In
   the CScheme interpreter this is basically a no-op, since fixnums
   already store 24 bits.
*/
Built_In_Primitive(Prim_Make_Non_Pointer, 1,
		   "MAKE-NON-POINTER-OBJECT", 0xB1)
{
  Primitive_1_Arg();

  Arg_1_Type(TC_FIXNUM);
  return Arg1;
}

/* (PRIMITIVE-DATUM OBJECT)
   Returns the datum part of OBJECT.
*/
Built_In_Primitive(Prim_Primitive_Datum, 1, "PRIMITIVE-DATUM", 0xB0)
{
  Primitive_1_Arg();

  return Make_New_Pointer(TC_ADDRESS, Arg1);
}

/* (PRIMITIVE-TYPE OBJECT)
   Returns the type code of OBJECT as a number.
   Note: THE OBJECT IS TOUCHED FIRST.
*/
Built_In_Primitive(Prim_Prim_Type, 1, "PRIMITIVE-TYPE", 0x10)
{
  Primitive_1_Arg();

  Touch_In_Primitive(Arg1, Arg1);
  return Make_Unsigned_Fixnum(Safe_Type_Code(Arg1));
}

/* (PRIMITIVE-GC-TYPE OBJECT)
   Returns a fixnum indicating the GC type of the object.  The object
   is NOT touched first.
*/

Built_In_Primitive(Prim_Gc_Type, 1, "PRIMITIVE-GC-TYPE", 0xBC)
{
  Primitive_1_Arg(); 

  return Make_Non_Pointer(TC_FIXNUM, GC_Type(Arg1));
}

/* (PRIMITIVE-TYPE? TYPE-CODE OBJECT)
   Return #!TRUE if the type code of OBJECT is TYPE-CODE, NIL
   otherwise.
   Note: THE OBJECT IS TOUCHED FIRST.
*/
Built_In_Primitive(Prim_Prim_Type_QM, 2, "PRIMITIVE-TYPE?", 0xF)
{
  Primitive_2_Args();

  Arg_1_Type(TC_FIXNUM);
  Touch_In_Primitive(Arg2, Arg2);
  if (Type_Code(Arg2) == Get_Integer(Arg1))
    return TRUTH;
  else
    return NIL;
}

/* (PRIMITIVE-SET-TYPE TYPE-CODE OBJECT)
   Returns a new object with TYPE-CODE and the datum part of
   OBJECT.
   Note : IT TOUCHES ITS SECOND ARGUMENT (for completeness sake).
   This is a "gc-safe" (paranoid) operation.
*/

Built_In_Primitive(Prim_Primitive_Set_Type, 2, "PRIMITIVE-SET-TYPE", 0x11)
{
  long New_GC_Type, New_Type;
  Primitive_2_Args();

  Arg_1_Type(TC_FIXNUM);
  Range_Check(New_Type, Arg1, 0, MAX_SAFE_TYPE, ERR_ARG_1_BAD_RANGE);
  Touch_In_Primitive(Arg2, Arg2);
  New_GC_Type = GC_Type_Code(New_Type);
  if ((GC_Type(Arg2) == New_GC_Type) ||
      (New_GC_Type == GC_Non_Pointer))
    return Make_New_Pointer(New_Type, Arg2);
  else
    Primitive_Error(ERR_ARG_1_BAD_RANGE);
  /*NOTREACHED*/
}

/* Subprimitives.  
   Many primitives can be built out of these, and eventually should be.
   These are extremely unsafe, since there is no consistency checking.
   In particular, they are not gc-safe: You can screw yourself royally
   by using them.  
*/

/* (&MAKE-OBJECT TYPE-CODE OBJECT)
   Makes a Scheme object whose datum field is the datum field of
   OBJECT, and whose type code is TYPE-CODE.  It does not touch.
*/

Built_In_Primitive(Prim_And_Make_Object, 2, "&MAKE-OBJECT", 0x8D)
{
  long New_Type;
  Primitive_2_Args();

  Arg_1_Type(TC_FIXNUM);
  Range_Check(New_Type, Arg1, 0, MAX_SAFE_TYPE, ERR_ARG_1_BAD_RANGE);
  return Make_New_Pointer(New_Type, Arg2);
}

/* (SYSTEM-MEMORY-REF OBJECT INDEX)
   Fetches the index'ed slot in object.
   Performs no type checking in object.
*/

Built_In_Primitive(Prim_System_Memory_Ref, 2, "SYSTEM-MEMORY-REF", 0x195)
{
  Primitive_2_Args();

  Arg_2_Type(TC_FIXNUM);
  return Vector_Ref(Arg1, Get_Integer(Arg2));
}

/* (SYSTEM-MEMORY-SET! OBJECT INDEX VALUE)
   Stores value in the index'ed slot in object.
   Performs no type checking in object.
*/

Built_In_Primitive(Prim_System_Memory_Set, 3, "SYSTEM-MEMORY-SET!", 0x196)
{
  long index;
  Primitive_3_Args();

  Arg_2_Type(TC_FIXNUM);
  index = Get_Integer(Arg2);
  return Swap_Pointers(Nth_Vector_Loc(Arg1, index), Arg3);
}

/* Playing with the danger bit */

/* (OBJECT-DANGEROUS? OBJECT)
   Returns #!TRUE if OBJECT has the danger bit set, NIL otherwise.
*/
Built_In_Primitive(Prim_Dangerous_QM, 1, "OBJECT-DANGEROUS?", 0x49)
{
  Primitive_1_Arg();

  return (Dangerous(Arg1)) ? TRUTH : NIL;
}

/* (MAKE-OBJECT-DANGEROUS OBJECT)
   Returns OBJECT, but with the danger bit set.
*/
Built_In_Primitive(Prim_Dangerize, 1, "MAKE-OBJECT-DANGEROUS", 0x48)
{
  Primitive_1_Arg();

  return Set_Danger_Bit(Arg1);
}

/* (MAKE-OBJECT-SAFE OBJECT)
   Returns OBJECT with the danger bit cleared.  This does not
   side-effect the object, it merely returns a new (non-dangerous)
   pointer to the same item.
*/
Built_In_Primitive(Prim_Undangerize, 1, "MAKE-OBJECT-SAFE", 0x47)
{
  Primitive_1_Arg();

  return Clear_Danger_Bit(Arg1);
}

/* Cells */

/* (MAKE-CELL CONTENTS)
   Creates a cell with contents CONTENTS.
*/
Built_In_Primitive(Prim_Make_Cell, 1, "MAKE-CELL", 0x61)
{
  Primitive_1_Arg();

  Primitive_GC_If_Needed(1);
  *Free++ = Arg1;
  return Make_Pointer(TC_CELL, Free-1);
}

/* (CELL-CONTENTS CELL)
   Returns the contents of the cell CELL.
*/
Built_In_Primitive(Prim_Cell_Contents, 1, "CELL-CONTENTS", 0x62)
{
  Primitive_1_Arg();

  Arg_1_Type(TC_CELL);
  return(Vector_Ref(Arg1, CELL_CONTENTS));
}

/* (CELL? OBJECT)
   Returns #!TRUE if OBJECT has type-code CELL, otherwise returns
   NIL.
*/
Built_In_Primitive(Prim_Cell, 1, "CELL?", 0x63)
{
  Primitive_1_Arg();

  Touch_In_Primitive(Arg1,Arg1);
  return (Type_Code(Arg1 == TC_CELL)) ? TRUTH : NIL;
}

/* (SET-CELL-CONTENTS! CELL VALUE)
   Stores VALUE as contents of CELL.  Returns the previous contents of CELL.
*/
Built_In_Primitive(Prim_Set_Cell_Contents, 2, "SET-CELL-CONTENTS!", 0x8C)
{
  Primitive_2_Args();

  Arg_1_Type(TC_CELL);
  Side_Effect_Impurify(Arg1, Arg2);
  return Swap_Pointers(Nth_Vector_Loc(Arg1, CELL_CONTENTS), Arg2);
}
