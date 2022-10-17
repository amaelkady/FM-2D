### 
### Utility for the build process. Main purpose currently:
###
###  - Build the pkgIndex in each directory
###

# adjust the paths;
# - auto_path is needed, when nx is loaded via good old pkgIndex.tcl
# - tcl::tm::roots is needed when nx is provided as a Tcl module (.tm)
lappend auto_path ..

# Is support for Tcl modules available (>= Tcl 8.5)?
if {[info commands ::tcl::tm::roots] ne ""} {
    ::tcl::tm::roots [pwd]
}

set verbose 0

proc mkIndex {} {
    if {$::verbose} {puts stderr "+++ mkIndex in [pwd]"}
    set fls {}
    foreach f [glob -nocomplain *tcl] {
	if {![file isdirectory $f]} {
	    set F [open $f]; set c [read $F]; close $F
	    if {[string match "*package provide*" $c]} {
		lappend fls $f 
		#puts "provide in $f"
		foreach l [split $c \n] {
		    #puts stderr "check $l"
		    if {[regexp {^\s*package\s+provide\s+(\S+)\s+([0-9]\S+)\s*$} $l _ pkg version]} {
			#puts stderr "found package $pkg $version in $f"
			set pkg_file($pkg) $f
			set pkg_version($pkg) $version
			break
		    }
		}
	    }
	}
    }

    set pkgIndex ""
    foreach pkg [lsort [array names pkg_file]] {
	append pkgIndex "package ifneeded $pkg $pkg_version($pkg) \[list source \[file join \$dir $pkg_file($pkg)\]\]\n"
    }

    foreach addFile [glob -nocomplain *.add] {
	if {[file exists $addFile]} {
	    puts stderr "Appending $addFile to pkgIndex.tcl in [pwd]"
	    set IN [open $addFile]
	    append pkgIndex [read $IN]\n
	    close $IN
	}
    }
    
    if {$pkgIndex ne ""} {
	if {$::verbose} {puts stderr "Write [pwd]/pkgIndex.tcl"}
	set OUT [open pkgIndex.tcl w]
	puts -nonewline $OUT $pkgIndex
	close $OUT
    }

    #puts stderr "+++ mkIndex pwd=[pwd] DONE"
}

proc inEachDir {path cmd} {
    if {$::verbose} {puts stderr "[pwd] inEachDir $path (dir [file isdirectory $path]) $cmd"}
    if { [file isdirectory $path] 
         && ![string match *CVS $path]
         && ![string match *SCCS $path]
         && ![string match *Attic $path]
         && ![string match *dbm* $path]
       } {
	set olddir [pwd]
	cd $path
	if {[catch $cmd errMsg]} {
	    error  "$errMsg (in directory [pwd])"
	}
	set files [glob -nocomplain *]
	cd $olddir
	foreach p $files { inEachDir $path/$p $cmd }
	if {$::verbose} {puts stderr "+++ change back to $olddir"}
    }
}

inEachDir . mkIndex
