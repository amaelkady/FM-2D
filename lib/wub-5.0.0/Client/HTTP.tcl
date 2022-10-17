# HTTP 1.1 client

set MODULE(HTTP) {
    {
	HTTP constructs a connection to a host and initiates a series of HTTP 1.1 requests, it supports HTTP methods [[get]] [[put]] [[post]] [[delete]], and a [[close]] method for terminating the connection.

	Server responses are sent to the consumer in the form: [[list RESPONSE response]] where response is a response dictionary containing the originally requested url in X-url, and object sending the response in X-object, and an X-type of RESPONSE.  The actual response content may be found as [[dict get $response -content]].

	If the configuration variable ''justcontent'' is true, then server responses to the consumer consist of only the received entity, that is the content, of the response.  So a consumer will get the HTML of a page, for example.  This is ok if you know your request isn't going to fail.

	== Opening an HTTP Connection ==
	[[HTTP new $url $consumer ...]] is the general form of connection construction.  An HTTP connection ''must'' be constructed with at least a URL (to get) and a Consumer (to send responses to.)  As soon as the HTTP object comes into being, it sends all the requests its constructor has been given.

	Additional arguments to the constructor may be of the form:

	;get/put/post/delete {$url ...}: which queues up a protocol request in the pipeline, to be sent to the host in order.  Additional arguments are treated as HTTP protocol elements, and added to the request dict as it's sent.  Careful now.
	;var value: configuration variables (see Configuration, below)

	== Sending Requests on an HTTP Connection ==

	Requests may be sent in the form: [[$object ''op'' $url]] where ''op'' is one of [[get]], [[put]]. [[post]], [[delete]].  The url must have the same host and port as the HTTP connection was created with, and in fact can be shortened to omit the leading 'http://' and host information.

	=== Request Queries ===
	Queries are simply formed into the requested url.  [Wub]'s [Query] and [Url] packages may be of use in this, to construct properly formatted URLs and URL queries.

	=== Request Entities ===
	Entities, if any, can be sent as follows: [[$object post $url $entity]].  If you wish to indicate other information about the entity, it can be included thus: [[$object post $url $entity content-type text/html]] for example.

	The request will be formatted and sent to the host server, and its response indicated to the consumer.
	
	== HTTP Connection Termination ==
	If the configuration variable ''notify'' is true, then termination of the connection calls that script with a response dict containing the X-type CLOSED indication and an X-reason containing the reason for closure, otherwise the consumer receives that dict.   A consumer managing multiple connections may use the X-object element to associate responses with connections.

	The [[close]] method requests that the object destroy itself and close the connection after all outstanding responses are collected and have been forwarded as responses.

	An eof on the socket destroys the object immediately after sending a CLOSED indication to the consumer.  By the time the consumer receives the CLOSED indication, the HTTP object has probably already been destroyed.

	[[$object destroy]] will also immediately close HTTP connections.

	== Examples ==
	[[HTTP new $consumer get http://somewhere.com/something get http://somewhere.com/somethingelse ...]]
	[[http://somewhere.com $consumer get http://somewhere.com/somethingelse]] -- equivalent

	== Limitations ==

	=== Protocol Incompatibilities ===
	TBD: The HTTP1.1 protocol requires that a pipeline (of queued requests) be stalled until the response to a PUT or POST request has been received.  This version of HTTP doesn't do that, but later versions will.

	=== Redirections ===
	Servers may response with redirection response codes, indicating that the requested resource is located elsewhere.  This may necessitate a new connection be opened, perhaps to a different host.  The HTTP package doesn't attempt to follow redirections, reasoning that the consumer is in a better position to know what it wants.

	=== Cookies ===
	Cookies are received, and may be parsed with the [Wub] [Cookies] module, but are not further processed by HTTP.

	=== Caching ===
	No attempt is made to cache or to understand caching instructions.

	== ToDo ==
	Track [[rename]]s of the object command - this will impact on [[fileevent]] ... it's not safe to rename the object.
    }
    {consumer "A script prefix to consume responses from the connection"}
    {notify "Script called with notification of completion (default: none)"}
    {justcontent "boolean: the consumer just wants the content (default: no)"}
}

package require Tcl 8.6	;# minimum version of tcl required
package require TclOO
namespace import oo::*

# use the new coro functionality
namespace eval tcl::unsupported namespace export yieldm
namespace import tcl::unsupported::yieldm

# import the relevant commands from WubUtils package
if {[catch {package require WubUtils}]} {
    proc corovars {args} {
	foreach n $args {lappend v $n $n}
	uplevel 1 [list upvar #1 {*}$v]
    }
}

# import the relevant commands from Wub Http package
if {[catch {package require Http}]} {
    namespace eval ::Http {}
    # return an HTTP date
    proc ::Http::Date {{seconds ""}} {
	if {$seconds eq ""} {
	    set seconds [clock seconds]
	}

	return [clock format $seconds -format {%a, %d %b %Y %T GMT} -gmt true]
    }
}

# import the relevant commands from Wub Url package
if {[catch {package require Url}]} {
    namespace eval ::Url {
	# subset the Url package for stand-alone use
	proc url {args} {
	    if {[llength $args] == 1} {
		set args [lindex $args 0]
	    }
	    # minimize -port
	    if {[dict exists $args -port]
		&& ([dict get $args -port] eq "" || [dict get $args -port] eq "80")} {
		dict unset args -port
	    }
	    
	    foreach {part pre post} {
		-scheme "" :
		-host // ""
		-port : ""
		-path "" ""
	    } {
		if {[dict exists $args $part]} {
		    append result "${pre}[dict get $args $part]${post}"
		}
	    }
	    return $result
	}
	proc uri {x args} {
	    set result [url $x]

	    foreach {part pre post} {
		-query ? ""
		-fragment \# ""
	    } {
		if {[dict exists $x $part]} {
		    append result "${pre}[dict get $x $part]${post}"
		}
	    }
	    return $result
	}
	proc normalize {url} {
	    while {[set new [regsub -all {(/+)|(^[.][.]/)|(^/[.][.])|(/[^/]+/[.][.]$)|(/[^/]+/[.][.]/)|(^[.]/)|(/[.]$)|(/[.]/)|(^[.][.]$)|(^[.]$)} $url /]] ne $url} {
		set url $new
	    }
	    return "/[string trimleft $url /]"
	}
	proc parse {url {normalize 1}} {
	    array set x {}
	    regexp {^(([^:/?\#]+):)?(//([^/?\#]*))?([^?\#]*)([?]([^\#]*))?(\#(.*))?$} $url \
		-> . x(-scheme) . x(-authority) x(-path) . x(-query) . x(-fragment)
	    regexp {^(([^@]+)@)?([^@:]+)?(:([0-9]+))?$} $x(-authority) \
		-> . x(-authority) x(-host) . x(-port)

	    if {$normalize} {
		set x(-path) [normalize $x(-path)]	;# fix up oddities in URLs
	    }
	    
	    foreach n [array names x] {
		if {$x($n) eq ""} {
		    unset x($n)
		}
	    }
	    if {[info exists x(-scheme)]} {
		set x(-url) [url [array get x]]
	    }
	    return [array get x]
	}
	
	# construct the host part of a URL dict
	proc host {x} {
	    if {[dict exists $x -port]
		&& [dict get $x -port] ne {}
		&& [dict get $x -port] != 80} {
		return "[dict get $x -host]:[dict get $x -port]"
	    } else {
		return "[dict get $x -host]"
	    }
	}

	proc http {x args} {
	    set result ""
	    foreach {part pre post} {
		-path "" ""
		-fragment \# ""
		-query ? ""
	    } {
		if {[dict exists $x $part]} {
		    append result "${pre}[dict get $x $part]${post}"
		}
	    }
	    return $result
	}
	
	namespace export -clear *
	namespace ensemble create -subcommands {}
    }
}

if {[catch {package require Debug}]} {
    proc Debug.HTTP {args} {}
    #proc Debug.HTTP {args} {puts stderr HTTP@[uplevel subst $args]}
    proc Debug.HTTPdetail {args} {}
    #proc Debug.HTTPdetail {args} {puts stderr HTTPdetail@[uplevel subst $args]}
} else {
    Debug off HTTP 10
    Debug off HTTPdetail 10
}

# this enables urls to be commands.
if {[catch {package require know}]} {
    proc know {cond body} {
	if {![info complete $body]} {error "incomplete command(s) $body"}
	proc ::unknown {args} [string map [list @c@ $cond @b@ $body] {
	    if {![catch {expr {@c@}} res eo] && $res} {
		return [eval {@b@}]
	    }
	}][info body ::unknown]
    } ;# RS
}

# this parses the URL into a host part and a 'get $path' part.
know {[string match http://* [lindex $args 0]]} {
    # parse the URL
    set urld [Url parse [lindex $args 0]]
    Debug.HTTPdetail {parsed URL: $urld}
    set host [Url host $urld]
    set path [Url http $urld]
    if {[dict exists $urld -fragment]} {
	dict unset urld -fragment	;# we don't pass fragments
    }
    if {$path ne ""} {
	set path [list get $path]	;# make a 'get' op for path remainder
    }

    HTTP new [Url uri $urld] [lindex $args 1] $path	;# close close
}

package provide HTTP 2.0

class create HTTP {
    # send - send an op HTTP request to the server
    method send {method url {entity ""} args} {
	corovars socket sent host http
	Debug.HTTP {send method:$method url:$url entity: [string length $entity] ($args)}

	set T [dict merge $http $args [list -scheme http -port $port -host $host] [Url parse $url]]
	set T [dict merge $T [list -method $method date [::Http::Date] host $host]]
	set requrl([incr txcount]) [Url uri $T]
	Debug.HTTP {T: ($T) #$txcount -> [Url http $T] -> [Url uri $T]}

	# format entity
	if {$entity ne ""} {
	    # encode entity body
	    dict set T content-length [string length $entity]
	} else {
	    unset entity
	}

	# format up header
	set request "[string toupper $method] [Url http $T] HTTP/1.1\r\n"

	dict for {n v} [dict filter $T key {[a-zA-Z]*}] {
	    if {[string length $v] > 100} {
		# break long lines into partial lines
		set sv {}
		while {[string length $v] > 100} {
		    lappend sv [string range $v 0 99]
		    set v [string range $v 100 end]
		}
		set v [join $sv "\r\n "]
	    }
	    append request "$n: $v\r\n"
	}
	append request "\r\n"	;# signal end of header
	chan puts -nonewline $socket $request
	Debug.HTTPdetail {Sent header: [string map {\r \\r \n \\n} $request]}

	if {[info exists entity]} {
	    # send the entity
	    chan puts -nonewline $socket $entity
	}
	incr outstanding
	chan event $socket readable [list [self] reader READ]

	Debug.HTTP {sent $method $url - $outstanding outstanding}
    }

    method parse {lines} {
	# we have a complete header - parse it.
	set r {}
	set last ""
	foreach line $lines {
	    if {[string index $line 0] in {" " "\t"}} {
		# continuation line
		dict append r $last " [string trim $line]"
	    } else {
		set value [join [lassign [split $line ":"] key] ":"]
		set key [string tolower [string trim $key "- \t"]]
		
		if {[dict exists $r $key]} {
		    dict append r $key ",$value"
		} else {
		    dict set r $key [string trim $value]
		}
	    }
	}
	return $r
    }

    method gets {} {
	corovars socket

	set line ""
	set gone [catch {chan eof $socket} eof]
	while {!$gone && !$eof
	       && [chan gets $socket line] != -1
	       && [chan blocked $socket]
	   } {
	    ::yieldm
	    set gone [catch {chan eof $socket} eof]
	}

	if {$gone || $eof} {
	    set reason "EOF reading HEADER"
	    Debug.HTTPdetail {gets: EOF reading HEADER}
	    [self] destroy
	} else {
	    Debug.HTTPdetail {gets: '$line' [chan blocked $socket] [chan eof $socket]}
	    return $line
	}
    }

    method read {{size -1}} {
	corovars socket
	Debug.HTTP {Reading $size}

	set chunk ""
	set gone [catch {chan eof $socket} eof]
	while {$size && !$gone && !$eof} {
	    ::yieldm	;# wait for read event
	    set chunklet [chan read $socket {*}[expr {$size>0?$size:""}]]	;# get some
	    append chunk $chunklet			;# remember it
	    incr size -[string length $chunklet]	;# how much left?
	    set gone [catch {chan eof $socket} eof]
	    Debug.HTTPdetail {Read chunk ($size left)}
	}

	if {$gone || $eof} {
	    set reason "EOF reading ENTITY"
	    return $chunk	;# can just EOF in entity
	} else {
	    # we have successfully read our chunk of $size
	    Debug.HTTPdetail {Read: '$chunk' of size $size}
	    return $chunk
	}
    }

    variable closing outstanding rqcount txcount reader writer consumer socket reason self spawn notify justcontent host port requrl

    destructor {
	Debug.HTTP {[self]: $socket closed because: $reason}

	# alert consumer
	set close [list X-type CLOSED X-count [incr rqcount] X-reason $reason]
	if {$notify ne ""} {
	    catch {after 1 {*}$notify $close}
	} else {
	    catch {after 1 {*}$consumer $close}
	}
	catch {chan close $socket}
    }

    constructor {url _consumer args} {
	Debug.HTTP {[self] construct $url $_consumer $args}

	set self [self]		;# for identifying responses
	set closing 0		;# signals EOF to both reader and writer
	set outstanding 0	;# counts outstanding packets
	set rqcount -1		;# counts received packets
	set reason "none given"	;# reason for closure
	set consumer $_consumer	;# who's consuming this?
	set template {accept */*}	;# http template
	set spawn 1		;# create a new instance for changed hosts (NYI)
	set notify ";#"		;# notify close to consumer?
	set justcontent 0	;# the consumer only wants content
	set sockopts {}

	if {[llength $args] == 1} {
	    set args [lindex $args 0]
	}
 
	set ops {}
	foreach {n v} $args {
	    if {$n in {get put post delete close}} {
		lappend ops $n $v
	    } else {
		set $n $v
	    }
	}

	# parse url into host,port
	set urld [Url parse $url]
	Debug.HTTPdetail {url dict: $urld}
	if {![dict exist $urld -host]} {
	    error "'$url' is not a properly formed URL"
	}
	set host [dict get $urld -host]
	if {[dict exists $urld -port]} {
	    set port [dict get $urld -port]
	} else {
	    if {[dict get $urld -scheme] ne "https"} {
		set port 80
	    } else {
		set port 443
	    }
	}

	# connect socket to host
	set socket ""
	if {[catch {
	    if {[dict get $urld -scheme] ne "https"} {
		socket -async {*}$sockopts $host $port	;# create the socket
	    } else {
		::tls::socket -async {*}$sockopts $host $port  ;# create SSL socket
	    }
	} socket eo] || [catch {
	    # condition the socket
	    chan configure $socket -blocking 0 -buffering none -encoding binary -translation {crlf binary}
	}]} {
	    set reason $socket
	    catch {after 1 [self] destroy}
	    return
	}

	# reader proc - the functional base of the read coroutine
	proc reader {args} {
	    Debug.HTTP {reader: $args}

	    # unpack all the passed-in args
	    dict with args {}
	    ::yieldm

	    variable self;
	    # keep receiving input resulting from our requests
	    set gone [catch {chan eof $socket} eof]
	    while {!$gone && !$eof} {
		set r {}	;# empty header
		# get whole header
		# keep a count of the number of packets received
		variable rqcount; set reqcount [incr rqcount]

		set headering 1; set bogus 0
		set lines {}
		while {$headering} {
		    set line [my gets]
		    Debug.HTTP {reader got line: ($line)}
		    if {[string trim $line] eq ""} {
			if {[llength $lines]} {
			    set headering 0
			}
		    } elseif {[string match <* [string trim $line]]} {
			set headering 0
			set bogus 1
		    } else {
			lappend lines $line
		    }
		}

		if {$bogus} {
		    # some sites (yes, ReCAPTCHA, you) don't even send headers
		    Debug.HTTP {This site is bogus, no header sent, just content}
		    set entity $line
		    while {![eof $socket]} {
			append entity \n [my gets]
		    }
		    dict set r -content $entity
		} else {
		    # got the header
		    set header [lindex $lines 0]
		    set r [my parse [lrange $lines 1 end]]	;# parse the header

		    # split out some interesting parts of the first header line
		    dict set r -message [join [lassign [split $header] version code]]
		    dict set r -version $version
		    dict set r -code $code
		    Debug.HTTP {reader header: $header ($r)}
		    
		    # now we have to fetch the entity (if any)
		    if {[dict exists $r content-length]} {
			set left [dict get $r content-length]
			set entity ""
			chan configure $socket -encoding binary -translation {binary binary}
			Debug.HTTP {reader getting entity of length ($left)}
			while {$left > 0} {
			    set chunk [my read $left]
			    incr left -[string length $chunk]
			    Debug.HTTP {reader getting remainder of entity of length ($left)}
			    dict append r -content $chunk
			}
			Debug.HTTP {reader got whole entity}
		    } elseif {[dict exists $r transfer-encoding]} {
			switch -- [dict get $r transfer-encoding] {
			    chunked {
				set chunksize 1
				while {$chunksize} {
				    chan configure $socket -encoding [encoding system] -translation {crlf binary}
				    set chunksize 0x[my gets]
				    chan configure $socket -encoding binary -translation {binary binary}
				    if {!$chunksize} {
					my gets
					Debug.HTTP {Chunks all done}
					break
				    }
				    set chunk [my read $chunksize]
				    my gets	;# get the closing \n
				    Debug.HTTP {Chunk: $chunksize ($chunk)}
				    dict append r -content $chunk
				}
			    }
			    default {
				error "Unknown transfer encoding"
			    }
			}
		    } elseif {[string toupper $version] eq "HTTP/1.0"} {
			dict set r -content [my read]
		    }
		}

		# reset to header config
		if {![chan eof $socket]} {
		    chan configure $socket -encoding [encoding system] -translation {crlf binary}
		}

		# check content-encoding and gunzip content if necessary
		if {[dict exists $r content-encoding]} {
		    switch -- [string tolower [dict get $r content-encoding]] {
			gzip {
			    set content [dict get $r -content]
			    dict set r -content [zlib gunzip $content]
			}
			default {}
		    }
		}

		# hand consumer the result
		variable consumer
		variable justcontent
		if {$justcontent} {
		    after 1 [list {*}$consumer [list [dict get $r -content]]]
		} else {
		    variable requrl
		    Debug.HTTPdetail {formatting up consumer message $reqcount}
		    dict set r X-url $requrl($reqcount)
		    dict set r X-count $rqcount
		    dict set r X-object $self
		    dict set r X-type RESPONSE
		    after 1 [list {*}$consumer $r]
		}

		# count the outstanding responses left
		# close if there are none
		variable outstanding
		incr outstanding -1
		Debug.HTTP {outstanding: $outstanding}

		variable closing
		if {[dict exists $r connection]
		    && [string tolower [dict get $r connection]] eq "close"
		} {
		    set outstanding 0
		    incr closing
		}

		if {$closing && !$outstanding} {
		    set reason "requested by WRITER"
		    $self destroy
		} elseif {!$outstanding} {
		    # nothing to read
		    chan event $socket readable {}
		}
		Debug.HTTP {reader: sent response, waiting for next}
		::yieldm
		set gone [catch {chan eof $socket} eof]
	    }
	    catch {chan close $socket}
	    $self destroy
	}

	# create reader coroutine
	set reader [self]::${socket}R
	coroutine $reader reader socket $socket
	objdefine [self] forward reader $reader	;# forward the method to the coro

	# writer proc - the functional basis of the writer coroutine
	proc writer {args} {
	    # writer - coro to send HTTP requests to a server
	    Debug.HTTP {writer: $args}
	    variable txcount -1

	    # unpack all the passed-in args
	    set ops {}
	    set http {}

	    foreach {var val} $args {
		if {[string tolower $var] in {get put post delete close}} {
		    # collect protocol operations
		    lappend ops [string tolower $var] $val
		} elseif {$var eq "ops"} {
		    lappend ops {*}$val
		} else {
		    set $var $val
		}
	    }
	    
	    # construct a request template
	    set http [dict merge $template $http]	;# http could have been passed in
	    dict set http User-Agent "TclHTTP/[package present HTTP]"
	    lappend http accept-encoding gzip
	    
	    variable closing; variable self

	    # send any ops we were passed
	    if {[info exists ops]} {
		Debug.HTTP {initial ops: $ops}
		foreach {op val} $ops {
		    if {$op eq "close"} {
			# we've been asked to close
			Debug.HTTP {closing upon request}
			variable reason "Requested by Consumer"
			proc writethis {args} {
			    error "The writer has been closed"
			}
			set closing 1
			return
		    } else {
			set entity [lassign $val url]
			my send $op $url {*}$entity
		    }
		}
	    }

	    variable closing; variable self
	    set retval ""
	    while {!$closing} {
		# unpack event
		if {[catch {
		    set args [lassign [::yieldm $self] op]; set retval ""
		} e eo]} {
		    Debug.HTTP {[info coroutine] yield: $e ($eo)}
		    return
		}
		
		set op [string tolower $op]
		Debug.HTTP {writer $op $args}
		if {$closing || $op eq "close"} {
		    Debug.HTTP {close: $op / $closing}
		    variable reason "Requested by Consumer"
		    proc writethis {args} {
			error "The writer has been closed"
		    }
		    set closing 1
		    return
		} elseif {$op in {get put post delete}} {
		    # got a protocol operator from consumer
		    set entity [lassign $args url]
		    my send $op $url {*}$entity
		}
	    }
	}

	# create writer coroutine
	set writer [self]::${socket}W 
	coroutine $writer writer socket $socket ops $ops template $template host $host
	objdefine [self] forward write [self]::writethis	;# forward the method to the coro

	# forward some methods for writing
	proc writethis {args} {
	    variable self
	    variable host
	    variable port
	    variable writer
	    if {[llength $args]} {
		set args [lassign $args op url]
		$writer $op $url {*}$args
		return $self
	    } else {
		return $writer
	    }
	}

	foreach v {get put post delete close} {
	    objdefine [self] forward $v [self]::writethis $v	;# forward the method to the coro
	}

	return $writer
    }
}

if {[info exists argv0] && ($argv0 eq [info script])} {
    catch {Debug on HTTP 10}
    proc echo {arg} {
	puts "ECHO: $arg"
	lassign $arg op
	if {$op eq "CLOSED"} {
	    global done
	    #set done 1
	}
    }

    http://1023.1024.1025.0126:8080/ echo	;# a bad url
    set obj [http://localhost:8080/wub/ echo get /]	;# get a couple of URLs
    http://www.google.com.au/ echo justcontent 1	;# just get the content, not the dict
    puts $obj
    $obj get /wub/?A=1&B=2 echo
    $obj get http://localhost:8080/ echo

    set fd [open [info script]]; set source [read $fd]; close $fd
    if {![catch {zlib adler32 $source} crc]} {
	if {![catch {package require fileutil}]} {
	    http://wub.googlecode.com/svn/trunk/Client/HTTP.tcl	{set ::source} justcontent 1	;# fetch the latest HTTP.tcl
	}
    }

    vwait ::source
    set source [subst -nocommands -novariables $source]
    puts stderr "Fetched [string length $source] bytes of source for HTTP.tcl"
    if {![catch {zlib adler32 $source} crc2]} {
	if {$crc ne $crc2} {
	    puts stderr "There seems to be a newer version of HTTP.tcl"
	    if {[lsearch $argv -autoupdate] != -1} {
		puts stderr "Auto-updating HTTP.tcl in-place"
		set this [info script]
		if {![catch {fileutil::writeFile -- $this.new $source} e eo]} {
		    file rename -force $this $this.bak
		    file rename -force $this.new $this
		} else {
		    puts stderr "writing $this failed: $e ($eo)"
		}
	    }
	} else {
	    puts stderr "You seem to have the most current version of HTTP.tcl"
	}
    }
}
