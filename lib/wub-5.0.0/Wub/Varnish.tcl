# Varnish - varnish cache support
# see http://www.varnish-cache.org/ for what this marvellous beastie can do.

package require Debug
package require Url

package provide Varnish 1.0

Debug off varnish 10

#interp bgerror {} bge
#proc bge {args} {
#    puts stderr "ERR: $args"
#}

# TODO:
# when varnish goes down and comes back up, the connection dies.
# this needs to be detected, and the varnish reconnected

namespace eval Varnish {
    variable vaddress localhost
    variable vport 6082
    variable tx {}
    variable rx {}

    proc collect {} {
	variable rx; variable tx

	set result {}
	set len [llength $rx]
	for {set i 0} {$i < $len} {incr i} {
	    lappend result [lindex $tx $i] [lindex $rx $i]
	}

	set tx [lrange $tx $len end]
	set rx [lrange $rx $len end]

	return $result
    }

    proc response {} {
	variable varnish
	set line [gets $varnish]
	set status 0; set length 0
	lassign [split $line] status length
	set data [read $varnish $length]
	Debug.varnish {R: ($data)}
	variable rx; lappend rx $data
	gets $varnish
    }

    proc send {cmd args} {
	variable tx; lappend tx [list $cmd {*}$args]

	variable varnish
	if {[eof $varnish]} {
	    connect
	}

	puts $varnish "$cmd $args"

	Debug.varnish {T: $cmd $args}
    }

    variable vclfile [file join [file dirname [file normalize [info script]]] wub.vcl]
    
    proc immediate {cmd} {
	variable tx; lappend tx [list $cmd]

	variable varnish
	Debug.varnish {I: $cmd}
	puts $varnish $cmd
	response
	return [collect]
    }

    proc connect {} {
	variable vport
	variable vaddress
	variable varnish [socket $vaddress $vport]
	fconfigure $varnish -buffering line -translation {binary auto}
	fileevent $varnish readable [list Varnish response]
	return $varnish
    }

    proc new {args} {
	if {$args ne {}} {
	    variable {*}$args
	}

	variable debug
	if {[info exists debug]} {
	    Debug on varnish $debug
	}
	Debug.varnish {Varnish starting}

	connect

	# pass our VCL config
	variable vcl
	variable cookies

	#variable vclfile
	#immediate "vcl.load wub $vclfile"
	#immediate "vcl.use wub"
	return [immediate vcl.list]
    }

    namespace export -clear *
    namespace ensemble create -subcommands {}
}

namespace eval Cache {

    #### Cache API
    proc delete {url} {
	Varnish send url.purge [dict get [Url parse $url] -path]
    }

    proc clear {} {
	Varnish send url.purge *
    }

    proc check {args} {
	return {}
    }

    proc put {args} {
	return 0
    }

    namespace export -clear *
    namespace ensemble create -subcommands {}
}

if {0} {
    Varnish new
    Varnish send url.purge /
    after 10 {puts stderr [Varnish collect]}

    set forever 0
    vwait forever
}
