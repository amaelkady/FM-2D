# Cookies - a package to provide parsing and formatting of HTTP cookies
# according to rfc2109 (with a nod to Netscape)
#
# TODO: effective filtering of cookies for a given URL
#
# URL: http://wiki.tcl.tk/Cookies.tcl
#
# Modification:
# Wed, 31st Jan, 2007	Initial Release	Colin McCormack (colin at chinix dot com)

set ::API(Utilities/Cookies) {
    {
	Cookie handler utility.

	== API ==

	=== Cookie Accessor/Mutators ===
	;Cookies match: return a list of unique cookie names within cookies dict which match the template given in $args
	;Cookies clear: clear all cookies in cookie dict which match the template in args note: the cookies are modified to a state intended to cause a client to drop the cookie from their local cookie jar. YMMV.
	;Cookies add: add a cookie to the cookie dict. Cookie must be unique (by -name, -domain, -path)
	;Cookies remove: remove matching cookies from the cookie dict.
	;Cookies modify: modify matching cookies in the cookie dict
	;Cookies fetch: fetch a single matching cookie's value from the cookie dict
	;Cookies fetchAll: fetch all matching cookies' values from the cookie dict

	=== Cookie constructors/parsers ===
	;Cookies expire: filter all expired cookies from a cookie dict
	;Cookies format4client: format a cookie dict into a list of ''cookie:'' values suitable to be sent by an HTTP/1.1 client
	;Cookies parse4client: decode a cookie header received from a server into a dict
	;Cookies format4server: Save the cookie dict into fields ready to be sent by HTTP/1.1 server
	;Cookies parse4server: decode a cookie header received from a server into a dict
	;Cookies 4Server: decode cookie header into a request dict

	== Cookie Dict Format ==
	Cookies are stored and manipulated in dicts with the following feature elements:

	;-name: the cookie name
	;-path: the URL path prefix within which the cookie is active
	;-domain: the URL domain suffix within which the cookie is active
	;-value: the cookie's value
	;-comment: a comment - don't know if this is useful
	;-secure: completely useless
	;-when: the absolute seconds when the cookie expires
	;-changed: an indicator that this code has changed a cookie's values.  (Used by format4* procs to only send changed cookie values.)
    }
}

package provide Cookies 1.0

namespace eval ::Cookies {

    # filter all expired cookies from a cookie dict
    proc expire {cookies {now ""}} {
	# get a time value as a base for expiry calculations
	if {$now eq ""} {
	    set now [clock seconds]
	}
	
	# expire old cookies
	dict for {name cdict} $cookies {
	    # ensure the cookie expires when it's supposed to
	    set name [dict get $cdict -name]
	    if {[dict exists $cdict -when] && ([dict exists $cdict -when] < $now)} {
		dict unset cookies $name	;# delete expired cookie
		continue
	    }
	}
	return $cookies
    }

    # return an http date
    proc DateInSeconds {date} {
	if {[string is integer -strict $date]} {
	    return $date
	} elseif {[catch {clock scan $date \
			-format {%a, %d %b %Y %T GMT} \
			-gmt true} result eo]} {
	    error "DateInSeconds '$date', ($result)"
	} else {
	    return $result
	}
    }

    # filter all expired cookies from a cookie dict stored in a record
    proc expire_record {rec} {
	if {[dict exists $rec -cookies]} {
	    # get a time value as a base for expiry calculations
	    if {[dict exists $rec date]} {
		set now [DateInSeconds [dict get $rec date]]
	    } else {
		set now [clock seconds]
	    }
	    dict set rec -cookies [expire [dict get $rec -cookies] $now]
	}
	return $rec
    }

    proc domain_match {a b} {
	# Host A's name domain-matches host B's if
	if {$a eq $b} {
	    return 1
	}

	# they're not identical
	for v {a b} {
	    if {[regexp {[0-9]+[.][0-9]+[.][0-9]+[.][0-9]+} $a]} {
		return 0
	    }
	}

	# try a prefix match:
	return [string match "*.[string trimleft $b .]" $a]
    }

    # filter a cookie dict according to rfc2109
    # against the url dict given in args
    proc filter {cookies args} {
	if {[llength $args] eq 1} {
	    set args [lindex $args 0]
	}
	set cookies [expire $cookies]	;# expire any old cookies

	dict for {n cookie} [match $cookie $args] {
	    # decide which cookies are in and out according to rfc2109
	    if {[dict exists $args -domain]
		&& [dict exists $cookie -domain]
		&& ![domain-match [dict get $args -domain] [dict get $cookie -domain]]} {
		dict unset cookies $n
		continue
	    }
	    if {[dict exists $args -path]
		&& [dict exists $cookie -path]
		&& ![string match "[string trimright [dict get $cookie -path] /]/*" [dict get $args -path]] {
		    dict unset cookies $n
		    continue
		}
	    }
	    # TODO: ordering multiple cookies with same name by -path specificity
	}
	return $cookie_dict
    }

    # format a cookie dict into a list of 'cookie:' values
    # ready to be sent by Http/1.1 client
    proc format4client {cookie_dict {secure 0}} {
	Debug.cookies {format4client save $cookie_dict}

	set cookies {}	;# list of cookies in rfc2109 format
	dict for {name cdict} $cookie_dict {
	    if {[string match "-*" $name]} {
		continue
	    }

	    # secure cookies should not be sent over insecure connection
	    if {[dict exists $cdict -secure] && !$secure} {
		continue
	    }

	    # cdict is a cookie record, comprising:
	    # rfc-specified attributes:
	    # -path, -comment, -domain, -max-age, -expires -secure, etc.
	    #
	    # and internal attributes:
	    # -name (the original name of the cookie)
	    # -when (the absolute seconds when the cookie expires)

	    # first send the $Version
	    if {![dict exists $cdict -version]} {
		dict set cdict -version 0
	    }
	    set cookie "\$Version=[dict get $cdict -version]"

	    # then the named value
	    set name [dict get $cdict -name]
	    set val [dict get $cdict -value]
	    if {[string is alnum -strict $val]} {
		lappend cookie "$name=[dict get $cdict -value]"
	    } else {
		lappend cookie "$name=\"[dict get $cdict -value]\""
	    }

	    # then other cookie fields with values
	    foreach k {domain path} {
		if {[dict exists $cdict -$k]} {
		    set v [dict get $cdict -$k]
		    set k [string totitle $k]
		    if {![string is alnum -strict $v]} {
			lappend cookie "\$$k=\"$v\""
		    } else {
			lappend cookie "\$$k=$v"
		    }
		}
	    }

	    lappend cookies [join $cookie ";"]
	}

	return $cookies
    }

    # reject out cookies which don't jibe with the request url
    # according to rfc2109 4.3.2
    proc reject {cookies url} {
	dict for {n cookie} $cookies {
	    if {[dict exists $cookie -path]} {
		set cpath [dict get $cookie -path]
		set upath [dict get $url -path]
		if {![string match "[string trimright ${cpath} /]/*" $upath]} {
		    dict unset cookies $n
		    continue
		}
	    }

	    if {[dict exists $cookie -domain]} {
		set cdomain [dict get $cookie -domain]
		set udomain [dict get $url -domain]
		if {([string first "." $cdomain] == -1)
		    || ([string first "." [string trimleft $cdomain "."]] != -1)
		    || ([string index $cdomain 0] ne ".")
		    || ![domain_match $udomain $cdomain]
		    || ([string first "." [string range $udomain 0 end-[string length $cdomain]]] != -1)
		} {
		    dict unset cookies $n
		    continue
		}
		
	    }
	}
	return $cookies
    }

    # construct a unique name for cookie storage
    # cookies are distinguished by -name, -domain and -path qualifiers
    proc unique {cookie} {
	Debug.cookies {unique: $cookie} 10
	if {![dict exists $cookie -domain]} {
	    dict set cookie -domain ""
	}
	if {![dict exists $cookie -path]} {
	    dict set cookie -path ""
	}
	return [list [dict get $cookie -domain] [dict get $cookie -path] [dict get $cookie -name]]
    }

    # decode a cookie header received from a server into a dict
    proc parse4client {cookies {now ""}} {
	# get a time value as a base for expiry calculations
	if {$now eq ""} {
	    set now [clock seconds]
	}

	set cdict [dict create]

	Debug.cookies {PREEXPIRES: $cookies} 9

	# hide and strip quoted strings
	catch {unset quoted}
	set re {"([^\"]+?)"}	;# quoted string
	set cnt 0
	while {[regexp $re $cookies -> quoted(\x84$cnt\x85)]} {
	    regsub $re $cookies "\x84$cnt\x85" cookies
	    incr cnt
	}

	# clean up the absolutely awful "expires" field.
	# we look for these naked time-values (which contain commas) and remove them
	# prior to splitting on ',', then resubstitute them - awful hack - blame netscape.
	catch {unset expires}
	set re {((Mon|Tue|Wed|Thu|Fri|Sat|Sun)[^,]*, +[0-9]+-(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)-[0-9]+ [0-9]+:[0-9]+:[0-9]+ GMT)}
	set cnt 0
	while {[regexp $re $cookies expires(\x81$cnt\x82)]} {
	    regsub $re $cookies "\x81$cnt\x82" cookies
	    incr cnt
	}

	# distinguish the real delimiters in the set-cookie field
	# split on delimeter, substitute back hidden values
	set cookies [string map {, \x83 ; \x86} $cookies]
	set cookies [string map [array get expires] [split $cookies "\x83"]]
	Debug.cookies {PROCESSING: [array get expires] - $cookies} 9

	# construct an attribute dict for each cookie
	set attrs [dict create]
	foreach cookie $cookies {
	    set cookie [string map [array get quoted] [split $cookie "\x86"]]
	    Debug.cookies {Client Parsing: $cookie}
	    set cval [string trim [join [lassign [split [lindex $cookie 0] =] name] =]]

	    # process each cookie's attributes
	    foreach term [lrange $cookie 1 end] {
		set val [string trim [join [lassign [split $term =] attr] =]]
		set attr [string trim $attr]
		Debug.cookies {ATTR '$attr' $val}
		dict set attrs -$attr [string trim $val \"]
	    }

	    # check cookie values, ensure -domain is in .form, etc.
	    # TODO

	    # store attribute dict into cookie dict by unique name
	    dict set attrs -value $cval
	    dict set attrs -name $name
	    set cname [unique $attrs]	;# get full name of cookie
	    dict set cdict $cname $attrs

	    # set expiry time
	    if {[dict exists $cdict $cname -expires]} {
		dict set cdict $cname -when [clock scan [dict get $cdict $cname -expires]]
	    } elseif {[dict exists $cdict $cname -max-age]} {
		dict set cdict $cname -when [expr {$now + [dict get $cdict $cname -expires]}]
	    }
	}

	return $cdict
    }

    # load cookies from a server's response into a cookie dict
    proc load_server_cookies {rsp} {
	Debug.cookies {load $rsp}

	if {[dict exists $rsp set-cookie]} {
	    # get a time value as a base for expiry calculations
	    if {[dict exists $rsp date]} {
		set now [DateInSeconds [dict get $rsp date]]
	    } else {
		set now [clock seconds]
	    }
	    Debug.cookies {Cookies to parse: [dict get $rsp set-cookie]}
	    dict set rsp -cookies [parse4client [dict get $rsp set-cookie] $now]
	} else {
	    Debug.cookies {load NO cookie}
	}

	return $rsp
    }

    # Save the -cookie sub-dict into fields ready to be sent by HTTP/1.1 server
    proc format4server {cookie_dict {secure 0}} {
	Debug.cookies {format4server save $cookie_dict}
	set cookies {}	;# collection of cookies in cookie1 format
	dict for {name cdict} $cookie_dict {
	    if {[string match "-*" $name]} {
		Debug.cookies {format4server $name is synthetic}
		continue
	    }
	    set csec [dict get? $cdict -secure]
	    if {$csec ne "" && $csec && !$secure} {
		Debug.cookies {format4server cookie $name is secure}
		continue	;# secure cookies shouldn't be sent over insecure connection

	    }
	    if {![dict exists $cdict -changed]
		|| ![dict get $cdict -changed]} {
		Debug.cookies {format4server cookie $name has not changed}
		continue
	    }

	    # cdict is a cookie record, comprising:
	    # rfc-specified attributes:
	    # -path, -comment, -domain, -max-age, -expires -secure, etc.
	    #
	    # and internal attributes:
	    # -name (the original name of the cookie)
	    # -when (the absolute seconds when the cookie expires)
	    set name [dict get $cdict -name]
	    set val [dict get? $cdict -value]
	    if {$val eq ""} {
		set val ""
	    }
	    set cookie "$name=$val"
	    if {[dict exists $cdict path]
		&& [dict get $cdict -path] eq ""
	    } {
		dict unset cdict -path
	    }

	    if {[dict exists $cdict -max-age]
		&& ![dict exists $cdict -expires]
	    } {
		# make -expires track -max-age
		set expires [expr {[clock seconds] + [dict get $cdict -max-age]}]
		dict set args -expires [clock format $expires -format "%a, %d-%b-%Y %H:%M:%S GMT" -gmt 1]
	    }
	    
	    # cookie fields with values
	    foreach k {comment domain max-age path expires} {
		if {[dict exists $cdict -$k]} {
		    set v [dict get $cdict -$k]
		    lappend cookie "[string totitle $k]=$v"
		}
	    }
	    
	    # assemble cookie
	    if {0 && $cookie != {}} {
		lappend cookie "Version=\"1\""
	    }
	    lappend cookies [join $cookie "; "]
	    Debug.cookies {format4server cookie $name new value is '$cookie'}
	}

	Debug.cookies {format4server value: ($cookies)}
	return $cookies
	#set rsp [Http Vary $rsp set-cookie]	;# cookies are significant to caching
    }

    # jiggery pokery to get around the fact that browsers
    # don't send attrs with cookies, but just send multiple cookie assignments
    # so we have to have multiple -valueN elements if this occurs.  Le Sigh.
    proc setVal {cdict attrs} {
	set cname [unique $attrs]

	set cnt 0
	if {[dict exists $cdict $cname]} {
	    dict set cdict $cname [dict merge $attrs [dict get $cdict $cname]]
	    while {[dict exists $cdict $cname value[incr cnt]]} {}	;# get unique 'value' name
	    dict set cdict $cname -value$cnt [dict get $attrs -value]	;# add a valueN element
	} else {
	    dict set cdict $cname $attrs	;# this is truly unique, so just set it
	}

	return $cdict
    }

    # decode a cookie header received from a client.
    proc parse4server {cookies} {
	Debug.cookies {PARSING '$cookies'} 10
	set cdict [dict create]	;# empty cookie dict

	# hide and strip quoted strings
	catch {unset quoted}
	set re {"([^\"]+?)"}	;# quoted string
	set cnt 0
	while {[regexp $re $cookies -> quoted(\x84$cnt\x85)]} {
	    regsub $re $cookies "\x84$cnt\x85" cookies
	    incr cnt
	}

	set cookies [string map {, ;} $cookies]	;# comma and ; are identical
	set cookies [split $cookies ";"]

	# process each cookie from client
	set cname ""
	set attrs {}
	set version 0
	foreach cookie $cookies {
	    set cookie [string trim [string map [array get quoted] $cookie]]

	    Debug.cookies {TRYING '$cookie'} 10
	    set val [string trim [join [lassign [split $cookie =] name] =]]
	    set name [string trim [string tolower $name]]

	    if {[string match {$*} $name]} {
		# it's a reserved name which applies to the previous cookie
		set name [string range $name 1 end]
		dict set attrs -$name $val
		if {$name eq "version"} {
		    set version $val
		    dict unset attrs -version
		}
	    } else {
		if {[dict size $attrs] != 0} {
		    # we have the full dict for previous cookie,
		    # save it uniquely in cdict
		    dict set attrs -version $version
		    set cdict [setVal $cdict $attrs]
		    set attrs {}
		}

		# it's a value name, but we can't store it
		# until we have -path, -domain
		dict set attrs -value $val
		dict set attrs -name $name
	    }
	}

	# store final cookie's values
	if {[dict size $attrs] != 0} {
	    dict set attrs -version $version
	    set cdict [setVal $cdict $attrs]
	}

	Debug.cookies {parsed: '$cdict'} 2
	return $cdict
    }

    # decode cookie header into a request
    proc 4Server {req} {
	Debug.cookies {4Server '[dict get? $req cookie]'}
	if {[dict exists $req -cookies]} {
	    return $req
	}
	dict set req -cookies [parse4server [dict get? $req cookie]]
	return $req
    }

    # load cookies from a client's request
    proc load_client_cookies {req} {
	if {[dict exists $rsp cookie]} {
	    dict set req -cookies [parse4server [dict get $req cookie]]
	}
	return $req
    }

    # return a list of unique cookie names within cookies dict
    # which match the template given in $args
    proc match {cookies args} {
	if {[llength $args] eq 1} {
	    set args [lindex $args 0]
	}

	if {[dict get? $args -path] eq "/"} {
	    dict unset args -path	;# a path of / is no path at all
	}
	foreach v {name path domain} {
	    if {[dict exists $args -$v]} {
		set $v [dict get $args -$v]
	    } else {
		set $v "*"
	    }
	}

	set matches [dict keys $cookies [list $domain $path $name]]
	Debug.cookies {match in dict ($cookies) for matching '$args' -> '$matches'}

	return $matches
    }

    # clear all cookies in cookie dict which match the template in args
    # note: the cookies are modified to a state intended to cause a client
    # to drop the cookie from their local cookie jar. YMMV.
    proc clear {cookies args} {
	Debug.cookies {clear ($cookies) $args}
	if {[llength $args] eq 1} {
	    set args [lindex $args 0]
	}

	foreach n [match $cookies $args] {
	    Debug.cookies {clearing '$n'}
	    dict set cookies $n -value ""
	    dict set cookies $n -max-age 0
	    dict set cookies $n -expires -1
	    dict set cookies $n -changed 1
	}

	return $cookies
    }

    # add a cookie to the cookie dict.
    # Cookie must be unique (by -name, -domain, -path)
    proc add {cookies args} {
	Debug.cookies {Cookie add ($cookies) $args}
	if {[llength $args] eq 1} {
	    set args [lindex $args 0]
	}

	set cn [unique $args]
	if {[dict exists $cookies $cn]} {
	    # modify the cookie instead of adding it.
	    return [modify $cookies {*}$args]
	    error "Duplicate cookie $args"
	}
	if {0 && ![string is alnum -strict [dict get $args -name]]} {
	    # not strictly true - can include _
	    error "name must be alphanumeric, '[dict get $args -name]'"
	}
	if {[dict exists $args -expires]} {
	    set expires [dict get $args -expires]
	    if {![string is integer -strict $expires]} {
		set expires [clock scan $expires]
	    }
	    dict set args -expires [clock format $expires -format "%a, %d-%b-%Y %H:%M:%S GMT" -gmt 1]
	}
	foreach {attr val} $args {
	    dict set cookies $cn [string tolower $attr] $val
	}
	dict set cookies $cn -changed 1

	return $cookies
    }

    # remove cookies from the cookie dict.
    proc remove {cookies args} {
	Debug.cookies {Cookie remove ($cookies) $args}
	if {[llength $args] eq 1} {
	    set args [lindex $args 0]
	}

	foreach n [match $cookies $args] {
	    dict unset cookies $n
	}
	return $cookies
    }

    # modify matching cookies in the cookie dict.
    proc modify {cookies args} {
	Debug.cookies {Cookie modify $cookies $args}
	if {[llength $args] eq 1} {
	    set args [lindex $args 0]
	}

	# construct a modifier dict, as distinct from a selector dict
	# because modify can't change the name elements of a cookie
	set mods $args
	catch {dict unset mods -name}
	catch {dict unset mods -path}
	catch {dict unset mods -domain}

	foreach cookie [match $cookies $args] {
	    foreach {attr val} $mods {
		dict set cookies $cookie $attr $val
	    }
	    dict set cookies $cookie -changed 1
	}

	return $cookies
    }

    # fetch a single matching cookie's value from the cookie dict.
    proc fetch {cookies args} {
	Debug.cookies {Cookie fetch $cookies $args}
	if {[llength $args] eq 1} {
	    set args [lindex $args 0]
	}

	set matches [match $cookies $args]
	if {[llength $matches] == 0} {
	    error "No matches: '$args'"
	}
	if {[llength $matches] != 1} {
	    error "Multiple matches: '$matches'"
	}

	return [dict get $cookies [lindex $matches 0]]
    }

    # fetch all matching cookie's values from the cookie dict.
    proc fetchAll {cookies args} {
	Debug.cookies {Cookie fetch $cookies $args}
	if {[llength $args] eq 1} {
	    set args [lindex $args 0]
	}

	set result {}
	foreach n [match $cookies $args] {
	    lappend result $n [dict get $cookies $n]
	}
	return $result
    }

    # Request Dict API - same as lowercased procs, but operates on
    # cookie dict within request dict,
    proc Match {r args} {
	return [match [dict get $r -cookies] {*}$args]
    }
    proc Clear {r args} {
	dict set r -cookies [clear [dict get $r -cookies] {*}$args]
	return $r
    }
    proc Add {r args} {
	dict set r -cookies [add [dict get? $r -cookies] {*}$args]
	return $r
    }
    proc Remove {r args} {
	dict set r -cookies [remove [dict get $r -cookies] {*}$args]
	return $r
    }
    proc Modify {r args} {
	dict set r -cookies [modify [dict get $r -cookies] {*}$args]
	return $r
    }
    proc Fetch {r args} {
	return [fetch [dict get $r -cookies] {*}$args]
    }

    proc Fetch? {r args} {
	# try to find a matching cookie
	set cl [Cookies Match $r {*}$args]
	if {[llength $cl]} {
	    # we know they're human - they return cookies (?)
	    return [dict get [Cookies Fetch $r {*}$args] -value]
	} else {
	    return ""
	}
    }

    proc FetchAll {r args} {
	return [fetchAll [dict get $r -cookies] {*}$args]
    }

    namespace export -clear *
    namespace ensemble create -subcommands {}
}

if {[info exists argv0] && ($argv0 eq [info script])} {
    lappend auto_path [file dirname [info script]]
    if {[catch {package require Debug}]} {
	proc Debug.cookies {args} {
	}
    } else {
	Debug off cookies 10
    }

    # parsing cookies from a client
    foreach sc {
	{$Version="1"; Customer="WILE_E_COYOTE"; $Path="/acme"}
	{$Version="1"; Customer="WILE_E_COYOTE"; $Path="/acme"; Part_Number="Rocket_Launcher_0001"; $Path="/acme"}
	{$Version="1"; Customer="WILE_E_COYOTE"; $Path="/acme"; Part_Number="Rocket_Launcher_0001"; $Path="/acme"; Shipping="FedEx"; $Path="/acme"}
	{$Version="1"; Part_Number="Riding_Rocket_0023"; $Path="/acme/ammo"; Part_Number="Rocket_Launcher_0001"; $Path="/acme"}} {
	set cd [Cookies parse4server $sc]
	puts "$sc -> ($cd) -> [Cookies format4server $cd] + [Cookies format4client $cd]"
    }

    # parsing cookies from a server
    foreach sc {
	{Customer="WILE_E_COYOTE"; Version="1"; Path="/acme"}
	{Part_Number="Rocket_Launcher_0001"; Version="1"; Path="/acme"}
	{Shipping="FedEx"; Version="1"; Path="/acme"}
	{Part_Number="Rocket_Launcher_0001"; Version="1"; Path="/acme"}
	{Part_Number="Riding_Rocket_0023"; Version="1"; Path="/acme/ammo"}
    } {
	set cd [Cookies parse4client $sc]
	puts "$sc -> ($cd) -> [Cookies format4server $cd] + [Cookies format4client $cd]"
    }

    # direct access tests - there should be more of these :)
    set x [dict create]
    foreach sc {
	{Customer WILE_E_COYOTE -path /acme}
	{Part_Number Rocket_Launcher_0001 -path /acme}
	{Shipping FedEx -path /acme}
    } {
	set attrs [lassign $sc name val]
	set x [Cookies add $x -name $name -value $val {*}$attrs]
    }
}

# Here's the relevant syntax from rfc2109

# Set-Cookie: has the following syntax
#
# av-pairs = av-pair *(";" av-pair)
# av-pair = attr ["=" value]              ; optional value
# attr = token
# value = token | quoted-string
#
#   set-cookie      =       "Set-Cookie:" cookies
#   cookies         =       1#cookie
#   cookie          =       NAME "=" VALUE *(";" cookie-av)
#   NAME            =       attr
#   VALUE           =       value
#   cookie-av       =       "Comment" "=" value
#                   |       "Domain" "=" value
#                   |       "Max-Age" "=" value
#                   |       "Path" "=" value
#                   |       "Secure"
#                   |       "Version" "=" 1*DIGIT

# Cookie: has the following syntax:
#
# cookie          =  "Cookie:" cookie-version 1*((";" | ",") cookie-value)
# cookie-value    =  NAME "=" VALUE [";" path] [";" domain] [";" port]
# cookie-version  =  "$Version" "=" value
# NAME            =  attr
# VALUE           =  value
# path            =  "$Path" "=" value
# domain          =  "$Domain" "=" value
