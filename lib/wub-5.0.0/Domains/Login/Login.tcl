# Login is a domain to handle simple login account handling

package require TclOO
namespace import oo::*

set ::API(Domains/Login) {
    {
	Simple cookie-based login account management and is simultaneously a repository for field values keyed by user.

	== Operation ==
	Login provides a /login url to authenticate a user by password, and generate a cookie recording this authentication.  /logout removes the login cookies.

	/login can operate in a ''permissive'' mode (which allows anonymous account creation,) but the default response to non-existent user is to redirect to the url /new which will collect account information construct a new user.

	The provided /new will refuse to create duplicate users, and also refuse blank users and (by default) blank passwords.

	The /logout url will remove all the login cookies, logging the user out.

	Login also provides a /form url which either returns a form suitable to /login, or a button to /logout a user.

	=== URLs ===
	The Login domain provides the following URLs:

	;/login args: logs in the current user, must specify user and password fields
	;/logout {url ""}: logs out the current user, then redirects to specified url
	;/form: returns a login form or a logout link, depending on current login status
	;/new: args stores a new user's data - the user must be unique.

	== Repository ==
	Login also functions as a repository for form data associated with logged-in users.  You can easily store and data from <form>s and fetch them for javascript processing.

	The /set URL stores any data it is passed in the account View of the logged-in user.  It's intended to be invoked from a simple <form>.

	The /get method returns all account data in JSON format, suitable for AJAX processing.

	The data stored with /set doesn't have to be declared: any fields which appear explictly in the account db layout can be searched and manipulated by server db code, and any other fields and values are stashed as a tcl dict in the ''args'' field of the account record (if it is specified in the db layout.)  This makes Login a general purpose store for associating data with a logged in user.

	=== URLS ===
	;/get {fields ""}: returns JSON object containing specified account information fields for logged-in user (default: all fields).
	;/set args: sets account information for logged-in user, suitable for use as the action in a <form>

	== Database ==
	Login requires an account [http:../Utility/View View] which contains at least ''user'' and ''password'' fields, these are the minimum to allow a user to log in.  In addition, a field password_old is available as a fallback password, useful in the case of incomplete password changes.  Any other fields in the View are available to be stored and fetched by /set and /get (respectively.)

	== Methods ==
	;user r {user ""}: fetches account record of the specified user, or the logged-in user if no user is specified.  If the data can't be fetched (if, for example, there's no user logged in) then this method returns an empty list.  This can be reliably used to determine the identity of a logged-in user.
	;set r args: sets fields in the account record of user according to the dict in $args.
	;account args: evaluates args over the account [View] or (if empty args) returns the [View].  This can be used to process the account database.
	;clear r: clears any login cookies for this instance of Login - effectively logging user out
	;login r index {user ""} {password ""}: performs login from code, given at least account index of user to log in.

	== Forms ==
	Login requires several predefined forms, and these can be overriden with a ''forms'' configuration variable whose value is some or all of the forms in a dictionary.

	;forms login: is returned by /form to allow login.  It must at least provide the ''user'' and ''password'' variables.
	;forms logout: is returned by /form to allow logout.  It should allow the user to invoke the /logout url.
	;forms new: is used by /new, when a new account is to be created.  It may collect and deliver any variable/values to /new, all of which will be stored with the user.  It must at least provide the ''user'' and ''password'' variables.
	;forms logmsg: is used to indicate errors and successes.

	== Example ==
	This code illustrates how Login can be used to control the domain /cookie/

	package require Login

	# create a Login object called ::L which uses the account view
	# to store user account data.
	# it will commit to the account db immediately upon each modification
	# it will service the /cookie/ domain, enabling any url handler under /cookie/
	# access to the account db
	Login ::L account {
	    db accountdb file account.db layout {user:S password:S args:S}
	} cpath /cookie/ jQ 1 autocommit 1 ctype x-text/html-fragment

	# this is a test page for Login.  It will permit you to log in with a new account,
	# (invoking /new for collection of account information) and will display the user
	# account information recorded in the database for user.
	Nub code /login/test {
	    set r [::L /form $r]	;# the result of this nub will be a login or logout form
	    set user [::L get $r]	;# get the account record of the user (if any)

	    # add some output to the field content
	    set result [dict get $r -content]
	    append result [<div> id message {}]	;# add a message div for feedback
	    append result [<p> "User: $name"]	;# display the account data
	}

	=== Referenced in Examples ===
	;[http:Nub domain]: a command which construct a nub, mapping a URL-glob onto a domain handler (in this case, Coco.)
	;<*>: commands of this form are defined by the [http:../Utility/Html Html] generator package and the [http:../Utility/Form Form] generator package.

    }
    account {View for storing accounts (must have at least user and password fields)}
    cookie {cookie for storing tub key (default: tub)}
    age {cookie age}
    domain {domain covered by login cookie}
    cpath {list of paths for login cookie}
    emptypass {boolean - are passwords required to be non-blank (default: 0, of course)}
    realm {Realm used in password challenges for AUTH based login}
    permissive {boolean - completely anonymous accounts?}
    autocommit {boolean - commit on each write?}
    jQ {boolean - use jQuery javascript for interactions? (default: yes.)  Depends on [http:JQ jQ module]}
}

package require Debug
Debug define login 10

package require md5
package require Direct
package require View
package require Cookies

package provide Login 1.0

class create ::Login {
    # stmt - evaluate tdbc statement
    # caches prepared statements
    method stmt {stmt args} {
	if {[llength $args] == 1} {
	    set args [lindex $args 0]
	}

	variable stmts	;# here are some statements we prepared earlier
	if {[dict exists $stmts $stmt]} {
	    set s [dict get $stmts $stmt]
	} else {
	    set s [db prepare $stmt]
	    dict set stmts $stmt $s
	}

	Debug.loginsql {stmt '$stmt'}
	set result [$s allrows -as dicts $args]
	Debug.loginsql {stmt result: '$stmt' -> ($result)}
	return $result
    }

    # stmtL - evaluate tdbc statement
    # caches prepared statements
    method stmtL {stmt args} {
	if {[llength $args] == 1} {
	    set args [lindex $args 0]
	}

	variable stmts	;# here are some statements we prepared earlier
	if {[dict exists $stmts $stmt]} {
	    set s [dict get $stmts $stmt]
	} else {
	    set s [db prepare $stmt]
	    dict set stmts $stmt $s
	}
	
	set result [$s allrows -as lists $args]
	Debug.loginsql {stmtL result: '$stmt' -> ($result)}
	return $result
    }

    method Db_load {} {
	# load the tdbc drivers
	variable tdbc
	package require $tdbc
	package require tdbc::$tdbc
	
	variable file
	variable opts
	variable db [tdbc::${tdbc}::connection create [namespace current]::db $file {*}$opts]

	if {![llength [db tables login]]} {
	    # we don't have a stick table - make one
	    db allrows {
		PRAGMA foreign_keys = on;

		-- login table - associates user with uid and password
		CREATE TABLE login (uid INTEGER PRIMARY KEY AUTOINCREMENT,	-- user id
				    name TEXT COLLATE NOCASE,	-- user name - null for anon
				    password TEXT,	-- new password
				    opassword TEXT,	-- old password
				    last INTEGER DEFAULT CURRENT_TIMESTAMP	-- last login
				    created INTEGER DEFAULT CURRENT_TIMESTAMP	-- when created
				    );
		CREATE UNIQUE INDEX user ON login(user);

		-- mapping from cookies to uid
		CREATE TABLE cookies (uid INTEGER NOT NULL,
				   cookie TEXT UNIQUE NOT NULL,
				   created INTEGER DEFAULT CURRENT_TIMESTAMP	-- when created
				   FOREIGN KEY (uid) REFERENCES login(uid)
				   );
		CREATE UNIQUE INDEX uidkey ON cookies(uid,cookie);

		-- vars associated with user
		CREATE TABLE vars (uid INTEGER NOT NULL,
				   var TEXT NOT NULL,
				   value TEXT NOT NULL,
				   FOREIGN KEY (uid) REFERENCES login(uid)
				   );
		CREATE UNIQUE INDEX uidvar ON vars(uid,var);
	    }
	}

	variable columns [$db columns login]
	Debug.login {Login table columns: $columns}
	Debug.login {Database tables:([$db tables])}
    }


    # get account record of logged-in user
    method get {r {user ""}} {
	if {$user eq ""} {
	    variable cookie
	    variable domain

	    # don't know which user yet - use the cookie
	    set cdict [dict get? $r -cookies]

	    # determine the right domain/path for the cookie
	    set cd [list -name $cookie]
	    if {[info exists domain] && $domain ne ""} {
		dict set cd -domain $domain
	    }

	    Debug.login {logged in user in $cdict}

	    # fetch the cookie
	    if {![catch {Cookies fetch $cdict -name $cookie} cl]} {
		set key [dict get $cl -value]	;# cookie contains session key
		set uid [lindex [my stmtL {
		    SELECT uid FROM cookies WHERE cookie == :key
		} key $key] 0]
		Debug.login {key '$key' -> ($result)}

		if {$uid eq ""} {
		    Debug.login {bogus key: $key}
		    error "session cookie '$cookie' has expired"
		}
	    } {
		# there's no logged-in user here
		Debug.login {no user logged in under cookie '$cookie'}
		error "No user logged in under '$cookie'"
	    }

	    set op "get by uid '$uid' from cookie '$key'"
	    set record [my stmt {
		SELECT * FROM login WHERE uid == :uid
	    } uid $uid]
	} elseif {[string is integer -strict $user]} {
	    # passed in user name - search for it
	    set op "get by uid '$user'"
	    set record [my stmt {
		SELECT * FROM login WHERE uid == :uid
	    } uid $user]
	} else {
	    # passed in user name - search for it
	    set op "get by name '$user'"
	    set record [my stmt {
		SELECT * FROM login WHERE name == :name
	    } name $user]
	}
	if {![llength $record]} {
	    error "Failed: $op"
	}

	set record [lindex $record 0]	;# we only expect one user record
	Debug.login {$op: ($record)}

	# fetch the extra vars
	variable columns
	foreach {var value} [my stmtL {
	    SELECT * FROM vars WHERE (uid == :uid)
	} uid [dict get $record uid]] {
	    if {![dict exists $columns $var]} {
		dict set record $var $value
	    }
	}

	return $record
    }

    # set account record of logged-in user
    method set {r args} {
	if {[dict exists $args uid]} {
	    # specified user by uid
	    set record [my get $r [dict get $args uid]]
	} elseif {[dict exists $args name]} {
	    # specified user by name
	    set record [my get $r [dict get $args name]]
	} else {
	    # want logged-in user
	    set record [my get $r]
	}

	if {![dict size $record]} {
	    error "set login doesn't exist ($args)"
	}
	set uid [dict get $record uid]

	variable columns
	set extra {}
	set updates {}
	dict for {n v} $args {
	    if {[dict exists $columns $n]} {
		if {$n ni {uid}} {
		    # change those fields we may change
		    lappend updates "$n=:$n"
		}
	    } else {
		dict unset args $n
		dict set extra $n $v
	    }
	}

	if {[dict exists $args name]} {
	    # check that the name has an acceptable form
	}

	# save the main account detail
	Debug.login {saveDB saving ($args)}
	my stmt "UPDATE login SET [join $updates ,] WHERE uid=:uid" {*}$args

	# save the vars
	dict for {n v} $extra {
	    my stmt {
		INSERT OR REPLACE INTO vars (var,value) VALUES (:var,:value)
	    } var $n value $v
	}

	return $record
    }

    # create new user
    method new {r args} {
	# ensure the new record is minimally compliant
	if {[dict get? $args name] ne ""
	    && ![catch {my get [dict get $args name]}]
	} {
	    error "User must be unique"
	}

	# create a new account record
	set uid [my stmt {
	    BEGIN TRANSACTION;
	    INSERT login SET DEFAULT VALUES;
	    SELECT MAX(uid) FROM login;
	    END TRANSACTION;
	}]

	Debug.login {created new login $uid}
	tailcall my set $r {*}$args uid $uid	;# store the rest of the data
    }

    # clear the login cookie
    method clear {r} {
	variable cookie
	variable domain
	set cdict [dict get? $r -cookies]
	Debug.login {logout $cookie from $cdict}

	# determine the right domain/path for the cookie
	set cd [list -name $cookie]
	if {$domain ne ""} {
	    dict set cd -domain $domain
	}

	# fetch the cookies
	variable cpath
	if {![catch {Cookies fetch $cdict -name $cookie} cl]} {
	    variable keys
	    catch {unset keys([dict get $cl -value])}	;# forget key
	    # clear cookies
	    foreach cp $cpath {
		set cdict [Cookies clear $cdict {*}$cd -path $cp]
	    }

	    # rewrite the cleared cookies
	    dict set r -cookies $cdict
	}
	return $r
    }

    # send the client to a page indicating the failure of their login
    method logmsg {r {message "Login Failed"} {url ""}} {
	variable jQ
	if {$jQ} {
	    # we're using jQuery forms
	    if {0} {
		set r [jQ postscript $r {
		    $('input[title!=""]').hint();
		    $('.login').ajaxForm({target:'#message'});
		}]
	    }
	    variable forms
	    return [Http Ok $r [subst [dict get $forms logmsg]]]
	} else {
	    if {$url eq ""} {
		set url [Http Referer $r]
		if {$url eq ""} {
		    set url "http://[dict get $r host]/"
		}
	    }
	    # throw up a Forbidden form page.
	    variable forms
	    return [Http Forbidden $r [subst [dict get $forms logmsg]]]
	}
    }

    # perform the login of user at $uid
    method login {r uid} {
	# fetch user details for $uid'th user
	variable account
	set record [my get $uid]
	set cdict [dict get? $r -cookies]

	# construct a session record keyed by md5
	while {1} {
	    set key [::md5::md5 -hex "[clock microseconds]$user$password"]
	    if {![catch {my stmt {
		INSERT OR ABORT INTO cookies (uid,cookie) VALUES (:uid,:key)
	    } uid [dict get $record uid] key $key}]} break
	    # it's got to be a unique key
	}

	Debug.login {login: created key:$key -> uid:$uid}

	variable cookie
	set cd [list -name $cookie -value $key]	;# cookie dict

	# include an optional expiry age for the cookie
	variable expires
	if {expires ne ""} {
	    dict set cd -expires $expires
	}

	# determine the right domain/path for the cookie
	variable domain
	if {[info exists domain] && $domain ne ""} {
	    dict set cd -domain $domain
	}

	# add in the cookies for each cookie path
	variable cpath
	foreach cp $cpath {
	    set cdict [Cookies add $cdict {*}$cd -path $cp]
	}
	dict set r -cookies $cdict
	Debug.login {login: added cookie $cookie to $cdict}

	return $r
    }

    # return data stored in user record
    method /get {r {fields ""}} {
	set record [my get $r]

	# convert dict to json
	set result {}
	if {[dict exists $record args]} {
	    set record [dict merge [dict get $record args] $record]	;# merge args field into record
	    dict unset record args
	}
	dict for {n v} $record {
	    if {$n eq ""} continue
	    if {$fields ne "" && $n ni $fields} continue
	    lappend result "\"$n\": \"$v\""
	}
	set result \{[join $result ,\n]\}
	return [Http NoCache [Http Ok $r $result application/json]]
    }

    # store some data in the user's record at client request
    method /set {r args} {
	catch {[dict unset args user]}	;# want only logged-in user
	# (also, we don't want the user to change its name from a form.)
	if {[catch {my set $r {*}$args} record]} {
	    return [Http NotFound $r [<p> "Not logged in"]]
	} else {
	    return [Http Ok $r [<message> "User $user Logged in."]]
	}
    }

    method /logout {r {url ""}} {
	set r [Http NoCache $r]
	set r [my clear $r]
	if {$url eq ""} {
	    set url [Http Referer $r]
	    if {$url eq ""} {
		set url "http://[dict get $r host]/"
	    }
	}

	return [Http NoCache [Http SeeOther $r $url "Logged out"]]
    }

    # return a login or logout form
    method /form {r} {
	variable cookie
	set r [Http NoCache $r]
	set code [catch {Cookies fetch [dict get $r -cookies] -name $cookie} cl]

	variable keys
	if {!$code && [info exists keys([set key [dict get $cl -value]])]} {
	    # already logged in - return a logout link instead
	    variable jQ
	    if {$jQ} {
		set r [jQ form $r .login target '#message']
		set r [jQ hint $r]	;# style up the form
		if {0} {
		    set r [jQ postscript $r {
			$('input[title!=""]').hint();
			$('.login').ajaxForm({target:'#message'});
		    }]
		}
	    }

	    Debug.login {/form: logged in already as $keys($key)}
	    variable forms
	    return [Http Ok $r [dict get $forms logout]]
	} else {
	    if {!$code} {
		# there are cookies, but they're bogus
		set key [dict get $cl -value]
		Debug.login {/form: bogus cookie: $key}
		set r [my clear $r]	;# clear the bogus cookie
	    }

	    variable jQ
	    if {$jQ} {
		set r [jQ form $r .login target '#message']
		set r [jQ hint $r]	;# style up the form
		if {0} {
		    set r [jQ postscript $r {
			$('input[title!=""]').hint();
			$('.login').ajaxForm({target:'#message'});
		    }]
		}
	    }

	    # user not already logged in - return a login form
	    Debug.login {/form: not logged in}
	    variable forms
	    return [Http Ok $r [dict get $forms login]]
	}
    }

    # create new user and log them in
    method /new {r {submit 0} args} {
	if {$submit} {
	    # We have a form POST to create a new user
	    set index [my new $r {*}$args]
	    if {$index != -1} {
		my login $r $index	;# log in the new user
		return [my logmsg $r "New user '[dict get $args user]' created"]
	    } else {
		return [my logmsg $r "There's already a user '[dict get $args user]'"]
	    }
	} else {
	    # We need to throw up a new user form.
	    variable jQ
	    if {$jQ} {
		set r [jQ form $r .login target '#message']
		set r [jQ hint $r]	;# style up the form
	    }
	    set user [dict get? $args user]
	    set password [dict get? $args password]
	    variable forms
	    return [Http Ok $r [string map [list %USER $user %PASSWORD $password] [dict get $forms new]]]
	}
    }

    # login from a form - construct user record if necessary
    method /login {r args} {
	set r [Http NoCache $r]
	variable jQ
	if {$jQ} {
	    set r [jQ form $r .login target '#message']
	    set r [jQ hint $r]	;# style up the form
	}

	# expect vars name and password, accept url
	set name [dict get? $args name]
	set password [dict get? $args password]
	set url [dict get? $args url]

	Debug.login {/login: name:$name password:$password url:$url}

	# prelim check on args
	if {$name eq ""} {
	    return [my logmsg $r "Blank name not permitted." $url]
	} elseif {[string is integer -strict $name]} {
	    return [my logmsg $r "Name '$name' does not exist." $url]
	}

	variable emptypass
	if {!$emptypass && $password eq ""} {
	    return [my logmsg $r "Blank password not permitted." $url]
	}

	# find matching user in account
	if {[catch {my get $name} record]} {
	    # there's no existing user with this name.
	    variable permissive
	    if {$permissive && $name ne "" && $password ne ""} {
		# permissive - create a new user with the name and password given
		Debug.login {/login: permissively creating user}
		set record [my new name $name password $password]
	    } else {
		Debug.login {/login: no such user}
		variable new
		if {$new eq ""} {
		    # no $new url has been given for user creation, nothing to be done.
		    return [my logmsg $r "There is no such user as '$name'." $url]
		} else {
		    # redirect to $new URL for collecting account information
		    # the URL can decide to grant an account using /new
		    return [Http Redir $r $new name $name password $password redir [Http Referer $r]]
		}
	    }
	}
	
	# match account password
	variable properties
	if {[dict get? $record password] ne $password
	    && [dict get? $record opassword] ne $password
	} {
	    Debug.login {/login: passwords don't match}
	    return [my logmsg $r "Password doesn't match for '$name'." $url]
	}

	set r [my login $r $index]	;# log user in
	
	variable jQ
	if {$jQ} {
	    # assume the .form plugin is handling this.
	    return [Http Ok $r [<message> "User '$name' Logged in."]]
	} else {
	    # otherwise we redirect to the page which provoked the login
	    if {$url eq ""} {
		set url [Http Referer $r]
		if {$url eq ""} {
		    set url "http://[dict get $r host]/"
		}
	    }
	    # resume at the appropriate URL
	    return [Http NoCache [Http SeeOther $r $url "Logged in as $user"]]
	}
    }

    method / {r args} {
	return [/login $r {*}$args]
    }
    
    method mkForms {} {
	variable forms
	if {![dict exists $forms login]} {
	    # forms for Login
	    dict set forms login [subst {
		[<form> action [file join $mount login] class login {
		    [<submit> submit style {display:none;} Login]
		    [<text> user size 8 title Username]
		    [<text> password size 8 title Password]
		}]
	    }]
	}

	if {![dict exists $forms logout]} {
	    dict set forms logout [<a> href [file join $mount logout] Logout]
	}
	if {![dict exists $forms logmsg]} {
	    dict set forms logmsg {[<message> "$message [<a> href $url {Go Back.}]"]}
	}
	if {![dict exists $forms new]} {
	    dict set forms new [<form> newuser action new class login [<fieldset> [subst {
		[<legend> "Create User"]
		[<text> user title "user id" label "User Id: " "%USER"]
		[<text> password title "password" label "Password: " "%PASSWORD"]
		[<br>][<text> given title "given name" label "Given: " ""]
		[<text> surname title "surname" label "Surname: " ""]
		[<br>][<submit> submit value 1]
	    }]]]
	}
    }

    superclass Direct

    constructor {args} {
	Debug.login {constructing $args}
	variable cookie login		;# name of the cookie
	variable domain ""		;# domain for cookies
	variable cpath {}		;# list of paths for cookies
	variable expires "next year"	;# expiry
	variable permissive 0		;# allow anonymous creation?
	variable emptypass 0		;# permit blank passwords?
	variable account {user:S password:S}	;# minimal layout for account
	variable jQ 1			;# use jQ by default
	variable realm "Login [self]"	;# login for Basic AUTH
	variable autocommit 1		;# commit on each write
	variable new "new"		;# url to redirect to on new user creation request
	variable forms {}		;# named collection of forms
	variable tdbc sqlite3		;# TDBC backend
	variable file login.db		;# login db name
	variable opts {}		;# tdbc creation opts

	variable {*}[Site var? Login]	;# allow .ini file to modify defaults
	dict for {n v} $args {
	    set $n $v
	}

	variable keys; array set keys {}	;# start remembering our keys

	# the /login path must always get this cookie
	if {[lsearch $cpath $mount] == -1} {
	    lappend cpath $mount
	}

	next? {*}$args

	Debug.login {constructed [self] $args}
    }
}

if {0} {
    # example of how Login might be used to control the domain /cookie/
    package require Login 
    Debug on login 100
    Nub domain /login/ Direct object {Login ::L account {db accountdb file account.db layout {user:S password:S args:S}} cpath /cookie/ permissive 0 jQ 1 autocommit 1} ctype x-text/html-fragment

    Nub code /login/test {
	set r [::L /form $r]	;# the result of this nub will be a login or logout form
	set user [::L user $r]	;# get the account record of the user (if any)

	# add some output to the field content
	set result [dict get $r -content]
	append result [<div> id message {}]	;# add a message div for feedback
	append result [<p> "User: $user"]	;# display the account data
    }
}
