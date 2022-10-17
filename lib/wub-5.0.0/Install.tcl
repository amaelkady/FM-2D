# Install.tcl -- download or update Wub from its svn repository

# NB: uses old-style coro form so it can cope with older 8.6 beta versions

if {[catch {package require Tcl 8.6}]} {
    puts stderr "Tcl 8.6 required, you have [package provide Tcl]"
}
if {[catch {package require fileutil}]} {
    puts stderr "tcllib required, doesn't appear to be present"
}

package require http
package provide Install 1.1

namespace eval Install {
    variable base http://wub.googlecode.com/svn/
    variable version trunk
    variable home [file dirname [info script]]

    proc gotfile {file token} {
	if {[::http::status $token] ne "ok"} {
	    puts stderr "Failed to fetch file $file"
	} elseif {[catch {
	    # copy file contents to $home 
	    variable home
	    set file [string map {%20 " "} $file]
	    ::fileutil::writeFile -encoding binary [file join $home $file] [::http::data $token]
	    ::http::cleanup $token
	} e eo]} {
	    puts stderr "gotfile error: $e ($eo)"
	}
	getter [list FILE $file]	;# signal file completion
    }

    proc gotdir {dir token} {
	variable home
	set dirn [string map {%20 " "} $dir]
	if {[::http::status $token] ne "ok"} {
	    puts stderr "Failed to fetch dir $dir"
	} elseif {![file exists [file join $home $dirn]] && [catch {
	    # create destination directory if needed
	    file mkdir [file join $home $dirn]
	} e eo]} {
	    error $e
	} elseif {[catch {
	    # decode body as a <li> of <A> tags pointing to directory contents
	    set body [::http::data $token]
	    set urls [regexp -inline -all -- {href="([^\"]+)"} $body]
	    set urls [dict values $urls]
	    variable dl
	    foreach name $urls {
		set name [string map [list $dl/ ""] $name]
		
		switch -glob -- $name {
		    http://* -
		    .* {
			#puts "discarding $name"
			continue
		    }
		    */ {
			# initiate directory fetch of $name
			getter [list dir [file join $dir $name]/]
		    }
		    default {
			# initiate file fetch of $name
			getter [list file [file join $dir $name]]
		    }
		}
	    }
	    ::http::cleanup $token	;# finished dir page
	} e eo]} {
	    puts "gotdir error $e ($eo)"
	}
	getter [list DIR $dir]	;# signal dir completion
    }

    # getter coroutine implementation
    proc getC {args} {
	variable queue		;# queued fetches
	variable dl		;# base URL
	variable limit		;# limit simultaneous fetches
	variable loading 0	;# number of pending fetches
	variable pending {}	;# dict of pending fetches
	variable loaded 0	;# count of pages loaded

	while {1} {
	    if {[catch {
		lassign $args op path	;# decode args

		# first process any completed fetches
		switch -- $op {
		    FILE -
		    DIR {
			incr loaded
			incr loading -1
			dict unset pending [string map {" " %20} $path]
			puts stderr "DONE $loaded: $op $path ($loading/$limit) queue: [llength $queue] pending: [dict keys $pending]"
			set queue [lassign $queue op path]
		    }
		}
		
		switch -- $op {
		    "" {
			# nothing more queued yet, wait for completion
		    }
		    file -
		    dir {
			# requested a fetch
			if {$loading < $limit} {
			    # can fetch now
			    incr loading 1
			    variable dl
			    set cmd [list ::http::geturl $dl/$path -command [namespace code [list got$op $path]]]
			    puts stderr "GETTING: $op $path $loading/$limit ($cmd)"
			    puts stderr "$cmd"
			    dict set pending $path $op
			    {*}$cmd
			} else {
			    # fetching would exceed limit on simultaneous fetches
			    lappend queue $op $path
			    puts stderr "QUEUEING: $op $path $loading/$limit queued: [llength $queue] pending: [dict keys $pending]"
			}
		    }
		    default {
			error "getter doesn't do $op $path"
		    }
		}
	    } e eo]} {
		puts stderr "CORO error: $e ($eo)"
	    }
	    set args [yield]
	}	 
    }

    # waiter - vwaits until all pages are fetched
    proc waiter {} {
	variable queue
	variable loading
	while {1} {
	    vwait loading
	    puts "countdown: $loading/$limit queued: [llength $queue]"
	    if {$loading == 0} {
		variable loaded
		return $loaded
	    }
	}
    }

    # start recursive getter coro to fetch all files from a repo
    proc fetch {args} {
	variable limit 10
	variable version trunk
	variable overwrite 0
	variable {*}$args	;# set variables passed in

	# clean up directories and URLs
	variable home [file normalize $home]
	variable base [string trimright $base /]
	variable version [string trimright $version /]

	if {!$overwrite
	    && [file exists [file join $home .svn]]
	} {
		error "Refusing to overwrite subversion-controlled directory.  Use 'overwrite 1' if you insist upon this."
	}

	# work on release
	switch -glob -- $version {
	    trunk - head {
		set version trunk
	    }
	    [2-9]* {
		set version branches/RB-$version
	    }
	}
	variable dl [string trimright $base/$version /]

	puts "Install '$dl' to '$home'"
	coroutine ::Install::getter getC dir

	if {[info exists wait] && $wait} {
	    waiter	;# caller asked us to vwait
	}
    }

    namespace export -clear *
    namespace ensemble create -subcommands {}
}

Install fetch home [pwd] {*}$argv
Install waiter
