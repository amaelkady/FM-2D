# OAuth.tcl - a domain for OAuth (http://oauth.net/)

package require TclOO
namespace import oo::*

package require Debug
Debug define OAuth 10
Debug define OAuthUtils 10

package require HTTP
package require tls
package require md5
package require sha1
package require base64
package provide OAuth 1.0

set API(Domains/OAuth) {
    {OAuth protocol
	=== Example ===
	Nub domain /oauth/ {OAuth ::oa} providers {peer-name {realm REALM requesturi REQUEST_TOKEN_URI authorizeuri AUTHORIZE_URI accessuri ACCESS_TOKEN_URI callback CALLBACK signmethod SIGN_METHOD reqmethod REQUEST_METHOD key YOUR_CONSUMER_KEY secret YOUR_CLIENT_SECRET} ...} 
    }
}

namespace eval OAuthUtils {
    # Characters not in the unreserved character set MUST be encoded. 
    # Characters in the unreserved character set MUST NOT be encoded. 
    # Hexadecimal characters in encodings MUST be upper case.
    #   unreserved = ALPHA, DIGIT, '-', '.', '_', '~'
    proc init_map {} {
	variable map
	variable dmap
	set map {- -}
	set dmap {- -}

	# set up the map
	for {set i 1} {$i < 256} {incr i} {
	    set c [format %c $i]
	    if {![string match {[a-zA-Z0-9._~]} $c]} {
		if {![dict exists $map $c]} {
		    lappend map $c %[format %.2X $i]
		}
		lappend dmap %[format %.2X $i] [binary format c $i]
		lappend dmap %[format %.2x $i] [binary format c $i]
	    }
	}
    }

    variable map
    variable dmap
    init_map

    proc 2hex {str} {
	binary scan $str H* hex
	return $hex
    }

    # decode
    #
    #	This decodes data in OAuth parameter format.
    #
    # Arguments:
    #	An encoded value
    #
    # Results:
    #	The decoded value
    
    proc decode {str} {
	Debug.OAuthUtils {decode '$str' [2hex $str]} 10
	variable dmap
	set str [string map $dmap $str]
	Debug.OAuthUtils {decode dmap '$str' [2hex $str]} 10

	return $str
    }

    proc decodeD {str} {
	set result [dict create]
	foreach {x} [split [string trim $str] &] {
	    # Turns out you might not get an = sign,
	    # especially with <isindex> forms.
	    set z [split $x =]
	    if {[llength $z] == 1} {
		# var present without assignment
		set var [decode [lindex $z 0]]
		set val ""
	    } else {
		# var present with assignment
		set var [decode [lindex $z 0]]
		set val [decode [join [lrange $z 1 end] =]]
	    }
	    
	    dict lappend result $var $val
	}
	return $result
    }

    # encode
    #
    #	This encodes data according to OAuth parameter format.
    #
    # Arguments:
    #	A string
    #
    # Results:
    #	The encoded value

    proc encode {string} {
	variable map
	# map non-ascii characters away - note: % must be first
	Debug.OAuthUtils {encode '$string'}
	set string [string map $map $string]
	Debug.OAuthUtils {encode post '$string'}
	return $string
    }

    # encode dict per OAuth spec
    proc encodeD {args} {
	if {[llength $args] == 1} {
	    set args [lindex $args 0]
	}
	set pairs {}
	foreach {n v} $args {
	    lappend pairs "[OAuthUtils encode $n]=[OAuthUtils encode $v]"
	}
	return [join $pairs &]
    }

    proc authhead {args} {
	if {[llength $args] == 1} {
	    set args [lindex $args 0]
	}
	set pairs {}
	foreach {n v} $args {
	    lappend pairs "[OAuthUtils encode $n]=\"[OAuthUtils encode $v]\""
	}
	return [join $pairs {, }]
    }

    proc sign_request {req provider {token_secret {}}} {
	# normalize request parameters
	# > sort
	dict unset req oauth_signature
	foreach key [lsort [dict keys $req]] {
	    lappend sorted $key [dict get $req $key]
	}

	# > concat
	set query [OAuthUtils encode [OAuthUtils encodeD $sorted]]
	Debug.OAuth {Sorted query is $query}
	set url [OAuthUtils encode [Url url [Url parse [dict get $provider requesturi]]]]
	Debug.OAuth {Url is $url}
	lappend secrets [OAuthUtils encode [dict get $provider secret]]
	lappend secrets [OAuthUtils encode $token_secret]
	set secrets [join $secrets &]
	Debug.OAuth {Secrets are $secrets}
	set base [OAuthUtils encode [dict get $provider reqmethod]]
	Debug.OAuth {Signature base string is $base&$url&$query}
	set signature [OAuthUtils encode [base64::encode [::sha1::hmac -bin $secrets "$base&$url&$query"]]]
	Debug.OAuth {Signature is $signature}
	return $signature
    }

    namespace export -clear *
    namespace ensemble create -subcommands {}
}

class create OAuth {
    method request_temp_credentials {r provider {override {}}} {
	set timestamp [clock seconds]
	set authtype [dict get? $provider authtype]
	set nonce [::md5::md5 -hex "$timestamp[clock milliseconds]"]

        foreach {n v} $override {
	    set $n $v
	}

	set reqd [list oauth_version 1.0 oauth_nonce $nonce oauth_timestamp $timestamp oauth_consumer_key [dict get $provider key] oauth_callback [dict get $provider callback] oauth_signature_method [dict get $provider signmethod]]

	# dict unset reqd oauth_callback

	set req_url [dict get $provider requesturi]

	set req_urld [Url parse $req_url]

	Debug.OAuth {req_urld: $req_urld}
	set queryd [Query flatten [Query parse $req_urld]]

	set sign_reqd [dict merge $reqd $queryd]
	Debug.OAuth {reqd: $reqd}

	dict set reqd oauth_signature [OAuthUtils sign_request $sign_reqd $provider]

	Debug.OAuth {Request dict is $reqd}

	switch $authtype {
	    header {
		set headers [list Authorization "OAuth [OAuthUtils authhead $reqd]"]
		Debug.OAuth {Requesting via header: $headers}
		set entity {}
	    }
	    url -
	    uri {
		dict set req_urld -query [Query encodeL [dict merge [Query flatten [Query parse $req_urld]] $reqd]]
		Debug.OAuth {Requesting via URI: $req_urld}
		set headers {}
		set entity {}
	    }
	    post -
	    entity {
		set headers {content-type application/x-www-form-urlencoded}
		set entity [Query encodeL $reqd]
		Debug.OAuth {Requesting via entity: $entity}
	    }
	}

	Debug.OAuth {Url http: [Url http $req_urld]}

	set V [HTTP new [dict get $provider requesturi] [lambda {v} [string map [list %SELF [self] %R $r %PROVIDER $provider] {
	    set r [list %R]
	    set provider [list %PROVIDER]
	    Debug.OAuth {V: $v}
	    set result [lindex [split [dict get $v -content] \n] 0]
	    set result [OAuthUtils decodeD $result]
	    Debug.OAuth {Result: $result}
	    set authurl [Url parse [dict get $provider authorizeuri]]
	    set query [Query flatten [Query parse $authurl]]
	    dict set query oauth_token [dict get? $result oauth_token]
            set token [base64::encode [::sha1::hmac -bin [clock seconds] $provider[dict get? $result oauth_token]]]
	    dict set query oauth_callback "[string trimright [dict get $r -url] /]/$token"
	    Debug.OAuth {query is $query}
	    dict set authurl -query [Query encodeL $query]
	    set authurl [Url uri $authurl]
	    Debug.OAuth {authurl is $authurl}
	    %SELF set-token-info $token token [dict get? $result oauth_token]
	    %SELF set-token-info $token provider $provider
	    %SELF set-token-info $token timestamp [clock seconds]

	    # return [Httpd Resume $r] ; # [[Http Redirect $r $authurl Redirect text/plain]]
	    return [Httpd Resume [Http Redirect $r $authurl Redirect text/plain]]
	}]] [string tolower [dict get $provider reqmethod]] [list [Url http $req_urld] $entity {*}$headers]]
	return [Httpd Suspend $r 100000]
	#
    }

    method request_access_token {r provider tokenid token {override {}}} {
	set timestamp [clock seconds]
	set authtype [dict get? $provider authtype]
	set nonce [::md5::md5 -hex "$timestamp[clock milliseconds]"]

        foreach {n v} $override {
	    set $n $v
	}

	set reqd [list oauth_version 1.0 oauth_nonce $nonce oauth_timestamp $timestamp oauth_consumer_key [dict get $provider key] oauth_signature_method [dict get $provider signmethod] oauth_token $token]

	# dict unset reqd oauth_callback

	set req_url [dict get $provider requesturi]

	set req_urld [Url parse $req_url]

	Debug.OAuth {req_urld: $req_urld}
	set queryd [Query flatten [Query parse $req_urld]]

	set sign_reqd [dict merge $reqd $queryd]
	Debug.OAuth {reqd: $reqd}

	dict set reqd oauth_signature [OAuthUtils sign_request $sign_reqd $provider]

	Debug.OAuth {Request dict is $reqd}

	switch $authtype {
	    header {
		set headers [list Authorization "OAuth [OAuthUtils authhead $reqd]"]
		Debug.OAuth {Requesting via header: $headers}
		set entity {}
	    }
	    url -
	    uri {
		dict set req_urld -query [Query encodeL [dict merge [Query flatten [Query parse $req_urld]] $reqd]]
		Debug.OAuth {Requesting via URI: $req_urld}
		set headers {}
		set entity {}
	    }
	    post -
	    entity {
		set headers {content-type application/x-www-form-urlencoded}
		set entity [Query encodeL $reqd]
		Debug.OAuth {Requesting via entity: $entity}
	    }
	}

	Debug.OAuth {Url http: [Url http $req_urld]}

	set V [HTTP new [dict get $provider requesturi] [lambda {v} [string map [list %SELF [self] %TOKENID $tokenid %R $r %PROVIDER $provider] {
	    set r [list %R]
	    set provider [list %PROVIDER]
	    Debug.OAuth {V: $v}
	    set result [lindex [split [dict get $v -content] \n] 0]
	    set result [OAuthUtils decodeD $result]
	    Debug.OAuth {Result: $result}

            return [Httpd Resume [Http Ok+ $r "token=[dict get? $result oauth_token], secret=[dict get? $result oauth_token_secret]"]]
	}]] [string tolower [dict get $provider reqmethod]] [list [Url http $req_urld] $entity {*}$headers]]
	return [Httpd Suspend $r 100000]
	#
    }


    method set-token-info {id k v} {
        dict set tokens $id $k $v
    }
    
    method / {r} {
	set suffix [string trim [dict get? $r -suffix] /]
	# clean up expired tokens --- todo
	if {$suffix eq ""} {
	    set queryd [Query flatten [Query parse $r]]
	    set provider [dict get $queryd provider]
	    return [my request_temp_credentials $r [dict get $providers $provider]]
	} else {
	    if {![dict exists $tokens $suffix]} {
		return [Http NotFound $r {Session not found} text/plain]
	    } else {
		set queryd [Query flatten [Query parse $r]]
                set result [my request_access_token $r [dict get $tokens $suffix provider] $suffix [dict get? $queryd oauth_token]]
		dict unset tokens $suffix
		return $result
	    }
	}
    }

    mixin Direct
    variable mount providers tokens

    # the tokens array contains data needed to continue OAuth sequence together with timestamp

    constructor {args} {
	set mount ""
        set tokens ""
	foreach {n v} $args {
	    set $n $v
	}
	if {$providers eq ""} {
	    error "OAuth requires the list of service providers"
	}
    }
}

if {0} {
    # example of OAuth provider description
    domain /oauth {OAuth oa} providers {peer {requesturi http://www.openstreetmap.org/oauth/request_token authorizeuri http://www.openstreetmap.org/oauth/authorize accessuri http://www.openstreetmap.org/oauth/access_token callback http://yourconsumer.org/oauth/ signmethod HMAC-SHA1 reqmethod POST key your-key secret your-secret authtype entity}}
}
