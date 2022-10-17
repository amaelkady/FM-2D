# Removed provision of the backward compatible name. Moved to separate
# file/package.
package provide vfs::zip 1.0.4.1

package require vfs

# Using the vfs, memchan and Trf extensions, we ought to be able
# to write a Tcl-only zip virtual filesystem.  What we have below
# is basically that.

namespace eval vfs::zip {}

# Used to execute a zip archive.  This is rather like a jar file
# but simpler.  We simply mount it and then source a toplevel
# file called 'main.tcl'.
proc vfs::zip::Execute {zipfile} {
    Mount $zipfile $zipfile
    source [file join $zipfile main.tcl]
}

proc vfs::zip::Mount {zipfile local} {
    set fd [::zip::open [::file normalize $zipfile]]
    vfs::filesystem mount $local [list ::vfs::zip::handler $fd]
    # Register command to unmount
    vfs::RegisterMount $local [list ::vfs::zip::Unmount $fd]
    return $fd
}

proc vfs::zip::Unmount {fd local} {
    vfs::filesystem unmount $local
    ::zip::_close $fd
}

proc vfs::zip::handler {zipfd cmd root relative actualpath args} {
    #::vfs::log [list $zipfd $cmd $root $relative $actualpath $args]
    if {$cmd == "matchindirectory"} {
	eval [list $cmd $zipfd $relative $actualpath] $args
    } else {
	eval [list $cmd $zipfd $relative] $args
    }
}

proc vfs::zip::attributes {zipfd} { return [list "state"] }
proc vfs::zip::state {zipfd args} {
    vfs::attributeCantConfigure "state" "readonly" $args
}

# If we implement the commands below, we will have a perfect
# virtual file system for zip files.

proc vfs::zip::matchindirectory {zipfd path actualpath pattern type} {
    #::vfs::log [list matchindirectory $path $actualpath $pattern $type]

    # This call to zip::getdir handles empty patterns properly as asking
    # for the existence of a single file $path only
    set res [::zip::getdir $zipfd $path $pattern]
    #::vfs::log "got $res"
    if {![string length $pattern]} {
	if {![::zip::exists $zipfd $path]} { return {} }
	set res [list $actualpath]
	set actualpath ""
    }

    set newres [list]
    foreach p [::vfs::matchCorrectTypes $type $res $actualpath] {
	lappend newres [file join $actualpath $p]
    }
    #::vfs::log "got $newres"
    return $newres
}

proc vfs::zip::stat {zipfd name} {
    #::vfs::log "stat $name"
    ::zip::stat $zipfd $name sb
    #::vfs::log [array get sb]
    # remove socket mode file type (0xc000) to prevent Tcl from reporting Fossil archives as socket types
    if {($sb(mode) & 0xf000) == 0xc000} {
        set sb(mode) [expr {$sb(mode) ^ 0xc000}]
    }
    # remove block device bit file type (0x6000)
    if {($sb(mode) & 0xf000) == 0x6000} {
        set sb(mode) [expr {$sb(mode) ^ 0x6000}]
    }
    # remove FIFO mode file type (0x1000)
    if {($sb(mode) & 0xf000) == 0x1000} {
        set sb(mode) [expr {$sb(mode) ^ 0x1000}]
    }
    # remove character device mode file type (0x2000)
    if {($sb(mode) & 0xf000) == 0x2000} {
        set sb(mode) [expr {$sb(mode) ^ 0x2000}]
    }
    # workaround for certain errorneus zip archives
    if {($sb(mode) & 0xffff) == 0xffff} {
	# change to directory type and set mode to 0777 + directory flag
	set sb(mode) 0x41ff
    }
    array get sb
}

proc vfs::zip::access {zipfd name mode} {
    #::vfs::log "zip-access $name $mode"
    if {$mode & 2} {
	vfs::filesystem posixerror $::vfs::posix(EROFS)
    }
    # Readable, Exists and Executable are treated as 'exists'
    # Could we get more information from the archive?
    if {[::zip::exists $zipfd $name]} {
	return 1
    } else {
	error "No such file"
    }
    
}

proc vfs::zip::open {zipfd name mode permissions} {
    #::vfs::log "open $name $mode $permissions"
    # return a list of two elements:
    # 1. first element is the Tcl channel name which has been opened
    # 2. second element (optional) is a command to evaluate when
    #    the channel is closed.

    switch -- $mode {
	"" -
	"r" {
	    if {![::zip::exists $zipfd $name]} {
		vfs::filesystem posixerror $::vfs::posix(ENOENT)
	    }
	    
	    ::zip::stat $zipfd $name sb

            if {$sb(ino) == -1} {
                vfs::filesystem posixerror $::vfs::posix(EISDIR)
            }

#	    set nfd [vfs::memchan]
#	    fconfigure $nfd -translation binary

	    seek $zipfd $sb(ino) start
#	    set data [zip::Data $zipfd sb 0]

#	    puts -nonewline $nfd $data

#	    fconfigure $nfd -translation auto
#	    seek $nfd 0
#	    return [list $nfd]
	    # use streaming for files larger than 1MB
	    if {$::zip::useStreaming && $sb(size) >= 1048576} {
		seek $zipfd [zip::ParseDataHeader $zipfd sb] start
		if { $sb(method) != 0} {
		    set nfd [::zip::zstream $zipfd $sb(csize) $sb(size)]
		}  else  {
		    set nfd [::zip::rawstream $zipfd $sb(size)]
		}
		return [list $nfd]
	    }  else  {
		set nfd [vfs::memchan]
		fconfigure $nfd -translation binary

		set data [zip::Data $zipfd sb 0]

		puts -nonewline $nfd $data

		fconfigure $nfd -translation auto
		seek $nfd 0
		return [list $nfd]
	    }
	}
	default {
	    vfs::filesystem posixerror $::vfs::posix(EROFS)
	}
    }
}

proc vfs::zip::createdirectory {zipfd name} {
    #::vfs::log "createdirectory $name"
    vfs::filesystem posixerror $::vfs::posix(EROFS)
}

proc vfs::zip::removedirectory {zipfd name recursive} {
    #::vfs::log "removedirectory $name"
    vfs::filesystem posixerror $::vfs::posix(EROFS)
}

proc vfs::zip::deletefile {zipfd name} {
    #::vfs::log "deletefile $name"
    vfs::filesystem posixerror $::vfs::posix(EROFS)
}

proc vfs::zip::fileattributes {zipfd name args} {
    #::vfs::log "fileattributes $args"
    switch -- [llength $args] {
	0 {
	    # list strings
	    return [list]
	}
	1 {
	    # get value
	    set index [lindex $args 0]
	    return ""
	}
	2 {
	    # set value
	    set index [lindex $args 0]
	    set val [lindex $args 1]
	    vfs::filesystem posixerror $::vfs::posix(EROFS)
	}
    }
}

proc vfs::zip::utime {fd path actime mtime} {
    vfs::filesystem posixerror $::vfs::posix(EROFS)
}

# Below copied from TclKit distribution

#
# ZIP decoder:
#
# See the ZIP file format specification:
#   http://www.pkware.com/documents/casestudies/APPNOTE.TXT
#
# Format of zip file:
# [ Data ]* [ TOC ]* EndOfArchive
#
# Note: TOC is refered to in ZIP doc as "Central Archive"
#
# This means there are two ways of accessing:
#
# 1) from the begining as a stream - until the header
#	is not "PK\03\04" - ideal for unzipping.
#
# 2) for table of contents without reading entire
#	archive by first fetching EndOfArchive, then
#	just loading the TOC
#

namespace eval zip {
    set zseq 0

    array set methods {
	0	{stored - The file is stored (no compression)}
	1	{shrunk - The file is Shrunk}
	2	{reduce1 - The file is Reduced with compression factor 1}
	3	{reduce2 - The file is Reduced with compression factor 2}
	4	{reduce3 - The file is Reduced with compression factor 3}
	5	{reduce4 - The file is Reduced with compression factor 4}
	6	{implode - The file is Imploded}
	7	{reserved - Reserved for Tokenizing compression algorithm}
	8	{deflate - The file is Deflated}
	9	{reserved - Reserved for enhanced Deflating}
	10	{pkimplode - PKWARE Date Compression Library Imploding}
        11	{reserved - Reserved by PKWARE}
        12	{bzip2 - The file is compressed using BZIP2 algorithm}
        13	{reserved - Reserved by PKWARE}
        14	{lzma - LZMA (EFS)}
        15	{reserved - Reserved by PKWARE}
    }
    # Version types (high-order byte)
    array set systems {
	0	{dos}
	1	{amiga}
	2	{vms}
	3	{unix}
	4	{vm cms}
	5	{atari}
	6	{os/2}
	7	{macos}
	8	{z system 8}
	9	{cp/m}
	10	{tops20}
	11	{windows}
	12	{qdos}
	13	{riscos}
	14	{vfat}
	15	{mvs}
	16	{beos}
	17	{tandem}
	18	{theos}
    }
    # DOS File Attrs
    array set dosattrs {
	1	{readonly}
	2	{hidden}
	4	{system}
	8	{unknown8}
	16	{directory}
	32	{archive}
	64	{unknown64}
	128	{normal}
    }

    proc u_short {n}  { return [expr { ($n+0x10000)%0x10000 }] }
}

proc zip::DosTime {date time} {
    set time [u_short $time]
    set date [u_short $date]

    # time = fedcba9876543210
    #        HHHHHmmmmmmSSSSS (sec/2 actually)

    # data = fedcba9876543210
    #        yyyyyyyMMMMddddd

    set sec  [expr { ($time & 0x1F) * 2 }]
    set min  [expr { ($time >> 5) & 0x3F }]
    set hour [expr { ($time >> 11) & 0x1F }]

    set mday [expr { $date & 0x1F }]
    set mon  [expr { (($date >> 5) & 0xF) }]
    set year [expr { (($date >> 9) & 0xFF) + 1980 }]

    # Fix up bad date/time data, no need to fail
    if {$sec  > 59} {set sec  59}
    if {$min  > 59} {set min  59}
    if {$hour > 23} {set hour 23}
    if {$mday < 1}  {set mday 1}
    if {$mday > 31} {set mday 31}
    if {$mon  < 1}  {set mon  1}
    if {$mon > 12}  {set mon  12}

    set res 0
    catch {
	set dt [format {%4.4d-%2.2d-%2.2d %2.2d:%2.2d:%2.2d} \
		    $year $mon $mday $hour $min $sec]
	set res [clock scan $dt -gmt 1]
    }

    return $res
}

proc zip::ParseDataHeader {fd arr {dataVar ""}} {
    upvar 1 $arr sb

    upvar 1 $arr sb

    # APPNOTE A: Local file header
    set buf [read $fd 30]
    set n [binary scan $buf A4sssssiiiss \
               hdr sb(ver) sb(flags) sb(method) time date \
               crc csize size namelen xtralen]

    if { ![string equal "PK\03\04" $hdr] } {
	binary scan $hdr H* x
	return -code error "bad header: $x"
    }
    set sb(ver)	   [expr {$sb(ver) & 0xffff}]
    set sb(flags)  [expr {$sb(flags) & 0xffff}]
    set sb(method) [expr {$sb(method) & 0xffff}]
    set sb(mtime)  [DosTime $date $time]
    if {!($sb(flags) & (1<<3))} {
        set sb(crc)    [expr {$crc & 0xffffffff}]
        set sb(csize)  [expr {$csize & 0xffffffff}]
        set sb(size)   [expr {$size & 0xffffffff}]
    }

    set sb(name)   [read $fd [expr {$namelen & 0xffff}]]
    set sb(extra)  [read $fd [expr {$xtralen & 0xffff}]]
    if {$sb(flags) & (1 << 11)} {
        set sb(name) [encoding convertfrom utf-8 $sb(name)]
    }
    set sb(name) [string trimleft $sb(name) "./"]

    # APPNOTE B: File data
    #   if bit 3 of flags is set the csize comes from the central directory
    set offset [tell $fd]
    if {$dataVar != ""} {
	upvar 1 $dataVar data
	set data [read $fd $sb(csize)]
    }  else  {
	seek $fd $sb(csize) current
    }

    # APPNOTE C: Data descriptor
    if { $sb(flags) & (1<<3) } {
        binary scan [read $fd 4] i ddhdr
        if {($ddhdr & 0xffffffff) == 0x08074b50} {
            binary scan [read $fd 12] iii sb(crc) sb(csize) sb(size)
        } else {
            set sb(crc) $ddhdr
            binary scan [read $fd 8] ii sb(csize) sb(size)
        }
        set sb(crc) [expr {$sb(crc) & 0xffffffff}]
        set sb(csize) [expr {$sb(csize) & 0xffffffff}]
        set sb(size) [expr {$sb(size) & 0xffffffff}]
    }
    return $offset
}

proc zip::Data {fd arr verify} {
    upvar 1 $arr sb
    ParseDataHeader $fd $arr data
    switch -exact -- $sb(method) {
        0 {
            # stored; no compression
        }
        8 {
            # deflated
            if {[catch {
                set data [vfs::zip -mode decompress -nowrap 1 $data]
            } err]} then {
                return -code error "error inflating \"$sb(name)\": $err"
            }
        }
        default {
            set method $sb(method)
            if {[info exists methods($method)]} {
                set method $methods($method)
            }
            return -code error "unsupported compression method
                \"$method\" used for \"$sb(name)\""
        }
    }

    if { $verify && $sb(method) != 0} {
	set ncrc [vfs::crc $data]
	if { ($ncrc & 0xffffffff) != $sb(crc) } {
	    vfs::log [format {%s: crc mismatch: expected 0x%x, got 0x%x} \
                          $sb(name) $sb(crc) $ncrc]
	}
    }
    return $data
}

proc zip::EndOfArchive {fd arr} {
    upvar 1 $arr cb

    # [SF Tclvfs Bug 1003574]. Do not seek over beginning of file.
    seek $fd 0 end

    # Just looking in the last 512 bytes may be enough to handle zip
    # archives without comments, however for archives which have
    # comments the chunk may start at an arbitrary distance from the
    # end of the file. So if we do not find the header immediately
    # we have to extend the range of our search, possibly until we
    # have a large part of the archive in memory. We can fail only
    # after the whole file has been searched.

    set sz  [tell $fd]
    if {[info exists ::zip::max_header_seek]} {
        if {$::zip::max_header_seek < $sz} {
            set sz $::zip::max_header_seek
        }
    }
    set len 512
    set at  512
    while {1} {
	if {$sz < $at} {set n -$sz} else {set n -$at}

	seek $fd $n end
	set hdr [read $fd $len]

	# We are using 'string last' as we are searching the first
	# from the end, which is the last from the beginning. See [SF
	# Bug 2256740]. A zip archive stored in a zip archive can
	# confuse the unmodified code, triggering on the magic
	# sequence for the inner, uncompressed archive.
	set pos [string last "PK\05\06" $hdr]
	if {$pos == -1} {
	    if {$at >= $sz} {
		return -code error "no header found"
	    }
	    set len 540 ; # after 1st iteration we force overlap with last buffer
	    incr at 512 ; # to ensure that the pattern we look for is not split at
	    #           ; # a buffer boundary, nor the header itself
	} else {
	    break
	}
    }

     set hdrlen [string length $hdr]
     set hdr [string range $hdr [expr $pos + 4] [expr $pos + 21]]
 
     set pos [expr {wide([tell $fd]) + $pos - $hdrlen}]
 
     if {$pos < 0} {
         set pos 0
     }

    binary scan $hdr ssssiis \
	cb(ndisk) cb(cdisk) \
	cb(nitems) cb(ntotal) \
	cb(csize) cb(coff) \
	cb(comment)

    set cb(ndisk)	[u_short $cb(ndisk)]
    set cb(nitems)	[u_short $cb(nitems)]
    set cb(ntotal)	[u_short $cb(ntotal)]
    set cb(comment)	[u_short $cb(comment)]

    # Compute base for situations where ZIP file
    # has been appended to another media (e.g. EXE)
    set base            [expr { $pos - $cb(csize) - $cb(coff) }]
    if {$base < 0} {
        set base 0
    }
    set cb(base)	$base

    if {$cb(coff) < 0} {
	set cb(base) [expr {wide($cb(base)) - 4294967296}]
	set cb(coff) [expr {wide($cb(coff)) + 4294967296}]
    }
}

proc zip::TOC {fd arr} {
    upvar #0 zip::$fd cb
    upvar #0 zip::$fd.dir cbdir
    upvar 1 $arr sb

    set buf [read $fd 46]

    binary scan $buf A4ssssssiiisssssii hdr \
      sb(vem) sb(ver) sb(flags) sb(method) time date \
      sb(crc) sb(csize) sb(size) \
      flen elen clen sb(disk) sb(attr) \
      sb(atx) sb(ino)

    set sb(ino) [expr {$cb(base) + $sb(ino)}]

    if { ![string equal "PK\01\02" $hdr] } {
	binary scan $hdr H* x
	return -code error "bad central header: $x"
    }

    foreach v {vem ver flags method disk attr} {
	set sb($v) [expr {$sb($v) & 0xffff}]
    }
    set sb(crc) [expr {$sb(crc) & 0xffffffff}]
    set sb(csize) [expr {$sb(csize) & 0xffffffff}]
    set sb(size) [expr {$sb(size) & 0xffffffff}]
    set sb(mtime) [DosTime $date $time]
    set sb(mode) [expr { ($sb(atx) >> 16) & 0xffff }]
    # check atx field or mode field if this is a directory
    if { ((( $sb(atx) & 0xff ) & 16) != 0) || (($sb(mode) & 0x4000) != 0) } {
	set sb(type) directory
    } else {
	set sb(type) file
    }
    set sb(name) [read $fd [u_short $flen]]
    set sb(extra) [read $fd [u_short $elen]]
    set sb(comment) [read $fd [u_short $clen]]
    while {$sb(ino) < 0} {
	set sb(ino) [expr {wide($sb(ino)) + 4294967296}]
    }
    if {$sb(flags) & (1 << 11)} {
        set sb(name) [encoding convertfrom utf-8 $sb(name)]
        set sb(comment) [encoding convertfrom utf-8 $sb(comment)]
    }
    set sb(name) [string trimleft $sb(name) "./"]
    set parent [file dirname $sb(name)]
    if {$parent == "."} {set parent ""}
    lappend cbdir([string tolower $parent]) [file tail [string trimright $sb(name) /]]
}

proc zip::open {path} {
    #vfs::log [list open $path]
    set fd [::open $path]
    
    if {[catch {
	upvar #0 zip::$fd cb
	upvar #0 zip::$fd.toc toc
	upvar #0 zip::$fd.dir cbdir

	fconfigure $fd -translation binary ;#-buffering none
	
	zip::EndOfArchive $fd cb

	seek $fd [expr {$cb(base) + $cb(coff)}] start

	set toc(_) 0; unset toc(_); #MakeArray
	
	for {set i 0} {$i < $cb(nitems)} {incr i} {
	    zip::TOC $fd sb
	    
	    set origname [string trimright $sb(name) /]
	    set sb(depth) [llength [file split $sb(name)]]
	    
	    set name [string tolower $origname]
	    set sba [array get sb]
	    set toc($name) $sba
	    FAKEDIR toc cbdir [file dirname $origname]
	}
	foreach {n v} [array get cbdir] {
	    set cbdir($n) [lsort -unique $v]
	}
    } err]} {
	close $fd
	return -code error $err
    }

    return $fd
}

proc zip::FAKEDIR {tocarr cbdirarr origpath} {
    upvar 1 $tocarr toc $cbdirarr cbdir

    set path [string tolower $origpath]
    if { $path == "."} { return }

    if { ![info exists toc($path)] } {
	# Implicit directory
	lappend toc($path) \
		name $origpath \
		type directory mtime 0 size 0 mode 0777 \
		ino -1 depth [llength [file split $path]]
	
	set parent [file dirname $path]
	if {$parent == "."} {set parent ""}
	lappend cbdir($parent) [file tail $origpath]
    }
    FAKEDIR toc cbdir [file dirname $origpath]
}

proc zip::exists {fd path} {
    #::vfs::log "$fd $path"
    if {$path == ""} {
	return 1
    } else {
	upvar #0 zip::$fd.toc toc
	info exists toc([string tolower $path])
    }
}

proc zip::stat {fd path arr} {
    upvar #0 zip::$fd.toc toc
    upvar 1 $arr sb
    #vfs::log [list stat $fd $path $arr [info level -1]]

    set name [string tolower $path]
    if { $name == "" || $name == "." } {
	array set sb {
	    type directory mtime 0 size 0 mode 0777 
	    ino -1 depth 0 name ""
	}
    } elseif {![info exists toc($name)] } {
	return -code error "could not read \"$path\": no such file or directory"
    } else {
	array set sb $toc($name)
    }
    set sb(dev) -1
    set sb(uid)	-1
    set sb(gid)	-1
    set sb(nlink) 1
    set sb(atime) $sb(mtime)
    set sb(ctime) $sb(mtime)
    return ""
}

# Treats empty pattern as asking for a particular file only
proc zip::getdir {fd path {pat *}} {
    #::vfs::log [list getdir $fd $path $pat]
    upvar #0 zip::$fd.toc toc
    upvar #0 zip::$fd.dir cbdir

    if { $path == "." || $path == "" } {
	set path ""
    }  else  {
	set path [string tolower $path]
    }

    if {$pat == ""} {
	if {[info exists cbdir($path)]} {
	    return [list $path]
	}  else  {
	    return [list]
	}
    }

    set rc [list]
    if {[info exists cbdir($path)]} {
	if {$pat == "*"} {
	    set rc $cbdir($path)
	}  else  {
	    foreach f $cbdir($path) {
		if {[string match -nocase $pat $f]} {
		    lappend rc $f
		}
	    }
	}
    }
    return $rc
}

proc zip::_close {fd} {
    variable $fd
    variable $fd.toc
    variable $fd.dir
    unset $fd
    unset $fd.toc
    unset $fd.dir
    ::close $fd
}

# Implementation of stream based decompression for zip
if {([info commands ::rechan] != "") || ([info commands ::chan] != "")} {
    if {![catch {package require Tcl 8.6}]} {
	# implementation using [zlib stream inflate] and [rechan]/[chan create]
	proc ::zip::zstream_create {fd} {
	    upvar #0 ::zip::_zstream_zcmd($fd) zcmd
	    if {$zcmd == ""} {
		set zcmd [zlib stream inflate]
	    }
	}
	proc ::zip::zstream_delete {fd} {
	    upvar #0 ::zip::_zstream_zcmd($fd) zcmd
	    if {$zcmd != ""} {
		rename $zcmd ""
		set zcmd ""
	    }
	}

	proc ::zip::zstream_put {fd data} {
	    upvar #0 ::zip::_zstream_zcmd($fd) zcmd
	    zstream_create $fd
	    $zcmd put $data
	}

	proc ::zip::zstream_get {fd} {
	    upvar #0 ::zip::_zstream_zcmd($fd) zcmd
	    zstream_create $fd
	    return [$zcmd get]
	}

	set ::zip::useStreaming 1
    }  elseif {![catch {zlib sinflate ::zip::__dummycommand ; rename ::zip::__dummycommand ""}]} {
	proc ::zip::zstream_create {fd} {
	    upvar #0 ::zip::_zstream_zcmd($fd) zcmd
	    if {$zcmd == ""} {
		set zcmd ::zip::_zstream_cmd_$fd
		zlib sinflate $zcmd
	    }
	}
	proc ::zip::zstream_delete {fd} {
	    upvar #0 ::zip::_zstream_zcmd($fd) zcmd
	    if {$zcmd != ""} {
		rename $zcmd ""
		set zcmd ""
	    }
	}

	proc ::zip::zstream_put {fd data} {
	    upvar #0 ::zip::_zstream_zcmd($fd) zcmd
	    zstream_create $fd
	    $zcmd fill $data
	}

	proc ::zip::zstream_get {fd} {
	    upvar #0 ::zip::_zstream_zcmd($fd) zcmd
	    zstream_create $fd
	    set rc ""
	    while {[$zcmd fill] != 0} {
		if {[catch {
		    append rc [$zcmd drain 4096]
		}]} {
		    break
		}
	    }
	    return $rc
	}

	set ::zip::useStreaming 1
    }  else  {
	set ::zip::useStreaming 0
    }
}  else  {
    set ::zip::useStreaming 0
}

proc ::zip::eventClean {fd} {
    variable eventEnable
    eventSet $fd 0
}

proc ::zip::eventWatch {fd a} {
    if {[lindex $a 0] == "read"} {
	eventSet $fd 1
    }  else  {
	eventSet $fd 0
    }
}

proc zip::eventSet {fd e} {
    variable eventEnable
    set cmd [list ::zip:::eventPost $fd]
    after cancel $cmd
    if {$e} {
	set eventEnable($fd) 1
	after 0 $cmd
    }  else  {
	catch {unset eventEnable($fd)}
    }
}

proc zip::eventPost {fd} {
    variable eventEnable
    if {[info exists eventEnable($fd)] && $eventEnable($fd)} {
	chan postevent $fd read
	eventSet $fd 1
    }
}

proc ::zip::zstream {ifd clen ilen} {
    set start [tell $ifd]
    set cmd [list ::zip::zstream_handler $start $ifd $clen $ilen]
    if {[catch {
	set fd [chan create read $cmd]
    }]} {
	set fd [rechan $cmd 2]
    }
    set ::zip::_zstream_buf($fd) ""
    set ::zip::_zstream_pos($fd) 0
    set ::zip::_zstream_tell($fd) $start
    set ::zip::_zstream_zcmd($fd) ""
    return $fd
}

proc ::zip::zstream_handler {istart ifd clen ilen cmd fd {a1 ""} {a2 ""}} {
    upvar #0 ::zip::_zstream_pos($fd) pos
    upvar #0 ::zip::_zstream_buf($fd) buf
    upvar #0 ::zip::_zstream_tell($fd) tell
    upvar #0 ::zip::_zstream_zcmd($fd) zcmd
    switch -- $cmd {
	initialize {
	    return [list initialize finalize watch read seek]
	}
	watch {
	    eventWatch $fd $a1
	}
	seek {
	    switch $a2 {
		1 - current { incr a1 $pos }
		2 - end { incr a1 $ilen }
	    }
	    # to seek back, rewind, i.e. start from scratch
	    if {$a1 < $pos} {
		zstream_delete $fd
		seek $ifd $istart
		set pos 0
		set buf ""
		set tell $istart
	    }

	    while {$pos < $a1} {
		set n [expr {$a1 - $pos}]
		if {$n > 4096} { set n 4096 }
		zstream_handler $istart $ifd $clen $ilen read $fd $n
	    }
	    return $pos
	}

	read {
	    set r ""
	    set n $a1
	    if {$n + $pos > $ilen} { set n [expr {$ilen - $pos}] }

	    while {$n > 0} {
		set chunk [string range $buf 0 [expr {$n - 1}]]
		set buf [string range $buf $n end]
		incr n -[string length $chunk]
		incr pos [string length $chunk]
		append r $chunk

		if {$n > 0} {
		    set c [expr {$istart + $clen - [tell $ifd]}]
		    if {$c > 4096} { set c 4096 }
		    if {$c <= 0} {
			break
		    }
		    seek $ifd $tell start
		    set data [read $ifd $c]
		    set tell [tell $ifd]
		    zstream_put $fd $data
		    while {[string length [set bufdata [zstream_get $fd]]] > 0} {
			append buf $bufdata
		    }
		}
	    }
	    return $r
	}
	close - finalize {
	    eventClean $fd
	    if {$zcmd != ""} {
		rename $zcmd ""
	    }
	    unset pos
	}
    }
}

proc ::zip::rawstream_handler {ifd ioffset ilen cmd fd {a1 ""} {a2 ""} args} {
    upvar ::zip::_rawstream_pos($fd) pos
    switch -- $cmd {
	initialize {
	    return [list initialize finalize watch read seek]
	}
	watch {
	    eventWatch $fd $a1
	}
	seek {
	    switch $a2 {
		1 - current { incr a1 $pos }
		2 - end { incr a1 $ilen }
	    }
	    if {$a1 < 0} {set a1 0}
	    if {$a1 > $ilen} {set a1 $ilen}
	    set pos $a1
	    return $pos
	}
	read {
	    seek $ifd $ioffset
	    seek $ifd $pos current
	    set n $a1
	    if {$n + $pos > $ilen} { set n [expr {$ilen - $pos}] }
	    set fc [read $ifd $n]
	    incr pos [string length $fc]
	    return $fc
	}
	close - finalize {
	    eventClean $fd
	    unset pos
	}
    }
}

proc ::zip::rawstream {ifd ilen} {
    set cname _rawstream_[incr ::zip::zseq]
    set start [tell $ifd]
    set cmd [list ::zip::rawstream_handler $ifd $start $ilen]
    if {[catch {
	set fd [chan create read $cmd]
    }]} {
	set fd [rechan $cmd 2]
    }
    set ::zip::_rawstream_pos($fd) 0
    return $fd
}

