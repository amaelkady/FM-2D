#
# Copyright (c) 2004-2012, Ashok P. Nadkarni
# All rights reserved.
#
# See the file LICENSE for license

package require registry

namespace eval twapi {
    # We maintain caches so we do not do lookups all the time
    # TBD - have a means of clearing this out
    variable _eventlog_message_cache
    set _eventlog_message_cache {}
}


# Read the event log
proc twapi::eventlog_read {hevl args} {
    _eventlog_valid_handle $hevl read raise

    array set opts [parseargs args {
        seek.int
        {direction.arg forward}
    }]

    if {[info exists opts(seek)]} {
        set flags 2;                    # Seek
        set offset $opts(seek)
    } else {
        set flags 1;                    # Sequential read
        set offset 0
    }

    switch -glob -- $opts(direction) {
        ""    -
        forw* {
            setbits flags 4
        }
        back* {
            setbits flags 8
        }
        default {
            error "Invalid value '$opts(direction)' for -direction option"
        }
    }

    set results [list ]

    trap {
        set recs [ReadEventLog $hevl $flags $offset]
    } onerror {TWAPI_WIN32 38} {
        # EOF - no more
        set recs [list ]
    }
    foreach event $recs {
        dict set event -type [string map {0 success 1 error 2 warning 4 information 8 auditsuccess 16 auditfailure} [dict get $event -level]]
        lappend results $event
    }

    return $results
}


# Get the oldest event log record index. $hevl must be read handle
proc twapi::eventlog_oldest {hevl} {
    _eventlog_valid_handle $hevl read raise
    return [GetOldestEventLogRecord $hevl]
}

# Get the event log record count. $hevl must be read handle
proc twapi::eventlog_count {hevl} {
    _eventlog_valid_handle $hevl read raise
    return [GetNumberOfEventLogRecords $hevl]
}

# Check if the event log is full. $hevl may be either read or write handle
# (only win2k plus)
proc twapi::eventlog_is_full {hevl} {
    # Does not matter if $hevl is read or write, but verify it is a handle
    _eventlog_valid_handle $hevl read
    return [Twapi_IsEventLogFull $hevl]
}

# Backup the event log
proc twapi::eventlog_backup {hevl file} {
    _eventlog_valid_handle $hevl read raise
    BackupEventLog $hevl $file
}

# Clear the event log
proc twapi::eventlog_clear {hevl args} {
    _eventlog_valid_handle $hevl read raise
    array set opts [parseargs args {backup.arg} -nulldefault]
    ClearEventLog $hevl $opts(backup)
}


# Formats the given event log record message
# 
proc twapi::eventlog_format_message {rec args} {
    variable _eventlog_message_cache

    array set opts [parseargs args {
        width.int
        langid.int
    } -nulldefault]

    set source  [dict get $rec -source]
    set eventid [dict get $rec -eventid]

    if {[dict exists $_eventlog_message_cache $source fmtstring $opts(langid) $eventid]} {
        set fmtstring [dict get $_eventlog_message_cache $source fmtstring $opts(langid) $eventid]
        dict incr _eventlog_message_cache __fmtstring_hits
    } else {
        dict incr _eventlog_message_cache __fmtstring_misses

        # Find the registry key if we do not have it already
        if {[dict exists $_eventlog_message_cache $source regkey]} {
            dict incr _eventlog_message_cache __regkey_hits
            set regkey [dict get $_eventlog_message_cache $source regkey]
        } else {
            set regkey [_find_eventlog_regkey $source]
            dict set _eventlog_message_cache $source regkey $regkey
            dict incr _eventlog_message_cache __regkey_misses
        }

        # Get the message file, if there is one
        if {! [catch {registry get $regkey "EventMessageFile"} path]} {
            # Try each file listed in turn
            foreach dll [split $path \;] {
                set dll [expand_environment_strings $dll]
                if {! [catch {
                    set fmtstring [format_message -module $dll -messageid $eventid -width $opts(width) -langid $opts(langid)]
                } msg]} {
                    dict set _eventlog_message_cache $source fmtstring $opts(langid) $eventid $fmtstring
                    break
                }
            }
        }
    }

    if {! [info exists fmtstring]} {
        dict incr _eventlog_message_cache __notfound

        set fmt "The message file or event definition for event id [dict get $rec -eventid] from source [dict get $rec -source] was not found. The following information was part of the event: "
        set flds [list ]
        for {set i 1} {$i <= [llength [dict get $rec -params]]} {incr i} {
            lappend flds %$i
        }
        append fmt [join $flds ", "]
        return [format_message -fmtstring $fmt  \
                    -params [dict get $rec -params] -width $opts(width)]
    }

    set msg [format_message -fmtstring $fmtstring -params [dict get $rec -params]]

    # We'd found a message from the message file and replaced the string
    # parameters. Now fill in the parameter file values if any. Note these are
    # separate from the string parameters passed in through rec(-params)

    # First check if the formatted string itself still has placeholders
    # Place holder for the parameters file are supposed to start
    # with two % chars. Unfortunately, not all apps, even Microsoft's own
    # DCOM obey this. So check for both % and %%
    set placeholder_indices [regexp -indices -all -inline {%?%\d+} $msg]
    if {[llength $placeholder_indices] == 0} {
        # No placeholders.
        return $msg
    }

    # Loop through to replace placeholders.
    set msg2 "";                # Holds result after param replacement
    set prev_end 0
    foreach placeholder $placeholder_indices {
        lassign $placeholder start end
        # Append the stuff between previous placeholder and this one
        append msg2 [string range $msg $prev_end [expr {$start-1}]]
        set repl [string range $msg $start $end]; # Default if not found
        set paramid [string trimleft $repl %];     # Skip "%"
        if {[dict exists $_eventlog_message_cache $source paramstring $opts(langid) $paramid]} {
            dict incr _eventlog_message_cache __paramstring_hits
            set repl [format_message -fmtstring [dict get $_eventlog_message_cache $source paramstring $opts(langid) $paramid] -params [dict get $rec -params]]
        } else {
            dict incr _eventlog_message_cache __paramstring_misses
            # Not in cache, need to look up
            if {![info exists paramfiles]} {
                # Construct list of parameter string files

                # TBD - cache registry key results?
                # Find the registry key if we do not have it already
                if {![info exists regkey]} {
                    if {[dict exists $_eventlog_message_cache $source regkey]} {
                        dict incr _eventlog_message_cache __regkey_hits
                        set regkey [dict get $_eventlog_message_cache $source regkey]
                    } else {
                        dict incr _eventlog_message_cache __regkey_misses
                        set regkey [_find_eventlog_regkey $source]
                        dict set _eventlog_message_cache $source regkey $regkey
                    }
                }
                set paramfiles {}
                if {! [catch {registry get $regkey "ParameterMessageFile"} path]} {
                    # Loop through every placeholder, look for the entry in the
                    # parameters file and replace it if found
                    foreach paramfile [split $path \;] {
                        lappend paramfiles [expand_environment_strings $paramfile]
                    }
                }
            }
            # Try each file listed in turn
            foreach paramfile $paramfiles {
                if {! [catch {
                    set paramstring [string trimright [format_message -module $paramfile -messageid $paramid -langid $opts(langid)] \r\n]
                } ]} {
                    # Found the replacement
                    dict set _eventlog_message_cache $source paramstring $opts(langid) $paramid $paramstring
                    set repl [format_message -fmtstring $paramstring -params [dict get $rec -params]]
                    break
                }
            }
        }
        append msg2 $repl
        set prev_end [incr end]
    }
    
    # Tack on tail after last placeholder
    append msg2 [string range $msg $prev_end end]
    return $msg2
}

# Format the category
proc twapi::eventlog_format_category {rec args} {

    array set opts [parseargs args {
        width.int
        langid.int
    } -nulldefault]

    set category [dict get $rec -category]
    if {$category == 0} {
        return ""
    }

    variable _eventlog_message_cache

    set source  [dict get $rec -source]

    # Get the category string from cache, if there is one
    if {[dict exists $_eventlog_message_cache $source category $opts(langid) $category]} {
        dict incr _eventlog_message_cache __category_hits
        set fmtstring [dict get $_eventlog_message_cache $source category $opts(langid) $category]
    } else {
        dict incr _eventlog_message_cache __category_misses

        # Find the registry key if we do not have it already
        if {[dict exists $_eventlog_message_cache $source regkey]} {
            dict incr _eventlog_message_cache __regkey_hits
            set regkey [dict get $_eventlog_message_cache $source regkey]
        } else {
            set regkey [_find_eventlog_regkey $source]
            dict set _eventlog_message_cache $source regkey $regkey
            dict incr _eventlog_message_cache __regkey_misses
        }

        if {! [catch {registry get $regkey "CategoryMessageFile"} path]} {
            # Try each file listed in turn
            foreach dll [split $path \;] {
                set dll [expand_environment_strings $dll]
                if {! [catch {
                    set fmtstring [format_message -module $dll -messageid $category -width $opts(width) -langid $opts(langid)]
                } msg]} {
                    dict set _eventlog_message_cache $source category $opts(langid) $category $fmtstring
                    break
                }
            }
        }
    }

    if {![info exists fmtstring]} {
        set fmtstring "Category $category"
        dict set _eventlog_message_cache $source category $opts(langid) $category $fmtstring
    }

    return [format_message -fmtstring $fmtstring -params [dict get $rec -params]]
}

proc twapi::eventlog_monitor_start {hevl script} {
    variable _eventlog_notification_scripts

    set hevent [lindex [CreateEvent [_make_secattr {} 0] 0 0 ""] 0]
    if {[catch {NotifyChangeEventLog $hevl $hevent} msg]} {
        CloseHandle $hevent
        error $msg $::errorInfo $::errorCode
    }

    wait_on_handle $hevent -async twapi::_eventlog_notification_handler
    set _eventlog_notification_scripts($hevent) $script

    # We do not want the application mistakenly closing the event
    # while being waited on by the thread pool. That would be a big NO-NO
    # so change the handle type so it cannot be passed to close_handle.
    return [list evl $hevent]
}

# Stop any notifications. Note these will stop even if the event log
# handle is closed but leave the event dangling.
proc twapi::eventlog_monitor_stop {hevent} {
    variable _eventlog_notification_scripts
    set hevent [lindex $hevent 1]
    if {[info exists _eventlog_notification_scripts($hevent)]} {
        unset _eventlog_notification_scripts($hevent)
        cancel_wait_on_handle $hevent
        CloseHandle $hevent
    }
}

proc twapi::_eventlog_notification_handler {hevent event} {
    variable _eventlog_notification_scripts
    if {[info exists _eventlog_notification_scripts($hevent)] &&
        $event eq "signalled"} {
        uplevel #0 $_eventlog_notification_scripts($hevent) [list [list evl $hevent]]
    }
}

# TBD - document
proc twapi::eventlog_subscribe {source} {
    set hevl [eventlog_open -source $source]
    set hevent [lindex [CreateEvent [_make_secattr {} 0] 0 0 ""] 0]
    if {[catch {NotifyChangeEventLog $hevl $hevent} msg]} {
        set erinfo $::errorInfo
        set ercode $::errorCode
        CloseHandle $hevent
        error $hsubscribe $erinfo $ercode
    }

    return [list $hevl $hevent]
}

# Utility procs

# Find the registry key corresponding the given event log source
proc twapi::_find_eventlog_regkey {source} {
    set topkey {HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Eventlog}

    # Set a default list of children to work around an issue in
    # the Tcl [registry keys] command where a ERROR_MORE_DATA is returned
    # instead of a retry with a larger buffer.
    set keys {Application Security System}
    catch {set keys [registry keys $topkey]}
    # Get all keys under this key and look for a source under that
    foreach key $keys {
        # See above Tcl issue
        set srckeys {}
        catch {set srckeys [registry keys "${topkey}\\$key"]}
        foreach srckey $srckeys {
            if {[string equal -nocase $srckey $source]} {
                return "${topkey}\\${key}\\$srckey"
            }
        }
    }

    # Default to Application - TBD
    return "${topkey}\\Application"
}

proc twapi::_eventlog_dump {source chan} {
    set hevl [eventlog_open -source $source]
    while {[llength [set events [eventlog_read $hevl]]]} {
        # print out each record
        foreach eventrec $events {
            array set event $eventrec
            set timestamp [clock format $event(-timewritten) -format "%x %X"]
            set source   $event(-source)
            set category [twapi::eventlog_format_category $eventrec -width -1]
            set message  [twapi::eventlog_format_message $eventrec -width -1]
            puts $chan "$timestamp  $source  $category  $message"
        }
    }
    eventlog_close $hevl
}




# If we are being sourced ourselves, then we need to source the remaining files.
if {[file tail [info script]] eq "eventlog.tcl"} {
    source [file join [file dirname [info script]] evt.tcl]
    source [file join [file dirname [info script]] winlog.tcl]
}
