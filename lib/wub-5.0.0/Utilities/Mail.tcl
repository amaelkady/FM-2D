# Mail - Mail Form for Wub - fairly thin interface to SMTP package
package require Debug
Debug define mail 10

package require SMTP
package require Form
package require mime

package provide Mail 1.0

set ::API(Utilities/Mail) {
    {
	Mail front-end for SMTP client
    }
}

namespace eval ::Mail {

    proc check {email} {
	if {[catch {::mime::parseaddress $email} x eo]} {
	    return "The email address '$email' is incorrectly formatted ($x)"
	}
	set check [lindex $x 0]
	if {[dict get? $check domain] eq ""} {
	    return "The email address '$email' is incomplete (nothing after the '@'.)"
	}
	return [dict get? $check error]
    }

    # return a form suitable for Web display
    proc form {args} {
	set vars {from {} to {} content {} action . subject {} style {} title {Send Email}}
	foreach n [dict keys $vars] {
	    set d($n) 0
	}
	foreach n [dict get? $args disable] {
	    set d($n) 1
	}
	catch {dict unset args disable}

	set vars [dict merge $vars $args]
	dict with vars {
	    return [<form> email class autoform {*}$style action $action [<fieldset> emfs {
		[<legend> $title]
		[<text> subject title "Subject of Email" disable $d(subject) legend Subject: $subject]
		[<text> to title "Recipient Email Address" disable $d(to) legend To: $to]
		[<text> from title "Your Email Address" disable $d(from) legend From: $from]
		[<textarea> content title "Your Message" style {width:80%} disable $d(content) legend Message: $content]
		[<submit> _go style {float:right} "Cancel"]
		[<submit> _go style {float:right} "Send"]
	    }]]
	}
    }

    # interface to SMTP to send the message.
    proc send {args} {
	set content [dict get $args content]; dict unset args content
	set smtp [dict get $args smtp]; dict unset args smtp
	return [$smtp simple {*}$args $content]
    }

    proc new {args} {return ::Mail}

    namespace export -clear *
    namespace ensemble create -subcommands {}
}
