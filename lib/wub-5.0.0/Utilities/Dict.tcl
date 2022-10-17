# Extra useful dict commands - a dict enhancer, if you will
# code from patthoyts and nem (http://wiki.tcl.tk/17686)

package provide Dict 1.0

namespace eval ::tcl::dict {
    # dict witharray dictVar arrayVar script --
    #
    #       Unpacks the elements of the dictionary in dictVar into the array
    #       variable arrayVar and then evaluates the script. If the script
    #       completes with an ok, return or continue status, then the result is copied
    #       back into the dictionary variable, otherwise it is discarded. A
    #       [break] can be used to explicitly abort the transaction.
    #
    proc witharray {dictVar arrayVar script} {
	upvar 1 $dictVar dict $arrayVar array
	array set array $dict
	try {
	    uplevel 1 $script
	} on break    {}     { # Discard the result
	} on continue result - on ok result {
	    ::set dict [array get array] ;# commit changes
	    return $result
	} on return   {result opts} {
	    ::set dict [array get array] ;# commit changes
	    dict incr opts -level ;# remove this proc from level
	    return -options $opts $result
	}
	# All other cases will discard the changes and propagage
    }

    # dict equal equalp d1 d2 --
    #
    #       Compare two dictionaries for equality. Two dictionaries are equal
    #       if they (a) have the same keys, (b) the corresponding values for
    #       each key in the two dictionaries are equal when compared using the
    #       equality predicate, equalp (passed as an argument). The equality
    #       predicate is invoked with the key and the two values from each
    #       dictionary as arguments.
    #
    proc equal {equalp d1 d2} {
	if {[dict size $d1] != [dict size $d2]} { return 0 }
	dict for {k v} $d1 {
	    if {![dict exists $d2 $k]} { return 0 }
	    if {![invoke $equalp $k $v [dict get $d2 $k]]} { return 0 }
	}
	return 1
    }

    # apply dictVar lambdaExpr ?arg1 arg2 ...? --
    #
    #       A combination of *dict with* and *apply*, this procedure creates a
    #       new procedure scope populated with the values in the dictionary
    #       variable. It then applies the lambdaTerm (anonymous procedure) in
    #       this new scope. If the procedure completes normally, then any
    #       changes made to variables in the dictionary are reflected back to
    #       the dictionary variable, otherwise they are ignored. This provides
    #       a transaction-style semantics whereby atomic updates to a
    #       dictionary can be performed. This procedure can also be useful for
    #       implementing a variety of control constructs, such as mutable
    #       closures.
    #
    proc apply {dictVar lambdaExpr args} {
	upvar 1 $dictVar dict
	::set env $dict ;# copy
	lassign $lambdaExpr params body ns
	if {$ns eq ""} { ::set ns "::" }
	::set body [format {
	    upvar 1 env __env__
	    dict with __env__ %s
	} [::list $body]]
	::set lambdaExpr [::list $params $body $ns]
	::set rc [catch { ::apply $lambdaExpr {*}$args } ret opts]
	if {$rc == 0} {
	    # Copy back any updates
	    ::set dict $env
	}
	return -options $opts $ret
    }

    # capture ?level? ?exclude? ?include? --
    #
    #       Captures a snapshot of the current (scalar) variable bindings at
    #       $level on the stack into a dictionary environment. This dictionary
    #       can later be used with *dictutils apply* to partially restore the
    #       scope, creating a first approximation of closures. The *level*
    #       argument should be of the forms accepted by *uplevel* and
    #       designates which level to capture. It defaults to 1 as in uplevel.
    #       The *exclude* argument specifies an optional list of literal
    #       variable names to avoid when performing the capture. No variables
    #       matching any item in this list will be captured. The *include*
    #       argument can be used to specify a list of glob patterns of
    #       variables to capture. Only variables matching one of these
    #       patterns are captured. The default is a single pattern "*", for
    #       capturing all visible variables (as determined by *info vars*).
    #
    proc capture {{level 1} {exclude {}} {include {*}}} {
	if {[string is integer $level]} { incr level }
	::set env [dict create]
	foreach pattern $include {
	    foreach name [uplevel $level [::list info vars $pattern]] {
		if {[lsearch -exact -index 0 $exclude $name] >= 0} { continue }
		upvar $level $name value
		catch { dict set env $name $value } ;# no arrays
	    }
	}
	return $env
    }

    # nlappend dictVar keyList ?value ...?
    #
    #       Append zero or more elements to the list value stored in the given
    #       dictionary at the path of keys specified in $keyList.  If $keyList
    #       specifies a non-existent path of keys, nlappend will behave as if
    #       the path mapped to an empty list.
    #
    proc nlappend {dictvar keylist args} {
	upvar 1 $dictvar dict
	if {[info exists dict] && [dict exists $dict {*}$keylist]} {
	    ::set list [dict get $dict {*}$keylist]
	}
	lappend list {*}$args
	dict set dict {*}$keylist $list
    }
    
    # invoke cmd args... --
    #
    #       Helper procedure to invoke a callback command with arguments at
    #       the global scope. The helper ensures that proper quotation is
    #       used. The command is expected to be a list, e.g. {string equal}.
    #
    proc invoke {cmd args} { uplevel #0 $cmd $args }
    
    # dict get? courtesy patthoyts
    proc get? {dict args} {
	if {[dict exists $dict {*}$args]} {
	    return [dict get $dict {*}$args]
	} else {
	    return {}
	}
    }

    # construct a dict with empty elements whose keys are passed
    proc list {args} {
	::set o {}
	::foreach l $args {
	    ::dict set o {*}$l {}
	}
	return $o
    }

    # return the dict subset specified by args
    proc in {dict args} {
	if {[llength $args] == 1} {
	    ::set args [lindex $args 0]
	}
	return [dict filter $dict script {k v} {
	    expr {$k in $args}
	}]
    }

    # return the dict subset specified by args
    proc ni {dict args} {
	if {[llength $args] == 1} {
	    ::set args [lindex $args 0]
	}
	return [dict filter $dict script {k v} {
	    expr {$k ni $args}
	}]
    }

    # return three dicts:
    # values unchanged between d1 and d2
    # values deleted from d1 by d2
    # values added by d2
    proc diff {d1 d2} {
	::set del {}
	dict for {n v} $d1 {
	    if {[dict exists $d2 $n]} {
		if {[dict get $d2 $n] ne $v} {
		    # record new value
		    dict set del $n $v
		    dict unset d1 $n	;# it changed
		} else {
		    # leave it in d1, it's unchanged
		    dict unset d2 $n
		}
	    } else {
		dict set del $n $v
		dict unset d1 $n	;# it changed
	    }
	}
	return [::list $d1 $del $d2]
    }

    # set a dict element, only if it doesn't already exist
    proc set? {var args} {
	upvar 1 $var dvar
	::set val [lindex $args end]
	::set name [lrange $args 0 end-1]
	
	if {![::info exists dvar] || ![dict exists $dvar {*}$name]} {
	    dict set dvar {*}$name $val
	    return $args
	} else {
	    return {}
	}
    }

    # unset a dict element if it exists
    proc unset? {var args} {
	upvar 1 $var dvar
	if {[dict exists $dvar {*}$args]} {
	    dict unset dvar {*}$args
	}
    }

    # dict switch dict args... --
    #
    # Apply matching functions from the second dict (or $args)
    # replacing existing values with the function application's return
    #
    # dict switch record {
    #	name {string tolower $name}
    #	dob {...}
    # }

    proc switch {d args} {
	upvar 1 $d dict
	if {[llength $args] == 1} {
	    ::set args [lindex $args 0]
	}
	dict for {n v} $dict {
	    if {[dict exists $args $n]} {
		dict set dict $n [uplevel 1 [::list ::apply [::list $n [dict get $args $n]] $v]]
	    }
	}
	return $dict
    }

    # side effect free variant of switch
    proc transmute {dict args} {
        if {[llength $args] == 1} {
            ::set args [lindex $args 0]
        }
        dict for {n v} $dict {
            if {[dict exists $args $n]} {
                dict set dict $n [uplevel 1 [::list ::apply [::list $n [dict get $args $n]] $v]]
            }
        }
        return $dict
    }


    if {0} {
	# [dict_project $keys $dict] extracts the specified keys in $args from the $dict
	# and returns a plain old list-of-values.
	proc project {dict args} {
	    ::set result {}
	    foreach k $args {
		lappend result [dict get $dict $k]
	    }
	    return $result
	}

	# [dict_select $keys $dicts] does the same thing to a list-of-dicts, returning a list-of-lists.
	proc select {keys args} {
	    return [map [::list dict project $keys] $args]
	}
    }

    foreach x {get? set? unset? witharray equal apply capture nlappend in ni list diff switch transmute} {
	namespace ensemble configure dict -map [linsert [namespace ensemble configure dict -map] end $x ::tcl::dict::$x] -unknown {::apply {{dict cmd args} {
	    if {[string first . $cmd] > -1} {
		if {[string index $cmd end] eq "?"} {
		    ::set opt ?
		    ::set cmd [string trim $cmd ?]
		} else {
		    ::set opt ""
		}
		::set cmd 
		if {[llength $args]} {
		    # [dict a.b.c] -> [dict get $a b c]
		    return [::list dict set$opt {*}[::split $cmd .]]
		} else {
		    # [dict a.b.c x] -> [dict set a b c x]
		    ::set cmd [::lassign [::split $cmd .] var]
		    ::upvar 1 $var v
		    return [::list dict get$opt $v {*}$cmd]
		}
	    }
	} ::tcl::dict}}
    }
    ::unset x
}

namespace eval ::Dict {
    # return a dict element, or {} if it doesn't exist
    proc get? {dict args} {
	if {$args eq {}} {
	    return {}
	}
	if {[dict exists $dict {*}$args]} {
	    return [dict get $dict {*}$args]
	} else {
	    return {}
	}
    }

    # modify a dict var with the args-dict given
    proc modify {var args} {
	if {[llength $args] == 1} {
	    ::set args [lindex $args 0]
	}
	upvar 1 $var dvar
	::set dvar [dict merge $dvar $args]
    }

    # fill a dict with default key/value pairs as defaults
    # if a key already exists, it is unperturbed.
    proc defaults {var args} {
	if {[llength $args] == 1} {
	    ::set args [lindex $args 0]
	}
	upvar 1 $var dvar
	foreach {name val} $args {
	    dict set? dvar $name $val
	}
    }

    # trim the given chars from a dict's keyset
    proc trimkey {dict {trim -}} {
	dict for {key val} $dict {
	    ::set nk [string trim $key $trim]
	    if {$nk ne $key} {
		dict set dict $nk $val
		dict unset dict $key
	    }
	}
	return $dict
    }

    # return dict keys, sorted by some subkey value
    proc subkeyorder {dict subkey args} {
	if {[llength $args] == 1} {
	    ::set args [lindex $args 0]
	}
	# build a key/value list where value is extracted from subdict
	::set kl {}
	dict for {key val} $dict {
	    lappend kl [::list $key [dict get $val $subkey]]
	}

	# return keys in specified order
	::set keys {}
	foreach el [lsort -index 1 {*}$args $kl] {
	    lappend keys [lindex $el 0]
	}

	return $keys
    }

    # return dict as list sorted by key
    proc keysorted {dict args} {
	::set result {}
	foreach key [lsort {*}$args [dict keys $dict]] {
	    lappend result $key [dict get $dict $key]
	}
	return $result
    }

    # strip a set of keys from a dict
    proc strip {var args} {
	if {[llength $args] == 1} {
	    ::set args [lindex $args 0]
	}
	upvar 1 $var dvar
	foreach key $args {
	    if {[dict exists $dvar $key]} {
		dict unset dvar $key
	    }
	}
    }

    # use a dict as a cache for the value of the $args-expression
    proc cache {dict name args} {
	if {[llength $args] == 1} {
	    ::set args [lindex $args 0]
	}
	upvar dict dict
	if {[info exists $dict $name]} {
	    return [dict get $dict $name]
	} else {
	    dict set dict [set retval [uplevel $args]]
	    return $retval
	}
    }

    # return the dict subset specified by args
    proc subset {dict args} {
	if {[llength $args] == 1} {
	    ::set args [lindex $args 0]
	}
	::set result {}
	dict for {k v} $dict {
	    if {$k in $args} {
		dict set result $k $v
	    }
	}
	return $result

	return [dict filter $dict script {k v} {
	    expr {$k in $args}
	}]
    }

    # return the values specified by args
    proc getall {dict args} {
	if {[llength $args] == 1} {
	    ::set args [lindex $args 0]
	}
	return [dict values [dict filter $dict script {k v} {
	    expr {$k in $args}
	}]]
    }

    # convert directory to dict
    proc dir {dir {glob *}} {
	::set content {}
	foreach file [glob -nocomplain -directory $dir $glob] {
	    while {[file type $file] eq "link"} {
		::set file [file readlink $file]
	    }

	    ::switch -- [file type $file] {
		directory {
		    ::set extra "/"
		}
		file {
		    ::set extra ""
		}
		default {
		    continue
		}
	    }

	    catch {unset attr}
	    file stat $file attr
	    ::set name [file tail $file]
	    dict set content $name [array get attr]
	    foreach {x y} [file attributes $file] {
		dict set content $name $x $y
	    }
	    foreach {x y} [dict get $content $name] {
		if {[string match *time $x]} {
		    dict set content $name $x [clock format $y -format {%Y-%m-%d %H:%M:%S}]
		}
		if {$x eq "size"
		    && [file type $file] eq "directory"
		} {
		    dict set content $name $x [expr {[dict get $content $name nlink] - 2}]
		}
	    }
	    dict set content $name name [<a> href $name $name$extra]
	}
	return $content
    }

    proc vars {dvar args} {
	::set script [::list dict with $dvar]
	foreach a $args {
	    lappend script $a $a
	}
	uplevel 1 $script {{}}
    }

    namespace export -clear *
    namespace ensemble create -subcommands {}
}

if {[info exists argv0] && ($argv0 eq [info script])} {
    set a {b {c 1 d 0} c 2 d 3}
    puts [time {dict a.b.c}]
    puts [time {dict a.b.c}]
    puts [time {dict get $a b c}]
    puts [time {dict get? $a b c}]
    puts [time {dict a.b.q?}]
}
# vim: ts=8:sw=4:noet
