# Direct.tcl - direct domain handler, like tclhttpd's
#
# Provides wildcard dispatch, /photo/1234 handled by photo::/default
#
# Examples:
#  1) Create a Direct domain handler (fred) which will interpret URLs 
#  with a prefix /fred/ as proc calls within a namespace ::Fred
#
#   Direct fred namespace ::Fred prefix /fred/
#
#  2) Using [fred] domain handler to interpret a request $r:
#
#  fred do $r

package require OO
package require Query
package require Url
package require Debug
Debug define direct 10

package provide Direct 1.0

set ::API(Domains/Direct) {
    {
	A domain which dispatches URL requests to commands within a namespace or methods within an object.  Note that only commands whose name starts with '/' will be exported to the web.

	== QuickStart ==
	Create a namespace NS containing commands of the form [[proc /name {r arg1 arg2 ...} {}]]

	[[[http:Nub Nub] domain /prefix/ Direct namespace NS]]

	Now any URL reference to /prefix/FRED will invoke the command ::NS::/FRED with any URL query args passed as actual parameters.

	== Operation ==
	A target URL is interpreted as a command/method invocation with its query arguments interpreted as actual parameters.

	Argument defaults are honoured, as is the ''$args'' formal parameter - unspecified query arguments are passed into the target command as a dict.  Multiple query args with the same name are passed as a list of values.

	Prefix invocation is supported, where a url like '''/fred/wilma''' will be matched by command /fred if /fred/wilma is not found.  The unmatched url suffix can be found in [[dict $r get -extra]]

	Wildcard invocation is supported, with unmatched urls being handled by a nominated default command.

	== TODO ==
	Different varieties of command might be supported.  Specifically, interps should be considered as a valid command container.

	== Homage ==
	This concept is an extension of TclHttpd's domain of the same name.
    }
    namespace {namespace in which to invoke commands}
    ctype {default content-type of returned values}
    wildcard {process to be used if a request doesn't match any proc in $namespace (default /)}
    correct {insist that the top level domain is referenced with a trailing / (default: yes)}
}

class create ::Direct {
    variable namespace object class ctype mount wildcard methods

    method do_ns {rsp} {
	Debug.direct {direct ns:$namespace mount:$mount ctype:$ctype suffix:'[dict get $rsp -suffix]'}
	
	# search for a matching command prefix
	set cmd ""
	set fn [dict get $rsp -suffix]; if {$fn eq ""} {set fn /}
	set cprefix [split [armour $fn] /]
	set extra {}
	while {$cmd eq "" && [llength $cprefix]} { 
	    set probe [info commands ${namespace}::/[string trim [join $cprefix /] /]]
	    Debug.direct {direct probe: ($probe) - ${namespace}::/[string trim [join $cprefix /] /]}
	    if {[llength $probe] == 1} {
		set cmd [lindex $probe 0]
		break
	    }

	    # there's no exact match, so trim cprefix and try again.
	    Debug.direct {searching for ($cprefix) in '$namespace' among '$probe'}
	    lappend extra [lindex $cprefix end]		;# remember trailing part of url
	    set cprefix [lrange $cprefix 0 end-1]	;# trim url and try again
	}

	# no match - use wildcard proc
	if {$cmd eq ""} {
	    Debug.direct {no match looking for '$fn' in '$namespace' ([info procs ${namespace}::/*])}
	    set cmd ${namespace}::$wildcard
	    dict set rsp -extra [dict get $rsp -suffix]
	    if {[info commands $cmd] eq {}} {
		Debug.direct {default not found looking for $cmd in ([info procs ${namespace}::/*])}
		return [Http NotFound $rsp]
	    }
	} else {
	    dict set rsp -extra [join [lreverse $extra] /]	;# record the extra parts of the domain
	}

	set params [lrange [info args $cmd] 1 end]
	array set used {}
	set needargs 0
	set argl {}
	set qd [dict get $rsp -Query]

	Debug.direct {cmd: '$cmd' params:$params qd:[dict keys $qd]}
	foreach arg $params {
	    if {[Query exists $qd $arg]} {
		Debug.direct {param $arg exists} 2
		incr used($arg)
		if {[Query numvalues $qd $arg] > 1} {
		    Debug.direct {multiple $arg: [Query values $qd $arg]} 2
		    lappend argl [Query values $qd $arg]
		} else {
		    Debug.direct {single $arg: [string range [Query value $qd $arg] 0 80]...} 2
		    lappend argl [Query value $qd $arg]
		}
	    } elseif {$arg eq "args"} {
		set needargs 1
	    } else {
		Debug.direct {param '$arg' does not exist} 2
		if {[info default $cmd $arg value]} {
		    Debug.direct {default $arg: $value} 2
		    lappend argl $value
		} else {
		    lappend argl {}
		}
	    }
	}

	set argll {}
	if {$needargs} {
	    foreach {name value} [Query flatten $qd] {
		if {![info exists used($name)]} {
		    Debug.direct {args $name: [string range $value 0 80]...} 2
		    lappend argll $name $value
		}
	    }
	}

	Debug.direct {calling $cmd [string range $argl 0 80]... [dict keys $argll]} 2
	if {[catch {
	    dict merge $rsp [$cmd $rsp {*}$argl {*}$argll]
	} result eo]} {
	    Debug.direct {error: $result ($eo)}
	    return [Http ServerError $rsp $result $eo]
	} else {
	    Debug.direct {Content: [dict get $result -code] '[string range [dict get $result -content] 0 80]...'} 2
	    return $result
	}
    }

    # locate a matching direct method in an object
    method do_obj {rsp} {
	Debug.direct {do direct $object $mount $ctype}
	
	# search for a matching command prefix
	set fn [dict get $rsp -suffix]
	set cprefix [split [armour $fn] /]
	set extra {}
	set cmd ""
	while {$cmd eq "" && [llength $cprefix]} { 
	    Debug.direct {searching for ($cprefix) in '$object' ($methods)}
	    set probe [dict keys $methods /[join $cprefix /]]
	    # this strict match can only have 1 or 0 results
	    if {[llength $probe] == 1} {
		set cmd $probe
		break
	    }

	    # there's no exact match, so trim cprefix and try again.
	    lappend extra [lindex $cprefix end]	;# remember the non-matching bits
	    set cprefix [lrange $cprefix 0 end-1]
	}

	# no match - use wildcard method
	if {$cmd eq ""} {
	    Debug.direct {'$cmd' not found looking for '$fn' in '$object' ($methods)}
	    set cmd $wildcard
	    dict set rsp -extra [dict get $rsp -suffix]
	    if {![dict exists $methods $cmd] eq {}} {
		Debug.direct {default not found looking for $cmd in ($methods)}
		return [Http NotFound $rsp]
	    }
	} else {
	    dict set rsp -extra [join [lreverse $extra]	/] ;# record the extra parts of the domain
	}

	# get the formal parameters and args-status of the method
	lassign [dict get $methods $cmd] needargs params

	set qd [dict get $rsp -Query]
	Debug.direct {cmd: '$cmd' needargs:$needargs params:$params qd:[dict keys $qd]}

	set argl {}
	array set used {}
	foreach arg $params {
	    lassign $arg arg default
	    if {[Query exists $qd $arg]} {
		Debug.direct {param $arg exists} 2
		incr used($arg)
		if {[Query numvalues $qd $arg] > 1} {
		    Debug.direct {multiple $arg: [Query values $qd $arg]} 2
		    lappend argl [Query values $qd $arg]
		} else {
		    Debug.direct {single $arg: [string range [Query value $qd $arg] 0 80]...} 2
		    lappend argl [Query value $qd $arg]
		}
	    } else {
		Debug.direct {param '$arg' does not exist} 2
		lappend argl $default
	    }
	}

	set argll {}
	if {$needargs} {
	    foreach {name value} [Query flatten $qd] {
		if {![info exists used($name)]} {
		    Debug.direct {args $name: [string range $value 0 80]...} 2
		    lappend argll $name $value
		}
	    }
	}

	Debug.direct {calling method $cmd [string range $argl 0 80]... [dict keys $argll]} 2
	if {[catch {
	    dict merge $rsp [$object $cmd $rsp {*}$argl {*}$argll]
	} result eo]} {
	    Debug.direct {error: $result ($eo)}
	    return [Http ServerError $rsp $result $eo]
	} else {
	    Debug.direct {Content: [dict get $result -code] '[string range [dict get? $result -content] 0 80]...'} 2
	    return $result
	}
    }

    # called as "do $request" causes procs defined within 
    # the specified namespace to be invoked, with the request as an argument,
    # expecting a response result.
    method do {r} {
	# get query dict
	set qd [Query parse $r]
	dict set r -Query $qd
	Debug.direct {Query: [Query dump $qd]}

	# calculate the suffix of the URL relative to $mount
	lassign [Url urlsuffix $r $mount] result r suffix path
	if {!$result} {
	    return $r	;# the URL isn't in our domain
	}

	# insist upon correct form for top-level reference
	variable correct
	if {$correct && $suffix eq "/" && [string index $path end] ne "/"} {
	    return [Http Redirect $r $path/ "<p>Please ensure paths are /-terminated</p>"]
	}

	# remove suffix's extension and trim /s
	Debug.direct {suffix: '$suffix' path: '$path' result: '$result'}
	dict set r -suffix [string trim $suffix /]

	# TODO: armour commands
	if {[dict exists $r content-type]} {
	    dict set r -content-type [dict get $r content-type]
	}
	dict set r content-type $ctype
	#dict set r cache-control no-cache	;# default - not cacheable
	dict set r -dynamic 1
	catch {dict unset r -content}

	if {[info exists object]} {
	    return [my do_obj $r]
	} else {
	    return [my do_ns $r]
	}
    }

    # init cmd {namespace ns} {ctype default-mime-type} {mount mount-of-domain}
    # creates cmd command proxy/interface to procs within $ns called /name,
    # which will be invoked with Query args from the request assigned to actual
    # parameters of matching proc, procs are matched from the -path or -suffix
    # components of the passed request
    constructor {args} {
	set ctype "x-text/html-fragment"
	set mount "/"
	set wildcard /
	variable correct 1	;# insist on trailing /

	foreach {n v} $args {
	    set [string trimleft $n -] $v
	    Debug.direct {variable: $n $v}
	}
	variable {*}[Site var? Direct]	;# allow .ini file to modify defaults

	# one or the other of namespace or object must exist
	if {![info exist namespace] && ![info exists object]} {
	    # no namespace or object - must be a mixin
	    next? {*}$args mount $mount
	    set object [self]
	    Debug.direct {mixin Direct [self] class: '[info object class [self]]', mixins: '[info class mixins [info object class $object]]' methods: '[info class methods [info object class $object] -private -all]'}
	}

	set wildcard /[string trim $wildcard /]

	if {[info exists object]} {
	    if {[info exists namespace]} {
		error "Direct domain: can only specify one of object or namespace"
	    }

	    if {[llength $object] == 1
		&& [info object class $object] ne "::oo::class"
	    } {
		# object name must be fully ns-qualified
		if {![string match "::*" $object]} {
		    set object ::$object
		}
	    } elseif {[llength $object]%2} {
		Debug.direct {[lindex $object 0] new {*}[lrange $object 1 end] mount $mount}
		set object [[lindex $object 0] new {*}[lrange $object 1 end] mount $mount]
	    } else {
		Debug.direct {[lindex $object 0] create {*}[lrange $object 1 end] mount $mount}
		set object [[lindex $object 0] create {*}[lrange $object 1 end] mount $mount]
	    }

	    # construct a dict from method name to the formal parameters of the method
	    set class [info object class $object]
	    set methods {}
	    set superclass [info class superclasses $class]
	    set mixins [info class mixins $class]
	    foreach m [lreverse [lsort -dictionary [info class methods $class -private -all]]] {
		if {[string match /* $m]} {
		    foreach class [list [info object class $object] {*}$superclass {*}$mixins] {
			if {![set unfound [catch {
			    lindex [info class definition $class $m] 0
			} def eo]]} {
			    # defined in $class, else try next mixin
			    break
			}
		    }
		    if {$unfound} {
			error "Can't find method $m in any class of [info object class [self]] $mixins"
		    }
		    Debug.direct {[lindex $object 0] method $m definition: $def}
		    if {[lindex $def end] eq "args"} {
			set needargs 1
			set params [lrange $def 1 end-1]	;# remove 'r' and args from params
		    } else {
			set needargs 0
			set params [lrange $def 1 end]	;# remove 'r' from params
		    }
		    
		    Debug.direct {[lindex $object 0] method $m record definition: [list $needargs $params]}
		    dict set methods $m [list $needargs $params]
		}
	    }

	    Debug.direct {[lindex $object 0] of class $class methods: ($methods) / ([info class methods $class -private -all])}
	    objdefine $object export {*}[info object methods $object -all] {*}[dict keys $methods]
	    if {![dict exists $methods $wildcard]} {
		error "Wildcard method $wildcard must exist in object. ([dict keys $methods])"
	    }
	} else {
	    # namespace must be fully qualified
	    if {![string match "::*" $namespace]} {
		set namespace ::$namespace
	    }
	}
	catch {next {*}$args}
    }
}
