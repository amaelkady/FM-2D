# Coco.tcl - a domain built around coroutines from tcl8.6

package require Debug
Debug define coco 10
package require Http
package require md5

package provide Coco 2.0

set ::API(Domains/Coco) {
    {
	Tcl8.6 Coroutine domain.  Invoking the domain URL creates a coroutine with semantics given by a lambda (evaluated within the Coco namespace,) and associates this running coroutine with an automatically-generated URL.  The domain URL invocation, having generated its coroutine, redirects to it.

	Coco is like a [Direct] domain except the functional element is a coroutine not a namespace or object instance.  The coroutine created by invoking a Coco domain has a unique name which will persist until the coroutine exits or until the server restarts.

	Coroutines maintain their local variable state, so Coco may be used to maintain persistent state for as long as the coroutine exists.  It is possible, therefore, to use Coco as the basis of a session facility.

	The Cocoroutine is called with the request dict.  [[yield]] may return a response to that request, which will subsequently be returned to the client.  If [[yield]] is called without an argument, it returns an HTTP redirect to the coroutine's URL.

	== Coco Forms ==
	Since Coco provides lightweight session persistence, keyed by synthetic URL, it can be used to validate forms.  The [[Coco form]] command is invoked as ''[[Coco form $request $form [[list $fail_message $predicate]] ... ]]''.  Where $request is the current HTTP request dict, $form is an HTML form (with an optional %MESSAGE string embedded), and args are a validation dict.

	Validation dicts associate the name of a field in the form with a list comprising a message to be displayed if the validation fails, and a tcl validation expression or predicate.  The predicate may be anything acceptable to Tcl's [[expr]], and is expected to return a boolean value.  All form fields are available to each predicate as tcl variables of the same name.

	[[Coco form]] will cause the Coco coroutine to re-issue the form until all validation predicates evaluate true.

	=== Example: validating a form ===
	[[Coco form]] provides a form validation facility.  Once called, it will return the supplied form until all validation predicates are true.

	Nub domain /copf/ Coco lambda {r {
	    set referer [Http Referer $r]	;# remember referer
	    set r [yield]	;# initially just redirect

	    set prefix "[<h1> "Personal Information"][<p> "Referer: '$referer'"]"
	    set suffix [<p> [clock format [clock seconds]]]

	    # validate the supplied form against a dict of field/validators
	    set r [my Form $r info -prefix $prefix -suffix $suffix {
		<p> class message [join %MESSAGE% <br>]
		fieldset personal {
		    legend [<submit> submit "Personal Information"]
		    text forename title "Forename" -invalid "Forename can't be empty" -validate {$forename ne ""}
		    text surname title "Surname" -invalid "Surname can't be empty." -validate {$surname ne ""}
		    [<br>]
		    text phone title "Phone number" -invalid "Phone number has to look like a phone number." -validate {[regexp {^[-0-9+ ]+$} $phone]}
		}
	    }]

	    # now all the variable/fields mentioned in [form] have valid values
	    
	    # resume where you were
	    return [Http Redirect $r $referer]
	}}

	== Examples ==

	=== Simple interaction example ===
	This Cocoroutine returns a simple form, collects its response, echoes it to the client, and terminates.

	Nub domain /said/ Coco lambda {r {
	    set r [yield [Http Ok+ [yield] [<form> said "[<text> stuff][<submit> ok]"]]]
	    Query qvars [Query parse $r] stuff	;# fetch $stuff from the submitted form
	    return [Http Ok+ [yield [Http Ok+ $r [<a> href . "click here"]]] [<p> "You said: $stuff"]]
	    # this coroutine is a one-shot - as it returns, the coroutine will disappear
	}}

	=== Example: Counting calls ===
	The following just counts calls to the synthetic URL

	Nub domain /coco/ Coco lambda {r {
	    set r [yield]	;# initially just redirect to this coroutine
	    while {1} {
		# this coroutine loops around counting calls in $n
		set content [<h1> "Coco - Coroutining"]
		append content [<p> "You have called the coroutine [incr n] times."]
		set r [yield [Http Ok [Http NoCache $r] $content]]
	    }
	}}

	=== Referenced in Examples ===
	;[http:Nub domain]: a command which construct a nub, mapping a URL-glob onto a domain handler (in this case, Coco.)
	;[http:../Utility/Http Http]: a module to transform request dicts into response dicts suitable for returning to the client.  In summary, [[Http Ok]] generates a normal HTTP Ok response, [[Http Redirect]] generates an HTTP Redirect response, and so on.
	;[http:../Utility/Query Query]: a module to parse and manipulate the GET-query or POST-entity components of a request.
	;<*>: commands of this form are defined by the [http:../Utility/Html Html] generator package and the [http:../Utility/Form Form] generator package.
    }
    lambda {+a lambda or procname (taking a single argument) which is invoked as a coroutine to process client input.  This lambda will be invoked in the context of the Coco-constructed coroutine.}
}

class create ::Coco {
    method var {name} {
	upvar #1 $name var
	if {[info exists var]} {
	    return $var
	} else {
	    return ""
	}
    }

    # form - construct a self-validating form within a Coco
    # this will continue emitting and validating form until it's complete
    method Form {_r name args} {
	variable hint
	set form [lindex $args end]
	set args [lrange $args 0 end-1]

	set prefix [dict get? $args -prefix]; dict unset? args -prefix
	set suffix [dict get? $args -suffix]; dict unset? args -suffix

	Debug.coco {[self] Form $name}
	upvar 1 _vals _vals
	set _vals {}
 
	set lmetadata {}
	set form [my layout_parser $name -content {my var} $form]
	dict for {n v} $lmetadata {
	    dict set _vals $n [dict get? $v -content]
	    if {[dict exists $v -validate]} {
		set _validates($n) [dict get $v -validate]
	    }
	    if {[dict exists $v -invalid]} {
		set _messages($n) [string trim [dict get $v -invalid] \"]
	    }
	}
	uplevel 1 {dict with _vals {}}	;# initialize corovars

	Debug.coco {[self] layout: $form}
	set metadata [my metadata]
	Debug.coco {FORM: $form}
	Debug.coco {METADATA: $metadata}

	set _message [list {Enter Fields.}]	;# initial message
	while {[llength $_message]} {
	    if {$hint} {
		set _r [jQ hint $_r]	;# add form hinting
	    }
	    
	    # issue form
	    set F [uplevel 1 [list [self] <form> {*}$form]]	;# generate form
	    set F [string map [list %MESSAGE% [join $_message <br>]] $F]
	    set F "$prefix\n$F\n$suffix"
	    set _r [yield [Http Ok [Http NoCache $_r] $F x-text/html-fragment]]

	    # unpack query response
	    set _Q [Query parse $_r]; dict set _r -Query $_Q; set _Q [Query flatten $_Q]
	    Debug.coco {[info coroutine] Query: $_Q / ([dict keys $_vals])}

	    # fetch and validate response fields
	    set _message {}	;# default - empty message
	    foreach _var [dict keys $_vals] {
		dict set _vals $_var [dict get? $_Q $_var]	;# record value
	    }

	    uplevel 1 {dict with _vals {}}	;# initialize corovars
	    
	    Debug.coco {[info coroutine] form vals: $_vals}
	    foreach _var [dict keys $_vals] {
		if {[info exists _validates($_var)]} {
		    set valid [uplevel 1 expr $_validates($_var)]
		    Debug.coco {[info coroutine] valid? '$_var' -> '$valid'}
		    if {!$valid} {
			lappend _message $_messages($_var)
		    }
		}
	    }
	}
	
	return $_r
    }

    # process request helper
    method do {r} {
	variable mount
	# calculate the suffix of the URL relative to $mount
	lassign [Url urlsuffix $r $mount] result r suffix path
	if {!$result} {
	    return [Httpd NotFound $r]	;# the URL isn't in our domain
	}

	Debug.coco {process '$suffix' over $mount}
	
	if {$suffix eq "/" || $suffix eq ""} {
	    # this is a new call - create the coroutine
	    variable uniq; incr uniq
	    set cmd [::md5::md5 -hex $uniq[clock microseconds]]

	    dict set r -cmd $cmd

	    Debug.coco {coroutine initialising - ($r) reply}
	    variable lambda
	    set s [lrange [list {*}$lambda [namespace current]] 0 2]
	    set result [coroutine Coros::@$cmd ::apply $s $r]

	    if {$result ne ""} {
		Debug.coco {coroutine initialised - ($r) reply}
		return $result	;# allow coroutine lambda to reply
	    } else {
		# otherwise simply redirect to coroutine lambda
		Debug.coco {coroutine initialised - redirect to ${mount}$cmd}
		return [Http Redirect $r [string trimright $mount /]/$cmd/]
	    }
	}

	set extra [lassign [split $suffix /] cmd]
	dict set r -extra [join $extra /]

	if {[namespace which -command Coros::@$cmd] ne ""} {
	    # this is an existing coroutine - call it and return result
	    Debug.coco {calling coroutine '@$cmd' with extra '$extra'}
	    if {[catch {
		Coros::@$cmd $r
	    } result eo]} {
		Debug.error {'@$cmd' error: $result ($eo)}
		return [Http ServerError $r $result $eo]
	    }
	    Debug.coco {'@$cmd' yielded: ($result)}
	    return $result
	} else {
	    Debug.coco {coroutine gone: @$cmd}
	    variable tolerant
	    if {$tolerant} {
		return [Http Redirect $r [string trimright $mount /]/]
	    } else {
		return [Http NotFound $r [<p> "WubTk '$cmd' has terminated."]]
	    }
	}
    }

    destructor {
	namespace delete Coros
    }

    superclass FormClass	;# allow Form to work nicely
    constructor {args} {
	variable hint 1
	variable tolerant 0
	variable {*}[Site var? Coco]	;# allow .ini file to modify defaults
	variable {*}$args
	namespace eval [namespace current]::Coros {}
	next {*}$args
    }
}
