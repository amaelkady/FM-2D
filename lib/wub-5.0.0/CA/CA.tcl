# Simplistic Certificate Authority code for generating
# server and CA certificates, suitable for Wub and tls
#
# Provides just enough openssl interface to create a self-signed CA
# and to create and sign a server certificate.

# Note: we do not encrypt the private keys we generate.
# if this troubles you (and it probably should):
# store $dir/private on an encrypted mount.

# We generate a little CA directory with server and CA certs
# and a directory [Doc_Root]/ca/ containing those keys, to enable a client
# to trust the CA key so our server key will go down easy.

# Configuration for CA
# Edit to suit - particularly the CA_* fields

if {[info exists argv0] && ($argv0 eq [info script])} {
    lappend auto_path ../Utilities ../extensions
}

set ::CA_dir [file normalize [file dirname [info script]]]
lappend ::auto_path $::CA_dir

package require Debug
Debug define ca 10
Debug define caui 10
Debug define openssl 10
Debug define skpac 10

package require Url
package require Dict
package require fileutil
package require Config
#package require CertStore

package provide CA 2.0

oo::class create OpenSSL {
    method readerr {args} {
	variable rerr
	if {[catch {chan eof $rerr} eof] || $eof} {
	    # detect fd closure ASAP
	    Debug.openssl {Lost connection}
	}

	set read [chan read $rerr 1024]	;# grab some input

	variable errbuf
	append errbuf $read
	if {[string first \n $read] > -1} {
	    #Debug.ca {Err: '$read'}
	}
    }

    method reader {args} {
	variable fd
	if {[catch {chan eof $fd} eof] || $eof} {
	    # detect fd closure ASAP
	    Debug.openssl {Lost connection}
	}

	# calculate scanning start position
	variable inbuf
	set for "OpenSSL> "
	set scanned [expr {[string length $inbuf]-[string length $for]}]
	if {$scanned < 0} {
	    set scanned 0
	}
	set read [chan read $fd 1024]	;# grab some input
	append inbuf $read
	#Debug.ca {Read: '$read' - [string first $for [string range $inbuf $scanned end]]}

	# scan inbuf for responses and dispatch
	variable responses

	while {[set found [string first $for [string range $inbuf $scanned end]]] >= 0} {
	    # we've found a prompt!
	    incr found $scanned
	    set response [string range $inbuf 0 [expr {$found-1}]]
	    set inbuf [string range $inbuf [expr {$found + [string length $for]}] end]
	    set responses [lassign $responses respond]
	    if {[llength $respond]} {
		Debug.ca {responding to '$response' with '$respond'}
		{*}$respond $response
	    }
	}
    }

    method send {what args} {
	variable responses
	lappend responses $args
	variable fd
	Debug.ca {OpenSSL send: '$what'}
	if {[catch {
	    puts $fd $what
	} e eo]} {
	    Debug.ca {Error writing to OpenSSL: '$e' ($eo)}
	    catch {close $fd}
	}
    }

    method started {args} {
	Debug.ca {[self] STARTED $args}
    }

    destructor {
	variable fd
	catch {close $fd}
    }

    constructor {args} {
	variable openssl ""
	variable sslopts {}
	variable inbuf ""
	variable errbuf ""
	variable responses [list [list [self] started]]
	variable {*}$args
	if {$openssl eq ""} {
	    set openssl [exec which openssl]
	}
	variable scanned 0

	variable fd [open "|$openssl $sslopts 2>@1" r+]
	variable pid $fd

	chan configure $fd -blocking 0 -buffering line
	chan event $fd readable [list [self] reader]
	if {0} {
	    variable errbuf
	    chan configure $rerr -blocking 0 -buffering line
	    chan event $rerr readable [list [self] readerr]
	}
    }
}

oo::class create CA {
    # run the openssl program
    method openssl {what args} {
	if {[llength $args] == 1} {
	    set arglist result
	    set args [lassign $args after]
	} else {
	    set args [lassign $args arglist after]
	}
	variable ossl
	$ossl send $what ::apply [list $arglist $after [namespace current]] {*}$args
    }

    # construct a subject for a request
    method subject {args} {
	variable DN
	foreach var {C ST L O OU CN} {
	    if {[dict exists $args $var]} {
		set val [dict args.$var]
	    } elseif {[dict exists $DN $var]} {
		set val [dict DN.$var]
	    }
	    lappend result $var=$val
	}
	return /[join $result /]
    }

    # symbolic link two files
    method link {link dst} {
	set base [file dirname $link]
	set rdst [::fileutil::relative $base $dst]
	file link -symbolic $link $rdst
    }

    # get the CA serial number
    method getSN {} {
	variable dir
	set sf [file join $dir serial]
	set sn [string trimleft [::fileutil::cat -- $sf] 0]
	if {$sn eq ""} {
	    set sn 0
	}
	::fileutil::writeFile -- $sf 0[expr {$sn + 1}]
	return 0$sn
    }

    method cafile {} {
	variable cacert; return $cacert
    }

    method certificate {server} {
	variable type2ext
	variable webdir
	set cert [file join $webdir $server.[dict type2ext.server]]
	set cert [file normalize [file join [file dirname $cert] [file link $cert]]]
	if {[file exists $cert]} {
	    return $cert
	} else {
	    Debug.ca {CERT: $cert}
	    error "$server has no certificate - check CA"
	}
    }

    method getcert {cf args} {
	if {![llength $args]} {
	    set args {{puts $result}}
	}
	foreach n {header pubkey sigdump} {
	    lappend certopt -certopt no_$n
	}

	my openssl "x509 -in $cf $certopt -text -subject_hash -issuer_hash" {*}$args
    }

    method write_config {to config} {
	set extracted [$config extract]
	Debug.ca {writing config ($extracted)}
	set fd [open $to w]
	puts $fd "# Generated from [file join $::CA_dir CA.config]"
	dict for {id section} $extracted {
	    puts $fd "\[${id}\]"
	    dict for {var val} $section {
		if {[string match "* *" $val]} {
		    set val "\"${val}\""	;# needs to be wrapped in quotes
		}
		puts $fd "\t$var = $val"
	    }
	    puts $fd ""
	}
	close $fd
    }

    # construct config file for openssl
    method configuration {} {
	variable config [Config new]

	# fill config with defaults if unspecified
	variable dir
	$config assign? CA_default dir $dir ;# Where everything is kept
	variable cacert
	$config assign? CA_default certificate $cacert	;# The CA certificate
	variable cakey
	$config assign? CA_default private_key $cakey	;# The private key
	variable keybits
	$config assign? req default_bits $keybits	;# request key size

	variable url
	$config assign? v3_ca nsBaseUrl $url
	$config assign? v3_user nsBaseUrl $url
	$config assign? v3_server nsBaseUrl $url

	$config load [file join $::CA_dir CA.config]		;# load config file

	variable DN
	Debug.ca {config req_distinguished_name ($DN)}
	dict for {n v} $DN {
	    $config assign? req_distinguished_name $n [list $v]
	}

	variable policy
	dict for {n v} $policy {
	    $config assign policy $n [list $v]
	}
	$config assign CA_default policy policy

	# write config for generate and GenCA
	variable ca_config
	my write_config $ca_config $config
    }

    # provide symlink for tls dir handling
    method trust {cafn what} {
	variable cacert
	variable dir

	set trust [file join $dir trusted]
	my openssl "x509 -hash -fingerprint -noout -addtrust $what -in $cacert" {trust cafn result} {
	    lassign [split $result "\n"] hash fingerprint

	    set suffix 0
	    while {[file exists [file join $trust $hash].$suffix]} {
		incr suffix
	    }

	    my link [file join $trust $hash].$suffix $cafn
	} $trust $cafn
    }

    # generate and return to Client a pkcs12
    # from a certificate and key of type
    method pkcs12 {r cert key type result} {
	variable cacert; variable cakey
	set cmd pkcs12
	lappend cmd -export
	lappend cmd -in $cert
	set fd [file tempfile fn]; close $fd
	lappend cmd -out $fn
	lappend cmd -name ${type}_Certificate
	lappend cmd -caname "WubCA"
	lappend cmd -certfile $cacert
	lappend cmd -inkey $key
	lappend cmd -passout pass:moop

	my openssl [join $cmd] {r fn result} {
	    set cert [fileutil::cat -- $fn]
	    #file delete $fn
	    Debug.ca {PKCS12: certificate [string length $cert] '$result'}
	    set r [Http NoCache $r]
	    Httpd Resume [Http Ok $r $cert application/x-pkcs12] 0
	    # application/x-x509-user-cert
	    # application/x-pkcs12
	} $r $fn
    }

    method decodeSID {text} {
	set subjk [string range $text [string first "X509v3 Subject Key Identifier:" $text] end]
	return [string trim [string map {: ""} [lindex [split $subjk \n] 1]]]
    }

    method decodeValidity {text} {
	set text [string range $text [string first "Not Before:" $text] end]
	set before [string trim [join [lrange [split [lindex $text 0] :] 1 end] :]]
	set after [string trim [join [lrange [split [lindex $text 0] :] 1 end] :]]
	return [list from [clock scan $before] to [clock scan $after]]
    }

    method decodeAuth {text} {
	set authk [split [string range $text [string first "X509v3 Authority Key Identifier:" $text] end] \n]
	dict set result akeyid [string trim [join [lrange [split [lindex $authk 1] :] 1 end] ""]]
	foreach i [split [lindex [split [lindex $authk 2] :] 1] /] {
	    set i [string trim $i]
	    if {$i eq ""} continue
	    lassign [split $i =] var val
	    dict set result authority [string trim $var] [string trim $val]
	}
	dict set result aserial [join [lrange [split [lindex $authk 3] :] 1 end] ""]
	return $result
    }

    method decodeCert {text} {
	set result [my decodeAuth $text]
	dict set result skeyid [my decodeSID $text]
	set text [string range $text 0 [string first "\n-----BEGIN CERTIFICATE-----" $text]]
	set text [split $text \n]
	dict set result hash [lindex $text end-1]
	dict set result serial [string toupper [string trim [string map {: ""} [lindex $text 2]]]]

	foreach {comp l} {issuer 4 subject 8} {
	    set line [lindex [split [lindex $text $l] :] 1]
	    foreach i [split $line ,] {
		lassign [split $i =] var val
		dict set result $comp [string trim $var] [string trim $val]
	    }
	}
	
	return [dict merge $result [my decodeValidity $text]]
    }

    # decode the response we get from openssl spkac
    method decodeSPKAC {text} {
	set result [my decodeAuth $text]
	dict set result skeyid [my decodeSID $text]
	return [dict merge $result [my decodeValidity $text]]
    }

    # generate a user or server request and certificate where we 
    # hold the keypair - not suitable for secure user certificates
    method generate {type name args} {
	# get continuation (if any)
	if {[llength $args]%2} {
	    set rest [lindex $args end]
	    set args [lrange $args 0 end-1]
	} else {
	    set rest {}
	}

	# generate certificate file name
	variable webdir
	variable type2ext
	set cert [file join $webdir $name].[dict get $type2ext $type]
	if {[file exists $cert]} {
	    error "$type cert '$name' already set up"
	}

	set cmd req
	lappend cmd -new -nodes
	variable ca_config; lappend cmd -config $ca_config
	lappend cmd -multivalue-rdn

	# we must create private key
	variable keybits
	variable private
	set key [file join $private $name].key
	lappend cmd -newkey rsa:$keybits -keyout $key

	set fd [file tempfile rqfn]; close $fd; lappend cmd -out $rqfn
	set subject [my subject OU [string totitle $type] CN $name {*}$args]
	lappend cmd -subj '$subject'

	my openssl [join $cmd] {cert key rest type rqfn result} {
	    # we have generated a request - now sign it
	    Debug.ca {new request: $result}
	    variable ca_config; variable cacert; variable cakey; variable days
	    set cmd x509
	    lappend cmd -req
	    lappend cmd -extfile $ca_config 
	    lappend cmd -in $rqfn -out $cert
	    lappend cmd -CA $cacert -CAkey $cakey -CAcreateserial
	    lappend cmd -extensions v3_$type
	    lappend cmd -days $days
	    my openssl [join $cmd] {cert key rest type rqfn result} {
		Debug.ca {signed: $result}
		file delete $rqfn	;# dispose of request
		if {[llength $rest]} {
		    # apply continuation (if any)
		    {*}$rest $cert $key $type $result
		}
	    } $cert $key $rest $type $rqfn
	} $cert $key $rest $type $rqfn

	return [list $cert $key]
    }

    # generate Certificate Authority keys and self-signed certificate
    method GenCA {args} {
	Debug.ca {GenCA $args}

	# generate a new request
	variable dir
	variable keybits
	variable cacert
	variable cakey
	variable ca_config
	variable webdir
	variable host

	# create CA's key and self-signed certificate
	set cmd req
	lappend cmd -nodes -x509 -new -out $cacert
	lappend cmd -config $ca_config
	lappend cmd -newkey rsa:$keybits -keyout $cakey
	set subj [my subject CN $host {*}$args]; lappend cmd -subj '$subj'
	lappend cmd -extensions v3_ca -reqexts v3_careq
	lappend cmd -days [expr {5 * 365}]
	my openssl [join $cmd] {subj result} {
	    # link the CA certificate to a web directory
	    variable webdir; variable cacert
	    my link [file join $webdir ca.cacert] $cacert
	    my getcert $cacert {cacert result} {
		puts stderr "CERT: ($result)"
		set cert [my decodeCert $result]
		dict set cert cert [::fileutil::cat -encoding binary $cacert]
		puts stderr "DECERT: $cert"
		file link -symbolic [file join [my cadir] [dict get $cert hash]].0 [file tail $cacert]
	    } $cacert
	} $subj
    }

    method spkac_parse {data} {
	set data [lassign [split $data \n] verify netscape algorithm bits modulus]
	dict set spkac valid [expr {$verify eq "Signature OK"}]
	if {![dict get $spkac valid]} {
	    Debug.spkac {SPKAC Invalid: $spkac}
	    return $spkac
	}

	Debug.spkac {PRE algorithm:'$algorithm' modbits:'$modulus' bits:'$bits'}
	set algorithm [regexp -inline {^.+: +(.+)$} $algorithm]
	set modulus [regexp -inline {[(]([0-9]+).+[)]} $modulus]
	set bits [regexp -inline {[(]([0-9]+).+[)]} $bits]
	Debug.spkac {POST algorithm:'$algorithm' modbits:'$modulus' bits:'$bits'}
	dict set spkac algorithm [lindex $algorithm end]
	dict set spkac modbits [lindex $modulus end]
	dict set spkac bits [lindex $bits end]

	set modulus ""
	foreach line $data {
	    if {[string index $line 2] ne " "} break
	    set data [lrange $data 1 end]
	    append modulus [string trim $line]
	}
	dict set spkac modulus $modulus

	set data [lassign $data line]
	lassign [regexp -inline {^[0-9]*\([0-9]+\) (\([0-9x]+\))} $line] exp1 exp2
	dict set spkac exp $exp1
	dict set spkac exp2 $exp2

	set data [lassign $data line]
	dict set spkac challenge [string trim [lindex [split $line :] 1]]
	dict set spkac sigalg [string trim [lindex [split $line :] 1]]

	set signature ""
	foreach line $data {
	    if {[string index $line 2] ne " "} break
	    set data [lrange $data 1 end]
	    append signature [string trim $line]
	}
	dict set spkac signature $signature

	Debug.spkac {SPKAC: $spkac}
	return $spkac
    }

    method spkac_sign {r tmpfn spkac udata args} {
	variable ca_config
	variable days
	Debug.caui {SPKAC signing}
	set cmd ca
	lappend cmd -config $ca_config
	lappend cmd -days $days -spkac $tmpfn -out $tmpfn.der
	lappend cmd {*}$args

	my openssl [join $cmd] {r tmpfn result} {
	    # sign the SPKAC file
	    Debug.ca {SIGNING: [split $result \n]}
	    file delete $tmpfn
	    file delete $tmpfn.der

	    set sn [regexp -inline {[0-9]+} [lindex [split $result \n] 4]]

	    if {$sn eq ""} {
		Httpd Resume [Http Ok $r $result text/plain] 0
	    } else {
		set cdata [my decodeSPKAC $result]
		Debug.ca {decode SPKAC: $cdata}
		variable dir
		set sn [format %02X $sn]
		set cf [file join $dir newcerts $sn].pem
		set cert [fileutil::cat -- $cf]

		set found [string first "X509v3 Subject Key Identifier" $result]
		set kid [string range $result $found end]
		set kid [string map {: "" " " ""} [lindex [split $kid \n] 1]]
		file copy $cf [file join $dir signed $kid].pem
		Debug.ca {serial: $sn key id:'$kid'}

		Debug.ca {SENDING CERT: [string length $cert]}
		Httpd Resume [Http Ok $r $cert application/x-x509-user-cert] 0
	    }
	} $r $tmpfn
    }

    method spkac_process {r cr args} {
	# create the SPKAC file
	set fd [file tempfile tmpfn]
	puts $fd "SPKAC=[string map {\n ""} $cr]"
	foreach {v n} {CN CN
	    emailAddress EMAIL
	    organizationName O
	    OU OU
	    localityName L
	    stateOrProvinceName ST
	    countryName C
	} {
	    if {[dict args.$n?] ne ""} {
		puts $fd "$v=[dict args.$n]"
	    }
	}
	close $fd

	# validate the spkac file
	Debug.ca {verifying SPKAC file: $tmpfn}
	my openssl "spkac -in $tmpfn -verify" {r udata tmpfn result} {
	    set spkac [my spkac_parse $result]
	    if {[dict get $spkac valid]} {
		my spkac_sign $r $tmpfn $spkac $udata
	    } else {
		Debug.caui {SPKAC invalid}
		Httpd Resume [Http Ok $r $spkac text/plain]
	    }
	} $r $args $tmpfn
    }

    method /keygen {r {cr ""} CN args} {
	Debug.caui {/keygen '$CN' $args}
	variable DN
	set args [dict merge {EMAIL ""} $DN $args]

	if {$cr ne ""} {
	    # we've been sent a certificate request form
	    my spkac_process $r $cr {*}$args CN $CN
	    return [Httpd Suspend $r]
	}

	dict with args {
	    set content [Form layout crmform action getkey {
		fieldset kg {
		    legend "Key Generation"
		    text CN label "Name: "
		    text EMAIL label "Email: "
		    <br>
		    text O label "Organization: "
		    text OU label "Unit: "
		    <br>
		    text L label "Locale: "
		    text ST label "State: "
		    <br>
		    text C label "Country: "
		    <br>
		    submit submit "Generate Key"
		    keygen cr challenge moop
		}
	    }]
	    append content [<div> output {}]
	    tailcall Http Ok [Http NoCache $r] $content x-text/html-fragment
	}
    }

    method /request {r {CN ""} args} {
	Debug.caui {/keygen '$CN' $args}
	variable DN
	set args [dict merge {EMAIL ""} $DN $args]

	if {$CN ne ""} {
	    # we've been sent a certificate request form
	    my generate user $CN {*}$args [list my pkcs12 $r]
	    return [Httpd Suspend $r]
	}

	dict with args {
	    set content [Form layout crmform vertical 1 {
		fieldset kg {
		    legend "Key Generation"
		    text CN label "Name: "
		    password password label "Password: "
		    submit submit
		}
	    }]
	    append content [<div> output {}]
	    tailcall Http Ok $r $content x-text/html-fragment
	}
    }

    method /cacert {r} {
	variable cacert
	return [Http File [Http NoCache $r] $cacert application/x-x509-ca-cert]
    }

    method /certificate {r args} {
	set cert [dict r.-extra?]
	variable webdir
	if {$cert eq ""} {
	    foreach f [glob -nocomplain -tails -directory $webdir *] {
		Debug.caui {certificate: $f}
		lappend result [<li> [<a> href $f $f]]
	    }
	    return [Http Ok $r [<ol> [join $result]] x-text/html-fragment]
	} else {
	    # specific certificate requested
	    my getcert [file join $webdir $cert] {r udata result} {
		Httpd Resume [Http Ok $r $result text/plain]
	    } $r $args
	    return [Httpd Suspend $r]
	}
    }

    method /certs {r args} {
	Debug.ca {request for certificate '[dict r.-extra]' ($args)}

	set cert [dict r.-extra?]
	variable webdir
	if {$cert eq ""} {
	    foreach f [glob -nocomplain -tails -directory $webdir *] {
		Debug.caui {certificate: $f}
		lappend result [<li> [<a> href $f $f]]
	    }
	    return [Http Ok $r [<ol> [join $result]] x-text/html-fragment]
	} else {
	    # specific certificate requested
	    return [Http File $r [file join $webdir $cert] application/x-x509-user-cert]
	}
    }

    method / {r} {
	foreach {name url descr} {
	    "CA Certificate" cacert "Use this to fetch our CA Certificate"
	    "Generate Certificate" keygen "Use this to generate your own Certificate"
	    "Display Certificates" certificate "Display some of our Certificates"
	    "Download Certificates" certificate "Download your Certificates (TODO)"
	} {
	    lappend result [<li> [<span> "[<a> href $url/ $name] - $descr"]]
	}
	return [Http Ok $r [<ul> [join $result]] x-text/html-fragment]
    }

    method cadir {} {
	variable dir
	Debug.ca {server trust dir requested: '[file join $dir private]'}
	return [file join $dir private]/
    }

    method cacert {} {
	variable cacert
	return $cacert
    }

    method servercert {{machine ""}} {
	if {$machine eq ""} {
	    variable host; set machine $host
	}
	variable webdir; variable type2ext
	set cert [file join $webdir $machine].[dict get $type2ext server]
	Debug.ca {server certificate requested for '$machine': '$cert'}
	return $cert
    }

    method serverkey {{machine ""}} {
	if {$machine eq ""} {
	    variable host; set machine $host
	}
	variable private; variable type2ext
	set key [file join $private $machine].key
	Debug.ca {serverkey requested for '$machine': '$key'}
	return $key
    }

    destructor {
	catch {my openssl destroy}
    }

    catch {superclass Direct}
    constructor {args} {
	# initialize the Certificate Authority
	variable dir [file join $::CA_dir CA] ;# directory for CA information
	# nb: this must be outside any web-accessible directory
	variable openssl ""		;# your openssl executable
	variable host [info hostname]	;# host for fetching our certificates
	variable port 8080		;# port for fetching our certificates

	variable keybits 2048	;# default certificate key size
	variable days 180

	variable mount /ca/
	catch {variable {*}[Site var? CA]}	;# allow .ini file to modify defaults
	variable {*}$args

	if {[dict exists $args mount]} {
	    next {*}$args	;# not running stand-alone
	}

	variable DN
	variable policy
	foreach {n v p} [subst {
	    C "AU" optional
	    ST "NSW" optional
	    L "Sydney" optional
	    O "Wub" optional
	    OU "CA" optional
	    CN $host supplied
	    EMAIL ca@host ""
	    givenName "" ""
	    initials "" ""
	}] {
	    dict set? DN $n $v
	    if {$p ne ""} {
		dict set? policy $n $p
	    }
	}

	# map type of cert to web extension
	variable type2ext {
	    ca cacert
	    server scert
	    user ucert
	    email ecert
	    objsign ucert
	    everything ucert
	}

	# web-accessible CA certificates
	if {![info exists url]} {
	    variable url [Url url -scheme http -host $host -port $port -path ${mount}certs/]
	}

	if {![info exists ocsp]} {
	    variable ocsp [Url url -scheme http -host $host -port $port -path ${mount}oscp/]
	}

	if {![info exists webdir]} {
	    variable webdir [file join $dir web]
	}

	# create web-accessible ca directory
	# which can deliver our certificates
	variable webdir
	if {![file exists $webdir]} {
	    file mkdir $webdir
	}

	# create private CA directory for storage of CA certificates
	variable private [file join $dir private]
	file mkdir [file join $dir private]
	file attributes $dir -permissions 0770	;# make private private

	# name ca certificate
	variable cacert [file join $private ca.cacert]
	variable cakey [file join $private ca.key]

	# generate openssl configuration files and interface
	variable ca_config [file join $dir ca.cnf]
	if {![file exists $ca_config]} {
	    my configuration
	}

	variable ossl [OpenSSL new]	;# openssl interface

	# construct the certificate store
	#variable store [CertStore new file [file join $dir store.db]]
	#oo::objdefine [self] forward store $store

	if {[file exists $cacert]} {
	} else {
	    # create CA directory structure for openSSL under $dir
	    # then generate our CA keys and our server key
	    file mkdir [file join $dir crl]		;# certificate revocation directory
	    file mkdir [file join $dir requests]	;# new requests directory
	    file mkdir [file join $dir newcerts]	;# new certificate directory
	    file mkdir [file join $dir signed]	;# signed certificate directory
	    file mkdir [file join $dir spkac]		;# spkac request directory
	    file mkdir [file join $dir trusted]		;# trusted CAs
	    
	    ::fileutil::writeFile [file join $dir crlnumber] 0	;# crlnumber file

	    ::fileutil::writeFile [file join $dir index.txt] ""	;# empty index file
	    ::fileutil::writeFile [file join $dir serial] 00	;# create a serial file

	    # generate CA certificate into our private space
	    my GenCA

	    # make server certificate under CA
	    variable server_cert; variable server_key
	    lassign [my generate server $host] server_cert server_key
	    my generate server localhost
	}
    }
}

if {[info exists argv0] && ([info script] == $argv0)} {
    # unit test - standalone load
    Debug on ca 10
    #Debug on config 10
    Debug on error 10

    CA create ca dir [file join [pwd] CATEST]
    ca getcert [file join [pwd] CATEST private ca.cacert]

    Debug.ca {create server certificate 2}
    ca generate server localhost
    Debug.ca {create server certificate 3}
    ca generate server fred
    if {0} {
	Debug.ca {create user certificate - DOES NOT WORK}
	ca generate user "A User"
    }
    set forever 0
    vwait forever
    if {0} {
	ca prime CN [info host]
	ca openssl genrsa -out server-private.pem 1024
	ca openssl req -new -x509 -key server-private.pem -out server-public.pem -days 365 -config 
    }
}
