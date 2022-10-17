# ACTIVESTATE TEAPOT-PKG BEGIN TM -*- tcl -*-
# -- Tcl Module

# @@ Meta Begin
# Package vfs::test 1.0
# Meta activestatetags ActiveTcl Public
# Meta as::author      {Vincent Darley}
# Meta as::build::date 2015-03-10
# Meta as::origin      http://sf.net/projects/tclvfs
# Meta category        Virtual filesystems
# Meta description     Tclvfs allows Virtual Filesystems to be built using
# Meta description     Tcl scripts only. It is also a repository of such
# Meta description     Tcl-implemented filesystems (metakit, zip, ftp, tar,
# Meta description     http, webdav, namespace, url)
# Meta license         BSD
# Meta platform        tcl
# Meta require         {Tcl 8.4}
# Meta require         vfs
# Meta subject         zip ftp tar http webdav vfs filesystem metakit
# Meta subject         namespace url
# Meta summary         Extra virtual filesystems for Tcl.
# @@ Meta End


# ACTIVESTATE TEAPOT-PKG BEGIN REQUIREMENTS

package require Tcl 8.4
package require vfs

# ACTIVESTATE TEAPOT-PKG END REQUIREMENTS

# ACTIVESTATE TEAPOT-PKG BEGIN DECLARE

package provide vfs::test 1.0

# ACTIVESTATE TEAPOT-PKG END DECLARE
# ACTIVESTATE TEAPOT-PKG END TM

package provide vfs::test 1.0

package require vfs 1.0

namespace eval vfs::test {}

proc vfs::test::Mount {what local} {
    vfs::filesystem mount $local [list ::vfs::test::handler $what]
    vfs::RegisterMount $local [list ::vfs::test::Unmount]
}

proc vfs::test::Unmount {local} {
    vfs::filesystem unmount $local
}

proc vfs::test::handler {what cmd root relative actualpath args} {
    eval [list $cmd $what $relative] $args
}

# If we implement the commands below, we will have a perfect
# virtual file system.

proc vfs::test::stat {what name} {
    puts "stat $name"
}

proc vfs::test::access {what name mode} {
    puts "access $name $mode"
}

proc vfs::test::open {what name mode permissions} {
    puts "open $name $mode $permissions"
    # return a list of two elements:
    # 1. first element is the Tcl channel name which has been opened
    # 2. second element (optional) is a command to evaluate when
    #    the channel is closed.
    return [list]
}

proc vfs::test::matchindirectory {what path pattern type} {
    puts "matchindirectory $path $pattern $type"
    set res [list]

    if {[::vfs::matchDirectories $type]} {
	# add matching directories to $res
    }
    
    if {[::vfs::matchFiles $type]} {
	# add matching files to $res
    }
    return $res
}

proc vfs::test::createdirectory {what name} {
    puts "createdirectory $name"
}

proc vfs::test::removedirectory {what name recursive} {
    puts "removedirectory $name"
}

proc vfs::test::deletefile {what name} {
    puts "deletefile $name"
}

proc vfs::test::fileattributes {what args} {
    puts "fileattributes $args"
    switch -- [llength $args] {
	0 {
	    # list strings
	}
	1 {
	    # get value
	    set index [lindex $args 0]
	}
	2 {
	    # set value
	    set index [lindex $args 0]
	    set val [lindex $args 1]
	}
    }
}

proc vfs::test::utime {what name actime mtime} {
    puts "utime $name"
}
