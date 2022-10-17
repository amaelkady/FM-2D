# Auth.tcl
#
# Provides Authentication, per http://www.ietf.org/rfc/rfc2617.txt

package require base64
package require Login
package require Debug
Debug define auth 10

package provide Auth 1.0

set ::API(Utilities/Auth) {
    {
	Facilities for HTTP Auth
    }
}

namespace eval ::Auth {
    variable passwd	;# special purpose in-place passwd
    array set passwd {}

    namespace eval Basic {
	proc challenge {req realm} {
	    return "Basic realm=\"$realm\""
	}

	proc authenticate {cred} {
	    lassign [split [::base64::decode $cred] :] user password
	    Debug.auth {Basic auth '$cred' -> user:$user password:$password}
	    if {$user eq "" || $password eq ""} {
		error "No Null users or passwords"
	    }

	    if {[info exists ::Auth::passwd($user)]} {
		if {$::Auth::passwd($user) eq $password} {
		    Debug.auth {password match: $user $password}
		    return 1
		} else {
		    Debug.auth {password '$password' does not match $::Auth::passwd($user)}
		}
	    } else {
		Debug.auth {inbuilt: [array names ::Auth::passwd]}
	    }
	    Login /login $user $password
	}

	namespace export -clear *
	namespace ensemble create -subcommands {}
    }

    namespace eval Digest {
	namespace export -clear *
	namespace ensemble create -subcommands {}
    }
    proc got? {req} {
	return [dict exists $req authorization]
    }

    proc ok? {req} {
	foreach auth [split [dict get? $req authorization] ,] {
	    Debug.auth {authenticate: $auth}
	    set cred [join [lassign [split $auth] kind]]
	    if {![catch {
		switch -- [string tolower $kind] {
		    basic {
			Basic authenticate $cred
		    }
		    digest {
		    }
		    default {
		    }
		}
	    } r eo]} {
		return 1
	    } else {
		Debug.auth {Auth Failed: $r ($eo)}
	    }
	}
	return 0
    }

    namespace export -clear *
    namespace ensemble create -subcommands {}
}

#set ::Auth::passwd(colin) MOOP

