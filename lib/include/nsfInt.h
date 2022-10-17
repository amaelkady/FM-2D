/*
 *  nsfInt.h --
 *
 *      Declarations of the internally used API Functions of the Next
 *      Scripting Framework.
 *
 *  Copyright (C) 1999-2017 Gustaf Neumann (a, b)
 *  Copyright (C) 1999-2007 Uwe Zdun (a, b)
 *  Copyright (C) 2011-2017 Stefan Sobernig (b)
 *
 * (a) University of Essen
 *     Specification of Software Systems
 *     Altendorferstrasse 97-101
 *     D-45143 Essen, Germany
 *
 * (b) Vienna University of Economics and Business
 *     Institute of Information Systems and New Media
 *     A-1020, Welthandelsplatz 1
 *     Vienna, Austria
 *
 * This work is licensed under the MIT License
 * http://www.opensource.org/licenses/MIT
 *
 * Copyright:
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 *
 */

#ifndef _nsf_int_h_
#define _nsf_int_h_

#if defined(HAVE_STDINT_H)
# define HAVE_INTPTR_T
# define HAVE_UINTPTR_T
#endif

/*
 * Well behaved compiler with C99 support should define __STDC_VERSION__
 */
#if defined(__STDC_VERSION__)
# if __STDC_VERSION__ >= 199901L
#  define NSF_HAVE_C99
# endif
#endif

/*
 * Starting with Visual Studio 2013, Microsoft provides C99 library support.
 */
#if (!defined(NSF_HAVE_C99)) && defined(_MSC_VER) && (_MSC_VER >= 1800)
# define NSF_HAVE_C99
#endif

/*
 * Boolean type "bool" and constants
 */
#ifdef NSF_HAVE_C99
   /*
    * C99
    */
# include <stdbool.h>
# define NSF_TRUE                    true
# define NSF_FALSE                   false
#else
   /*
    * Not C99
    */
# if defined(__cplusplus)
   /*
    * C++ is similar to C99, but no include necessary
    */
#  define NSF_TRUE                    true
#  define NSF_FALSE                   false
# else
   /*
    * If everything fails, use int type and int values for bool
    */
typedef int bool;
#  define NSF_TRUE                    1
#  define NSF_FALSE                   0
# endif
#endif


/*
 * MinGW and MinGW-w64 provide both MSCRT-compliant and ANSI-compliant
 * implementations of certain I/O operations (e.g., *printf()). By
 * setting __USE_MINGW_ANSI_STDIO to 1 explicitly, we can assume the
 * ANSI versions.
 *
 * Note: It is sufficient to test for __MINGW32__ to trap all MinGW
 * tool chains, including 64bit versions. See
 * http://sourceforge.net/p/predef/wiki/Compilers/#mingw-and-mingw-w64
 */

#if defined(__MINGW32__) && !defined(__USE_MINGW_ANSI_STDIO)
# define __USE_MINGW_ANSI_STDIO 1
#endif

#include <tclInt.h>
#include "nsf.h"

#include <stdlib.h>
#include <string.h>
#include <assert.h>

#if defined(HAVE_TCL_COMPILE_H)
# include <tclCompile.h>
#endif

#if __GNUC_PREREQ(2, 95)
/* Use gcc branch prediction hint to minimize cost of e.g. DTrace
 * ENABLED checks.
 */
#  define unlikely(x) (__builtin_expect((x), 0))
#  define likely(x) (__builtin_expect((x), 1))
#else
#  define unlikely(x) (x)
#  define likely(x) (x)
#endif

#if __GNUC_PREREQ(2, 96)
# define pure __attribute__((pure))
#else
# define pure
#endif

#if __GNUC_PREREQ(3, 3)
# define nonnull(ARGS) __attribute__((__nonnull__(ARGS)))
#else
# define nonnull(ARGS)
#endif

#if __GNUC_PREREQ(4, 9)
# define returns_nonnull __attribute__((returns_nonnull))
#else
# define returns_nonnull
#endif

#define nonnull_assert(assertion) assert((assertion))
/*
 * Tries to use gcc __attribute__ unused and mangles the name, so the
 * attribute could not be used, if declared as unused.
 */
#ifdef UNUSED
#elif __GNUC_PREREQ(2, 7)
# define UNUSED(x) UNUSED_ ## x __attribute__((unused))
#elif defined(__LCLINT__)
# define UNUSED(x) /*@unused@*/ (x)
#else
# define UNUSED(x) (x)
#endif

#if defined(NSF_DTRACE)
# include "nsfDTrace.h"
# define NSF_DTRACE_METHOD_ENTRY_ENABLED()		unlikely(NSF_METHOD_ENTRY_ENABLED())
# define NSF_DTRACE_METHOD_RETURN_ENABLED()		unlikely(NSF_METHOD_RETURN_ENABLED())
# define NSF_DTRACE_OBJECT_ALLOC_ENABLED()		unlikely(NSF_OBJECT_ALLOC_ENABLED())
# define NSF_DTRACE_OBJECT_FREE_ENABLED()		unlikely(NSF_OBJECT_FREE_ENABLED())
# define NSF_DTRACE_CONFIGURE_PROBE_ENABLED()		unlikely(NSF_CONFIGURE_PROBE_ENABLED())
# define NSF_DTRACE_METHOD_ENTRY(a0, a1, a2, a3, a4)	NSF_METHOD_ENTRY((a0), (a1), (a2), (a3), (a4))
# define NSF_DTRACE_METHOD_RETURN(a0, a1, a2, a3)	NSF_METHOD_RETURN((a0), (a1), (a2), (a3))
# define NSF_DTRACE_OBJECT_ALLOC(a0, a1)		NSF_OBJECT_ALLOC((a0), (a1))
# define NSF_DTRACE_OBJECT_FREE(a0, a1)		NSF_OBJECT_FREE((a0), (a1))
# define NSF_DTRACE_CONFIGURE_PROBE(a0, a1)		NSF_CONFIGURE_PROBE((a0), (a1))
#else
# define NSF_DTRACE_METHOD_ENTRY_ENABLED()		0
# define NSF_DTRACE_METHOD_RETURN_ENABLED()		0
# define NSF_DTRACE_OBJECT_ALLOC_ENABLED()		0
# define NSF_DTRACE_OBJECT_FREE_ENABLED()		0
# define NSF_DTRACE_CONFIGURE_PROBE_ENABLED()		0
# define NSF_DTRACE_METHOD_ENTRY(a0, a1, a2, a3, a4)	{}
# define NSF_DTRACE_METHOD_RETURN(a0, a1, a2, a3)	{}
# define NSF_DTRACE_OBJECT_ALLOC(a0, a1)		{}
# define NSF_DTRACE_OBJECT_FREE(a0, a1)		{}
# define NSF_DTRACE_CONFIGURE_PROBE(a0, a1)		{}
#endif


#ifdef DMALLOC
#  include "dmalloc.h"
#endif

/*
 * Makros
 */

#if defined(PRE86)
# define Tcl_NRCallObjProc(interp, proc, cd, objc, objv) \
  (*(proc))((cd), (interp), (objc), (objv))
#endif

#ifdef NSF_MEM_COUNT
EXTERN int nsfMemCountInterpCounter;
typedef struct NsfMemCounter {
  int peak;
  int count;
} NsfMemCounter;
#  define MEM_COUNT_ALLOC(id,p) NsfMemCountAlloc((id), (p))
#  define MEM_COUNT_FREE(id,p) NsfMemCountFree((id), (p))
#  define MEM_COUNT_INIT() NsfMemCountInit()
#  define MEM_COUNT_RELEASE() NsfMemCountRelease()
#else
#  define MEM_COUNT_ALLOC(id,p)
#  define MEM_COUNT_FREE(id,p)
#  define MEM_COUNT_INIT()
#  define MEM_COUNT_RELEASE()
#endif

# define STRING_NEW(target, p, l)  {char *tempValue = ckalloc((unsigned)(l)+1u); strncpy((tempValue), (p), (l)+1u); *((tempValue)+(l)) = '\0'; target = tempValue; MEM_COUNT_ALLOC(#target, (target));}
# define STRING_FREE(key, p)  MEM_COUNT_FREE((key), (p)); ckfree((char*)(p))

#define DSTRING_INIT(dsPtr) Tcl_DStringInit(dsPtr); MEM_COUNT_ALLOC("DString",(dsPtr))
#define DSTRING_FREE(dsPtr) \
  if ((dsPtr)->string != (dsPtr)->staticSpace) {Tcl_DStringFree(dsPtr);} MEM_COUNT_FREE("DString",(dsPtr))

#if defined(USE_ASSOC_DATA)
# define RUNTIME_STATE(interp) ((NsfRuntimeState*)Tcl_GetAssocData((interp), "NsfRuntimeState", NULL))
#else
# define RUNTIME_STATE(interp) ((NsfRuntimeState*)((Interp*)(interp))->globalNsPtr->clientData)
#endif

#define nr_elements(arr)  ((int) (sizeof(arr) / sizeof((arr)[0])))

/*
 * Tcl 8.6 uses (unsigned) per default
 */
# define NEW(type) \
  (type *)ckalloc((unsigned)sizeof(type)); MEM_COUNT_ALLOC(#type, NULL)
# define NEW_ARRAY(type,n) \
  (type *)ckalloc((unsigned)sizeof(type)*(unsigned)(n)); MEM_COUNT_ALLOC(#type "*", NULL)
# define FREE(type, var) \
  ckfree((char*) (var)); MEM_COUNT_FREE(#type,(var))

#define isAbsolutePath(m) (*(m) == ':' && (m)[1] == ':')
#define isArgsString(m) (\
	*(m)   == 'a' && (m)[1] == 'r' && (m)[2] == 'g' && (m)[3] == 's' && \
	(m)[4] == '\0')
#define isBodyString(m) (\
	*(m)   == 'b' && (m)[1] == 'o' && (m)[2] == 'd' && (m)[3] == 'y' && \
	(m)[4] == '\0')
#define isCheckString(m) (\
	*(m)   == 'c' && (m)[1] == 'h' && (m)[2] == 'e' && (m)[3] == 'c' && \
	(m)[4] == 'k' && (m)[5] == '\0')
#define isCheckObjString(m) (\
	*(m)   == 'c' && (m)[1] == 'h' && (m)[2] == 'e' && (m)[3] == 'c' && \
	(m)[4] == 'k' && (m)[5] == 'o' && (m)[6] == 'b' && (m)[7] == 'j' && \
	(m)[8] == '\0')
#define isCreateString(m) (\
	*(m)   == 'c' && (m)[1] == 'r' && (m)[2] == 'e' && (m)[3] == 'a' && \
	(m)[4] == 't' && (m)[5] == 'e' && (m)[6] == '\0')
#define isTypeString(m) (\
	*(m)   == 't' && (m)[1] == 'y' && (m)[2] == 'p' && (m)[3] == 'e' && \
	(m)[4] == '\0')
#define isObjectString(m) (\
	*(m)   == 'o' && (m)[1] == 'b' && (m)[2] == 'j' && (m)[3] == 'e' && \
	(m)[4] == 'c' && (m)[5] == 't' && (m)[6] == '\0')
#define isClassString(m) (\
	*(m)   == 'c' && (m)[1] == 'l' && (m)[2] == 'a' && (m)[3] == 's' && \
	(m)[4] == 's' && (m)[5] == '\0')

#if (defined(sun) || defined(__hpux)) && !defined(__GNUC__)
#  define USE_ALLOCA
#endif

#if defined(__IBMC__) && !defined(__GNUC__)
# if __IBMC__ >= 0x0306
#  define USE_ALLOCA
# else
#  define USE_MALLOC
# endif
#endif

#if defined(VISUAL_CC)
#  define USE_MALLOC
#endif

#if defined(__GNUC__) && !defined(USE_ALLOCA) && !defined(USE_MALLOC)
# if !defined(NDEBUG)
#  define ALLOC_ON_STACK(type,n,var) \
  int __##var##_count = (n); type __##var[(n)+2];			\
  type *(var) = __##var + 1; (var)[-1] = var[__##var##_count] = (type)0xdeadbeaf
#  define FREE_ON_STACK(type,var)                                       \
  assert((var)[-1] == (var)[__##var##_count] && (var)[-1] == (type)0xdeadbeaf)
# else
#  define ALLOC_ON_STACK(type,n,var) type (var)[(n)]
#  define FREE_ON_STACK(type,var)
# endif
#elif defined(USE_ALLOCA)
#  define ALLOC_ON_STACK(type,n,var) type *(var) = (type *)alloca((n)*sizeof(type))
#  define FREE_ON_STACK(type,var)
#else
#  define ALLOC_ON_STACK(type,n,var) type *(var) = (type *)ckalloc((n)*sizeof(type))
#  define FREE_ON_STACK(type,var) ckfree((char*)(var))
#endif

#ifdef USE_ALLOCA
# include <alloca.h>
#endif

#if !defined(NDEBUG)
# define ISOBJ(o) ((o) != NULL && ISOBJ_(o))
# define ISOBJ_(o) ((o) != (void*)0xdeadbeaf && (((o)->typePtr != NULL) ? ((o)->typePtr->name != NULL) : ((o)->bytes != NULL)) && (((o)->bytes != NULL) ? (o)->length >= -1 : 1) && (o)->refCount >= 0)
#else
# define ISOBJ(o)
#endif

#define NSF_ABBREV_MIN_CHARS 4
/*
 * This was defined to be inline for anything !sun or __IBMC__ >= 0x0306,
 * but __hpux should also be checked - switched to only allow in gcc - JH
 */
#if defined(__GNUC__) && !defined(__STRICT_ANSI__)
# define NSF_INLINE inline
#else
# define NSF_INLINE
#endif

#ifdef USE_TCL_STUBS
# define DECR_REF_COUNT(A) \
  MEM_COUNT_FREE("INCR_REF_COUNT" #A,(A)); assert((A)->refCount > -1);	\
  Tcl_DecrRefCount(A)
# define DECR_REF_COUNT2(name,A)					\
  MEM_COUNT_FREE("INCR_REF_COUNT-" name,(A)); assert((A)->refCount > -1); \
  Tcl_DecrRefCount(A)
#else
# define DECR_REF_COUNT(A) \
  MEM_COUNT_FREE("INCR_REF_COUNT" #A,(A)); TclDecrRefCount(A)
# define DECR_REF_COUNT2(name,A)				\
  MEM_COUNT_FREE("INCR_REF_COUNT-" name,(A)); TclDecrRefCount(A)
#endif

#define INCR_REF_COUNT(A) MEM_COUNT_ALLOC("INCR_REF_COUNT" #A,(A)); Tcl_IncrRefCount((A))
#define INCR_REF_COUNT2(name,A) \
  /*fprintf(stderr, "c '%s'\n", ObjStr(A));*/				\
  MEM_COUNT_ALLOC("INCR_REF_COUNT-" name,(A)); Tcl_IncrRefCount((A))

#define ObjStr(obj) ((obj)->bytes) ? ((obj)->bytes) : Tcl_GetString(obj)
#define ObjTypeStr(obj) (((obj)->typePtr != NULL) ? ((obj)->typePtr->name) : "NONE")
#define ClassName(cl) (((cl) != NULL) ? ObjStr((cl)->object.cmdName) : "NULL")
#define ClassName_(cl) (ObjStr((cl)->object.cmdName))
#define ObjectName(obj) (((obj) != NULL) ? ObjStr((obj)->cmdName) : "NULL")
#define ObjectName_(obj) (ObjStr((obj)->cmdName))

#ifdef OBJDELETION_TRACE
# define PRINTOBJ(ctx,obj) \
  fprintf(stderr, "  %s %p %s oid=%p teardown=%p destroyCalled=%d\n", \
	  (ctx),(obj),(obj)->teardown?ObjStr((obj)->cmdName):"(deleted)", \
	  (obj)->id, (obj)->teardown,                                 \
	  ((obj)->flags & NSF_DESTROY_CALLED))
#else
# define PRINTOBJ(ctx,obj)
#endif

/*
 * When an integer is printed, it might take so many digits
 */
#define LONG_AS_STRING 32

/* TCL_CONTINUE is defined as 4, from 5 on we can
   use app-specific return codes */
#define NSF_CHECK_FAILED 6


/*
  The NsfConfigEnabled() macro allows for querying whether a
  configuration macro (NSF_*; see above) is actually defined (and
  whether it expands to 1). This macro can be used both in CPP
  expressions (e.g., "#if NsfConfigEnabled(...)") and in C expressions
  (e.g., "if(NsfConfigEnabled(...))")
*/

#define NsfConfigEnabled__NOOP(...)
#define NsfConfigEnabled__open (
#define NsfConfigEnabled__close )
#define NsfConfigEnabled__caller(macro, args) macro args
#define NsfConfigEnabled__helper_1 NsfConfigEnabled__close NsfConfigEnabled__open 1
#define NsfConfigEnabled__(x) (NsfConfigEnabled__caller(NsfConfigEnabled__NOOP, \
						       NsfConfigEnabled__open \
						       NsfConfigEnabled__helper_##x \
						       NsfConfigEnabled__close) + 0)
#define NsfConfigEnabled_(x) NsfConfigEnabled__(x)
#define NsfConfigEnabled(x) NsfConfigEnabled_(NSF_##x)


/*
 *
 * Next Scripting Structures
 *
 */

/*
 * Filter structures
 */
typedef struct NsfFilterStack {
  Tcl_Command currentCmdPtr;
  Tcl_Obj *calledProc;
  struct NsfFilterStack *nextPtr;
} NsfFilterStack;


/*
 * Assertion structures
 */

typedef struct NsfTclObjList {
  Tcl_Obj *content;
  Tcl_Obj *payload;
  struct NsfTclObjList *nextPtr;
} NsfTclObjList;

typedef struct NsfProcAssertion {
  NsfTclObjList *pre;
  NsfTclObjList *post;
} NsfProcAssertion;

typedef struct NsfAssertionStore {
  NsfTclObjList *invariants;
  Tcl_HashTable procs;
} NsfAssertionStore;

typedef enum { /* powers of 2; add to ALL, if default; */
  CHECK_NONE     = 0,
  CHECK_CLINVAR  = 1,
  CHECK_OBJINVAR = 2,
  CHECK_PRE      = 4,
  CHECK_POST     = 8,
  CHECK_INVAR    = CHECK_CLINVAR + CHECK_OBJINVAR,
  CHECK_ALL      = CHECK_INVAR   + CHECK_PRE + CHECK_POST
} CheckOptions;

void NsfAssertionRename(Tcl_Interp *interp, Tcl_Command cmd,
			  NsfAssertionStore *as,
			  char *oldSimpleCmdName, char *newName);
/*
 * mixins
 */
typedef struct NsfMixinStack {
  Tcl_Command currentCmdPtr;
  struct NsfMixinStack *nextPtr;
} NsfMixinStack;

/*
 * Generic command pointer list
 */
typedef struct NsfCmdList {
  Tcl_Command cmdPtr;
  ClientData clientData;
  struct NsfClass *clorobj;
  struct NsfCmdList *nextPtr;
} NsfCmdList;

typedef void (NsfFreeCmdListClientData) (NsfCmdList*);

/* for incr string */
typedef struct NsfStringIncrStruct {
  char *buffer;
  char *start;
  size_t bufSize;
  size_t length;
} NsfStringIncrStruct;


/*
 * cmd flags
 */

#define NSF_CMD_CALL_PROTECTED_METHOD		0x00010000
#define NSF_CMD_CALL_PRIVATE_METHOD		0x00020000
#define NSF_CMD_REDEFINE_PROTECTED_METHOD	0x00040000
/* NSF_CMD_NONLEAF_METHOD is used to flag, if a Method implemented via cmd calls "next" */
#define NSF_CMD_NONLEAF_METHOD			0x00080000
#define NSF_CMD_CLASS_ONLY_METHOD		0x00100000
#define NSF_CMD_DEPRECATED_METHOD		0x00200000
#define NSF_CMD_DEBUG_METHOD			0x00400000

/*
 * traceEvalFlags controlling NsfDStringEval
 */
#define NSF_EVAL_SAVE                    0x01u  /* save interp context */
#define NSF_EVAL_NOPROFILE               0x02u  /* no profile below this call */
#define NSF_EVAL_DEBUG                   0x04u  /* call is a debug call, prevent recursion */
#define NSF_EVAL_LOG                     0x08u  /* call is a log call, prevent recursion */
#define NSF_EVAL_DEPRECATED              0x10u  /* call is a deprecated call, prevent recursion */

#define NSF_EVAL_PREVENT_RECURSION (NSF_EVAL_DEBUG|NSF_EVAL_LOG|NSF_EVAL_DEPRECATED)

/*
 * object flags ...
 */

/* DESTROY_CALLED indicates that destroy was called on obj */
#define NSF_DESTROY_CALLED                 0x0001u
/* INIT_CALLED indicates that init was called on obj */
#define NSF_INIT_CALLED                    0x0002u
/* MIXIN_ORDER_VALID set when mixin order is valid */
#define NSF_MIXIN_ORDER_VALID              0x0004u
/* MIXIN_ORDER_DEFINED set, when mixins are defined for obj */
#define NSF_MIXIN_ORDER_DEFINED            0x0008u
#define NSF_MIXIN_ORDER_DEFINED_AND_VALID  0x000cu
/* FILTER_ORDER_VALID set, when filter order is valid */
#define NSF_FILTER_ORDER_VALID             0x0010u
/* FILTER_ORDER_DEFINED set, when filters are defined for obj */
#define NSF_FILTER_ORDER_DEFINED           0x0020u
#define NSF_FILTER_ORDER_DEFINED_AND_VALID 0x0030u
/* class and object properties for objects */
#define NSF_IS_CLASS                       0x0040u
#define NSF_IS_ROOT_META_CLASS             0x0080u
#define NSF_IS_ROOT_CLASS                  0x0100u
#define NSF_IS_SLOT_CONTAINER              0x0200u
#define NSF_KEEP_CALLER_SELF               0x0400u
#define NSF_PER_OBJECT_DISPATCH            0x0800u
#define NSF_HAS_PER_OBJECT_SLOTS           0x1000u
/* deletion states */
#define NSF_DESTROY_CALLED_SUCCESS       0x010000u /* requires flags to be int, not short */
#define NSF_DURING_DELETE                0x020000u
#define NSF_DELETED                      0x040000u
#define NSF_RECREATE                     0x080000u
#define NSF_TCL_DELETE                   0x100000u


/* method invocations */
#define NSF_ARG_METHOD_INVOCATION	     (NSF_ARG_ALIAS|NSF_ARG_FORWARD|NSF_ARG_INITCMD|NSF_ARG_CMD)
#define NSF_ARG_METHOD_CALL		     (NSF_ARG_ALIAS|NSF_ARG_FORWARD)

/* Disallowed parameter options */
#define NSF_DISALLOWED_ARG_METHOD_PARAMETER  (NSF_ARG_METHOD_INVOCATION|NSF_ARG_NOCONFIG|NSF_ARG_SLOTSET|NSF_ARG_SLOTINITIALIZE)
#define NSF_DISALLOWED_ARG_SETTER	     (NSF_ARG_SWITCH|NSF_ARG_SUBST_DEFAULT|NSF_DISALLOWED_ARG_METHOD_PARAMETER)
/*#define NSF_DISALLOWED_ARG_OBJECT_PARAMETER  (NSF_ARG_SWITCH)*/
#define NSF_DISALLOWED_ARG_OBJECT_PARAMETER  0
#define NSF_DISALLOWED_ARG_VALUECHECK	     (NSF_ARG_SUBST_DEFAULT|NSF_ARG_METHOD_INVOCATION|NSF_ARG_SWITCH|NSF_ARG_CURRENTLY_UNKNOWN|NSF_ARG_SLOTSET|NSF_ARG_SLOTINITIALIZE)

/* flags for ParseContext */
#define NSF_PC_MUST_DECR		     0x0001u
#define NSF_PC_IS_DEFAULT		     0x0002u
#define NSF_PC_INVERT_DEFAULT		     0x0010u

#define NSF_PC_STATUS_MUST_DECR		     0x0001u
#define NSF_PC_STATUS_FREE_OBJV		     0x0002u
#define NSF_PC_STATUS_FREE_CD		     0x0004u


/* method types */
#define NSF_METHODTYPE_ALIAS     0x0001
#define NSF_METHODTYPE_SCRIPTED  0x0002
#define NSF_METHODTYPE_SETTER    0x0004
#define NSF_METHODTYPE_FORWARDER 0x0008
#define NSF_METHODTYPE_OBJECT    0x0010
#define NSF_METHODTYPE_NSFPROC   0x0020
#define NSF_METHODTYPE_OTHER     0x0100
#define NSF_METHODTYPE_BUILTIN   NSF_METHODTYPE_ALIAS|NSF_METHODTYPE_SETTER|NSF_METHODTYPE_FORWARDER|NSF_METHODTYPE_OTHER
#define NSF_METHODTYPE_ALL       NSF_METHODTYPE_SCRIPTED|NSF_METHODTYPE_BUILTIN|NSF_METHODTYPE_OBJECT


#define NsfObjectSetClass(obj) \
	(obj)->flags |= NSF_IS_CLASS
#define NsfObjectClearClass(obj) \
	(obj)->flags &= ~NSF_IS_CLASS
#define NsfObjectIsClass(obj) \
	((obj)->flags & NSF_IS_CLASS)
#define NsfObjectToClass(obj) \
	(NsfClass *)((((NsfObject *)obj)->flags & NSF_IS_CLASS) ? obj : NULL)


/*
 * object and class internals
 */

typedef struct NsfParamDefs {
  Nsf_Param *paramsPtr;
  int nrParams;
  int refCount;
  int serial;
} NsfParamDefs;

typedef struct NsfParsedParam {
  NsfParamDefs *paramDefs;
  int possibleUnknowns;
} NsfParsedParam;

typedef struct NsfObjectOpt {
  NsfAssertionStore *assertions;
  NsfCmdList *objFilters;
  NsfCmdList *objMixins;
  ClientData clientData;
  const char *volatileVarName;
#if defined(PER_OBJECT_PARAMETER_CACHING)
  NsfParsedParam *parsedParamPtr;
  unsigned int classParamPtrEpoch;
#endif
  CheckOptions checkoptions;
} NsfObjectOpt;

typedef struct NsfObject {
  Tcl_Obj *cmdName;
  Tcl_Command id;
  Tcl_Interp *teardown;
  struct NsfClass *cl;
  TclVarHashTable *varTablePtr;
  Tcl_Namespace *nsPtr;
  NsfObjectOpt *opt;
  struct NsfCmdList *filterOrder;
  struct NsfCmdList *mixinOrder;
  NsfFilterStack *filterStack;
  NsfMixinStack *mixinStack;
  int refCount;
  unsigned int flags;
  short activationCount;
} NsfObject;

typedef struct NsfClassOpt {
  NsfCmdList *classFilters;
  NsfCmdList *classMixins;
  NsfCmdList *isObjectMixinOf;
  NsfCmdList *isClassMixinOf;
  NsfAssertionStore *assertions;
  Tcl_Obj *mixinRegObjs;
#ifdef NSF_OBJECTDATA
  Tcl_HashTable *objectdata;
#endif
  Tcl_Command id;
  ClientData clientData;
} NsfClassOpt;

typedef struct NsfClass {
  struct NsfObject        object;
  struct NsfClasses      *super;
  struct NsfClasses      *sub;
  struct NsfObjectSystem *osPtr;
  struct NsfClasses      *order;
  Tcl_HashTable           instances;
  Tcl_Namespace          *nsPtr;
  NsfParsedParam         *parsedParamPtr;
  NsfClassOpt            *opt;
  short                   color;
} NsfClass;

typedef struct NsfClasses {
  struct NsfClass   *cl;
  ClientData         clientData;
  struct NsfClasses *nextPtr;
} NsfClasses;

/*
 * needed in nsf.c and in nsfShadow
 */
#define NSF_PROC_FLAG_AD           0x01u
#define NSF_PROC_FLAG_CHECK_ALWAYS 0x02u

typedef struct NsfProcClientData {
  Tcl_Obj       *procName;
  Tcl_Command    cmd;
  Tcl_Command    wrapperCmd;
  NsfParamDefs  *paramDefs;
  Tcl_Namespace *origNsPtr;
  unsigned int   flags;
} NsfProcClientData;

typedef enum SystemMethodsIdx {
  NSF_c_alloc_idx,
  NSF_c_create_idx,
  NSF_c_dealloc_idx,
  NSF_c_configureparameter_idx,
  NSF_c_recreate_idx,
  NSF_o_cleanup_idx,
  NSF_o_configure_idx,
  NSF_o_configureparameter_idx,
  NSF_o_defaultmethod_idx,
  NSF_o_destroy_idx,
  NSF_o_init_idx,
  NSF_o_move_idx,
  NSF_o_unknown_idx,
  NSF_s_get_idx,
  NSF_s_set_idx
} SystemMethodsIdx;

#if !defined(NSF_C)
EXTERN const char *Nsf_SystemMethodOpts[];
#else
const char *Nsf_SystemMethodOpts[] = {
  "-class.alloc",
  "-class.create",
  "-class.dealloc",
  "-class.configureparameter",
  "-class.recreate",
  "-object.cleanup",
  "-object.configure",
  "-object.configureparameter",
  "-object.defaultmethod",
  "-object.destroy",
  "-object.init",
  "-object.move",
  "-object.unknown",
  "-slot.get",
  "-slot.set",
  NULL
};
#endif

typedef struct NsfObjectSystem {
  NsfClass     *rootClass;
  NsfClass     *rootMetaClass;
  unsigned int  overloadedMethods;
  unsigned int  definedMethods;
  Tcl_Obj      *methods[NSF_s_set_idx+2];
  const char   *methodNames[NSF_s_set_idx+2];
  Tcl_Obj      *handles[NSF_s_set_idx+2];
  struct NsfObjectSystem *nextPtr;
  char          protected[NSF_s_set_idx+2];
} NsfObjectSystem;


/*
 * Next Scripting global names and strings
 *
 * We provide enums for efficient lookup for corresponding string
 * names and Tcl_Objs via global arrays. The "constant" Tcl_Objs are
 * built at start-up-time via Nsf_Init().
 */

typedef enum {
  NSF_EMPTY, NSF_ZERO, NSF_ONE,
  /* methods called internally */
  NSF_CONFIGURE, NSF_INITIALIZE, NSF_GET_PARAMETER_SPEC,
  NSF_SLOT_GET, NSF_SLOT_SET,
  /* var names */
  NSF_AUTONAMES, NSF_DEFAULTMETACLASS, NSF_DEFAULTSUPERCLASS,
  NSF_ARRAY_INITCMD, NSF_ARRAY_CMD,
  NSF_ARRAY_ALIAS, NSF_ARRAY_PARAMETERSYNTAX,
  NSF_POSITION, NSF_POSITIONAL, NSF_CONFIGURABLE, NSF_PARAMETERSPEC,
  /* object/class names */
  NSF_METHOD_PARAMETER_SLOT_OBJ,
  /* constants */
  NSF_ALIAS, NSF_ARGS, NSF_CMD, NSF_FILTER, NSF_FORWARD,
  NSF_METHOD,  NSF_OBJECT, NSF_SETTER, NSF_SETTERNAME, NSF_VALUECHECK,
  NSF_GUARD_OPTION, NSF___UNKNOWN__, NSF_ARRAY, NSF_GET, NSF_SET, NSF_OPTION_STRICT, NSF_SCRIPT,
  NSF_OBJECT_UNKNOWN_HANDLER, NSF_ARGUMENT_UNKNOWN_HANDLER,
  NSF_PARSE_ARGS,
  /* Partly redefined Tcl commands; leave them together at the end */
  NSF_EXPR, NSF_FORMAT, NSF_INFO_BODY, NSF_INFO_FRAME, NSF_INTERP,
  NSF_STRING_IS, NSF_EVAL, NSF_DISASSEMBLE,
  NSF_RENAME 
} NsfGlobalNames;
#if !defined(NSF_C)
EXTERN const char *NsfGlobalStrings[];
#else
const char *NsfGlobalStrings[] = {
  "", "0", "1",
  /* methods called internally */
  "configure", "initialize", "getParameterSpec",
  "value=get", "value=set",
  /* var names */
  "__autonames", "__default_metaclass", "__default_superclass", "__initcmd", "__cmd",
  "::nsf::alias", "::nsf::parameter::syntax",
  "position", "positional", "configurable", "parameterSpec",
  /* object/class names */
  "::nx::methodParameterSlot",
  /* constants */
  "alias", "args", "cmd", "filter",  "forward",
  "method", "object", "setter", "settername", "valuecheck",
  "-guard", "__unknown__", "::array", "get", "set", "-strict", "script",
  /* nsf Tcl commands */
  "::nsf::object::unknown",
  "::nsf::argument::unknown",
  "::nsf::parseargs",
  /* Tcl commands */
  "expr", "format", "::tcl::info::body", "::tcl::info::frame", "interp",
  "::tcl::string::is", "::eval", "::tcl::unsupported::disassemble",
  "rename"
};
#endif

#define NsfGlobalObjs RUNTIME_STATE(interp)->methodObjNames

/* 
 * Interface for Tcl_Obj types 
 */
EXTERN Tcl_ObjType NsfMixinregObjType;
EXTERN int NsfMixinregGet(Tcl_Interp *interp, Tcl_Obj *obj, NsfClass **classPtr, Tcl_Obj **guardObj)
  nonnull(1) nonnull(2) nonnull(3) nonnull(4);
EXTERN int NsfMixinregInvalidate(Tcl_Interp *interp, Tcl_Obj *obj)
  nonnull(1) nonnull(2);

EXTERN Tcl_ObjType NsfFilterregObjType;
EXTERN int NsfFilterregGet(Tcl_Interp *interp, Tcl_Obj *obj, Tcl_Obj **filterObj, Tcl_Obj **guardObj)
  nonnull(1) nonnull(2) nonnull(3) nonnull(4);

EXTERN NsfClassOpt *NsfRequireClassOpt(NsfClass *class)
  nonnull(1) returns_nonnull;


/* 
 * Next Scripting ShadowTclCommands 
 */
typedef struct NsfShadowTclCommandInfo {
  TclObjCmdProcType proc;
  ClientData clientData;
  int nrArgs;
} NsfShadowTclCommandInfo;
typedef enum {SHADOW_LOAD=1, SHADOW_UNLOAD=0, SHADOW_REFETCH=2} NsfShadowOperations;


typedef enum {NSF_PARAMS_NAMES, NSF_PARAMS_LIST,
	      NSF_PARAMS_PARAMETER, NSF_PARAMS_SYNTAX} NsfParamsPrintStyle;

int NsfCallCommand(Tcl_Interp *interp, NsfGlobalNames name,
		     int objc, Tcl_Obj *const objv[])
  nonnull(1) nonnull(4);

int NsfShadowTclCommands(Tcl_Interp *interp, NsfShadowOperations load)
  nonnull(1);

Tcl_Obj *NsfMethodObj(const NsfObject *object, int methodIdx)
  nonnull(1) pure;

int NsfReplaceCommandCleanup(Tcl_Interp *interp, Tcl_Obj *nameObj, NsfShadowTclCommandInfo *ti)
  nonnull(1) nonnull(2) nonnull(3);

int NsfReplaceCommand(Tcl_Interp *interp, Tcl_Obj *nameObj,
		      Tcl_ObjCmdProc *nsfReplacementProc,
		      ClientData cd,
		      NsfShadowTclCommandInfo *ti)
  nonnull(1) nonnull(2) nonnull(5);


/*
 * Next Scripting CallStack
 */
typedef struct NsfCallStackContent {
  NsfObject *self;
  NsfClass *cl;
  Tcl_Command cmdPtr;
  NsfFilterStack *filterStackEntry;
  Tcl_Obj *const* objv;
  int objc;
  unsigned int flags;
#if defined(NSF_PROFILE) || defined(NSF_DTRACE)
  long int startUsec;
  long int startSec;
  const char *methodName;
#endif
  unsigned short frameType;
} NsfCallStackContent;

#define NSF_CSC_TYPE_PLAIN                    0u
#define NSF_CSC_TYPE_ACTIVE_MIXIN             1u
#define NSF_CSC_TYPE_ACTIVE_FILTER            2u
#define NSF_CSC_TYPE_INACTIVE                 4u
#define NSF_CSC_TYPE_INACTIVE_MIXIN           5u
#define NSF_CSC_TYPE_INACTIVE_FILTER          6u
#define NSF_CSC_TYPE_GUARD                 0x10u
#define NSF_CSC_TYPE_ENSEMBLE              0x20u

#define NSF_CSC_CALL_IS_NEXT                  1u
#define NSF_CSC_CALL_IS_GUARD                 2u
#define NSF_CSC_CALL_IS_ENSEMBLE              4u
#define NSF_CSC_CALL_IS_COMPILE               8u


#define NSF_CSC_IMMEDIATE           0x000000100u
#define NSF_CSC_FORCE_FRAME         0x000000200u
#define NSF_CSC_CALL_NO_UNKNOWN     0x000000400u
#define NSF_CSC_CALL_IS_NRE         0x000002000u
#define NSF_CSC_MIXIN_STACK_PUSHED  0x000004000u
#define NSF_CSC_FILTER_STACK_PUSHED 0x000008000u
#define NSF_CSC_METHOD_IS_UNKNOWN   0x000010000u

/* flags for call method */
#define NSF_CM_NO_UNKNOWN           0x000000001u
#define NSF_CM_NO_SHIFT             0x000000002u
#define NSF_CM_IGNORE_PERMISSIONS   0x000000004u
#define NSF_CM_NO_OBJECT_METHOD     0x000000008u
#define NSF_CM_SYSTEM_METHOD        0x000000010u
#define NSF_CM_LOCAL_METHOD         0x000000020u
#define NSF_CM_INTRINSIC_METHOD     0x000000040u
#define NSF_CM_KEEP_CALLER_SELF     0x000000080u
#define NSF_CM_ENSEMBLE_UNKNOWN     0x008000000u


#define NSF_CSC_COPY_FLAGS          (NSF_CSC_MIXIN_STACK_PUSHED|NSF_CSC_FILTER_STACK_PUSHED|NSF_CSC_IMMEDIATE|NSF_CSC_FORCE_FRAME|NSF_CM_LOCAL_METHOD)

#define NSF_VAR_TRIGGER_TRACE    1
#define NSF_VAR_REQUIRE_DEFINED  2
#define NSF_VAR_ISARRAY          4

/*
 * Tcl uses 01 and 02, TclOO uses 04 and 08, so leave some space free
 * for further extensions of Tcl and tcloo...
 */
#define FRAME_IS_NSF_OBJECT  0x10000u
#define FRAME_IS_NSF_METHOD  0x20000u
#define FRAME_IS_NSF_CMETHOD 0x40000u
#define FRAME_VAR_LOADED     0x80000u

#if defined(NRE)
# define NRE_SANE_PATCH 1
# define NsfImmediateFromCallerFlags(flags) \
  (((flags) & (NSF_CSC_CALL_IS_NRE|NSF_CSC_IMMEDIATE)) == NSF_CSC_CALL_IS_NRE ? 0 : NSF_CSC_IMMEDIATE)
# if defined(NRE_SANE_PATCH)
#  define NsfNRRunCallbacks(interp, result, rootPtr) TclNRRunCallbacks(interp, result, rootPtr)
#  if !defined(TclStackFree)
#   define TclStackFree(interp, ptr) ckfree(ptr)
#   define TclStackAlloc(interp, size) ckalloc(size)
#  endif
# else
#  define NsfNRRunCallbacks(interp, result, rootPtr) TclNRRunCallbacks(interp, result, rootPtr, 0)
#  define TEOV_callback NRE_callback
# endif
#endif

#if defined(NSF_PROFILE)
typedef struct NsfProfile {
  long int overallTime;
  long int startSec;
  long int startUSec;
  Tcl_HashTable objectData;
  Tcl_HashTable methodData;
  Tcl_HashTable procData;
  Tcl_DString traceDs;
  int depth;
  int verbose;
  Tcl_Obj *shadowedObjs;
  NsfShadowTclCommandInfo *shadowedTi;
  int inmemory;
} NsfProfile;

# define NSF_PROFILE_TIME_DATA struct Tcl_Time profile_trt
# define NSF_PROFILE_CALL(interp, object, methodName) \
  Tcl_GetTime(&profile_trt);			\
  NsfProfileTraceCall(interp, object, NULL, methodName)
# define NSF_PROFILE_EXIT(interp, object, methodName) \
  NsfProfileTraceExit(interp, object, NULL, methodName, &profile_trt)
#else
# define NSF_PROFILE_TIME_DATA
# define NSF_PROFILE_CALL(interp, object, methodName)
# define NSF_PROFILE_EXIT(interp, object, methodName)
#endif

typedef struct NsfList {
  void           *data;
  Tcl_Obj        *obj;
  struct NsfList *nextPtr;
} NsfList;

typedef struct NsfDList {
  void  **data;
  size_t  size;
  size_t  avail;
  void   *static_data[30];
} NsfDList;


typedef struct NsfRuntimeState {
  /*
   * The defined object systems
   */
  struct NsfObjectSystem *objectSystems;
  /*
   * namespaces and cmds
   */
  Tcl_Namespace *NsfNS;           /* the ::nsf namespace */
  Tcl_Namespace *NsfClassesNS;    /* the ::nsf::classes namespace, where classes are created physically */
  Tcl_ObjCmdProc *objInterpProc;  /* cached result of TclGetObjInterpProc() */
  Tcl_Command colonCmd;           /* cmdPtr of cmd ":" to dispatch via cmdResolver */
  Proc fakeProc;                  /* dummy proc structure, used for C-implemented methods with local scope */
  Tcl_Command currentMixinCmdPtr; /* cmdPtr of currently active mixin, used for "info activemixin" */
  unsigned int objectMethodEpoch;
  unsigned int instanceMethodEpoch;
#if defined(PER_OBJECT_PARAMETER_CACHING)
  unsigned int classParamPtrEpoch;
#endif
  unsigned int overloadedMethods; /* bit-array for tracking overloaded methods */
  Tcl_Obj **methodObjNames;       /* global objects of nsf */
  struct NsfShadowTclCommandInfo *tclCommands; /* shadowed Tcl commands */

#if defined(CHECK_ACTIVATION_COUNTS)
  NsfClasses *cscList;
#endif
  int errorCount;        /* keep track of number of errors to avoid potential error loops */
  int unknown;           /* keep track whether an unknown method is currently called */
  /*
   * Configure options. The following do*-flags could be moved into a
   * bit-array, but we have only one state per interp, so the win on
   * memory is very little.
   */
  int logSeverity;
  int debugCallingDepth;
  unsigned int doCheckArguments;
  unsigned int doCheckResults;
  int doFilters;
  int doKeepcmds;
  int doProfile;
  int doTrace;
  unsigned int preventRecursionFlags;
  int doClassConverterOmitUnknown;
  int doSoftrecreate;
  int exitHandlerDestroyRound;          /* shutdown handling */

  Tcl_HashTable activeFilterTablePtr;   /* keep track of defined filters */
  NsfList *freeListPtr;                 /* list of elements to free when interp shuts down */
  NsfDList freeDList;
#if defined(NSF_PROFILE)
  NsfProfile profile;
#endif
#if defined(NSF_STACKCHECK)
  void *bottomOfStack;
  void *maxStack;
#endif
  ClientData clientData;
  NsfStringIncrStruct iss; /* used for new to create new symbols */
  short guardCount;        /* keep track of guard invocations */
} NsfRuntimeState;

#define NSF_EXITHANDLER_OFF 0
#define NSF_EXITHANDLER_ON_SOFT_DESTROY 1
#define NSF_EXITHANDLER_ON_PHYSICAL_DESTROY 2


#ifdef NSF_OBJECTDATA
EXTERN void
NsfSetObjectData(struct NsfObject *object, struct NsfClass *class, ClientData data)
  nonnull(1) nonnull(2) nonnull(3);
EXTERN int
NsfGetObjectData(struct NsfObject *object, struct NsfClass *class, ClientData *data)
  nonnull(1) nonnull(2) nonnull(3);
EXTERN int
NsfUnsetObjectData(struct NsfObject *object, struct NsfClass *class)
  nonnull(1) nonnull(2);
EXTERN void
NsfFreeObjectData(NsfClass *class)
  nonnull(1);
#endif

/*
 * Prototypes for method definitions
 */
EXTERN Tcl_ObjCmdProc NsfObjDispatch;

/*
 *  NsfObject Reference Accounting
 */
EXTERN void NsfCleanupObject_(NsfObject *object) nonnull(1);

#if defined(NSFOBJ_TRACE)
# define NsfObjectRefCountIncr(obj)					\
  ((NsfObject *)obj)->refCount++;					\
  fprintf(stderr, "RefCountIncr %p count=%d %s\n", obj, ((NsfObject *)obj)->refCount, \
	((NsfObject *)obj)->cmdName?ObjStr(((NsfObject *)obj)->cmdName):"no name"); \
  MEM_COUNT_ALLOC("NsfObject.refCount", obj)
# define NsfObjectRefCountDecr(obj)					\
  (obj)->refCount--;							\
  fprintf(stderr, "RefCountDecr %p count=%d\n", obj, obj->refCount);	\
  MEM_COUNT_FREE("NsfObject.refCount", obj)
#else
# define NsfObjectRefCountIncr(obj)           \
  (obj)->refCount++;                            \
  MEM_COUNT_ALLOC("NsfObject.refCount", obj)
# define NsfObjectRefCountDecr(obj)           \
  (obj)->refCount--;                            \
  MEM_COUNT_FREE("NsfObject.refCount", obj)
#endif

/*
 *
 *  Internally used API functions
 *
 */
#if defined(NRE)
# include "stubs8.6/nsfIntDecls.h"
#else
# include "stubs8.5/nsfIntDecls.h"
#endif

/*
 * Profiling functions
 */

EXTERN void NsfDeprecatedCmd(Tcl_Interp *interp, const char *what, const char *oldCmd, const char *newCmd)
  nonnull(1) nonnull(2) nonnull(3) nonnull(4);
EXTERN void NsfProfileDeprecatedCall(Tcl_Interp *interp, NsfObject *object, NsfClass *class,
				     const char *methodName, const char *altMethod)
  nonnull(1) nonnull(2) nonnull(4) nonnull(5);
EXTERN void NsfProfileDebugCall(Tcl_Interp *interp, NsfObject *object, NsfClass *class, const char *methodName,
				int objc, Tcl_Obj **objv)
  nonnull(1) nonnull(4);
EXTERN void NsfProfileDebugExit(Tcl_Interp *interp, NsfObject *object, NsfClass *class, const char *methodName,
		    long startSec, long startUsec)
  nonnull(1) nonnull(4);

#if defined(NSF_PROFILE)
EXTERN void NsfProfileRecordMethodData(Tcl_Interp* interp, NsfCallStackContent *cscPtr)
  nonnull(1) nonnull(2);
EXTERN void NsfProfileRecordProcData(Tcl_Interp *interp, const char *methodName, long startSec, long startUsec)
  nonnull(1) nonnull(2);
EXTERN void NsfProfileInit(Tcl_Interp *interp) nonnull(1);
EXTERN void NsfProfileFree(Tcl_Interp *interp) nonnull(1);
EXTERN void NsfProfileClearData(Tcl_Interp *interp) nonnull(1);
EXTERN void NsfProfileGetData(Tcl_Interp *interp) nonnull(1);
EXTERN int NsfProfileTrace(Tcl_Interp *interp, int withEnable, int withVerbose, int withDontsave, Tcl_Obj *builtinObjs);

EXTERN void NsfProfileTraceCall(Tcl_Interp *interp, NsfObject *object, NsfClass *class, const char *methodName)
  nonnull(1) nonnull(2) nonnull(4);
EXTERN void NsfProfileTraceExit(Tcl_Interp *interp, NsfObject *object, NsfClass *class, const char *methodName,
				struct Tcl_Time *callTime)
  nonnull(1) nonnull(2) nonnull(4) nonnull(5);
EXTERN void NsfProfileTraceCallAppend(Tcl_Interp *interp, const char *label)
  nonnull(1) nonnull(2);
EXTERN void NsfProfileTraceExitAppend(Tcl_Interp *interp, const char *label, double duration)
  nonnull(1) nonnull(2);

EXTERN NsfCallStackContent *NsfCallStackGetTopFrame(const Tcl_Interp *interp, Tcl_CallFrame **framePtrPtr)
  nonnull(1);
#endif

/*
 * MEM Counting
 */
#ifdef NSF_MEM_COUNT
void NsfMemCountAlloc(const char *id, const void *p) nonnull(1);
void NsfMemCountFree(const char *id, const void *p) nonnull(1);
void NsfMemCountInit(void);
void NsfMemCountRelease(void);
#endif /* NSF_MEM_COUNT */

/*
 * TCL_STACK_ALLOC_TRACE
 */
#if defined(TCL_STACK_ALLOC_TRACE)
# define NsfTclStackFree(interp,ptr,msg) \
  fprintf(stderr, "---- TclStackFree %p %s\n", ptr, msg);\
  TclStackFree(interp,ptr)

static char *
NsfTclStackAlloc(Tcl_Interp *interp, size_t size, char *msg) {
  char *ptr = TclStackAlloc(interp, size);
  fprintf(stderr, "---- TclStackAlloc %p %s\n", ptr, msg);
  return ptr;
}
#else
# define NsfTclStackFree(interp,ptr,msg) TclStackFree(interp,ptr)
# define NsfTclStackAlloc(interp,size,msg) TclStackAlloc(interp,size)
#endif

/*
 * bytecode support
 */
#ifdef NSF_BYTECODE
typedef struct NsfCompEnv {
  int bytecode;
  Command *cmdPtr;
  CompileProc *compileProc;
  Tcl_ObjCmdProc *callProc;
} NsfCompEnv;

typedef enum {INST_INITPROC, INST_NEXT, INST_SELF, INST_SELF_DISPATCH,
	      LAST_INSTRUCTION} NsfByteCodeInstructions;

Tcl_ObjCmdProc NsfInitProcNSCmd, NsfSelfDispatchCmd,
  NsfNextObjCmd, NsfGetSelfObjCmd;

EXTERN NsfCompEnv *NsfGetCompEnv(void);
int NsfDirectSelfDispatch(ClientData cd, Tcl_Interp *interp,
		     int objc, Tcl_Obj *const objv[])
  nonnull(1) nonnull(2);
#endif

EXTERN int NsfGetClassFromObj(Tcl_Interp *interp, Tcl_Obj *objPtr,
			      NsfClass **classPtr, bool withUnknown)
  nonnull(1) nonnull(2) nonnull(3);

EXTERN int NsfObjWrongArgs(Tcl_Interp *interp, const char *msg,
			   Tcl_Obj *cmdNameObj, Tcl_Obj *methodPathObj,
			   const char *arglist)
  nonnull(1) nonnull(2);

EXTERN const char *NsfMethodName(Tcl_Obj *methodObj)
  nonnull(1) returns_nonnull;

EXTERN void NsfInitPkgConfig(Tcl_Interp *interp)
  nonnull(1);

EXTERN void NsfDStringArgv(Tcl_DString *dsPtr, int objc, Tcl_Obj *const objv[])
  nonnull(1) nonnull(3);

EXTERN Tcl_Obj *NsfMethodNamePath(Tcl_Interp *interp,
				  Tcl_CallFrame *framePtr,
				  const char *methodName)
  nonnull(1) nonnull(3) returns_nonnull;

EXTERN int NsfDStringEval(Tcl_Interp *interp, Tcl_DString *dsPtr, const char *context,
			  unsigned int traceEvalFlags)
  nonnull(1) nonnull(2) nonnull(3);


/*
 * Definition of methodEpoch macros
 */
#if defined(METHOD_OBJECT_TRACE)
# define NsfInstanceMethodEpochIncr(msg) \
  RUNTIME_STATE(interp)->instanceMethodEpoch++;	\
  fprintf(stderr, "+++ instanceMethodEpoch %d %s\n", RUNTIME_STATE(interp)->instanceMethodEpoch, msg)
# define NsfObjectMethodEpochIncr(msg) \
  RUNTIME_STATE(interp)->objectMethodEpoch++;	\
  fprintf(stderr, "+++ objectMethodEpoch %d %s\n", RUNTIME_STATE(interp)->objectMethodEpoch, msg)
#else
# define NsfInstanceMethodEpochIncr(msg) RUNTIME_STATE(interp)->instanceMethodEpoch++
# define NsfObjectMethodEpochIncr(msg)   RUNTIME_STATE(interp)->objectMethodEpoch++
#endif

#if defined(PER_OBJECT_PARAMETER_CACHING)
# define NsfClassParamPtrEpochIncr(msg)   RUNTIME_STATE(interp)->classParamPtrEpoch++
#else
# define NsfClassParamPtrEpochIncr(msg)
#endif

/*
 * NsfFlag type
 */
EXTERN Tcl_ObjType NsfFlagObjType;
EXTERN int NsfFlagObjSet(Tcl_Interp      *UNUSED(interp),
			 Tcl_Obj         *objPtr,
			 Nsf_Param const *baseParamPtr,
			 int              serial,
			 Nsf_Param const *paramPtr,
			 Tcl_Obj         *payload,
			 unsigned int     flags);
typedef struct {
  const Nsf_Param *signature;
  Nsf_Param const *paramPtr;
  Tcl_Obj         *payload;
  int              serial;
  unsigned int     flags;
} NsfFlag;

#define NSF_FLAG_DASHDAH		0x01
#define NSF_FLAG_CONTAINS_VALUE		0x02

/*
 * NsfMethodContext type
 */
EXTERN Tcl_ObjType NsfInstanceMethodObjType;
EXTERN Tcl_ObjType NsfObjectMethodObjType;

EXTERN int NsfMethodObjSet(
    Tcl_Interp  *UNUSED(interp),
    Tcl_Obj     *objPtr,
    const Tcl_ObjType *objectType,
    void        *context,
    unsigned int methodEpoch,
    Tcl_Command  cmd,
    NsfClass    *class,
    unsigned int flags
) nonnull(1) nonnull(2) nonnull(3) nonnull(4) nonnull(6);




typedef struct {
  void        *context;
  Tcl_Command  cmd;
  NsfClass    *cl;
  unsigned int methodEpoch;
  unsigned int flags;
} NsfMethodContext;

/* functions from nsfUtil.c */
char *Nsf_ltoa(char *buf, long i, int *lengthPtr)
  nonnull(1) nonnull(3);

char *NsfStringIncr(NsfStringIncrStruct *iss)
  nonnull(1);

void NsfStringIncrInit(NsfStringIncrStruct *iss)
  nonnull(1);

void NsfStringIncrFree(NsfStringIncrStruct *iss)
  nonnull(1);


/*
 *  Interface for NSF's custom hash tables supporting function
 *  pointers as keys.
 *
 */

typedef void (Nsf_AnyFun)(void);

EXTERN void Nsf_InitFunPtrHashTable(Tcl_HashTable *tablePtr)
  nonnull(1);
EXTERN Tcl_HashEntry *Nsf_CreateFunPtrHashEntry(Tcl_HashTable *tablePtr, Nsf_AnyFun *key, int *isNew)
  nonnull(1) nonnull(2);
EXTERN Tcl_HashEntry *Nsf_FindFunPtrHashEntry(Tcl_HashTable *tablePtr, Nsf_AnyFun *key)
  nonnull(1) nonnull(2);


/*
 * NSF enumeration-type interface
 */
EXTERN void Nsf_EnumerationTypeInit(void);
EXTERN void Nsf_EnumerationTypeRelease(void);

EXTERN const char *Nsf_EnumerationTypeGetDomain(Nsf_TypeConverter *converter)
  nonnull(1);

/*
 * NSF command definitions interface
 */
EXTERN void Nsf_CmdDefinitionInit(void);
EXTERN void Nsf_CmdDefinitionRelease(void);
EXTERN Nsf_methodDefinition *Nsf_CmdDefinitionGet(Tcl_ObjCmdProc *proc)
  nonnull(1);


#ifndef HAVE_STRNSTR
char *strnstr(const char *buffer, const char *needle, size_t buffer_len) pure;
#endif

/*
   In ANSI mode (ISO C89/90) compilers such as gcc and clang do not
   define the va_copy macro. However, they *do* in reasonably recent
   versions provide a prefixed (__*) one. The by-feature test below
   falls back to the prefixed version, if available, and provides a
   more general fallback to a simple assignment; this is primarily for
   MSVC; admittedly, this simplification is not generally portable to
   platform/compiler combos other then x86, but the best I can think of right
   now. One might constrain the assignment-fallback to a platform and
   leave va_copy undefined in uncaught platform cases (?).
*/
#ifndef va_copy
#ifdef	__va_copy
#define	va_copy(dest,src) __va_copy((dest),(src))
#else
#define va_copy(dest,src) ((dest) = (src))
#endif
#endif

/* In Tcl 8.6 (tclInt.h), vsnprintf is mapped to _vsnprintf. In Tcl
   8.5, this is missing from tclInt.h. So ... */

#if defined(PRE86) && defined(_MSC_VER)
#define vsnprintf _vsnprintf
#endif

/* 
 * There are six whitespace characters in Tcl, which serve as element
 * separators in string representations of Tcl lists. See tclUtil.c
 */

#define NsfHasTclSpace(str) \
  (strpbrk((str), " \t\n\r\v\f") != NULL)

#define NsfMax(a,b) ((a) > (b) ? a : b)
#define NsfMin(a,b) ((a) < (b) ? a : b)

#endif /* _nsf_int_h_ */
