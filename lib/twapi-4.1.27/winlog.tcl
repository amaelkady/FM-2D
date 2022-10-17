#
# Copyright (c) 2012, Ashok P. Nadkarni
# All rights reserved.
#
# See the file LICENSE for license

# Routines to unify old and new Windows event log APIs

namespace eval twapi {
    # Dictionary to map eventlog consumer handles to various related info
    # The primary key is the read handle to the event channel/source.
    # Nested keys depend on OS version
    variable _winlog_handles
}

proc twapi::winlog_open {args} {
    variable _winlog_handles

    # TBD - document -authtype
    array set opts [parseargs args {
        {system.arg ""}
        channel.arg
        file.arg
        {authtype.arg 0}
        {direction.arg forward {forward backward}}
    } -maxleftover 0]

    if {[info exists opts(file)] &&
        ($opts(system) ne "" || [info exists opts(channel)])} {
        error "Option '-file' cannot be used with '-channel' or '-system'"
    } else {
        if {![info exists opts(channel)]} {
            set opts(channel) "Application"
        }
    }
    
    if {[min_os_version 6]} {
        # Use new Vista APIs
        if {[info exists opts(file)]} {
            set hsess NULL
            set hq [evt_query -file $opts(file) -ignorequeryerrors]
        } else {
            if {$opts(system) eq ""} {
                set hsess [twapi::evt_local_session]
            } else {
                set hsess [evt_open_session $opts(system) -authtype $opts(authtype)]
            }
            # evt_query will not read new events from a channel once
            # eof is reached. So if reading in forward direction, we use
            # evt_subscribe. Backward it does not matter.
            if {$opts(direction) eq "forward"} {
                lassign [evt_subscribe $opts(channel) -session $hsess -ignorequeryerrors -includeexisting] hq signal
                dict set _winlog_handles $hq signal $signal
            } else {
                set hq [evt_query -session $hsess -channel $opts(channel) -ignorequeryerrors -direction $opts(direction)]
            }
        }
        
        dict set _winlog_handles $hq session $hsess
    } else {
        if {[info exists opts(file)]} {
            set hq [eventlog_open -file $opts(file)]
            dict set _winlog_handles $hq channel $opts(file)
        } else {
            set hq [eventlog_open -system $opts(system) -source $opts(channel)]
            dict set _winlog_handles $hq channel $opts(channel)
        }
        dict set _winlog_handles $hq direction $opts(direction)
    }
    return $hq
}

proc twapi::winlog_close {hq} {
    variable _winlog_handles

    if {! [dict exists $_winlog_handles $hq]} {
        error "Invalid event consumer handler '$hq'"
    }

    if {[dict exists $_winlog_handles $hq signal]} {
        # Catch in case app has closed event directly, for
        # example when returned through winlog_subscribe
        catch {close_handle [dict get $_winlog_handles $hq signal]}
    }
    if {[min_os_version 6]} {
        set hsess [dict get $_winlog_handles $hq session]
        evt_close $hq
        evt_close_session $hsess
    } else {
        eventlog_close $hq
    }

    dict unset _winlog_handles $hq
    return
}

proc twapi::winlog_event_count {args} {
    # TBD - document and -authtype
    array set opts [parseargs args {
        {system.arg ""}
        channel.arg
        file.arg
        {authtype.arg 0}
    } -maxleftover 0]

    if {[info exists opts(file)] &&
        ($opts(system) ne "" || [info exists opts(channel)])} {
        error "Option '-file' cannot be used with '-channel' or '-system'"
    } else {
        if {![info exists opts(channel)]} {
            set opts(channel) "Application"
        }
    }

    if {[min_os_version 6]} {
        # Use new Vista APIs
        trap {
            if {[info exists opts(file)]} {
                set hsess NULL
                set hevl [evt_open_log_info -file $opts(file)]
            } else {
                if {$opts(system) eq ""} {
                    set hsess [twapi::evt_local_session]
                } else {
                    set hsess [evt_open_session $opts(system) -authtype $opts(authtype)]
                }
                set hevl [evt_open_log_info -session $hsess -channel $opts(channel)]
            }
            return [lindex [evt_log_info $hevl -numberoflogrecords] 1]
        } finally {
            if {[info exists hsess]} {
                evt_close_session $hsess
            }
            if {[info exists hevl]} {
                evt_close $hevl
            }
        }
    } else {
        if {[info exists opts(file)]} {
            set hevl [eventlog_open -file $opts(file)]
        } else {
            set hevl [eventlog_open -system $opts(system) -source $opts(channel)]
        }

        trap {
            return [eventlog_count $hevl]
        } finally {
            eventlog_close $hevl
        }
    }
}

if {[twapi::min_os_version 6]} {

    proc twapi::winlog_read {hq args} {
        parseargs args {
            {lcid.int 0}
        } -setvars -maxleftover 0

        # TBD - is 10 an appropriate number of events to read?
        set events [evt_next $hq -timeout 0 -count 10 -status status]
        if {[llength $events]} {
            trap {
                set result [evt_decode_events $events -lcid $lcid -ignorestring "" -message -levelname -taskname]
            } finally {
                evt_close {*}$events
            }
            return $result
        }

        # No events were returned. Check status whether it is fatal error
        # or not. SUCCESS, NO_MORE_ITEMS, TIMEOUT, INVALID_OPERATION
        # are acceptable. This last happens when another EvtNext is done
        # after an NO_MORE_ITEMS is already returned.
        if {$status == 0 || $status == 259 || $status == 1460 || $status == 4317} {
            # Even though $events is empty, still pass it in so it returns
            # an empty record array in the correct format.
            return [evt_decode_events $events -lcid $lcid -ignorestring "" -message -levelname -taskname]
        } else {
            win32_error $status
        }
    }

    proc twapi::winlog_subscribe {channelpath} {
        variable _winlog_handles
        lassign [evt_subscribe $channelpath -ignorequeryerrors] hq signal
        dict set _winlog_handles $hq signal $signal
        dict set _winlog_handles $hq session NULL; # local session
        return [list $hq $signal]
    }

    interp alias {} twapi::winlog_clear {} twapi::evt_clear_log

    proc twapi::winlog_backup {channel outpath} {
        evt_export_log $outpath -channel $channel
        return
    }

} else {

    proc twapi::winlog_read {hq args} {
        parseargs args {
            {lcid.int 0}
        } -setvars -maxleftover 0

        variable _winlog_handles
        set fields {-channel -taskname -message -providername -eventid -level -levelname -eventrecordid -computer -sid -timecreated}
        set values {}
        set channel [dict get $_winlog_handles $hq channel]
        foreach evl [eventlog_read $hq -direction [dict get $_winlog_handles $hq direction]] {
            # Note order must be same as fields above
            lappend values \
                [list \
                     $channel \
                     [eventlog_format_category $evl -langid $lcid] \
                     [eventlog_format_message $evl -langid $lcid -width -1] \
                     [dict get $evl -source] \
                     [dict get $evl -eventid] \
                     [dict get $evl -level] \
                     [dict get $evl -type] \
                     [dict get $evl -recordnum] \
                     [dict get $evl -system] \
                     [dict get $evl -sid] \
                     [secs_since_1970_to_large_system_time [dict get $evl -timewritten]]]
        }
        return [list $fields $values]
    }

    proc twapi::winlog_subscribe {source} {
        variable _winlog_handles
        lassign [eventlog_subscribe $source] hq hevent
        dict set _winlog_handles $hq channel $source
        dict set _winlog_handles $hq direction forward
        dict set _winlog_handles $hq signal $hevent
        return [list $hq $hevent]
    }

    proc twapi::winlog_clear {source args} {
        set hevl [eventlog_open -source $source]
        trap {
            eventlog_clear $hevl {*}$args
        } finally {
            eventlog_close $hevl
        }
        return
    }

    proc twapi::winlog_backup {source outpath} {
        set hevl [eventlog_open -source $source]
        trap {
            eventlog_backup $hevl $outpath
        } finally {
            eventlog_close $hevl
        }
        return
    }

}


proc twapi::_winlog_dump_list {{channels {Application System Security}} {atomize 0}} {
    set evlist {}
    foreach channel $channels {
        set hevl [winlog_open -channel $channel]
        trap {
            while {[llength [set events [winlog_read $hevl]]]} {
                foreach e [recordarray getlist $events -format dict] {
                    if {$atomize} {
                        dict set ev -message [atomize [dict get $e -message]]
                        dict set ev -levelname [atomize [dict get $e -levelname]]
                        dict set ev -channel [atomize [dict get $e -channel]]
                        dict set ev -providername [atomize [dict get $e -providername]]
                        dict set ev -taskname [atomize [dict get $e -taskname]]
                        dict set ev -eventid [atomize [dict get $e -eventid]]
                        dict set ev -account [atomize [dict get $e -userid]]
                    } else {
                        dict set ev -message [dict get $e -message]
                        dict set ev -levelname [dict get $e -levelname]
                        dict set ev -channel [dict get $e -channel]
                        dict set ev -providername [dict get $e -providername]
                        dict set ev -taskname [dict get $e -taskname]
                        dict set ev -eventid [dict get $e -eventid]
                        dict set ev -account [dict get $e -userid]
                    }
                    lappend evlist $ev
                }
            }
        } finally {
            winlog_close $hevl
        }
    }
    return $evlist
}

proc twapi::_winlog_dump {{channel Application} {fd stdout}} {
    set hevl [winlog_open -channel $channel]
    while {[llength [set events [winlog_read $hevl]]]} {
        # print out each record
        foreach ev [recordarray getlist $events -format dict] {
            puts $fd "[dict get $ev -timecreated] [dict get $ev -providername]: [dict get $ev -message]"
        }
    }
    winlog_close $hevl
}
