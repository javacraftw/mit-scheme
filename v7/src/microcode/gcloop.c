/* -*-C-*-

$Id: gcloop.c,v 9.51.2.8 2006/08/30 03:00:03 cph Exp $

Copyright 1986,1987,1988,1989,1990,1991 Massachusetts Institute of Technology
Copyright 1992,1993,2000,2001,2005,2006 Massachusetts Institute of Technology

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

/* Inner loop of garbage collector.  */

#include "scheme.h"
#include "gccode.h"

#ifndef READ_REFERENCE_OBJECT
#  define READ_REFERENCE_OBJECT(addr)					\
     (MAKE_POINTER_OBJECT (TC_HUNK3, (* ((SCHEME_OBJECT **) (addr)))))
#  define WRITE_REFERENCE_OBJECT(ref, addr)				\
     ((* ((SCHEME_OBJECT **) (addr))) = (OBJECT_ADDRESS (ref)))
#endif

static gc_tuple_handler_t gc_tuple;
static gc_vector_handler_t gc_vector;
static gc_object_handler_t gc_cc_entry;
static gc_object_handler_t gc_weak_pair;

static SCHEME_OBJECT * weak_chain;

static gc_table_t * gc_table (void);

#ifdef ENABLE_GC_DEBUGGING_TOOLS
#  ifndef GC_SCAN_HISTORY_SIZE
#    define GC_SCAN_HISTORY_SIZE 1024
#  endif
#  define INITIALIZE_GC_HISTORY initialize_gc_history
#  define HANDLE_GC_TRAP handle_gc_trap
#  define DEBUG_TRANSPORT_ONE_WORD debug_transport_one_word

   static unsigned int gc_scan_history_index;
   static SCHEME_OBJECT * gc_scan_history [GC_SCAN_HISTORY_SIZE];
   static SCHEME_OBJECT * gc_to_history [GC_SCAN_HISTORY_SIZE];

   static SCHEME_OBJECT gc_trap
     = (MAKE_OBJECT (TC_REFERENCE_TRAP, TRAP_MAX_IMMEDIATE));
   static SCHEME_OBJECT * gc_scan_trap = 0;
   static SCHEME_OBJECT * gc_free_trap = 0;

   static SCHEME_OBJECT gc_object_referenced = SHARP_F;
   static SCHEME_OBJECT gc_objects_referencing = SHARP_F;
   static unsigned long gc_objects_referencing_count;
   static SCHEME_OBJECT * gc_objects_referencing_scan;
   static SCHEME_OBJECT * gc_objects_referencing_end;

   static void initialize_gc_history (void);
   static void handle_gc_trap
     (SCHEME_OBJECT *, SCHEME_OBJECT **, SCHEME_OBJECT);
   static void debug_transport_one_word (SCHEME_OBJECT, SCHEME_OBJECT *);
   static void update_gc_objects_referencing (void);
#else
#  define INITIALIZE_GC_HISTORY() do {} while (0)
#  define HANDLE_GC_TRAP(scan, pto, object) do {} while (0)
#  define DEBUG_TRANSPORT_ONE_WORD(object, from) do {} while (0)
#endif

#define SIMPLE_HANDLER(name)						\
  (GCT_ENTRY (table, i)) = name;					\
  break

void
initialize_gc_table (gc_table_t * table,
		     gc_tuple_handler_t * tuple_handler,
		     gc_vector_handler_t * vector_handler,
		     gc_object_handler_t * cc_entry_handler,
		     gc_object_handler_t * weak_pair_handler,
		     gc_precheck_from_t * precheck_from)
{
  unsigned int i;
  for (i = 0; (i < N_TYPE_CODES); i += 1)
    switch (gc_type_map[i])
      {
      case GC_NON_POINTER: SIMPLE_HANDLER (gc_handle_non_pointer);
      case GC_CELL:        SIMPLE_HANDLER (gc_handle_cell);
      case GC_PAIR:        SIMPLE_HANDLER (gc_handle_pair);
      case GC_TRIPLE:      SIMPLE_HANDLER (gc_handle_triple);
      case GC_QUADRUPLE:   SIMPLE_HANDLER (gc_handle_quadruple);
      case GC_COMPILED:    SIMPLE_HANDLER (gc_handle_cc_entry);
      case GC_UNDEFINED:   SIMPLE_HANDLER (gc_handle_undefined);

      case GC_VECTOR:
	(GCT_ENTRY (table, i))
	  = (((i == TC_COMPILED_CODE_BLOCK) || (i == TC_BIG_FLONUM))
	     ? gc_handle_aligned_vector
	     : gc_handle_unaligned_vector);
	break;

      case GC_SPECIAL:
	switch (i)
	  {
	  case TC_BROKEN_HEART:
	    SIMPLE_HANDLER (gc_handle_broken_heart);

	  case TC_REFERENCE_TRAP:
	    SIMPLE_HANDLER (gc_handle_reference_trap);

	  case TC_LINKAGE_SECTION:
	    SIMPLE_HANDLER (gc_handle_linkage_section);

	  case TC_MANIFEST_CLOSURE:
	    SIMPLE_HANDLER (gc_handle_manifest_closure);

	  case TC_MANIFEST_NM_VECTOR:
	  case TC_MANIFEST_SPECIAL_NM_VECTOR:
	    SIMPLE_HANDLER (gc_handle_nmv);

	  default:
	    outf_fatal ("\nunknown GC special type: %#x\n", i);
	    termination_init_error ();
	    break;
	  }
	break;
      }
  (GCT_TUPLE (table)) = tuple_handler;
  (GCT_VECTOR (table)) = vector_handler;
  (GCT_CC_ENTRY (table)) = cc_entry_handler;
  (GCT_WEAK_PAIR (table)) = weak_pair_handler;
  (GCT_PRECHECK_FROM (table)) = precheck_from;
}

void
run_gc_loop (SCHEME_OBJECT * scan, SCHEME_OBJECT ** pend, gc_ctx_t * ctx)
{
  INITIALIZE_GC_HISTORY ();
  while (scan < (*pend))
    {
      SCHEME_OBJECT object = (*scan);
      HANDLE_GC_TRAP (scan, (GCTX_PTO (ctx)), object);
      (GCTX_SCAN (ctx)) = scan;
      (GCTX_OBJECT (ctx)) = object;
      scan
	= ((* (GCT_ENTRY ((GCTX_TABLE (ctx)), (OBJECT_TYPE (object)))))
	   (scan, object, ctx));
    }
}

DEFINE_GC_HANDLER (gc_handle_non_pointer)
{
  return (scan + 1);
}

DEFINE_GC_HANDLER (gc_handle_cell)
{
  (*scan) = (GC_HANDLE_TUPLE (object, 1, ctx));
  return (scan + 1);
}

DEFINE_GC_HANDLER (gc_handle_pair)
{
  (*scan) = (GC_HANDLE_TUPLE (object, 2, ctx));
  return (scan + 1);
}

DEFINE_GC_HANDLER (gc_handle_triple)
{
  (*scan) = (GC_HANDLE_TUPLE (object, 3, ctx));
  return (scan + 1);
}

DEFINE_GC_HANDLER (gc_handle_quadruple)
{
  (*scan) = (GC_HANDLE_TUPLE (object, 4, ctx));
  return (scan + 1);
}

DEFINE_GC_HANDLER (gc_handle_cc_entry)
{
  (*scan) = (GC_HANDLE_CC_ENTRY (object, ctx));
  return (scan + 1);
}

DEFINE_GC_HANDLER (gc_handle_aligned_vector)
{
  (*scan) = (GC_HANDLE_VECTOR (object, true, ctx));
  return (scan + 1);
}

DEFINE_GC_HANDLER (gc_handle_unaligned_vector)
{
  (*scan) = (GC_HANDLE_VECTOR (object, false, ctx));
  return (scan + 1);
}

DEFINE_GC_HANDLER (gc_handle_broken_heart)
{
  gc_death (TERM_BROKEN_HEART, (GCTX_SCAN (ctx)), (GCTX_PTO (ctx)),
	    "broken heart in scan: %#lx", object);
  /*NOTREACHED*/
  return (scan);
}

DEFINE_GC_HANDLER (gc_handle_nmv)
{
  return (scan + 1 + (OBJECT_DATUM (object)));
}

DEFINE_GC_HANDLER (gc_handle_reference_trap)
{
  (*scan) = (((OBJECT_DATUM (object)) <= TRAP_MAX_IMMEDIATE)
	     ? object
	     : (GC_HANDLE_TUPLE (object, 2, ctx)));
  return (scan + 1);
}

DEFINE_GC_HANDLER (gc_handle_linkage_section)
{
#ifdef CC_SUPPORT_P
  unsigned long count = (linkage_section_count (object));
  scan += 1;
  switch (linkage_section_type (object))
    {
    case LINKAGE_SECTION_TYPE_REFERENCE:
    case LINKAGE_SECTION_TYPE_ASSIGNMENT:
      while (count > 0)
	{
	  WRITE_REFERENCE_OBJECT
	    ((GC_HANDLE_TUPLE ((READ_REFERENCE_OBJECT (scan)), 3, ctx)),
	     scan);
	  scan += 1;
	  count -= 1;
	}
      break;

    case LINKAGE_SECTION_TYPE_OPERATOR:
    case LINKAGE_SECTION_TYPE_GLOBAL_OPERATOR:
      {
	DECLARE_RELOCATION_REFERENCE (ref);
	START_OPERATOR_RELOCATION (scan, ref);
	while (count > 0)
	  {
	    write_uuo_target
	      ((GC_HANDLE_CC_ENTRY ((READ_UUO_TARGET (scan, ref)), ctx)),
	       scan);
	    scan += UUO_LINK_SIZE;
	    count -= 1;
	  }
	END_OPERATOR_RELOCATION (scan, ref);
      }
      break;

    default:
      gc_death (TERM_EXIT, (GCTX_SCAN (ctx)), (GCTX_PTO (ctx)),
		"Unknown linkage-section type.");
      break;
    }
  return (scan);
#else
  gc_no_cc_support (ctx);
  return (scan);
#endif
}

DEFINE_GC_HANDLER (gc_handle_manifest_closure)
{
#ifdef CC_SUPPORT_P
#ifdef EMBEDDED_CLOSURE_ADDRS_P
  DECLARE_RELOCATION_REFERENCE (ref);
  START_CLOSURE_RELOCATION (scan, ref);
  scan += 1;
  {
    insn_t * start = (compiled_closure_start (scan));
    unsigned long count = (compiled_closure_count (scan));
    while (count > 0)
      {
	write_compiled_closure_target
	  ((GC_HANDLE_CC_ENTRY ((READ_COMPILED_CLOSURE_TARGET (start, ref)),
				ctx)),
	   start);
	start = (compiled_closure_next (start));
	count -= 1;
      }
    scan = (skip_compiled_closure_padding (start));
  }
  END_CLOSURE_RELOCATION (scan, ref);
  return (scan);
#else
  return (compiled_closure_objects (scan + 1));
#endif
#else
  gc_no_cc_support (ctx);
  return (scan);
#endif
}

DEFINE_GC_HANDLER (gc_handle_undefined)
{
  GC_BAD_TYPE (object, (GCTX_SCAN (ctx)), (GCTX_PTO (ctx)));
  return (scan + 1);
}

void
std_gc_loop (SCHEME_OBJECT * scan, SCHEME_OBJECT ** pend,
	     SCHEME_OBJECT ** pto, SCHEME_OBJECT ** pto_end,
	     SCHEME_OBJECT * from_start, SCHEME_OBJECT * from_end)
{
  gc_ctx_t ctx0;
  gc_ctx_t * ctx = (&ctx0);

  (GCTX_TABLE (ctx)) = (gc_table ());
  (GCTX_PTO (ctx)) = pto;
  (GCTX_PTO_END (ctx)) = pto_end;
  (GCTX_FROM_START (ctx)) = from_start;
  (GCTX_FROM_END (ctx)) = from_end;
  run_gc_loop (scan, pend, ctx);
}

static gc_table_t *
gc_table (void)
{
  static gc_table_t table;
  static bool initialized_p = false;
  if (!initialized_p)
    {
      initialize_gc_table ((&table),
			   gc_tuple,
			   gc_vector,
			   gc_cc_entry,
			   gc_weak_pair,
			   gc_precheck_from);
      initialized_p = true;
    }
  return (&table);
}

bool
address_in_from_space_p (void * addr, gc_ctx_t * ctx)
{
  return
    ((addr >= ((void *) (GCTX_FROM_START (ctx))))
     && (addr < ((void *) (GCTX_FROM_END (ctx)))));
}

static
DEFINE_GC_TUPLE_HANDLER (gc_tuple)
{
  SCHEME_OBJECT * from = (OBJECT_ADDRESS (tuple));
  SCHEME_OBJECT * new_address = (GC_PRECHECK_FROM (from, ctx));
  return
    (OBJECT_NEW_ADDRESS (tuple,
			 ((new_address != 0)
			  ? new_address
			  : (gc_transport_words (from,
						 n_words,
						 false,
						 ctx)))));
}

static
DEFINE_GC_VECTOR_HANDLER (gc_vector)
{
  SCHEME_OBJECT * from = (OBJECT_ADDRESS (vector));
  SCHEME_OBJECT * new_address = (GC_PRECHECK_FROM (from, ctx));
  return
    (OBJECT_NEW_ADDRESS (vector,
			 ((new_address != 0)
			  ? new_address
			  : (gc_transport_words (from,
						 (1 + (OBJECT_DATUM (*from))),
						 align_p,
						 ctx)))));
}

static
DEFINE_GC_OBJECT_HANDLER (gc_cc_entry)
{
#ifdef CC_SUPPORT_P
  SCHEME_OBJECT old_block = (cc_entry_to_block (object));
  SCHEME_OBJECT new_block = (GC_HANDLE_VECTOR (old_block, true, ctx));
  return (CC_ENTRY_NEW_BLOCK (object,
			      (OBJECT_ADDRESS (new_block)),
			      (OBJECT_ADDRESS (old_block))));
#else
  gc_no_cc_support (ctx);
  return (object);
#endif
}

static
DEFINE_GC_OBJECT_HANDLER (gc_weak_pair)
{
  SCHEME_OBJECT * new_address
    = (GC_PRECHECK_FROM ((OBJECT_ADDRESS (object)), ctx));
  return ((new_address != 0)
	  ? (OBJECT_NEW_ADDRESS (object, new_address))
	  : (gc_transport_weak_pair (object, ctx)));
}

SCHEME_OBJECT *
gc_precheck_from (SCHEME_OBJECT * from, gc_ctx_t * ctx)
{
#ifdef ENABLE_GC_DEBUGGING_TOOLS
  if (!ADDRESS_IN_MEMORY_BLOCK_P (from))
    gc_death (TERM_EXIT, (GCTX_SCAN (ctx)), (GCTX_PTO (ctx)),
	      "out of range pointer: %#lx", ((unsigned long) from));
#endif
  return
    ((!address_in_from_space_p (from, ctx))
     ? from
     : (BROKEN_HEART_P (*from))
     ? (OBJECT_ADDRESS (*from))
     : 0);
}

SCHEME_OBJECT *
gc_transport_words (SCHEME_OBJECT * from,
		    unsigned long n_words,
		    bool align_p,
		    gc_ctx_t * ctx)
{
  SCHEME_OBJECT * to = (* (GCTX_PTO (ctx)));
  if (align_p)
    ALIGN_FLOAT (to);
#ifdef ENABLE_GC_DEBUGGING_TOOLS
  if (to >= (* (GCTX_PTO_END (ctx))))
    gc_death (TERM_EXIT, (GCTX_SCAN (ctx)), (GCTX_PTO (ctx)),
	      "target space completely filled");
  {
    SCHEME_OBJECT * end = (to + n_words);
    if (end > (* (GCTX_PTO_END (ctx))))
      gc_death (TERM_EXIT, (GCTX_SCAN (ctx)), (GCTX_PTO (ctx)),
		"block overflows target space: %#lx",
		((unsigned long) end));
  }
  if (n_words > 0x10000)
    {
      outf_error ("\nWarning: copying large block: %lu\n", n_words);
      outf_flush_error ();
    }
#endif
  {
    SCHEME_OBJECT * scan_to = to;
    SCHEME_OBJECT * scan_from = from;
    while (n_words > 0)
      {
	DEBUG_TRANSPORT_ONE_WORD ((GCTX_OBJECT (ctx)), scan_from);
	(*scan_to++) = (*scan_from++);
	n_words -= 1;
      }
    (* (GCTX_PTO (ctx))) = scan_to;
  }
  (*from) = (MAKE_BROKEN_HEART (to));
  return (to);
}

/* Weak pairs are supported by adding an extra pass to the GC.  During
   the normal pass, a weak pair is transported to new space, but the
   car of the pair is marked as a non-pointer so that won't be traced.
   Then the original weak pair in old space is chained into a list.
   This work is performed by 'note_weak_pair'.

   At the end of this pass, we have a list of all of the old weak
   pairs.  Since each weak pair in old space has a broken-heart
   pointer to the corresponding weak pair in new space, we also have a
   list of all of the new weak pairs.

   The extra pass then traverses this list, restoring the original
   type of the object in the car of each pair.  Then, if the car is a
   pointer that hasn't been copied to new space, it is replaced by #F.
   This work is performed by 'update_weak_pointers'.

   Here is a diagram showing the layout of a weak pair immediately
   after it is transported to new space.  After the normal pass is
   complete, the only thing that will have changed is that the "old
   CDR object" will have been updated to point to new space, if it is
   a pointer object.


   weak_chain       old space           |         new space
       |      _______________________   |   _______________________
       |      |broken |     new     |   |   |      |              |
       +=====>|heart  |  location ======|==>| NULL | old CAR data |
	      |_______|_____________|   |   |______|______________|
	      |old car|   next in   |   |   |                     |
	      | type  |    chain    |   |   |   old CDR object    |
	      |_______|_____________|   |   |_____________________|

 */

SCHEME_OBJECT
gc_transport_weak_pair (SCHEME_OBJECT pair, gc_ctx_t * ctx)
{
  SCHEME_OBJECT * old_addr = (OBJECT_ADDRESS (pair));
  SCHEME_OBJECT * new_addr = (gc_transport_words (old_addr, 2, false, ctx));
  SCHEME_OBJECT old_car = (new_addr[0]);
  SCHEME_OBJECT * caddr;

  /* Don't add pair to chain unless old_car is a pointer into old
     space.  */

  switch (gc_ptr_type (old_car))
    {
    case GC_POINTER_NORMAL:
      caddr = (OBJECT_ADDRESS (old_car));
      break;

    case GC_POINTER_COMPILED:
#ifdef CC_SUPPORT_P
      caddr = (cc_entry_address_to_block_address (CC_ENTRY_ADDRESS (old_car)));
      break;
#endif

    default:
      caddr = 0;
      break;
    }
  if ((caddr != 0) && (address_in_from_space_p (caddr, ctx)))
    {
      (old_addr[1])
	= (MAKE_POINTER_OBJECT ((OBJECT_TYPE (old_car)), weak_chain));
      (new_addr[0]) = (OBJECT_NEW_TYPE (TC_NULL, old_car));
      weak_chain = old_addr;
    }

  return (OBJECT_NEW_ADDRESS (pair, new_addr));
}

void
initialize_weak_chain (void)
{
  weak_chain = 0;
}

void
update_weak_pointers (void)
{
  while (weak_chain != 0)
    {
      SCHEME_OBJECT * new_addr = (OBJECT_ADDRESS (weak_chain[0]));
      SCHEME_OBJECT old_car
	= (OBJECT_NEW_TYPE ((OBJECT_TYPE (weak_chain[1])), (new_addr[0])));

      switch (gc_ptr_type (old_car))
	{
	case GC_POINTER_NORMAL:
	  {
	    SCHEME_OBJECT * addr = (OBJECT_ADDRESS (old_car));
	    (*new_addr)
	      = ((BROKEN_HEART_P (*addr))
		 ? (MAKE_OBJECT_FROM_OBJECTS (old_car, (*addr)))
		 : SHARP_F);
	  }
	  break;

	case GC_POINTER_COMPILED:
#ifdef CC_SUPPORT_P
	  {
	    SCHEME_OBJECT * addr
	      = (cc_entry_address_to_block_address
		 (CC_ENTRY_ADDRESS (old_car)));
	    (*new_addr)
	      = ((BROKEN_HEART_P (*addr))
		 ? (CC_ENTRY_NEW_BLOCK (old_car,
					(OBJECT_ADDRESS (*addr)),
					addr))
		 : SHARP_F);
	  }
	  break;
#endif

	case GC_POINTER_NOT:
	  /* Shouldn't happen -- filtered out in 'note_weak_pair'.  */
	  (*new_addr) = old_car;
	  break;
	}
      weak_chain = (OBJECT_ADDRESS (weak_chain[1]));
    }
}

void
gc_death (long code, SCHEME_OBJECT * scan, SCHEME_OBJECT ** pfree,
	  const char * format, ...)
{
  va_list ap;

  outf_fatal ("\n");
  va_start (ap, format);
  voutf_fatal (format, ap);
  va_end (ap);
  outf_fatal ("\n");
  if (scan != 0)
    {
      outf_fatal ("scan = 0x%lx", ((unsigned long) scan));
      if (pfree != 0)
	outf_fatal ("; free = 0x%lx", ((unsigned long) (*pfree)));
      outf_fatal ("\n");
    }
  Microcode_Termination (code);
  /*NOTREACHED*/
}

void
gc_no_cc_support (gc_ctx_t * ctx)
{
  gc_death (TERM_EXIT, (GCTX_SCAN (ctx)), (GCTX_PTO (ctx)),
	    "No compiled-code support.");
}

#ifdef ENABLE_GC_DEBUGGING_TOOLS

void
initialize_gc_history (void)
{
  gc_scan_history_index = 0;
  memset (gc_scan_history, 0, (sizeof (gc_scan_history)));
  memset (gc_to_history, 0, (sizeof (gc_to_history)));
}

void
handle_gc_trap (SCHEME_OBJECT * scan,
		SCHEME_OBJECT ** pto,
		SCHEME_OBJECT object)
{
  (gc_scan_history[gc_scan_history_index]) = scan;
  (gc_to_history[gc_scan_history_index]) = ((pto == 0) ? 0 : (*pto));
  gc_scan_history_index += 1;
  if (gc_scan_history_index == GC_SCAN_HISTORY_SIZE)
    gc_scan_history_index = 0;
  if ((object == gc_trap)
      || ((gc_scan_trap != 0) && (scan >= gc_scan_trap))
      || ((gc_free_trap != 0) && (pto != 0) && ((*pto) >= gc_free_trap)))
    {
      outf_error ("\nstd_gc_loop: trap.\n");
      abort ();
    }
}

void
collect_gc_objects_referencing (SCHEME_OBJECT object, SCHEME_OBJECT collector)
{
  gc_object_referenced = object;
  gc_objects_referencing = collector;
}

static void
debug_transport_one_word (SCHEME_OBJECT object, SCHEME_OBJECT * from)
{
  if ((gc_object_referenced == (*from))
      && (gc_objects_referencing != SHARP_F))
    {
      gc_objects_referencing_count += 1;
      if (gc_objects_referencing_scan != gc_objects_referencing_end)
	{
	  update_gc_objects_referencing ();
	  (*gc_objects_referencing_scan++) = object;
	}
    }
}

void
initialize_gc_objects_referencing (void)
{
  if (gc_objects_referencing != SHARP_F)
    {
      /* Temporarily change to non-marked vector.  */
      MEMORY_SET
	(gc_objects_referencing, 0,
	 (MAKE_OBJECT
	  (TC_MANIFEST_NM_VECTOR,
	   (OBJECT_DATUM (MEMORY_REF (gc_objects_referencing, 0))))));
      /* Wipe the table.  */
      {
	SCHEME_OBJECT * scan = (VECTOR_LOC (gc_objects_referencing, 0));
	SCHEME_OBJECT * end
	  = (VECTOR_LOC (gc_objects_referencing,
			 (VECTOR_LENGTH (gc_objects_referencing))));
	while (scan < end)
	  (*scan++) = SHARP_F;
      }
      gc_objects_referencing_count = 0;
      gc_objects_referencing_scan = (VECTOR_LOC (gc_objects_referencing, 1));
      gc_objects_referencing_end
	= (VECTOR_LOC (gc_objects_referencing,
		       (VECTOR_LENGTH (gc_objects_referencing))));
      (*Free++) = gc_objects_referencing;
    }
}

void
scan_gc_objects_referencing (SCHEME_OBJECT * from_start,
			     SCHEME_OBJECT * from_end)
{
  if (gc_objects_referencing != SHARP_F)
    {
      update_gc_objects_referencing ();
      /* Change back to marked vector.  */
      MEMORY_SET
	(gc_objects_referencing, 0,
	 (MAKE_OBJECT
	  (TC_MANIFEST_VECTOR,
	   (OBJECT_DATUM (MEMORY_REF (gc_objects_referencing, 0))))));
      /* Store the count in the table.  */
      VECTOR_SET (gc_objects_referencing, 0,
		  (ULONG_TO_FIXNUM (gc_objects_referencing_count)));
      {
	SCHEME_OBJECT * end = gc_objects_referencing_scan;
	std_gc_loop ((VECTOR_LOC (gc_objects_referencing, 1)), (&end),
		     (&end), (&end),
		     from_start, from_end);
	if (end != gc_objects_referencing_scan)
	  gc_death (TERM_BROKEN_HEART, 0, 0,
		    "scan of gc_objects_referencing performed transport");
      }
      gc_objects_referencing = SHARP_F;
      gc_object_referenced = SHARP_F;
    }
}

static void
update_gc_objects_referencing (void)
{
  SCHEME_OBJECT header = (MEMORY_REF (gc_objects_referencing, 0));
  if (BROKEN_HEART_P (header))
    {
      SCHEME_OBJECT new
	= (MAKE_OBJECT_FROM_OBJECTS (gc_objects_referencing, header));
      gc_objects_referencing_scan =
	(VECTOR_LOC (new,
		     (gc_objects_referencing_scan
		      - (VECTOR_LOC (gc_objects_referencing, 0)))));
      gc_objects_referencing_end = (VECTOR_LOC (new, (VECTOR_LENGTH (new))));
      gc_objects_referencing = new;
    }
}

#endif /* ENABLE_GC_DEBUGGING_TOOLS */
