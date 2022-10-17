# WSWub - Wub interface to WebServices
package require WS::Server

package require OO
package require Direct
package require Debug
Debug define wsdl 10

package provide WS::Wub 1.1.1
package provide Wsdl 1.0

set ::API(Domains/WDSL) {
    {
	A domain which dispatches URL requests to WDSL WebServices

	== QuickStart ==
	package require WS::Wub
	Nub domain /service/wsEchoExample Wsdl service wsEchoExample
	Nub domain /service/wsEchoExample2 Wsdl service wsEchoExample

	Note: you can have multiple Wsdl instances
    }
    service {service defined by WS::Server}
}

class create ::Wsdl {
    method / {r args} {
	return [Http Ok $r [::WS::Server::generateInfo $service 0] text/html]
    }

    method /op {r args} {
	# TODO - got to read -entity if it's a file
	if {[catch {::WS::Server::callOp $service 0 [dict get $r -entity]} result]} {
	    return [Http Ok $r $result]
	} else {
	    dict set r -code 500
	    dict set r content-type text/xml
	    dict set r -content $result
	    return [NoCache $r]
	}
    }

    method /wsdl {r args} {
	return [Http Ok $r [::WS::Server::GetWsdl $service] text/xml]
    }

    superclass mixin Direct	;# Direct mixin maps the URL to invocations of the above methods
    variable service
    constructor {args} {
	set service [dict get $args service]	;# we need to remember the service name
	next {*}$args
    }
}
