# Listener
#
# Listener is a network server which listens for connection attempts and
# dispatches the connected socket to a handler
#
# This implementation dispatches to a pool of objects which
# interact at the protocol level, to provide a network service.
#
# NOTE: there's no need for the $socket [get] [connect] [Exhausted] interface - just a single [connect] which handles the rest.

if {[info exists argv0] && ($argv0 eq [info script])} {
    # test Listener
    lappend auto_path [pwd]
}

package require OO
package require Chan
package require WubUtils
package require Debug
Debug define listener 10
Debug define tls 10
package provide Listener 2.0

set ::API(Server/Listener) {
    {
	Listener is a network server which listens for connection attempts and dispatches the connected socket to a handler.

	== Handler Interface ==

	The protocol handler is a script (specified by -httpd argument, below) which is invoked as follows:

	''handler'' Connect $sock $ipaddr $rport args

	Where '''args''' consists of all the options passed to [Listen listener] when the Listener was created.

	== Creating a Listener ==

	A Listener is created by [[Listen listen]] which takes the following args:

	;-host: host name used in HTTP replies (default: [[info hostname]])
	;-myaddr: ip address to listen on (default: any)
	;-port: port upon which to listen (default ''8015'')
	;-httpd: a script prefix which invokes a handler of an incoming connection (default ''Httpd'')
	;-id: a unique identifier of this listener (default: ''system assigned'')
	;-tls: a list of args passed to tls::socket

	All of the arguments passed to [[Listen listen]] will be passed as args to the protocol handler ''Connect'' command.
	
	Some options bound for the protocol handler are important.  Notably ''-dispatch'' which is specifies the worker script for each request processed by the [Httpd] protocol stack.

	Generating SSL key is very easy, just use these two commands:
	    openssl genrsa -out server-private.pem 1024
	    openssl req -new -x509 -key server-private.pem -out server-public.pem -days 365
    }
}

class create ::Listener {
    # accept --
    #
    #	This is the socket accept callback invoked by Tcl when
    #	clients connect to the server.
    #
    # Arguments:
    #   opts	a dict containing listener options
    #	sock	The new socket connection
    #	ipaddr	The client's IP address
    #	port	The client's port
    #
    # Results:
    #	none
    #
    # Side Effects:
    #	Set up a handler, HttpdRead, to read the request from the client.
    #	The per-connection state is kept in Httpd$sock, (e.g., Httpdsock6),
    #	and upvar is used to create a local "data" alias for this global array.

    method accept {opts sock ipaddr rport} {
	Debug.listener {accepted: $sock $ipaddr $rport}

	if {[dict exists $opts -tls]} {
	    variable defaults
	    if {[catch {
		chan configure $sock -blocking 1 -translation {binary binary}
		tls::import $sock -server 1 {*}[dict in [dict opts.-tls] [dict keys $defaults]] -command [list [self] progress] -password [list [self] password]
		tls::handshake $sock
	    } e eo]} {
		Debug.error {Error accepting HTTPS connection: '$e'}
		catch {close $sock}
		return
	    }
	    Debug.listener {TLS status local: [::tls::status -local $sock] remote: [::tls::status $sock]}
	    dict set opts -client_certificate [::tls::status $sock] -server_certificate [::tls::status -local $sock]
	}

	if {[catch {
	    # select an Http object to handle incoming
	    set server [chan configure $sock -sockname]
	    Debug.listener {connect: [dict get $opts -httpd] $sock $ipaddr $rport {*}$opts -server $server}
	    {*}[dict get $opts -httpd] $sock $ipaddr $rport {*}$opts -server $server
	} result eo]} {
	    Debug.error {accept: $eo}
	}
    }

    method progress {op sock args} {
	switch -- $op {
	    error {
		Debug.error {error on $sock: '$args'}
		#catch {close $sock}
	    }
	    verify {
		set args [lassign $args depth cert status error]
		Debug.tls {verify ($depth) on $sock: $status '$error' cert:($cert)}
	    }
	    info {
		lassign $args major minor msg
		Debug.tls {info on $sock: $major/$minor '$msg'}
	    }
	    default {
		Debug.tls {$op $sock $args}
	    }
	}
	return 1
    }

    method password {args} {
	puts stderr "TLS password: $args"
	return 1
    }

    constructor {args} {
	Debug.listener {construct [self] ($args)}
	set args [dict merge [subst {
	    -host [info hostname]
	    -port 8080
	    -httpd {Httpd connect}
	}] $args]
	dict set args -id [self]

	if {[dict exists $args -tls] && [dict get $args -tls]} {
	    # TLS / HTTPS socket
	    Debug.listener {TLS required}
	    variable defaults {
		-certfile server-public.pem
		-keyfile server-private.pem
		-cadir .
		-cafile ca.pem
		-ssl2 0
		-ssl3 1
		-tls1 1
		-require 0
		-request 1
	    }
	    dict unset args -tls
	    dict for {n v} $defaults {
		if {[dict exists $args $n]} {
		    dict args.-tls.$n [dict args.$n]
		    dict unset args $n
		} else {
		    dict args.-tls.$n $v
		}
	    }

	    set ca [dict args.-ca?]
	    if {$ca ne ""} {
		dict args.-tls.-ca $ca
		dict unset args -ca

		# we're operating a CA - get the keys from there
		if {![string match ::* $ca]} {
		    set ca ::Domains::$ca	;# make it relative to Domains
		}

		Debug.listener {server key and cert supplied by '$ca' domain}
		dict args.-tls.-certfile [{*}$ca servercert [dict args.-host]]
		dict args.-tls.-cafile [{*}$ca cacert]
		dict args.-tls.-keyfile [{*}$ca serverkey [dict args.-host]]
	    } else {
		Debug.listener {no CA domain specified $ca}
	    }
	    Debug.listener {TLS args: [dict args.-tls]}
	}

	set cmd [list socket -server [list [self] accept $args]]

	# specifying -myaddr makes the Listener listen
	# on only the specified interface
	if {[dict exists $args -myaddr] &&
	    [dict get $args -myaddr] != 0
	} {
	    lappend cmd -myaddr [dict get $args -myaddr]
	}
	
	lappend cmd [dict get $args -port]
	
	Debug.listener {server: $cmd}
	variable listener
	if {[catch $cmd listener eo]} {
	    Debug.error {Listener Failed: '$cmd' $listener ($eo)}
	} else {
	}

	Debug.log {Listener $listener on [fconfigure $listener]}
    }

    destructor {
	catch {close $listen}
    }
}

if {[info exists argv0] && ($argv0 eq [info script])} {
    # test Listener with Httpd
    package require Httpd
    package require Query

    proc Dispatch {req} {
	#puts stderr "Dispatcher: $req"

	set http [dict get $req -http]
	{*}$http Restart $req	;# assume it's not a POST

	# clean out some values
	dict unset req cache-control

	set c {
	    <html>
	    <head>
	    <title>Test Page</title>
	    </head>
	    <body>
	    <h1>Test Content</h1>
	}

	append c "<table border='1' width='80%'>" \n
	append c <tr> <th> metadata </th> </tr> \n
	dict for {n v} $req {
	    if {[string match -* $n]} {
		append c <tr> <td> $n </td> <td> $v </td> </tr> \n
	    }
	}
	append c </table> \n

	append c "<table border='1' width='80%'>" \n
	append c <tr> <th> "HTTP field" </th> </tr> \n
	dict for {n v} $req {
	    if {![string match -* $n]} {
		append c <tr> <td> $n </td> <td> $v </td> </tr> \n
	    }
	}
	append c </table> \n

	append c "<table border='1' width='80%'>" \n
	append c <tr> <th> "Query field" </th> </tr> \n
	dict for {n v} [Query flatten [Query parse $req]] {
	    append c <tr> <td> $n </td> <td> $v </td> </tr> \n
	}
	append c </table> \n

	append c {
	    </body>
	    </html>
	}

	$http Respond 200 [dict replace $req -content $c \
			       warning "199 Moop 'For fun'" \
			       content-type text/html \
			      ]
    }

    # start Listener
    set listener [Listener %AUTO% -port 8080 -dispatcher Dispatch]

    package require Stdin

    set forever 0
    vwait forever
}
