# Package - provide a [package] work-alike with db backing
# [package require Package]
# http://code.google.com/p/wub/source/browse/trunk/Utilities/Package.tcl

# Completely replaces package with a version which tracks additions to (note: not subtractions from) ::auto_path. First time it ever runs it creates a database under ~/.tclpkg into which it stores all the packages it finds. Thereafter, it satisfies all [package require] calls from that database, never traversing the filesystem again, unless and until ::auto_path changes to include a new, as yet unseen, directory.

# This is faster than filesystem traversal, and provides a centralised database of all known/seen packages. This speed comes at a cost, of course: changes to the underlying file system will *not* be noticed by or reflected in Package. As things stand, the database would have to be removed to reflect these changes when it is automatically rebuilt.

package require sqlite3
package require tdbc::sqlite3

package provide Package 1.0

set ::API(Utilities/Package) {
    {
	Package - provide a [[package]] work-alike with db backing
    }
}


namespace eval ::tcl::package {
    variable Debug 1
    proc puts {args} {
	variable Debug
	if {$Debug} {
	    ::puts {*}$args
	}
    }

    # calculate old-school package subcommands
    catch {package moop} e eo
    set e [split [lindex [split [dict get $eo -errorinfo] \n] 0] ,]
    set e [lreplace $e 0 0 [lindex [split [lindex $e 0]] end]]
    set e [lreplace $e end end [lindex [split [lindex $e end]] end]]
    variable orgsubs {}
    foreach eo $e {
	lappend orgsubs [string trim $eo]
    }
    unset e; unset eo

    package require md5
    variable libv [::md5::md5 -hex [file normalize [info library]]]
    variable dbfile ~/.tclpkg.$libv
    variable repo ~/.tclrepo
    catch {file mkdir $repo}

    # open DB
    tdbc::sqlite3::connection create pdb $dbfile
    variable live [catch {
	pdb allrows {
	    CREATE TABLE package (package TEXT NOT NULL,
				  version TEXT NOT NULL,
				  script TEXT NOT NULL,
				  dir TEXT,
				  PRIMARY KEY (package,version)
				  );
	}
	pdb allrows {
	    CREATE INDEX pindex ON package (package,version);
	}
	pdb allrows {
	    CREATE TABLE path (path TEXT NOT NULL,
			       date INT NOT NULL,
			       PRIMARY KEY (path)
			       );
	}
	pdb allrows {
	    CREATE INDEX pathindex ON path (path);
	}
    } e eo]
    #puts stderr "DB: $e: $eo"

    # construct DB statements
    foreach {name stmt} {
	del {DELETE from package WHERE package = :package AND version = :version}
	replace {REPLACE INTO package (package, version, script, dir) VALUES (:package, :version, :script, :dir)}
	version {SELECT * FROM package WHERE package = :package AND version = :version}
	find {SELECT * FROM package WHERE package = :package}
	findD {SELECT * FROM package WHERE package = :package ORDER BY version DESC}
	paths {SELECT * FROM path}
	addpath {REPLACE INTO path (path, date) VALUES (:path, :date)}
    } {
	set statement($name) [pdb prepare $stmt]
    }

    # create our own [package unknown] command
    variable oldunknown [package unknown]
    proc unknown {args} {
	puts stderr "Package: UNKNOWN: $args"
	variable oldunknown
	return [{*}$oldunknown {*}$args]
    }
    package unknown [namespace code unknown]

    # create a wrapper around each existing package subcommand
    foreach n $orgsubs {
	if {"::tcl::package::$n" ni [info commands ::tcl::package::*]} {
	    {*}[string map [list %N% $n] {
		proc %N% {args} {
		    set result [uplevel [list [namespace current]::_package %N% {*}$args]]
		    puts stderr "Package: called package %N% $args -> $result"
		    return $result
		}
	    }]
	}
    }

    # forward unimplemented subcommands
    proc _unknown {cmd subcmd args} {
	variable orgsubs
	if {$subcmd in $orgsubs} {
	    set result [list [namespace current]::_package $subcmd {*}$args]
	    puts stderr "Package: $cmd $subcmd $args -> $result"
	    return $result
	} else {
	    error "bad option $subcmd: must be [join $orgsubs ,]"
	}
    }

    # install the contents of this ns as an ensemble over ::package
    rename ::package ::tcl::package::_package

    # create ::package as an ensemble
    namespace export -clear *
    namespace ensemble create -command ::package -subcommands {} -unknown ::tcl::package::_unknown

    variable priming 0	;# we're not currently priming
    variable paths {}	;# cache of known paths

    # track changes to ::auto_path
    proc pathchange {args} {
	variable paths
	variable statement
	puts stderr "Package: PathChange $::auto_path ($paths)"
	set new 0
	set date [clock seconds]
	foreach path $::auto_path {
	    set path [file normalize $path]
	    if {![dict exists $paths $path]} {
		$statement(addpath) allrows
		dict set paths $path $date
		puts stderr "Package: PathChanged $path"
		incr new
	    }
	}
	variable priming
	if {$new && !$priming} {
	    priming
	}
    }

    # prime the db
    proc priming {} {
	variable priming
	if {$priming} return
	set priming 1

	variable paths
	puts stderr "Package: PRIMING $::auto_path ($paths)"

	# collect and store in db each ifneeded script
	proc ifneeded {package version script} {
	    variable statement
	    upvar 1 dir dir	;# this is supposed to be the active dir, but isn't
	    set found [$statement(version) allrows -as lists]
	    if {![llength $found]} {
		$statement(replace) allrows
		puts stderr "Package: Priming ifneeded $package $version $script"
	    }
	}

	proc require {args} {
	    set result [uplevel [list [namespace current]::_package require {*}$args]]
	    puts stderr "Package: called package require $args -> $result"
	    return $result
	}

	# collect and store any additionally provided packages
	variable statement
	foreach package [_package names] {
	    set script ""
	    set versions [_package versions $package]
	    if {[llength $versions]} {
		# here's a package with multiple versions
		foreach version $versions {
		    set found [$statement(version) allrows -as lists]
		    if {![llength $found]} {
			set script [_package ifneeded $package $version]
			puts stderr "Package: PRELOAD: $package $version $script"
			$statement(replace) allrows
		    }
		}
	    } else {
		# this package has no versions, must be builtin
		set script ""
		set version [_package present $package]
		set found [$statement(version) allrows -as lists]
		if {![llength $found]} {
		    $statement(replace) allrows
		    puts stderr "Package: BUILTIN $package"
		}
	    }
	}

	# force traversal of the whole ::auto_path, collecting ifneeded data
	catch {package require __MOOOP____}
	running
    }

    # replace the collector ifneeded script with the real one
    proc running {} {
	variable priming 0
	proc ifneeded {package version {script ""}} {
	    if {$script eq ""} {
		set d [$statement(version) allrows -as dicts]
		if {[dict size $d]} {
		    puts stderr "Package: ifneeded $package $version -> [dict get $d script]"
		    return [dict get $d script]
		} else {
		    puts stderr "Package: ifneeded $package $version -> UNREGISTERED"
		    return ""
		}
	    } else {
		$statement(replace) allrows
		puts stderr "Package: ifneeded $package $version -> [dict get $d script]"
		return ""
	    }
	}

	# what versions do we know about?
	proc versions {package} {
	    variable statement
	    set v {}
	    $statement(find) foreach -as dicts d {
		lappend v [dict get $d version]
	    }
	    puts stderr "Package: versions $package -> $v"
	    return $v
	}

	proc require {args} {
	    # parse args
	    if {[string match -exact [lindex $args 0]]} {
		set exact 1
		set package [lindex $args end-1]
		set version [lindex $args end]

		puts stderr "Package: require -exact $package '$version'"
		if {![catch {_package present $package} present]} {
		    return $present
		}

		set match [$statement(version) allrows -as dicts]
		if {[llength $match]} {
		    uplevel #0 [dict get [lindex $match 0] script]
		    return $version
		} else {
		    return ""
		}
	    }

	    set package [lindex $args 0]
	    if {[llength $args] > 1} {
		set version [lindex $args end]
	    }

	    variable statement
	    if {[info exists version]} {
		# run query over all matches, check requirement
		set ds [$statement(findD) allrows -as dicts]
		if {![llength $ds]} {
		    return ""
		}
		foreach d $ds {
		    if {[_package vsatisfies [dict get $d version] $version]} {
			puts stderr "Package: $package,$version is vsatisfied by ($d)"
			break
		    } else {
			puts stderr "Package: ($d) does not satisfy $package,$version"
		    }
		}
	    } elseif {![catch {_package present $package} present]} {
		return $present
	    } else {
		# no version, get highest available
		set d [$statement(findD) allrows -as dicts]
		if {![llength $d]} {
		    error "no package $package"
		    return ""
		} else {
		    set d [lindex $d 0]
		    puts stderr "Package: no version of $package specified, found singleton ($d)"
		}
	    }

	    dict with d {
		if {$script ne ""} {
		    puts stderr "Package: Running: $d"
		    uplevel #0 $script
		}
		return $version
	    }
	}
    }

    proc pkgFILE {cmd args} {
	switch -- $cmd {
	    join {
		return [file join {*}$args]
	    }
	    default {
		error "Can't call file $cmd"
	    }
	}
    }

    # mount a zip file for processing
    proc zmount {file} {
	package require vfs::zip
	set file [file normalize $file]
	set root [file rootname $file]
	file mkdir $root
	::vfs::zip::Mount $file $root
	return $root
    }

    # add a zip archive to the package search space via vfs
    proc zip {file args} {
	package require vfs::zip
	set file [file normalize $file]
	set mp [zmount $file]
	set indices {}
	foreach index [list $mp {*}[glob -directory $mp *]] {
	    if {[file isdirectory $index]} {
		set index [file join $index pkgIndex.tcl]
		if {[file exists $index]} {
		    lappend indices $index
		}
	    }
	}

	if {![llength $indices]} {
	    # no pkgIndex.tcl - this isn't a zipped package
	    # TODO: define a different style of metadata?
	    error "Zip package $file doesn't contain a pkgIndex.tcl"
	} else {
	    interp create -safe zipper
	    zipper alias ::package ::package zipIN $file $mp
	    zipper alias ::file ::package pkgFILE
	    foreach index $indices {
		puts stderr "Package: zip adding $index"
		set fd [open $index]; set content [read $fd]; close $fd
		zipper eval [list set dir [file dirname $index]]
		zipper eval [list eval $content]
	    }
	    interp delete zipper
	}
    }

    # track zipper's auto_path
    proc zipauto_path {args} {
	lappend ::auto_path {*}[zipper eval {set ::auto_path}]
    }

    # intercept zipper's ::package calls, paying attention to ifneeded
    proc zipIN {zip mp command args} {
	variable statement
	switch -- $command {
	    ifneeded {
		set script ""
		lassign $args package version script
		set found [$statement(version) allrows -as dicts]
		if {![llength $found]} {
		    # this is a new script
		    if {$script ne ""} {
			set script "package zmount $zip; $script"
			$statement(replace) allrows
			puts stderr "Package: Zip Priming ifneeded $package $version $script"
		    } else {
			return $script
		    }
		} elseif {$script eq ""} {
		    return [dict get [lindex $found 0] script $script]
		} else {
		    # we have a zip file seeking to override an existing mapping
		    # what to do?  Do nothing ATM.  Could optionally permit it,
		    # could error on conflict ...
		}
	    }
	    default {
		# perform normal package thing
		return [$command {*}$args]
	    }
	}
    }

    # add an http archive to the package search space via vfs
    proc http {url args} {
	package require vfs::http
	package require md5

	variable repo; set repo [file normalize $repo]
	set mp [file join $repo HTTP.[md5::md5 -hex $url]]
	if {[file exists $mp]} {
	    return
	}
	file mkdir $mp
	set root [file join $mp .http]
	file mkdir $root
	::vfs::http::Mount $url $root

	set index [file join $root pkgIndex.tcl]
	if {![file exists $index]} {
	    # no pkgIndex.tcl - this isn't a httpped package
	    # TODO: define a different style of metadata?
	    error "Http package $url doesn't contain a pkgIndex.tcl"
	} else {
	    puts stderr "Package: http adding $index to $mp"
	    file copy $index $mp
	    interp create -safe httper
	    httper alias ::package [namespace current]::httpIN $root $mp
	    httper alias ::load [namespace current]::http_copy $root $mp
	    httper alias ::source [namespace current]::http_copy $root $mp
	    httper alias ::file [namespace current]::pkgFILE
	    set fd [open $index]; set content [read $fd]; close $fd
	    httper eval [list set dir @BASE@]
	    httper eval [list eval $content]
	    interp delete httper
	}
	::vfs::http::Unmount $url $root
	file delete $root
    }

    proc http_copy {root mp file} {
	puts stderr "Package: http copying $file to $mp"
	file copy [string map [list @BASE@ $root] $file] $mp
    }

    # intercept httper's ::package calls, paying attention to ifneeded
    proc httpIN {root mp command args} {
	variable statement
	switch -- $command {
	    ifneeded {
		set script ""
		lassign $args package version script
		set found [$statement(version) allrows -as dicts]
		if {![llength $found]} {
		    # this is a new script
		    if {$script ne ""} {
			httper eval $script	;# run the install script, to copy files across
			set script [string map [list @BASE@ $mp] $script]
			$statement(replace) allrows
			puts stderr "Package: Http Priming ifneeded $package $version $script"
		    } else {
			return $script
		    }
		} elseif {$script eq ""} {
		    return [dict get [lindex $found 0] script $script]
		} else {
		    # we have a http file seeking to override an existing mapping
		    # what to do?  Do nothing ATM.  Could optionally permit it,
		    # could error on conflict ...
		}
	    }
	    default {
		# perform normal package thing
		return [$command {*}$args]
	    }
	}
    }

    proc teapot {package version {arch tcl}} {
	variable repo; set repo [file normalize $repo]
	puts stderr "Package: teapot $package $version $arch"
	set url "http://teapot.activestate.com/package/name/$package/ver/$version/arch/$arch/"
	set mp TEAPOT.[md5::md5 -hex $package-$version-$arch]
	if {$arch eq "tcl"} {
	    append url file.tm
	    append mp .tm
	} else {
	    append url file.zip
	    append mp .zip
	}
	set mp [file join $repo $mp]
	if {[file exists $mp]} {
	    return
	}

	package require http
	set token [::http::geturl $url]
	switch -- [::http::status $token] {
	    ok {
		set fd [open $mp wb]
		fconfigure $fd 
		puts -nonewline $fd [::http::data $token]
		close $fd
		::http::cleanup $token

		if {$arch eq "tcl"} {
		    variable statement
		    set script [list source $mp]
		    set found [$statement(version) allrows -as dicts]
		    if {![llength $found]} {
			# this is a new script
			$statement(replace) allrows
			puts stderr "Package: TEA Priming ifneeded $package $version $script"
		    } else {
			# what to do about conflicting versions?
		    }
		} else {
		    return [zip $mp]
		}
	    }
	    default {
		set error [::http::error $token]
		::http::cleanup $token
	    }
	}
    }

    # track changes to ::auto_path
    trace add variable ::auto_path write [namespace code pathchange]

    if {!$live} {
	pathchange
	priming
    } else {
	# build cache of known paths
	variable paths
	$statement(paths) foreach -as dicts d {
	    dict set paths [dict get $d path] [dict get $d date]
	}
	running
    }
}

if {[info exists argv0] && ($argv0 eq [info script])} {
    package require Package	;# start the cooption of [package]

    puts stderr "Package: DONE PRIMING"
    package require Tcl
    package require fileutil
    package zip ziptest.zip
    package require ZipTest

    package http http://wub.googlecode.com/svn/trunk/Client/
    puts stderr "Package: Loaded Client"
    package require HTTP

    package teapot ceptcl 0.3 linux-glibc2.3-ix86
    package require ceptcl
    cep localhost 8080

    package require moop	;# doesn't exist
}
