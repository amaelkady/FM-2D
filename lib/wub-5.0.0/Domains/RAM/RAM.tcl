# RAM.tcl - return contents of array as a domain

package require Http
package require TclOO
namespace import oo::*

package require Debug
Debug define RAM 10

package provide RAM 2.0

set ::API(Domains/RAM) {
    {
	in-RAM page store presenting a tcl array to a client with elements named by URL.

	RAM is useful for generated content for which you don't want to have to construct a containing file.  It is quite stupid about hierarchy, ignoring all but the prefix URL structure, so you can construct arbitrary URL hierarchies within a RAM instance, and they will be fetched without further inspection.

	Conditional fetching is supported - the last update to an element is timestamped, and a client's conditional fetch request will be honoured.  You could use RAM as a kind of Cache.

	== QuickStart ==
	[[[http:Nub Nub] domain /ram/ RAM]]

	[[RAM set fred "This is the content for fred" content-type text/plain]]

	Now you have a store with a single element ''fred'' with the above content accessable from the URL /ram/fred

	== Operation ==
	From Tcl you call [[$ram set $key content args]] to store $content under the URL $mount/$key.

	$args is a dict containing metadata such as 'content-type' and any other HTTP response dict metadata.  The fields 'last-modified' and 'content-length' are controlled by RAM, and setting them will have no effect.

	You could go crazy with this, and set arbitrary HTTP response elements ... feel free to do so with caution.

	$args may also contain a ''-headers'' element, whose content will be appended to the response's -headers element.
    }
    content_type {default content-type (default: x-text/html-fragment)}
}

class create ::RAM {
    variable ram mount content_type

    # get - gets keyed content only
    method get {key} {
	Debug.RAM {[self] get $key '$ram($key)'}
	return [lindex $ram($key) 0]
    }

    # exists - does keyed content exist?
    method exists {key} {
	Debug.RAM {exists $key '[info exists ram($key)]'}
	return [info exists ram($key)]
    }

    # _set - assumes first arg is content, rest are to be merged
    method set {key args} {
	if {$args ne {}} {
	    # calculate an accurate content length
	    set now [clock seconds]
	    lappend args -modified $now
	    lappend args last-modified [Http Date $now]
	    lappend args content-length [string length [lindex $args 0]]
	    Debug.RAM {$key set '$args'}
	    set ram($key) $args
	}

	# fetch ram for prefix
	return $ram($key)
    }

    # unset - remove content
    method unset {key} {
	# unset ram element
	Debug.RAM {unset $key '$ram($key)'}
	unset ram($key)
    }

    method keys {} {
	set result {}
	return [array names ram]
    }

    # called as "do $request" returns the value stored in this RAM to be returned.
    method do {r} {
	# calculate the suffix of the URL relative to $mount
	lassign [Url urlsuffix $r $mount] result r suffix path
	if {!$result} {
	    return $r	;# the URL isn't in our domain
	}

	variable ram
	Debug.RAM {exists ram $suffix [info exists ram($suffix)]}
	if {![info exists ram($suffix)]} {
	    # path isn't inside our domain suffix - error
	    return [Http NotFound $r]
	}

	variable content_type
	set content [lindex $ram($suffix) 0]
	set els {}
	set extra [lrange $ram($suffix) 1 end]

	# check conditional
	if {[dict exists $r if-modified-since]
	    && (![dict exists $extra -dynamic] || ![dict get $extra -dynamic])
	} {
	    set since [Http DateInSeconds [dict get $r if-modified-since]]
	    if {[dict get $extra -modified] <= $since} {
		Debug.RAM {NotModified: $path - [dict get $extra last-modified] < [dict get $extra if-modified-since]}
		Debug.RAM {if-modified-since: not modified}
		return [Http NotModified $r]
	    }
	}
	
	foreach {el val} $extra {
	    if {$el eq "-header"} {
		dict lappend r -headers $val
	    } else {
		dict set els $el $val
	    }
	}
	set r [dict merge $r [list content-type $content_type {*}$els -content $content]]

	return [Http Ok $r]
    }

    # initialize view ensemble for RAM
    constructor {args} {
	set content_type x-text/html-fragment
	set mount /ram/
	array set ram {}
	variable {*}[Site var? RAM]	;# allow .ini file to modify defaults

	foreach {n v} $args {
	    set [string trimleft $n -] $v
	}
	set mount /[string trim $mount /]/
    }
}
