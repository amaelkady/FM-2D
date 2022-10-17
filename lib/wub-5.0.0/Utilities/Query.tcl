# Query - handle URL/HTTP query strings
if {[info exists argv0] && ([info script] eq $argv0)} {
    lappend auto_path [file dirname [file normalize [info script]]]
}

package require Debug
Debug define query 10
package require mime
package require base64

package provide Query 2.0

set ::API(Utilities/Query) {
    {
	Query - parse and manipulate HTML query strings
    }
}

namespace eval ::Query {
    variable todisk 10000000
    variable utf8 [expr {[catch {package require utf8}] == 0}]

    variable map
    variable dmap

    # Support for x-www-urlencoded character mapping
    # The spec says: "non-alphanumeric characters are replaced by '%HH'"

    set dmap {%0D%0A \n %0d%0a \n %% %}
    lappend dmap + " "
    set map {% %% = = & & - -}

    # set up non-alpha map
    for {set i 0} {$i < 256} {incr i} {
	set c [format %c $i]
	if {![string match {[a-zA-Z0-9]} $c]} {
	    if {![dict exists $map $c]} {
		lappend map $c %[format %.2X $i]
	    }
	}
	# must be able to decode any %-form, however stupid
	lappend dmap %[format %.2X $i] [binary format c $i]
	lappend dmap %[format %.2x $i] [binary format c $i]
    }

    # These are handled specially
    lappend map " " + \n %0D%0A
    #puts stderr "QUERY dmap: $dmap"
    #puts stderr "QUERY map: $map"

    proc 2hex {str} {
	binary scan $str H* hex
	return $hex
    }

    # decode
    #
    #	This decodes data in www-url-encoded format.
    #
    # Arguments:
    #	An encoded value
    #
    # Results:
    #	The decoded value
    
    proc decode {str} {
	Debug.query {decode '$str'} 10
	variable dmap
	set str [string map $dmap $str]
#	set str [encoding convertfrom utf-8 $str]
	Debug.query {decode dmap '$str' [2hex $str]} 10

	return $str
    }

    # encode
    #
    #	This encodes data in www-url-encoded format.
    #
    # Arguments:
    #	A string
    #
    # Results:
    #	The encoded value

    proc encode {string} {
	variable map
	# map non-ascii characters away - note: % must be first
	Debug.query {encode '$string'}
	set string [string map $map $string]
	Debug.query {encode post '$string'}
	return $string
    }

    # encode args as a www-url-encoded entity
    proc encodeL {args} {
	if {[llength $args] == 1} {
	    set args [lindex $args 0]
	}
	set entity {}
	foreach {n v} $args {
	    lappend entity "$n=[Query encode $v]"
	}
	return [join $entity &]
    }

    # build
    #
    #	This encodes a dict in www-url-encoded format.
    #
    # Arguments:
    #	a list of name, value pairs
    #
    # Results:
    #	The encoded value

    proc build {args} {
	if {[llength $args] == 1} {
	    set args [lindex $args 0]
	}
	set pairs {}
	foreach {n v} $args {
	    lappend pairs "[encode $n]=[encode $v]"
	}
	return [join $pairs &]
    }

    # qparse -- internal parser support
    #
    #	decodes a query string
    #	
    # Arguments:
    #	qstring	a string containing a query
    #	ct	the content type
    #
    # Results:
    #	A dictionary of names and values from the query
    #	The form of the dict is {name {{value {metadata}}  ... }}
    #
    # Side Effects:

    proc qparse {qstring count {ct "NONE"}} {
	Debug.query {qparse $ct - [string range $qstring 0 80]...}
	switch -glob -- [lindex [split $ct \;] 0] {
	    text/html -
	    text/xml -
	    application/xml -
	    application/x-www-form-urlencoded -
	    application/x-www-urlencoded -
	    application/x-url-encoded -
	    NONE {
		set query [dict create]
		foreach {x} [split [string trim $qstring] &] {
		    # Turns out you might not get an = sign,
		    # especially with <isindex> forms.
		    set z [split $x =]
		    if {[llength $z] == 1} {
			# var present without assignment
			set var [decode [lindex $z 0]]
			set val ""
			set meta [list -unassigned 1 -count [incr count]]
		    } else {
			# var present with assignment
			set var [decode [lindex $z 0]]
			set val [decode [join [lrange $z 1 end] =]]
			set meta [list -count [incr count]]
		    }
		    
		    dict lappend query $var $val $meta
		    # todo - not quite right - this doesn't allow duplicate
		    # var=val, but should
		}
	    }

	    default {
		error "Unknown Content-Type: $ct"
	    }
	}
	
	set query [charset $query]
	return [list $query $count]
    }

    # cconvert - convert charset to appropriate encoding
    # - try to ensure the correctness of utf-8 input
    proc cconvert {query charset} {
	if {$charset eq ""} {
	    set charset utf-8
	} else {
	    set charset [string tolower $charset]
	}
	Debug.query {cconvert charset '$charset'} 6
	variable encodings
	if {$charset in [encoding names]} {
	    # tcl knows of this encoding - so make the conversion
	    variable utf8
	    dict for {k v} $query {
		set vals {}
		foreach {val meta} $v {
		    if {$utf8 && $charset eq "utf-8"} {
			# check the content for utf8 correctness
			set point [::utf8::findbad $v]
			if {$point < [string length $v] - 1} {
			    if {$point >= 0} {
				incr point
				lappend meta -bad $point
			    }
			    lappend vals $val $meta
			    Debug.query {cconvert charset '$charset' - bad at $point} 6
			    continue
			}
		    }

		    set v1 [encoding convertfrom $charset $val]
		    Debug.query {cconvert charset '$charset' '$val'->'$v1'} 6
		    lappend vals $v1 $meta
		}
		Debug.query {cconverted $k -> ($vals)} 10
		dict set query $k $vals
	    }
	}

	return $query
    }

    # charset - handle '_charset_' hack
    # see https://bugzilla.mozilla.org/show_bug.cgi?id=18643
    proc charset {query} {
	Debug.query {charset [dict get? $query _charset_]}
	if {![exists $query _charset_]} {
	    # no conversion necessary
	    return $query
	}
	set query [cconvert $query [value $query _charset_]]
	dict unset query _charset_
	
	return $query
    }

    proc components {token} {
	set components [list token $token]
	foreach p [::mime::getproperty $token -names] {
	    dict set components $p [::mime::getproperty $token $p]
	}

	foreach p [::mime::getheader $token -names] {
	    dict set components headers $p [::mime::getheader $token $p]
	}
	Debug.query {Components $token: ($components)}
	if {[dict exists $components size] && [dict get $components size] < 100000} {
	    dict set components body [::mime::getbody $token -decode]
	} else {
	    set body [file tempfile path]
	    dict set components path $path
	    dict set components fd $body
	    dict set ::Httpd::files [info coroutine] $body	;# keep a copy
	    Debug.query {Components BODY $token: $path}
	    ::mime::copymessage $token $body	;# make a copy in the given file.
	}

	if {[dict exists $components parts]} {
	    # recurse over parts
	    set parts [dict get $components parts]; dict unset components parts
	    foreach p [dict get $components $parts] {
		dict set components parts $p [components $token]
		dict set components parts $p token $token
	    }
	}
	Debug.query {Components Full $token: ($components)}
	
	return $components
    }

    # parse -- parse an http dict's queries
    #
    #	decodes the -query and -entity elements of an httpd dict
    #	
    # Arguments:
    #	http	dict containing an HTTP request
    #
    # Results:
    #	A dictionary of names associated with a list of 
    #	values from the request's query part and entity body
    
    proc parse {r} {
	if {[dict exists $r -Query]} {
	    return [dict get $r -Query]
	}

	if {[dict exists $r -query]} {
	    # parse the query part normally
	    Debug.query {parsing query part ([dict get $r -query])}
	    lassign [qparse [dict get $r -query] 0] query count
	} else {
	    set query {}
	    set count 0
	}
    
	if {[dict exists $r -entity]
	    || [dict exists $r -entitypath]
	} {
	    # there is an entity body
	    set ct [dict get $r content-type]
	    Debug.query {parsing entity part of type '$ct'}
		    
	    switch -glob -- [dict exists $r -entitypath],[dict exists $r -entity],[lindex [split $ct \;] 0] {
		0,1,multipart/* {
		    lassign [multipart $ct [dict get $r -entity] $count] query count
		}
		1,1,multipart/* {
		    lassign [multipartF $ct [dict get $r -entitypath] [dict get $r -entity] $count] query count
		}

		default {
		    # this entity is in memory - use the quick stuff to parse it
		    lassign [qparse [dict get $r -entity] $count $ct] query count
		    Debug.query {qparsed [string range $query1 0 80]...}
		}
	    }
	}

	return $query
    }

    # dump query dict
    proc dump {qd} {
	set result {}
	foreach name [dict keys $qd] {
	    lappend result [list $name [string range [value $qd $name] 0 80] [metadata $qd $name]]
	}
	return $result
    }

    # numvalues -- how many values does a named element have?
    #
    # Arguments:
    #	query	query dict generated by parse
    #	el	element name
    #
    # Results:
    #	number of values associated with query
    
    proc numvalues {query el} {
	return [expr {[llength [dict get $query $el]] / 2}]
    }

    # value -- return the nth value associated with a name in a query
    #
    # Arguments:
    #	query	query dict generated by parse
    #	el	name of element
    #	num	index of value
    #
    # Results:
    #	num'th value associated with el by query
    
    proc value {query el {num 0}} {
	return [lindex [dict get $query $el] [expr {$num * 2}]]
    }

    proc qvars {query args} {
	foreach var $args {
	    upvar 1 $var _$var
	    set _$var [value $query $var]
	}
    }

    # add - add a simulated query element
    # query - query dict generated by parse
    # el - name of element
    # val - value of element
    # metadata - metadata
    proc add {query el val {metadata {}}} {
	dict lappend query $el $val $metadata
	return $query
    }

    # metadata -- return the nth metadata associated with a name in a query
    #
    # Arguments:
    #	query	query dict generated by parse
    #	el	name of element
    #	num	index of value
    #
    # Results:
    #	num'th metadata associated with el by query
    
    proc metadata {query el {num 0}} {
	return [lindex [dict get $query $el] [expr {$num * 2 + 1}]]
    }

    # if this is a file, return its characteristics
    proc file? {query el {num 0}} {
	set md [metadata $query $el $num]
	if {![dict exists $md -path]} {
	    return {}
	} else {
	    return [dict in $md -path -fd -start -size]
	}
    }

    proc copydone {to md bytes {error ""}} {
	if {$bytes != [dict get $md -size]
	    || $error ne ""
	} {
	    if {$error eq ""} {
		set error "[$bytes bytes copied, [dict get $md -size] expected."
	    }
	    Debug.error {"Query copy error to '$to': $error ($md)"}
	}
	catch {file close $to}
    }

    # if this is a file, copy its content to a stream
    proc copy {fd callback query el {num 0}} {
	if {$callback eq ""} {
	    set callback {Query copydone}
	}
	set md [metadata $query $el $num]
	if {![dict exists $md -path]} {
	    return 0
	} else {
	    set md [dict in $md -path -fd -start -size]
	    dict with md {
		chan seek ${-fd} ${-start}
		chan copy ${-fd} $fd ${-size} -command [list {*}$callback $fd $md]
	    }
	    return 1
	}
    }

    proc copytmp {file callback query el {num 0}} {
	set fd [file tempfile path]
	set result [copy $fd $callback $query $el $num]
	if {$result} {
	    return [list $fd $path]
	} else {
	    return {}
	}
    }

    # exists -- does a value with the given name exist
    #
    # Arguments:
    #	query	query dict generated by parse
    #	el	name of element
    #	num	number of element's values
    #
    # Results:
    #	true if el is in query
    
    proc exists {query el {num 0}} {
	if {$num == 0} {
	    return [dict exists $query $el]
	} else {
	    return [expr {
			  [dict exists $query $el]
			  && ([llength [dict get $query $el]] > ($num*3))
		      }]
	}
    }

    # return a name, value, meta list from the query dict
    proc nvmlist {query} {
	set result {}
	dict for {n v} $query {
	    foreach {val meta} $v {
		lappend result $n $val $meta
	    }
	}
	return $result
    }
    
    # values -- return the list of values associated with a name in a query
    #
    # Arguments:
    #	query	query dict generated by parse
    #	el	name of element
    #
    # Results:
    #	list of values associated with el by query
    
    proc values {query el} {
	set result {}
	foreach {v m} [dict get $query $el] {
	    lappend result $v
	}
	return $result
    }

    # vars -- the list of names in the query
    #
    # Arguments:
    #	query	query dict generated by parse
    #
    # Results:
    #	list of values associated with el by query
    
    proc vars {query} {
	return [dict keys $query]
    }

    # flatten -- flatten query ignoring multiple values and metadata
    #
    #	construct a list able to be flattened into an array
    #
    # Arguments:
    #	query	query dict generated by parse
    #
    # Results:
    #	list of values associated with el by query
    #	multiple values are stored with ,$index as a name suffix
    
    proc flatten {query} {
	set result {}
	dict for {n v} $query {
	    set count 0
	    foreach {val meta} $v {
		if {$count} {
		    lappend result $n,$count $val
		} else {
		    lappend result $n $val
		}
		incr count
	    }
	}
	return $result
    }

    # for compatibility with ncgi.
    proc nvlist {query} {
	return [flatten $query]
    }

    # parseMimeValue
    #
    #	Parse a MIME header value, which has the form
    #	value; param=value; param2="value2"; param3='value3'
    #
    # Arguments:
    #	value	The mime header value.  This does not include the mime
    #		header field name, but everything after it.
    #
    # Results:
    #	A two-element list, the first is the primary value,
    #	the second is in turn a name-value list corresponding to the
    #	parameters.  Given the above example, the return value is
    #	{
    #		value
    #		{param value param2 value param3 value3}
    #	}
    
    proc parseMimeValue {value} {
	set parts [split $value \;]
	set results [list [string trim [lindex $parts 0]]]
	
	set paramList {}
	foreach sub [lrange $parts 1 end] {
	    if {[regexp -- {([^=]+)=(.+)} $sub match key val]} {
		set key [string trim [string tolower $key]]
		set val [string trim $val]
		
		# Allow single as well as double quotes
		if {[regexp -- {^[\"']} $val quote]} {
		    # need a quote for balance
		    if {[regexp -- ^${quote}(\[^$quote\]*)$quote $val x val2]} {
			# Trim quotes and any extra crap after close quote
			set val $val2
		    }
		}
		lappend paramList $key $val
		Debug.query {parseMimeValue $key: '[string range $val 0 80]...'}
	    }
	}
	
	if {[llength $paramList]} {
	    lappend results $paramList
	}
	
	return $results
    }

    # pconvert - convert part's charset to appropriate encoding
    # - try to ensure the correctness of utf-8 input
    proc pconvert {charset content} {
	Debug.query {pconvert '$charset'} 6
	if {$charset eq ""} {
	    return $content
	}

	if {$charset ni [encoding names]} {
	    Debug.error {Query pconvert doesn't know how to convert '$charset'}
	    return $content
	}
    
	# tcl knows of this encoding - so make the conversion
	variable utf8
	if {$utf8 && $charset eq "utf-8"} {
	    # check the content for utf8 correctness
	    set point [::utf8::findbad $content]
	    if {$point < [string length $v] - 1} {
		if {$point >= 0} {
		    incr point
		    lappend meta -bad $point
		}
		lappend vals $val $meta
		continue
	    }
	}
	Debug.query {pconvert '$charset'}
	return [encoding convertfrom $charset $content]
    }

    # multipart
    #
    #	This parses multipart form data.
    #	Based on work by Steve Ball for TclHttpd
    #
    # Arguments:
    #	type	The Content-Type, because we need boundary options
    #	query	The raw multipart query data
    #
    # Results:
    #	An alternating list of names and values
    #	In this case, the value is a two element list:
    #		content, which is the main value of the element
    #		headers, which in turn is a list names and values
    #	The header name/value pairs come primarily from the MIME headers
    #	like Content-Type that appear in each part.  However, the
    #	Content-Disposition header is handled specially.  It has several
    #	parameters like "name" and "filename" that are important, so they
    #	are promoted to to the same level as Content-Type.  Otherwise,
    #	if a header like Content-Type has parameters, they appear as a list
    #	after the primary value of the header.  For example, if the
    #	part has these two headers:
    #
    #	Content-Disposition: form-data; name="Foo"; filename="/a/b/C.txt"
    #	Content-Type: text/html; charset="iso-8859-1"; mumble='extra'
    #	
    #	Then the header list will have this structure:
    #	{
    #		content-disposition form-data
    #		name Foo
    #		filename /a/b/C.txt
    #		content-type {text/html {charset iso-8859-1 mumble extra}}
    #	}
    #	Note that the header names are mapped to all lowercase.  You can
    #	use "array set" on the header list to easily find things like the
    #	filename or content-type.  You should always use [lindex $value 0]
    #	to account for values that have parameters, like the content-type
    #	example above.  Finally, not that if the value has a second element,
    #	which are the parameters, you can "array set" that as well.
    
    proc multipart {type query {count -1}} {
	set parsedType [parseMimeValue $type]
	if {![string match multipart/* [lindex $parsedType 0]]} {
	    error "Not a multipart Content-Type: [lindex $parsedType 0]"
	}

	Debug.query {multipart parsed Mime Values $type '$parsedType'}
	#puts stderr "PARTS: $query"
	array set options [lindex $parsedType 1]
	if {![info exists options(boundary)]} {
	    error "No boundary given for multipart document"
	}
	set boundary $options(boundary)

	Debug.query {multipart options $type '[array get options]'}
	
	# The query data is typically read in binary mode, which preserves
	# the \r\n sequence from a Windows-based browser.
	# Also, binary data may contain \r\n sequences.
	
	if {[string match "*$boundary\r\n*" $query]} {
	    set lineDelim "\r\n"
	    # puts "DELIM"
	} else {
	    set lineDelim "\n"
	    # puts "NO"
	}
	
	# Iterate over the boundary string and chop into parts
	
	set len [string length $query]

	# [string length $lineDelim]+2 is for "$lineDelim--"
	set blen [expr {[string length $lineDelim] + 2 + [string length $boundary]}]
	set first 1
	set results [dict create]

	# Ensuring the query data starts
	# with a newline makes the string first test simpler
	if {[string first $lineDelim $query 0] != 0} {
	    set query $lineDelim$query
	}
	
	set offset 0
	set charset ""	;# charset encoding of part
	set te ""	;# transfer encoding of part

	while {[set offset [string first "$lineDelim--$boundary" $query $offset]] >= 0} {
	    # offset is the position of the next boundary string
	    # in $query after $offset
	    
	    Debug.query {multipart found offset:$offset/[string length $query]}
	    if {$first} {
		set first 0	;# this was the opening delimiter
	    } else {
		# this was the delimiter bounding current element
		# generate a n,v element from parsed content
		set content [string range $query $off2 [expr {$offset -1}]]

		Debug.query {encodings te:$te charset:$charset}
		# decode transfer encoding
		switch -- $te {
		    quoted-printable {
			set content [::mime::qp_decode $content]
		    }
		    base64 {
			set content [::base64::decode]
		    }
		    7bit - 8bit - binary - "" {}
		    default {
			Debug.error {Query multipart can't handle TE '$te'}
		    }
		}

		# decode charset encoding
		if {$charset ne ""} {
		    Debug.query {pconverting: $formName '$charset'}
		    set content [pconvert $charset $content]
		}
		dict lappend results $formName $content $headers
	    }
	    incr offset $blen	;# skip boundary in stream
	    
	    # Check for the terminating entity boundary,
	    # which is signaled by --$boundary--
	    if {[string range $query $offset [expr {$offset + 1}]] eq "--"} {
		# end of parse
		Debug.query {multipart endparse offset:$offset/[string length $query]}
		break
	    }
	    
	    # We have a new element. Split headers out from content.
	    # The headers become a nested dict structure in result:
	    # {header-name { value { paramname paramvalue ... } } }
	    
	    # find off2, the offset of the delimiter which terminates
	    # the current element
	    set off2 [string first "$lineDelim$lineDelim" $query $offset]
	    Debug.query {multipart parsed between:$offset...$off2 /[string length $query]}
	    
	    # generate a dict called headers with element's headers and values
	    set headers [dict create -count [incr count]]
	    set formName ""	;# any header 'name' becomes the element name
	    set charset ""
	    set te ""
	    foreach line [split [string range $query $offset $off2] $lineDelim] {
		if {[regexp -- {([^:\t ]+):(.*)$} $line x hdrname value]} {
		    set hdrname [string tolower $hdrname]
		    # RFC2388: Field names originally in non-ASCII character sets may be encoded
		    # within the value of the "name" parameter using the standard method
		    # described in RFC 2047.
		    # encoded-word = "=?" charset "?" encoding "?" encoded-text "?="
		    # charset = token    ; see section 3
		    # encoding = token   ; see section 4
		    # We're not going to support that.

		    set valueList [parseMimeValue $value]
		    Debug.query {part header $hdrname: $valueList}
		    switch -- $hdrname {
			content-disposition {
			    # Promote Content-Disposition parameters up to headers,
			    # and look for the "name" that identifies the form element
			    dict set headers $hdrname [lindex $valueList 0]
			    foreach {n v} [lindex $valueList 1] {
				set n [string tolower $n]
				Debug.query {multipart content-disposition: $n '$v'}
				dict set headers $n $v
				if {$n eq "name"} {
				    set formName $v	;# the name of the element
				}
			    }
			}

			content-type {
			    # RFC2388: As with all multipart MIME types, each part has an optional
			    # "Content-Type", which defaults to text/plain.
			    set charset [string tolower [dict get? [lindex $valueList 1] charset]]
			    dict set headers $hdrname $valueList
			}

			content-transfer-encoding {
			    # RFC2388: The value supplied
			    # for a part may need to be encoded and the "content-transfer-encoding"
			    # header supplied if the value does not conform to the default
			    # encoding.  [See section 5 of RFC 2046 for more details.]
			    set te $valueList
			    dict set headers $hdrname $valueList
			}

			default {
			    Debug.query {multipart header: $hdrname '$valueList'}
			    set te $valuelist
			    dict set headers $hdrname $valueList
			}
		    }
		} elseif {$line ne ""} {
		    error "bogus field: '$line'"
		} else {
		    Debug.query {multipart headers last line}
		}
	    }
	    
	    # we have now ingested the part's headers
	    if {$off2 > 0} {
		# +[string length "$lineDelim$lineDelim"] for the
		# $lineDelim$lineDelim
		incr off2 [string length "$lineDelim$lineDelim"]
		set offset $off2
	    } else {
		break
	    }
	}
	
	Debug.query {headers: $results}
	return [list $results $count]
    }

    proc scanF {fd pattern} {
	chan seek $fd 0
	set bsize [chan configure $fd -buffersize]
	set psize [string length $pattern]
	if {$psize >= $bsize} {
	    error "pattern is longer than buffer"
	}

	chan configure $fd -blocking 0
	set result {0}
	set prior ""	;# previous buffer
	while {1} {
	    set next [chan read $fd $bsize]
	    set found [string first $pattern $prior$next]
	    if {$found < 0} {
		if {[chan eof $fd]} break
		#Debug.query {scanF not found at [chan tell $fd]}
		continue
	    } else {
		# got a match in buffer
		Debug.query {scanF found at $found from [chan tell $fd]}
		set got [expr {[chan tell $fd]-[string length $next]-[string length $prior]+$found}]
		lappend result $got [expr {$got + [string length $pattern]}]
		set prior [string range $next end-$psize end]
	    }
	}
	# compensate for 'terminating boundary' extra leading --
	lappend result [expr {[chan tell $fd]-[string length $pattern]-2}]
	
	return $result
    }

    proc multipartF {type path fd {count -1}} {
	set parsedType [parseMimeValue $type]
	if {![string match multipart/* [lindex $parsedType 0]]} {
	    error "Not a multipart Content-Type: [lindex $parsedType 0]"
	}

	Debug.query {multipartF parsed Mime Values type:'$type' options:'$parsedType'}
	array set options [lindex $parsedType 1]
	if {![info exists options(boundary)]} {
	    error "No boundary given for multipart document"
	}
	set boundary $options(boundary)

	Debug.query {multipartF options '[array get options]'}

	# Iterate over the file looking for boundary string and chop into parts
	set boundary --$boundary\r\n
	set boundaries [scanF $fd $boundary]
	Debug.query {boundaries: $boundaries}
	if {[llength $boundaries] < 2} {
	    error "multipart improperly formed"
	}

	set i -1
	set q {}
	foreach {start end} $boundaries {
	    set size [expr {$end-$start}]
	    if {$size} {
		chan seek $fd $start
		incr i
		Debug.query {bounded $i ($start..$end $size)}
		chan configure $fd -translation crlf
		set headers [list -count [incr count]]
		set formName "Part$i"	;# any header 'name' becomes the element name
		while {[gets $fd line] > 0
		       && [chan tell $fd] < $end
		   } {
		    Debug.query {LINE $i: '$line'}

		    # generate a dict called headers with element's headers and values
		    if {[regexp -- {([^:\t ]+):(.*)$} $line x hdrname value]} {
			set hdrname [string tolower $hdrname]
			# RFC2388: Field names originally in non-ASCII character sets may be encoded
			# within the value of the "name" parameter using the standard method
			# described in RFC 2047.
			# encoded-word = "=?" charset "?" encoding "?" encoded-text "?="
			# charset = token    ; see section 3
			# encoding = token   ; see section 4
			# We're not going to support that.

			set valueList [parseMimeValue $value]
			Debug.query {hdr: $hdrname ($valueList)}

			switch -- $hdrname {
			    content-disposition {
				# Promote Content-Disposition parameters up to headers,
				# and look for the "name" that identifies the form element
				dict lappend headers $hdrname [lindex $valueList 0]
				foreach {n v} [lindex $valueList 1] {
				    set n [string tolower $n]
				    Debug.query {multipart content-disposition: $n '$v'}
				    lappend headers $n $v
				    if {$n eq "name"} {
					set formName $v	;# the name of the element
				    }
				}
			    }

			    content-type {
				# RFC2388: As with all multipart MIME types, each part has an optional
				# "Content-Type", which defaults to text/plain.
				set charset [string tolower [dict get? [lindex $valueList 1] charset]]
				dict lappend headers $hdrname $valueList
			    }

			    content-transfer-encoding {
				# RFC2388: The value supplied
				# for a part may need to be encoded and the "content-transfer-encoding"
				# header supplied if the value does not conform to the default
				# encoding.  [See section 5 of RFC 2046 for more details.]
				set te $valueList
				dict lappend headers $hdrname $valueList
			    }

			    default {
				Debug.query {multipart header: $hdrname '$valueList'}
				set te $valuelist
				dict lappend headers $hdrname $valueList
			    }
			}
		    }
		}

		set csize [expr {$end - [chan tell $fd]-2}]	;# content size
		if {$csize > $::Httpd::todisk} {
		    set content {}
		    set headers [dict merge $headers [list -path $path -fd $fd -start $start -size $csize]]

		} else {
		    set content [chan read $fd $csize]
		}
		dict lappend q $formName $content $headers

		chan configure $fd -translation binary
	    }
	}

	Debug.query {multipartF Result: $q}

	return [list $q $count]
    }

    namespace export -clear *
    namespace ensemble create -subcommands {}
}

if {[info exists argv0] && ([info script] eq $argv0)} {
    foreach test {
	"error=User%20Doesn?error=User%20Doesn't%20Exist"
	"error=Passwords%20don't%20match"
	"error=first&error=second&error=third"
    } {
	lassign [Query qparse $test 0] query count
	puts stderr "'$test' -> ($query)"
	puts stderr "find error '[Query value $query error]'"
	
	set query [Query parse [dict create -query $test]]
	puts stderr "'$test' -> ($query)"
	puts stderr "find error '[Query value $query error]'"
	puts stderr "flattened: [Query flatten $query]"
    }

    # here's something I caught in the wild
    set q {N {8942 {}} cancel {Cancel {-count 4}} C {{This is a Work-in-progress translation (to Swedish) of the eleven syntactic rules of Tcl. (see [Endekalogue] for other translations). [Category Documentation] |} {-count 1 -bad 163}} O {{1182004521 lars_h@81.231.37.27} {-count 2}}}
    set metadata [Query metadata $q C]
    puts stderr "metadata: $metadata"
}
