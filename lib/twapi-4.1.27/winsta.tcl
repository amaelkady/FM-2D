#
# Copyright (c) 2004-2012, Ashok P. Nadkarni
# All rights reserved.
#
# See the file LICENSE for license


# TBD - document and test
proc twapi::get_active_console_tssession {} {
    return [WTSGetActiveConsoleSessionId]
}

proc twapi::get_current_window_station_handle {} {
    return [GetProcessWindowStation]
}

# Get the handle to a window station
proc twapi::get_window_station_handle {winsta args} {
    array set opts [parseargs args {
        inherit.bool
        {access.arg  generic_read}
    } -nulldefault]

    set access_rights [_access_rights_to_mask $opts(access)]
    
    return [OpenWindowStation $winsta $opts(inherit) $access_rights]
}


# Close a window station handle
proc twapi::close_window_station_handle {hwinsta} {
    # Trying to close our window station handle will generate an error
    if {$hwinsta != [get_current_window_station_handle]} {
        CloseWindowStation $hwinsta
    }
    return
}

# List all window stations
proc twapi::find_window_stations {} {
    return [EnumWindowStations]
}


# Enumerate desktops in a window station
proc twapi::find_desktops {args} {
    array set opts [parseargs args {winsta.arg}]

    if {[info exists opts(winsta)]} {
        set hwinsta [get_window_station_handle $opts(winsta)]
    } else {
        set hwinsta [get_current_window_station_handle]
    }

    trap {
        return [EnumDesktops $hwinsta]
    } finally {
        # Note close_window_station_handle protects against
        # hwinsta being the current window station handle so 
        # we do not need to do that check here
        close_window_station_handle $hwinsta
    }
}


# Get the handle to a desktop
proc twapi::get_desktop_handle {desk args} {
    array set opts [parseargs args {
        inherit.bool
        allowhooks.bool
        {access.arg  generic_read}
    } -nulldefault]

    set access_mask [_access_rights_to_mask $opts(access)]
    
    # If certain access rights are specified, we must add certain other
    # access rights. See OpenDesktop SDK docs
    set access_rights [_access_mask_to_rights $access_mask]
    if {"read_control" in $access_rights ||
        "write_dacl" in $access_rights ||
        "write_owner" in  $access_rights} {
        lappend access_rights desktop_readobject desktop_writeobjects
        set access_mask [_access_rights_to_mask $opts(access)]
    }

    return [OpenDesktop $desk $opts(allowhooks) $opts(inherit) $access_mask]
}

# Close the desktop handle
proc twapi::close_desktop_handle {hdesk} {
    CloseDesktop $hdesk
}

# Set the process window station
proc twapi::set_process_window_station {hwinsta} {
    SetProcessWindowStation $hwinsta
}

# TBD - document and test
proc twapi::get_desktop_user {hdesk} {
    return [GetUserObjectInformation $hdesk 4]
}

# TBD - document and test
proc twapi::get_window_station_user {hwinsta} {
    return [GetUserObjectInformation $hwinsta 4]
}
