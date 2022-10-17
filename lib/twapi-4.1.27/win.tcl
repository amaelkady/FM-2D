#
# Copyright (c) 2012 Ashok P. Nadkarni
# All rights reserved.
#
# See the file LICENSE for license

# Contains common windowing and notification infrastructure

namespace eval twapi {
    variable null_hwin ""

    # Windows messages that are directly accessible from script. These
    # are handled by the default notifications window and passed to
    # the twapi::_script_wm_handler. These messages must be in the
    # range (1056 = 1024+32) - (1024+32+31) (see twapi_wm.h)
    variable _wm_script_msgs
    array set _wm_script_msgs {
        TASKBAR_RESTART      1031
        NOTIFY_ICON_CALLBACK 1056
    }
    proc _get_script_wm {tok} {
        variable _wm_script_msgs
        return $_wm_script_msgs($tok)
    }
}

# Backward compatibility aliases
interp alias {} twapi::GetWindowLong {} twapi::GetWindowLongPtr
interp alias {} twapi::SetWindowLong {} twapi::SetWindowLongPtr

# Return the long value at the given index
# This is a raw function, and should generally be used only to get
# non-system defined indices
proc twapi::get_window_long {hwin index} {
    return [GetWindowLongPtr $hwin $index]
}

# Set the long value at the given index and return the previous value
# This is a raw function, and should generally be used only to get
# non-system defined indices
proc twapi::set_window_long {hwin index val} {
    set oldval [SetWindowLongPtr $hwin $index $val]
}

# Set the user data associated with a window. Returns the previous value
proc twapi::set_window_userdata {hwin val} {
    # GWL_USERDATA -> -21
    return [SetWindowLongPtr $hwin -21 $val]
}

# Attaches to the thread queue of the thread owning $hwin and executes
# script in the caller's scope
proc twapi::_attach_hwin_and_eval {hwin script} {
    set me [GetCurrentThreadId]
    set hwin_tid [lindex [GetWindowThreadProcessId $hwin] 0]
    if {$hwin_tid == 0} {
        error "Window $hwin does not exist or could not get its thread owner"
    }

    # Cannot (and no need to) attach to oneself so just exec script directly
    if {$me == $hwin_tid} {
        return [uplevel 1 $script]
    }

    trap {
        if {![AttachThreadInput $me $hwin_tid 1]} {
            error "Could not attach to thread input for window $hwin"
        }
        set result [uplevel 1 $script]
    } finally {
        AttachThreadInput $me $hwin_tid 0
    }

    return $result
}

proc twapi::_register_script_wm_handler {msg cmdprefix {overwrite 0}} {
    variable _wm_registrations

    # Ensure notification window exists
    twapi::Twapi_GetNotificationWindow

    # The incr ensures decimal format
    # The lrange ensure proper list format
    if {$overwrite} {
        set _wm_registrations([incr msg 0]) [list [lrange $cmdprefix 0 end]]
    } else {
        lappend _wm_registrations([incr msg 0]) [lrange $cmdprefix 0 end]
    }
}

proc twapi::_unregister_script_wm_handler {msg cmdprefix} {
    variable _wm_registrations

    # The incr ensures decimal format
    incr msg 0
    # The lrange ensure proper list format
    if {[info exists _wm_registrations($msg)]} {
        set _wm_registrations($msg) [lsearch -exact -inline -not -all $_wm_registrations($msg) [lrange $cmdprefix 0 end]]
    }                                 
}

# Handles notifications from the common window for script level windows
# messages (see win.c)
proc twapi::_script_wm_handler {msg wparam lparam msgpos ticks} {
    variable _wm_registrations

    set code 0
    if {[info exists _wm_registrations($msg)]} {
        foreach handler $_wm_registrations($msg) {
            set code [catch {uplevel #0 [linsert $handler end $msg $wparam $lparam $msgpos $ticks]} msg]
            switch -exact -- $code {
                1 {
                    # TBD - should remaining handlers be called even on error ?
                    after 0 [list error $msg $::errorInfo $::errorCode]
                    break
                }
                3 {
                    break;      # Ignore remaining handlers
                }
                default {
                    # Keep going
                }
            }
        }
    } else {
        # TBD - debuglog - no handler for $msg
    }

    return
}
