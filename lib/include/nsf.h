/*
 *  Next Scripting Framework
 *
 *  Copyright (C) 1999-2017 Gustaf Neumann (a) (b)
 *  Copyright (C) 1999-2007 Uwe Zdun (a) (b)
 *  Copyright (C) 2007-2008 Martin Matuska (b)
 *  Copyright (C) 2010-2017 Stefan Sobernig (b)
 *
 * (a) University of Essen
 *     Specification of Software Systems
 *     Altendorferstrasse 97-101
 *     D-45143 Essen, Germany
 *
 * (b) Vienna University of Economics and Business
 *     Institute of Information Systems and New Media
 *     A-1090, Augasse 2-6
 *     Vienna, Austria
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
 * */

#ifndef _nsf_h_
#define _nsf_h_

#include "tcl.h"

#undef TCL_STORAGE_CLASS
#ifdef BUILD_nsf
# define TCL_STORAGE_CLASS DLLEXPORT
#else
# ifdef USE_NSF_STUBS
#  define TCL_STORAGE_CLASS
# else
#  define TCL_STORAGE_CLASS DLLIMPORT
# endif
#endif

/*
 * prevent old TCL-versions
 */

#if TCL_MAJOR_VERSION < 8
# error Tcl distribution is TOO OLD, we require at least tcl8.5
#endif

#if TCL_MAJOR_VERSION==8 && TCL_MINOR_VERSION<5
# error Tcl distribution is TOO OLD, we require at least tcl8.5
#endif

#if TCL_MAJOR_VERSION==8 && TCL_MINOR_VERSION<6
# define PRE86
#endif

#if defined(PRE86)
# define CONST86
# define Tcl_GetErrorLine(interp) (interp)->errorLine
#else
# define NRE
#endif

/*
 * Feature activation/deactivation
 */

/*
 * The following features are controlled via
 * configure flags
 *
 *   --with-dtrace
 *   --enable-development
 *   --enable-profile
 *   --enable-memcount=yes|trace
 *   --enable-assertions
 *
 * Are we developing?
 *
#define NSF_DEVELOPMENT 1
 *
 * Activate/deactivate profiling information
 *
#define NSF_PROFILE 1
 *
 * Compile with dtrace support
 *
#define NSF_DTRACE 1
 *
 * Scripting level assertions
 *
#define NSF_WITH_ASSERTIONS 1
 *
 * Activate/deactivate memory tracing
 *
#define NSF_MEM_TRACE 1
#define NSF_MEM_COUNT 1
 *
 * Activate/deactivate valgrind support
 *
#define NSF_VALGRIND 1
 */

/* Activate bytecode support
#define NSF_BYTECODE
*/

/* Activate/deactivate C-level assert()
   Activated automatically when
   NSF_DEVELOPMENT is set
#define NDEBUG 1
*/

/* Experimental language feature
#define NSF_WITH_INHERIT_NAMESPACES 1
*/

#define NSF_WITH_OS_RESOLVER 1
#define NSF_WITH_VALUE_WARNINGS 1

/* turn  tracing output on/off
#define NSFOBJ_TRACE 1
#define NAMESPACE_TRACE 1
#define OBJDELETION_TRACE 1
#define STACK_TRACE 1
#define PARSE_TRACE 1
#define PARSE_TRACE_FULL 1
#define CONFIGURE_ARGS_TRACE 1
#define TCL_STACK_ALLOC_TRACE 1
#define VAR_RESOLVER_TRACE 1
#define CMD_RESOLVER_TRACE 1
#define NRE_CALLBACK_TRACE 1
#define METHOD_OBJECT_TRACE 1
#define NSF_LINEARIZER_TRACE 1
#define NSF_STACKCHECK 1
#define NSF_CLASSLIST_PRINT 1
#define NSF_PRINT_OBJV 1
*/

#define PER_OBJECT_PARAMETER_CACHING 1

/*
 * Sanity checks and dependencies for optional compile flags
 */
#if defined(PARSE_TRACE_FULL)
# define PARSE_TRACE 1
#endif

#ifdef NSF_MEM_COUNT
# define DO_FULL_CLEANUP 1
#endif

#ifdef AOL_SERVER
# ifndef TCL_THREADS
#  define TCL_THREADS
# endif
#endif

#ifdef TCL_THREADS
# define DO_CLEANUP
#endif

#ifdef DO_FULL_CLEANUP
# define DO_CLEANUP
#endif

#ifdef NSF_LINEARIZER_TRACE
# if !defined(NSF_CLASSLIST_PRINT)
#  define NSF_CLASSLIST_PRINT 1
# endif
#endif

#ifdef NSF_DTRACE
# define NSF_DTRACE_METHOD_RETURN_PROBE(cscPtr,retCode) \
  if (cscPtr->cmdPtr && NSF_DTRACE_METHOD_RETURN_ENABLED()) {		\
    NSF_DTRACE_METHOD_RETURN(ObjectName((cscPtr)->self),		\
			     (cscPtr)->cl ? ClassName((cscPtr)->cl) : ObjectName((cscPtr)->self), \
			     (char *)(cscPtr)->methodName,		\
			     (retCode));				\
  }
#else
# define NSF_DTRACE_METHOD_RETURN_PROBE(cscPtr,retCode) {}
#endif

#if defined(NSF_DEVELOPMENT_FULL) && !defined(NSF_DEVELOPMENT)
# define NSF_DEVELOPMENT 1
#endif

#ifdef NSF_DEVELOPMENT
/*
 * The activation counts checking is best performed via the MEM_COUNT
 * macros. In case, the MEM_COUNT macros indicate a problem, setting
 * CHECK_ACTIVATION_COUNTS might help to locate the problem more
 * precisely. The CHECK_ACTIVATION_COUNTS tester might however still
 * report false positives.
 */
/*# define CHECK_ACTIVATION_COUNTS 1*/
# define NsfCleanupObject(object,string)				\
  /*fprintf(stderr, "NsfCleanupObject %p %s\n",object,string);*/	\
  NsfCleanupObject_((object))
# define CscFinish(interp,cscPtr,retCode,string)			\
  /*fprintf(stderr, "CscFinish %p %s\n",cscPtr,string);	*/		\
  NSF_DTRACE_METHOD_RETURN_PROBE((cscPtr),(retCode));			\
  CscFinish_((interp), (cscPtr))
#else
# define NDEBUG 1
# define NsfCleanupObject(object,string)				\
  NsfCleanupObject_((object))
# define CscFinish(interp,cscPtr,retCode,string)			\
  NSF_DTRACE_METHOD_RETURN_PROBE(cscPtr,retCode);			\
  CscFinish_((interp), (cscPtr))
#endif

#if defined(NSF_MEM_TRACE) && !defined(NSF_MEM_COUNT)
# define NSF_MEM_COUNT 1
#endif

/*  if ((cmd) != NULL) {fprintf(stderr, "METHOD %s cmd %p flags %.8x (%.8x)\n", (method), (cmd), Tcl_Command_flags((cmd)), NSF_CMD_DEPRECATED_METHOD);} */
#if defined(NSF_PROFILE)
# define CscInit(cscPtr, object, cl, cmd, frametype, flags, method) \
  CscInit_((cscPtr), (object), (cl), (cmd), (frametype), (flags)); (cscPtr)->methodName = (method); \
  NsfProfileTraceCall((interp), (object), (cl), (method));
#else
# if defined(NSF_DTRACE)
#  define CscInit(cscPtr, object, cl, cmd, frametype, flags, method) \
  CscInit_((cscPtr), (object), (cl), (cmd), (frametype), (flags)); (cscPtr)->methodName = (method);
# else
#  define CscInit(cscPtr, object, cl, cmd, frametype, flags, methodName) \
  CscInit_((cscPtr), (object), (cl), (cmd), (frametype), (flags))
# endif
#endif

#if !defined(CHECK_ACTIVATION_COUNTS)
# define CscListAdd(interp, cscPtr)
# define CscListRemove(interp, cscPtr, cscListPtr)
#endif

#if defined(TCL_THREADS)
# define NsfMutex Tcl_Mutex
# define NsfMutexLock(a) Tcl_MutexLock((a))
# define NsfMutexUnlock(a) Tcl_MutexUnlock((a))
#else
# define NsfMutex int
# define NsfMutexLock(a)   (*(a))++
# define NsfMutexUnlock(a) (*(a))--
#endif

/*
 * A special definition used to allow this header file to be included
 * in resource files so that they can get obtain version information from
 * this file.  Resource compilers don't like all the C stuff, like typedefs
 * and procedure declarations, that occur below.
 */

#ifndef RC_INVOKED

/*
 * The structures Nsf_Object and Nsf_Class define mostly opaque
 * data structures for the internal use structures NsfObject and
 * NsfClass (both defined in NsfInt.h). Modification of elements
 * visible elements must be mirrored in both incarnations.
 *
 * Warning: These structures are just containing a few public
 * fields. These structures must not be used for querying the size or
 * allocating the data structures.
 */

typedef struct Nsf_Object {
  Tcl_Obj *cmdName;
} Nsf_Object;

typedef struct Nsf_Class {
  struct Nsf_Object object;
} Nsf_Class;

typedef struct Nsf_ParseContext {
  ClientData *clientData;
  int status;
} Nsf_ParseContext;


struct Nsf_Param;
typedef int (Nsf_TypeConverter)(Tcl_Interp *interp,
				 Tcl_Obj *obj,
				 struct Nsf_Param const *pPtr,
				 ClientData *clientData,
				 Tcl_Obj **outObjPtr);

typedef struct {
  Nsf_TypeConverter *converter;
  const char *domain;
} Nsf_EnumeratorConverterEntry;

EXTERN Nsf_TypeConverter Nsf_ConvertToBoolean, Nsf_ConvertToClass,
  Nsf_ConvertToInteger, Nsf_ConvertToInt32,
  Nsf_ConvertToObject, Nsf_ConvertToParameter,
  Nsf_ConvertToString, Nsf_ConvertToSwitch,
  Nsf_ConvertToTclobj, Nsf_ConvertToPointer;

typedef struct Nsf_Param {
  const char        *name;
  unsigned int       flags;
  int                nrArgs;
  Nsf_TypeConverter *converter;
  Tcl_Obj           *converterArg;
  Tcl_Obj           *defaultValue;
  const char        *type;
  Tcl_Obj           *nameObj;
  Tcl_Obj           *converterName;
  Tcl_Obj           *paramObj;
  Tcl_Obj           *slotObj;
  Tcl_Obj           *method;
} Nsf_Param;

/* Argument parse processing flags */
#define NSF_ARGPARSE_CHECK		     0x0001
#define NSF_ARGPARSE_FORCE_REQUIRED	     0x0002
#define NSF_ARGPARSE_BUILTIN		     (NSF_ARGPARSE_CHECK|NSF_ARGPARSE_FORCE_REQUIRED)
#define NSF_ARGPARSE_START_ZERO		     0x0010
/* Special flags for process method arguments */
#define NSF_ARGPARSE_METHOD_PUSH	     0x0100


/* flags for NsfParams */

#define NSF_ARG_REQUIRED		  0x00000001u
#define NSF_ARG_MULTIVALUED		  0x00000002u
#define NSF_ARG_NOARG			  0x00000004u
#define NSF_ARG_NOCONFIG		  0x00000008u
#define NSF_ARG_CURRENTLY_UNKNOWN	  0x00000010u
#define NSF_ARG_SUBST_DEFAULT		  0x00000020u
#define NSF_ARG_ALLOW_EMPTY		  0x00000040u
#define NSF_ARG_INITCMD			  0x00000080u
#define NSF_ARG_CMD			  0x00000100u
#define NSF_ARG_ALIAS			  0x00000200u
#define NSF_ARG_FORWARD			  0x00000400u
#define NSF_ARG_SWITCH			  0x00000800u
#define NSF_ARG_BASECLASS		  0x00001000u
#define NSF_ARG_METACLASS		  0x00002000u
#define NSF_ARG_HAS_DEFAULT		  0x00004000u
#define NSF_ARG_IS_CONVERTER		  0x00008000u
#define NSF_ARG_IS_ENUMERATION		  0x00010000u
#define NSF_ARG_CHECK_NONPOS		  0x00020000u
#define NSF_ARG_SET			  0x00040000u
#define NSF_ARG_WARN			  0x00080000u
#define NSF_ARG_UNNAMED			  0x00100000u
#define NSF_ARG_IS_RETURNVALUE		  0x00200000u
#define NSF_ARG_NODASHALNUM		  0x00400000u
#define NSF_ARG_SLOTSET			  0x00800000u
#define NSF_ARG_SLOTINITIALIZE		  0x01000000u
#define NSF_ARG_SUBST_DEFAULT_COMMANDS	  0x10000000u
#define NSF_ARG_SUBST_DEFAULT_VARIABLES   0x20000000u
#define NSF_ARG_SUBST_DEFAULT_BACKSLASHES 0x40000000u
#define NSF_ARG_SUBST_DEFAULT_ALL         0x70000000u

#undef  __GNUC_PREREQ
#if defined __GNUC__ && defined __GNUC_MINOR__
# define __GNUC_PREREQ(maj, min) \
	((__GNUC__ << 16) + __GNUC_MINOR__ >= ((maj) << 16) + (min))
#else
# define __GNUC_PREREQ(maj, min) (0)
#endif

#if __GNUC_PREREQ(3, 3)
# define NSF_nonnull(ARGS) __attribute__((__nonnull__(ARGS)))
#else
# define NSF_nonnull(ARGS)
#endif

#if __GNUC_PREREQ(6, 0)
# define NSF_nonnull_assert(assertion)
#else
# define NSF_nonnull_assert(assertion) assert((assertion))
#endif


/*
 * Unfortunately, we can't combine NSF_attribute_format() with
 * functions called via stubs.
 */
#if __GNUC_PREREQ(3, 4)
# define NSF_attribute_format(ARGS) __attribute__((__format__ ARGS))
#else
# define NSF_attribute_format(ARGS)
#endif

EXTERN int
NsfArgumentError(Tcl_Interp *interp, const char *errorMsg, Nsf_Param const *paramPtr,
		 Tcl_Obj *cmdNameObj, Tcl_Obj *methodPathObj)
  NSF_nonnull(1) NSF_nonnull(2) NSF_nonnull(3);


EXTERN int
NsfDispatchClientDataError(Tcl_Interp *interp, ClientData clientData,
			   const char *what, const char *methodName)
  NSF_nonnull(1) NSF_nonnull(3) NSF_nonnull(4);

EXTERN int
NsfNoCurrentObjectError(Tcl_Interp *interp, const char *methodName)
  NSF_nonnull(1);

EXTERN int
NsfUnexpectedArgumentError(Tcl_Interp *interp, const char *argumentString,
			   Nsf_Object *object, Nsf_Param const *paramPtr,
			   Tcl_Obj *methodPathObj)
  NSF_nonnull(1) NSF_nonnull(2) NSF_nonnull(4) NSF_nonnull(5);

EXTERN int
NsfUnexpectedNonposArgumentError(Tcl_Interp *interp,
				 const char *argumentString,
				 Nsf_Object *object,
				 Nsf_Param const *currentParamPtr,
				 Nsf_Param const *paramPtr,
				 Tcl_Obj *methodPathObj)
  NSF_nonnull(1) NSF_nonnull(2) NSF_nonnull(4) NSF_nonnull(5) NSF_nonnull(6);

/*
 * logging severities
 */
#define NSF_LOG_ERROR  3
#define NSF_LOG_WARN   2
#define NSF_LOG_NOTICE 1
#define NSF_LOG_DEBUG  0

EXTERN void
NsfLog(Tcl_Interp *interp, int requiredLevel, const char *fmt, ...)
  NSF_nonnull(1) NSF_nonnull(3) NSF_attribute_format((printf,3,4));

/*
 * Nsf Pointer converter interface
 */

EXTERN int Nsf_PointerAdd(Tcl_Interp *interp, char *buffer, size_t size, const char *typeName, void *valuePtr)
  NSF_nonnull(1) NSF_nonnull(2) NSF_nonnull(4) NSF_nonnull(5);

EXTERN int Nsf_PointerDelete(const char *key, void *valuePtr, int free)
  NSF_nonnull(2);

EXTERN void Nsf_PointerInit(void);

EXTERN void Nsf_PointerExit(Tcl_Interp *interp)
  NSF_nonnull(1);

EXTERN void *Nsf_PointerTypeLookup(const char* typeName)
  NSF_nonnull(1);

EXTERN int Nsf_PointerTypeRegister(Tcl_Interp *interp, const char* typeName, int *counterPtr)
  NSF_nonnull(1) NSF_nonnull(2) NSF_nonnull(3);

/*
 * methodDefinition
 */

typedef struct Nsf_methodDefinition {
  const char     *methodName;
  Tcl_ObjCmdProc *proc;
  int             nrParameters;
  Nsf_Param       paramDefs[12];
} Nsf_methodDefinition;

/*
 * Nsf Enumeration type interface
 */
EXTERN int Nsf_EnumerationTypeRegister(Tcl_Interp *interp, Nsf_EnumeratorConverterEntry *typeRecords)
  NSF_nonnull(1) NSF_nonnull(2);


/*
 * Nsf Cmd definition interface
 */
EXTERN int  Nsf_CmdDefinitionRegister(Tcl_Interp *interp, Nsf_methodDefinition *definitionRecords)
  NSF_nonnull(1) NSF_nonnull(2);


/*
 * Include the public function declarations that are accessible via
 * the stubs table.
 */
#if defined(NRE)
# include "stubs8.6/nsfDecls.h"
#else
# include "stubs8.5/nsfDecls.h"
#endif

/*
 * Nsf_InitStubs is used by extensions  that can be linked
 * against the nsf stubs library.  If we are not using stubs
 * then this reduces to package require.
 */

#ifdef USE_NSF_STUBS

# ifdef __cplusplus
EXTERN "C"
# endif
const char *
Nsf_InitStubs(Tcl_Interp *interp, const char *version, int exact);
#else
# define Nsf_InitStubs(interp, version, exact) \
      Tcl_PkgRequire(interp, "nx", version, exact)
#endif

#endif /* RC_INVOKED */

/*
#undef TCL_STORAGE_CLASS
#define TCL_STORAGE_CLASS DLLIMPORT
*/

#endif /* _nsf_h_ */
