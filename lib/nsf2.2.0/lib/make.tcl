### 
### Utility for the build process. Main purpose currently:
###
###  - Build the pkgIndex in each directory
###

# adjust the paths;
# - auto_path is needed, when nx is loaded via good old pkgIndex.tcl
# - tcl::tm::roots is needed when nx is provided as a Tcl module (.tm)
lappend auto_path ..
::tcl::tm::roots [pwd]
#puts stderr TM-LIST=[  ::tcl::tm::path list ]

set verbose 0

package require nx
namespace eval ::nx {}; # make pkg_mkIndex happy

###
nx::Object create make {
  #
  # shared lib add files for pkgIndex.tcl
  #
  :object method mkIndex {name} {
    if {$::verbose} {puts stderr "+++ mkIndex in [pwd]"}
    set fls {}
    foreach f [glob -nocomplain *tcl] {
      if {![file isdirectory $f]} {
        set F [file open $f]; set c [read $F]; close $F
        if {[string match "*package provide*" $c]} { lappend fls $f }
      }
    }

    set so [glob -nocomplain *[info sharedlibextension]]
    set version $::nsf::version
    # loading libnext into nextsh might cause problems on some systems
    foreach lib [list libnext$version[info sharedlibextension] \
                     next$version.dll] {
      set p [lsearch -exact $so $lib]
      if {$p != -1} {
        set so [lreplace $so $p $p]
        puts stderr "new so=<$so>"
      }
    }
    #puts stderr "[pwd]: call so=<$so>"
    lappend fls {*}$so
    
    if {$fls ne ""} {
      if {[file exists pkgIndex.tcl]} {
        file delete -force pkgIndex.tcl
      }
      #puts stderr "callinglevel <[current callinglevel]> $fls"

      #
      # redefine the logging behavior to show just error or warnings,
      # preceded by the current directory
      #
      #set ::current [pwd]
      proc ::tclLog msg {
	if {[regexp {^(error|warning)} $msg]} {
	  if {[regexp -nocase error $msg]} {
	    error $msg
	  }
	  puts stderr "$msg ([pwd])"
	}
      }
      
      set flags "-verbose -direct -load nsf"
      # the following test is just an approximization, loading nsf +
      # nx does not seem to work for binary extensions (e.g. mongodb)
      if {$fls ne "nx.tcl" && ![string match "*[info sharedlibextension]" $fls]} {
	append flags " -load nx"
      }
      #package prefer latest
      if {$::verbose} {puts stderr "[pwd]:\n\tcall pkg_mkIndex $flags . $fls"}
      pkg_mkIndex {*}$flags . {*}$fls
      if {$::verbose} {puts stderr "[pwd] done"}
    }
    
    foreach addFile [glob -nocomplain *.add] {
      if {[file exists $addFile]} {
        puts stderr "Appending $addFile to pkgIndex.tcl in [pwd]"
        set OUT [file open pkgIndex.tcl a]
        set IN [file open $addFile]
        puts -nonewline $OUT [read $IN]
        close $IN; close $OUT
      }
    }

    #puts stderr "+++ mkIndex name=$name, pwd=[pwd] DONE"
  }

  :public object method inEachDir {path cmd} {
    if {$::verbose} {puts stderr "[pwd] inEachDir $path (dir [file isdirectory $path]) $cmd"}
    if { [file isdirectory $path] 
         && ![string match *CVS $path]
         && ![string match *SCCS $path]
         && ![string match *Attic $path]
         && ![string match *dbm* $path]
       } {
      set olddir [pwd]
      cd $path
      if {[catch {make {*}$cmd $path} errMsg]} {
	error  "$errMsg (in directory [pwd])"
      }
      set files [glob -nocomplain *]
      cd $olddir
      foreach p $files { :inEachDir $path/$p $cmd }
      if {$::verbose} {puts stderr "+++ change back to $olddir"}
    }
  }

  :object method in {path cmd} {
    if {[file isdirectory $path] && ![string match *CVS $path]} {
      set olddir [pwd]
      cd $path
      make {*}$cmd $path
      cd $olddir
    }
  }
}

### Tcl file-command
rename file tcl_file
nx::Object create file {
  :require namespace

  array set :destructive {
    atime 0       attributes 0  copy 1       delete 1      dirname 0
    executable 0  exists 0      extension 0  isdirectory 0 isfile 0
    join 0        lstat 0       mkdir 1      mtime 0       nativename 0
    owned 0       pathtype 0    readable 0   readlink 0    rename 1
    rootname 0    size 0        split 0      stat 0        tail 0
    type 0        volumes 0     writable 0
  }

  foreach subcmd [array names :destructive] {
    :public object method $subcmd args {
      #puts stderr " [pwd] call: '::tcl_file [current method] $args'"
      ::tcl_file [current method] {*}$args
    }
  }
}

rename open file::open
proc open {f {mode r}} { file open $f $mode }


### minus n option
nx::Class create make::-n
foreach f [file info object methods] {
  if {$f eq "unknown" || $f eq "next" || $f eq "self"} continue
  if {![file exists destructive($f)] || [file eval [list set :destructive($f)]]} {
    #puts stderr destruct=$f
    make::-n method $f args {
	puts "--- [pwd]:\t[current method] $args"
    }
  } else {
    #puts stderr nondestruct=$f
    make::-n method $f args {
      set r [next]
      #puts "??? [current method] $args -> {$r}"
      return $r
    }
  }
}

### command line parameters
if {![info exists argv] || $argv eq ""} {set argv -all}
if {$argv eq "-n"} {set argv "-n -all"}

nx::Class create Script {
  :public object method create args {
    lappend args {*}$::argv
    set s [next]
    set method [list]
    foreach arg [lrange $args 1 end] {
      switch -glob -- $arg {
        "-all" {$s all}
        "-n" {$s n}
        "-*" {set method [string range $arg 1 end]}
        default {
	  puts "$s $method $arg"
	  $s $method $arg
	}
      }
    }
  }

  :object method unknown args {
    puts stderr "$::argv0: Unknown option ´-$args´ provided"
  }

  :public method n {} {file mixin make::-n}

  :public method all {} {make inEachDir . mkIndex}

  :public method dir {dirName} {cd $dirName}

  :public method target {path} {make eval [list set :target $path]}

  if {[catch {:create main} errorMsg]} {
    puts stderr "*** $errorMsg"
    # Exit silently, alltough we are leaving from an active stack
    # frame.
    ::nsf::configure debug 0
    exit -1
  }
}

#puts stderr "+++ make.tcl finished."

#exit $::result
