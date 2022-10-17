#
# Copyright (c) 2012-2014, Ashok P. Nadkarni
# All rights reserved.
#
# See the file LICENSE for license

# Event log handling for Vista and later

namespace eval twapi {
    variable _evt;              # See _evt_init

    # System event fields in order returned by _evt_decode_event_system_fields
    twapi::record evt_system_fields  {
        -providername -providerguid -eventid -qualifiers -level -task
        -opcode -keywordmask -timecreated -eventrecordid -activityid
        -relatedactivityid -pid -tid -channel
        -computer -sid -version
    }

    proc _evt_init {} {
        variable _evt

        # Various structures that we maintain / cache for efficiency as they
        # are commonly used are kept in the _evt array with the following keys:

        # system_render_context_handle - is the handle to a rendering
        #    context for the system portion of an event
        set _evt(system_render_context_handle) [evt_render_context_system]

        # user_render_context_handle - is the handle to a rendering
        #    context for the user data portion of an event
        set _evt(user_render_context_handle) [evt_render_context_user]

        # render_buffer - is NULL or holds a pointer to the buffer used to
        #    retrieve values so does not have to be reallocated every time.
        set _evt(render_buffer) NULL

        # publisher_handles - caches publisher names to their meta information.
        #    This is a dictionary indexed with nested keys - 
        #     publisher, session, lcid. TBD - need a mechanism to clear ?
        set _evt(publisher_handles) [dict create]

        # -levelname - dict of publisher name / level number to level names
        set _evt(-levelname) {}

        # -taskname - dict of publisher name / task number to task name
        set _evt(-taskname) {}

        # -opcodename - dict of publisher name / opcode number to opcode name
        set _evt(-opcodename) {}

        # No-op the proc once init is done
        proc _evt_init {} {}
    }
}

# TBD - document
proc twapi::evt_local_session {} {
    return NULL
}

# TBD - document
proc twapi::evt_local_session? {hsess} {
    return [pointer_null? $hsess]
}

# TBD - document
proc twapi::evt_open_session {server args} {
    array set opts [parseargs args {
        user.arg
        domain.arg
        password.arg
        {authtype.arg 0}
    } -nulldefault -maxleftover 0]

    if {![string is integer -strict $opts(authtype)]} {
        set opts(authtype) [dict get {default 0 negotiate 1 kerberos 2 ntlm 3} [string tolower $opts(authtype)]]
    }

    return [EvtOpenSession 1 [list $server $opts(user) $opts(domain) $opts(password) $opts(authtype)] 0 0]
}

# TBD - document
proc twapi::evt_close_session {hsess} {
    if {![evt_local_session? $hsess]} {
        evt_close $hsess
    }
}

proc twapi::evt_channels {{hevtsess NULL}} {
    # TBD - document hevtsess
    set chnames {}
    set hevt [EvtOpenChannelEnum $hevtsess 0]
    trap {
        while {[set chname [EvtNextChannelPath $hevt]] ne ""} {
            lappend chnames $chname
        }
    } finally {
        evt_close $hevt
    }

    return $chnames
}

proc twapi::evt_clear_log {chanpath args} {
    # TBD - document -session
    array set opts [parseargs args {
        {session.arg NULL}
        {backup.arg ""}
    } -maxleftover 0]

    return [EvtClearLog $opts(session) $chanpath [_evt_normalize_path $opts(backup)] 0]
}

# TBD - document
proc twapi::evt_archive_exported_log {logpath args} {
    array set opts [parseargs args {
        {session.arg NULL}
        {lcid.int 0}
    } -maxleftover 0]

    return [EvtArchiveExportedLog $opts(session) [_evt_normalize_path $logpath] $opts(lcid) 0]
}

proc twapi::evt_export_log {outfile args} {
    # TBD - document -session
    array set opts [parseargs args {
        {session.arg NULL}
        file.arg
        channel.arg
        {query.arg *}
        {ignorequeryerrors 0 0x1000}
    } -maxleftover 0]

    if {([info exists opts(file)] && [info exists opts(channel)]) ||
        ! ([info exists opts(file)] || [info exists opts(channel)])} {
        error "Exactly one of -file or -channel must be specified."
    }

    if {[info exists opts(file)]} {
        set path [_evt_normalize_path $opts(file)]
        incr opts(ignorequeryerrors) 2
    } else {
        set path $opts(channel)
        incr opts(ignorequeryerrors) 1
    }

    return [EvtExportLog $opts(session) $path $opts(query) [_evt_normalize_path $outfile] $opts(ignorequeryerrors)]
}

# TBD - document
proc twapi::evt_create_bookmark {{mark ""}} {
    return [EvtCreateBookmark $mark]
}

# TBD - document
proc twapi::evt_render_context_xpaths {xpaths} {
    return [EvtCreateRenderContext $xpaths 0]
}

# TBD - document
proc twapi::evt_render_context_system {} {
    return [EvtCreateRenderContext {} 1]
}

# TBD - document
proc twapi::evt_render_context_user {} {
    return [EvtCreateRenderContext {} 2]
}

# TBD - document
proc twapi::evt_open_channel_config {chanpath args} {
    array set opts [parseargs args {
        {session.arg NULL}
    } -maxleftover 0]

    return [EvtOpenChannelConfig $opts(session) $chanpath 0]
}

# TBD - document
proc twapi::evt_get_channel_config {hevt args} {
    set result {}
    foreach opt $args {
        lappend result $opt \
            [EvtGetChannelConfigProperty $hevt \
                 [_evt_map_channel_config_property $hevt $propid]]
    }
    return $result
}

# TBD - document
proc twapi::evt_set_channel_config {hevt propid val} {
    return [EvtSetChannelConfigProperty $hevt [_evt_map_channel_config_property $propid 0 $val]]
}


# TBD - document
proc twapi::_evt_map_channel_config_property {propid} {
    if {[string is integer -strict $propid]} {
        return $propid
    }
    
    # Note: values are from winevt.h, Win7 SDK has typos for last few
    return [dict get {
        -enabled                  0
        -isolation                1
        -type                     2
        -owningpublisher          3
        -classiceventlog          4
        -access                   5
        -loggingretention         6
        -loggingautobackup        7
        -loggingmaxsize           8
        -logginglogfilepath       9
        -publishinglevel          10
        -publishingkeywords       11
        -publishingcontrolguid    12
        -publishingbuffersize     13
        -publishingminbuffers     14
        -publishingmaxbuffers     15
        -publishinglatency        16
        -publishingclocktype      17
        -publishingsidtype        18
        -publisherlist            19
        -publishingfilemax        20
    } $propid]
}

# TBD - document
proc twapi::evt_event_info {hevt args} {
    set result {}
    foreach opt $args {
        lappend result $opt [EvtGetEventInfo $hevt \
                                 [dict get {-queryids 0 -path 1} $opt]]
    }
    return $result
}


# TBD - document
proc twapi::evt_event_metadata_property {hevt args} {
    set result {}
    foreach opt $args {
        lappend result $opt \
            [EvtGetEventMetadataProperty $hevt \
                 [dict get {
                     -id 0 -version 1 -channel 2 -level 3
                     -opcode 4 -task 5 -keyword 6 -messageid 7 -template 8
                 } $opt]]
    }
    return $result
}


# TBD - document
proc twapi::evt_open_log_info {args} {
    array set opts [parseargs args {
        {session.arg NULL}
        file.arg
        channel.arg
    } -maxleftover 0]

    if {([info exists opts(file)] && [info exists opts(channel)]) ||
        ! ([info exists opts(file)] || [info exists opts(channel)])} {
        error "Exactly one of -file or -channel must be specified."
    }
    
    if {[info exists opts(file)]} {
        set path [_evt_normalize_path $opts(file)]
        set flags 0x2
    } else {
        set path $opts(channel)
        set flags 0x1
    }

    return [EvtOpenLog $opts(session) $path $flags]
}

# TBD - document
proc twapi::evt_log_info {hevt args} {
    set result {}
    foreach opt $args {
        lappend result $opt  [EvtGetLogInfo $hevt [dict get {
            -creationtime 0 -lastaccesstime 1 -lastwritetime 2
            -filesize 3 -attributes 4 -numberoflogrecords 5
            -oldestrecordnumber 6 -full 7
        } $opt]]
    }
    return $result
}

# TBD - document
proc twapi::evt_publisher_metadata_property {hpub args} {
    set result {}
    foreach opt $args {
        set val [EvtGetPublisherMetadataProperty $hpub [dict get {
            -publisherguid 0  -resourcefilepath 1 -parameterfilepath 2
            -messagefilepath 3 -helplink 4 -publishermessageid 5
            -channelreferences 6 -levels 12 -tasks 16
            -opcodes 21 -keywords 25
        } $opt] 0]
        if {$opt ni {-channelreferences -levels -tasks -opcodes -keywords}} {
            lappend result $opt $val
            continue
        }
        set n [EvtGetObjectArraySize $val]
        set val2 {}
        for {set i 0} {$i < $n} {incr i} {
            set rec {}
            foreach {opt2 iopt} [dict get {
                -channelreferences { -channelreferencepath 7
                    -channelreferenceindex 8 -channelreferenceid 9
                    -channelreferenceflags 10 -channelreferencemessageid 11}
                -levels { -levelname 13 -levelvalue 14 -levelmessageid 15 }
                -tasks { -taskname 17 -taskeventguid 18 -taskvalue 19
                    -taskmessageid 20}
                -opcodes {-opcodename 22 -opcodevalue 23 -opcodemessageid 24}
                -keywords {-keywordname 26 -keywordvalue 27
                    -keywordmessageid 28}
            } $opt] {
                lappend rec $opt2 [EvtGetObjectArrayProperty $val $iopt $i]
            }
            lappend val2 $rec
        }

        evt_close $val
        lappend result $opt $val2
    }
    return $result
}

# TBD - document
proc twapi::evt_query_info {hq args} {
    set result {}
    foreach opt $args {
        lappend result $opt  [EvtGetQueryInfo $hq [dict get {
            -names 1 statuses 2
        } $opt]]
    }
    return $result
}

# TBD - document
proc twapi::evt_object_array_size {hevt} {
    return [EvtGetObjectArraySize $hevt]
}

# TBD - document
proc twapi::evt_object_array_property {hevt index args} {
    set result {}

    foreach opt $args {
        lappend result $opt \
            [EvtGetObjectArrayProperty $hevt [dict get {
                -channelreferencepath 7
                -channelreferenceindex 8 -channelreferenceid 9
                -channelreferenceflags 10 -channelreferencemessageid 11
                -levelname 13 -levelvalue 14 -levelmessageid 15
                -taskname 17 -taskeventguid 18 -taskvalue 19
                -taskmessageid 20 -opcodename 22
                -opcodevalue 23 -opcodemessageid 24
                -keywordname 26 -keywordvalue 27 -keywordmessageid 28
            }] $index]
    }
    return $result
}

proc twapi::evt_publishers {{hsess NULL}} {
    set pubs {}
    set hevt [EvtOpenPublisherEnum $hsess 0]
    trap {
        while {[set pub [EvtNextPublisherId $hevt]] ne ""} {
            lappend pubs $pub
        }
    } finally {
        evt_close $hevt
    }

    return $pubs
}

# TBD - document
proc twapi::evt_open_publisher_metadata {pub args} {
    array set opts [parseargs args {
        {session.arg NULL}
        logfile.arg
        lcid.int
    } -nulldefault -maxleftover 0]

    return [EvtOpenPublisherMetadata $opts(session) $pub $opts(logfile) $opts(lcid) 0]
}

# TBD - document
proc twapi::evt_publisher_events_metadata {hpub args} {
    set henum [EvtOpenEventMetadataEnum $hpub]

    # It is faster to build a list and then have Tcl shimmer to a dict when
    # required
    set meta {}
    trap {
        while {[set hmeta [EvtNextEventMetadata $henum 0]] ne ""} {
            lappend meta [evt_event_metadata_property $hmeta {*}$args]
            evt_close $hmeta
        }
    } finally {
        evt_close $henum
    }
    
    return $meta
}

proc twapi::evt_query {args} {
    array set opts [parseargs args {
        {session.arg NULL}
        file.arg
        channel.arg
        {query.arg *}
        {ignorequeryerrors 0 0x1000}
        {direction.sym forward {forward 0x100 reverse 0x200 backward 0x200}}
    } -maxleftover 0]

    if {([info exists opts(file)] && [info exists opts(channel)]) ||
        ! ([info exists opts(file)] || [info exists opts(channel)])} {
        error "Exactly one of -file or -channel must be specified."
    }
    
    set flags $opts(ignorequeryerrors)
    incr flags $opts(direction)

    if {[info exists opts(file)]} {
        set path [_evt_normalize_path $opts(file)]
        incr flags 0x2
    } else {
        set path $opts(channel)
        incr flags 0x1
    }

    return [EvtQuery $opts(session) $path $opts(query) $flags]
}

proc twapi::evt_next {hresultset args} {
    array set opts [parseargs args {
        {timeout.int -1}
        {count.int 1}
        {status.arg}
    } -maxleftover 0]

    if {[info exists opts(status)]} {
        upvar 1 $opts(status) status
        return [EvtNext $hresultset $opts(count) $opts(timeout) 0 status]
    } else {
        return [EvtNext $hresultset $opts(count) $opts(timeout) 0]
    }
}

twapi::proc* twapi::_evt_decode_event_system_fields {hevt} {
    _evt_init
} {
    variable _evt
    set _evt(render_buffer) [Twapi_EvtRenderValues $_evt(system_render_context_handle) $hevt $_evt(render_buffer)]
    set rec [Twapi_ExtractEVT_RENDER_VALUES $_evt(render_buffer)]
    return [evt_system_fields set $rec \
                -providername [atomize [evt_system_fields -providername $rec]] \
                -providerguid [atomize [evt_system_fields -providerguid $rec]] \
                -channel [atomize [evt_system_fields -channel $rec]] \
                -computer [atomize [evt_system_fields -computer $rec]]]
}

# TBD - document. Returns a list of user data values
twapi::proc* twapi::evt_decode_event_userdata {hevt} {
    _evt_init
} {
    variable _evt
    set _evt(render_buffer) [Twapi_EvtRenderValues $_evt(user_render_context_handle) $hevt $_evt(render_buffer)]
    return [Twapi_ExtractEVT_RENDER_VALUES $_evt(render_buffer)]
}

twapi::proc* twapi::evt_decode_events {hevts args} {
    _evt_init
} {
    variable _evt

    array set opts [parseargs args {
        {values.arg NULL}
        {session.arg NULL}
        {logfile.arg ""}
        {lcid.int 0}
        ignorestring.arg
        message
        levelname
        taskname
        opcodename
        keywords
        xml
    } -ignoreunknown -hyphenated]
        
    # SAME ORDER AS _evt_decode_event_system_fields
    set decoded_fields [evt_system_fields]
    set decoded_events {}
    
    # ORDER MUST BE SAME AS order in which values are appended below
    foreach opt {-levelname -taskname -opcodename -keywords -xml -message} {
        if {$opts($opt)} {
            lappend decoded_fields $opt
        }
    }

    foreach hevt $hevts {
        set decoded [_evt_decode_event_system_fields $hevt]
        # Get publisher from hevt
        set publisher [evt_system_fields -providername $decoded]

        if {! [dict exists $_evt(publisher_handles) $publisher $opts(-session) $opts(-lcid)]} {
            if {[catch {
                dict set _evt(publisher_handles) $publisher $opts(-session) $opts(-lcid) [EvtOpenPublisherMetadata $opts(-session) $publisher $opts(-logfile) $opts(-lcid) 0]
            }]} {
                # TBD - debug log
                dict set _evt(publisher_handles) $publisher $opts(-session) $opts(-lcid) NULL
            }
        }
        set hpub [dict get $_evt(publisher_handles) $publisher $opts(-session) $opts(-lcid)]

        # See if cached values are present for -levelname -taskname
        # and -opcodename. TBD - can -keywords be added to this ?
        foreach {intopt opt callflag} {-level -levelname 2 -task -taskname 3 -opcode -opcodename 4} {
            if {$opts($opt)} {
                set ival [evt_system_fields $intopt $decoded]
                if {[dict exists $_evt($opt) $publisher $ival]} {
                    lappend decoded [dict get $_evt($opt) $publisher $ival]
                } else {
                    # Not cached. Look it up. Value of 0 -> null so
                    # just use ignorestring if specified.
                    if {$ival == 0 && [info exists opts(-ignorestring)]} {
                        set optval $opts(-ignorestring)
                    } else {
                        if {[info exists opts(-ignorestring)]} {
                            if {[EvtFormatMessage $hpub $hevt 0 $opts(-values) $callflag optval]} {
                                dict set _evt($opt) $publisher $ival $optval
                            } else {
                                # Note result not cached if not found since
                                # ignorestring may be different on every call
                                set optval $opts(-ignorestring)
                            }
                        } else {
                            # -ignorestring not specified so
                            # will raise error if not found
                            set optval [EvtFormatMessage $hpub $hevt 0 $opts(-values) $callflag]
                            dict set _evt($opt) $publisher $ival [atomize $optval]
                        }
                    }
                    lappend decoded $optval
                }
            }
        }

        # Non-cached fields
        # ORDER MUST BE SAME AS decoded_fields ABOVE
        foreach {opt callflag} {
            -keywords 5
            -xml 9
        } {
            if {$opts($opt)} {
                if {[info exists opts(-ignorestring)]} {
                    if {! [EvtFormatMessage $hpub $hevt 0 $opts(-values) $callflag optval]} {
                        set optval $opts(-ignorestring)
                    }
                } else {
                    set optval [EvtFormatMessage $hpub $hevt 0 $opts(-values) $callflag]
                }
                lappend decoded $optval
            }
        }

        # We treat -message differently because on failure we want
        # to extract the user data. -ignorestring is not used for this
        # unless user data extraction also fails
        if {$opts(-message)} {
            if {[EvtFormatMessage $hpub $hevt 0 $opts(-values) 1 message]} {
                lappend decoded $message
            } else {
                # TBD - make sure we have a test for this case.
                # TBD - log
                if {[catch {
                    lappend decoded "Message for event could not be found. Event contained user data: [join [evt_decode_event_userdata $hevt] ,]"
                } message]} {
                    if {[info exists opts(-ignorestring)]} {
                        lappend decoded $opts(-ignorestring)
                    } else {
                        error $message
                    }
                }
            }
        }
        
        lappend decoded_events $decoded
    }

    return [list $decoded_fields $decoded_events]
}

proc twapi::evt_decode_event {hevt args} {
    return [recordarray index [evt_decode_events [list $hevt] {*}$args] 0 -format dict]
}

# TBD - document
proc twapi::evt_format_publisher_message {hpub msgid args} {

    array set opts [parseargs args {
        {values.arg NULL}
    } -maxleftover 0]
        
    return [EvtFormatMessage $hpub NULL $msgid $opts(values) 8]
}

# TBD - document
# Where is this used?
proc twapi::evt_free_EVT_VARIANT_ARRAY {p} {
    evt_free $p
}

# TBD - document
# Where is this used?
proc twapi::evt_free_EVT_RENDER_VALUES {p} {
    evt_free $p
}

# TBD - document
proc twapi::evt_seek {hresults pos args} {
    array set opts [parseargs args {
        {origin.arg first {first last current}}
        bookmark.arg
        {strict 0 0x10000}
    } -maxleftover 0]

    if {[info exists opts(bookmark)]} {
        set flags 4
    } else {
        set flags [lsearch -exact {first last current} $opts(origin)]
        incr flags;             # 1 -> first, 2 -> last, 3 -> current
        set opts(bookmark) NULL
    }
        
    incr flags $opts(strict)

    EvtSeek $hresults $pos $opts(bookmark) 0 $flags
}

proc twapi::evt_subscribe {path args} {
    # TBD - document -session and -bookmark and -strict
    array set opts [parseargs args {
        {session.arg NULL}
        {query.arg *}
        bookmark.arg
        includeexisting
        {ignorequeryerrors 0 0x1000}
        {strict 0 0x10000}
    } -maxleftover 0]

    set flags [expr {$opts(ignorequeryerrors) | $opts(strict)}]
    if {[info exists opts(bookmark)]} {
        set flags [expr {$flags | 3}]
        set bookmark $opts(origin)
    } else {
        set bookmark NULL
        if {$opts(includeexisting)} {
            set flags [expr {$flags | 2}]
        } else {
            set flags [expr {$flags | 1}]
        }
    }

    set hevent [lindex [CreateEvent [_make_secattr {} 0] 0 0 ""] 0]
    if {[catch {
        EvtSubscribe $opts(session) $hevent $path $opts(query) $bookmark $flags
    } hsubscribe]} {
        set erinfo $::errorInfo
        set ercode $::errorCode
        CloseHandle $hevent
        error $hsubscribe $erinfo $ercode
    }

    return [list $hsubscribe $hevent]
}

proc twapi::_evt_normalize_path {path} {
    # Do not want to rely on [file normalize] returning "" for ""
    if {$path eq ""} {
        return ""
    } else {
        return [file nativename [file normalize $path]]
    }
}

proc twapi::_evt_dump {args} {
    array set opts [parseargs args {
        {outfd.arg stdout}
        count.int
    } -ignoreunknown]

    set hq [evt_query {*}$args]
    trap {
        while {[llength [set hevts [evt_next $hq]]]} {
            trap {
                foreach ev [recordarray getlist [evt_decode_events $hevts -message -ignorestring None.] -format dict] {
                    if {[info exists opts(count)] &&
                        [incr opts(count) -1] < 0} {
                        return
                    }
                    puts $opts(outfd) "[dict get $ev -timecreated] [dict get $ev -eventrecordid] [dict get $ev -providername]: [dict get $ev -eventrecordid] [dict get $ev -message]"
                }
            } finally {
                evt_close {*}$hevts
            }
        }
    } finally {
        evt_close $hq
    }
}
