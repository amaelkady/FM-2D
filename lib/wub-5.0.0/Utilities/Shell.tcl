# Shell -- a coroutine enabled tcl evaluator
#
# From Neil Madden's corotcl http://wiki.tcl.tk/24060
#
# Usage:
#
# [Shell new] - create a shell listening on stdio
# [Shell new in $chan out $chan] - shell connected to chan
# [Shell new port $port] - shell server on localhost port $port
#
# Options:
#
# login - a command prefix given lines of input until it returns true
# password - a list of passwords for default login facility
# host - a non-localhost interface upon which to listen at $port

package require TclOO
namespace import oo::*

package provide Shell 1.0

set ::API(Utilities/Shell) {
    {
	Shell - Provides a tcl login shell to the running server
    }
}

class create Shell {
    constructor {args} {
	# prompt for input, collect it and return
	proc prompt {in out p} {
	    puts -nonewline $out "$p "
	    chan flush $out
	    chan event $in readable [list ::apply {{return in} {
		$return [gets $in]
	    }} [info coroutine] $in]
	    return [yield]
	}

	# read-eval-print loop - prompt, gets input, evaluate it, print result
	proc repl {self in out interp {login ""}} {
	    while {1} {
		if {[info exists login]} {
		    if {$login eq ""} {
			unset login	;# don't leave it hanging around
		    } else {
			set cmd [prompt $in $out login:]
			try {
			    {*}$login $cmd
			} on error {result eo} {
			    puts stderr "Shell login error: $result ($eo)"
			    break
			} on return {} {
			    puts stderr "Shell login aborted"
			    break
			} on continue {} {
			    continue
			} on ok {result} {
			    if {$result} {
				unset login	;# login returned ok
			    } else {
				continue
			    }
			}
		    }
		}

		set cmd [prompt $in $out %]
		while {![info complete $cmd]} {
		    append cmd \n [prompt $in $out >]
		}

		try {
		    {*}$interp $cmd
		} on error {result eo} {
		    puts $out [dict get $eo -errorinfo]
		} on return {result} {
		    break
		} on ok {result} {
		    puts $out $result
		}
	    }

	    # close the i/o unless it's stdio
	    if {$in ne "stdin"} {
		chan close $in read
	    } else {
		chan event $in readable {}	;# stop listening to stdin
	    }
	    if {![string match std* $out]} {
		chan close $out write
	    }

	    return $result
	}

	set interp {uplevel #0}	;# default cmd interpreter
	set login ""		;# default - no login
	set in stdin; set out "";# default - use stdio
	set host localhost	;# default - listen only to localhost

	dict with args {
	    if {[info exists password] && $password ne "" && $login eq ""} {
		# throw in some default password handling
		set login [list ::apply [list {password} [string map [list %PASSWORDS% $password] {
		    return [expr {$password in {%PASSWORDS%}}]
		}]]]
	    }

	    if {[info exists port]} {
		# what is wanted is a listener
		socket -server [list ::apply {{login sock addr port} {
		    set shell [Shell new in $sock login $login]
		}} $login]  -myaddr $host $port
	    } else {
		# we have a chan (or a couple of chans)
		if {$out eq ""} {
		    if {$in eq "stdin"} {
			set out stdout
		    } else {
			set out $in
		    }
		}
		chan configure $out -buffering line
		coroutine [self]_CORO repl [self] $in $out $interp $login
	    }
	}
    }
}

if {[info exists argv0] && ($argv0 eq [info script])} {
    puts "Shell on stdio"
    Shell new
    puts "Shell on localhost port 8082"
    Shell new port 8082 interp {uplevel #1}
    vwait forever
}
