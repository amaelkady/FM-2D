#
# Copyright (c) 2003-2014, Ashok P. Nadkarni
# All rights reserved.
#
# See the file LICENSE for license

namespace eval twapi {
    # Win SDK based structure definitions

    record SHARE_INFO_0 {-name}
    record SHARE_INFO_1 {-name -type -comment}
    record SHARE_INFO_2 {-name -type -comment -permissions -max_conn -current_conn -path -passwd}
    record SHARE_INFO_502 {-name -type -comment -permissions -max_conn -current_conn -path -passwd -reserved -secd}

    record USE_INFO_0 {-localdevice -remoteshare}
    record USE_INFO_1 {-localdevice -remoteshare -password -status -type -opencount -usecount}
    record USE_INFO_2 {-localdevice -remoteshare -password -status -type -opencount -usecount -user -domain}

    record SESSION_INFO_0 {-clientname}
    record SESSION_INFO_1 {-clientname -user -opencount -activeseconds -idleseconds -attrs}
    record SESSION_INFO_2 {-clientname -user -opencount -activeseconds -idleseconds -attrs -clienttype}
    record SESSION_INFO_502 {-clientname -user -opencount -activeseconds -idleseconds -attrs -clienttype -transport}
    record SESSION_INFO_10 {-clientname -user -activeseconds -idleseconds}

    record FILE_INFO_2 {-id}
    record FILE_INFO_3 {-id -permissions -lockcount -path -user}

    record CONNECTION_INFO_0 {-id}
    record CONNECTION_INFO_1 {-id -type -opencount -usercount -activeseconds -user -netname}

    struct NETRESOURCE {
        DWORD  dwScope;
        DWORD  dwType;
        DWORD  dwDisplayType;
        DWORD  dwUsage;
        LPCWSTR lpLocalName;
        LPCWSTR lpRemoteName;
        LPCWSTR lpComment;
        LPCWSTR lpProvider;
    };

    struct NETINFOSTRUCT {
        DWORD     cbStructure;
        DWORD     dwProviderVersion;
        DWORD     dwStatus;
        DWORD     dwCharacteristics;
        HANDLE    dwHandle;
        WORD      wNetType;
        DWORD     dwPrinters;
        DWORD     dwDrives;
    }
}

# TBD - is there a Tcl wrapper around NetShareCheck?

# Create a network share
proc twapi::new_share {sharename path args} {
    array set opts [parseargs args {
        {system.arg ""}
        {type.arg "file"}
        {comment.arg ""}
        {max_conn.int -1}
        secd.arg
    } -maxleftover 0]

    # If no security descriptor specified, default to "Everyone,
    # read permission". Levaing it empty will give everyone all permissions
    # which is probably not a good idea!
    if {![info exists opts(secd)]} {
        set opts(secd) [new_security_descriptor -dacl [new_acl [list [new_ace allow S-1-1-0 1179817]]]]
    }
    
    NetShareAdd $opts(system) \
        $sharename \
        [_share_type_symbols_to_code $opts(type)] \
        $opts(comment) \
        $opts(max_conn) \
        [file nativename $path] \
        $opts(secd)
}

# Delete a network share
proc twapi::delete_share {sharename args} {
    array set opts [parseargs args {system.arg} -nulldefault]
    NetShareDel $opts(system) $sharename 0
}

# Enumerate network shares
proc twapi::get_shares {args} {

    array set opts [parseargs args {
        {system.arg ""}
        {type.arg ""}
        excludespecial
        level.int
    } -maxleftover 0]

    if {$opts(type) != ""} {
        set type_filter [_share_type_symbols_to_code $opts(type) 1]
    }

    if {[info exists opts(level)] && $opts(level) > 0} {
        set level $opts(level)
    } else {
        # Either -level not specified or specified as 0
        # We need at least level 1 to filter on type
        set level 1
    }

    set record_proc SHARE_INFO_$level
    set raw_data [_net_enum_helper NetShareEnum -system $opts(system) -level $level -fields [$record_proc]]
    set recs [list ]
    foreach rec [recordarray getlist $raw_data] {
        # 0xC0000000 -> 0x80000000 (STYPE_SPECIAL), 0x40000000 (STYPE_TEMPORARY)
        set special [expr {[$record_proc -type $rec] & 0xC0000000}]
        if {$special && $opts(excludespecial)} {
            continue
        }
        # We need the special cast to int because else operands get promoted
        # to 64 bits as the hex is treated as an unsigned value
        set share_type [$record_proc -type $rec]
        if {[info exists type_filter] && [expr {int($share_type & ~ $special)}] != $type_filter} {
            continue
        }
        set rec [$record_proc set $rec -type [_share_type_code_to_symbols $share_type]]
        if {[info exists opts(level)]} {
            lappend recs $rec
        } else {
            lappend recs [$record_proc -name $rec]
        }
    }

    if {[info exists opts(level)]} {
        set ra [list [$record_proc] $recs]
        if {$opts(level) == 0} {
            # We actually need only a level 0 subset
            return [recordarray get $ra -slice [SHARE_INFO_0]]
        }
        return $ra
    } else {
        return $recs
    }
}


# Get details about a share
proc twapi::get_share_info {sharename args} {
    array set opts [parseargs args {
        system.arg
        all
        name
        type
        path
        comment
        max_conn
        current_conn
        secd
    } -nulldefault -hyphenated]

    set level 0

    if {$opts(-all) || $opts(-name) || $opts(-type) || $opts(-comment)} {
        set level 1
        set record_proc SHARE_INFO_1
    }

    if {$opts(-all) || $opts(-max_conn) || $opts(-current_conn) || $opts(-path)} {
        set level 2
        set record_proc SHARE_INFO_2
    }

    if {$opts(-all) || $opts(-secd)} {
        set level 502
        set record_proc SHARE_INFO_502
    }

    if {! $level} {
        return
    }

    set rec [NetShareGetInfo $opts(-system) $sharename $level]
    set result [list ]
    foreach opt {-name -comment -max_conn -current_conn -path -secd} {
        if {$opts(-all) || $opts($opt)} {
            lappend result $opt [$record_proc $opt $rec]
        }
    }
    if {$opts(-all) || $opts(-type)} {
        lappend result -type [_share_type_code_to_symbols [$record_proc -type $rec]]
    }

    return $result
}


# Set a share configuration
proc twapi::set_share_info {sharename args} {
    array set opts [parseargs args {
        {system.arg ""}
        comment.arg
        max_conn.int
        secd.arg
    }]

    # First get the current config so we can change specified fields
    # and write back
    array set shareinfo [get_share_info $sharename -system $opts(system) \
                             -comment -max_conn -secd]
    foreach field {comment max_conn secd} {
        if {[info exists opts($field)]} {
            set shareinfo(-$field) $opts($field)
        }
    }

    NetShareSetInfo $opts(system) $sharename $shareinfo(-comment) \
        $shareinfo(-max_conn) $shareinfo(-secd)
}


# Get list of remote shares
proc twapi::get_client_shares {args} {
    array set opts [parseargs args {
        {system.arg ""}
        level.int
    } -maxleftover 0]

    if {[info exists opts(level)]} {
        set rec_proc USE_INFO_$opts(level)
        set ra [_net_enum_helper NetUseEnum -system $opts(system) -level $opts(level) -fields [$rec_proc]]
        set fields [$rec_proc]
        set have_status [expr {"-status" in $fields}]
        set have_type [expr {"-type" in $fields}]
        if {! ($have_status || $have_type)} {
            return $ra
        }
        set recs {}
        foreach rec [recordarray getlist $ra] {
            if {$have_status} {
                set rec [$rec_proc set $rec -status [_map_useinfo_status [$rec_proc -status $rec]]]
            }
            if {$have_type} {
                set rec [$rec_proc set $rec -type [_map_useinfo_type [$rec_proc -type $rec]]]
            }
            lappend recs $rec
        }
        return [list $fields $recs]
    }

    # -level not specified. Just return a list of the remote share names
    return [recordarray column [_net_enum_helper NetUseEnum -system $opts(system) -level 0 -fields [USE_INFO_0]] -remoteshare]
}


# Connect to a share
proc twapi::connect_share {remoteshare args} {
    array set opts [parseargs args {
        {type.arg  "disk"} 
        localdevice.arg
        provider.arg
        password.arg
        nopassword
        defaultpassword
        user.arg
        {window.arg 0}
        {interactive {} 0x8}
        {prompt      {} 0x10}
        {updateprofile {} 0x1}
        {commandline {} 0x800}
    } -nulldefault]

    set flags 0

    switch -exact -- $opts(type) {
        "any"       {set type 0}
        "disk"      -
        "file"      {set type 1}
        "printer"   {set type 2}
        default {
            error "Invalid network share type '$opts(type)'"
        }
    }

    # localdevice - "" means no local device, * means pick any, otherwise
    # it's a local device to be mapped
    if {$opts(localdevice) == "*"} {
        set opts(localdevice) ""
        setbits flags 0x80;             # CONNECT_REDIRECT
    }

    if {$opts(defaultpassword) && $opts(nopassword)} {
        error "Options -defaultpassword and -nopassword may not be used together"
    }
    if {$opts(nopassword)} {
        set opts(password) ""
        set ignore_password 1
    } else {
        set ignore_password 0
        if {$opts(defaultpassword)} {
            set opts(password) ""
        }
    }

    set flags [expr {$flags | $opts(interactive) | $opts(prompt) |
                     $opts(updateprofile) | $opts(commandline)}]

    return [Twapi_WNetUseConnection $opts(window) $type $opts(localdevice) \
                $remoteshare $opts(provider) $opts(user) $ignore_password \
                $opts(password) $flags]
}

# Disconnects an existing share
proc twapi::disconnect_share {sharename args} {
    array set opts [parseargs args {updateprofile force}]

    set flags [expr {$opts(updateprofile) ? 0x1 : 0}]
    WNetCancelConnection2 $sharename $flags $opts(force)
}


# Get information about a connected share
proc twapi::get_client_share_info {sharename args} {
    if {$sharename eq ""} {
        error "A share name cannot be the empty string"
    }

    # We have to use a combination of NetUseGetInfo and 
    # WNetGetResourceInformation as neither gives us the full information
    # THe former takes the local device name if there is one and will
    # only accept a UNC if there is an entry for the UNC with
    # no local device mapped. The latter
    # always wants the UNC. So we need to figure out exactly if there
    # is a local device mapped to the sharename or not
    # TBD _ see if this is really the case. Also, NetUse only works with
    # LANMAN, not WebDAV. So see if there is a way to only use WNet*
    # variants
    
    # There may be multiple entries for the same UNC
    # If there is an entry for the UNC with no device mapped, select
    # that else select any of the local devices mapped to it
    # TBD - any better way of finding out a mapping than calling
    # get_client_shares?
    # TBD - use wnet_connected_resources
    foreach {elem_device elem_unc} [recordarray getlist [get_client_shares -level 0] -format flat] {
        if {[string equal -nocase $sharename $elem_unc]} {
            if {$elem_device eq ""} {
                # Found an entry without a local device. Use it
                set unc $elem_unc
                unset -nocomplain local; # In case we found a match earlier
                break
            } else {
                # Found a matching device
                set local $elem_device
                set unc $elem_unc
                # Keep looping in case we find an entry with no local device
                # (which we will prefer)
            }
        } else {
            # See if the sharename is actually a local device name
            if {[string equal -nocase [string trimright $elem_device :] [string trimright $sharename :]]} {
                # Device name matches. Use it
                set local $elem_device
                set unc $elem_unc
                break
            }
        }
    }

    if {![info exists unc]} {
        win32_error 2250 "Share '$sharename' not found."
    }

    # At this point $unc is the UNC form of the share and
    # $local is either undefined or the local mapped device if there is one

    array set opts [parseargs args {
        user
        localdevice
        remoteshare
        status
        type
        opencount
        usecount
        domain
        provider
        comment
        all
    } -maxleftover 0 -hyphenated]


    # Call Twapi_NetGetInfo always to get status. If we are not connected,
    # we will not call WNetGetResourceInformation as that will time out
    if {[info exists local]} {
        set share [NetUseGetInfo "" $local 2]
    } else {
        set share [NetUseGetInfo "" $unc 2]
    }
    array set shareinfo [USE_INFO_2 $share]
    unset shareinfo(-password)
    if {[info exists shareinfo(-status)]} {
        set shareinfo(-status) [_map_useinfo_status $shareinfo(-status)]
    }
    if {[info exists shareinfo(-type)]} {
        set shareinfo(-type) [_map_useinfo_type $shareinfo(-type)]
    }

    if {$opts(-all) || $opts(-comment) || $opts(-provider)} {
        # Only get this information if we are connected
        if {$shareinfo(-status) eq "connected"} {
            set wnetinfo [lindex [Twapi_WNetGetResourceInformation $unc "" 0] 0]
            set shareinfo(-comment) [lindex $wnetinfo 6]
            set shareinfo(-provider) [lindex $wnetinfo 7]
        } else {
            set shareinfo(-comment) ""
            set shareinfo(-provider) ""
        }
    }

    if {$opts(-all)} {
        return [array get shareinfo]
    }

    # Get rid of unwanted fields
    foreach opt {
        -user
        -localdevice
        -remoteshare
        -status
        -type
        -opencount
        -usecount
        -domain
        -provider
        -comment
    } {
        if {! $opts($opt)} {
            unset -nocomplain shareinfo($opt)
        }
    }

    return [array get shareinfo]
}


# Enumerate sessions
proc twapi::find_lm_sessions args {
    array set opts [parseargs args {
        all
        {matchclient.arg ""}
        {system.arg ""}
        {matchuser.arg ""}
        transport
        clientname
        user
        clienttype
        opencount
        idleseconds
        activeseconds
        attrs
    } -maxleftover 0]

    set level [_calc_minimum_session_info_level opts]
    
    # On all platforms, client must be in UNC format
    set opts(matchclient) [_make_unc_computername $opts(matchclient)]

    trap {
        set sessions [_net_enum_helper NetSessionEnum -system $opts(system) -preargs [list $opts(matchclient) $opts(matchuser)] -level $level -fields [SESSION_INFO_$level]]
    } onerror {TWAPI_WIN32 2312} {
        # No session matching the specified client
        set sessions {}
    } onerror {TWAPI_WIN32 2221} {
        # No session matching the user
        set sessions {}
    }

    return [_format_lm_sessions $sessions opts]
}


# Get information about a session 
proc twapi::get_lm_session_info {client user args} {
    array set opts [parseargs args {
        all
        {system.arg ""}
        transport
        clientname
        user
        clienttype
        opencount
        idleseconds
        activeseconds
        attrs
    } -maxleftover 0]

    set level [_calc_minimum_session_info_level opts]
    if {$level == -1} {
        # No data requested so return empty list
        return [list ]
    }

    if {![min_os_version 5]} {
        # System name is specified. If NT, make sure it is UNC form
        set opts(system) [_make_unc_computername $opts(system)]
    }
    
    # On all platforms, client must be in UNC format
    set client [_make_unc_computername $client]

    # Note an error is generated if no matching session exists
    set sess [NetSessionGetInfo $opts(system) $client $user $level]

    return [recordarray index [_format_lm_sessions [list [SESSION_INFO_$level] [list $sess]] opts] 0 -format dict]
}

# Delete sessions
proc twapi::end_lm_sessions args {
    array set opts [parseargs args {
        {client.arg ""}
        {system.arg ""}
        {user.arg ""}
    } -maxleftover 0]

    if {![min_os_version 5]} {
        # System name is specified. If NT, make sure it is UNC form
        set opts(system) [_make_unc_computername $opts(system)]
    }

    if {$opts(client) eq "" && $opts(user) eq ""} {
        win32_error 87 "At least one of -client and -user must be specified."
    }

    # On all platforms, client must be in UNC format
    set opts(client) [_make_unc_computername $opts(client)]

    trap {
        NetSessionDel $opts(system) $opts(client) $opts(user)
    } onerror {TWAPI_WIN32 2312} {
        # No session matching the specified client - ignore error
    } onerror {TWAPI_WIN32 2221} {
        # No session matching the user - ignore error
    }
    return
}

# Enumerate open files
proc twapi::find_lm_open_files args {
    array set opts [parseargs args {
        {basepath.arg ""}
        {system.arg ""}
        {matchuser.arg ""}
        all
        permissions
        id
        lockcount
        path
        user
    } -maxleftover 0]

    set level 3
    if {! ($opts(all) || $opts(permissions) || $opts(lockcount) ||
           $opts(path) || $opts(user))} {
        # Only id's required
        set level 2
    }

    # TBD - change to use -resume option to _net_enum_helper as there
    # might be a lot of files
    trap {
        set files [_net_enum_helper NetFileEnum -system $opts(system) -preargs [list [file nativename $opts(basepath)] $opts(matchuser)] -level $level -fields [FILE_INFO_$level]]
    } onerror {TWAPI_WIN32 2221} {
        # No files matching the user
        set files [list [FILE_INFO_$level] {}]
    }

    return [_format_lm_open_files $files opts]
}

# Get information about an open LM file
proc twapi::get_lm_open_file_info {fid args} {
    array set opts [parseargs args {
        {system.arg ""}
        all
        permissions
        id
        lockcount
        path
        user
    } -maxleftover 0]

    # System name is specified. If NT, make sure it is UNC form
    if {![min_os_version 5]} {
        set opts(system) [_make_unc_computername $opts(system)]
    }
    
    set level 3
    if {! ($opts(all) || $opts(permissions) || $opts(lockcount) ||
           $opts(path) || $opts(user))} {
        # Only id's required. We actually already have this but don't
        # return it since we want to go ahead and make the call in case
        # the id does not exist
        set level 2
    }

    return [recordarray index [_format_lm_open_files [list [FILE_INFO_$level] [list [NetFileGetInfo $opts(system) $fid $level]]] opts] 0 -format dict]
}

# Close an open LM file
proc twapi::close_lm_open_file {fid args} {
    array set opts [parseargs args {
        {system.arg ""}
    } -maxleftover 0]
    trap {
        NetFileClose $opts(system) $fid
    } onerror {TWAPI_WIN32 2314} {
        # No such fid. Ignore, perhaps it was closed in the meanwhile
    }
}


# Enumerate open connections
proc twapi::find_lm_connections args {
    array set opts [parseargs args {
        client.arg
        {system.arg ""}
        share.arg
        all
        id
        type
        opencount
        usercount
        activeseconds
        user
        clientname
        sharename
    } -maxleftover 0]

    if {! ([info exists opts(client)] || [info exists opts(share)])} {
        win32_error 87 "Must specify either -client or -share option."
    }

    if {[info exists opts(client)] && [info exists opts(share)]} {
        win32_error 87 "Must not specify both -client and -share options."
    }

    if {[info exists opts(client)]} {
        set qualifier [_make_unc_computername $opts(client)]
    } else {
        set qualifier $opts(share)
    }

    set level 0
    if {$opts(all) || $opts(type) || $opts(opencount) ||
        $opts(usercount) || $opts(user) ||
        $opts(activeseconds) || $opts(clientname) || $opts(sharename)} {
        set level 1
    }

    # TBD - change to use -resume option to _net_enum_helper since
    # there might be a log of connections
    set conns [_net_enum_helper NetConnectionEnum -system $opts(system) -preargs [list $qualifier] -level $level -fields [CONNECTION_INFO_$level]]

    # NOTE fields MUST BE IN SAME ORDER AS VALUES BELOW
    if {! $opts(all)} {
        set fields {}
        foreach opt {id opencount usercount activeseconds user type} {
            if {$opts(all) || $opts($opt)} {
                lappend fields -$opt
            }
        }
        if {$opts(all) || $opts(clientname) || $opts(sharename)} {
            lappend fields -netname
        }
        set conns [recordarray get $conns -slice $fields]
    }    
    set fields [recordarray fields $conns]
    if {"-type" in $fields} {
        set type_enum [enum $fields -type]
    }
    if {"-netname" in $fields} {
        set netname_enum [enum $fields -netname]
    }

    if {! ([info exists type_enum] || [info exists netname_enum])} {
        # No need to massage any data
        return $conns
    }

    set recs {}
    foreach rec [recordarray getlist $conns] {
        if {[info exists type_enum]} {
            lset rec $type_enum [_share_type_code_to_symbols [lindex $rec $type_enum]]
        }
        if {[info exists netname_enum]} {
            # What's returned in the netname field depends on what we
            # passed as the qualifier
            if {[info exists opts(client)]} {
                set sharename [lindex $rec $netname_enum]
                set clientname [_make_unc_computername $opts(client)]
            } else {
                set sharename $opts(share)
                set clientname [_make_unc_computername [lindex $rec $netname_enum]]
            }
            if {$opts(all) || $opts(clientname)} {
                lappend rec $clientname
            }
            if {$opts(all) || $opts(sharename)} {
                lappend rec $sharename
            }
        }
        lappend recs $rec
    }
    if {$opts(all) || $opts(clientname)} {
        lappend fields -clientname
    }
    if {$opts(all) || $opts(sharename)} {
        lappend fields -sharename
    }

    return [list $fields $recs]
}

proc twapi::wnet_connected_resources {args} {
    # Accept both file/disk and print/printer for historical reasons
    # file and printer are official to match get_client_share_info
    parseargs args {
        {type.sym any {any 0 file 1 disk 1 print 2 printer 2}}
    } -maxleftover 0 -setvars
    set h [WNetOpenEnum 1 $type 0 ""]
    trap {
        set resources {}
        set structdef [twapi::NETRESOURCE]
        while {[llength [set rs [WNetEnumResource $h 100 $structdef]]]} {
            foreach r $rs {
                lappend resources [lrange $r 4 5]
            }
        }
    } finally {
        WNetCloseEnum $h
    }
    return $resources
}

################################################################
# Utility functions

# Common code to figure out what SESSION_INFO level is required
# for the specified set of requested fields. v_opts is name
# of array indicating which fields are required
proc twapi::_calc_minimum_session_info_level {v_opts} {
    upvar $v_opts opts

    # Set the information level requested based on options specified.
    # We set the level to the one that requires the lowest possible
    # privilege level and still includes the data requested.
    if {$opts(all) || $opts(transport)} {
        return 502
    } elseif {$opts(clienttype)} {
        return 2
    } elseif {$opts(opencount) || $opts(attrs)} {
        return 1
    } elseif {$opts(clientname) || $opts(user) ||
        $opts(idleseconds) || $opts(activeseconds)} {
        return 10
    } else {
        return 0
    }
}

# Common code to format a session record. v_opts is name of array
# that controls which fields are returned
# sessions is a record array
proc twapi::_format_lm_sessions {sessions v_opts} {
    upvar $v_opts opts

    if {! $opts(all)} {
        set fields {}
        foreach opt {
            transport user opencount idleseconds activeseconds
            clienttype clientname attrs
        } {
            if {$opts(all) || $opts($opt)} {
                lappend fields -$opt
            }
        }
        set sessions [recordarray get $sessions -slice $fields]
    }

    set fields [recordarray fields $sessions]
    if {"-clientname" in $fields} {
        set client_enum [enum $fields -clientname]
    }
    if {"-attrs" in $fields} {
        set attrs_enum [enum $fields -attrs]
    }

    if {! ([info exists client_enum] || [info exists attrs_enum])} {
        return $sessions
    }

    # Need to map client name and attrs fields
    set recs {}
    foreach rec [recordarray getlist $sessions] {
        if {[info exists client_enum]} {
            lset rec $client_enum [_make_unc_computername [lindex $rec $client_enum]]
        }
        if {[info exists attrs_enum]} {
            set attrs {}
            set flags [lindex $rec $attrs_enum]
            if {$flags & 1} {
                lappend attrs guest
            }
            if {$flags & 2} {
                lappend attrs noencryption
            }
            lset rec $attrs_enum $attrs
        }
        lappend recs $rec
    }
    return [list $fields $recs]
}

# Common code to format a lm open file record. v_opts is name of array
# that controls which fields are returned
proc twapi::_format_lm_open_files {files v_opts} {
    upvar $v_opts opts

    if {! $opts(all)} {
        set fields {}
        foreach opt {
            id lockcount path user permissions
        } {
            if {$opts(all) || $opts($opt)} {
                lappend fields -$opt
            }
        }
        set files [recordarray get $files -slice $fields]
    }

    set fields [recordarray fields $files]

    if {"-permissions" ni $fields} {
        return $files
    }

    # Need to massage permissions
    set enum [enum $fields -permissions]

    set recs {}
    foreach rec [recordarray getlist $files] {
        set permissions [list ]
        set perms [lindex $rec $enum]
        foreach {flag perm} {1 read 2 write 4 create} {
            if {$perms & $flag} {
                lappend permissions $perm
            }
        }
        lset rec $enum $permissions
        lappend recs $rec
    }

    return [list $fields $recs]
}

# NOTE: THIS ONLY MAPS FOR THE Net* functions, NOT THE WNet*
proc twapi::_share_type_symbols_to_code {typesyms {basetypeonly 0}} {

    # STYPE_DISKTREE          0
    # STYPE_PRINTQ            1
    # STYPE_DEVICE            2
    # STYPE_IPC               3
    switch -exact -- [lindex $typesyms 0] {
        file    { set code 0 }
        printer { set code 1 }
        device  { set code 2 }
        ipc     { set code 3 }
        default {
            error "Unknown type network share type symbol [lindex $typesyms 0]"
        }
    }

    if {$basetypeonly} {
        return $code
    }

    # STYPE_TEMPORARY         0x40000000
    # STYPE_SPECIAL           0x80000000
    set special 0
    foreach sym [lrange $typesyms 1 end] {
        switch -exact -- $sym {
            special   { setbits special 0x80000000 }
            temporary { setbits special 0x40000000 }
            file    -
            printer -
            device  -
            ipc     {
                error "Base share type symbol '$sym' cannot be used as a share attribute type"
            }
            default {
                error "Unknown type network share type symbol '$sym'"
            }
        }
    }

    return [expr {$code | $special}]
}


# First element is always the base type of the share
# NOTE: THIS ONLY MAPS FOR THE Net* functions, NOT THE WNet*
proc twapi::_share_type_code_to_symbols {type} {

    # STYPE_DISKTREE          0
    # STYPE_PRINTQ            1
    # STYPE_DEVICE            2
    # STYPE_IPC               3
    # STYPE_TEMPORARY         0x40000000
    # STYPE_SPECIAL           0x80000000

    set special [expr {$type & 0xC0000000}]

    # We need the special cast to int because else operands get promoted
    # to 64 bits as the hex is treated as an unsigned value
    switch -exact -- [expr {int($type & ~ $special)}] {
        0  {set sym "file"}
        1  {set sym "printer"}
        2  {set sym "device"}
        3  {set sym "ipc"} 
        default {set sym $type}
    }

    set typesyms [list $sym]

    if {$special & 0x80000000} {
        lappend typesyms special
    }

    if {$special & 0x40000000} {
        lappend typesyms temporary
    }
    
    return $typesyms
}

# Make sure a computer name is in unc format unless it is an empty
# string (local computer)
proc twapi::_make_unc_computername {name} {
    if {$name eq ""} {
        return ""
    } else {
        return "\\\\[string trimleft $name \\]"
    }
}

proc twapi::_map_useinfo_status {status} {
    set sym [lindex {connected paused lostsession disconnected networkerror connecting reconnecting} $status]
    if {$sym ne ""} {
        return $sym
    } else {
        return $status
    }
}

proc twapi::_map_useinfo_type {type} {
    # Note share type and use info types are different
    return [_share_type_code_to_symbols [expr {$type & 0x3fffffff}]]
}
