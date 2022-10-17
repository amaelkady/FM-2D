# hello-direct - a hello world example of a Direct domain
namespace eval ::Hello {

    proc / {r args} {
	# this is the default
	set content {
	    <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
	    <html>
	    <head>
	    <title>Hello World</title>
	    </head>
	    <body>
	    <h1>Hello World</h1>
	    <p>This is a demonstration of a Direct domain.  The examples below become progressively more ornate<p>
	    <ul>
	    <li><a href='text'>Plain Text</a></li>
	    <li><a href='html'>Html Fragment</a></li>
	    <li><a href='error'>Intentional Error</a></li>
	    <li><a href='redirect'>Redirection</a></li>
	    <li><a href='nowhere'>Non-existent element</a></li>
	    <li><a href='form'>Form sample with CSS</a></li>
	    <li><a href='form?css=0'>Form sample without CSS</a></li>
	    <li><a href='show'>Display arguments passed in.</a></li>
	    </body>
	    </html>
	}
	return [Http Ok $r $content text/html]
    }

    proc /text {r args} {
	# [Http Ok] can return other mime types:
	# Here, text/plain can be used to return just the literal text
	set content {
	    <p>Hello World</p>
	}
	return [Http Ok $r $content text/plain]
    }

    proc /html {r args} {
	# Here, content is returned as an x-text/html-fragment
	# which is wrapped and filled in by the Convert module
	# to present an HTML page to the client
	set content {
	    <p>Hello World</p>
	}
	return [Http Ok $r $content x-text/html-fragment]
    }

    proc /html2 {r args} {
	# Here, /html is repeated using the [Html] utility
	set content [<p> "Hello World"]
	return [Http Ok $r $content x-text/html-fragment]
    }

    proc /show {r {css 1} args} {
	# Here we display the args passed from the client
	# we use the utilities from [Html] to construct the page
	append content [<h2> class pretty "Form Submission Result"]

	append vartable [<tr> "[<th> Var] [<th> Value]"] \n
	foreach {n v} $args {
	    append vartable [<tr> "[<td> $n] [<td> $v]"] \n
	}
	append content [<table> border 1 class pretty $vartable]

	if {$css} {
	    set r [Html style $r css]	;# this adds a css styling to an html-fragment
	}
	return [Http Ok $r $content]	;# we default mime type
    }

    proc /css {r args} {
	set css {
	    * {zoom: 1.0;}
	    body {
		width: 80%;
		margin-left:10%;
	    }
	    input.blur {
		color:lightgray;
	    }
	    img.icon {
		border:0px;
		width:25px
	    }

	    div.nav {
		float:right;
		background: whitesmoke;
		padding: 0.3em 0.7em;
		-moz-border-radius-topleft:5px;
		-moz-border-radius-topright:5px;
		-moz-border-radius-bottomleft:5px;
		-moz-border-radius-bottomright:5px;
	    }
	    h1.pretty, h2.pretty, h3.pretty, h4.pretty, h5.pretty, h6.pretty {
		background: darkslategray;
		color: whitesmoke;
		padding: 0.2em 0.5em;
		-moz-border-radius-topleft:7px;
		-moz-border-radius-topright:7px;
		-moz-border-radius-bottomleft:7px;
		-moz-border-radius-bottomright:7px;
	    }
	    table.pretty {
		margin: 1em 1em 1em 2em;
		background: whitesmoke;
		border-collapse: collapse;
	    }
	    table.pretty td {
		border: 1px silver solid;
		padding: 0.2em;
	    }
	    table.pretty th {
		border: 1px silver solid;
		padding: 0.2em;
		background: darkslategray;
		color: white;
		text-align: left;
		-moz-border-radius-topleft:7px;
		-moz-border-radius-topright:7px;
		-moz-border-radius-bottomleft:7px;
		-moz-border-radius-bottomright:7px;
	    }
	    table.pretty tr.family {
		background: gainsboro;
	    }
	    table.pretty caption {
		margin-left: inherit;
		margin-right: inherit;
		font-size: 150%;
	    }

	    fieldset {
		background: whitesmoke;
		margin-bottom: 1em;
		-moz-border-radius-topleft:7px;
		-moz-border-radius-topright:7px;
		-moz-border-radius-bottomleft:7px;
		-moz-border-radius-bottomright:7px;
	    }

	    fieldset > legend {
		background: darkslategray;
		color: white;
		padding-left: 0.5em;
		padding-right: 0.5em;
		padding-top: 0.25em;
		padding-bottom: 0.25em;
		-moz-border-radius-topleft:5px;
		-moz-border-radius-topright:5px;
		-moz-border-radius-bottomleft:5px;
		-moz-border-radius-bottomright:5px;
	    }
	}

	return [Http Ok $r $css text/css]
    }

    proc /form {r {css 1} args} {
	# here we will display whatever args are passed in.
	# we also use the [Form] utility to construct the page
	set content [<h2> class pretty "Sample Form"]
	dict with args {
	    append content [<form> xxx action show {
		[<p> "This is a form to enter your account details"]
		[<fieldset> details vertical 1 title "Account Details" {
		    [<legend> "Account Details"]
		    [<text> user label "User name" title "Your preferred username (only letters, numbers and spaces)"]
		    [<text> email label "Email Address" title "Your email address" moop]
		    [<hidden> hidden moop]
		}]
		[<fieldset> passwords maxlength 16 size 16 {
		    [<legend> "Passwords"]
		    [<p> "Type in your preferred password, twice.  Leaving it blank will generate a random password for you."]
		    [<password> password]
		    [<password> repeat]
		}]
		[<radioset> illness legend "Personal illnesses" {
		    +none 0
		    lameness 1
		    haltness 2
		    blindness 2
		}]
		[<checkset> illness vertical 1 legend "Personal illnesses" {
		    +none 0
		    lameness 1
		    haltness 2
		    blindness 2
		}]
		[<select> selname legend "Shoe Size" title "Security dictates that we know your approximate shoe size" {
		    [<option> value moop1 label moop1 value 1 "Petit"]
		    [<option> label moop2 value moop2 value 2 "Massive"]
		}]
		[<fieldset> personal tabular 1 legend "Personal Information" {
		    [<text> fullname label "full name" title "Full name to be used in email."] [<text> phone label phone title "Phone number for official contact"]
		}]
		[<fieldset> permissions -legend Permissions {
		    [<fieldset> gpermF style "float:left" title "Group Permissions." {
			[<legend> Group]
			[<checkbox> gperms title "Can group members read this page?" value 1 checked 1 read]
			[<checkbox> gperms title "Can group members modify this page?" value 2 checked 1 modify]
			[<checkbox> gperms title "Can group members add to this page?" value 4 checked 1 add]
			[<br>][<text> group title "Which group owns this page?" label "Group: "]
		    }]
		    [<fieldset> opermF style "float:left" title "Default Permissions." {
			[<legend> Anyone]
			[<checkbox> operms title "Can anyone read this page?" value 1 checked 1 read]
			[<checkbox> operms title "Can anyone modify this page?" value 2 modify]
			[<checkbox> operms title "Can anyone add to this page?" value 4 add]
		    }]
		}]
		[<div> class buttons [<submit> class positive {
		    [<img> src /images/icons/tick.png alt ""] Save
		}]]
	    }]
	}

	if {$css} {
	    set r [Html style $r css]	;# this adds a css styling to an html-fragment
	}
	return [Http Ok $r $content x-text/html-fragment]
    }

    proc /error {r args} {
	# errors are caught and presented to the client
	error "This is an intentional error."
    }

    proc /redirect {r args} {
	# You can redirect URLs using the facilities of the Http utility
	return [Http Moved $r html]	;# this redirects you to /hello
    }

    # Nub will call this with args presented to the Nub
    proc new {args} {
	# we do nothing with the args
    }

    namespace export -clear *
    namespace ensemble create -subcommands {}
}

# this Nub inserts the Hello namespace into the URL space at /hello/
Nub domain /hello/ Direct namespace ::Hello
