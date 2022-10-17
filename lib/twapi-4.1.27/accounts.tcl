#
# Copyright (c) 2009-2015, Ashok P. Nadkarni
# All rights reserved.
#
# See the file LICENSE for license

package require twapi_security

namespace eval twapi {
    record USER_INFO_0 {-name}
    record USER_INFO_1 [concat [USER_INFO_0] {
        -password -password_age -priv -home_dir -comment -flags -script_path
    }]
    record USER_INFO_2 [concat [USER_INFO_1] {
        -auth_flags -full_name -usr_comment -parms 
        -workstations -last_logon -last_logoff -acct_expires -max_storage
        -units_per_week -logon_hours -bad_pw_count -num_logons
        -logon_server -country_code -code_page
    }]
    record USER_INFO_3 [concat [USER_INFO_2] {
        -user_id -primary_group_id -profile -home_dir_drive -password_expired
    }]
    record USER_INFO_4 [concat [USER_INFO_2] {
        -sid -primary_group_id -profile -home_dir_drive -password_expired
    }]

    record GROUP_INFO_0 {-name}
    record GROUP_INFO_1 {-name -comment}
    record GROUP_INFO_2 {-name -comment -group_id -attributes}
    record GROUP_INFO_3 {-name -comment -sid -attributes}

    record NetEnumResult {moredata hresume totalentries entries}

}

# Add a new user account
proc twapi::new_user {username args} {
    array set opts [parseargs args [list \
                                        system.arg \
                                        password.arg \
                                        comment.arg \
                                        [list priv.arg "user" [array names twapi::priv_level_map]] \
                                        home_dir.arg \
                                        script_path.arg \
                                       ] \
                        -nulldefault]

    if {$opts(priv) ne "user"} {
        error "Option -priv is deprecated and values other than 'user' are not allowed"
    }

    # 1 -> priv level 'user'. NetUserAdd mandates this as only allowed value
    NetUserAdd $opts(system) $username $opts(password) 1 \
        $opts(home_dir) $opts(comment) 0 $opts(script_path)


    # Backward compatibility - add to 'Users' local group
    # but only if -system is local
    if {$opts(system) eq "" ||
        ([info exists ::env(COMPUTERNAME)] &&
         [string equal -nocase $opts(system) $::env(COMPUTERNAME)])} {
        trap {
            _set_user_priv_level $username $opts(priv) -system $opts(system)
        } onerror {} {
            # Remove the previously created user account
            catch {delete_user $username -system $opts(system)}
            rethrow
        }
    }
}


# Delete a user account
proc twapi::delete_user {username args} {
    array set opts [parseargs args {system.arg} -nulldefault]

    # Remove the user from the LSA rights database.
    _delete_rights $username $opts(system)

    NetUserDel $opts(system) $username
}


# Define various functions to set various user account fields
foreach twapi::_field_ {
    {name  0}
    {password  1003}
    {home_dir  1006}
    {comment  1007}
    {script_path  1009}
    {full_name  1011}
    {country_code  1024}
    {profile  1052}
    {home_dir_drive  1053}
} {
    proc twapi::set_user_[lindex $::twapi::_field_ 0] {username fieldval args} "
        array set opts \[parseargs args {
            system.arg
        } -nulldefault \]
        Twapi_NetUserSetInfo [lindex $::twapi::_field_ 1] \$opts(system) \$username \$fieldval"
}
unset twapi::_field_

# Set account expiry time
proc twapi::set_user_expiration {username time args} {
    array set opts [parseargs args {system.arg} -nulldefault]

    if {![string is integer -strict $time]} {
        if {[string equal $time "never"]} {
            set time -1
        } else {
            set time [clock scan $time]
        }
    }
    Twapi_NetUserSetInfo 1017 $opts(system) $username $time
}

# Unlock a user account
proc twapi::unlock_user {username args} {
    # UF_LOCKOUT -> 0x10
    _change_user_info_flags $username 0x10 0 {*}$args
}

# Enable a user account
proc twapi::enable_user {username args} {
    # UF_ACCOUNTDISABLE -> 0x2
    _change_user_info_flags $username 0x2 0 {*}$args
}

# Disable a user account
proc twapi::disable_user {username args} {
    # UF_ACCOUNTDISABLE -> 0x2
    _change_user_info_flags $username 0x2 0x2 {*}$args
}


# Return the specified fields for a user account
proc twapi::get_user_account_info {account args} {
    # Define each option, the corresponding field, and the 
    # information level at which it is returned
    array set fields {
        comment 1
        password_expired 4
        full_name 2
        parms 2
        units_per_week 2
        primary_group_id 4
        flags 1
        logon_server 2
        country_code 2
        home_dir 1
        password_age 1
        home_dir_drive 4
        num_logons 2
        acct_expires 2
        last_logon 2
        usr_comment 2
        bad_pw_count 2
        code_page 2
        logon_hours 2
        workstations 2
        last_logoff 2
        name 0
        script_path 1
        profile 4
        max_storage 2
    }
    # Left out - auth_flags 2
    # Left out (always returned as NULL) - password {usri3_password 1}
    # Note sid is available at level 4 as well but don't want to set
    # level 4 just for that since we can get it by other means. Hence
    # not listed above

    array set opts [parseargs args \
                        [concat [array names fields] sid \
                             internet_identity \
                             status type password_attrs \
                             [list local_groups global_groups system.arg all]] \
                        -nulldefault]

    if {$opts(all)} {
        set level 4
        set opts(local_groups) 1
        set opts(global_groups) 1
    } else {
        # Based on specified fields, figure out what level info to ask for
        set level -1
        foreach {opt optval} [array get opts] {
            if {[info exists fields($opt)] &&
                $optval &&
                $fields($opt) > $level
            } {
                set level $fields($opt)
            }
        }                
        if {$opts(status) || $opts(type) || $opts(password_attrs)} {
            # These fields are based on the flags field
            if {$level < 1} {
                set level 1
            }
        }
    }
    
    array set result [list ]

    if {$level > -1} {
        set rawdata [NetUserGetInfo $opts(system) $account $level]
        array set data [USER_INFO_$level $rawdata]

        # Extract the requested data
        foreach opt [array names fields] {
            if {$opts(all) || $opts($opt)} {
                set result(-$opt) $data(-$opt)
            }
        }
        if {$level == 4 && ($opts(all) || $opts(sid))} {
            set result(-sid) $data(-sid)
        }

        # Map internal values to more friendly formats
        if {$opts(all) || $opts(status) || $opts(type) || $opts(password_attrs)} {
            array set result [_map_userinfo_flags $data(-flags)]
            if {! $opts(all)} {
                if {! $opts(status)} {unset result(-status)}
                if {! $opts(type)} {unset result(-type)}
                if {! $opts(password_attrs)} {unset result(-password_attrs)}
            }
        }

        if {[info exists result(-logon_hours)]} {
            binary scan $result(-logon_hours) b* result(-logon_hours)
        }

        foreach time_field {-acct_expires -last_logon -last_logoff} {
            if {[info exists result($time_field)]} {
                if {$result($time_field) == -1 || $result($time_field) == 4294967295} {
                    set result($time_field) "never"
                } elseif {$result($time_field) == 0} {
                    set result($time_field) "unknown"
                }
            }
        }
    }

    if {$opts(all) || $opts(internet_identity)} {
        set result(-internet_identity) {}
        if {[min_os_version 6 2]} {
            set inet_ident [NetUserGetInfo $opts(system) $account 24]
            if {[llength $inet_ident]} {
                set result(-internet_identity) [twine {
                    internet_provider_name internet_principal_name sid
                } [lrange $inet_ident 1 end]]
            }
        }
    }

    # The Net* calls always return structures as lists even when the struct
    # contains only one field so we need to lpick to extract the field

    if {$opts(local_groups)} {
        set result(-local_groups) [lpick [NetEnumResult entries [NetUserGetLocalGroups $opts(system) $account 0 0]] 0]
    }

    if {$opts(global_groups)} {
        set result(-global_groups) [lpick [NetEnumResult entries [NetUserGetGroups $opts(system) $account 0]] 0]
    }

    if {$opts(sid)  && ! [info exists result(-sid)]} {
        set result(-sid) [lookup_account_name $account -system $opts(system)]
    }

    return [array get result]
}

proc twapi::get_user_global_groups {account args} {
    parseargs args {
        system.arg
        denyonly
        all
    } -nulldefault -maxleftover 0 -setvars

    set groups {}
    foreach elem [NetEnumResult entries [NetUserGetGroups $system [map_account_to_name $account -system $system] 1]] {
        # 0x10 -> SE_GROUP_USE_FOR_DENY_ONLY
        set marked_denyonly [expr {[lindex $elem 1] & 0x10}]
        if {$all || ($denyonly && $marked_denyonly) || !($denyonly || $marked_denyonly)} {
            lappend groups [lindex $elem 0]
        }
    }
    return $groups
}

proc twapi::get_user_local_groups {account args} {
    parseargs args {
        system.arg
        {recurse.bool 0}
    } -nulldefault -maxleftover 0 -setvars

    # The Net* calls always return structures as lists even when the struct
    # contains only one field so we need to lpick to extract the field
    return [lpick [NetEnumResult entries [NetUserGetLocalGroups $system [map_account_to_name $account -system $system] 0 $recurse]] 0]
}

proc twapi::get_user_local_groups_recursive {account args} {
    return [get_user_local_groups $account {*}$args -recurse 1]
}


# Set the specified fields for a user account
proc twapi::set_user_account_info {account args} {

    # Define each option, the corresponding field, and the 
    # information level at which it is returned
    array set opts [parseargs args {
        {system.arg ""}
        comment.arg
        full_name.arg
        country_code.arg
        home_dir.arg
        home_dir.arg
        acct_expires.arg
        name.arg
        script_path.arg
        profile.arg
    }]

    # TBD - rewrite this to be atomic

    if {[info exists opts(comment)]} {
        set_user_comment $account $opts(comment) -system $opts(system)
    }

    if {[info exists opts(full_name)]} {
        set_user_full_name $account $opts(full_name) -system $opts(system)
    }

    if {[info exists opts(country_code)]} {
        set_user_country_code $account $opts(country_code) -system $opts(system)
    }

    if {[info exists opts(home_dir)]} {
        set_user_home_dir $account $opts(home_dir) -system $opts(system)
    }

    if {[info exists opts(home_dir_drive)]} {
        set_user_home_dir_drive $account $opts(home_dir_drive) -system $opts(system)
    }

    if {[info exists opts(acct_expires)]} {
        set_user_expiration $account $opts(acct_expires) -system $opts(system)
    }

    if {[info exists opts(name)]} {
        set_user_name $account $opts(name) -system $opts(system)
    }

    if {[info exists opts(script_path)]} {
        set_user_script_path $account $opts(script_path) -system $opts(system)
    }

    if {[info exists opts(profile)]} {
        set_user_profile $account $opts(profile) -system $opts(system)
    }
}
                    

proc twapi::get_global_group_info {grpname args} {
    array set opts [parseargs args {
        {system.arg ""}
        comment
        name
        members
        sid
        attributes
        all
    } -maxleftover 0]

    set result {}
    if {[expr {$opts(comment) || $opts(name) || $opts(sid) || $opts(attributes) || $opts(all)}]} {
        # 3 -> GROUP_INFO level 3
        lassign [NetGroupGetInfo $opts(system) $grpname 3] name comment sid attributes
        if {$opts(all) || $opts(sid)} {
            lappend result -sid $sid
        }
        if {$opts(all) || $opts(name)} {
            lappend result -name $name
        }
        if {$opts(all) || $opts(comment)} {
            lappend result -comment $comment
        }
        if {$opts(all) || $opts(attributes)} {
            lappend result -attributes [map_token_group_attr $attributes]
        }
    }

    if {$opts(all) || $opts(members)} {
        lappend result -members [get_global_group_members $grpname -system $opts(system)]
    }

    return $result
}

# Get info about a local or global group
proc twapi::get_local_group_info {name args} {
    array set opts [parseargs args {
        {system.arg ""}
        comment
        name
        members
        sid
        all
    } -maxleftover 0]

    set result [list ]
    if {$opts(all) || $opts(sid)} {
        lappend result -sid [lookup_account_name $name -system $opts(system)]
    }
    if {$opts(all) || $opts(comment) || $opts(name)} {
        lassign [NetLocalGroupGetInfo $opts(system) $name 1] name comment
        if {$opts(all) || $opts(name)} {
            lappend result -name $name
        }
        if {$opts(all) || $opts(comment)} {
            lappend result -comment $comment
        }
    }
    if {$opts(all) || $opts(members)} {
        lappend result -members [get_local_group_members $name -system $opts(system)]
    }
    return $result
}

# Get list of users on a system
proc twapi::get_users {args} {
    parseargs args {
        level.int
    } -setvars -ignoreunknown

    # TBD -allow user to specify filter
    lappend args -filter 0
    if {[info exists level]} {
        lappend args -level $level -fields [USER_INFO_$level]
    }
    return [_net_enum_helper NetUserEnum $args]
}

proc twapi::get_global_groups {args} {
    parseargs args {
        level.int
    } -setvars -ignoreunknown

    # TBD - level 3 returns an ERROR_INVALID_LEVEL even though
    # MSDN says its valid for NetGroupEnum

    if {[info exists level]} {
        lappend args -level $level -fields [GROUP_INFO_$level]
    }
    return [_net_enum_helper NetGroupEnum $args]
}

proc twapi::get_local_groups {args} {
    parseargs args {
        level.int
    } -setvars -ignoreunknown

    if {[info exists level]} {
        lappend args -level $level -fields [dict get {0 {-name} 1 {-name -comment}} $level]
    }
    return [_net_enum_helper NetLocalGroupEnum $args]
}

# Create a new global group
proc twapi::new_global_group {grpname args} {
    array set opts [parseargs args {
        system.arg
        comment.arg
    } -nulldefault]

    NetGroupAdd $opts(system) $grpname $opts(comment)
}

# Create a new local group
proc twapi::new_local_group {grpname args} {
    array set opts [parseargs args {
        system.arg
        comment.arg
    } -nulldefault]

    NetLocalGroupAdd $opts(system) $grpname $opts(comment)
}


# Delete a global group
proc twapi::delete_global_group {grpname args} {
    array set opts [parseargs args {system.arg} -nulldefault]

    # Remove the group from the LSA rights database.
    _delete_rights $grpname $opts(system)

    NetGroupDel $opts(system) $grpname
}

# Delete a local group
proc twapi::delete_local_group {grpname args} {
    array set opts [parseargs args {system.arg} -nulldefault]

    # Remove the group from the LSA rights database.
    _delete_rights $grpname $opts(system)

    NetLocalGroupDel $opts(system) $grpname
}


# Enumerate members of a global group
proc twapi::get_global_group_members {grpname args} {
    parseargs args {
        level.int
    } -setvars -ignoreunknown

    if {[info exists level]} {
        lappend args -level $level -fields [dict! {0 {-name} 1 {-name -attributes}} $level]
    }

    lappend args -preargs [list $grpname] -namelevel 1
    return [_net_enum_helper NetGroupGetUsers $args]
}

# Enumerate members of a local group
proc twapi::get_local_group_members {grpname args} {
    parseargs args {
        level.int
    } -setvars -ignoreunknown

    if {[info exists level]} {
        lappend args -level $level -fields [dict! {0 {-sid} 1 {-sid -sidusage -name} 2 {-sid -sidusage -domainandname} 3 {-domainandname}} $level]
    }

    lappend args -preargs [list $grpname] -namelevel 1 -namefield 2
    return [_net_enum_helper NetLocalGroupGetMembers $args]
}

# Add a user to a global group
proc twapi::add_user_to_global_group {grpname username args} {
    array set opts [parseargs args {system.arg} -nulldefault]

    # No error if already member of the group
    trap {
        NetGroupAddUser $opts(system) $grpname $username
    } onerror {TWAPI_WIN32 1320} {
        # Ignore
    }
}


# Remove a user from a global group
proc twapi::remove_user_from_global_group {grpname username args} {
    array set opts [parseargs args {system.arg} -nulldefault]

    trap {
        NetGroupDelUser $opts(system) $grpname $username
    } onerror {TWAPI_WIN32 1321} {
        # Was not in group - ignore
    }
}


# Add a user to a local group
proc twapi::add_member_to_local_group {grpname username args} {
    array set opts [parseargs args {
        system.arg
        {type.arg name}
    } -nulldefault]

    # No error if already member of the group
    trap {
        Twapi_NetLocalGroupMembers 0 $opts(system) $grpname [expr {$opts(type) eq "sid" ? 0 : 3}] [list $username]
    } onerror {TWAPI_WIN32 1378} {
        # Ignore
    }
}

proc twapi::add_members_to_local_group {grpname accts args} {
    array set opts [parseargs args {
        system.arg
        {type.arg name}
    } -nulldefault]

    Twapi_NetLocalGroupMembers 0 $opts(system) $grpname [expr {$opts(type) eq "sid" ? 0 : 3}] $accts
}


# Remove a user from a local group
proc twapi::remove_member_from_local_group {grpname username args} {
    array set opts [parseargs args {
        system.arg
        {type.arg name}
    } -nulldefault]

    trap {
        Twapi_NetLocalGroupMembers 1 $opts(system) $grpname [expr {$opts(type) eq "sid" ? 0 : 3}] [list $username]
    } onerror {TWAPI_WIN32 1377} {
        # Was not in group - ignore
    }
}

proc twapi::remove_members_from_local_group {grpname accts args} {
    array set opts [parseargs args {
        system.arg
        {type.arg name}
    } -nulldefault]

    Twapi_NetLocalGroupMembers 1 $opts(system) $grpname [expr {$opts(type) eq "sid" ? 0 : 3}] $accts
}


# Get rights for an account
proc twapi::get_account_rights {account args} {
    array set opts [parseargs args {
        {system.arg ""}
    } -maxleftover 0]

    set sid [map_account_to_sid $account -system $opts(system)]

    trap {
        set lsah [get_lsa_policy_handle -system $opts(system) -access policy_lookup_names]
        return [Twapi_LsaEnumerateAccountRights $lsah $sid]
    } onerror {TWAPI_WIN32 2} {
        # No specific rights for this account
        return [list ]
    } finally {
        if {[info exists lsah]} {
            close_lsa_policy_handle $lsah
        }
    }
}

# Get accounts having a specific right
proc twapi::find_accounts_with_right {right args} {
    array set opts [parseargs args {
        {system.arg ""}
        name
    } -maxleftover 0]

    trap {
        set lsah [get_lsa_policy_handle \
                      -system $opts(system) \
                      -access {
                          policy_lookup_names
                          policy_view_local_information
                      }]
        set accounts [list ]
        foreach sid [Twapi_LsaEnumerateAccountsWithUserRight $lsah $right] {
            if {$opts(name)} {
                if {[catch {lappend accounts [lookup_account_sid $sid -system $opts(system)]}]} {
                    # No mapping for SID - can happen if account has been
                    # deleted but LSA policy not updated accordingly
                    lappend accounts $sid
                }
            } else {
                lappend accounts $sid
            }
        }
        return $accounts
    } onerror {TWAPI_WIN32 259} {
        # No accounts have this right
        return [list ]
    } finally {
        if {[info exists lsah]} {
            close_lsa_policy_handle $lsah
        }
    }

}

# Add/remove rights to an account
proc twapi::_modify_account_rights {operation account rights args} {
    set switches {
        system.arg
        handle.arg
    }    

    switch -exact -- $operation {
        add {
            # Nothing to do
        }
        remove {
            lappend switches all
        }
        default {
            error "Invalid operation '$operation' specified"
        }
    }

    array set opts [parseargs args $switches -maxleftover 0]

    if {[info exists opts(system)] && [info exists opts(handle)]} {
        error "Options -system and -handle may not be specified together"
    }

    if {[info exists opts(handle)]} {
        set lsah $opts(handle)
        set sid $account
    } else {
        if {![info exists opts(system)]} {
            set opts(system) ""
        }

        set sid [map_account_to_sid $account -system $opts(system)]
        # We need to open a policy handle ourselves. First try to open
        # with max privileges in case the account needs to be created
        # and then retry with lower privileges if that fails
        catch {
            set lsah [get_lsa_policy_handle \
                          -system $opts(system) \
                          -access {
                              policy_lookup_names
                              policy_create_account
                          }]
        }
        if {![info exists lsah]} {
            set lsah [get_lsa_policy_handle \
                          -system $opts(system) \
                          -access policy_lookup_names]
        }
    }

    trap {
        if {$operation == "add"} {
            LsaAddAccountRights $lsah $sid $rights
        } else {
            LsaRemoveAccountRights $lsah $sid $opts(all) $rights
        }
    } finally {
        # Close the handle if we opened it
        if {! [info exists opts(handle)]} {
            close_lsa_policy_handle $lsah
        }
    }
}

interp alias {} twapi::add_account_rights {} twapi::_modify_account_rights add
interp alias {} twapi::remove_account_rights {} twapi::_modify_account_rights remove

# Return list of logon sesionss
proc twapi::find_logon_sessions {args} {
    array set opts [parseargs args {
        user.arg
        type.arg
        tssession.arg
    } -maxleftover 0]

    set luids [LsaEnumerateLogonSessions]
    if {! ([info exists opts(user)] || [info exists opts(type)] ||
           [info exists opts(tssession)])} {
        return $luids
    }


    # Need to get the data for each session to see if it matches
    set result [list ]
    if {[info exists opts(user)]} {
        set sid [map_account_to_sid $opts(user)]
    }
    if {[info exists opts(type)]} {
        set logontypes [list ]
        foreach logontype $opts(type) {
            lappend logontypes [_logon_session_type_code $logontype]
        }
    }

    foreach luid $luids {
        trap {
            unset -nocomplain session
            array set session [LsaGetLogonSessionData $luid]

            # For the local system account, no data is returned on some
            # platforms
            if {[array size session] == 0} {
                set session(Sid) S-1-5-18; # SYSTEM
                set session(Session) 0
                set session(LogonType) 0
            }
            if {[info exists opts(user)] && $session(Sid) ne $sid} {
                continue;               # User id does not match
            }

            if {[info exists opts(type)] && [lsearch -exact $logontypes $session(LogonType)] < 0} {
                continue;               # Type does not match
            }

            if {[info exists opts(tssession)] && $session(Session) != $opts(tssession)} {
                continue;               # Term server session does not match
            }

            lappend result $luid

        } onerror {TWAPI_WIN32 1312} {
            # Session no longer exists. Just skip
            continue
        }
    }

    return $result
}


# Return data for a logon session
proc twapi::get_logon_session_info {luid args} {
    array set opts [parseargs args {
        all
        authpackage
        dnsdomain
        logondomain
        logonid
        logonserver
        logontime
        type
        usersid
        user
        tssession
        userprincipal
    } -maxleftover 0]

    array set session [LsaGetLogonSessionData $luid]

    # Some fields may be missing on Win2K
    foreach fld {LogonServer DnsDomainName Upn} {
        if {![info exists session($fld)]} {
            set session($fld) ""
        }
    }

    array set result [list ]
    foreach {opt index} {
        authpackage AuthenticationPackage
        dnsdomain   DnsDomainName
        logondomain LogonDomain
        logonid     LogonId
        logonserver LogonServer
        logontime   LogonTime
        type        LogonType
        usersid         Sid
        user        UserName
        tssession   Session
        userprincipal Upn
    } {
        if {$opts(all) || $opts($opt)} {
            set result(-$opt) $session($index)
        }
    }

    if {[info exists result(-type)]} {
        set result(-type) [_logon_session_type_symbol $result(-type)]
    }

    return [array get result]
}




# Set/reset the given bits in the usri3_flags field for a user account
# mask indicates the mask of bits to set. values indicates the values
# of those bits
proc twapi::_change_user_info_flags {username mask values args} {
    array set opts [parseargs args {
        system.arg
    } -nulldefault -maxleftover 0]

    # Get current flags
    set flags [USER_INFO_1 -flags [NetUserGetInfo $opts(system) $username 1]]

    # Turn off mask bits and write flags back
    set flags [expr {$flags & (~ $mask)}]
    # Set the specified bits
    set flags [expr {$flags | ($values & $mask)}]

    # Write new flags back
    Twapi_NetUserSetInfo 1008 $opts(system) $username $flags
}

# Returns the logon session type value for a symbol
twapi::proc* twapi::_logon_session_type_code {type} {
    variable _logon_session_type_map
    # Variable that maps logon session type codes to integer values
    # Position of each symbol gives its corresponding type value
    # See ntsecapi.h for definitions
    set _logon_session_type_map {
        0
        1
        interactive
        network
        batch
        service
        proxy
        unlockworkstation
        networkclear
        newcredentials
        remoteinteractive
        cachedinteractive
        cachedremoteinteractive
        cachedunlockworkstation
    }
} {
    variable _logon_session_type_map

    # Type may be an integer or a token
    set code [lsearch -exact $_logon_session_type_map $type]
    if {$code >= 0} {
        return $code
    }

    if {![string is integer -strict $type]} {
        badargs! "Invalid logon session type '$type' specified" 3
    }
    return $type
}

# Returns the logon session type symbol for an integer value
proc twapi::_logon_session_type_symbol {code} {
    variable _logon_session_type_map
    _logon_session_type_code interactive; # Just to init _logon_session_type_map
    set symbol [lindex $_logon_session_type_map $code]
    if {$symbol eq ""} {
        return $code
    } else {
        return $symbol
    }
}

proc twapi::_set_user_priv_level {username priv_level args} {

    array set opts [parseargs args {system.arg} -nulldefault]

    if {0} {
        # FOr some reason NetUserSetInfo cannot change priv level
        # Tried it separately with a simple C program. So this code
        # is commented out and we use group membership to achieve
        # the desired result
        # Note: - latest MSDN confirms above
        if {![info exists twapi::priv_level_map($priv_level)]} {
            error "Invalid privilege level value '$priv_level' specified. Must be one of [join [array names twapi::priv_level_map] ,]"
        }
        set priv $twapi::priv_level_map($priv_level)

        Twapi_NetUserSetInfo_priv $opts(system) $username $priv
    } else {
        # Don't hardcode group names - reverse map SID's instead for 
        # non-English systems. Also note that since
        # we might be lowering privilege level, we have to also
        # remove from higher privileged groups

        switch -exact -- $priv_level {
            guest {
                # administrators users
                set outgroups {S-1-5-32-544 S-1-5-32-545}
                # guests
                set ingroup S-1-5-32-546
            }
            user  {
                # administrators
                set outgroups {S-1-5-32-544}
                # users
                set ingroup S-1-5-32-545
            }
            admin {
                set outgroups {}
                set ingroup S-1-5-32-544
            }
            default {error "Invalid privilege level '$priv_level'. Must be one of 'guest', 'user' or 'admin'"}
        }
        # Remove from higher priv groups
        foreach outgroup $outgroups {
            # Get the potentially localized name of the group
            set group [lookup_account_sid $outgroup -system $opts(system)]
            # Catch since may not be member of that group
            catch {remove_member_from_local_group $group $username -system $opts(system)}
        }

        # Get the potentially localized name of the group to be added
        set group [lookup_account_sid $ingroup -system $opts(system)]
        add_member_to_local_group $group $username -system $opts(system)
    }
}

proc twapi::_map_userinfo_flags {flags} {
    # UF_LOCKOUT -> 0x10, UF_ACCOUNTDISABLE -> 0x2
    if {$flags & 0x2} {
        set status disabled
    } elseif {$flags & 0x10} {
        set status locked
    } else {
        set status enabled
    }

    #define UF_TEMP_DUPLICATE_ACCOUNT       0x0100
    #define UF_NORMAL_ACCOUNT               0x0200
    #define UF_INTERDOMAIN_TRUST_ACCOUNT    0x0800
    #define UF_WORKSTATION_TRUST_ACCOUNT    0x1000
    #define UF_SERVER_TRUST_ACCOUNT         0x2000
    if {$flags & 0x0200} {
        set type normal
    } elseif {$flags & 0x0100} {
        set type duplicate
    } elseif {$flags & 0x0800} {
        set type interdomain_trust
    } elseif {$flags & 0x1000} {
        set type workstation_trust
    } elseif {$flags & 0x2000} {
        set type server_trust
    } else {
        set type unknown
    }

    set pw {}
    #define UF_PASSWD_NOTREQD                  0x0020
    if {$flags & 0x0020} {
        lappend pw not_required
    }
    #define UF_PASSWD_CANT_CHANGE              0x0040
    if {$flags & 0x0040} {
        lappend pw cannot_change
    }
    #define UF_ENCRYPTED_TEXT_PASSWORD_ALLOWED 0x0080
    if {$flags & 0x0080} {
        lappend pw encrypted_text_allowed
    }
    #define UF_DONT_EXPIRE_PASSWD                         0x10000
    if {$flags & 0x10000} {
        lappend pw no_expiry
    }
    #define UF_SMARTCARD_REQUIRED                         0x40000
    if {$flags & 0x40000} {
        lappend pw smartcard_required
    }
    #define UF_PASSWORD_EXPIRED                          0x800000
    if {$flags & 0x800000} {
        lappend pw expired
    }

    return [list -status $status -type $type -password_attrs $pw]
}

twapi::proc* twapi::_define_user_modals {} {
    struct _USER_MODALS_INFO_0 {
        DWORD min_passwd_len;
        DWORD max_passwd_age;
        DWORD min_passwd_age;
        DWORD force_logoff;
        DWORD password_hist_len;
    }
    struct _USER_MODALS_INFO_1 {
        DWORD  role;
        LPWSTR primary;
    }
    struct _USER_MODALS_INFO_2 {
        LPWSTR domain_name;
        PSID   domain_id;
    }
    struct _USER_MODALS_INFO_3 {
        DWORD lockout_duration;
        DWORD lockout_observation_window;
        DWORD lockout_threshold;
    }
    struct _USER_MODALS_INFO_1001 {
        DWORD min_passwd_len;
    }
    struct _USER_MODALS_INFO_1002 {
        DWORD max_passwd_age;
    }
    struct _USER_MODALS_INFO_1003 {
        DWORD min_passwd_age;
    }
    struct _USER_MODALS_INFO_1004 {
        DWORD force_logoff;
    }
    struct _USER_MODALS_INFO_1005 {
        DWORD password_hist_len;
    }
    struct _USER_MODALS_INFO_1006 {
        DWORD role;
    }
    struct _USER_MODALS_INFO_1007 {
        LPWSTR primary;
    }
} {
}

twapi::proc* twapi::get_password_policy {{server_name ""}} {
    _define_user_modals
} {
    set result [NetUserModalsGet $server_name 0 [_USER_MODALS_INFO_0]]
    dict with result {
        if {$force_logoff == 4294967295 || $force_logoff == -1} {
            set force_logoff never
        }
        if {$max_passwd_age == 4294967295 || $max_passwd_age == -1} {
            set max_passwd_age none
        }
    }
    return $result
}

# TBD - doc & test
twapi::proc* twapi::get_system_role {{server_name ""}} {
    _define_user_modals
} {
    set result [NetUserModalsGet $server_name 1 [_USER_MODALS_INFO_1]]
    dict set result role [dict* {
        0 standalone 1 member 2 backup 3 primary
    } [dict get $result role]]
    return $result
}

# TBD - doc & test
twapi::proc* twapi::get_system_domain {{server_name ""}} {
    _define_user_modals
} {
    return [NetUserModalsGet $server_name 2 [_USER_MODALS_INFO_2]]
}

twapi::proc* twapi::get_lockout_policy {{server_name ""}} {
    _define_user_modals
} {
    return [NetUserModalsGet $server_name 3 [_USER_MODALS_INFO_3]]
}

# TBD - doc & test
twapi::proc* twapi::set_password_policy {name val {server_name ""}} {
    _define_user_modals
} {
    switch -exact $name {
        min_passwd_len {
            NetUserModalsSet $server_name 1001 [_USER_MODALS_INFO_1001 $val]
        }
        max_passwd_age {
            if {$val eq "none"} {
                set val 4294967295
            }
            NetUserModalsSet $server_name 1002 [_USER_MODALS_INFO_1002 $val]
        }
        min_passwd_age {
            NetUserModalsSet $server_name 1003 [_USER_MODALS_INFO_1003 $val]
        }
        force_logoff {
            if {$val eq "never"} {
                set val 4294967295
            }
            NetUserModalsSet $server_name 1004 [_USER_MODALS_INFO_1004 $val]
        }
        password_hist_len {
            NetUserModalsSet $server_name 1005 [_USER_MODALS_INFO_1005 $val]
        }
    }
}

# TBD - doc & test
twapi::proc* twapi::set_lockout_policy {duration observe_window threshold {server_name ""}} {
    _define_user_modals
} {
    NetUserModalsSet $server_name 3 [_USER_MODALS_INFO_3 $duration $observe_window $threshold]
}
