# tclConfig.sh --
# 
# This shell script (for sh) is generated automatically by Tcl's
# configure script.  It will create shell variables for most of
# the configuration options discovered by the configure script.
# This script is intended to be included by the configure scripts
# for Tcl extensions so that they don't have to figure this all
# out for themselves.
#
# The information in this file is specific to a single platform.

TCL_DLL_FILE="tcl85.dll"

# Tcl's version number.
TCL_VERSION='8.5'
TCL_MAJOR_VERSION='8'
TCL_MINOR_VERSION='5'
TCL_PATCH_LEVEL='.18'

# C compiler to use for compilation.
TCL_CC='cl'

# -D flags for use with the C compiler.
TCL_DEFS='-DPACKAGE_NAME=\"\" -DPACKAGE_TARNAME=\"\" -DPACKAGE_VERSION=\"\" -DPACKAGE_STRING=\"\" -DPACKAGE_BUGREPORT=\"\" -Dinline=__inline -DSTDC_HEADERS=1 -DTCL_THREADS=1 -DUSE_THREAD_ALLOC=1 -DTCL_CFGVAL_ENCODING=\"cp1252\" -DHAVE_SYS_TYPES_H=1 -DHAVE_SYS_STAT_H=1 -DHAVE_STDLIB_H=1 -DHAVE_STRING_H=1 -DHAVE_MEMORY_H=1 -DTCL_CFG_DO64BIT=1 -DHAVE_INTPTR_T=1 -DHAVE_UINTPTR_T=1 -DHAVE_NO_FINDEX_ENUMS=1 -DNDEBUG=1 -DTCL_CFG_OPTIMIZED=1 '

# If TCL was built with debugging symbols, generated libraries contain
# this string at the end of the library name (before the extension).
TCL_DBGX=

# Default flags used in an optimized and debuggable build, respectively.
TCL_CFLAGS_DEBUG='-nologo -Zi -Od -MDd -D_CRT_SECURE_NO_DEPRECATE -D_CRT_NONSTDC_NO_DEPRECATE'
TCL_CFLAGS_OPTIMIZE='-nologo -O1 -MD -D_CRT_SECURE_NO_DEPRECATE -D_CRT_NONSTDC_NO_DEPRECATE'

# Default linker flags used in an optimized and debuggable build, respectively.
TCL_LDFLAGS_DEBUG='-debug'
TCL_LDFLAGS_OPTIMIZE='-release'

# Flag, 1: we built a shared lib, 0 we didn't
TCL_SHARED_BUILD=1

# The name of the Tcl library (may be either a .a file or a shared library):
TCL_LIB_FILE='tcl85.lib'

# Flag to indicate whether shared libraries need export files.
TCL_NEEDS_EXP_FILE=

# String that can be evaluated to generate the part of the export file
# name that comes after the "libxxx" (includes version number, if any,
# extension, and anything else needed).  May depend on the variables
# VERSION.  On most UNIX systems this is ${VERSION}.exp.
TCL_EXPORT_FILE_SUFFIX='${NODOT_VERSION}${DBGX}.lib'

# Additional libraries to use when linking Tcl.
TCL_LIBS='user32.lib advapi32.lib ws2_32.lib bufferoverflowU.lib'

# Top-level directory in which Tcl's platform-independent files are
# installed.
TCL_PREFIX='C:/Dropbox/Ph.D/Open SEES/OpenSees 4Story Panel Zone/IDA ALL RECORDS GENERAL'

# Top-level directory in which Tcl's platform-specific files (e.g.
# executables) are installed.
TCL_EXEC_PREFIX='C:/Dropbox/Ph.D/Open SEES/OpenSees 4Story Panel Zone/IDA ALL RECORDS GENERAL'

# Flags to pass to cc when compiling the components of a shared library:
TCL_SHLIB_CFLAGS=''

# Flags to pass to cc to get warning messages
TCL_CFLAGS_WARNING='-W3'

# Extra flags to pass to cc:
TCL_EXTRA_CFLAGS=''

# Base command to use for combining object files into a shared library:
TCL_SHLIB_LD='"C:/PlatSDK/Bin/Win64/x86/AMD64/link.exe" -dll -incremental:no -nologo -MACHINE:AMD64 -LIBPATH:"C:/PlatSDK/Lib/AMD64"'

# Base command to use for combining object files into a static library:
TCL_STLIB_LD='"C:/PlatSDK/Bin/Win64/x86/AMD64/link.exe" -lib -nologo -MACHINE:AMD64 -LIBPATH:"C:/PlatSDK/Lib/AMD64"'

# Either '$LIBS' (if dependent libraries should be included when linking
# shared libraries) or an empty string.  See Tcl's configure.in for more
# explanation.
TCL_SHLIB_LD_LIBS='${LIBS}'

# Suffix to use for the name of a shared library.
TCL_SHLIB_SUFFIX='.dll'

# Library file(s) to include in tclsh and other base applications
# in order to provide facilities needed by DLOBJ above.
TCL_DL_LIBS=''

# Flags to pass to the compiler when linking object files into
# an executable tclsh or tcltest binary.
TCL_LD_FLAGS=''

# Flags to pass to ld, such as "-R /usr/local/tcl/lib", that tell the
# run-time dynamic linker where to look for shared libraries such as
# libtcl.so.  Used when linking applications.  Only works if there
# is a variable "LIB_RUNTIME_DIR" defined in the Makefile.
TCL_LD_SEARCH_FLAGS=''

# Additional object files linked with Tcl to provide compatibility
# with standard facilities from ANSI C or POSIX.
TCL_COMPAT_OBJS=''

# Name of the ranlib program to use.
TCL_RANLIB='ranlib'

# -l flag to pass to the linker to pick up the Tcl library
TCL_LIB_FLAG='-ltcl85'

# String to pass to linker to pick up the Tcl library from its
# build directory.
TCL_BUILD_LIB_SPEC='-L/home/Administrator/dbn/lba/GlobalBuildArena/builds/win32-x64/tcl/win/win32-x64 -ltcl85'

# String to pass to linker to pick up the Tcl library from its
# installed directory.
TCL_LIB_SPEC='-LC:/Dropbox/Ph.D/Open SEES/OpenSees 4Story Panel Zone/IDA ALL RECORDS GENERAL/lib -ltcl85'

# String to pass to the compiler so that an extension can
# find installed Tcl headers.
TCL_INCLUDE_SPEC='-IC:/Dropbox/Ph.D/Open SEES/OpenSees 4Story Panel Zone/IDA ALL RECORDS GENERAL/include'

# Indicates whether a version numbers should be used in -l switches
# ("ok" means it's safe to use switches like -ltcl7.5;  "nodots" means
# use switches like -ltcl75).  SunOS and FreeBSD require "nodots", for
# example.
TCL_LIB_VERSIONS_OK=''

# String that can be evaluated to generate the part of a shared library
# name that comes after the "libxxx" (includes version number, if any,
# extension, and anything else needed).  May depend on the variables
# VERSION and SHLIB_SUFFIX.  On most UNIX systems this is
# ${VERSION}${SHLIB_SUFFIX}.
TCL_SHARED_LIB_SUFFIX='${NODOT_VERSION}${DBGX}.dll'

# String that can be evaluated to generate the part of an unshared library
# name that comes after the "libxxx" (includes version number, if any,
# extension, and anything else needed).  May depend on the variable
# VERSION.  On most UNIX systems this is ${VERSION}.a.
TCL_UNSHARED_LIB_SUFFIX='${NODOT_VERSION}${DBGX}.lib'

# Location of the top-level source directory from which Tcl was built.
# This is the directory that contains a README file as well as
# subdirectories such as generic, unix, etc.  If Tcl was compiled in a
# different place than the directory containing the source files, this
# points to the location of the sources, not the location where Tcl was
# compiled.
TCL_SRC_DIR='/home/Administrator/dbn/lba/GlobalBuildArena/builds/win32-x64/tcl'

# List of standard directories in which to look for packages during
# "package require" commands.  Contains the "prefix" directory plus also
# the "exec_prefix" directory, if it is different.
TCL_PACKAGE_PATH='C:/Dropbox/Ph.D/Open SEES/OpenSees 4Story Panel Zone/IDA ALL RECORDS GENERAL/lib C:/Dropbox/Ph.D/Open SEES/OpenSees 4Story Panel Zone/IDA ALL RECORDS GENERAL/lib'

# Tcl supports stub.
TCL_SUPPORTS_STUBS=1

# The name of the Tcl stub library (.a):
TCL_STUB_LIB_FILE='tclstub85.lib'

# -l flag to pass to the linker to pick up the Tcl stub library
TCL_STUB_LIB_FLAG='-ltclstub85'

# String to pass to linker to pick up the Tcl stub library from its
# build directory.
TCL_BUILD_STUB_LIB_SPEC='-L/home/Administrator/dbn/lba/GlobalBuildArena/builds/win32-x64/tcl/win/win32-x64 -ltclstub85'

# String to pass to linker to pick up the Tcl stub library from its
# installed directory.
TCL_STUB_LIB_SPEC='-LC:/Dropbox/Ph.D/Open SEES/OpenSees 4Story Panel Zone/IDA ALL RECORDS GENERAL/lib -ltclstub85'

# Path to the Tcl stub library in the build directory.
TCL_BUILD_STUB_LIB_PATH='/home/Administrator/dbn/lba/GlobalBuildArena/builds/win32-x64/tcl/win/win32-x64/tclstub85.lib'

# Path to the Tcl stub library in the install directory.
TCL_STUB_LIB_PATH='C:/Dropbox/Ph.D/Open SEES/OpenSees 4Story Panel Zone/IDA ALL RECORDS GENERAL/lib/tclstub85.lib'

# Flag, 1: we built Tcl with threads enabled, 0 we didn't
TCL_THREADS=1

