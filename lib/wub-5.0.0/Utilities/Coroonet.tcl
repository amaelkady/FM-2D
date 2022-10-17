# Coronet - a simple tcloo mixin for coroutine networking
# CMcC and MS 13Jul09

package require Tcl 8.6	;# minimum version of tcl required
package require TclOO
namespace import oo::*

package provide Coroonet 2.0

class create Coroonet {
    # terminate coroutine
    method terminate {args} {
	return -level [info level] $args        ;# terminate consumer
    }

    method _yield {socket args} {
	set result [lassign [::yield] command]

	if {$command ni $args} {
	    catch {catch {fileevent $socket readable {}}}
	    return -code 1 {*}$result $command
	}

	return $result
    }

    # cancel the ms timer
    method cancel {} {
	upvar #1 after after
	# unset old timeout if any
	if {[info exists after]} {
	    after cancel $after
	    unset after
	}
    }

    method timeout {args} {
	puts stderr "timeout: $args"
	[info coroutine] [list TIMEOUT {*}$args]
    }
    
    # start a ms timer
    method timer {ms} {
	my cancel
	
	# set timeout if any
	if {$ms >= 0} {
	    upvar #1 after after
	    set after [::after $ms [self] timeout -options timeout $ms]
	} else {
	    # no timeout
	    set msecs 0
	}
    }

    # coroutine-enabled gets
    method get {socket {maxline 0}} {
	fileevent $socket readable [list [info coroutine] INCOMING]

	my _yield $socket INCOMING
	set line ""
	while {[chan gets $socket line] == -1 && ![chan eof $socket]} {
	    my _yield $socket INCOMING

	    if {$maxline && [chan pending input $socket] > $maxline
	    } {
		catch {close $socket}
		error MAXLINE
	    }
	}

	if {[chan eof $socket]} {
	    catch {close $socket}
	    error EOF
	} else {
	    fileevent $socket readable {}
	}

	# return the line
	return $line
    }

    # coroutine-enabled read
    method read {socket size {reason ""}} {
	fileevent $socket readable [list [info coroutine] INCOMING]

	# read a chunk of $size bytes
	set chunk ""
	while {$size && ![chan eof $socket]} {
	    my _yield $socket INCOMING

	    set chunklet [chan read $socket $size]
	    incr size [expr {-[string length $chunklet]}]
	    append chunk $chunklet
	}

	if {[chan eof $socket]} {
	    catch {close $socket}
	    error EOF
	} else {
	    catch {fileevent $socket readable {}}
	}

	# return the chunk
	return $chunk
    }
}
