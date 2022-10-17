# Threaded.tcl - install and proxy a Domain in a thread, or pool of threads

# we can't proceed without Tcl Threads
package require Debug
Debug define threaded 10
if {[catch {
    package require Thread
} e eo] {
    Debug.error {Thread package unavailable - no Threaded domains possible. ($e ($eo))}
    return
}

package require OO
package require Query
package require Url

package provide Threaded 1.0

set ::API(Domains/Threaded) {
    {
	A domain which dispatches URL requests threads containing nominated domains.

	Threaded acts as a transparent proxy to threaded instances of the domain given in -domain and constructed with all args following the domain entry.

	Threaded domains may themselves handle concurrent requests using Httpd Suspend and Resume.  The maximum permitted degree of concurrency within a thread is determined by 'occupancy' arg.

	Example: Nub domain Threaded -domain Direct ...
    }
    -domain {names the domain to be constructed per thread, and commences the dict of its constructor args}
    maxthreads {maximum number of threads to create (default 10)}
    newfirst {we prefer new threads to greater occupancy (default true)}
    occupancy {maximum occupancy of each thread (default 1)}
    unavailable {return 'Unavailable' for this many ms or 0 to make 'em wait (default 1000)}
    unmsg {unavailability message}
    waitfor {how long to wait for a free thread -1 means 'forever' (default 10000)}
    grace {how long to wait for response from thread -1 means forever (default 100000)}
}

class create ::Threaded {
    # caught a background error in a thread
    method caught {args} {
    }

    # construct a new thread
    method newthread {} {
	set thread [::thread::create -preserved [string map [list %S% [self] %T% [::thread::id]] {
	    proc ::ERROR {args} {
		::thread::send -async %T% [list %S% caught [::thread::id] $args]
	    }
	    ::thread::errorproc ::ERROR	;# this catches our uncaught errors

	    # process parent call, returning tid + result dict
	    proc ::CALL {args} {
		set code [catch {
		    uplevel #0 $args
		} e eo]
		return [list [::thread::id] $code $e $eo]	;# package up entire result dict
	    }

	    # we need a shim for Httpd to provide Suspend/Resume
	    package provide Httpd 1.0
	    namespace eval ::Httpd {
		# format something to suspend this proxied packet
		# this is a NOOP here, but handled by the Threaded domain
		proc Suspend {r {grace -1}} {
		    Debug.Httpd {Thread Suspending [rdump $r]}
		    dict set r -suspend $grace	;# Threaded controls the suspension
		    return $r
		}

		# resume this request via the Threaded domain
		proc Resume {r {cache 1}} {
		    Debug.Httpd {Thread Resuming [rdump $r]}
		    # ask socket coro to send the response for us
		    # we inject the SEND event into the coro so Resume may be called from any
		    # event, thread or coroutine
		    ::thread::send -async %T% [list %S% resume [::thread::id] $r]
		    return {}
		}
	    }
	}]]

	Debug.threaded {[self] new thread $thread}

	# construct the necessary Domain handler in $thread, recording its invocation
	variable domain; variable dargs
	set cmd [thread::send $thread [list $domain {*}$dargs]]

	# record the thread in our generic pool
	variable pool
	dict set pool $thread $cmd

	return $thread
    }

    method findthread {thread id} {
	# find out the current state of the thread - 'full' or 'running'
	variable full; variable running
	if {[dict exists $running $thread]} {
	    set found running
	} elseif {[dict exists $full $thread]} {
	    set found full
	} else {
	    # thread isn't running at all!
	    Debug.error {Thread $thread isn't full or running}
	    error "Thread $thread isn't full or running"
	}

	# get the queue containing request
	return $found
    }

    # thread found in $found queue has completed
    # release resources, reallocate if possible
    method completed {found thread id} {
	variable full; variable running; variable idle

	set orgr [dict get [set $found] $thread $id]

	# $thread has completely handled request
	# adjust $thread into the correct queue - running or idle
	dict unset $found $thread $id	;# remove record of thread
	if {$found eq "full"}  {
	    # it was full, now it's not, it's just running
	    dict set running $thread [dict get full $thread]
	    dict unset full $thread
	    set found "running"
	}
	if {$found eq "running"}  {
	    if {[dict size running $thread] == 0} {
		# it was running, now it's idle
		dict set idle $thread
	    }
	    dict unset $found $thread
	}

	::thread::release $thread

	# now we can resume one element of the waiting requests
	# (also trims dead requests)
	variable waiting
	set waiting [lassign $waiting next]
	while {$next ne "" && ![Httpd active [dict get $next -send]]} {
	    set waiting [lassign $waiting next]
	}

	if {$next ne ""} {
	    my do $next	;# try to restart the waiting thread
	}
    }

    # resume a request which the thread had suspended
    method resume {thread r} {
	# shuffle the old thread id around, get its original request
	set id [dict get $r -threaded]
	set found [my findthread $thread $id]
	set orgr [dict get [set $found] $thread $id]

	# we just resume *our* suspend with their response
	dict set r -send [dict get $orgr -send]
	Httpd Resume $r	;# resume with whatever thread sent us

	# now release resources
	my completed $found $thread $id
    }

    # result - results are returned in the tr array
    method result {. thread .} {
	variable tr
	lassign $tr($thread) tid code r eo
	if {$tid ne $thread} {
	    # this is a problem
	    Debug.error {Threaded [self] - result for $thread references a different thread ($tr($thread))}
	    error "Threaded [self] - result for $thread references a different thread ($tr($thread))"
	}
	unset tr($thread)	;# we have the result, discard the carrier

	# shuffle the old thread id around, get its original request
	set id [dict get $r -threaded]
	set found [my findthread $thread $id]
	set orgr [dict get [set $found] $thread $id]

	# arrange for the original (currently suspended) request to be satisfied
	switch -- $code {
	    0 { # ok
		if {[dict exists $r -suspend]} {
		    # $thread has suspended its response - leave it alone
		    # it will signal completion with a [resume] to us.
		} else {
		    dict set r -send [dict get $orgr -send]
		    Httpd Resume $r	;# resume with whatever thread sent us

		    # release resources
		    my completed $found $thread $id
		}
	    }

	    1 - 2 - 3 - 4 -
	    default {
		# anything else is an error
		Httpd Resume [Http ServerError $orgr $ $e $eo]

		# release resources
		my completed $found $thread $id
	    }
	}
    }

    # called as "do $request" causes procs defined within 
    # the specified namespace to be invoked, with the request as an argument,
    # expecting a response result.
    method do {r} {
	# calculate the suffix of the URL relative to $mount
	lassign [Url urlsuffix $r $mount] result r suffix path
	if {!$result} {
	    return $r	;# the URL isn't in our domain
	}

	variable last
	while {[set now [clock microseconds]] == $last} {}	;# now in uS, useful for stuff.
	set last $now	;# against the possibility that we have more than one/uS

	# determine which thread from which queue
	variable idle		;# collection of idle threads
	variable maxthreads	;# maximum number of threads to create
	variable newfirst	;# we prefer new threads to greater occupancy
	variable occupancy	;# maximum occupancy of each thread
	variable unavailable	;# return 'Unavailable' or make 'em wait?

	if {[dict size $idle]} {
	    # there's an idle thread to use
	    set thread [lindex [dict keys $idle] 0]	;# grab next idle thread
	    dict unset idle $thread	;# remove from idle thread collection
	} elseif ($newfirst && [dict size $pool] < $maxthreads) {
	    # initialize a new thread - we prefer maximum number of threads
	    set thread [my newthread]
	} elseif {[dict size $running]} {
	    # we permit thread sharing - find a relatively unoccupied thread
	    set runners [dict keys $running]	;# grab next idle thread
	    set select [expr {$now % [dict size $running]}] ;# select a thread
	    set thread [lindex $runners $select]
	} elseif (!$newfirst && [dict size $pool] < $maxthreads) {
	    # initialize a thread - we prefer maximum thread occupancy
	    set thread [my newthread]
	} elseif {$unavailable > 0} {
	    # everthing is fully committed - have to tell the client we're busy
	    variable unmsg
	    return [Http Unavailable $r $unmsg $unavailable]
	} else {
	    # everything is fully committed - suspend request until something's available
	    variable waitfor	;# how long to wait for a free thread
	    variable waiting {}	;# list of pending requests awaiting unoccupied threads
	    lappend waiting $r	;# record this waiting request
	    return [Http Suspend $r $waitfor]
	}

	# we are ready to proxy this request $r to $thread
	dict set running $thread $now $r	;# record new $thread occupant

	# keep fully committed threads out of future selection
	if {[dict size [dict get $running $thread]] >= $occupancy} {
	    # this thread is now fully committed
	    variable full
	    dict set full $thread [dict get $running $thread]
	    dict unset running $thread	;# remove from possible selections
	}

	# now proxy the request to the $thread
	variable response
	thread::preserve $thread

	# voodoo to permit threaded domain to [Httpd Resume]
	dict set r [list ::thread::send -async [::thread::id] [list [self] resume]]
	dict set r -threaded $now	;# voodoo to process return

	# pass the requst to the threaded domain
	variable tr
	thread::send -async $thread [list ::CALL [dict get $pool $thread] do $r] tr($thread)

	# meanwhile - suspend the request
	variable grace
	return [Http Suspend $r $grace]
    }

    destructor {
	variable pool
	dict for {t occ} $pool {
	    # destroy thread $t
	    while {[::thread::release $thread] > 0}
	}
    }

    constructor {args} {
	variable maxthreads 10	;# maximum number of threads to create
	variable newfirst 1	;# we prefer new threads to greater occupancy
	variable occupancy 1	;# maximum occupancy of each thread
	variable unavailable 1000 ;# return 'Unavailable' for this many ms or 0 to make 'em wait
	variable unmsg "Try again in a short while"	;# unavailability message
	variable waitfor 10000	;# how long to wait for a free thread -1 means 'forever'
	variable grace 100000	;# how long to wait for response from thread -1 means forever

	variable {*}[Site var? Threaded]	;# allow .ini file to modify defaults

	# search for -domain element
	set where [lsearch -exact -- $args -domain]
	if {$where < 0} {
	    error "Threaded construction must have a -domain element, followed by domain name and its args"
	}

	# split out everything after '-domain' arg into dargs
	variable dargs [lrange $args $where+2 end]	;# record args for domain
	set args [lrange $args 0 $where+1]

	# duplicate mount arg between args and dargs
	if {![dict exists $args mount]} {
	    dict set args mount [dict get $dargs mount]
	} else {
	    dict set dargs mount [dict get $args mount]
	}

	# rename -domain to domain for variables
	dict set args domain [dict get $args -domain]
	dict unset args -domain

	variable {*}$args	;# instantiate all the Threaded parameters

	# internal vars - thread queues and such
	variable pool {}	;# collection of all managed threads
	variable idle {}	;# collection of idle threads
	variable running {}	;# collection of running threads
	variable full {}	;# collection of fully occupied threads
	variable waiting {}	;# list of pending requests awaiting unoccupied threads
	variable last 0		;# uS of last thread allocation

	# set up result trace - this collects our threads responses
	variable tr; array set tr
	trace add variable tr write [list [self] result]
    }
}
