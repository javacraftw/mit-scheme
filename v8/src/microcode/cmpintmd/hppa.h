/* -*-C-*-

$Header: /Users/cph/tmp/foo/mit-scheme/mit-scheme/v8/src/microcode/cmpintmd/hppa.h,v 1.30 1992/02/04 23:09:48 jinx Exp $

Copyright (c) 1989-92 Massachusetts Institute of Technology

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

/*
 *
 * Compiled code interface macros.
 *
 * See cmpint.txt for a description of these fields.
 *
 * Specialized for the HP Precision Architecture (Spectrum)
 */

#ifndef CMPINT2_H_INCLUDED
#define CMPINT2_H_INCLUDED

#define COMPILER_NONE_TYPE			0
#define COMPILER_MC68020_TYPE			1
#define COMPILER_VAX_TYPE			2
#define COMPILER_SPECTRUM_TYPE			3
#define COMPILER_MIPS_TYPE			4

/* Machine parameters to be set by the user. */

/* Processor type.  Choose a number from the above list, or allocate your own. */

#define COMPILER_PROCESSOR_TYPE			COMPILER_SPECTRUM_TYPE

/* Size (in long words) of the contents of a floating point register if
   different from a double.  For example, an MC68881 saves registers
   in 96 bit (3 longword) blocks.
   Default is fine for PA.
   define COMPILER_TEMP_SIZE			3
*/

/* Descriptor size.
   This is the size of the offset field, and of the format field.
   This definition probably does not need to be changed.
 */

typedef unsigned short format_word;

/* PC alignment constraint.
   Change PC_ZERO_BITS to be how many low order bits of the pc are
   guaranteed to be 0 always because of PC alignment constraints.
*/

#define PC_ZERO_BITS                    2

/* C function pointers are pairs of instruction addreses and data segment
   pointers.  We don't want that for the assembly language entry points.
 */

#ifdef __GNUC__
   /* Under GCC version 1, function pointers are NOT closures.
      We don't know about version 2 or later yet.
    */
#  if (__GNUC__ >= 2)
#    include "Fix cmpint-hppa.h to define C_FUNC_PTR_IS_CLOSURE if necessary"
#  endif
#else /* Assume HP C -- Test for HP-UX >= 8.0 */
#  include <magic.h>
#  ifdef SHL_MAGIC
#    define C_FUNC_PTR_IS_CLOSURE
#  endif
#endif

/* Utilities for manipulating absolute subroutine calls.
   On the PA the absolute address is "smeared out" over two
   instructions, an LDIL and a BLE instruction.
 */

extern unsigned long
  EXFUN (hppa_extract_absolute_address, (unsigned long *));

extern void
  EXFUN (hppa_store_absolute_address,
	 (unsigned long *, unsigned long, unsigned long));

#define EXTRACT_ABSOLUTE_ADDRESS(target, address)			\
{									\
  (target) =								\
    ((SCHEME_OBJECT)							\
     (hppa_extract_absolute_address ((unsigned long *) (address))));	\
}

#define STORE_ABSOLUTE_ADDRESS(entry_point, address, nullify_p)		\
{									\
  hppa_store_absolute_address (((unsigned long *) (address)),		\
			       ((unsigned long) (entry_point)),		\
			       ((unsigned long) (nullify_p)));		\
}

#ifdef IN_CMPINT_C

/* Definitions of the utility procedures.
   Procedure calls of leaf procedures on the HPPA are pretty fast,
   so there is no reason not to do this out of line.
   In this way compiled code can use them too.
 */

union ldil_inst
{
  unsigned long inst;
  struct
  {
    unsigned opcode	: 6;
    unsigned base	: 5;
    unsigned D		: 5;
    unsigned C		: 2;
    unsigned E		: 2;
    unsigned B		: 11;
    unsigned A		: 1;
  } fields;
};

union ble_inst
{
  unsigned long inst;
  struct
  {
    unsigned opcode	: 6;
    unsigned base	: 5;
    unsigned w1		: 5;
    unsigned s		: 3;
    unsigned w2b	: 10;
    unsigned w2a	: 1;
    unsigned n		: 1;
    unsigned w0		: 1;
  } fields;
};

union short_pointer
{
  unsigned long address;
  struct
  {
    unsigned A		: 1;
    unsigned B		: 11;
    unsigned C		: 2;
    unsigned D		: 5;
    unsigned w2a	: 1;
    unsigned w2b	: 10;
    unsigned pad	: 2;
  } fields;
};

union bl_offset
{
  long value;
  struct
  {
    int sign_pad	: 13;
    unsigned w0		: 1;
    unsigned w1		: 5;
    unsigned w2a	: 1;
    unsigned w2b	: 10;
    unsigned pad	: 2;
  } fields;
};

/*
   Note: The following does not do a full decoding of the BLE instruction.
   It assumes that the bits have been set by STORE_ABSOLUTE_ADDRESS below,
   which decomposes an absolute address according to the `short_pointer'
   structure above, and thus certain fields are 0.

   The sequence inserted by STORE_ABSOLUTE_ADDRESS is approximately
   (the actual address decomposition is given above).
   LDIL		L'ep,26
   BLE		R'ep(5,26)
 */

unsigned long
DEFUN (hppa_extract_absolute_address, (addr), unsigned long * addr)
{
  union short_pointer result;
  union ble_inst ble;
  union ldil_inst ldil;

  ldil.inst = *addr++;
  ble.inst = *addr;

  /* Fill the padding */
  result.address = 0;

  result.fields.A = ldil.fields.A;
  result.fields.B = ldil.fields.B;
  result.fields.C = ldil.fields.C;
  result.fields.D = ldil.fields.D;
  result.fields.w2a = ble.fields.w2a;
  result.fields.w2b = ble.fields.w2b;

  return (result.address);
}

void
DEFUN (hppa_store_absolute_address, (addr, sourcev, nullify_p),
       unsigned long * addr AND unsigned long sourcev
       AND unsigned long nullify_p)
{
  union short_pointer source;
  union ldil_inst ldil;
  union ble_inst ble;

  source.address = sourcev;

#if 0
  ldil.fields.opcode = 0x08;
  ldil.fields.base = 26;
  ldil.fields.E = 0;
#else
  ldil.inst = ((0x08 << 26) | (26 << 21));
#endif

  ldil.fields.A = source.fields.A;
  ldil.fields.B = source.fields.B;
  ldil.fields.C = source.fields.C;
  ldil.fields.D = source.fields.D;

#if 0
  ble.fields.opcode = 0x39;
  ble.fields.base = 26;
  ble.fields.w1 = 0;
  ble.fields.s = 3;
  ble.fields.w0 = 0;
#else
  ble.inst = ((0x39 << 26) | (26 << 21) | (3 << 13));
#endif

  ble.fields.w2a = source.fields.w2a;
  ble.fields.w2b = source.fields.w2b;
  ble.fields.n = (nullify_p & 1);

  *addr++ = ldil.inst;
  *addr = ble.inst;
  return;
}

/* Cache flushing/pushing code.
   Uses routines from cmpaux-hppa.m4.
 */

#include "hppacache.h"
#include "option.h"

static struct pdc_cache_dump cache_info;

extern void
  EXFUN (flush_i_cache, (void)),
  EXFUN (push_d_cache_region, (PTR, unsigned long));

void
DEFUN_VOID (flush_i_cache)
{
  extern void
    EXFUN (cache_flush_all, (unsigned int, struct pdc_cache_result *));

  struct pdc_cache_result * cache_desc;
  
  cache_desc = ((struct pdc_cache_result *) &(cache_info.cache_format));

  /* The call can be interrupted in the middle of a set, so do it twice.
     Probability of two interrupts in the same cache line is
     exceedingly small, so this is likely to win.
     On the other hand, if the caches are directly mapped, a single
     call can't lose.
     In addition, if the cache is shared, there is no need to flush at all.
   */

  if (((cache_desc->I_info.conf.bits.fsel & 1) == 0)
      || ((cache_desc->D_info.conf.bits.fsel & 1) == 0))
  {
    unsigned int flag = 0;

    if (cache_desc->I_info.loop != 1)
      flag |= I_CACHE;
    if (cache_desc->D_info.loop != 1)
      flag |= D_CACHE;

    if (flag != 0)
      cache_flush_all (flag, cache_desc);
    cache_flush_all ((D_CACHE | I_CACHE), cache_desc);
  }
}

void
DEFUN (push_d_cache_region, (start_address, block_size),
       PTR start_address AND unsigned long block_size)
{
  extern void
    EXFUN (cache_flush_region, (PTR, long, unsigned int));

  struct pdc_cache_result * cache_desc;
  
  cache_desc = ((struct pdc_cache_result *) &(cache_info.cache_format));

  /* Note that the first and last words are also flushed from the I-cache
     in case this object is adjacent to another that has already caused
     the cache line to be copied into the I-cache.
   */

  if (((cache_desc->I_info.conf.bits.fsel & 1) == 0)
      || ((cache_desc->D_info.conf.bits.fsel & 1) == 0))
  {
    cache_flush_region (start_address, block_size, D_CACHE);
    cache_flush_region (start_address, 1, I_CACHE);
    cache_flush_region (((PTR)
			 (((unsigned long *) start_address)
			  + (block_size - 1))),
			1,
			I_CACHE);
  }
  return;
}

#ifndef MODELS_FILENAME
#define MODELS_FILENAME "HPPAmodels"
#endif

static void
DEFUN_VOID (flush_i_cache_initialize)
{
  struct utsname sysinfo;
  CONST char * models_filename =
    (search_path_for_file (0, MODELS_FILENAME, 1));
  if ((uname (&sysinfo)) < 0)
    {
      fprintf (stderr, "\nflush_i_cache: uname failed.\n");
      goto loser;
    }
  {
    int fd = (open (models_filename, O_RDONLY));
    if (fd < 0)
      {
	fprintf (stderr, "\nflush_i_cache: open (%s) failed.\n",
		 models_filename);
	goto loser;
      }
    while (1)
      {
	int read_result =
	  (read (fd,
		 ((char *) (&cache_info)),
		 (sizeof (struct pdc_cache_dump))));
	if (read_result == 0)
	  {
	    close (fd);
	    break;
	  }
	if (read_result != (sizeof (struct pdc_cache_dump)))
	  {
	    close (fd);
	    fprintf (stderr, "\nflush_i_cache: read (%s) failed.\n",
		     models_filename);
	    goto loser;
	  }
	if ((strcmp ((sysinfo . machine), (cache_info . hardware))) == 0)
	  {
	    close (fd);
	    return;
	  }
      }
  }
  fprintf (stderr,
	   "The cache parameters database has no entry for the %s model.\n",
	   (sysinfo . machine));
  fprintf (stderr, "Please make an entry in the database;\n");
  fprintf (stderr, "the installation notes contain instructions for doing so.\n");
 loser:
  fprintf (stderr, "\nASM_RESET_HOOK: Unable to read cache parameters.\n");
  termination_init_error ();
}

#endif	/* IN_CMPINT_C */

/* Interrupt/GC polling. */

/* Skip over this many BYTES to bypass the GC check code (ordinary
procedures and continuations differ from closures) */

#define ENTRY_SKIPPED_CHECK_OFFSET 	4
#define CLOSURE_SKIPPED_CHECK_OFFSET 	16

/* The length of the GC recovery code that precedes an entry.
   On the HP-PA a "ble, ldi" instruction sequence.
 */

#define ENTRY_PREFIX_LENGTH		8

/*
  The instructions for a normal entry should be something like

  COMBT,>=,N	Rfree,Rmemtop,interrupt
  LDW		0(0,Regs),Rmemtop

  For a closure

  DEP		0,31,2,31			; clear privilege bits
  DEPI		tc_closure>>1,4,5,31		; set type code
  STWM		31,-4(0,Rstack)			; push on stack
  COMB,>=	Rfree,Rmemtop,interrupt		; GC/interrupt check
  LDW		0(0,Regs),Rmemtop		; Recache memtop

  Notes:

  The LDW can be eliminated once the C interrupt handler is changed to
  update Rmemtop directly.  At that point, the instruction following the
  COMB instruction will have to be nullified whenever the interrupt
  branch is processed.

  The DEP can be eliminated if we assume that the privilege bits will always
  be the same (3).  The clearing can be combined with the ADDI instruction in
  the closure object itself.

 */

/* A NOP on machines where instructions are longword-aligned. */

#define ADJUST_CLOSURE_AT_CALL(entry_point, location) do		\
{									\
} while (0)

/* Compiled closures */

/* Manifest closure entry block size.
   Size in bytes of a compiled closure's header excluding the
   TC_MANIFEST_CLOSURE header.

   On the PA this is 2 format_words for the format word and gc
   offset words, and 12 more bytes for 3 instructions:

   LDIL		L'target,26
   BLE		R'target(5,26)
   ADDI		-12,31,31
 */

#define COMPILED_CLOSURE_ENTRY_SIZE     16

/* Manifest closure entry destructuring.

   Given the entry point of a closure, extract the `real entry point'
   (the address of the real code of the procedure, ie. one indirection)
   from the closure.
   On the PA, the real entry point is "smeared out" over the LDIL and
   the BLE instructions.
*/

#define EXTRACT_CLOSURE_ENTRY_ADDRESS(real_entry_point, entry_point)	\
{									\
  EXTRACT_ABSOLUTE_ADDRESS(real_entry_point, entry_point);		\
}

/* This is the inverse of EXTRACT_CLOSURE_ENTRY_ADDRESS.
   Given a closure's entry point and a code entry point, store the
   code entry point in the closure.
 */

#define STORE_CLOSURE_ENTRY_ADDRESS(real_entry_point, entry_point)	\
{									\
  STORE_ABSOLUTE_ADDRESS(real_entry_point, entry_point, false);		\
}

/* Trampolines

   Here's a picture of a trampoline on the PA (offset in bytes from
   entry point)

     -12: MANIFEST vector header
     - 8: NON_MARKED header
     - 4: Format word
     - 2: 0xC (GC Offset to start of block from .+2)
       0: BLE	4(4,3)		; call trampoline_to_interface
       4: LDI	index,28
       8: trampoline dependent storage (0 - 3 longwords)

   TRAMPOLINE_ENTRY_SIZE is the size in longwords of the machine
   dependent portion of a trampoline, including the GC and format
   headers.  The code in the trampoline must store an index (used to
   determine which C SCHEME_UTILITY procedure to invoke) in a
   register, jump to "scheme_to_interface" and leave the address of
   the storage following the code in a standard location.

   TRAMPOLINE_BLOCK_TO_ENTRY is the number of longwords from the start
   of a trampoline to the first instruction.  Note that this aligns
   the first instruction to a longword boundary.

   WARNING: make_trampoline in cmpint.c will need to be changed if
   machine instructions must be aligned more strictly than just on
   longword boundaries (e.g. quad word alignment for instructions).

   TRAMPOLINE_STORAGE takes the address of the first instruction in a
   trampoline (not the start of the trampoline block) and returns the
   address of the first storage word in the trampoline.

   STORE_TRAMPOLINE_ENTRY gets the address of the first instruction in
   the trampoline and stores the instructions.  It also receives the
   index of the C SCHEME_UTILITY to be invoked.

   Note: this flushes both caches because the words may fall in a cache
   line that already has an association in the i-cache because a different
   trampoline or a closure are in it.
*/

#define TRAMPOLINE_ENTRY_SIZE		3
#define TRAMPOLINE_BLOCK_TO_ENTRY	3
#define TRAMPOLINE_STORAGE(tramp)					\
((((SCHEME_OBJECT *) tramp) - TRAMPOLINE_BLOCK_TO_ENTRY) +		\
 (2 + TRAMPOLINE_ENTRY_SIZE)) 

#define STORE_TRAMPOLINE_ENTRY(entry_address, index) do			\
{									\
  extern void								\
    EXFUN (cache_flush_region, (PTR, long, unsigned int));		\
									\
  unsigned long *PC;							\
									\
  PC = ((unsigned long *) (entry_address));				\
									\
  /*	BLE	4(4,3)		*/					\
									\
  *PC = ((unsigned long) 0xe4602008);					\
									\
  /*	LDO	index(0),28	*/					\
  /*    This assumes that index is >= 0. */				\
									\
  *(PC + 1) = (((unsigned long) 0x341c0000) +				\
	       (((unsigned long) (index)) << 1));			\
  cache_flush_region (PC, (TRAMPOLINE_ENTRY_SIZE - 1),			\
		      (I_CACHE | D_CACHE));				\
} while (0)

/* Execute cache entries.

   Execute cache entry size size in longwords.  The cache itself
   contains both the number of arguments provided by the caller and
   code to jump to the destination address.  Before linkage, the cache
   contains the callee's name instead of the jump code.

   On PA: 2 instructions, and a fixnum representing the number of arguments.
 */

#define EXECUTE_CACHE_ENTRY_SIZE        3

/* For the HPPA, addresses in bytes from the start of the cache:

   Before linking

     +0: TC_SYMBOL || symbol address
     +4: #F
     +8: TC_FIXNUM || 0
    +10: number of supplied arguments, +1

   After linking

     +0: LDIL	L'target,26
     +4: BLE,n	R'target(5,26)
     +8: (unchanged)
    +10: (unchanged)

   Important:

     Currently the code below unconditionally nullifies the delay-slot
     instruction for the BLE instruction.  This is wasteful and
     unnecessary.  An EXECUTE_CACHE_ENTRY could be one word longer to
     accomodate a delay-slot instruction, and the linker could do the
     following:

     - If the target instruction is not a branch instruction, use 4 +
     the address of the target instruction, and copy the target
     instruction to the delay slot.  Note that branch instructions are
     those with opcodes (6 bits) in the range #b1xy0zw, for any bit
     value for x, y, z, w.

     - If the target instruction is the COMBT instruction of an
     interrupt/gc check, use 4 + the address of the target
     instruction, and insert a similar COMBT instruction in the delay
     slot.  This COMBT instruction would then branch to an instruction
     shared by all the cache cells in the same block.  This shared
     instruction would be a BE instruction used to jump to an assembly
     language handler.  This handler would recover the target address
     from the link address left in register 31 by the BLE instruction
     in the execute cache cell, and use it to compute the address of
     and branch to the interrupt code for the entry.

     - Otherwise use the address of the target instruction and insert
     a NOP in the delay slot.
*/

/* Execute cache destructuring. */

/* Given a target location and the address of the first word of an
   execute cache entry, extract from the cache cell the number of
   arguments supplied by the caller and store it in target.
 */

#define EXTRACT_EXECUTE_CACHE_ARITY(target, address)			\
{									\
  (target) = ((long) (* (((unsigned short *) (address)) + 5)));		\
}

/* Given a target location and the address of the first word of an
   execute cache entry, extract from the cache cell the name
   of the variable whose value is being invoked.
   This is valid only before linking.
 */

#define EXTRACT_EXECUTE_CACHE_SYMBOL(target, address)			\
{									\
  (target) = (* (((SCHEME_OBJECT *) (address))));			\
}

/* Extract the target address (not the code to get there) from an
   execute cache cell.
 */

#define EXTRACT_EXECUTE_CACHE_ADDRESS(target, address)			\
{									\
  EXTRACT_ABSOLUTE_ADDRESS(target, address);				\
}

/* This is the inverse of EXTRACT_EXECUTE_CACHE_ADDRESS. */

#define STORE_EXECUTE_CACHE_ADDRESS(address, entry)			\
{									\
  STORE_ABSOLUTE_ADDRESS(entry, address, true);				\
}

/* This stores the fixed part of the instructions leaving the
   destination address and the number of arguments intact.  These are
   split apart so the GC can call EXTRACT/STORE...ADDRESS but it does
   NOT need to store the instructions back.  On some architectures the
   instructions may change due to GC and then STORE_EXECUTE_CACHE_CODE
   should become a no-op and all of the work is done by
   STORE_EXECUTE_CACHE_ADDRESS instead.
   On PA this is a NOP.
 */

#define STORE_EXECUTE_CACHE_CODE(address) do				\
{									\
} while (0)

/* This is supposed to flush the Scheme portion of the I-cache.
   It flushes the entire I-cache instead, since it is easier.
   It is used after a GC or disk-restore.
   It's needed because the GC has moved code around, and closures
   and execute cache cells have absolute addresses that the
   processor might have old copies of.
 */

#define FLUSH_I_CACHE() do						\
{									\
  extern void								\
    EXFUN (flush_i_cache, (void));					\
									\
  flush_i_cache ();							\
} while (0)

/* This flushes a region of the I-cache.
   It is used after updating an execute cache while running.
   Not needed during GC because FLUSH_I_CACHE will be used.
 */   

#define FLUSH_I_CACHE_REGION(address, nwords) do			\
{									\
  extern void								\
    EXFUN (cache_flush_region, (PTR, long, unsigned int));		\
									\
  cache_flush_region (((PTR) (address)), ((long) (nwords)),		\
		      (D_CACHE | I_CACHE));				\
} while (0)

/* This pushes a region of the D-cache back to memory.
   It is (typically) used after loading (and relocating) a piece of code
   into memory.
 */   

#define PUSH_D_CACHE_REGION(address, nwords) do				\
{									\
  extern void								\
    EXFUN (push_d_cache_region, (PTR, unsigned long));			\
									\
  push_d_cache_region (((PTR) (address)),				\
		       ((unsigned long) (nwords)));			\
} while (0)

/* This is not completely true.  Some models (eg. 850) have combined caches,
   but we have to assume the worst.
 */

#define SPLIT_CACHES

#ifdef IN_CMPINT_C

long
DEFUN (assemble_17, (inst), union ble_inst inst)
{
  union bl_offset off;

  off.fields.pad = 0;
  off.fields.w2b = inst.fields.w2b;
  off.fields.w2a = inst.fields.w2a;
  off.fields.w1  = inst.fields.w1;
  off.fields.w0  = inst.fields.w0;
  off.fields.sign_pad = ((inst.fields.w0 == 0) ? 0 : -1);
  return off.value;
}

PTR *
DEFUN (transform_procedure_table, (table_length, old_table),
       long table_length AND PTR * old_table)
{
  PTR * new_table;
  long counter;

  new_table = ((PTR *) (malloc (table_length * (sizeof (PTR)))));
  if (new_table == ((PTR *) NULL))
  {
    fprintf (stderr,
	     "transform_procedure_table: malloc (%d) failed.\n",
	     (table_length * (sizeof (PTR))));
    exit (1);
  }

  for (counter = 0; counter < table_length; counter++)
  {
#ifdef C_FUNC_PTR_IS_CLOSURE
    char * C_closure, * blp;
    long offset;

    /* This is correct for HP C for HP-UX >= 8.0.
       Is it also correct for GCC 2?
     */

    C_closure = ((char *) (old_table [counter]));
    blp = (* ((char **) (C_closure - 2)));
    blp = ((char *) (((unsigned long) blp) & ~3));
    offset = (assemble_17 (* ((union ble_inst *) blp)));
    new_table[counter] = ((PTR) ((blp + 8) + offset));
#else
    new_table[counter] = ((PTR) (old_table [counter]));
#endif
  }
  return (new_table);
}


/* This loads the cache information structure for use by flush_i_cache,
   sets the floating point flags correctly, and accommodates the c
   function pointer closure format problems for utilities for HP-UX >= 8.0 .
 */

extern PTR * hppa_utility_table;
PTR * hppa_utility_table;

void
DEFUN (hppa_reset_hook, (table_length, utility_table),
       long table_length AND PTR * utility_table)
{
  extern void
    EXFUN (interface_initialize, (void));

  flush_i_cache_initialize ();
  interface_initialize ();
  /* This can be done with the primitive table as well if we add
     assembly-language primitive invocation code.
   */
  hppa_utility_table =
    (transform_procedure_table (table_length, utility_table));
  return;
}

#define ASM_RESET_HOOK() do						\
{									\
  hppa_reset_hook (((sizeof (utility_table)) / (sizeof (PTR))),		\
		   ((PTR *) (&utility_table[0])));			\
} while (0)

#endif /* IN_CMPINT_C */

/* Derived parameters and macros.

   These macros expect the above definitions to be meaningful.
   If they are not, the macros below may have to be changed as well.
 */

#define COMPILED_ENTRY_OFFSET_WORD(entry)                               \
  (((format_word *) (entry))[-1])
#define COMPILED_ENTRY_FORMAT_WORD(entry)                               \
  (((format_word *) (entry))[-2])

/* The next one assumes 2's complement integers....*/
#define CLEAR_LOW_BIT(word)                     ((word) & ((unsigned long) -2))
#define OFFSET_WORD_CONTINUATION_P(word)        (((word) & 1) != 0)

#if (PC_ZERO_BITS == 0)
/* Instructions aligned on byte boundaries */
#define BYTE_OFFSET_TO_OFFSET_WORD(offset)      ((offset) << 1)
#define OFFSET_WORD_TO_BYTE_OFFSET(offset_word)                         \
  ((CLEAR_LOW_BIT(offset_word)) >> 1)
#endif

#if (PC_ZERO_BITS == 1)
/* Instructions aligned on word (16 bit) boundaries */
#define BYTE_OFFSET_TO_OFFSET_WORD(offset)      (offset)
#define OFFSET_WORD_TO_BYTE_OFFSET(offset_word)                         \
  (CLEAR_LOW_BIT(offset_word))
#endif

#if (PC_ZERO_BITS >= 2)
/* Should be OK for =2, but bets are off for >2 because of problems
   mentioned earlier!
*/
#define SHIFT_AMOUNT                            (PC_ZERO_BITS - 1)
#define BYTE_OFFSET_TO_OFFSET_WORD(offset)      ((offset) >> (SHIFT_AMOUNT))
#define OFFSET_WORD_TO_BYTE_OFFSET(offset_word)                         \
  ((CLEAR_LOW_BIT(offset_word)) << (SHIFT_AMOUNT))
#endif

#define MAKE_OFFSET_WORD(entry, block, continue)                        \
  ((BYTE_OFFSET_TO_OFFSET_WORD(((char *) (entry)) -                     \
                               ((char *) (block)))) |                   \
   ((continue) ? 1 : 0))

#if (EXECUTE_CACHE_ENTRY_SIZE == 2)
#define EXECUTE_CACHE_COUNT_TO_ENTRIES(count)                           \
  ((count) >> 1)
#define EXECUTE_CACHE_ENTRIES_TO_COUNT(entries)				\
  ((entries) << 1)
#endif

#if (EXECUTE_CACHE_ENTRY_SIZE == 4)
#define EXECUTE_CACHE_COUNT_TO_ENTRIES(count)                           \
  ((count) >> 2)
#define EXECUTE_CACHE_ENTRIES_TO_COUNT(entries)				\
  ((entries) << 2)
#endif

#if (!defined(EXECUTE_CACHE_COUNT_TO_ENTRIES))
#define EXECUTE_CACHE_COUNT_TO_ENTRIES(count)                           \
  ((count) / EXECUTE_CACHE_ENTRY_SIZE)
#define EXECUTE_CACHE_ENTRIES_TO_COUNT(entries)				\
  ((entries) * EXECUTE_CACHE_ENTRY_SIZE)
#endif

/* The first entry in a cc block is preceeded by 2 headers (block and nmv),
   a format word and a gc offset word.   See the early part of the
   TRAMPOLINE picture, above.
 */

#define CC_BLOCK_FIRST_ENTRY_OFFSET                                     \
  (2 * ((sizeof(SCHEME_OBJECT)) + (sizeof(format_word))))

/* Format words */

#define FORMAT_BYTE_EXPR                0xFF
#define FORMAT_BYTE_COMPLR              0xFE
#define FORMAT_BYTE_CMPINT              0xFD
#define FORMAT_BYTE_DLINK               0xFC
#define FORMAT_BYTE_RETURN              0xFB

#define FORMAT_WORD_EXPR        (MAKE_FORMAT_WORD(0xFF, FORMAT_BYTE_EXPR))
#define FORMAT_WORD_CMPINT      (MAKE_FORMAT_WORD(0xFF, FORMAT_BYTE_CMPINT))
#define FORMAT_WORD_RETURN      (MAKE_FORMAT_WORD(0xFF, FORMAT_BYTE_RETURN))

/* This assumes that a format word is at least 16 bits,
   and the low order field is always 8 bits.
 */

#define MAKE_FORMAT_WORD(field1, field2)                                \
  (((field1) << 8) | ((field2) & 0xff))

#define SIGN_EXTEND_FIELD(field, size)                                  \
  (((field) & ((1 << (size)) - 1)) |                                    \
   ((((field) & (1 << ((size) - 1))) == 0) ? 0 :                        \
    ((-1) << (size))))

#define FORMAT_WORD_LOW_BYTE(word)                                      \
  (SIGN_EXTEND_FIELD((((unsigned long) (word)) & 0xff), 8))

#define FORMAT_WORD_HIGH_BYTE(word)					\
  (SIGN_EXTEND_FIELD((((unsigned long) (word)) >> 8),			\
		     (((sizeof (format_word)) * CHAR_BIT) - 8)))

#define COMPILED_ENTRY_FORMAT_HIGH(addr)                                \
  (FORMAT_WORD_HIGH_BYTE(COMPILED_ENTRY_FORMAT_WORD(addr)))

#define COMPILED_ENTRY_FORMAT_LOW(addr)                                 \
  (FORMAT_WORD_LOW_BYTE(COMPILED_ENTRY_FORMAT_WORD(addr)))

#define FORMAT_BYTE_FRAMEMAX            0x7f

#define COMPILED_ENTRY_MAXIMUM_ARITY    COMPILED_ENTRY_FORMAT_LOW
#define COMPILED_ENTRY_MINIMUM_ARITY    COMPILED_ENTRY_FORMAT_HIGH

#endif /* CMPINT2_H_INCLUDED */
