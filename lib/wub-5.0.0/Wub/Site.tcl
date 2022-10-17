#! /usr/bin/env tclsh

# Site - simple configuration for single-threaded Wub Server.
package require Tcl 8.6	;# minimum version of tcl required
set ::tcl::unsupported::noReverseDNS 1	;# turn off reverse DNS

namespace eval ::Site {
    variable home [file normalize [file dirname [info script]]]
}

# temporary compatibility shim for coroutines
# handle new coro interface
if {[llength [info command ::tcl::unsupported::yieldm]]} {
    namespace eval tcl::unsupported namespace export yieldm
    namespace import tcl::unsupported::yieldm
    interp alias {} ::Coroutine {} ::coroutine
} else {
    # the new yieldm multi-arg coro call does not exist.
    # this is the older coroutine implementation
    interp alias {} ::yieldm {} ::yield

    proc ::delshim {name x y op} {
	catch {::rename $name {}}	;# delete shim
    }

    proc ::Coroutine {name command args} {
	# determine the appropriate namespace for coro creation
	set ns [namespace qualifiers $name]
	if {![string match ::* $ns]} {
	    set ns [uplevel 1 namespace current]::$ns
	}
	set name [namespace tail $name]

	# create a like-named coro
	set x [uplevel 1 [list ::coroutine ${ns}_$name $command {*}$args]]

	# wrap the coro in a shim
	proc ${ns}$name {args} [string map [list $x %N%] {
	    tailcall %N% $args	;# wrap the args into a list for the old-style coro
	}]

	# the two commands need to be paired for destruction
	trace add command ${ns}_$name delete [list ::delshim ${ns}$name]
	trace add command ${ns}$name delete [list ::delshim ${ns}_$name]

	# tell it we created the one they requested
	return ${ns}$name
    }
}

# keep track of sourced files - doesn't work on macosx
package require platform
if {[lindex [split [platform::generic] -] 0] ni {macosx}} {
    set ::__source_log [file normalize [info script]]
    rename source source_org
    proc ::source {args} {
	set fn [lindex $args end]
	if {[lindex [file split $fn] end] ne "pkgIndex.tcl"} {
	    set f [file normalize $fn]
	    dict set ::Site::sourced [list source $f] $args
	    lappend ::__source_log ${f}
	    puts stderr "source $f"
	}
	return [uplevel source_org {*}$args]
    }

    set ::__load_log {}
    rename load load_org
    proc ::load {args} {
	set f [file normalize [lindex $args 0]]
	dict set ::Site::sourced [list load $f] $args
	lappend ::__load_log ${args}
	puts stderr "load $f"
	return [uplevel load_org {*}$args]
    }
}


# this will make some necessary changes to auto_path so we find Wub
proc findpaths {} {
    foreach el $::auto_path {
	dict set apath [file normalize $el] {}
    }
    set nousrlib [catch {dict unset apath /usr/lib}]

    if {![info exists ::starkit::topdir]} {
	# unpacked startup
	dict set apath $::Site::home {}

	# find Wub stuff
	set top [file dirname $::Site::home]
	foreach lib {extensions Wub Domains Utilities Client} {
	    dict set apath [file join $top $lib] {}
	}
    } else {
	# starkits handle the auto_path for us
	# but do they handle the home for us?
    }

    if {!$nousrlib} {
	dict set apath /usr/lib {}	;# put the fallback libdir at the end
    }

    set ::auto_path [dict keys $apath]

    #Debug.log {AUTOPATH: $::auto_path}
}
findpaths	;# have to do this before looking for Debug or Dict

package require Debug	;# Debug before Dict, as it depends on it

##nagelfar syntax catch c n? n?
proc bgerror {args} {
    Debug.error {bgerror: $args}
}
interp bgerror {} ::bgerror

package require Dict
package require Config	;# handle configuration

Debug on site 10
Debug define nubsite 10
package provide Site 1.0	;# we're providing the Site facilities

namespace eval ::Site {
    ::variable phase "Base Initialization"	;# record the site init phase

    # variable - track variable definitions
    proc variable {args} {
	::variable phase
	dict for {name value} $args {
	    ::variable $name
	    if {[info exists $name]} {
		Debug.site {($phase) overriding variable $name: $value - was ([set $name])}
	    } else {
		Debug.site {($phase) define variable $name: $value}
	    }
	    set $name $value
	    if {[catch {
		uplevel ::variable $name	;# add the variable def to caller
	    } e eo]} {
		Debug.error {variable '$name' $e ($eo)}
	    }
	}
    }

    # conditionally overwrite variables
    proc Variable {args} {
	::variable phase
	dict for {name value} $args {
	    ::variable $name
	    if {![info exists $name]} {
		Debug.site {($phase) define Variable $name: $value}
		set $name $value
	    } else {
		Debug.site {($phase) not overriding Variable $name: $value - existing value ([set $name])}
	    }
	    uplevel ::variable $name	;# add the variable def to caller
	}
    }

    variable sourced [list [info script] [info script]]

    # record wub's home
    variable wubroot $home
    variable wubtop [file dirname $home]

    # uncomment to turn off caching for testing
    # package provide Cache 2.0 ; proc Cache args {return {}}

    # return a specific module Site var
    proc var {module args} {
	if {[llength $args]} {
	    return [config get $module {*}$args]
	} else {
	    return [config section $module]
	}
    }

    proc var? {module args} {
	if {[config exists $module]} {
	    if {[llength $args]} {
		return [config get $module {*}$args]
	    } else {
		return [config section $module]
	    }
	} else {
	    return {}
	}
    }

    # return all the configuration state of Site in a handy form
    proc vars {args} {
	set vars {}
	foreach var [info vars ::Site::*] {
	    if {[info exists $var]} {
		set svar [namespace tail $var] 
		catch {lappend vars $svar [set $var]}
	    }
	}
	return $vars
    }

    variable wubdir [file normalize [file join [file dirname [info script]] ..]] ;# where's wub
    variable docroot $wubdir
    ::variable configuration {
	Wub {
	    home [file normalize [file dirname [info script]]] ;# home of application script
	    host [info hostname]	;# default home for relative paths
	    config ./site.config	;# configuration file
	    globaldocroot 1		;# do we use Wub's docroot, or caller's
	    application ""		;# package to require as application
	    local local.tcl	;# post-init localism
	    password ""		;# account (and general) root password
	    # topdir	;# Where to look for Wub libs - don't change
	    # docroot	;# Where to look for document root.
	}

	Shell {
	    load 0		;# want Console
	    port 8082		;# Console listening socket
	}

	STX {
	    load 1	;# want STX by default
	    scripting 0	;# permit stx scripting?
	}

	Listener {
	    # HTTP Listener configuration
	    -port 8080	;# Wub listener port
	    #-host	;# listening host (default [info hostname]
	    #-http	;# dispatch handler (default Http)
	    -httpd {::Httpd connect}
	}

	Https {
	    # HTTPS Listener configuration
	    # -port 8081	;# Wub listener port
	    # -host	;# listening host (default [info hostname]
	    # -http	;# dispatch handler (default Http)
	}

	Sscgi {
	    # SCGI Listener configuration
	    -port 8088			;# what port does SCGI run on
	    -port 0			;# disable SCGI - comment to enable
	    -scgi_send {::scgi Send}	;# how does SCGI communicate incoming?
	}

	Varnish {
	    # Varnish configuration
	    load 0			;# don't want varnish
	    # vaddress localhost	;# where is varnish running?
	    # vport 6082		;# on what port is varnish control?
	}

	Block {
	    load 1		;# want block by default
	}

	Human {
	    load 0		;# want human by default
	}

	Ua {
	    load 1		;# want user agent classification by default
	}

	Convert {		;# cant content negotiation by default
	    load 1
	}

	Cache {
	    # Internal Cache configuration
	    load 1		;# want cache, by default
	    maxsize 204800	;# maximum size of object to cache
	    high 100		;# high water mark for cache
	    low 90		;# low water mark for cache
	    weight_age 0.02	;# age weight for replacement
	    weight_hits -2.0	;# hits weight for replacement
	    # CC 0	;# do we bother to parse cache-control?
	    # obey_CC 0	;# do we act on cache-control? (Not Implemented)
	}

	Nub {
	    load 1
	    nubs {}
	    # nub.nub bogus.nub
	}

	Httpd {
	    # Httpd protocol engine configuration
	    logfile "wub.log"	;# log filename for common log format logging
	    max_conn 20		;# max connections per IP
	    no_really 30	;# how many times to complain about max_conn
	    # server_port	;# server's port, if different from Listener's
	    # server_id		;# server ID to client (default "Wub")
	    retry_wait	20	;# how long to advise client to wait on exhaustion
	    timeout 60000	;# ms of idle to tolerate
	}
    }

    proc init {args} {
	::variable phase "init processing"	;# move to site init phase

	# immediately set up debugging
	if {[dict exists $args debug]
	    && [dict get $args debug]
	} {
	    Debug on site [dict get $args debug]
	    dict unset args debug
	}

	::variable configuration
	#Debug on config
	Config create config $configuration
	namespace export -clear *
	namespace ensemble create -subcommands {}
	unset configuration	;# done with configuration var

	# unpacked startup
	::variable home
	lappend ::auto_path $home	;# add the app's home dir to auto_path

	# find Wub stuff
	::variable wubdir; ::variable topdir
	config assign Wub topdir [file normalize $wubdir]

	# evaluate Wub section + $args
	::variable home	;# application's default home
	config assign Wub home $home

	config merge_section Wub [list home $home {*}$args]

	# read Wub.config configuration file
	set C [config extract]
	if {[dict exists $C Wub config]} {
	    set phase "Site user configuration"	;# move to site config files phase
	    if {[file exists [dict get $C Wub config]]} {
		config aggregate [Config create user file [dict get $C Wub config]]
		set C [config extract]	;# extract configuration values
		user destroy
	    } else {
		Debug.site {Site ERROR: config file [dict get $C Wub config] does not exist.}
	    }
	}

	# args to Site::init override initial variable values
	foreach {n v} $args {
	    if {[string match {[A-Z]*} $n]} {
		config merge_section [string totitle $n] $v
		dict unset args $n
	    }
	}

	# use Wub config to populate ::Site variables
	dict for {n v} [dict get $C Wub] {
	    variable $n $v
	}

	# configuration variable contains defaults
	# set some default configuration flags and values
	set phase "Site init configuration"	;# move to site configuration phase

	set phase "Site derived values"	;# phase to generate some derived values
	#dict set config Wub url "http://[dict get $C Wub host]:[dict get $C Listener -port]/"

	set phase "Site modules"	;# load site modules

	proc init {args} {}	;# ensure init can't be called twice
    }

    #### Debug init - set some reasonable Debug narrative levels
    Debug on error 100
    Debug on log 10
    Debug on block 10

    #### section - interrogate section for nub definitions
    proc section {sect} {
	set section [config get $sect]
	if {[dict exists $section domain] || [dict exists $section handler]} {
	    # Domain Nub declaration
	    if {![dict exists $section url]} {
		error "nub '$sect' declared in .config must have a url value"
	    }

	    # handler and domain are synonyms ... le sigh
	    if {![dict exists $section handler]} {
		set domain [dict get $section domain]
	    } else {
		set domain [dict get $section handler]
	    }
	    dict unset section domain

	    if {![string match {[A-Z]*} $domain]
		|| [string map {" " ""} $domain] ne $domain} {
		error "Nub '$sect' domain arg '$domain' is badly formed."
	    }
	    set url [dict get $section url]
	    dict unset section url

	    if {[dict exists $section -loaddir]} {
		set dir [dict get $section -loaddir]
		::source [file join $dir pkgIndex.tcl]
		dict unset section -loaddir
	    }
	    if {[dict exists $section -loadfile]} {
		set file [dict get $section -loadfile]
		::source $file
		dict unset section -loadfile
	    }

	    set a {}
	    foreach {n v} $section {
		lappend a $n $v
	    }

	    if {[dict exists $a -threaded]} {
		# this is a threaded domain
		set targs [dict get $a -threaded]
		dict unset a -threaded
		Debug.nubsite {Nub domain $url [list Threaded ::Domains::$sect] {*}$targs $domain $a}
		Nub domain $url [list Threaded ::Domains::$sect] {*}$targs $domain {*}$a
	    } else {
		# this is a non-threaded domain
		Debug.nubsite {Nub domain $url [list $domain ::Domains::$sect] $a}
		Nub domain $url [list $domain ::Domains::$sect] {*}$a
	    }
	} elseif {[dict exists $section block]} {
	    # Block Nub section
	    dict with section {
		Debug.nubsite {Nub block $block}
		Nub block $block
	    }
	} elseif {![dict exists $section url]} {
	    error "nub '$sect' declared in .config must have a url value"
	} elseif {[dict exists $section code]} {
	    # Code Nub section
	    dict with section {
		if {![info exists mime]} {
		    set mime x-text/html-fragment
		} else {
		    set mime $mime
		}
		Debug.nubsite {Nub code $url $code $mime}
		Nub code $url $code $mime
	    }
	} elseif {[dict exists $section literal]} {
	    # Literal Nub section
	    dict with section {
		if {![info exists mime]} {
		    set mime x-text/html-fragment
		} else {
		    set mime $mime
		}
		Debug.nubsite {Nub literal [lindex $url 0] '$literal' $mime}
		Nub literal $url $literal $mime
	    }
	} elseif {[dict exists $section redirect]} {
	    # Redirect Nub section
	    dict with section {
		Debug.nubsite {Nub redirect $url $redirect}
		Nub redirect $url $redirect
	    }
	} elseif {[dict exists $section rewrite]} {
	    # Rewrite Nub section
	    dict with section {
		Debug.nubsite {Nub rewrite [lindex $url 0] $rewrite}
		Nub rewrite [lindex $url 0] $rewrite
	    }
	} elseif {[dict exists $section auth]} {
	    # Auth Nub section
	    dict with section {
		Debug.nubsite {Nub auth [lindex $url 0] $auth}
		Nub auth [lindex $url 0] $auth
	    }
	}
    }

    #### sections - process each section for Domain definition
    proc sections {} {
	::variable sections
	foreach sect [config sections {[a-z]*}] {
	    Debug.site {processing section: $sect}
	    section $sect
	}
    }

    #### Load those modules needed for the server to run
    proc modules {} {
	::variable docroot
	package require Httpd

	#### Load Debug defaults
	if {[config exists Debug]} {
	    foreach {n v} [config section Debug] {
		set v [lassign $v val]
		if {[string is integer -strict $val]} {
		    Debug on $n $val {*}$v
		} elseif {$val eq "on"} {
		    Debug on $n {*}$v
		} elseif {$val eq "off"} {
		    Debug off $n {*}$v
		} else {
		    puts stderr "Debug config error '$n $val $v'"
		}
	    }
	    puts stderr "DEBUG: [Debug 2array]"
	}

	#### Load Convert module - content negotiation
	# install default conversions
	package require Convert
	if {[config exists Convert]} {
	    Convert create ::convert {*}[config section Convert]
	} else {
	    Convert create ::convert
	}

	#### Load Block module - blocks incoming by ipaddress
	::variable block
	if {[config exists Block]
	    && [config get Block load]
	} {
	    #### initialize Block
	    Debug.site {Module Block: YES}
	    package require Block
	    ::variable docroot
	    Block new logdir $docroot {*}[config section Block]
	} else {
	    # NULL Block
	    Debug.site {Module Block: NO}
	    namespace eval ::Block {
		proc block {args} {}
		proc blocked? {args} {return 0}
		proc new {args} {}
		namespace export -clear *
		namespace ensemble create -subcommands {}
	    }
	}

	#### Load Human Module - redirects bad bots
	if {[config exists Human]
	    && [config get Human load]
	} {
	    #### initialize Human
	    package require Human
	    Debug.site {Module Human: YES}
	    ::HumanC create ::Human {*}[config section Human]
	} else {
	    # NULL Human
	    Debug.site {Module Human: NO}
	    namespace eval ::Human {
		proc track {r args} {return $r}
		namespace export -clear *
		namespace ensemble create -subcommands {}
	    }
	}

	#### Load UA Module - classifies by user-agent
	if {[config exists UA]
	    && [config get UA load]
	} {
	    #### initialize UA
	    package require UA
	    Debug.site {Module UA: YES}
	} else {
	    # NULL UA classifier
	    Debug.site {Module UA: NO}
	    namespace eval ::UA {
		proc classify {args} {return browser}
		proc parse {args} {return ""}
		namespace export -clear *
		namespace ensemble create -subcommands {}
	    }
	}

	### Load Varnish Module - a kind of Cache
	if {[config exists Varnish]
	    && [config get Varnish load]
	} {
	    #### Varnish cache
	    package require Varnish
	    if {![catch {
		Varnish init {*}[config section Varnish]
		Debug.site {Module Varnish: YES}
	    } r eo]} {
		Debug.error {varnish: $r ($eo)}
		package forget Varnish
		catch {unset cache}
	    }
	} else {
	    Debug.site {Module Varnish: NO}
	}

	#### Load Cache Module - server caching
	if {[config exists Cache]
	    && [config get Cache load]
	} {
	    #### in-RAM Cache
	    package require Cache 
	    Cache new {*}[config section Cache]
	    Debug.site {Module Cache: YES}
	} else {
	    #### Null Cache - provide a minimal non-Cache interface
	    package provide Cache 2.0
	    namespace eval ::Cache {
		proc put {r} {return $r}
		proc check {r} {return {}}
		
		namespace export -clear *
		namespace ensemble create -subcommands {}
	    }
	    Debug.site {Module Cache: NO}
	}

	#### Load STX Module - rich text conversion
	if {[config exists STX]
	    && [config get STX load]
	} {
	    #### stx init
	    package require stx
	    package require stx2html

	    ::variable stx_scripting
	    stx2html init script [config get STX scripting] {*}[config section STX]
	    Debug.site {Module STX: YES}
	} else {
	    Debug.site {Module STX: NO}
	}

	#### Console init
	if {[config exists Shell]
	    && [config get Shell load]
	} {
	    if {[catch {
		#### Shell init
		package require Shell
		Shell new {*}[config section Shell]
	    } err eo]} {
		Debug.error {Module Shell: Failed to Init. $err ($eo)}
	    }
	} else {
	    Debug.site {Module Shell: NO}
	}

	#### Load up nubs
	package require Nub
	Nub init {*}[config section Nub]
	sections	;# initialize the nubs

	#### Load local semantics from ./local.tcl
	::variable local
	::variable home
	if {[info exists local] && $local ne ""} {
	    if {[file exists $local]} {
		if {[catch {source $local} r eo]} {
		    Debug.error {Site LOCAL ($local) error: '$r' ($eo)}
		}
	    }
	}

	# apply all collected Nubs - this doesn't instantiate them
	if {[config exists Nub]
	    && [config get Nub load]
	} {
	    Nub apply
	}

	#### start Httpd protocol
	::variable httpd
	Httpd configure server_id "Wub [package present Httpd]" {*}[config section Httpd]

	::variable server_port
	if {[info exists server_port]} {
	    # the listener and server ports differ
	    Httpd configure server_port $server_port
	}

	::variable host
	::variable docroot

	#### start Listeners
	set lconf [config section Listener]
	if {[dict get? $lconf -myaddr] eq ""} {
	    Listener new {*}[config section Listener]
	} else {
	    foreach p [dict get? $lconf -myaddr] {
		Listener new {*}[config section Listener] -myaddr $p
	    }
	}

	#### start HTTPS Listener
	if {[config exists Https -port]
	    && ([config get Https -port] > 0)
	} {
	    Debug.site {Loading HTTPS listener}
	    if {[catch {
		package require tls
	    } e eo]} {
		Debug.error {Failed to load tls package for Https.  '$e' ($eo)}
	    } else {
		#### Simplistic Certificate Authority
		#package require CA
		#CA init dir $home/CA host $host port [dict get $https -port]
		#dict lappend https -tls -cafile [CA cafile] -certfile [CA certificate $host] 
		Listener new {*}[config section Https] -tls 1 -httpd ::Httpd
	    }
	} else {
	    Debug.site {Not loading HTTPS listener}
	}

	#### start scgi Listener
	if {[config exists Sscgi -port]
	    && [config get Sscgi -port] > 0
	} {
	    package require Sscgi
	    Listener new sscgi {*}[config section Sscgi] -httpd Sscgi
	}
	puts stderr "DEBUG2: [Debug 2array]"
    }

    # this will shut down the whole system
    proc shutdown {{reason "No Reason"}} {
	variable done 1
    }

    # Load the application, on first call also starts the server
    proc start {args} {
	Debug.site {start: $args}
	init {*}$args

	modules		;# start the listeners etc

	set phase "Site Start"	;# site start phase

	# can't run the whole start up sequence twice
	# can initialize the application
	proc start {args} {
	    #### load the application
	    set application [dict get? $args application]
	    if {$application ne ""} {
		package require $application
		
		# install variables defined by local, argv, etc
		set app [string tolower $application]
		if {[info exists modules([string tolower $app])]} {
		    ::variable $app
		    Debug.site {starting application $application - [list variable {*}[set $app]]}
		    Debug.site {app ns: [info vars ::${application}::*]}
		    namespace eval ::$application [list ::variable {*}[set $app]]
		    Debug.site {app ns: [info vars ::${application}::*]}
		} else {
		    Debug.site {not starting application $application, no module in [array names modules]}
		}
	    } else {
		Debug.site {No application specified}
	    }
	}
	if {[info exists application]} {
	    start application $application	;# init the application
	} else {
	    start
	}

	# redefine ::vwait so we don't get fooled again
	rename ::vwait ::Site::vwait
	proc ::vwait {args} {
	    catch {
		info frame -1
	    } frame
	    puts stderr "Recursive VWAIT AAAARRRRRRGH! from '$frame'"
	}

	# enter event loop
	::variable done 0
	while {!$done} {
	    Debug.site {entered event loop}
	    ::Site::vwait ::Site::done
	}

	Debug.log {Shutdown top level}
    }

    namespace export -clear *
    namespace ensemble create -subcommands {}
}

if {[info exists argv0] && ($argv0 eq [info script])} {
    if {0} {
	# this will run Wub under the experimental Package facility
	lappend auto_path [file dirname [pwd]]/Utilities/
	package require Package	;# start the cooption of [package]
    }
    set auto_path [list [pwd] {*}$auto_path]

    # Initialize Site
    Site init home [file normalize [file dirname [info script]]] config site.config debug 10

    # Start Site Server(s)
    Site start 
}

# vim: ts=8:sw=4:noet
