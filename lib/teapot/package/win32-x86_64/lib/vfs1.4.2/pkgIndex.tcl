
# @@ Meta Begin
# Package vfs 1.4.2
# Meta activestatetags ActiveTcl Public
# Meta as::author      {Vincent Darley}
# Meta as::build::date 2015-03-10
# Meta as::origin      http://sourceforge.net/projects/tclvfs
# Meta category        Virtual filesystems
# Meta description     Tclvfs allows Virtual Filesystems to be built using
# Meta description     Tcl scripts only. It is also a repository of such
# Meta description     Tcl-implemented filesystems (metakit, zip, ftp, tar,
# Meta description     http, webdav, namespace, url)
# Meta license         BSD
# Meta platform        win32-x86_64
# Meta recommend       Memchan
# Meta recommend       Trf
# Meta recommend       zlibtcl
# Meta require         {Tcl 8.4}
# Meta subject         zip ftp tar http webdav vfs filesystem metakit
# Meta subject         namespace url
# Meta summary         Extra virtual filesystems for Tcl.
# @@ Meta End


if {![package vsatisfies [package provide Tcl] 8.4]} return

package ifneeded vfs 1.4.2 [string map [list @ $dir] {
        # ACTIVESTATE TEAPOT-PKG BEGIN REQUIREMENTS

        package require Tcl 8.4

        # ACTIVESTATE TEAPOT-PKG END REQUIREMENTS

            source [file join {@} vfs.tcl]

        # ACTIVESTATE TEAPOT-PKG BEGIN DECLARE

        package provide vfs 1.4.2

        # ACTIVESTATE TEAPOT-PKG END DECLARE
    }]
