# zlibtclConfig.sh --
#
# This shell script (for sh) is generated automatically by zlibtcl's
# configure script.  It will create shell variables for most of
# the configuration options discovered by the configure script.
# This script is intended to be included by the configure scripts
# for zlibtcl extensions so that they don't have to figure this all
# out for themselves.  This file does not duplicate information
# already provided by tclConfig.sh, so you may need to use that
# file in addition to this one.
#
# The information in this file is specific to a single platform.

# zlibtcl's version number.
zlibtcl_VERSION='1.2.8.1'
zlibtcl_MAJOR_VERSION=''
zlibtcl_MINOR_VERSION=''
zlibtcl_RELEASE_LEVEL=''

# The name of the zlibtcl library (may be either a .a file or a shared library):
zlibtcl_LIB_FILE=zlibtcl1281.dll

# String to pass to linker to pick up the zlibtcl library from its
# build directory.
zlibtcl_BUILD_LIB_SPEC='-L/home/gecko/work/Img/zlib -lzlibtcl1281'

# String to pass to linker to pick up the zlibtcl library from its
# installed directory.
zlibtcl_LIB_SPEC='-LC:/tools/msys64/tmp/ActiveState-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/lib/Img1.4.6 -lzlibtcl1281'

# The name of the zlibtcl stub library (a .a file):
zlibtcl_STUB_LIB_FILE=zlibtclstub1281.lib

# String to pass to linker to pick up the zlibtcl stub library from its
# build directory.
zlibtcl_BUILD_STUB_LIB_SPEC='-L/home/gecko/work/Img/zlib -lzlibtclstub1281'

# String to pass to linker to pick up the zlibtcl stub library from its
# installed directory.
zlibtcl_STUB_LIB_SPEC='-LC:/tools/msys64/tmp/ActiveState-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/lib/Img1.4.6 -lzlibtclstub1281'

# String to pass to linker to pick up the zlibtcl stub library from its
# build directory.
zlibtcl_BUILD_STUB_LIB_PATH='/home/gecko/work/Img/zlib/zlibtclstub1281.lib'

# String to pass to linker to pick up the zlibtcl stub library from its
# installed directory.
zlibtcl_STUB_LIB_PATH='C:/tools/msys64/tmp/ActiveState-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/lib/Img1.4.6/zlibtclstub1281.lib'

# Location of the top-level source directories from which zlibtcl
# was built.  This is the directory that contains generic, unix, etc.
# If zlibtcl was compiled in a different place than the directory
# containing the source files, this points to the location of the
# sources, not the location where zlibtcl was compiled. This can
# be relative to the build directory.

zlibtcl_SRC_DIR='.'
