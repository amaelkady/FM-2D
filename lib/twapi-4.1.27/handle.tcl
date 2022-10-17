#
# Copyright (c) 2010, Ashok P. Nadkarni
# All rights reserved.
#
# See the file LICENSE for license

namespace eval twapi {
    # Array maps handles we are waiting on to the ids of the registered waits
    variable _wait_handle_ids
    # Array maps id of registered wait to the corresponding callback scripts
    variable _wait_handle_scripts
    
}

proc twapi::cast_handle {h type} {
    # TBD - should this use pointer_from_address:
    #    return [pointer_from_address [address_from_pointer $h] $type]
    return [list [lindex $h 0] $type]
}

proc twapi::close_handle {h} {

    # Cancel waits on the handle, if any
    cancel_wait_on_handle $h
    
    # Then close it
    CloseHandle $h
}

# Close multiple handles. In case of errors, collects them but keeps
# closing remaining handles and only raises the error at the end.
proc twapi::close_handles {args} {
    # The original definition for this was broken in that it would
    # gracefully accept non list parameters as a list of one. In 3.0
    # the handle format has changed so this does not happen
    # naturally. We have to try and decipher whether it is a list
    # of handles or a single handle.

    foreach arg $args {
        if {[pointer? $arg]} {
            # Looks like a single handle
            if {[catch {close_handle $arg} msg]} {
                set erinfo $::errorInfo
                set ercode $::errorCode
                set ermsg $msg
            }
        } else {
            # Assume a list of handles
            foreach h $arg {
                if {[catch {close_handle $h} msg]} {
                    set erinfo $::errorInfo
                    set ercode $::errorCode
                    set ermsg $msg
                }
            }
        }
    }

    if {[info exists erinfo]} {
        error $msg $erinfo $ercode
    }
}

#
# Wait on a handle
proc twapi::wait_on_handle {hwait args} {
    variable _wait_handle_ids
    variable _wait_handle_scripts

    # When we are invoked from callback, handle is always typed as HANDLE
    # so convert it so lookups succeed
    set h [cast_handle $hwait HANDLE]

    # 0x00000008 ->   # WT_EXECUTEONCEONLY
    array set opts [parseargs args {
        {wait.int -1}
        async.arg
        {executeonce.bool false 0x00000008}
    }]

    if {![info exists opts(async)]} {
        if {[info exists _wait_handle_ids($h)]} {
            error "Attempt to synchronously wait on handle that is registered for an asynchronous wait."
        }

        set ret [WaitForSingleObject $h $opts(wait)]
        if {$ret == 0x80} {
            return abandoned
        } elseif {$ret == 0} {
            return signalled
        } elseif {$ret == 0x102} {
            return timeout
        } else {
            error "Unexpected value $ret returned from WaitForSingleObject"
        }
    }

    # async option specified

    # Do not wait on manual reset events as cpu will spin continuously
    # queueing events
    if {[pointer? $hwait HANDLE_MANUALRESETEVENT] &&
        ! $opts(executeonce)
    } {
        error "A handle to a manual reset event cannot be waited on asynchronously unless -executeonce is specified."
    }

    # If handle already registered, cancel previous registration.
    if {[info exists _wait_handle_ids($h)]} {
        cancel_wait_on_handle $h
    }


    set id [Twapi_RegisterWaitOnHandle $h $opts(wait) $opts(executeonce)]

    # Set now that successfully registered
    set _wait_handle_scripts($id) $opts(async)
    set _wait_handle_ids($h) $id

    return
}

#
# Cancel an async wait on a handle
proc twapi::cancel_wait_on_handle {h} {
    variable _wait_handle_ids
    variable _wait_handle_scripts

    if {[info exists _wait_handle_ids($h)]} {
        Twapi_UnregisterWaitOnHandle $_wait_handle_ids($h)
        unset _wait_handle_scripts($_wait_handle_ids($h))
        unset _wait_handle_ids($h)
    }
}

#
# Called from C when a handle is signalled or times out
proc twapi::_wait_handler {id h event} {
    variable _wait_handle_ids
    variable _wait_handle_scripts

    # We ignore the following stale event cases -
    #  - _wait_handle_ids($h) does not exist : the wait was canceled while
    #    and event was queued
    #  - _wait_handle_ids($h) exists but is different from $id - same
    #    as prior case, except that a new wait has since been initiated
    #    on the same handle value (which might have be for a different
    #    resource

    if {[info exists _wait_handle_ids($h)] &&
        $_wait_handle_ids($h) == $id} {
        uplevel #0 [linsert $_wait_handle_scripts($id) end $h $event]
    }

    return
}

# Get the handle for a Tcl channel
proc twapi::get_tcl_channel_handle {chan direction} {
    set direction [expr {[string equal $direction "write"] ? 1 : 0}]
    return [Tcl_GetChannelHandle $chan $direction]
}

# Duplicate a OS handle
proc twapi::duplicate_handle {h args} {
    variable my_process_handle

    array set opts [parseargs args {
        sourcepid.int
        targetpid.int
        access.arg
        inherit
        closesource
    } -maxleftover 0]

    # Assume source and target processes are us
    set source_ph $my_process_handle
    set target_ph $my_process_handle

    if {[string is wideinteger $h]} {
        set h [pointer_from_address $h HANDLE]
    }

    trap {
        set me [pid]
        # If source pid specified and is not us, get a handle to the process
        if {[info exists opts(sourcepid)] && $opts(sourcepid) != $me} {
            set source_ph [get_process_handle $opts(sourcepid) -access process_dup_handle]
        }

        # Ditto for target process...
        if {[info exists opts(targetpid)] && $opts(targetpid) != $me} {
            set target_ph [get_process_handle $opts(targetpid) -access process_dup_handle]
        }

        # Do we want to close the original handle (DUPLICATE_CLOSE_SOURCE)
        set flags [expr {$opts(closesource) ? 0x1: 0}]

        if {[info exists opts(access)]} {
            set access [_access_rights_to_mask $opts(access)]
        } else {
            # If no desired access is indicated, we want the same access as
            # the original handle
            set access 0
            set flags [expr {$flags | 0x2}]; # DUPLICATE_SAME_ACCESS
        }


        set dup [DuplicateHandle $source_ph $h $target_ph $access $opts(inherit) $flags]

        # IF targetpid specified, return handle else literal
        # (even if targetpid is us)
        if {[info exists opts(targetpid)]} {
            set dup [pointer_to_address $dup]
        }
    } finally {
        if {$source_ph != $my_process_handle} {
            CloseHandle $source_ph
        }
        if {$target_ph != $my_process_handle} {
            CloseHandle $source_ph
        }
    }

    return $dup
}

proc twapi::set_handle_inheritance {h inherit} {
    # 1 -> HANDLE_FLAG_INHERIT
    SetHandleInformation $h 0x1 [expr {$inherit ? 1 : 0}]
}

proc twapi::get_handle_inheritance {h} {
    # 1 -> HANDLE_FLAG_INHERIT
    return [expr {[GetHandleInformation $h] & 1}]
}
