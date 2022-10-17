# Debug - a debug narrative logger.
#
# Debugging areas of interest are represented by 'tokens' which have 
# independantly settable levels of interest (an integer, higher is more detailed)
#
# Debug narrative is provided as a tcl script whose value is [subst]ed in the 
# caller's scope if and only if the current level of interest matches or exceeds
# the Debug call's level of detail.  This is useful, as one can place arbitrarily
# complex narrative in code without unnecessarily evaluating it.
#
# TODO: potentially different streams for different areas of interest.
# (currently only stderr is used.  there is some complexity in efficient
# cross-threaded streams.)

package provide Debug 2.0

set ::API(Utilities/Debug) {
    {
	Debug narrative generator
    }
}

namespace eval ::Debug {
    variable detail
    variable level 0
    variable fds
    variable timestamp 1
    variable delta 0
    variable baseline [::tcl::clock::milliseconds]

    proc every {ms body} {eval $body; after $ms [info level 0]}

    variable duration 0
    variable heartbeat 0
    set hbtimer [::tcl::clock::milliseconds]

    proc pulse {} {
	variable hbtimer
	set now [::tcl::clock::milliseconds]

	variable duration
	set diff [expr {$now - $hbtimer - $duration}]

	set hbtimer $now

	variable heartbeat
	return [list [incr heartbeat] $diff]
    }

    proc heartbeat {{f 500}} {
	variable duration
	set duration $f
	if {$duration > 0} {
	    Debug on heartbeat
	    Debug every $duration {Debug.heartbeat {[Debug pulse]}}
	} else {
	}
    }

    proc noop {args} {}

    proc debug {tag message {level 1}} {
	variable detail
	if {$detail($tag) >= $level} {
	    variable fds
	    set fd $fds($tag)

	    set code [catch {
		uplevel 1 [list ::subst -nobackslashes [list $message]]
	    } result eo]
	    if {$code} {
		set x [info level -1]
		puts -nonewline $fd @@[string map {\n \\n \r \\r} "(DebugError from $tag [if {[string length $x] < 1000} {set x} else {set x "[string range $x 0 200]...[string range $x end-200 end]"}] ($eo)):"]
	    } else {
		if {[string length $result] > 4096} {
		    set result "[string range $result 0 2048]...(truncated) ... [string range $result end-2048 end]"
		}
		variable timestamp
		variable delta
		variable baseline
		if {$timestamp} {
		    set now [::tcl::clock::milliseconds]
		    if {$delta} {
			set time "[expr {$now - $baseline}]-[expr {$now - $delta}]mS "
		    } else {
			set time "[expr {$now - $baseline}]mS "
		    }
		    set delta $now
		} else {
		    set time ""
		}
		#puts $fd "$time$tag @@[regsub {([^[:print:]])} $result ^^^^^^^]"
		puts $fd "$time$tag @@[string map {\n \\n \r ""} $result]"
	    }
	} else {
	    #puts stderr "$tag @@@ $detail($tag) >= $level"
	}
    }

    # names - return names of debug tags
    proc names {} {
	variable detail
	return [lsort [array names detail]]
    }

    proc 2array {} {
	variable detail
	set result {}
	foreach n [lsort [array names detail]] {
	    if {[interp alias {} Debug.$n] ne "::Debug::noop"} {
		lappend result $n $detail($n)
	    } else {
		lappend result $n -$detail($n)
	    }
	}
	return $result
    }

    # level - set level and fd for tag
    proc level {tag {level ""} {fd stderr}} {
	variable detail
	if {$level ne ""} {
	    set detail($tag) $level
	}

	if {![info exists detail($tag)]} {
	    set detail($tag) 1
	}

	variable fds
	set fds($tag) $fd

	return $detail($tag)
    }

    # turn on debugging for tag
    proc on {tag {level ""} {fd stderr}} {
	level $tag $level $fd
	interp alias {} Debug.$tag {} ::Debug::debug $tag
    }

    # turn off debugging for tag
    proc off {tag {level ""} {fd stderr}} {
	level $tag $level $fd
	interp alias {} Debug.$tag {} ::Debug::noop
    }

    proc define {tag {level ""} {fd stderr}} {
	variable detail
	if {![info exists detail($tag)]} {
	    return [off $tag $level $fd]
	}
    }

    proc setting {args} {
	if {[llength $args] == 1} {
	    set args [lindex $args 0]
	}
	set fd stderr
	if {[llength $args]%2} {
	    set fd [lindex $args end]
	    set args [lrange $args 0 end-1]
	}
	foreach {tag level} $args {
	    if {$level > 0} {
		level $tag $level $fd
		interp alias {} Debug.$tag {} ::Debug::debug $tag
	    } else {
		level $tag [expr {-$level}] $fd
		interp alias {} Debug.$tag {} ::Debug::noop
	    }
	}
    }

    namespace export -clear *
    namespace ensemble create -subcommands {}
}

Debug on error 100
Debug off admin
Debug off cache
Debug off convert
Debug off cookies
Debug off db
Debug off dblayout
Debug off dispatch
Debug off entity
Debug off file
Debug off home
Debug off host
Debug off http
Debug off mason
Debug off mime
Debug off session
Debug off smtp
Debug off socket
Debug off sql
Debug off timer
Debug off url
Debug off vfs
Debug off wiki
Debug off wikiload
Debug off wikisearch
Debug off activity
