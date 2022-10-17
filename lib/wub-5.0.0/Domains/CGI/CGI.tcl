# cgi interface.  Blerk.
# TODO: make the post-header response go out as a -file

package require TclOO
namespace import oo::*

package require Html
package require Debug
Debug define cgi 1000

package provide CGI 1.0

set ::API(Domains/CGI) {
    {
	A traditional CGI interface
    }
    fields {+additional fields to pass to CGI in ::env variable}
    executors {+association list between extension and language processor (which should be somewhere on your exec path)}
    root {root of directory containing scripts}
    maxcgi {limit to number of simultaneously running CGI processes}
    whitelist {+list of environment variables to pass to CGI scripts}
}

class create ::CGI {
    variable fields executors mount root maxcgi cgi whitelist

    method env {r} {
	lappend env SERVER_SOFTWARE [string map {" " /} $::Httpd::server_id]
	# name and version of the server. Format: name/version

	lappend env GATEWAY_INTERFACE CGI/1.1
	# revision of the CGI specification to which this server complies.
	# Format: CGI/revision

	lappend env SERVER_NAME [dict get? $r -host]
	# server's hostname, DNS alias, or IP address
	# as it would appear in self-referencing URLs.

	set protocol [string toupper [dict get? $r -scheme]]
	append protocol /[dict get? $r -version]
	lappend env SERVER_PROTOCOL $protocol
	# name and revision of the information protcol this request came in with.
	# Format: protocol/revision

	lappend env SERVER_PORT [dict get? $r -port]
	# port number to which the request was sent.

	set url [Url parse [dict get? $r -uri]]
	lappend env REQUEST_URI [dict get? $r -uri]
	lappend env REQUEST_METHOD [dict get? $r -method]
	# method with which the request was made.
	# For HTTP, this is "GET", "HEAD", "POST", etc.

	lappend env QUERY_STRING [dict get? $url -query]
	# information which follows the ? in the URL which referenced this script.
	# This is the query information. It should not be decoded in any fashion.
	# This variable should always be set when there is query information,
	# regardless of command line decoding.

	lappend env PATH_INFO [dict get? $r -info]
	# extra path information, as given by the client.
	# Scripts can be accessed by their virtual pathname, followed by
	# extra information at the end of this path.
	# The extra information is sent as PATH_INFO.
	# This information should be decoded by the server if it comes
	# from a URL before it is passed to the CGI script.

	lappend env PATH_TRANSLATED [dict get? $r -translated]
	# server provides a translated version of PATH_INFO,
	# which takes the path and does any virtual-to-physical mapping to it.

	lappend env SCRIPT_NAME [dict get? $r -script]
	# A virtual path to the script being executed, used for self-referencing URLs.

	lappend env REMOTE_ADDR [dict get? $r -ipaddr]
	# IP address of the remote host making the request.

	if {[dict exists $r -entity]} {
	    lappend env CONTENT_TYPE [dict get? $r content-type]
	    # For queries which have attached information, such as HTTP POST and PUT,
	    # this is the content type of the data.

	    lappend env CONTENT_LENGTH [dict get? $r content-length]
	    # The length of the said content as given by the client.
	}

	# Header lines received from the client, if any, are placed
	# into the environment with the prefix HTTP_ followed by the header name.
	# If necessary, the server may choose to exclude any or all of these headers
	# if including them would exceed any system environment limits.
	foreach field [dict get $r -clientheaders] {
	    if {[dict exists $r $field]} {
		lappend env HTTP_[string map {- _} [string toupper $field]] [dict get $r $field]
	    }
	}

	# Modify the global environment variable by removing anything not
	# in our whitelist. We may not unset ::env as that breaks the link
	# between the environment and this Tcl array.
	foreach name [array names ::env] {
	    if {$name ni $whitelist} { unset ::env($name) }
	}
	array set ::env $env
	return
    }

    # parseSuffix - given a suffix, locate the named object and split its name
    # components into usable variables.
    method parseSuffix {suffix} {
	Debug.cgi {parseSuffix $suffix}
	set dir [expr {[string index $suffix end] eq "/"}]
	if {$dir} {
	    # strip trailing '/'
	    set suffix [string range $suffix 0 end-1]
	}
	set ext [file extension $suffix]	;# file extension
	set path [file rootname $suffix]	;# entire path except extension
	set ftail [file tail $suffix]		;# last component of path
	set tail [file rootname $ftail]		;# last component except extension

	Debug.cgi {parseSuffix first cut: path:'$path' tail:'$tail' ftail:'$ftail' ext:'$ext' suffix:'$suffix' dir:$dir}

	# map names which are only extensions to their parent+extension
	# avoid sending files with hidden names, thus /fred/.add -> fred.add
	if {($tail eq "") && ($ext ne "")} {
	    # this is a file name like '.../.tml', or is hidden
	    Debug.cgi {parseSuffix transposing $ext to parent$ext}
	    error "'$path' is an illegal script"
	}

	# at this point we have a full path and inode

	# normalize path - reject any paths beginning with .
	if {[string first "/." $path] != -1} {
	    Debug.cgi {parseSuffix $suffix - $path illegal name}
	    error "'$path' has illegal name."
	} else {
	    set path [string trimleft $path "/."]
	}

	set ext [string trimleft $ext .]	;# remove leading .

	# keep the file variables in request dict for future reference
	foreach v {suffix ext tail ftail path dir} {
	    dict set retval $v [set $v]
	}

	Debug.cgi {parseSuffix $suffix -> $retval}
	return $retval
    }

    method closed {r pipe} {
	Debug.cgi {closed [string length [dict get? $r -content]]}
	Httpd disassociate $pipe
	if {[catch {
	    incr cgi -1

	    # close the pipe and investigate the consequences
	    catch {fileevent $pipe readable {}}

	    set status [catch {close $pipe} result]
	    if { $status == 0 } {
		# The command succeeded, and wrote nothing to stderr.
		# $result contains what it wrote to stdout, unless you
		# redirected it
		set r [Http Ok $r]
	    } elseif {$::errorCode eq "NONE"} {
		# The command exited with a normal status, but wrote something
		# to stderr, which is included in $result.
		Debug.log {CGI stderr: $result}
		set r [Http Ok $r]
	    } else {
		switch -exact -- [lindex $::errorCode 0] {
		    CHILDKILLED {
			lassign $::errorCode - pid sigName msg
			Debug.cgi {CHILDKILLED: $pid $sigName '$msg'}
			set r [Http ServerError "Child Killed $pid $sigName $msg"]
			# A child process, whose process ID was $pid,
			# died on a signal named $sigName.  A human-
			# readable message appears in $msg.
		    }

		    CHILDSTATUS {
			lassign $::errorCode - pid code
			Debug.cgi {CHILDSTATUS: $pid $code}
			set r [Http ServerError "Child Status $pid $code"]
			# A child process, whose process ID was $pid,
			# exited with a non-zero exit status, $code.
		    }
		    
		    CHILDSUSP {
			lassign $::errorCode - pid sigName msg
			Debug.cgi {CHILDSUSP: $pid $sigName '$msg'}
			set r [Http ServerError "Child Suspended $pid $sigName $msg"]
			# A child process, whose process ID was $pid,
			# has been suspended because of a signal named
			# $sigName.  A human-readable description of the
			# signal appears in $msg.
		    }
		    
		    POSIX {
			lassign $::errorCode - errName msg
			Debug.cgi {POSIX: $errName '$msg'}
			set r [Http ServerError "Child Error $errName $msg"]
			# One of the kernel calls to launch the command
			# failed.  The error code is in $errName, and a
			# human-readable message is in $msg.
		    }
		}
	    }
	} e eo]} {
	    Debug.error {cgi closed: $e ($eo)}
	}
	Httpd Resume $r
    }

    method entity {r pipe} {
	if {[catch {
	    fconfigure $pipe -translation {binary binary} -encoding binary
	    set gone [catch {chan eof $pipe} eof]
	    if {$gone || $eof} {
		set c [read $pipe]
		dict append r -content $c
		Debug.cgi {done body [string length $c]'}
		my closed $r $pipe
	    } else {
		# read the rest of the content
		set c [read $pipe]
		dict append r -content $c
		fileevent $pipe readable [list [self] entity $r $pipe]
		Debug.cgi {read body [string length $c]'}
	    }
	} e eo]} {
	    Debug.error {cgi entity: $e ($eo)}
	}
    }

    method headers {r pipe} {
	if {[catch {
	    # get headers from CGI process
	    set gone [catch {chan eof $pipe} eof]
	    if {$gone || $eof} {
		my closed $r $pipe
	    } else {
		set n [gets $pipe line]
		if {$n == -1} {
		    Debug.cgi {end of input}
		    my closed $r $pipe
		    # cgi dead
		} elseif {$n == 0} {
		    Debug.cgi {end of headers ($r)}
		    fconfigure $pipe -translation {binary binary} -encoding binary
		    fileevent $pipe readable [list [self] entity $r $pipe]
		} elseif {[string index $line 0] ne " "} {
		    # read a new header
		    set line [string trim [join [lassign [split $line :] header] :]]
		    dict set r [string tolower $header] $line
		    fileevent $pipe readable [list [self] headers $r $pipe]
		    Debug.cgi {header: $header '$line'}
		} else {
		    # get field continuation
		    dict append r [string tolower $header] " " [string trim $line]
		    fileevent $pipe readable [list [self] headers $r $pipe]
		    Debug.cgi {continuation: $header '$line'}
		}
	    }
	} e eo]} {
	    Debug.error {cgi header: $e ($eo)}
	}
    }

    method do {r} {
	# calculate the suffix of the URL relative to $mount
	lassign [Url urlsuffix $r $mount] result r suffix path
	if {!$result} {
	    return $r	;# the URL isn't in our domain
	}

	# parse suffix into semantically useful fields
	if {[catch {
	    my parseSuffix $suffix
	} fparts eo]} {
	    Debug.cgi {parseSuffix '$fparts' ($eo)}
	    return [Http NotFound $r $fparts]
	}
	Debug.cgi {parsed URL into '$fparts'}

	dict set req -fparts $fparts	;# record file parts in request
	dict with req -fparts {}	;# grab some useful values from req
	dict set req -suffix $suffix	;# remember the calculated suffix in req

	# derive a script path from the URL path fields
	Debug.cgi {searching for [file join $root $suffix]}
	set extlc [string tolower $ext]
	set suff [file split [string map [list / [file separator]] $path].$ext]
	dict set r -info {}
	while {$suff ne {}} {
	    set probe [file join $root {*}$suff]
	    set ext [file extension $probe]
	    set extlc [string tolower $ext]
	    set probe [file root $probe]$extlc
	    Debug.cgi {probing for '$probe'}
	    if {[file exists $probe]} {
		break
	    }
	    dict lappend r -info "[lindex $suff end].$extlc"
	    set suff [lrange $suff 0 end-1]
	}
	dict set r -translated $probe[dict get $r -info]

	# only execute scripts with appropriate extension
	if {[catch {
	    Debug.cgi {executors '$ext' in ($executors)}
	    dict get $executors [string toupper $ext]
	} executor]} {
	    return [Http Forbidden $r [<p> "Can't execute files of type '$ext'"]]
	}

	if {$suff eq {}} {
	    # we've failed to find a match
	    Debug.cgi {could not find script}
	    return [Http NotFound $r]
	    # could do a search with different variant extensions
	} else {
	    # found our script
	    set script [file rootname [file join $root {*}$suff]][string tolower [file extension $suff]]
	    Debug.cgi {found script '$script'}
	    dict set req -script $script
	}

	my env $r	;# construct the environment per CGI 1.1

	# limit the number of CGIs running
	if {[incr cgi] > $maxcgi} {
	    return [Http GatewayTimeout $r "Maximum CGI count exceeded"]
	}

	# collect arguments for GET methods
	dict set r -Query [Query parse $r]
	if {[dict get $r -method] ne "POST"} {
	    set arglist [Query flatten [dict get $r -Query]]
	} else {
	    set arglist {}
	}

	# move into the script dir
	set pwd [pwd]
	cd [file dirname $script]

	# execute the script
	Debug.cgi {running: open "|{*}$executor $script $arglist"}
	if {[catch {
	    # run the script under the executor
	    if {[dict exists $r -entitypath]} {
		# the entity file is already open.
		open "|$executor $script $arglist <@[dict get? $r -entity] 2>@1" r
	    } else {
		# entity content is in a string
		open "|$executor $script $arglist <<[dict get? $r -entity] 2>@1" r
	    }
	} pipe eo]} {
	    # execution failed
	    cd $pwd
	    Debug.error {CGI: Error $pipe ($eo) "|{*}$executor $script {*}$arglist"}
	    return [Http ServerError $r $pipe $eo]
	} else {
	    # execution succeeded
	    fconfigure $pipe -translation {auto binary} -blocking 0
	    cd $pwd
	}
	Httpd associate $pipe

	# collect input from the proc
	fileevent $pipe readable [list [self] headers $r $pipe]

	# suspend this response
	return [Httpd Suspend $r]
    }

    constructor {args} {
	set fields {}
	set executors {.CGI ""}
	set mount /CGI/
	set root /var/www/cgi-bin/
	set maxcgi 10
	set cgi 0
	set whitelist {PATH LD_LIBRARY_PATH TZ}
	variable {*}[Site var? CGI]	;# allow .ini file to modify defaults

	foreach {n v} $args {
	    set $n $v
	}

	# a set of executors for each extension
	foreach {ext lang} {.TCL tclsh .PY python .PL perl .SH bash .PHP php} {
	    if {![dict exists $executors $ext]} {
		dict set executors $ext $lang
	    }
	}

	foreach {ext lang} $executors {
	    catch {
		set l [join [exec which [lindex $lang 0]] [lrange $lang 1 end]]
		dict set executors $ext $l
	    }
	}
    }
}
