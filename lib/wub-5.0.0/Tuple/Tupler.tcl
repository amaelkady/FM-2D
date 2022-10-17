# Tupler - Tuple Rendering
#
# This is a child of Tuple which provides a Direct interface
# for presentation, creation and interaction with Tuples
# and a Convert interface to permit type-based rendering.
#
# Example: Nub domain /tuple/ {Tupler ::tupler} prime [::fileutil::cat [file join [file dirname [info script]] prime.tcl]]

if {[info exists argv0] && ($argv0 eq [info script])} {
    lappend auto_path ~/Desktop/Work/Wub/ [file dirname [info script]]
}

package require Tuple

if {[catch {package require Debug}]} {
    #proc Debug.tupler {args} {}
    proc Debug.tupler {args} {puts stderr HTTP@[uplevel subst $args]}
} else {
    Debug define tupler 10
}

package require OO
package require Site
package require Direct
package require Convert
package require Http
package require Html
package require Url
package require fileutil

package provide Tupler 1.0

oo::class create Tupler {
    foreach {f t} {
	text text/plain
	javascript application/javascript
	css text/css
    } {
	{*}[string map [list %F% $f %T% $t] {
	    method tuple/%F%.%T% {r} {
		dict set r content-type %T%
		return $r
	    }
	}]
    }
    method x-text/system.tuple/html {r} {
	return [Http Pass $r [dict get $r -content] tuple/html]
    }
    method x-text/system.tuple/text {r} {
	return [Http Pass $r [dict get $r -content] tuple/html]
    }

    set ::Tuple_home [file dirname [info script]]

    method tuRConvert {tuple to {from ""}} {
	dict with tuple {
	    if {$from eq ""} {
		set from tuple/$type
	    }
	    Debug.tupler {tuRConvert '[dict get $tuple name]' '$from->$to'}
	    set r [list content-type $from -content $content -tuple $tuple]
	}
	set result [my convert! $r $to]
	Debug.tupler {tuRConverted '[dict get $tuple name]' '$from->$to' => ($result)}
	return $result
    }

    method tuConvert {args} {
	Debug.tupler {tuConvert ($args)}
	set result [dict get [my tuRConvert {*}$args] -content]
	Debug.tupler {tuConverted ($result)}
	return $result
    }

    method component {r name el {type html}} {
	if {[catch {my fetch $name+$el} c]} {
	    Debug.tupler {'$name+$el' => NONE}
	    return {}
	}

	Debug.tupler {component convert '$name+$el' ($c) 'tuple/[dict get $c type]->tuple/$type'}
	set cpp [my tuRConvert $c tuple/$type]
	Debug.tupler {component conversion 'tuple/[dict get $c type]->tuple/$type' -> ($cpp)}

	# conversion of components may generate more header components
	# these must be added to the response
	foreach sub {script style} {
	    upvar $sub $sub
	    if {[dict exists $cpp -$sub]} {
		set $sub [dict merge [set $sub] [dict get $cpp -$sub]]
		Debug.tupler {component subcomponent '$name' -$sub is '[set $sub]'}
	    }
	}

	Debug.tupler {component done '$name' $el => [dict get $c id] '[dict get $cpp -content]'}
	return [list $r [dict get $c id] [dict get $cpp -content]]
    }

    # check for body and header components of document and assemble them
    method assemble {r name el tag args} {
	# fetch, convert and index header components
	Debug.tupler {assemble $name $el $tag $args}
	upvar $el result
	set result [dict merge $result [dict get? $r -$el]]

	# record supplied header components
	set loader {}
	set scripts {}
	dict for {n v} $result {
	    if {[string match !* $n]} {
		Debug.tupler {assembling literal $el '$n'}
		dict set scripts $n $v 
	    } else {
		Debug.tupler {assembling $el '$n' -> [$tag $n {*}$v]}
		dict set loader $n [$tag $n {*}$v]
	    }
	}

	if {![catch {my fetch $name+$el} c]} {
	    Debug.tupler {component '$name+$el' => $c}
	    set ct [string tolower [dict get $c type]]
	    set cc [dict get $c content]
	    set cid [dict get $c id]	;# default - index by component id
	    set cto head

	    if {$ct ni $args} {
		set cto [lindex $args 0]	;# convert to first expected type
	    } elseif {$ct eq "ref"} {
		set cid [lindex $cc 0]	;# index refs by URL component of ref
	    }
 
	    if {![dict exists $result $cid]} {
		# convert metadata component to expected type
		# index component by appropriate id
		set conv [my tuConvert $c tuple/$cto tuple/$ct]
		Debug.tupler {assembling $el $cid '$conv'}
		dict set scripts $cid $conv
	    } else {
		# don't bother converting if we already have this component
		Debug.tupler {not assembling $el $cid - duplicate}
	    }
	}

	Debug.tupler {assembled: ($result) -> '[join [dict values [dict merge $loader $scripts]] \n]'}
	return [join [dict values [dict merge $loader $scripts]] \n]
    }

    method html {body {head ""}} {
	# construct the final HTML text
	variable doctype	;# html doctype from Tupler instance
	append html $doctype \n
	append html <html> \n
	append html <head> \n $head \n </head> \n
	append html <body> \n $body \n </body> \n
	append html </html> \n
	return $html
    }

    method tuple/html.text/html {r args} {
	# convert the Html type to pure HTML
	dict set r -raw 1	;# no more conversions after this
	Debug.tupler {dynamic?: [dict get? $r -dynamic]}
 
	if {[string match "<!DOCTYPE*" [dict get $r -content]]} {
	    return [Http Ok $r $html text/html]	;# content is already fully HTML
	}

	variable html5
	if {$html5} {
	    set tag <section>
	} else {
	    set tag {<div> class section}
	}

	# pre or post process HTML fragments by assembling their subcomponents
	set tuple [dict get $r -tuple]
	set _left {}; set _right {}
	dict with tuple {}
	set r [Http CacheableContent $r $modified]

	# these will be filled in by [component]
	set style {}
	set script {}
	set footer ""
	if {[string tolower [dict get? $r -x-requested-with]] eq "xmlhttprequest"} {
	    # Transclusion - no textual components
	    Debug.tupler {'$name' tuple/html.text/html - ajax request - no textual components '[dict get? $r -x-requested-with]'}
	} else {
	    Debug.tupler {'$name' tuple/html.text/html - non-ajax request}
	    # fetch text/plain data (title)
	    foreach el {title} {
		set cm [my component $r $name $el text]
		if {[llength $cm]} {
		    lassign $cm r cid cc
		    dict lappend r -$el $cc
		}
	    }

	    foreach el {header nav aside footer} {
		set cm [my component $r $name $el]
		if {[llength $cm]} {
		    lassign $cm r cid cc
		    set $el [<$el> id T_$cid $cc]
		} else {
		    set $el ""
		}
	    }

	    append body $header \n
	    append body $nav \n
	    append body $aside \n

	}

	append body [{*}$tag id T_[armour $id] class editable [subst {
	    <!-- loaded name:'[armour $name]' left:[armour $_left] right:[armour $_right] -->
	    [dict get $r -content]
	    <!-- transforms [armour [dict get? $r -transforms]] -->
	}]] \n
	append body $footer \n

	# process dependent jQ file as text
	if {![catch {my fetch $name+jq} c]} {
	    set jQc [split [my tuConvert $c tuple/text] \n]
	    set jQl {}
	    foreach l $jQc {
		set l [string trim $l]
		if {[string match #* $l] || $l eq ""} continue
		lappend jQl $l
		set a [lassign [split $l] jq]
		Debug.tupler {jQ $jq .. $a}
		set r [jQ $jq $r {*}$a]
	    }
	    
	    append body "<!-- jQ [armour [join $jQl ,]] -->" \n
	    
	    Debug.tupler {post-jQ: ($r)}
	}

	# add inline scripts to <body> part
	append body [my assemble $r $name script <load> javascript ref]
 
	# construct <head> part
	if {[dict exists $r -title]} {
	    set head [<title> [armour [join [dict get $r -title]]]]\n
	} else {
	    set head [<title> [armour [dict get $r -tuple name]]]\n
	}
	
	# add so-called html5-shiv to permit IE to render HTML5
	append head {
	    <!--[if IE]>
	    <script src="http://html5shiv.googlecode.com/svn/trunk/html5.js"></script>
	    <![endif]-->
	}

	# add style preloads
	append head [my assemble $r $name style <stylesheet> css ref]

	return [Http Ok $r [my html $body $head] text/html]
    }

    # /js - return the pre-canned javascript for Tupler
    method /js/js {r args} {
	variable js
	# TODO - caching and expiry stuff
	return [Http Ok [Http Cache $r "next week"] $js application/javascript]
    }

    # MkType - creates a bare-bones Type tuple for a new object
    method MkType {name {type type}} {
	if {[catch {
	    my fetch $name
	} tuple]} {
	    Debug.tupler {MkType did not find '$name'}
	    set id [my new [list name $name type $type]]
	    Debug.tupler {MkType created $id -> ([my get $id])}
	    return [my get $id]
	}
	set tt [string tolower [dict get? $tuple type]]
	if {$tt ne $type} {
	    if {0 && $tt eq ""} {
		# it's empty type, we can coerce it
		my set [dict get $tuple id] type [string tolower $type]
	    } else {
		return -code error -kind type -notfound $name "'$name' must be of type '$type' but is of type '[dict get? $tuple type]' ($tuple)"
	    }
	} else {
	    return $tuple
	}
    }

    # fixup - consistency and semantic supplements to tuples
    # on their way to and from the store.
    method fixup {tuple} {
	set type Basic	;# default type
	dict with tuple {
	    set type [string tolower $type]

	    # check for conversions and Types
	    switch -- $type {
		type {
		    # the content of a Type is its Convert postprocessor
		    if {[info exists content]
			&& $content ne ""
		    } {
			if {![info exists mime]} {
			    dict set tuple mime "Tcl Script"
			}
			
			# (re)define the postprocess method
			set mname tuple/[string map {_ / " " _} [string tolower $name]]
			oo::objdefine [self] [string map [list %N% $mname %C% $content] {
			    method %N% {r} {%C%}
			}]
			my postprocess $mname [self] $mname
			Debug.tupler {added postprocess for type '$name' called $mname}

			if {![info exists mime]} {
			    dict set tuple mime "Tcl Script"
			}
		    }
		}

		conversion {
		    # Conversion tuples create matching methods in [self] to handle
		    # type conversion and content negotiation.
		    if {[llength [lassign [split $name +] l r]]} {
			return -code error -kind form -notfound $name "$name must be a pair"
		    }
		    set lt [my MkType $l type]
		    set rt [my MkType $r type]

		    # conversion tuple
		    Debug.tupler {fixup conversion $l -> $r on $name}

		    # (re)define the conversion method
		    set lname tuple/[string map {_ / " " _} [string tolower [dict get $lt name]]]
		    set rname tuple/[string map {_ / " " _} [string tolower [dict get $rt name]]]
		    set mname $lname.$rname
		    
		    oo::objdefine [self] [string map [list %N% $mname %C% [dict get $tuple content]] {
			method %N% {r} {%C%}
		    }]

		    my transform $lname $rname [self] $mname
		    Debug.tupler {added conversion from '$lname' to '$rname' called '$mname'}

		    if {![info exists mime]} {
			dict set tuple mime "Tcl Script"
		    }
		}
	    }
	}

	Debug.tupler {Tupler fixed up ($tuple)}
	return [next $tuple]
    }

    method getmime {tuple {default html}} {
	set mime [string map {" " _} [string tolower [dict get? $tuple mime]]]
	if {$mime eq ""} {
	    return tuple/$default
	} else {
	    return tuple/$mime
	}
    }

    method bad {r eo} {
	# failed to resolve name
	set extra [dict get $r -extra]
	set nfname [dict get? $eo -notfound]
	set kind [dict get? $eo -kind]
	
	# just an error - rethrow it
	if {$kind eq ""} {
	    return -options $eo
	} else {
	    if {[catch {
		my fetch "*rform+Not Found"
	    } found]} {
		# no user-defined page - go with the system default
		variable notfound
		return [Http NotFound $r [subst $notfound] x-text/html-fragment]
	    } else {
		# found the user-defined page "Not Found"
		return [Http Redirect $r "*rform+Not Found" name $nfname extra $extra kind $kind mime "" content "" type ""]
	    }
	}
    }

    method getname {r} {
	set extra [dict get $r -extra]
	Debug.tupler {getname extra: $extra}

	if {[string match +* $extra]} {
	    # + prefix means relative to referer
	    variable mount
	    set referer [Http Referer $r]
	    if {$referer eq ""} {
		error "$extra is not meaningful except as a component of a Tuple"
	    }
	    lassign [Url urlsuffix $referer $mount] meh rn suffix path
	    set extra $suffix$extra
	    Debug.tupler {getname: suffix:'$suffix' path:'$path' extra:'$extra'}
	}

	Debug.tupler {getname got: '$extra'}
	return $extra
    }

    method typeselect {{special ""}} {
	set tlist [lsort -dictionary [my names {*}[my oftype Type]]]
	Debug.tupler {typeselect: '$tlist'}
	if {$special eq ""} {
	    return $tlist
	}
	
	set special [string tolower $special]
	set types {}
	foreach type $tlist {
	    Debug.tupler {typeselector: '$type'}
	    if {$special ne "" && $special eq [string tolower $type]} {
		lappend types [list +$type]
	    } else {
		lappend types [list $type]
	    }
	}
	Debug.tupler {typeselected: '$types'}
	return $types
    }

    # xray a tuple - presenting it as a dict
    method /xray {r args} {
	set extra [my getname $r]
	if {[catch {my fetch $extra} tuple eo]} {
	    tailcall my bad $r $eo
	} else {
	    # resolved name
	    dict with tuple {
		dict set r -title "XRay of '$name'"
		dict set r -tuple $tuple
		dict set r -convert [self]
		return [Http Ok $r $tuple tuple/tcl_dict]
	    }
	}
    }

    method invalidate {id args} {
	if {![dict exists $args modified]} {
	    set modified [my get $id modified]
	} else {
	    set modified [dict get $args modified]
	}

	Cache invalidate T_$id@$modified
	Cache invalidate P_$id@$modified
    }

    # saveJE - save content given by Jeditable - inline jQ editor
    method /saveJE {r id content args} {
	Debug.tupler {/saveJE $id $args}
	dict set r -convert [self]

	set id [string range $id 2 end]	;# remove leading T_
	my invalidate $id	;# invalidate old cache contents
	my set $id [list content $content]

	set tuple [my get $id]
	dict set tuple _right [dict get $tuple name]
	dict set tuple _left {}

	dict set r -tuple $tuple

	# resolved name
	dict with tuple {
	    if {![info exists type]
		|| $type eq ""
	    } {
		set type basic
	    } else {
		set type [string map {" " _} [string tolower $type]]
	    }
	}

	Debug.tupler {saveJE -> tuple/$type, [dict get? -$r -convert]}

	# we must not cache /saveJE results
	tailcall Http Ok [Http NoCache $r] $content tuple/$type
    }

    # /save - save the tuple handed in from a form
    method /save {r args} {
	Debug.tupler {/save $args}
	dict set r -convert [self]

	set columns [my columns]
	set tuple {}	;# set of field values

	# sort args into tuple columns and others
	dict for {n v} $args {
	    if {[dict exists $columns $n]} {
		dict set tuple $n $v
		dict unset args $n
	    }
	}

	dict with tuple {
	    if {[catch {
		set outcome OK
		if {![info exists id]} {
		    # new tuple - create
		    Debug.tupler {/save creating ($tuple)}
		    if {![info exists name]} {
			error "All tuples must have a name"
		    }
		    set op create
		    my new $tuple
		} else {
		    # existing tuple - update
		    Debug.tupler {/save updating ($tuple)}
		    if {[info exists name]} {
			unset name	;# we do not change names
		    }
		    set op update
		    my invalidate $id
		    my set $id $tuple
		}
	    } result eo]} {
		set outcome failed
	    }
	}

	Debug.tupler {/save $op $outcome $result}
	tailcall Http Ok [Http NoCache $r] [<p> "$op $outcome $result"]
    }

    # send plain text contents of a tuple
    method /plain {r args} {
	dict set r -extra [file rootname [dict get $r -extra]]
	set extra [my getname $r]
	dict set r -convert [self]

	if {[catch {my fetch $extra} tuple eo]} {
	    tailcall my bad $r $eo
	}

	# we're requested to provide just the text
	Debug.tupler {/transclude id:'[dict get? $args id]'}
	dict with tuple {}
	set content [::textutil::undent [::textutil::untabify $content]]
	set content [string trim $content]

	# set expiry from DB
	if {![info exists expiry] || $expiry eq ""} {
	    set ttuple [my typeof {*}$tuple]
	    Debug.tupler {finding expiry from type ($ttuple)}
	    set expiry [dict get? $ttuple expiry]
	}
 
	if {$expiry ne ""} {
	    # this is cacheable with given expiry
	    Debug.tupler {/transclude Caching $expiry}
	    set r [Http Cache $r {*}$expiry]
	}

	dict set r etag "P_$id@$modified"	;# give tuple a unique ETag
	catch {dict unset r -dynamic}

	tailcall Http Ok $r $content text/plain
    }

    # view a tuple - giving it its most natural HTML presentation
    method /view {r args} {
	set extra [my getname $r]
	dict set r -convert [self]

	if {[catch {my fetch $extra} tuple eo]} {
	    tailcall my bad $r $eo
	}

	dict set r -tuple $tuple
	dict with tuple {}

	Debug.tupler {/view '$name'}

	if {![info exists type]
	    || $type eq ""
	} {
	    set type basic
	} else {
	    set type [string map {" " _} [string tolower $type]]
	}

	# set expiry from DB
	if {![info exists expiry] || $expiry eq ""} {
	    set ttuple [my typeof {*}$tuple]
	    Debug.tupler {finding expiry from type ($ttuple)}
	    set expiry [dict get? $ttuple expiry]
	}
	    
	if {$expiry ne ""} {
	    # this is cacheable with given expiry
	    Debug.tupler {/view Caching $expiry}
	    set r [Http Cache $r {*}$expiry]
	}

	dict set r etag "T_$id@$modified"	;# give tuple a unique ETag
	catch {dict unset r -dynamic}

	Debug.tupler {/view -> tuple/$type, [dict get? -$r -convert]}
	tailcall Http Ok [Http CacheableContent $r $modified] $content tuple/$type
    }

    method /dump {r args} {
	set content {}
	foreach tuple [my stmt {SELECT * FROM tuples}] {
	    set name [dict get $tuple name]
	    #dict unset tuple name
	    dict set content $name $tuple
	}
	dict set r -raw 1
	return [Http Ok $r $content text/tcl]
    }

    # default presentation
    method / {r args} {
	set extra [dict get $r -extra]
	if {$extra eq ""} {
	    variable welcome
	    return [Http Redirect $r $welcome]
	}

	set ext [file extension [Url tail $extra]]
	switch -- $ext {
	    .PT {
		# what is wanted is a straight textual content
		tailcall my /plain $r {*}$args
	    }
	    default {
		tailcall my /view $r {*}$args
	    }
	}
    }

    superclass Tuple Convert Direct

    constructor {args} {
	Debug.tupler {Creating Tupler [self] $args}
	variable mount
	variable welcome welcome
	variable primer prime.tcl		;# primer for Tupler
	variable doctype "<!DOCTYPE html>"	;# HTML5 doctype
	variable notfound {
	    [<h1> [string totitle "$kind error"]]
	    [<p> "'$name' not found while looking for '$extra'"]
	}
	variable html5 1
	variable {*}$args
	variable js [::fileutil::cat [file join $::Tuple_home Tupler.js]]

	if {![info exists prime]} {
	    # always try to prime the Tuple with something
	    #variable prime [::fileutil::cat [file join $::Tuple_home $primer]]
	    package require Config
	    set conf [Config new file [file join $::Tuple_home $primer]]
	    set prime [$conf extract]
	    $conf destroy
	    #Debug.tupler {PRIME: $prime}
	    dict set args prime $prime
	}

	set args [dict merge [Site var? Tupler] $args]	;# allow .ini file to modify defaults
	next? {*}$args conversions 0

	# we have to instantiate all type and convert tuples, so their conversions are known
	foreach id [my oftype Conversion] {
	    my exists $id
	}
	foreach id [my oftype Type] {
	    my exists $id
	}

	# add special transformations between native Types and mime types
	foreach {f t} {
	    text text/plain
	    html text/html
	    javascript application/javascript
	    css text/css
	} {
	    my transform tuple/$f $t [self] tuple/$f.$t
	}

	Debug.tupler {Conversion Graph: [my graph]}
	Debug.tupler {Conversion Transforms: [my transforms]}
    }
}

if {[info exists argv0] && ($argv0 eq [info script])} {
    package require fileutil
    Debug on convert 10
    Debug on tupler 10
    Debug on tupleprime 10

    set ts [Tupler new]

    if {0} {
	catch {$ts moop} e eo
	puts [string repeat = 80]
	puts "intentional error: '$e'"
    }

    if {0} {
	puts [string repeat = 80]
	puts "graph: [$ts graph]"
    }

    if {0} {
	puts [string repeat = 80]
	puts "check:"
	foreach {i} [$ts ids] {
	    set tuple [$ts fetch #$i]
	    dict with tuple {
		if {$i != $id} {
		    error "ID MISMATCH: ($tuple) found by #$i"
		}
	    }
	}
    }

    if {0} {
	puts [string repeat = 80]
	puts "test 'full' method:"
	foreach {n v} [$ts full] {
	    set x [$ts find #$n]
	    if {[lindex $x 0] != $n} {
		error "Couldn't find $n"
	    }
	    puts "$n: ($v)"
	}
    }

    if {0} {
	puts [string repeat = 80]
	puts "test 'view' method"
	set fetched [$ts /view {-extra now}]
	puts "view fetched: $fetched"
	puts [$ts convert! $fetched text/html]
    }

    if {0} {
	puts [string repeat = 80]
	puts "test xray method"
	set fetched [$ts /xray {-extra now}]
	puts "xray fetched: $fetched"
	puts [$ts convert! $fetched text/html]
    }

    if {0} {
	puts [string repeat = 80]
	puts "test Variable type"
	set fetched [$ts /view {-extra reflect}]
	puts "Variable fetched: $fetched"
	puts [$ts convert! $fetched text/html]
    }

    if {0} {
	puts [string repeat = 80]
	puts "test Text type"
	set fetched [$ts /view {-extra "Example Text"}]
	puts "Text fetched: $fetched"
	puts [$ts convert! $fetched text/plain]
    }

    if {0} {
	puts [string repeat = 80]
	puts "test Reflect Text"
	set fetched [$ts /view {-extra "Reflect Text"}]
	puts "Reflect Text fetched: $fetched"
	puts [$ts convert! $fetched text/plain]
    }

    if {0} {
	puts [string repeat = 80]
	puts "test Example Uppercase"
	set fetched [$ts /view {-extra "Example Uppercase"}]
	puts "Example Uppercase fetched: $fetched"
	puts [$ts convert! $fetched text/plain]
    }

    if {1} {
	puts [string repeat = 80]
	puts "test Glob"
	set fetched [$ts /view {-extra "Glob Test"}]
	puts "test Glob fetched: $fetched"
	puts [$ts convert! $fetched text/html]
    }
}
