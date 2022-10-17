# Repo -
#
# A domain to present a file system as a series of URLs

package require Debug
Debug define repo 10

package require tar
package require fileutil
package require Html
package require Query
package require Report
package require Form
package require Mime
package require jQ

package provide Repo 1.0

set ::API(Domains/Repo) {
    {
	A simple file repository providing uploads and tar'ed directory downloads

	Repo is essentially a [File] domain with a pretty front end enabling users to upload and download files and collections of files.

	== QuickStart ==

	[[[http:Nub Nub] domain /repo/ Repo tar 1 upload 1 root $::repobase]]

	Now you've got a domain which responds to the URL /repo, looking for files and directories in filesystem path $::repobase, will tar up directories and allows uploads.

	== ToDo ==
	As Repo was developed for a Wiki, where the culture's fairly permissive, it doesn't provide ''any'' authentication.  It probably should.
	Repo ought to decompress and untar any uploaded tar.gz files.
    }

    expires {a tcl clock expression indicating when contents expire from caches (default:0 - no expiry)}
    tar {flag: are directories to be provided as tar files? (default: no)}
    index {a file which provides header text for a directory, (default: index.html)}
    max {maximum upload file size in bytes (default: 1 megabyte)}
    title {title prefix for display (default: Repo)}
    titleURL {URL prefix for title (default: none)}
    dirtime {tcl clock display format for times (default: "%Y %b %d %T")}
    docprefix {URL prefix for documentation associated with directories}
    icon_size {pixel size of icons (default 24)}
    icons {icon domain to use for icons (default: /icons/)}
    jQ {use jQuery (default: yes)}
}
    
# TODO - handle dangling softlinks in dirlist
# TODO - some kind of permissions system

namespace eval ::Repo {
    variable dirparams {
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
	rparam {title row}
	eclass el
	eparam {}
	footer {}
    }
    variable dirtime "%Y %b %d %T"
    variable icon_size 24
    variable icons /icons/

    proc dir {req path args} {
	Debug.repo {dir $path $args}
	dict set files .. [list name [<a> href .. ..] type parent]
	variable dirtime
	variable icon_size

	foreach file [glob -nocomplain -directory $path *] {
	    set name [file tail $file]
	    if {![regexp {^([.].*)|(.*~)|(\#.*)$} $name]} {
		set type [Mime type $file]
		set qname [Query encode $name]	;# remove problem chars
		if {$type eq "multipart/x-directory"} {
		    set type directory
		    append name /
		    append qname /
		}
		set title [<a> href $name $name]
		set del [<a> href $name?op=del title "click to delete" [<img> height $icon_size src [dict get $args icons]remove.gif]]
		set del [<form> del$name action ./$name {
		    [<hidden> op del]
		    [<submit> submit [<img> height $icon_size src [dict get $args icons]remove.gif]]
		}]
		dict set files $name [list name $title modified [clock format [file mtime $file] -format $dirtime] size [file size $file] type $type delete $del view [<a> href $name?format=plain view]]
	    }
	}

	set suffix [dict get $req -suffix]
	set doctitle [string trimright $suffix /]
	if {[dict exists $args docprefix]
	    && $suffix ne "/"
	} {
	    set doctitle [<a> href [dict get $args docprefix]$doctitle $doctitle]
	}
	set title [dict get $args title]
	if {[dict exists $args titleURL] ne ""} {
	    set title [<a> href [dict get $args titleURL] $title]
	}
	append content [<h1> "$title - $doctitle"] \n

	variable dirparams
	append content [Report html $files {*}$dirparams headers {name type modified size delete view}] \n
	if {[dict exists $args tar] && [dict get $args tar]} {
	    append content [<p> "[<a> href [string trimright [dict get $req -path] /] Download] directory as a POSIX tar archive."] \n
	}

	if {[dict exists $args docprefix]
	    && $suffix ne "/"
	} {
	    append content [<p> [<a> href [dict get $args docprefix]$suffix "Read Documentation"]] \n
	}

	if {[dict exists $args upload]} {
	    append content [<form> create action . {
		[<text> subdir label [<submit> submit "Create"] title "subdirectory to create" size 20 ""]
		[<hidden> op create]
	    }] \n

	    append content [<form> upload action . enctype "multipart/form-data" {
		[<file> file label [<submit> submit "Upload"] class multi]
		[<hidden> op upload]
	    }] \n
	    if {[dict get $args jQ]} {
		set req [jQ multifile $req]	;# make upload form a multifile
	    }
	}

	dict set req -content $content
	dict set req content-type x-text/html-fragment
	if {[dict get $args jQ]} {
	    set req [jQ tablesorter $req .sortable]
	    set req [jQ hint $req]
	}

	return $req
    }

    proc upload {r Q args} {
	Debug.repo {upload ARGS: $args}
	dict with args {}	;# extract dict vars
	foreach v {r max path Q} {
	    catch {dict unset Q $v}
	}
	set Q [dict filter $Q key {[a-zA-Z]*}]
	dict with Q {}

	# process upload and mime type
	set messages {}
	foreach f [info vars file*] {
	    # extract meaning from file upload
	    set content [set $f]
	    if {$content eq ""} continue
	    set metadata [Query metadata [dict get $r -Query] $f]
	    Debug.repo {+add Q: ([llength $metadata]) $metadata}

	    set name [dict get? $metadata filename]
	    if {[string tolower [lindex [split $name .] 1]] in {"exe" "bat" "com" "scr" "vbs" "mp3" "avi"}} {
		lappend messages "files of type '$name' are not permitted."
		continue
	    }
	    if {$name eq ""} {
		set name [clock seconds]
	    }

	    if {[string length $content] > $max} {
		lappend messages "file '$name' is too long"
		continue
	    }
	    set name [::fileutil::jail $path $name]
	    ::fileutil::writeFile -encoding binary -translation binary -- $name $content
	    Debug.repo {upload $name}
	}

	if {$messages ne ""} {
	    return [Http Forbidden $r [<p> "Some uploads failed: "][join $messages \n]]
	} else {
	    # multiple adds - redirect to parent
	    return [Http Redirect $r [dict get $r -url]]	;# redirect to parent
	}
    }

    proc _do {inst r} {
	dict with inst {}	;# instance vars

	Debug.repo {do: $mount [dict get $r -path]}
	lassign [Url urlsuffix $r $mount] result r suffix path
	if {!$result} {
	    return $r	;# the URL isn't in our domain
	}

	dict set r -title "$title - [string trimright $suffix /]"
	if {$titleURL ne ""} {
	    set title [<a> href $titleURL $title]
	}
	set ext [file extension $suffix]
	set path [file normalize [file join $root [string trimleft $suffix /]]]
	#dict set r -path $path
	
	# unpack query response
	set Q [Query parse $r]
	dict set r -Query $Q
	set Q [Query flatten $Q]

	Debug.repo {suffix:$suffix path:$path r path:[dict get $r -path] mount:$mount Q:$Q}

	switch -- [dict get? $Q op] {
	    del {
		# move this file out of the way
		set dir [file dirname $path]
		set fn [file tail $path]
		set vers 0 ;while {[file exists [file join $dir .del-$fn.$vers]]} {incr vers}
		Debug.repo {del: $path -> [file join $dir .del-$fn.$vers]}
		file rename $path [file join $dir .del-$fn.$vers]
		return [Http Redir $r .]
	    }

	    create {
		# create a subdirectory
		set subdir [::fileutil::jail $path [dict get $Q subdir]]
		set relpath [join [lrange [split [::fileutil::relativeUrl $path $subdir] /] 1 end] /]/
		Debug.repo {create: $path $subdir - $relpath}
		file mkdir $subdir
		return [Http Redir $r $relpath]
	    }

	    upload {
		# upload some files
		return [upload $r $Q path $path {*}$inst]
	    }
	}
	
	if {$ext ne "" && [file tail $suffix] eq $ext} {
	    # this is a file name like '.tml'
	    return [Http NotFound $r [<p> "File '$suffix' has illegal name."]]
	}

	if {![file exists $path]} {
	    dict lappend r -depends $path	;# cache notfound
	    return [Http NotFound $r [<p> "File '$suffix' doesn't exist."]]
	}

	# handle conditional request
	if {[dict exists $r if-modified-since]
	    && (![dict exists $r -dynamic] || ![dict get $r -dynamic])
	} {
	    set since [Http DateInSeconds [dict get $r if-modified-since]]
	    if {[file mtime $path] <= $since} {
		Debug.repo {NotModified: $path - [Http Date [file mtime $path]] < [dict get $r if-modified-since]}
		Debug.repo {if-modified-since: not modified}
		return [Http NotModified $r]
	    }
	}
	
	Debug.repo {dispatch '$path' $r}
	
	Debug.repo {Found file '$path' of type [file type $path]}
	dict lappend r -depends $path	;# remember cache dependency on dir
	switch -- [file type $path] {
	    link -
	    file {
		dict set r -raw 1	;# no transformations
		set mime [Mime type $path]
		if {[dict exists $Q format]
		    && ![string match image/* $mime]
		} {
		    set mime text/plain
		}
		return [Http Ok [Http NoCache $r] [::fileutil::cat -encoding binary -translation binary -- $path] $mime]
	    }
	    
	    directory {
		# if a directory reference doesn't end in /, redirect.
		set rpath [dict get $r -path]
		if {[string index $rpath end] ne "/"} {
		    if {$tar} {
			# return the whole dir in one hit as a tar file
			set dir [pwd]
			cd [file dirname $path]
			set tname /tmp/tar[clock seconds]
			::tar::create $tname $suffix
			set content [::fileutil::cat -encoding binary -translation binary -- $tname]
			cd $dir
			return [Http CacheableContent [Http Cache $r $expires] [file mtime $path] $content application/x-tar]
		    } else {
			# redirect to the proper name
			dict set r -path "$rpath/"
			return [Http Redirect $r [Url uri $r]]
		    }
		}

		if {$index ne "" && [file exists [file join $path $index]]} {
		    # return the specified index file
		    set index [file join $path $index]
		    return [Http Ok [Http NoCache $r] [::fileutil::cat -encoding binary -translation binary -- $index] x-text/html-fragment]
		} else {
		    # return a pretty table
		    return [Http Ok [Http NoCache [dir $r $path {*}$inst]]]
		}

		dict set r -raw 1	;# no transformations
		return [Http Ok [Http NoCache $r] [::fileutil::cat -encoding binary -translation binary -- $index] [Mime type $path]]
	    }
	    
	    default {
		dict lappend r -depends $path	;# cache notfound
		return [Http NotFound $r [<p> "File '$suffix' is of illegal type [file type $path]"]]
	    }
	}
    }

    proc create {cmd args} {
	variable icons
	dict set args mount /[string trim [dict get $args mount] /]/
	set args [dict merge [list icons $icons expires 0 tar 0 jQ 1 index index.html max [expr {1024 * 1024}] titleURL "" title Repo] [Site var? Repo] $args]
	set cmd [uplevel 1 namespace current]::$cmd
	Debug.repo {create: $args}
	namespace ensemble create \
	    -command $cmd -subcommands {} \
	    -map [list do [list _do $args]]
	return $cmd
    }

    variable repocnt
    proc new {args} {
	return [create Repo[incr repocnt] {*}$args]
    }

    namespace export -clear *
    namespace ensemble create -subcommands {}
}
