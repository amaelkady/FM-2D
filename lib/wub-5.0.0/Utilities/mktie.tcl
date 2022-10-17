# mktie.tcl --
#
#	Tie arrays of dicts to Mk 
#

# ### ### ### ######### ######### #########
## Requisites

package require tie

if {[info exists argv0] && ($argv0 eq [info script])} {
    lappend auto_path [pwd] ~/Desktop/Work/Wub/Utilities/ ~/Desktop/Work/Wub/extensions/
}

package require View
package provide mktie 2.0

# ### ### ### ######### ######### #########
## Implementation

namespace eval ::mktie {
    # ### ### ### ######### ######### #########
    ## API : Construction & Destruction

    # called by tie
    proc %AUTO% {args} {
	init {*}$args
    }

    variable count 0
    proc init {args} {
	Debug.mktie {init $args}
	foreach {n v} $args {
	    set $n $v
	}

	variable count; set cmd tie[incr count]

	# no view supplied
	if {[info exists db] || [info exists file]} {
	    if {[info exists file]} {
		# open/create an existing file
		if {![info exists db]} {
		    set db tie
		}
		mk::file open $db $file
	    }

	    if {![info exists view]} {
		set view tie
	    }

	    if {$view ni [mk::file views $db]} {
		if {![info exists index]} {
		    set index name	;# default index is name
		}

		if {![info exists layout]} {
		    Debug.mktie {default layout}
		    mk::view layout $db.$view [list $index:S value:S]
		} else {
		    Debug.mktie {layout '$layout'}
		    mk::view layout $db.$view [View pretty $layout]
		}
		set view [View init ${cmd}V $db.$view]	;# initialize the view
	    } else {
		# got a view in the db
		set view [View init ${cmd}V $db.$view]	;# initialize the view
		if {![info exists index]} {
		    set index [lindex [$view names] 0]	;# default is first element
		}
		Debug.mktie {existing layout '[$view properties]'}
	    }
	} elseif {[info exists view]} {
	    if {![info exists index]} {
		set index [lindex [$view names] 0]	;# default is first element
	    }
	}

	foreach el {destroy names size get set unset setv unsetv getv} {
	    dict set map $el [list _$el $view $index]
	}

	dict set map destroy [list _destroy [namespace current]::$cmd $view]
	set en [namespace ensemble create -command $cmd -map $map -subcommands {}]
	Debug.mktie {tie: $en ([$view properties])}
	return $en
    }

    # destroy the tie
    proc _destroy {cmd view} {
	$view close
	unset $cmd
    }

    # ### ### ### ######### ######### #########
    ## API : Data source methods

    # equiv: array get
    proc _get {view index} {
	set result {}
	foreach idx [$view select] {
	    set rec [$view get $idx]
	    lappend result [dict get $rec $index] $rec
	}

	Debug.mktie {_get $result}
	return $result
    }
    
    # equiv array set
    proc _set {view index dict} {
	dict for {n v} $dict {
	    catch {dict unset v $index}
	    if {[catch {$view find $index $n} cursor]} {
		$view append $ov $n {*}$v
	    } else {
		$view set $cursor $ov $n {*}$v
	    }
	}
    }

    # equiv array unset
    proc _unset {view index {pattern *}} {
	foreach idx [lreverse [$view lselect -glob $index $pattern]] {
	    $view delete $idx
	}
    }

    # equiv array names
    proc _names {view index} {
	return [$view with {
	    set $index
	}]
    }

    # equiv array size
    proc _size {view index} {
	return [$view size]
    }

    # equiv $a($name)
    proc _getv {view index name} {
	Debug.mktie {getv '$name'}
	return [$view get [$view find $index $name]]
    }

    # equiv [set a($name) $value]
    proc _setv {view index name value} {
	Debug.mktie {setv '$name' '$value'}
	if {$name eq ""} {
	    set {*}$value
	    return
	}

	if {[catch {$view find $index $name} cursor]} {
	    Debug.mktie {setv $name $value APPEND} 3
	    $view append $index $name {*}$value
	} else {
	    Debug.mktie {setv $name $value SET}
	    $view set $cursor $index $name {*}$value
	}
    }

    # equiv unset a($name)
    proc _unsetv {view index name} {
	Debug.mktie {unsetv $name}
	$view delete [$view find $index $name]
    }

    namespace export -clear *
    namespace ensemble create -subcommands {}
}

::tie::register mktie as mktie

if {[info exists argv0] && ($argv0 eq [info script])} {
    Debug on mktie 1000
    array set test {}
    ::tie::tie test -open -merge mktie file mktie.db layout "uid:I user:S email:S count:I" index uid
    puts "[::tie::info ties test] - [array size test]"

    if {[info exists test(0)]} {
	set uid [expr {int(rand() * 1000)}]
	set test($uid) [dict create uid $uid user user$uid email user$uid@fred]
    } else {
	set uid 0
	set test(0) [dict create uid 0 user root email root@fred]
	set test(1) [dict create uid 1 user colin email colin@fred]
    }

    puts "Array: [array get test]"
    puts $test(0)
    puts $test($uid)
    puts [dict get $test(0) uid]
    puts [dict incr test(0) count]
}
