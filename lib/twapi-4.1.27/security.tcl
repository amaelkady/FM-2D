#
# Copyright (c) 2003-2014, Ashok P. Nadkarni
# All rights reserved.
#
# See the file LICENSE for license

# TBD - allow SID and account name to be used interchangeably in various
# functions
# TBD - ditto for LUID v/s privilege names

namespace eval twapi {
    # Map privilege level mnemonics to priv level
    array set priv_level_map {guest 0 user 1 admin 2}

    # TBD - the following are not used, enhancements needed ?
    # OBJECT_INHERIT_ACE                0x1
    # CONTAINER_INHERIT_ACE             0x2
    # NO_PROPAGATE_INHERIT_ACE          0x4
    # INHERIT_ONLY_ACE                  0x8
    # INHERITED_ACE                     0x10
    # VALID_INHERIT_FLAGS               0x1F

    # Cache of privilege names to LUID's
    variable _privilege_to_luid_map
    set _privilege_to_luid_map {}
    variable _luid_to_privilege_map {}

}


# Returns token for a process
proc twapi::open_process_token {args} {
    array set opts [parseargs args {
        pid.int
        hprocess.arg
        {access.arg token_query}
    } -maxleftover 0]

    set access [_access_rights_to_mask $opts(access)]

    # Get a handle for the process
    if {[info exists opts(hprocess)]} {
        if {[info exists opts(pid)]} {
            error "Options -pid and -hprocess cannot be used together."
        }
        set ph $opts(hprocess)
    } elseif {[info exists opts(pid)]} {
        set ph [get_process_handle $opts(pid)]
    } else {
        variable my_process_handle
        set ph $my_process_handle
    }
    trap {
        # Get a token for the process
        set ptok [OpenProcessToken $ph $access]
    } finally {
        # Close handle only if we did an OpenProcess
        if {[info exists opts(pid)]} {
            CloseHandle $ph
        }
    }

    return $ptok
}

# Returns token for a process
proc twapi::open_thread_token {args} {
    array set opts [parseargs args {
        tid.int
        hthread.arg
        {access.arg token_query}
        {self.bool  false}
    } -maxleftover 0]

    set access [_access_rights_to_mask $opts(access)]

    # Get a handle for the thread
    if {[info exists opts(hthread)]} {
        if {[info exists opts(tid)]} {
            error "Options -tid and -hthread cannot be used together."
        }
        set th $opts(hthread)
    } elseif {[info exists opts(tid)]} {
        set th [get_thread_handle $opts(tid)]
    } else {
        set th [GetCurrentThread]
    }

    trap {
        # Get a token for the thread
        set tok [OpenThreadToken $th $access $opts(self)]
    } finally {
        # Close handle only if we did an OpenProcess
        if {[info exists opts(tid)]} {
            CloseHandle $th
        }
    }

    return $tok
}

proc twapi::close_token {tok} {
    CloseHandle $tok
}

# TBD - document and test
proc twapi::duplicate_token {tok args} {
    parseargs args {
        access.arg
        {inherit.bool 0}
        {secd.arg ""}
        {impersonationlevel.sym impersonation {anonymous 0 identification 1 impersonation 2 delegation 3}}
        {type.sym primary {primary 1 impersonation 2}}
    } -maxleftover 0 -setvars

    if {[info exists access]} {
        set access [_access_rights_to_mask $access]
    } else {
        # If no desired access is indicated, we want the same access as
        # the original handle
        set access 0
    }

    return [DuplicateTokenEx $tok $access \
                [_make_secattr $secd $inherit] \
                $impersonationlevel $type]
}

proc twapi::get_token_info {tok args} {
    array set opts [parseargs args {
        defaultdacl
        disabledprivileges
        elevation
        enabledprivileges
        groupattrs
        groups
        integrity
        integritylabel
        linkedtoken
        logonsession
        logonsessionsid
        origin
        primarygroup
        primarygroupsid
        privileges
        restrictedgroupattrs
        restrictedgroups
        tssession
        usersid
        virtualized
    } -maxleftover 0]

    # Do explicit check so we return error if no args specified
    # and $tok is invalid
    if {![pointer? $tok]} {
        error "Invalid token handle '$tok'"
    }

    # TBD - add an -ignorerrors option

    set result [dict create]
    trap {
        if {$opts(privileges) || $opts(disabledprivileges) || $opts(enabledprivileges)} {
            lassign [GetTokenInformation $tok 13] gtigroups gtirestrictedgroups privs gtilogonsession
            set privs [_map_luids_and_attrs_to_privileges $privs]
            if {$opts(privileges)} {
                lappend result -privileges $privs
            }
            if {$opts(enabledprivileges)} {
                lappend result -enabledprivileges [lindex $privs 0]
            }
            if {$opts(disabledprivileges)} {
                lappend result -disabledprivileges [lindex $privs 1]
            }
        }
        if {$opts(defaultdacl)} {
            lappend result -defaultdacl [get_token_default_dacl $tok]
        }
        if {$opts(origin)} {
            lappend result -origin [get_token_origin $tok]
        }
        if {$opts(linkedtoken)} {
            lappend result -linkedtoken [get_token_linked_token $tok]
        }
        if {$opts(elevation)} {
            lappend result -elevation [get_token_elevation $tok]
        }
        if {$opts(integrity)} {
            lappend result -integrity [get_token_integrity $tok]
        }
        if {$opts(integritylabel)} {
            lappend result -integritylabel [get_token_integrity $tok -label]
        }
        if {$opts(virtualized)} {
            lappend result -virtualized [get_token_virtualization $tok]
        }
        if {$opts(tssession)} {
            lappend result -tssession [get_token_tssession $tok]
        }
        if {$opts(usersid)} {
            # First element of groups is user sid
            if {[info exists gtigroups]} {
                lappend result -usersid [lindex $gtigroups 0 0 0]
            } else {
                lappend result -usersid [get_token_user $tok]
            }
        }
        if {$opts(groups)} {
            if {[info exists gtigroups]} {
                set items {}
                # First element of groups is user sid, skip it
                foreach item [lrange $gtigroups 1 end] {
                    lappend items [lookup_account_sid [lindex $item 0]]
                }
                lappend result -groups $items
            } else {
                lappend result -groups [get_token_groups $tok -name]
            }
        }
        if {[min_os_version 6] && $opts(logonsessionsid)} {
            # Only possible on Vista+
	    lappend result -logonsessionsid [lindex [GetTokenInformation $tok 28] 0 0]
            set opts(logonsessionsid) 0; # So we don't try second method below
        }
        if {$opts(groupattrs) || $opts(logonsessionsid)} {
            if {[info exists gtigroups]} {
                set items {}
                # First element of groups is user sid, skip it
                foreach item [lrange $gtigroups 1 end] {
                    set gattrs [map_token_group_attr [lindex $item 1]]
                    if {$opts(groupattrs)} {
                        lappend items [lindex $item 0] $gattrs
                    }
                    if {$opts(logonsessionsid) && "logon_id" in $gattrs} {
                        set logonsessionsid [lindex $item 0]
                    }
                }
                if {$opts(groupattrs)} {
                    lappend result -groupattrs $items
                }
            } else {
                set groupattrs [get_token_groups_and_attrs $tok]
                if {$opts(logonsessionsid)} {
                    foreach {sid gattrs} $groupattrs {
                        if {"logon_id" in $gattrs} {
                            set logonsessionsid $sid
                            break
                        }
                    }
                }
                if {$opts(groupattrs)} {
                    lappend result -groupattrs $groupattrs
                }
            }
            if {$opts(logonsessionsid)} {
                if {[info exists logonsessionsid]} {
                    lappend result -logonsessionsid $logonsessionsid
                } else {
                    error "No logon session id found in token"
                }
            }
        }
        if {$opts(restrictedgroups)} {
            if {![info exists gtirestrictedgroups]} {
                set gtirestrictedgroups [get_token_restricted_groups_and_attrs $tok]
            }
            set items {}
            foreach item $gtirestrictedgroups {
                lappend items [lookup_account_sid [lindex $item 0]]
            }
            lappend result -restrictedgroups $items
        }
        if {$opts(restrictedgroupattrs)} {
            if {[info exists gtirestrictedgroups]} {
                set items {}
                foreach item $gtirestrictedgroups {
                    lappend items [lindex $item 0] [map_token_group_attr [lindex $item 1]]
                }
                lappend result -restrictedgroupattrs $items
            } else {
                lappend result -restrictedgroupattrs [get_token_restricted_groups_and_attrs $tok]
            }
        }
        if {$opts(primarygroupsid)} {
            lappend result -primarygroupsid [get_token_primary_group $tok]
        }
        if {$opts(primarygroup)} {
            lappend result -primarygroup [get_token_primary_group $tok -name]
        }
        if {$opts(logonsession)} {
            if {[info exists gtilogonsession]} {
                lappend result -logonsession $gtilogonsession
            } else {
                array set stats [get_token_statistics $tok]
                lappend result -logonsession $stats(authluid)
            }
        }
    }

    return $result
}

proc twapi::get_token_tssession {tok} {
    return [GetTokenInformation $tok 12]
}

# TBD - document and test
proc twapi::set_token_tssession {tok tssession} {
    Twapi_SetTokenSessionId $tok $tssession
    return
}

# Procs that differ between Vista and prior versions
if {[twapi::min_os_version 6]} {
    proc twapi::get_token_elevation {tok} {
        set elevation [GetTokenInformation $tok 18]; #TokenElevationType
        switch -exact -- $elevation {
            1 { set elevation default }
            2 { set elevation full }
            3 { set elevation limited }
        }
        return $elevation
    }

    proc twapi::get_token_virtualization {tok} {
        return [GetTokenInformation $tok 24]; # TokenVirtualizationEnabled
    }

    proc twapi::set_token_virtualization {tok enabled} {
        # tok must have TOKEN_ADJUST_DEFAULT access
        Twapi_SetTokenVirtualizationEnabled $tok [expr {$enabled ? 1 : 0}]
    }

    # Get the integrity level associated with a token
    proc twapi::get_token_integrity {tok args} {
        # TokenIntegrityLevel -> 25
        lassign [GetTokenInformation $tok 25]  integrity attrs
        if {$attrs != 96} {
            # TBD - is this ok?
        }
        return [_sid_to_integrity $integrity {*}$args]
    }

    # Get the integrity level associated with a token
    proc twapi::set_token_integrity {tok integrity} {
        # SE_GROUP_INTEGRITY attribute - 0x20
        Twapi_SetTokenIntegrityLevel $tok [list [_integrity_to_sid $integrity] 0x20]
    }

    proc twapi::get_token_integrity_policy {tok} {
        set policy [GetTokenInformation $tok 27]; #TokenMandatoryPolicy
        set result {}
        if {$policy & 1} {
            lappend result no_write_up
        }
        if {$policy & 2} {
            lappend result new_process_min
        }
        return $result
    }


    proc twapi::set_token_integrity_policy {tok args} {
        set policy [_parse_symbolic_bitmask $args {
            no_write_up     0x1
            new_process_min 0x2
        }]

        Twapi_SetTokenMandatoryPolicy $tok $policy
    }
} else {
    # Versions for pre-Vista
    proc twapi::get_token_elevation {tok} {
        # Older OS versions have no concept of elevation.
        return "default"
    }

    proc twapi::get_token_virtualization {tok} {
        # Older OS versions have no concept of elevation.
        return 0
    }

    proc twapi::set_token_virtualization {tok enabled} {
        # Older OS versions have no concept of elevation, so only disable
        # allowed
        if {$enabled} {
            error "Virtualization not available on this platform."
        }
        return
    }

    # Get the integrity level associated with a token
    proc twapi::get_token_integrity {tok args} {
        # Older OS versions have no concept of elevation.
        # For future consistency in label mapping, fall through to mapping
        # below instead of directly returning mapped value
        set integrity S-1-16-8192

        return [_sid_to_integrity $integrity {*}$args]
    }

    # Get the integrity level associated with a token
    proc twapi::set_token_integrity {tok integrity} {
        # Old platforms have a "default" of medium that cannot be changed.
        if {[_integrity_to_sid $integrity] ne "S-1-16-8192"} {
            error "Invalid integrity level value '$integrity' for this platform."
        }
        return
    }

    proc twapi::get_token_integrity_policy {tok} {
        # Old platforms - no integrity
        return 0
    }

    proc twapi::set_token_integrity_policy {tok args} {
        # Old platforms - no integrity
        return 0
    }
}

proc twapi::well_known_sid {sidname args} {
    parseargs args {
        {domainsid.arg {}}
    } -maxleftover 0 -setvars

    return [CreateWellKnownSid [_map_well_known_sid_name $sidname] $domainsid]
}

proc twapi::is_well_known_sid {sid sidname} {
    return [IsWellKnownSid $sid [_map_well_known_sid_name $sidname]]
}

# Get the user account associated with a token
proc twapi::get_token_user {tok args} {

    array set opts [parseargs args [list name]]
    # TokenUser -> 1
    set user [lindex [GetTokenInformation $tok 1] 0]
    if {$opts(name)} {
        set user [lookup_account_sid $user]
    }
    return $user
}

# Get the groups associated with a token
proc twapi::get_token_groups {tok args} {
    array set opts [parseargs args [list name] -maxleftover 0]

    set groups [list ]
    # TokenGroups -> 2
    foreach group [GetTokenInformation $tok 2] {
        if {$opts(name)} {
            lappend groups [lookup_account_sid [lindex $group 0]]
        } else {
            lappend groups [lindex $group 0]
        }
    }

    return $groups
}

# Get the groups associated with a token along with their attributes
# These are returned as a flat list of the form "sid attrlist sid attrlist..."
# where the attrlist is a list of attributes
proc twapi::get_token_groups_and_attrs {tok} {

    set sids_and_attrs [list ]
    # TokenGroups -> 2
    foreach {group} [GetTokenInformation $tok 2] {
        lappend sids_and_attrs [lindex $group 0] [map_token_group_attr [lindex $group 1]]
    }

    return $sids_and_attrs
}

# Get the groups associated with a token along with their attributes
# These are returned as a flat list of the form "sid attrlist sid attrlist..."
# where the attrlist is a list of attributes
proc twapi::get_token_restricted_groups_and_attrs {tok} {
    set sids_and_attrs [list ]
    # TokenRestrictedGroups -> 11
    foreach {group} [GetTokenInformation $tok 11] {
        lappend sids_and_attrs [lindex $group 0] [map_token_group_attr [lindex $group 1]]
    }

    return $sids_and_attrs
}


# Get list of privileges that are currently enabled for the token
# If -all is specified, returns a list {enabled_list disabled_list}
proc twapi::get_token_privileges {tok args} {

    set all [expr {[lsearch -exact $args -all] >= 0}]
    # TokenPrivileges -> 3
    set privs [_map_luids_and_attrs_to_privileges [GetTokenInformation $tok 3]]
    if {$all} {
        return $privs
    } else {
        return [lindex $privs 0]
    }
}

# Return true if the token has the given privilege
proc twapi::check_enabled_privileges {tok privlist args} {
    set all_required [expr {[lsearch -exact $args "-any"] < 0}]

    set luid_attr_list [list ]
    foreach priv $privlist {
        lappend luid_attr_list [list [map_privilege_to_luid $priv] 0]
    }
    return [Twapi_PrivilegeCheck $tok $luid_attr_list $all_required]
}


# Enable specified privileges. Returns "" if the given privileges were
# already enabled, else returns the privileges that were modified
proc twapi::enable_privileges {privlist} {
    variable my_process_handle

    # Get our process token
    set tok [OpenProcessToken $my_process_handle 0x28]; # QUERY + ADJUST_PRIVS
    trap {
        return [enable_token_privileges $tok $privlist]
    } finally {
        close_token $tok
    }
}


# Disable specified privileges. Returns "" if the given privileges were
# already enabled, else returns the privileges that were modified
proc twapi::disable_privileges {privlist} {
    variable my_process_handle

    # Get our process token
    set tok [OpenProcessToken $my_process_handle 0x28]; # QUERY + ADJUST_PRIVS
    trap {
        return [disable_token_privileges $tok $privlist]
    } finally {
        close_token $tok
    }
}


# Execute the given script with the specified privileges.
# After the script completes, the original privileges are restored
proc twapi::eval_with_privileges {script privs args} {
    array set opts [parseargs args {besteffort} -maxleftover 0]

    if {[catch {enable_privileges $privs} privs_to_disable]} {
        if {! $opts(besteffort)} {
            return -code error -errorinfo $::errorInfo \
                -errorcode $::errorCode $privs_to_disable
        }
        set privs_to_disable [list ]
    }

    set code [catch {uplevel $script} result]
    switch $code {
        0 {
            disable_privileges $privs_to_disable
            return $result
        }
        1 {
            # Save error info before calling disable_privileges
            set erinfo $::errorInfo
            set ercode $::errorCode
            disable_privileges $privs_to_disable
            return -code error -errorinfo $::errorInfo \
                -errorcode $::errorCode $result
        }
        default {
            disable_privileges $privs_to_disable
            return -code $code $result
        }
    }
}


# Get the privilege associated with a token and their attributes
proc twapi::get_token_privileges_and_attrs {tok} {
    set privs_and_attrs [list ]
    # TokenPrivileges -> 3
    foreach priv [GetTokenInformation $tok 3] {
        lassign $priv luid attr
        lappend privs_and_attrs [map_luid_to_privilege $luid -mapunknown] \
            [map_token_privilege_attr $attr]
    }

    return $privs_and_attrs

}


# Get the sid that will be used as the owner for objects created using this
# token. Returns name instead of sid if -name options specified
proc twapi::get_token_owner {tok args} {
    # TokenOwner -> 4
    return [ _get_token_sid_field $tok 4 $args]
}


# Get the sid that will be used as the primary group for objects created using
# this token. Returns name instead of sid if -name options specified
proc twapi::get_token_primary_group {tok args} {
    # TokenPrimaryGroup -> 5
    return [ _get_token_sid_field $tok 5 $args]
}

proc twapi::get_token_default_dacl {tok} {
    # TokenDefaultDacl -> 6
    return [GetTokenInformation $tok 6]
}

proc twapi::get_token_origin {tok} {
    # TokenOrigin -> 17
    return [GetTokenInformation $tok 17]
}

# Return the source of an access token
proc twapi::get_token_source {tok} {
    return [GetTokenInformation $tok 7]; # TokenSource
}


# Return the token type of an access token
proc twapi::get_token_type {tok} {
    # TokenType -> 8
    set type [GetTokenInformation $tok 8]
    if {$type == 1} {
        return "primary"
    } elseif {$type == 2} {
        return "impersonation"
    } else {
        return $type
    }
}

# Return the token type of an access token
proc twapi::get_token_impersonation_level {tok} {
    # TokenImpersonationLevel -> 9
    return [_map_impersonation_level [GetTokenInformation $tok 9]]
}

# Return the linked token when a token is filtered
proc twapi::get_token_linked_token {tok} {
    # TokenLinkedToken -> 19
    return [GetTokenInformation $tok 19]
}

# Return token statistics
proc twapi::get_token_statistics {tok} {
    array set stats {}
    set labels {luid authluid expiration type impersonationlevel
        dynamiccharged dynamicavailable groupcount
        privilegecount modificationluid}
    # TokenStatistics -> 10
    set statinfo [GetTokenInformation $tok 10]
    foreach label $labels val $statinfo {
        set stats($label) $val
    }
    set stats(type) [expr {$stats(type) == 1 ? "primary" : "impersonation"}]
    set stats(impersonationlevel) [_map_impersonation_level $stats(impersonationlevel)]

    return [array get stats]
}


# Enable the privilege state of a token. Generates an error if
# the specified privileges do not exist in the token (either
# disabled or enabled), or cannot be adjusted
proc twapi::enable_token_privileges {tok privs} {
    set luid_attrs [list]
    foreach priv $privs {
        # SE_PRIVILEGE_ENABLED -> 2
        lappend luid_attrs [list [map_privilege_to_luid $priv] 2]
    }

    set privs [list ]
    foreach {item} [Twapi_AdjustTokenPrivileges $tok 0 $luid_attrs] {
        lappend privs [map_luid_to_privilege [lindex $item 0] -mapunknown]
    }
    return $privs

    

}

# Disable the privilege state of a token. Generates an error if
# the specified privileges do not exist in the token (either
# disabled or enabled), or cannot be adjusted
proc twapi::disable_token_privileges {tok privs} {
    set luid_attrs [list]
    foreach priv $privs {
        lappend luid_attrs [list [map_privilege_to_luid $priv] 0]
    }

    set privs [list ]
    foreach {item} [Twapi_AdjustTokenPrivileges $tok 0 $luid_attrs] {
        lappend privs [map_luid_to_privilege [lindex $item 0] -mapunknown]
    }
    return $privs
}

# Disable all privs in a token
proc twapi::disable_all_token_privileges {tok} {
    set privs [list ]
    foreach {item} [Twapi_AdjustTokenPrivileges $tok 1 [list ]] {
        lappend privs [map_luid_to_privilege [lindex $item 0] -mapunknown]
    }
    return $privs
}


# Map a privilege given as a LUID
proc twapi::map_luid_to_privilege {luid args} {
    variable _luid_to_privilege_map
    
    array set opts [parseargs args [list system.arg mapunknown] -nulldefault]

    if {[dict exists $_luid_to_privilege_map $opts(system) $luid]} {
        return [dict get $_luid_to_privilege_map $opts(system) $luid]
    }

    # luid may in fact be a privilege name. Check for this
    if {[is_valid_luid_syntax $luid]} {
        trap {
            set name [LookupPrivilegeName $opts(system) $luid]
            dict set _luid_to_privilege_map $opts(system) $luid $name
        } onerror {TWAPI_WIN32 1313} {
            if {! $opts(mapunknown)} {
                rethrow
            }
            set name "Privilege-$luid"
            # Do not put in cache as privilege name might change?
        }
    } else {
        # Not a valid LUID syntax. Check if it's a privilege name
        if {[catch {map_privilege_to_luid $luid -system $opts(system)}]} {
            error "Invalid LUID '$luid'"
        }
        return $luid;                   # $luid is itself a priv name
    }

    return $name
}


# Map a privilege to a LUID
proc twapi::map_privilege_to_luid {priv args} {
    variable _privilege_to_luid_map

    array set opts [parseargs args [list system.arg] -nulldefault]

    if {[dict exists $_privilege_to_luid_map $opts(system) $priv]} {
        return [dict get $_privilege_to_luid_map $opts(system) $priv]
    }

    # First check for privilege names we might have generated
    if {[string match "Privilege-*" $priv]} {
        set priv [string range $priv 10 end]
    }

    # If already a LUID format, return as is, else look it up
    if {[is_valid_luid_syntax $priv]} {
        return $priv
    }

    set luid [LookupPrivilegeValue $opts(system) $priv]
    # This is an expensive call so stash it unless cache too big
    if {[dict size $_privilege_to_luid_map] < 100} {
        dict set _privilege_to_luid_map $opts(system) $priv $luid
    }

    return $luid
}


# Return 1/0 if in LUID format
proc twapi::is_valid_luid_syntax {luid} {
    return [regexp {^[[:xdigit:]]{8}-[[:xdigit:]]{8}$} $luid]
}


################################################################
# Functions related to ACE's and ACL's

# Create a new ACE
proc twapi::new_ace {type account rights args} {
    array set opts [parseargs args {
        {self.bool 1}
        {recursecontainers.bool 0 2}
        {recurseobjects.bool 0 1}
        {recurseonelevelonly.bool 0 4}
        {auditsuccess.bool 1 0x40}
        {auditfailure.bool 1 0x80}
    }]

    set sid [map_account_to_sid $account]

    set access_mask [_access_rights_to_mask $rights]

    switch -exact -- $type {
        mandatory_label -
        allow -
        deny  -
        audit {
            set typecode [_ace_type_symbol_to_code $type]
        }
        default {
            error "Invalid or unsupported ACE type '$type'"
        }
    }

    set inherit_flags [expr {$opts(recursecontainers) | $opts(recurseobjects) |
                             $opts(recurseonelevelonly)}]
    if {! $opts(self)} {
        incr inherit_flags 8; #INHERIT_ONLY_ACE
    }

    if {$type eq "audit"} {
        set inherit_flags [expr {$inherit_flags | $opts(auditsuccess) | $opts(auditfailure)}]
    }

    return [list $typecode $inherit_flags $access_mask $sid]
}

# Get the ace type (allow, deny etc.)
proc twapi::get_ace_type {ace} {
    return [_ace_type_code_to_symbol [lindex $ace 0]]
}


# Set the ace type (allow, deny etc.)
proc twapi::set_ace_type {ace type} {
    return [lreplace $ace 0 0 [_ace_type_symbol_to_code $type]]
}

# Get the access rights in an ACE
proc twapi::get_ace_rights {ace args} {
    array set opts [parseargs args {
        {type.arg ""}
        resourcetype.arg
        raw
    } -maxleftover 0]

    if {$opts(raw)} {
        return [format 0x%x [lindex $ace 2]]
    }

    if {[lindex $ace 0] == 0x11} {
        # MANDATORY_LABEL -> 0x11
        # Resource type is immaterial
        return [_access_mask_to_rights [lindex $ace 2] mandatory_label]
    }

    # Backward compatibility - in 2.x -type was documented instead
    # of -resourcetype
    if {[info exists opts(resourcetype)]} {
        return [_access_mask_to_rights [lindex $ace 2] $opts(resourcetype)]
    } else {
        return [_access_mask_to_rights [lindex $ace 2] $opts(type)]
    }
}

# Set the access rights in an ACE
proc twapi::set_ace_rights {ace rights} {
    return [lreplace $ace 2 2 [_access_rights_to_mask $rights]]
}


# Get the ACE sid
proc twapi::get_ace_sid {ace} {
    return [lindex $ace 3]
}

# Set the ACE sid
proc twapi::set_ace_sid {ace account} {
    return [lreplace $ace 3 3 [map_account_to_sid $account]]
}


# Get audit flags - TBD document and test
proc twapi::get_ace_audit {ace} {
    set audit {}
    set mask [lindex $ace 1]
    if {$mask & 0x40} {
        lappend audit "success"
    }
    if {$mask & 0x80} {
        lappend audit "failure"
    }
    return $audit
}

# Get the inheritance options
proc twapi::get_ace_inheritance {ace} {
    
    set inherit_opts [list ]
    set inherit_mask [lindex $ace 1]

    lappend inherit_opts -self \
        [expr {($inherit_mask & 8) == 0}]
    lappend inherit_opts -recursecontainers \
        [expr {($inherit_mask & 2) != 0}]
    lappend inherit_opts -recurseobjects \
        [expr {($inherit_mask & 1) != 0}]
    lappend inherit_opts -recurseonelevelonly \
        [expr {($inherit_mask & 4) != 0}]
    lappend inherit_opts -inherited \
        [expr {($inherit_mask & 16) != 0}]

    return $inherit_opts
}

# Set the inheritance options. Unspecified options are not set
proc twapi::set_ace_inheritance {ace args} {

    array set opts [parseargs args {
        self.bool
        recursecontainers.bool
        recurseobjects.bool
        recurseonelevelonly.bool
    }]
    
    set inherit_flags [lindex $ace 1]
    if {[info exists opts(self)]} {
        if {$opts(self)} {
            resetbits inherit_flags 0x8; #INHERIT_ONLY_ACE -> 0x8
        } else {
            setbits   inherit_flags 0x8; #INHERIT_ONLY_ACE -> 0x8
        }
    }

    foreach {
        opt                 mask
    } {
        recursecontainers   2
        recurseobjects      1
        recurseonelevelonly 4
    } {
        if {[info exists opts($opt)]} {
            if {$opts($opt)} {
                setbits inherit_flags $mask
            } else {
                resetbits inherit_flags $mask
            }
        }
    }

    return [lreplace $ace 1 1 $inherit_flags]
}


# Sort ACE's in the standard recommended Win2K order
proc twapi::sort_aces {aces} {

    _init_ace_type_symbol_to_code_map

    foreach type [array names twapi::_ace_type_symbol_to_code_map] {
        set direct_aces($type) [list ]
        set inherited_aces($type) [list ]
    }
    
    # Sort order is as follows: all direct (non-inherited) ACEs come
    # before all inherited ACEs. Within these groups, the order should be
    # access denied ACEs, access denied ACEs for objects/properties,
    # access allowed ACEs, access allowed ACEs for objects/properties,
    # TBD - check this ordering against http://msdn.microsoft.com/en-us/library/windows/desktop/aa379298%28v=vs.85%29.aspx
    foreach ace $aces {
        set type [get_ace_type $ace]
        # INHERITED_ACE -> 0x10
        if {[lindex $ace 1] & 0x10} {
            lappend inherited_aces($type) $ace
        } else {
            lappend direct_aces($type) $ace
        }
    }

    # TBD - check this order ACE's, especially audit and mandatory label
    return [concat \
                $direct_aces(deny) \
                $direct_aces(deny_object) \
                $direct_aces(deny_callback) \
                $direct_aces(deny_callback_object) \
                $direct_aces(allow) \
                $direct_aces(allow_object) \
                $direct_aces(allow_compound) \
                $direct_aces(allow_callback) \
                $direct_aces(allow_callback_object) \
                $direct_aces(audit) \
                $direct_aces(audit_object) \
                $direct_aces(audit_callback) \
                $direct_aces(audit_callback_object) \
                $direct_aces(mandatory_label) \
                $direct_aces(alarm) \
                $direct_aces(alarm_object) \
                $direct_aces(alarm_callback) \
                $direct_aces(alarm_callback_object) \
                $inherited_aces(deny) \
                $inherited_aces(deny_object) \
                $inherited_aces(deny_callback) \
                $inherited_aces(deny_callback_object) \
                $inherited_aces(allow) \
                $inherited_aces(allow_object) \
                $inherited_aces(allow_compound) \
                $inherited_aces(allow_callback) \
                $inherited_aces(allow_callback_object) \
                $inherited_aces(audit) \
                $inherited_aces(audit_object) \
                $inherited_aces(audit_callback) \
                $inherited_aces(audit_callback_object) \
                $inherited_aces(mandatory_label) \
                $inherited_aces(alarm) \
                $inherited_aces(alarm_object) \
                $inherited_aces(alarm_callback) \
                $inherited_aces(alarm_callback_object)]
}

# Pretty print an ACL
proc twapi::get_acl_text {acl args} {
    array set opts [parseargs args {
        {resourcetype.arg raw}
        {offset.arg ""}
    } -maxleftover 0]

    set count 0
    set result "$opts(offset)Rev: [get_acl_rev $acl]\n"
    foreach ace [get_acl_aces $acl] {
        append result "$opts(offset)ACE #[incr count]\n"
        append result [get_ace_text $ace -offset "$opts(offset)  " -resourcetype $opts(resourcetype)]
    }
    return $result
}

# Pretty print an ACE
proc twapi::get_ace_text {ace args} {
    array set opts [parseargs args {
        {resourcetype.arg raw}
        {offset.arg ""}
    } -maxleftover 0]

    if {$ace eq "null"} {
        return "Null"
    }

    set offset $opts(offset)
    array set bools {0 No 1 Yes}
    array set inherit_flags [get_ace_inheritance $ace]
    append inherit_text "${offset}Inherited: $bools($inherit_flags(-inherited))\n"
    append inherit_text "${offset}Include self: $bools($inherit_flags(-self))\n"
    append inherit_text "${offset}Recurse containers: $bools($inherit_flags(-recursecontainers))\n"
    append inherit_text "${offset}Recurse objects: $bools($inherit_flags(-recurseobjects))\n"
    append inherit_text "${offset}Recurse single level only: $bools($inherit_flags(-recurseonelevelonly))\n"
    
    set rights [get_ace_rights $ace -type $opts(resourcetype)]
    if {[lsearch -glob $rights *_all_access] >= 0} {
        set rights "All"
    } else {
        set rights [join $rights ", "]
    }

    set acetype [get_ace_type $ace]
    append result "${offset}Type: [string totitle $acetype]\n"
    set user [get_ace_sid $ace]
    catch {append user " ([map_account_to_name [get_ace_sid $ace]])"}
    append result "${offset}User: $user\n"
    append result "${offset}Rights: $rights\n"
    if {$acetype eq "audit"} {
        append result "${offset}Audit conditions: [join [get_ace_audit $ace] {, }]\n"
    }
    append result $inherit_text

    return $result
}

# Create a new ACL
proc twapi::new_acl {{aces ""}} {
    # NOTE: we ALWAYS set aclrev to 2. This may not be correct for the
    # supplied ACEs but that's ok. The C level code calculates the correct
    # acl rev level and overwrites anyways.
    return [list 2 $aces]
}

# Creates an ACL that gives the specified rights to specified trustees
proc twapi::new_restricted_dacl {accounts rights args} {
    set access_mask [_access_rights_to_mask $rights]

    set aces {}
    foreach account $accounts {
        lappend aces [new_ace allow $account $access_mask {*}$args]
    }

    return [new_acl $aces]

}

# Return the list of ACE's in an ACL
proc twapi::get_acl_aces {acl} {
    return [lindex $acl 1]
}

# Set the ACE's in an ACL
proc twapi::set_acl_aces {acl aces} {
    # Note, we call new_acl since when ACEs change, the rev may also change
    return [new_acl $aces]
}

# Append to the ACE's in an ACL
proc twapi::append_acl_aces {acl aces} {
    return [set_acl_aces $acl [concat [get_acl_aces $acl] $aces]]
}

# Prepend to the ACE's in an ACL
proc twapi::prepend_acl_aces {acl aces} {
    return [set_acl_aces $acl [concat $aces [get_acl_aces $acl]]]
}

# Arrange the ACE's in an ACL in a standard order
proc twapi::sort_acl_aces {acl} {
    return [set_acl_aces $acl [sort_aces [get_acl_aces $acl]]]
}

# Return the ACL revision of an ACL
proc twapi::get_acl_rev {acl} {
    return [lindex $acl 0]
}


# Create a new security descriptor
proc twapi::new_security_descriptor {args} {
    array set opts [parseargs args {
        owner.arg
        group.arg
        dacl.arg
        sacl.arg
    } -maxleftover 0]

    set secd [Twapi_InitializeSecurityDescriptor]

    foreach field {owner group dacl sacl} {
        if {[info exists opts($field)]} {
            set secd [set_security_descriptor_$field $secd $opts($field)]
        }
    }

    return $secd
}

# Return the control bits in a security descriptor
# TBD - update for new Windows versions
proc twapi::get_security_descriptor_control {secd} {
    if {[_null_secd $secd]} {
        error "Attempt to get control field from NULL security descriptor."
    }

    set control [lindex $secd 0]
    
    set retval [list ]
    if {$control & 0x0001} {
        lappend retval owner_defaulted
    }
    if {$control & 0x0002} {
        lappend retval group_defaulted
    }
    if {$control & 0x0004} {
        lappend retval dacl_present
    }
    if {$control & 0x0008} {
        lappend retval dacl_defaulted
    }
    if {$control & 0x0010} {
        lappend retval sacl_present
    }
    if {$control & 0x0020} {
        lappend retval sacl_defaulted
    }
    if {$control & 0x0100} {
        # Not documented because should not actually appear when reading a secd
        lappend retval dacl_auto_inherit_req
    }
    if {$control & 0x0200} {
        # Not documented because should not actually appear when reading a secd
        lappend retval sacl_auto_inherit_req
    }
    if {$control & 0x0400} {
        lappend retval dacl_auto_inherited
    }
    if {$control & 0x0800} {
        lappend retval sacl_auto_inherited
    }
    if {$control & 0x1000} {
        lappend retval dacl_protected
    }
    if {$control & 0x2000} {
        lappend retval sacl_protected
    }
    if {$control & 0x4000} {
        lappend retval rm_control_valid
    }
    if {$control & 0x8000} {
        lappend retval self_relative
    }
    return $retval
}

# Return the owner in a security descriptor
proc twapi::get_security_descriptor_owner {secd} {
    if {[_null_secd $secd]} {
        win32_error 87 "Attempt to get owner field from NULL security descriptor."
    }
    return [lindex $secd 1]
}

# Set the owner in a security descriptor
proc twapi::set_security_descriptor_owner {secd account} {
    if {[_null_secd $secd]} {
        set secd [new_security_descriptor]
    }
    set sid [map_account_to_sid $account]
    return [lreplace $secd 1 1 $sid]
}

# Return the group in a security descriptor
proc twapi::get_security_descriptor_group {secd} {
    if {[_null_secd $secd]} {
        win32_error 87 "Attempt to get group field from NULL security descriptor."
    }
    return [lindex $secd 2]
}

# Set the group in a security descriptor
proc twapi::set_security_descriptor_group {secd account} {
    if {[_null_secd $secd]} {
        set secd [new_security_descriptor]
    }
    set sid [map_account_to_sid $account]
    return [lreplace $secd 2 2 $sid]
}

# Return the DACL in a security descriptor
proc twapi::get_security_descriptor_dacl {secd} {
    if {[_null_secd $secd]} {
        win32_error 87 "Attempt to get DACL field from NULL security descriptor."
    }
    return [lindex $secd 3]
}

# Set the dacl in a security descriptor
proc twapi::set_security_descriptor_dacl {secd acl} {
    if {[_null_secd $secd]} {
        set secd [new_security_descriptor]
    }
    return [lreplace $secd 3 3 $acl]
}

# Return the SACL in a security descriptor
proc twapi::get_security_descriptor_sacl {secd} {
    if {[_null_secd $secd]} {
        win32_error 87 "Attempt to get SACL field from NULL security descriptor."
    }
    return [lindex $secd 4]
}

# Set the sacl in a security descriptor
proc twapi::set_security_descriptor_sacl {secd acl} {
    if {[_null_secd $secd]} {
        set secd [new_security_descriptor]
    }
    return [lreplace $secd 4 4 $acl]
}

# Get the specified security information for the given object
proc twapi::get_resource_security_descriptor {restype name args} {

    # -mandatory_label field is not documented. Should we ? TBD
    array set opts [parseargs args {
        owner
        group
        dacl
        sacl
        mandatory_label
        all
        handle
    }]

    set wanted 0

    # OWNER_SECURITY_INFORMATION 1
    # GROUP_SECURITY_INFORMATION 2
    # DACL_SECURITY_INFORMATION  4
    # SACL_SECURITY_INFORMATION  8
    foreach {field mask} {owner 1 group 2 dacl 4 sacl 8} {
        if {$opts($field) || $opts(all)} {
            incr wanted $mask;  # Equivalent to OR operation
        }
    }

    # LABEL_SECURITY_INFORMATION 0x10
    if {[min_os_version 6]} {
        if {$opts(mandatory_label) || $opts(all)} {
            incr wanted 16;     # OR with 0x10
        }
    }

    # Note if no options specified, we ask for everything except
    # SACL's which require special privileges
    if {! $wanted} {
        set wanted 0x7
        if {[min_os_version 6]} {
            incr wanted 0x10
        }
    }

    if {$opts(handle)} {
        set restype [_map_resource_symbol_to_type $restype false]
        if {$restype == 5} {
            # GetSecurityInfo crashes if a handles is passed in for
            # SE_LMSHARE (even erroneously). It expects a string name
            # even though the prototype says HANDLE. Protect against this.
            error "Share resource type (share or 5) cannot be used with -handle option"
        }
        set secd [GetSecurityInfo \
                      [CastToHANDLE $name] \
                      $restype \
                      $wanted]
    } else {
        # GetNamedSecurityInfo seems to fail with a overlapped i/o
        # in progress error under some conditions. If this happens
        # try getting with resource-specific API's if possible.
        trap {
            set secd [GetNamedSecurityInfo \
                          $name \
                          [_map_resource_symbol_to_type $restype true] \
                          $wanted]
        } onerror {} {
            # TBD - see what other resource-specific API's there are
            if {$restype eq "share"} {
                set secd [lindex [get_share_info $name -secd] 1]
            } else {
                # Throw the same error
                rethrow
            }
        }
    }

    return $secd
}


# Set the specified security information for the given object
# See http://search.cpan.org/src/TEVERETT/Win32-Security-0.50/README
# for a good discussion even though that applies to Perl
proc twapi::set_resource_security_descriptor {restype name secd args} {

    # PROTECTED_DACL_SECURITY_INFORMATION     0x80000000
    # PROTECTED_SACL_SECURITY_INFORMATION     0x40000000
    # UNPROTECTED_DACL_SECURITY_INFORMATION   0x20000000
    # UNPROTECTED_SACL_SECURITY_INFORMATION   0x10000000
    array set opts [parseargs args {
        all
        handle
        owner
        group
        dacl
        sacl
        mandatory_label
        {protect_dacl   {} 0x80000000}
        {unprotect_dacl {} 0x20000000}
        {protect_sacl   {} 0x40000000}
        {unprotect_sacl {} 0x10000000}
    }]


    if {![min_os_version 6]} {
        if {$opts(mandatory_label)} {
            error "Option -mandatory_label not supported by this version of Windows"
        }
    }

    if {$opts(protect_dacl) && $opts(unprotect_dacl)} {
        error "Cannot specify both -protect_dacl and -unprotect_dacl."
    }

    if {$opts(protect_sacl) && $opts(unprotect_sacl)} {
        error "Cannot specify both -protect_sacl and -unprotect_sacl."
    }

    set mask [expr {$opts(protect_dacl) | $opts(unprotect_dacl) |
                    $opts(protect_sacl) | $opts(unprotect_sacl)}]

    if {$opts(owner) || $opts(all)} {
        set opts(owner) [get_security_descriptor_owner $secd]
        setbits mask 1; # OWNER_SECURITY_INFORMATION
    } else {
        set opts(owner) ""
    }

    if {$opts(group) || $opts(all)} {
        set opts(group) [get_security_descriptor_group $secd]
        setbits mask 2; # GROUP_SECURITY_INFORMATION
    } else {
        set opts(group) ""
    }

    if {$opts(dacl) || $opts(all)} {
        set opts(dacl) [get_security_descriptor_dacl $secd]
        setbits mask 4; # DACL_SECURITY_INFORMATION
    } else {
        set opts(dacl) null
    }

    if {$opts(sacl) || $opts(mandatory_label) || $opts(all)} {
        set sacl [get_security_descriptor_sacl $secd]
        if {$opts(sacl) || $opts(all)} {
            setbits mask 0x8; # SACL_SECURITY_INFORMATION
        }
        if {[min_os_version 6]} {
            if {$opts(mandatory_label) || $opts(all)} {
                setbits mask 0x10; # LABEL_SECURITY_INFORMATION
            }
        }
        set opts(sacl) $sacl
    } else {
        set opts(sacl) null
    }

    if {$mask == 0} {
	error "Must specify at least one of the options -all, -dacl, -sacl, -owner, -group or -mandatory_label"
    }

    if {$opts(handle)} {
        set restype [_map_resource_symbol_to_type $restype false]
        if {$restype == 5} {
            # GetSecurityInfo crashes if a handles is passed in for
            # SE_LMSHARE (even erroneously). It expects a string name
            # even though the prototype says HANDLE. Protect against this.
            error "Share resource type (share or 5) cannot be used with -handle option"
        }

        SetSecurityInfo \
            [CastToHANDLE $name] \
            [_map_resource_symbol_to_type $restype false] \
            $mask \
            $opts(owner) \
            $opts(group) \
            $opts(dacl) \
            $opts(sacl)
    } else {
        SetNamedSecurityInfo \
            $name \
            [_map_resource_symbol_to_type $restype true] \
            $mask \
            $opts(owner) \
            $opts(group) \
            $opts(dacl) \
            $opts(sacl)
    }
}

# Get integrity level from a security descriptor
proc twapi::get_security_descriptor_integrity {secd args} {
    if {[min_os_version 6]} {
        foreach ace [get_acl_aces [get_security_descriptor_sacl $secd]] {
            if {[get_ace_type $ace] eq "mandatory_label"} {
                if {! [dict get [get_ace_inheritance $ace] -self]} continue; # Does not apply to itself
                set integrity [_sid_to_integrity [get_ace_sid $ace] {*}$args]
                set rights [get_ace_rights $ace -resourcetype mandatory_label]
                return [list $integrity $rights]
            }
        }
    }
    return {}
}

# Get integrity level for a resource
proc twapi::get_resource_integrity {restype name args} {
    # Note label and raw options are simply passed on

    if {![min_os_version 6]} {
        return ""
    }
    set saved_args $args
    array set opts [parseargs args {
        label
        raw
        handle
    }]

    if {$opts(handle)} {
        set secd [get_resource_security_descriptor $restype $name -mandatory_label -handle]
    } else {
        set secd [get_resource_security_descriptor $restype $name -mandatory_label]
    }

    return [get_security_descriptor_integrity $secd {*}$saved_args]
}


proc twapi::set_security_descriptor_integrity {secd integrity rights args} {
    # Not clear from docs whether this can
    # be done without interfering with SACL fields. Nevertheless
    # we provide this proc because we might want to set the
    # integrity level on new objects create thru CreateFile etc.
    # TBD - need to test under vista and win 7
    
    array set opts [parseargs args {
        {recursecontainers.bool 0}
        {recurseobjects.bool 0}
    } -maxleftover 0]

    # We preserve any non-integrity aces in the sacl.
    set sacl [get_security_descriptor_sacl $secd]
    set aces {}
    foreach ace [get_acl_aces $sacl] {
        if {[get_ace_type $ace] ne "mandatory_label"} {
            lappend aces $ace
        }
    }

    # Now create and attach an integrity ace. Note placement does not
    # matter
    lappend aces [new_ace mandatory_label \
                      [_integrity_to_sid $integrity] \
                      [_access_rights_to_mask $rights] \
                      -self 1 \
                      -recursecontainers $opts(recursecontainers) \
                      -recurseobjects $opts(recurseobjects)]
                  
    return [set_security_descriptor_sacl $secd [new_acl $aces]]
}

proc twapi::set_resource_integrity {restype name integrity rights args} {
    array set opts [parseargs args {
        {recursecontainers.bool 0}
        {recurseobjects.bool 0}
        handle
    } -maxleftover 0]
    
    set secd [set_security_descriptor_integrity \
                  [new_security_descriptor] \
                  $integrity \
                  $rights \
                  -recurseobjects $opts(recurseobjects) \
                  -recursecontainers $opts(recursecontainers)]

    if {$opts(handle)} {
        set_resource_security_descriptor $restype $name $secd -mandatory_label -handle
    } else {
        set_resource_security_descriptor $restype $name $secd -mandatory_label
    }
}


# Convert a security descriptor to SDDL format
proc twapi::security_descriptor_to_sddl {secd} {
    return [twapi::ConvertSecurityDescriptorToStringSecurityDescriptor $secd 1 0x1f]
}

# Convert SDDL to a security descriptor
proc twapi::sddl_to_security_descriptor {sddl} {
    return [twapi::ConvertStringSecurityDescriptorToSecurityDescriptor $sddl 1]
}

# Return the text for a security descriptor
proc twapi::get_security_descriptor_text {secd args} {
    if {[_null_secd $secd]} {
        return "null"
    }

    array set opts [parseargs args {
        {resourcetype.arg raw}
    } -maxleftover 0]

    append result "Flags:\t[get_security_descriptor_control $secd]\n"
    set name [get_security_descriptor_owner $secd]
    if {$name eq ""} {
        set name Undefined
    } else {
        catch {set name [map_account_to_name $name]}
    }
    append result "Owner:\t$name\n"
    set name [get_security_descriptor_group $secd]
    if {$name eq ""} {
        set name Undefined
    } else {
        catch {set name [map_account_to_name $name]}
    }
    append result "Group:\t$name\n"

    if {0} {
        set acl [get_security_descriptor_dacl $secd]
        append result "DACL Rev: [get_acl_rev $acl]\n"
        set index 0
        foreach ace [get_acl_aces $acl] {
            append result "\tDACL Entry [incr index]\n"
            append result "[get_ace_text $ace -offset "\t    " -resourcetype $opts(resourcetype)]"
        }
        set acl [get_security_descriptor_sacl $secd]
        append result "SACL Rev: [get_acl_rev $acl]\n"
        set index 0
        foreach ace [get_acl_aces $acl] {
            append result "\tSACL Entry $index\n"
            append result [get_ace_text $ace -offset "\t    " -resourcetype $opts(resourcetype)]
        }
    } else {
        append result "DACL:\n"
        append result [get_acl_text [get_security_descriptor_dacl $secd] -offset "  " -resourcetype $opts(resourcetype)]
        append result "SACL:\n"
        append result [get_acl_text [get_security_descriptor_sacl $secd] -offset "  " -resourcetype $opts(resourcetype)]
    }

    return $result
}


# Log off
proc twapi::logoff {args} {
    array set opts [parseargs args {
        {force {} 0x4}
        {forceifhung {} 0x10}
    } -maxleftover 0]
    ExitWindowsEx [expr {$opts(force) | $opts(forceifhung)}]  0
}

# Lock the workstation
proc twapi::lock_workstation {} {
    LockWorkStation
}


# Get a new LUID
proc twapi::new_luid {} {
    return [AllocateLocallyUniqueId]
}


# Get the description of a privilege
proc twapi::get_privilege_description {priv} {
    if {[catch {LookupPrivilegeDisplayName "" $priv} desc]} {
        # The above function will only return descriptions for
        # privileges, not account rights. Hard code descriptions
        # for some account rights
        set desc [dict* {
            SeBatchLogonRight "Log on as a batch job" 
            SeDenyBatchLogonRight "Deny logon as a batch job"
            SeDenyInteractiveLogonRight "Deny interactive logon"
            SeDenyNetworkLogonRight "Deny access to this computer from the network"
            SeRemoteInteractiveLogonRight "Remote interactive logon"
            SeDenyRemoteInteractiveLogonRight "Deny interactive remote logon"
            SeDenyServiceLogonRight "Deny logon as a service"
            SeInteractiveLogonRight "Log on locally"
            SeNetworkLogonRight "Access this computer from the network"
            SeServiceLogonRight "Log on as a service"
        } $priv]
    }
    return $desc
}



# For backward compatibility, emulate GetUserName using GetUserNameEx
proc twapi::GetUserName {} {
    return [file tail [GetUserNameEx 2]]
}


################################################################
# Utility and helper functions



# Returns an sid field from a token
proc twapi::_get_token_sid_field {tok field options} {
    array set opts [parseargs options {name}]
    set owner [GetTokenInformation $tok $field]
    if {$opts(name)} {
        set owner [lookup_account_sid $owner]
    }
    return $owner
}

# Map token group attributes
# TBD - write a test for this
proc twapi::map_token_group_attr {attr} {
    # SE_GROUP_MANDATORY              0x00000001
    # SE_GROUP_ENABLED_BY_DEFAULT     0x00000002
    # SE_GROUP_ENABLED                0x00000004
    # SE_GROUP_OWNER                  0x00000008
    # SE_GROUP_USE_FOR_DENY_ONLY      0x00000010
    # SE_GROUP_LOGON_ID               0xC0000000
    # SE_GROUP_RESOURCE               0x20000000
    # SE_GROUP_INTEGRITY              0x00000020
    # SE_GROUP_INTEGRITY_ENABLED      0x00000040

    return [_make_symbolic_bitmask $attr {
        mandatory              0x00000001
        enabled_by_default     0x00000002
        enabled                0x00000004
        owner                  0x00000008
        use_for_deny_only      0x00000010
        logon_id               0xC0000000
        resource               0x20000000
        integrity              0x00000020
        integrity_enabled      0x00000040
    }]
}

# Map token privilege attributes
# TBD - write a test for this
proc twapi::map_token_privilege_attr {attr} {
    # SE_PRIVILEGE_ENABLED_BY_DEFAULT 0x00000001
    # SE_PRIVILEGE_ENABLED            0x00000002
    # SE_PRIVILEGE_USED_FOR_ACCESS    0x80000000

    return [_make_symbolic_bitmask $attr {
        enabled_by_default 0x00000001
        enabled            0x00000002
        used_for_access    0x80000000
    }]
}



# Map an ace type symbol (eg. allow) to the underlying ACE type code
proc twapi::_ace_type_symbol_to_code {type} {
    _init_ace_type_symbol_to_code_map
    return $::twapi::_ace_type_symbol_to_code_map($type)
}


# Map an ace type code to an ACE type symbol
proc twapi::_ace_type_code_to_symbol {type} {
    _init_ace_type_symbol_to_code_map
    return $::twapi::_ace_type_code_to_symbol_map($type)
}


# Init the arrays used for mapping ACE type symbols to codes and back
proc twapi::_init_ace_type_symbol_to_code_map {} {

    if {[info exists ::twapi::_ace_type_symbol_to_code_map]} {
        return
    }

    # ACCESS_ALLOWED_ACE_TYPE                 0x0
    # ACCESS_DENIED_ACE_TYPE                  0x1
    # SYSTEM_AUDIT_ACE_TYPE                   0x2
    # SYSTEM_ALARM_ACE_TYPE                   0x3
    # ACCESS_ALLOWED_COMPOUND_ACE_TYPE        0x4
    # ACCESS_ALLOWED_OBJECT_ACE_TYPE          0x5
    # ACCESS_DENIED_OBJECT_ACE_TYPE           0x6
    # SYSTEM_AUDIT_OBJECT_ACE_TYPE            0x7
    # SYSTEM_ALARM_OBJECT_ACE_TYPE            0x8
    # ACCESS_ALLOWED_CALLBACK_ACE_TYPE        0x9
    # ACCESS_DENIED_CALLBACK_ACE_TYPE         0xA
    # ACCESS_ALLOWED_CALLBACK_OBJECT_ACE_TYPE 0xB
    # ACCESS_DENIED_CALLBACK_OBJECT_ACE_TYPE  0xC
    # SYSTEM_AUDIT_CALLBACK_ACE_TYPE          0xD
    # SYSTEM_ALARM_CALLBACK_ACE_TYPE          0xE
    # SYSTEM_AUDIT_CALLBACK_OBJECT_ACE_TYPE   0xF
    # SYSTEM_ALARM_CALLBACK_OBJECT_ACE_TYPE   0x10
    # SYSTEM_MANDATORY_LABEL_ACE_TYPE         0x11

    # Define the array.
    array set ::twapi::_ace_type_symbol_to_code_map {
        allow 0    deny 1     audit 2     alarm 3     allow_compound 4
        allow_object 5    deny_object 6    audit_object 7
        alarm_object 8    allow_callback 9    deny_callback 10
        allow_callback_object 11     deny_callback_object 12
        audit_callback 13    alarm_callback 14    audit_callback_object 15
        alarm_callback_object 16    mandatory_label 17
    }

    # Now define the array in the other direction
    foreach {sym code} [array get ::twapi::_ace_type_symbol_to_code_map] {
        set ::twapi::_ace_type_code_to_symbol_map($code) $sym
    }
}

# Map a resource symbol type to value
proc twapi::_map_resource_symbol_to_type {sym {named true}} {
    if {[string is integer $sym]} {
        return $sym
    }

    # Note "window" is not here because window stations and desktops
    # do not have unique names and cannot be used with Get/SetNamedSecurityInfo
    switch -exact -- $sym {
        file      { return 1 }
        service   { return 2 }
        printer   { return 3 }
        registry  { return 4 }
        share     { return 5 }
        kernelobj { return 6 }
    }
    if {$named} {
        error "Resource type '$sym' not valid for named resources."
    }

    switch -exact -- $sym {
        windowstation    { return 7 }
        directoryservice { return 8 }
        directoryserviceall { return 9 }
        providerdefined { return 10 }
        wmiguid { return 11 }
        registrywow6432key { return 12 }
    }

    error "Resource type '$sym' not valid"
}

# Valid LUID syntax
proc twapi::_is_valid_luid_syntax luid {
    return [regexp {^[[:xdigit:]]{8}-[[:xdigit:]]{8}$} $luid]
}


# Delete rights for an account
proc twapi::_delete_rights {account system} {
    # Remove the user from the LSA rights database. Ignore any errors
    catch {
        remove_account_rights $account {} -all -system $system

        # On Win2k SP1 and SP2, we need to delay a bit for notifications
        # to complete before deleting the account.
        # See http://support.microsoft.com/?id=316827
        lassign [get_os_version] major minor sp dontcare
        if {($major == 5) && ($minor == 0) && ($sp < 3)} {
            after 1000
        }
    }
}


# Get a token for a user
proc twapi::open_user_token {username password args} {

    array set opts [parseargs args {
        domain.arg
        {type.arg batch {interactive network batch service unlock network_cleartext new_credentials}}
        {provider.arg default {default winnt35 winnt40 winnt50}}
    } -nulldefault]

    # LOGON32_LOGON_INTERACTIVE       2
    # LOGON32_LOGON_NETWORK           3
    # LOGON32_LOGON_BATCH             4
    # LOGON32_LOGON_SERVICE           5
    # LOGON32_LOGON_UNLOCK            7
    # LOGON32_LOGON_NETWORK_CLEARTEXT 8
    # LOGON32_LOGON_NEW_CREDENTIALS   9
    set type [dict get {interactive 2 network 3 batch 4 service 5
        unlock 7 network_cleartext 8 new_credentials 9} $opts(type)]

    # LOGON32_PROVIDER_DEFAULT    0
    # LOGON32_PROVIDER_WINNT35    1
    # LOGON32_PROVIDER_WINNT40    2
    # LOGON32_PROVIDER_WINNT50    3
    set provider [dict get {default 0 winnt35 1 winnt40 2 winnt50 3} $opts(provider)]

    # If username is of the form user@domain, then domain must not be specified
    # If username is not of the form user@domain, then domain is set to "."
    # if it is empty
    if {[regexp {^([^@]+)@(.+)} $username dummy user domain]} {
        if {[string length $opts(domain)] != 0} {
            error "The -domain option must not be specified when the username is in UPN format (user@domain)"
        }
    } else {
        if {[string length $opts(domain)] == 0} {
            set opts(domain) "."
        }
    }

    return [LogonUser $username $opts(domain) $password $type $provider]
}


# Impersonate a user given a token
proc twapi::impersonate_token {token} {
    ImpersonateLoggedOnUser $token
}


# Impersonate a user
proc twapi::impersonate_user {args} {
    set token [open_user_token {*}$args]
    trap {
        impersonate_token $token
    } finally {
        close_token $token
    }
}

# Impersonate self
proc twapi::impersonate_self {level} {
    switch -exact -- $level {
        anonymous      { set level 0 }
        identification { set level 1 }
        impersonation  { set level 2 }
        delegation     { set level 3 }
        default {
            error "Invalid impersonation level $level"
        }
    }
    ImpersonateSelf $level
}

# Set a thread token - currently only for current thread
proc twapi::set_thread_token {token} {
    SetThreadToken NULL $token
}

# Reset a thread token - currently only for current thread
proc twapi::reset_thread_token {} {
    SetThreadToken NULL NULL
}

proc twapi::credentials {{pattern {}}} {
    trap {
        set raw [CredEnumerate  $pattern 0]
    } onerror {TWAPI_WIN32 1168} {
        # Not found / no entries
        return {}
    }

    set ret {}
    foreach cred $raw {
        set rec [twine {flags type target comment lastwritten credblob persist attributes targetalias username} $cred]
        dict with rec {
            set type [dict* {
                1 generic 2 domain_password 3 domain_certificate 4 domain_visible_password 5 generic_certificate 6 domain_extended} $type]
            set persist [dict* {
                1 session 2 local_machine 3 enterprise
            } $persist]
        }
        lappend ret $rec
    }
    return $ret
}

# TBD - document after implementing AuditQuerySystemPolicy and friends
# for Vista & later
proc twapi::get_audit_policy {lsah} {
    lassign [LsaQueryInformationPolicy $lsah 2] enabled audit_masks
    set settings {}
    foreach name {
        system  logon  object_access  privilege_use  detailed_tracking
        policy_change  account_management  directory_service_access
        account_logon
    } mask $audit_masks {
        # Copied from the Perl Win32 book.
        set setting {}
        if {$mask == 0 || ($mask & 4)} {
            set setting {}
        } elseif {$mask & 3} {
            if {$mask & 1} { lappend setting log_on_success }
            if {$mask & 2} { lappend setting log_on_failure }
        } else {
            error "Unexpected audit mask value $mask"
        }
        lappend settings $name $setting
    }

    return [list $enabled $settings]
}


# TBD - document after implementing AuditQuerySystemPolicy and friends
# for Vista & later
proc twapi::set_audit_policy {lsah enable settings} {
    set audit_masks {}
    # NOTE: the order here MUST match the enum definition for 
    # POLICY_AUDIT_EVENT_TYPE  (see SDK docs)
    foreach name {
        system  logon  object_access  privilege_use  detailed_tracking
        policy_change  account_management  directory_service_access
        account_logon
    } {
        set mask 0; # POLICY_AUDIT_EVENT_UNCHANGED
        if {[dict exists $settings $name]} {
            set setting [dict get $settings $name]
            # 4 -> POLICY_AUDIT_EVENT_NONE resets existing FAILURE|SUCCESS
            set mask 4
            if {"log_on_success" in $setting} {
                set mask [expr {$mask | 1}]; # POLICY_AUDIT_EVENT_SUCCESS
            }
            if {"log_on_failure" in $setting} {
                set mask [expr {$mask | 2}]; # POLICY_AUDIT_EVENT_FAILURE
            }
        }
        lappend audit_masks $mask
    }

    Twapi_LsaSetInformationPolicy_AuditEvents $lsah $enable $audit_masks
}

# Returns true if null security descriptor
proc twapi::_null_secd {secd} {
    if {[llength $secd] == 0} {
        return 1
    } else {
        return 0
    }
}

# Returns true if a valid ACL
proc twapi::_is_valid_acl {acl} {
    if {$acl eq "null"} {
        return 1
    } else {
        return [IsValidAcl $acl]
    }
}

# Returns true if a valid ACL
proc twapi::_is_valid_security_descriptor {secd} {
    if {[_null_secd $secd]} {
        return 1
    } else {
        return [IsValidSecurityDescriptor $secd]
    }
}

# Maps a integrity SID to integer or label
proc twapi::_sid_to_integrity {sid args} {
    # Note - to make it simpler for callers, additional options are ignored
    array set opts [parseargs args {
        label
        raw
    }]

    if {$opts(raw) && $opts(label)} {
        error "Options -raw and -label may not be specified together."
    }

    if {![string equal -length 7 S-1-16-* $sid]} {
        error "Unexpected integrity level value '$sid' returned by GetTokenInformation."
    }

    if {$opts(raw)} {
        return $sid
    }

    set integrity [string range $sid 7 end]

    if {! $opts(label)} {
        # Return integer level
        return $integrity
    }

    # Map to a label
    if {$integrity < 4096} {
        return untrusted
    } elseif {$integrity < 8192} {
        return low
    } elseif {$integrity < 8448} {
        return medium
    } elseif {$integrity < 12288} {
        return mediumplus
    } elseif {$integrity < 16384} {
        return high
    } else {
        return system
    }

}

proc twapi::_integrity_to_sid {integrity} {
    # Integrity level must be either a number < 65536 or a valid string
    # or a SID. Check for the first two and convert to SID. Anything else
    # will be trapped by the actual call as an invalid format.
    if {[string is integer -strict $integrity]} {
        set integrity S-1-16-[format %d $integrity]; # In case in hex
    } else {
        switch -glob -- $integrity {
            untrusted { set integrity S-1-16-0 }
            low { set integrity S-1-16-4096 }
            medium { set integrity S-1-16-8192 }
            mediumplus { set integrity S-1-16-8448 }
            high { set integrity S-1-16-12288 }
            system { set integrity S-1-16-16384 }
            S-1-16-* {
                if {![string is integer -strict [string range $integrity 7 end]]} {
                    error "Invalid integrity level '$integrity'"
                }
                # Format in case level component was in hex/octal
                set integrity S-1-16-[format %d [string range $integrity 7 end]]
            }
            default {
                error "Invalid integrity level '$integrity'"
            }
        }
    }
    return $integrity
}

proc twapi::_map_luids_and_attrs_to_privileges {luids_and_attrs} {
    set enabled_privs [list ]
    set disabled_privs [list ]
    foreach item $luids_and_attrs {
        set priv [map_luid_to_privilege [lindex $item 0] -mapunknown]
        # SE_PRIVILEGE_ENABLED -> 0x2
        if {[lindex $item 1] & 2} {
            lappend enabled_privs $priv
        } else {
            lappend disabled_privs $priv
        }
    }

    return [list $enabled_privs $disabled_privs]
}

# Map impersonation level to symbol
proc twapi::_map_impersonation_level ilevel {
    set map {
        0 anonymous
        1 identification
        2 impersonation
        3 delegation
    }
    if {[dict exists $map [incr ilevel 0]]} {
        return [dict get $map $ilevel]
    } else {
        return $ilevel
    }
}

proc twapi::_map_well_known_sid_name {sidname} {
    if {[string is integer -strict $sidname]} {
        return $sidname
    }

    set sidname [string tolower $sidname]
    set sidname [dict* {
         administrator accountadministrator
         {cert publishers} accountcertadmins
         {domain computers} accountcomputers
         {domain controllers} accountcontrollers
         {domain admins} accountdomainadmins
         {domain guests} accountdomainguests
         {domain users} accountdomainusers
         {enterprise admins} accountenterpriseadmins
         guest accountguest
         krbtgt accountkrbtgt
         {read-only domain controllers} accountreadonlycontrollers
         {schema admins} accountschemaadmins
         {anonymous logon} anonymous
         {authenticated users} authenticateduser
         batch batch
         administrators builtinadministrators
         {all application packages} builtinanypackage
         {backup operators} builtinbackupoperators
         {distributed com users} builtindcomusers
         builtin builtindomain
         {event log readers} builtineventlogreadersgroup
         guests builtinguests
         {performance log users} builtinperfloggingusers
         {performance monitor users} builtinperfmonitoringusers
         {power users} builtinpowerusers
         {remote desktop users} builtinremotedesktopusers
         replicator builtinreplicator
         users builtinusers
         {console logon} consolelogon
         {creator group} creatorgroup
         {creator group server} creatorgroupserver
         {creator owner} creatorowner
         {owner rights} creatorownerrights
         {creator owner server} creatorownerserver
         dialup dialup
         {digest authentication} digestauthentication
         {enterprise domain controllers} enterprisecontrollers
         {enterprise read-only domain controllers beta} enterprisereadonlycontrollers
         {high mandatory level} highlabel
         interactive interactive
         local local
         {local service} localservice
         system localsystem
         {low mandatory level} lowlabel
         {medium mandatory level} mediumlabel
         {medium plus mandatory level} mediumpluslabel
         network network
         {network service} networkservice
         {enterprise read-only domain controllers} newenterprisereadonlycontrollers
         {ntlm authentication} ntlmauthentication
         {null sid} null
         proxy proxy
         {remote interactive logon} remotelogonid
         restricted restrictedcode
         {schannel authentication} schannelauthentication
         self self
         service service
         {system mandatory level} systemlabel
         {terminal server user} terminalserver
         {untrusted mandatory level} untrustedlabel
         everyone world
         {write restricted} writerestrictedcode
    } $sidname]

    return [dict! {
        null 0
        world 1
        local 2
        creatorowner 3
        creatorgroup 4
        creatorownerserver 5
        creatorgroupserver 6
        ntauthority 7
        dialup 8
        network 9
        batch 10
        interactive 11
        service 12
        anonymous 13
        proxy 14
        enterprisecontrollers 15
        self 16
        authenticateduser 17
        restrictedcode 18
        terminalserver 19
        remotelogonid 20
        logonids 21
        localsystem 22
        localservice 23
        networkservice 24
        builtindomain 25
        builtinadministrators 26
        builtinusers 27
        builtinguests 28
        builtinpowerusers 29
        builtinaccountoperators 30
        builtinsystemoperators 31
        builtinprintoperators 32
        builtinbackupoperators 33
        builtinreplicator 34
        builtinprewindows2000compatibleaccess 35
        builtinremotedesktopusers 36
        builtinnetworkconfigurationoperators 37
        accountadministrator 38
        accountguest 39
        accountkrbtgt 40
        accountdomainadmins 41
        accountdomainusers 42
        accountdomainguests 43
        accountcomputers 44
        accountcontrollers 45
        accountcertadmins 46
        accountschemaadmins 47
        accountenterpriseadmins 48
        accountpolicyadmins 49
        accountrasandiasservers 50
        ntlmauthentication 51
        digestauthentication 52
        schannelauthentication 53
        thisorganization 54
        otherorganization 55
        builtinincomingforesttrustbuilders 56
        builtinperfmonitoringusers 57
        builtinperfloggingusers 58
        builtinauthorizationaccess 59
        builtinterminalserverlicenseservers 60
        builtindcomusers 61
        builtiniusers 62
        iuser 63
        builtincryptooperators 64
        untrustedlabel 65
        lowlabel 66
        mediumlabel 67
        highlabel 68
        systemlabel 69
        writerestrictedcode 70
        creatorownerrights 71
        cacheableprincipalsgroup 72
        noncacheableprincipalsgroup 73
        enterprisereadonlycontrollers 74
        accountreadonlycontrollers 75
        builtineventlogreadersgroup 76
        newenterprisereadonlycontrollers 77
        builtincertsvcdcomaccessgroup 78
        mediumpluslabel 79
        locallogon 80
        consolelogon 81
        thisorganizationcertificate 82
        applicationpackageauthority 83
        builtinanypackage 84
        capabilityinternetclient 85
        capabilityinternetclientserver 86
        capabilityprivatenetworkclientserver 87
        capabilitypictureslibrary 88
        capabilityvideoslibrary 89
        capabilitymusiclibrary 90
        capabilitydocumentslibrary 91
        capabilitysharedusercertificates 92
        capabilityenterpriseauthentication 93
        capabilityremovablestorage 94
    } $sidname]
}

