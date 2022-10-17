#
# Copyright (c) 2004, Ashok P. Nadkarni
# All rights reserved.
#
# See the file LICENSE for license
#
# TBD - document
# TBD - tcl wrappers for semaphores

namespace eval twapi {
}

#
# Create and return a handle to a mutex
proc twapi::create_mutex {args} {
    array set opts [parseargs args {
        name.arg
        secd.arg
        inherit.bool
        lock.bool
    } -nulldefault -maxleftover 0]

    if {$opts(name) ne "" && $opts(lock)} {
        # TBD - remove this mutex limitation
        # This is not a Win32 limitation but ours. Would need to change the C
        # implementation and our return format
        error "Option -lock must not be specified as true if mutex is named"
    }

    return [CreateMutex [_make_secattr $opts(secd) $opts(inherit)] $opts(lock) $opts(name)]
}

# Get handle to an existing mutex
proc twapi::open_mutex {name args} {
    array set opts [parseargs args {
        {inherit.bool 0}
        {access.arg {mutex_all_access}}
    } -maxleftover 0]
    
    return [OpenMutex [_access_rights_to_mask $opts(access)] $opts(inherit) $name]
}

# Lock the mutex
proc twapi::lock_mutex {h args} {
    array set opts [parseargs args {
        {wait.int -1}
    }]

    return [wait_on_handle $h -wait $opts(wait)]
}


# Unlock the mutex
proc twapi::unlock_mutex {h} {
    ReleaseMutex $h
}

#
# Create and return a handle to a event
proc twapi::create_event {args} {
    array set opts [parseargs args {
        name.arg
        secd.arg
        inherit.bool
        signalled.bool
        manualreset.bool
        existvar.arg
    } -nulldefault -maxleftover 0]

    if {$opts(name) ne "" && $opts(signalled)} {
        # Not clear whether event will be signalled state if it already
        # existed but was not signalled
        error "Option -signalled must not be specified as true if event is named."
    }

    lassign [CreateEvent [_make_secattr $opts(secd) $opts(inherit)] $opts(manualreset) $opts(signalled) $opts(name)]  h preexisted
    if {$opts(manualreset)} {
        # We want to catch attempts to wait on manual reset handles
        set h [cast_handle $h HANDLE_MANUALRESETEVENT]
    }
    if {$opts(existvar) ne ""} {
        upvar 1 $opts(existvar) existvar
        set existvar $preexisted
    }

    return $h
}

interp alias {} twapi::set_event {} twapi::SetEvent
interp alias {} twapi::reset_event {} twapi::ResetEvent

