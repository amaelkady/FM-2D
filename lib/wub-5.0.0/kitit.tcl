# kitit.tcl - find the necessary dirs to form into a starkit
package require Tcl
set pkgdirs {}
rename ::source ::org_source
proc ::source {args} {
    set result [uplevel 1 ::org_source $args]
    set fn [file normalize [lindex $args end]]
    if {[llength $args] == 1 && [file tail $fn] ni {pkgIndex.tcl package.tcl tm.tcl}} {
	if {![dict exists $::pkgdirs [file dirname [file dirname $fn]]]} {
	    #puts "SOURCE: $args"
	    dict lappend ::pkgdirs [file dirname $fn] {}
	}
    }
    return $result
}

proc ::load_new {fn args} {
    puts stderr "([info level -1]) load $fn $args"
    set result [uplevel 1 ::org_load $fn $args]
    set fn [file normalize [file dirname $fn]]
    dict lappend ::pkgdirs $fn {}
    return $result
}

proc require {what} {
    if {[catch {package require $what} e eo]} {
	puts stderr "Failed: $what - '$e' ($eo)"
    }
}

foreach tcllib {cmdline csv inifile
    dns fileutil struct
    tar textutil tie} {
    if {[package present $tcllib]} {
	puts stderr "BUG: $tcllib is already loaded."
    }
    require $tcllib
}

if {0} {
    foreach tklib {autoscroll gbutton jpeg} {
	require $tklib
    }
}

foreach wub {Client docroot
    Domains extensions Utilities Wub} {
    dict lappend ::pkgdirs [file normalize $wub] {}
}

foreach arg $argv {
    dict lappend ::pkgdirs [file normalize $arg] {}
}

puts stderr "PKGDICT: [dict keys $pkgdirs]"
file delete -force wub.vfs
file mkdir wub.vfs
file mkdir wub.vfs/lib
foreach file [dict keys $pkgdirs] {
    file link -symbolic wub.vfs/lib/[file tail $file] $file
}
file copy main.tcl wub.vfs
