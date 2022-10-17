# Mason -
#
# A domain to emulate Mason (http://www.masonhq.com/)

package require Html
package require OO

package require Report
package require Debug
Debug define mason

package provide Mason 1.0

set ::API(Domains/Mason) {
    {
	A [File]-like domain mapping a URL domain onto a file-system hierarchy, providing templating and pre- and post- filtering of requests and responses (respectively)

	== Quick Start ==
	[[[http:Nub Nub] domain /mason/ Mason root $docroot]]

	Where docroot is the path of your file directory.  The directory can contain .tml files which will be [[subst]]ed under tcl, index files, .before and .after files.

	Now any reference to /mason/path will return the content of the file at $docroot/path.  You can restrict access to the file using the .before facility, transform the file contents using the .after facility, and guard against non-existent files using the .notfound facility.
	
	== Operation ==
	The target URL is interpreted relative to the Mason object's ''root'' directory, and its value returned.  A literal match is preferred, but if one can't be made, a templated file with the same file rootname will be evaluated and returned in its stead (allowing generated content to match a requested file-extension.)

	Standard templates are run at strategic points in URL handling (pre- and post-processing) to allow Mason user-provided code to intervene in requests and transform responses. If a requested file can't be located, the per-directory notfound template is evaluated in its stead.

	Any file ending with .tml file extension is considered to be a template file, and is evaluated as a tcl script, and the resultant value of this evaluation returned as content to the user.  Unlike standard templates, *.tml templates are not expected to return complete response-dicts, but may return simple values.  However, *.tml template scripts have access to a variable ''response'' which will form the response dict sent to the client (after .after processing) and may access and modify it.  Any ''response'' fields may be modified, and will be combined with the value returned by the .tml script to form the client response.  Any error in the .tml script evaluation will be immediately returned as a Server Error.  If the .tml script sets the -content field of ''response'', then that (and not the .tml script evaluation result) will be the response content.  .tml may also set the ''response'' -code to an HTTP response code, and it will be definitive.  A .tml may also use tcl's [[return -code]] to set the HTTP response code.

	== Dynamic v. Static Content and Cache Interaction ==
	Content produced by .tml files is considered dynamic, it won't be cached by default.  However, setting the -dynamic response field to 0 will override this behaviour, and the content will be considered cacheable.  In this case, the file modification time of the .tml script itself will be considered to be the modification time of its result.

	Content derived from the resolution of URLs to files are considered to be static, and will be cached.  The modification time of these files will be considered in response to an HTTP if-modified-since request.  This caching behaviour may be changed if the response -dynamic field is set to true.

	Static content should probably specify an ''expires'' configuration value, which prevents caches from soliciting change information before the stated expiry time and which determines cache expiry.  Proper selection of caching options is a subtle and complex area, well beyond this document's scope.

	== Standard Templates ==
	Standard templates are sought in ancestor directories of the url-addressed file, and are evaluated in a context in which the current response dict is available in ''$rsp'' or the current request dict is available in a variable as ''$req'', respectively.  The scripts may use or modify ''req'' or ''rsp'', and are expected to return a new version.  If they modify the dict (by adding, changing or removing request fields) those changes will be propagated through the system and be returned to the client.  This gives Mason a great deal of power in interpreting client requests and transforming server responses.

	;.before: Pre-filters and pre-transforms requests before the target URL is fully processed.  If ,auth errors, or returns the request with a -code field of anything other than Ok (200) the request is immediately rejected by the server.
	;.after: post-transforms responses after the target URL has been processed.  The -code field contains HTTP code, the -content field contains the content, and the content-type field contains the mime-type of the eventual HTTP response.  Any response fields may be manipulated, but this is a powerful operator, and can cause confusing results.
	;.notfound: post-transforms responses after Mason has decided that it can't resolve the target URL into a resource.  .notfound script can try to recover, or can generate content (such as a search form, or suggested alternatives) or can redirect to some other resource (perhaps to create the content.)

	== Safe Interpreters ==
	Are not used to evaluate templates, but probably should be.
    }

    root {Filesystem root for this domain}
    ctype {default content-type of returned values}
    hide {a regexp to hide temp and other files (default hides .* *~ and #*)}
    indexfile {a file which stands for a directory (default index.html)}
    expires {a tcl clock expression indicating when contents expire from caches.  By setting a later value, one reduces server load at the risk of having the client see old content.}
    functional {file extension which marks tcl scripts to be evaluated for value (default .tml)}
    notfound {template sought and evaluated when a requested resource can't be located (default .notfound)}
    wrapper {template sought and evaluated with successful response (default .after)}
    auth {template sought and evaluated before processing requested file (default .before)}
    nodir {don't allow the browsing of directories (default: 0 - browsing allowed.)}
    dateformat {a tcl clock format for displaying dates in directory listings}
    stream {files above this size will be streamed using fcopy, not loaded and sent.  Note: streaming a file prevents *any* post-processing on is, so [Convert] for example will be ineffective.}
    sortparam {parameters for tablesorter}
}

class create ::Mason {
    variable mount root hide functional notfound wrapper auth indexfile dirhead dirfoot aliases cache ctype nodir dirparams dateformat stream sortparam

    method conditional {req path} {
	# check conditional
	if {[dict exists $req if-modified-since]
	    && (![dict exists $req -dynamic] || ![dict get $req -dynamic])
	} {
	    set since [dict get $req if-modified-since]
	    if {$since eq [Http Date [file mtime $path]]} {
		# if the times are identical, it's unmodified
		Debug.mason {NotModified: $path}
		return 1
	    }
	}
	return 0
    }

    method findUp {req name} {
	Debug.mason {findUp [dict get $req -root] [dict get $req -suffix] $name} 3
	set suffix [string trim [dict get $req -suffix] /]
	if {$cache} {
	    set result [file upm [dict get $req -root] $suffix $name]
	} else {
	    set result [file up [dict get $req -root] $suffix $name]
	}
	return $result
    }

    method template {req fpath} {
	Debug.mason {template run: '$fpath' [dumpMsg $req]}

	dict lappend req -depends $fpath ;# cache functional dependency

	# read template into interpreter
	if {[catch {
	    set fd [open $fpath]
	    set enc [dict get? $req -encoding]
	    if {$enc ne ""} {
		chan configure $fd -encoding $enc
	    } else {
		chan configure $fd -encoding binary
	    }
	    set template [read $fd]
	    close $fd
	    Debug.mason {template code: $template}
	} r eo]} {
	    Debug.mason {template error: $r ($eo)}
	    catch {close $fd}
	    return [Http ServerError $req $r $eo]
	}

	# set some variables
	set response $req
	catch {dict unset response -code}	;# let subst set -code value
	#catch {dict unset response -content}	;# let subst set content
	if {![dict exists $response content-type]} {
	    # set default mime type
	    dict set response content-type $ctype
	}

	# perform template substitution
	set code [catch {
	    #puts stderr "Mason template: $template"
	    subst $template
	} result eo]	;# result is the substituted template
	Debug.mason {template result: $code ($eo) - '$result' over '$template'} 2

	if {$code && $code < 200} {
	    dict set response -dynamic 1
	    return [Http ServerError $response $result $eo]
	}
	if {![dict exists $response -code]} {
	    dict set response -code 200
	}

	# implicit return value - use the substitution
	if {![dict exists $response -content]
	    && ![dict exists $response -file]
	} {
	    Debug.mason {setting implicit return value, '[string range $result 0 80]...[string range $result end-80 end]' of length [string length $result]}
	    dict set response -content $result	;# fold subst result back into response
	}

	Debug.mason {Mason Template '$fpath' return [Httpd rdump $response]}

	return $response
    }

    method functional {req fpath} {
	set rsp [my template $req $fpath]
	Debug.mason {Mason Functional ($fpath): [dumpMsg $rsp]}

	# determine whether content is dynamic or not
	if {[dict exists $rsp -dynamic] && [dict get $rsp -dynamic]} {
	    # it's completely dynamic - no caching
	    return [Http NoCache $rsp]
	} else {
	    # this is able to be cached.
	    #catch {dict unset rsp -dynamic}

	    if {[info exists expires] && $expires ne ""} {
		set rsp [Http Cache $req $expires]
	    }
	    return [Http CacheableContent $rsp [clock seconds]]
	}
    }

    # candidate - find a candidate for file
    method candidate {file} {
	if {[file exists $file]} {
	    return $file
	}
	
	# no such file - may be a functional?
	set fpath [file rootname $file]$functional
	Debug.mason {candidate $fpath - [file exists $fpath]}
	if {[file exists $fpath]} {
	    return $fpath
	} else {
	    return ""
	}
    }

    # dir - fallback to listing a directory
    method dir {req path args} {
	Debug.mason {dir over $path}
	dict set files .. [list name [<a> href .. ..] type parent]

	foreach file [glob -nocomplain -directory $path *] {
	    Debug.mason {dir element $file}
	    set name [file tail $file]
	    if {[regexp $hide $name]} continue

	    set type [Mime type $file]
	    if {$type eq "multipart/x-directory"} {
		set type directory
		append name /
	    }

	    set title [<a> href $name $name]
	    catch {dict set files $name [list name $title modified [clock format [file mtime $file] -format $dateformat] size [file size $file] type $type]}
	}

	set suffix [dict get $req -suffix]
	set doctitle [string trimright $suffix /]
	append content [<h1> $doctitle] \n

	append content [Report html $files {*}$dirparams headers {name type modified size}] \n

	dict set req -content $content
	dict set req content-type x-text/html-fragment
	set req [jQ tablesorter $req .sortable {*}$sortparam]

	return $req
    }

    method root {} {
	return $root
    }
    method mount {} {
	return $mount
    }

    method sendfile {r path} {
	# allow client caching
	if {[info exists expires] && $expires ne ""} {
	    set r [Http Cache $r $expires]
	}

	set ct [Mime magic path $path]
	set mtime [file mtime $path]
	Debug.mason {file: $path of ctype: $ct}

	# decide whether this file can be streamed
	if {![string match x-*/* $ct]
	    && [file size $path] > $stream
	} {
	    # this is a large, ordinary file - stream it using fcopy
	    return [Http File $r $path]
	}

	# read the file content
	set fd [open $path]
	chan configure $fd -translation binary
	set content [read $fd]
	chan close $fd

	dict set r -fpath $path	;# remember the path

	# return the content after conversion
	Debug.mason {returning file: $path of ctype: $ct}
	return [Http CacheableContent $r $mtime $content $ct]
    }

    method mason {req} {
	Debug.mason {Mason: [dumpMsg $req]}
	
	dict set req -mason [self]
	dict set req -urlroot $mount

	set http [dict get? $req -http]
	set suffix [string trimleft [dict get $req -suffix] /]
	
	set ext [file extension $suffix]	;# file extent
	set path [file join [dict get $req -root] $suffix] ;# complete path to file
	set tail [file tail $suffix]	;# last component of path
	set url [dict get $req -url]	;# full URL
	
	Debug.mason {Mason: -url:$url - suffix:$suffix - path:$path - tail:$tail - ext:$ext}
	if {(($tail eq $ext) && ($ext ne "")
	     && ![dict exists $req -extonly])
	    || [regexp $hide $tail]
	} {
	    # this is a file name like '.../.tml', or is hidden
	    Debug.mason {notfound failed - illegal name}
	    return [Http NotFound $req [subst {
		[<p> "'$path' has illegal name.</p>"]
	    }]]
	}
	
	# .notfound processing
	set fpath [my candidate $path]
	if {$fpath eq ""} {
	    Debug.mason {not found $fpath - looking for $notfound}
	    set fpath [my findUp $req $notfound]	;# get the .notfound
	    if {$fpath eq ""} {
		Debug.mason {.notfound failed - really not here}
		# .notfound template completely missing
		# just pick some match at random and return it
		set globs [glob -nocomplain [file rootname $path].*]
		if {![llength $globs]} {
		    return [Http NotFound $req]
		}
		set path [lindex $globs 0]	;# desperation
	    } else {
		# handle conditional request on .notfound
		if {[my conditional $req $fpath]} {
		    return [Http NotModified $req]
		}
		dict set req -dynamic 1	;# functionals are dynamic by default
		Debug.mason {running .notfound}
		return [my functional $req $fpath]	;# invoke the .notfound
	    }
	} elseif {[file extension $fpath] eq $functional} {
	    # handle conditional request on functional path
	    if {[my conditional $req $fpath]} {
		return [Http NotModified $req]
	    }

	    dict set req -dynamic 1	;# functionals are dynamic by default
	    Debug.mason {running user template '$fpath'}
	    return [my functional $req $fpath]	;# invoke the functional
	} else {
	    set path $fpath
	    Debug.mason {found user content '$fpath'}

	    # handle conditional request on path
	    if {[my conditional $req $path]} {
		return [Http NotModified $req]
	    }
	}

	# file $path exists
	Debug.mason {Found file '$path' of type [file type $path]}
	set cnt 20
	while {[file type $path] eq "link" && [incr cnt -1]} {
	    # chase down links
	    set lpath $path
	    set path [file readlink $path]
	    if {[file pathtype $path] eq "relative"} {
		set path [file normalize [file join [file dirname $lpath] $path]]
	    }
	}
	if {!$cnt} {
	    return [Http NotFound $req "File path has too many symlinks"]
	}

	switch -- [file type $path] {
	    file {
		return [my sendfile $req $path]
	    }
	    
	    directory {
		# URL maps to a directory.
		if {![string match */ $url]} {
		    # redirect - insist on trailing /
		    Debug.mason {Redirecting, as url '$url' doesn't end in a /, but '$path' a directory}
		    return [Http Redirect $req "${url}/"]

		    # Question: Why should a URL that names a directory have
		    # a trailing slash?
		    # Answer:
		    # When a document contains relative links, they are resolved
		    # by the browser, not by the HTTP server.
		    # The browser starts with the URL for the current document,
		    # removes everything after the last slash, and appends the
		    # relative URL. If the URL for the current document names
		    # a file, this works fine, but if the URL for the current
		    # document names a directory, and the URL is missing the
		    # trailing slash, then the method fails.
		} elseif {$indexfile ne ""} {
		    # we are instructed to use index.html (or similar)
		    # as the contents of a directory.
		    
		    # if there is an existing index file re-try this request
		    # after modifying the URL/path etc.
		    set fpath [my candidate [file join $path $indexfile]]
		    if {$fpath ne ""} {
			if {[file extension $fpath] eq $functional} {
			    # handle conditional request on functional path
			    if {[my conditional $req $fpath]} {
				return [Http NotModified $req]
			    }
			    Debug.mason {processing index candidate '$fpath' for $path/$indexfile}

			    # hand the functional some layout parameters
			    if {$dirhead ne {}} {
				dict set req -thead $dirhead
			    }
			    if {$dirfoot eq {}} {
				dict set req -tfoot [list [<a> href .. Up]]
			    }

			    dict set req -dynamic 1	;# functionals are dynamic by default
			    dict set req -fpath $fpath	;# remember the path
			    return [my functional $req $fpath]	;# invoke the functional
			}
			return [my sendfile $req $fpath]
		    } else {
			Debug.mason {didn't find index candidate $path/$indexfile}
			if {$nodir} {
			    return [Http NotFound $r [<p> "Couldn't find $path"]]
			} else {
			    # we're expected to generate some kind of dirlisting.
			    return [my dir $req $path]
			}
		    }
		}

		dict set req -dynamic 1	;# functionals are dynamic by default
		return [my functional $req $fpath]	;# invoke the functional
	    }
	    
	    default {
		dict lappend req -depends [file normalize $path]	;# cache notfound
		Debug.mason {Mason illegal type [file type $path]}
		return [Http NotFound $req [subst {
		    [<p> "'$suffix' is of illegal type [file type $path]"]
		}]]
	    }
	}
    }
    
    method auth {req} {
	# run authentication and return any codes
	set fpath [my findUp $req $auth]
	if {$fpath ne ""} {
	    Debug.mason {Mason got auth: $fpath}
	    
	    set req [my template $req $fpath]

	    if {[dict get $req -code] != 200} {
		# auth preprocessing has an exception - we're done
		Debug.mason {Mason auth exception: [dict get $req -code]}
	    } else {
		Debug.mason {Mason auth OK}

		# auth passed - remove any traces
		catch {dict unset req -content}
		catch {dict unset req -file}
		catch {dict unset req content-type}
	    }
	} else {
	    dict set req -code 200
	}

	return $req
    }

    method do {req} {
	dict set req -root $root

	# calculate the suffix of the URL relative to $mount
	lassign [Url urlsuffix $req $mount] result req suffix
	if {!$result} {
	    Debug.mason {do Suffix $suffix not in $mount: $result}
	    return $req	;# the URL isn't in our domain
	}

	Debug.mason {do $suffix}

	set req [my auth $req]	;# authenticate - must not be caught!
	if {[dict get $req -code] != 200} {
	    return $req
	}
	dict set req -dynamic 0		;# default: static content
	set rsp [my mason $req]	;# process request

	Debug.mason {processed $rsp}

	# filter/reprocess this response
	if {$wrapper ne "" && [set wrap [my findUp $rsp $wrapper]] ne ""} {
	    Debug.mason {wrapper $wrapper - $wrap}

	    # run template over request
	    if {[dict get $rsp -code] == 200} {
		set rsp [my template $rsp $wrap]
	    }
	    catch {dict unset rsp -root}

	    # determine whether content is dynamic or not
	    if {[dict exists $rsp -dynamic] && [dict get $rsp -dynamic]} {
		# it's completely dynamic - no caching
		return [Http NoCache $rsp]
	    } else {
		# this is able to be cached.
		if {[info exists expires] && $expires ne ""} {
		    set r [Http Cache $req $expires]
		}
		return [Http CacheableContent $rsp [clock seconds]]
	    }
	}

	Debug.mason {default response $rsp}
	return $rsp
    }

    constructor {args} {
	Debug.mason {constructor: $args}
	set mount ""	;# url for top of this domain
	set root ""		;# file system domain root
	set ctype x-text/html-fragment	;# default content type
	set hide {^([.].*)|(.*~)$}	;# these files are never matched
	set functional ".tml"	;# functional extension
	set notfound ".notfound"	;# notfound handler name
	set wrapper ".after"	;# wrapper handler name
	set auth ".before"	;# authentication functional
	set indexfile index.html	;# directory index name
	set dirhead {name size mtime *}
	set dirfoot {}
	# additional aliases to be installed in session interpreter
	set aliases {}
	set nodir 0
	set dirparams {
	    sortable 1
	    evenodd 0
	    class table
	    tparam {title "Registry for this class"}
	    hclass header
	    hparam {title "click to sort"}
	    thparam {class thead}
	    fclass footer
	    tfparam {class tfoot}
	    rclass row
	    rparam {}
	    eclass el
	    eparam {}
	    footer {}
	}
	set dateformat "%Y %b %d %T"
	set stream [expr {1024 * 1024}]	;# default streaming 1Mb
 	set sortparam {}

	# when a file is not located, it will be searched for.
	# to minimise the cost of this search, -cache will
	# instruct Mason to memoize found files
	set cache 1		;# cache file searches

	variable {*}[Site var? Mason]	;# allow .ini file to modify defaults

	foreach {n v} $args {
	    set [string trimleft $n -] $v
	}

	set root [file normalize $root]

	if {$dirhead ne ""} {
	    # search for an element "*" in -dirhead
	    catch {unset attr}
	    file lstat $root attr
	    set oth [array get attr]
	    dict set oth name X
	    foreach {x y} [file attributes $root] {
		dict set oth $x $y
	    }
 
	    set i 0
	    set index -1
	    set hd {}
	    set rhead {}
	    foreach el $dirhead {
		if {$el eq "*"} {
		    set index $i
		    lappend rhead *
		    incr i
		} elseif {![catch {dict unset oth $el}]} {
		    lappend rhead $el
		    incr i
		}
	    }

	    if {$index ne -1} {
		set thead [lreplace $rhead $index $index {*}[lsort -dictionary [dict keys $oth]]]
		set dirhead $thead
	    }
	}
    }
}

package require Convert

namespace eval ::MConvert {
    proc .x-text/dict.x-text/html-fragment {rsp} {
	Debug.convert {x-text/dict.x-text/html-fragment conversion: $rsp}

	# use -thead as table headers, or if there is none use the dict keys
	if {![dict exists $rsp -thead]} {
	    set thead [lsort [dict keys [lindex [dict get $rsp -content] 1]]]
	} else {
	    set thead [dict get $rsp -thead]
	}

	dict set rsp -content [Html dict2table [dict get $rsp -content] $thead [dict get? $rsp -tfoot]]

	if {[dict exists $rsp -title]} {
	    dict lappend rsp -headers [<title> [string trim [dict get $rsp -title]]]
	}

	set uroot [dict get? $rsp -urlroot]
	foreach js {common css standardista-table-sorting} {
	    set rsp [Html script $r $uroot/scripts/$js.js]
	}

	set rsp [Html style $rsp $uroot/css/sorttable.css]
	dict set rsp content-type x-text/html-fragment

	Debug.convert {x-text/dict.x-text/html-fragment conversion: $rsp}
	return $rsp
    }
}

::convert namespace ::MConvert	;# add Mason conversions
