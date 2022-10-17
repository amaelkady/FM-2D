# Alt.tcl - alternation wrapper around domains
package provide Alt 1.0

set ::API(Domains/Alt) {
    {
	A wrapper domain which iterates over other domains until a successful response is generated.
    }
}

oo::class create ::Alt {
    # called as "do $request" checks Basic Auth on request
    method do {r} {
	# calculate the suffix of the URL relative to $mount
	variable mount
	lassign [Url urlsuffix $r $mount] result r suffix path
	if {!$result} {
	    return $r	;# the URL isn't in our domain
	}

	# iterate over alternate domains in order until one responds
	set orgR $r
	variable alternates
	foreach $sub $alternates {
	    if {![catch {$sub $r} response]} {
		set code [dict get? $r -code]
		switch -glob -- $code {
		    2* -
		    3* {
			# we have an ok response
			return $response
		    }
		    default {
			# response was bad, try again
			set r $orgR
		    }
		}
	    }
	}

	# nothing responded - tell the client we couldn't find it.
	return [Http NotFound $orgR ]
    }

    # Alt is constructed with a series of domains or domain names to call
    # until one returns successfully
    constructor {args} {
	variable mount
	variable alternates
	variable {*}[Site var? Alt]	;# allow .ini file to modify defaults
	foreach sub $args {
	    if {[llength $sub] == 1} {
		# must be an existing command
		lappend alternates $sub
	    } else {
		set a [lassign $sub class]
		if {[llength $cmd] == 1} {
		    # anonymous class instance
		    lappend alternates [$class new {*}$a mount $mount]
		} elseif {[llength $cmd] == 2} {
		    lassign $cmd class name
		    lappend alternates [$class create $name {*}$a mount $mount]
		}
	    }
	}
    }
}
