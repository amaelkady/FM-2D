#
# Copyright (c) 2012-2014, Ashok P. Nadkarni
# All rights reserved.
#
# See the file LICENSE for license

# Commands in twapi_base module

namespace eval twapi {
    # Map of Sid integer type to Sid type name
    array set sid_type_names {
        1 user 
        2 group
        3 domain 
        4 alias 
        5 wellknowngroup
        6 deletedaccount
        7 invalid
        8 unknown
        9 computer
        10 label
    }

    # Cache mapping account names to SIDs. Dict keyed by system and name
    variable _name_to_sid_cache {}

    # Cache mapping SIDs to account names. Dict keyed by system and SID
    variable _sid_to_name_cache {}

}



# Return major minor servicepack as a quad list
proc twapi::get_os_version {} {
    array set verinfo [GetVersionEx]
    return [list $verinfo(dwMajorVersion) $verinfo(dwMinorVersion) \
                $verinfo(wServicePackMajor) $verinfo(wServicePackMinor)]
}

# Returns true if the OS version is at least $major.$minor.$sp
proc twapi::min_os_version {major {minor 0} {spmajor 0} {spminor 0}} {
    lassign  [twapi::get_os_version]  osmajor osminor osspmajor osspminor

    if {$osmajor > $major} {return 1}
    if {$osmajor < $major} {return 0}
    if {$osminor > $minor} {return 1}
    if {$osminor < $minor} {return 0}
    if {$osspmajor > $spmajor} {return 1}
    if {$osspmajor < $spmajor} {return 0}
    if {$osspminor > $spminor} {return 1}
    if {$osspminor < $spminor} {return 0}

    # Same version, ok
    return 1
}

# Convert a LARGE_INTEGER time value (100ns since 1601) to a formatted date
# time
interp alias {} twapi::large_system_time_to_secs {} twapi::large_system_time_to_secs_since_1970
proc twapi::large_system_time_to_secs_since_1970 {ns100 {fraction false}} {
    # No. 100ns units between 1601 to 1970 = 116444736000000000
    set ns100_since_1970 [expr {$ns100-116444736000000000}]

    set secs_since_1970 [expr {$ns100_since_1970/10000000}]
    if {$fraction} {
        append secs_since_1970 .[string range $ns100 end-6 end]
    }
    return $secs_since_1970
}

proc twapi::secs_since_1970_to_large_system_time {secs} {
    # No. 100ns units between 1601 to 1970 = 116444736000000000
    return [expr {($secs * 10000000) + 116444736000000000}]
}

# Map a Windows error code to a string
proc twapi::map_windows_error {code} {
    # Trim trailing CR/LF
    return [string trimright [twapi::Twapi_MapWindowsErrorToString $code] "\r\n"]
}

# Load given library
proc twapi::load_library {path args} {
    array set opts [parseargs args {
        dontresolverefs
        datafile
        alteredpath
    }]

    set flags 0
    if {$opts(dontresolverefs)} {
        setbits flags 1;                # DONT_RESOLVE_DLL_REFERENCES
    }
    if {$opts(datafile)} {
        setbits flags 2;                # LOAD_LIBRARY_AS_DATAFILE
    }
    if {$opts(alteredpath)} {
        setbits flags 8;                # LOAD_WITH_ALTERED_SEARCH_PATH
    }

    # LoadLibrary always wants backslashes
    set path [file nativename $path]
    return [LoadLibraryEx $path $flags]
}

# Free library opened with load_library
proc twapi::free_library {libh} {
    FreeLibrary $libh
}

# Format message string - will raise exception if insufficient number
# of arguments
proc twapi::_unsafe_format_message {args} {
    array set opts [parseargs args {
        module.arg
        fmtstring.arg
        messageid.arg
        langid.arg
        params.arg
        includesystem
        ignoreinserts
        width.int
    } -nulldefault -maxleftover 0]

    set flags 0

    if {$opts(module) == ""} {
        if {$opts(fmtstring) == ""} {
            # If neither -module nor -fmtstring specified, message is formatted
            # from the system
            set opts(module) NULL
            setbits flags 0x1000;       # FORMAT_MESSAGE_FROM_SYSTEM
        } else {
            setbits flags 0x400;        # FORMAT_MESSAGE_FROM_STRING
            if {$opts(includesystem) || $opts(messageid) != "" || $opts(langid) != ""} {
                error "Options -includesystem, -messageid and -langid cannot be used with -fmtstring"
            }
        }
    } else {
        if {$opts(fmtstring) != ""} {
            error "Options -fmtstring and -module cannot be used together"
        }
        setbits flags 0x800;        # FORMAT_MESSAGE_FROM_HMODULE
        if {$opts(includesystem)} {
            # Also include system in search
            setbits flags 0x1000;       # FORMAT_MESSAGE_FROM_SYSTEM
        }
    }

    if {$opts(ignoreinserts)} {
        setbits flags 0x200;            # FORMAT_MESSAGE_IGNORE_INSERTS
    }

    if {$opts(width) > 254} {
        error "Invalid value for option -width. Must be -1, 0, or a positive integer less than 255"
    }
    if {$opts(width) < 0} {
        # Negative width means no width restrictions
        set opts(width) 255;                  # 255 -> no restrictions
    }
    incr flags $opts(width);                  # Width goes in low byte of flags

    if {$opts(fmtstring) != ""} {
        return [FormatMessageFromString $flags $opts(fmtstring) $opts(params)]
    } else {
        if {![string is integer -strict $opts(messageid)]} {
            error "Unspecified or invalid value for -messageid option. Must be an integer value"
        }
        if {$opts(langid) == ""} { set opts(langid) 0 }
        if {![string is integer -strict $opts(langid)]} {
            error "Unspecfied or invalid value for -langid option. Must be an integer value"
        }

        # Check if $opts(module) is a file or module handle (pointer)
        if {[pointer? $opts(module)]} {
            return  [FormatMessageFromModule $flags $opts(module) \
                         $opts(messageid) $opts(langid) $opts(params)]
        } else {
            set hmod [load_library $opts(module) -datafile]
            trap {
                set message  [FormatMessageFromModule $flags $hmod \
                                  $opts(messageid) $opts(langid) $opts(params)]
            } finally {
                free_library $hmod
            }
            return $message
        }
    }
}

# Format message string
proc twapi::format_message {args} {
    array set opts [parseargs args {
        params.arg
        fmtstring.arg
        width.int
        ignoreinserts
    } -ignoreunknown]

    # TBD - document - if no params specified, different from params = {}

    # If a format string is specified, other options do not matter
    # except for -width. In that case, we do not call FormatMessage
    # at all
    if {[info exists opts(fmtstring)]} {
        # If -width specifed, call FormatMessage
        if {[info exists opts(width)] && $opts(width)} {
            set msg [_unsafe_format_message -ignoreinserts -fmtstring $opts(fmtstring) -width $opts(width) {*}$args]
        } else {
            set msg $opts(fmtstring)
        }
    } else {
        # Not -fmtstring, retrieve from message file
        if {[info exists opts(width)]} {
            set msg [_unsafe_format_message -ignoreinserts -width $opts(width) {*}$args]
        } else {
            set msg [_unsafe_format_message -ignoreinserts {*}$args]
        }
    }

    # If we are told to ignore inserts, all done. Else replace them except
    # that if no param list, do not replace placeholder. This is NOT
    # the same as empty param list
    if {$opts(ignoreinserts) || ![info exists opts(params)]} {
        return $msg
    }

    # TBD - cache fmtstring -> indices for performance
    set placeholder_indices [regexp -indices -all -inline {%(?:.|(?:[1-9][0-9]?(?:![^!]+!)?))} $msg]

    if {[llength $placeholder_indices] == 0} {
        # No placeholders.
        return $msg
    }

    # Use of * in format specifiers will change where the actual parameters
    # are positioned
    set num_asterisks 0
    set msg2 ""
    set prev_end 0
    foreach placeholder $placeholder_indices {
        lassign $placeholder start end
        # Append the stuff between previous placeholder and this one
        append msg2 [string range $msg $prev_end [expr {$start-1}]]
        set spec [string range $msg $start+1 $end]
        switch -exact -- [string index $spec 0] {
            % { append msg2 % }
            r { append msg2 \r }
            n { append msg2 \n }
            t { append msg2 \t }
            0 { 
                # No-op - %0 means to not add trailing newline
            }
            default {
                if {! [string is integer -strict [string index $spec 0]]} {
                    # Not a insert parameter. Just append the character
                    append msg2 $spec
                } else {
                    # Insert parameter
                    set fmt ""
                    scan $spec %d%s param_index fmt
                    # Note params are numbered starting with 1
                    incr param_index -1
                    # Format spec, if present, is enclosed in !. Get rid of them
                    set fmt [string trim $fmt "!"]
                    if {$fmt eq ""} {
                        # No fmt spec
                    } else {
                        # Since everything is a string in Tcl, we happily
                        # do not have to worry about type. However, the
                        # format spec could have * specifiers which will
                        # change the parameter indexing for subsequent
                        # arguments
                        incr num_asterisks [expr {[llength [split $fmt *]]-1}]
                        incr param_index $num_asterisks
                    }
                    # TBD - we ignore the actual format type
                    append msg2 [lindex $opts(params) $param_index]
                }                        
            }
        }                    
        set prev_end [incr end]
    }
    append msg2 [string range $msg $prev_end end]
    return $msg2
}

# Revert to process token. In base package because used across many modules
proc twapi::revert_to_self {{opt ""}} {
    RevertToSelf
}

# For backward compatibility
interp alias {} twapi::expand_environment_strings {} twapi::expand_environment_vars

proc twapi::_init_security_defs {} {
    variable security_defs

    # NOTE : the access definitions for those types that are included here
    # have been updated as of Windows 8.
    array set security_defs {

        TOKEN_ASSIGN_PRIMARY           0x00000001
        TOKEN_DUPLICATE                0x00000002
        TOKEN_IMPERSONATE              0x00000004
        TOKEN_QUERY                    0x00000008
        TOKEN_QUERY_SOURCE             0x00000010
        TOKEN_ADJUST_PRIVILEGES        0x00000020
        TOKEN_ADJUST_GROUPS            0x00000040
        TOKEN_ADJUST_DEFAULT           0x00000080
        TOKEN_ADJUST_SESSIONID         0x00000100

        TOKEN_ALL_ACCESS_WINNT         0x000F00FF
        TOKEN_ALL_ACCESS_WIN2K         0x000F01FF
        TOKEN_ALL_ACCESS               0x000F01FF
        TOKEN_READ                     0x00020008
        TOKEN_WRITE                    0x000200E0
        TOKEN_EXECUTE                  0x00020000

        SYSTEM_MANDATORY_LABEL_NO_WRITE_UP         0x1
        SYSTEM_MANDATORY_LABEL_NO_READ_UP          0x2
        SYSTEM_MANDATORY_LABEL_NO_EXECUTE_UP       0x4

        ACL_REVISION     2
        ACL_REVISION_DS  4

        ACCESS_MAX_MS_V2_ACE_TYPE               0x3
        ACCESS_MAX_MS_V3_ACE_TYPE               0x4
        ACCESS_MAX_MS_V4_ACE_TYPE               0x8
        ACCESS_MAX_MS_V5_ACE_TYPE               0x11

        STANDARD_RIGHTS_REQUIRED       0x000F0000
        STANDARD_RIGHTS_READ           0x00020000
        STANDARD_RIGHTS_WRITE          0x00020000
        STANDARD_RIGHTS_EXECUTE        0x00020000
        STANDARD_RIGHTS_ALL            0x001F0000
        SPECIFIC_RIGHTS_ALL            0x0000FFFF

        GENERIC_READ                   0x80000000
        GENERIC_WRITE                  0x40000000
        GENERIC_EXECUTE                0x20000000
        GENERIC_ALL                    0x10000000

        SERVICE_QUERY_CONFIG           0x00000001
        SERVICE_CHANGE_CONFIG          0x00000002
        SERVICE_QUERY_STATUS           0x00000004
        SERVICE_ENUMERATE_DEPENDENTS   0x00000008
        SERVICE_START                  0x00000010
        SERVICE_STOP                   0x00000020
        SERVICE_PAUSE_CONTINUE         0x00000040
        SERVICE_INTERROGATE            0x00000080
        SERVICE_USER_DEFINED_CONTROL   0x00000100
        SERVICE_ALL_ACCESS             0x000F01FF

        SC_MANAGER_CONNECT             0x00000001
        SC_MANAGER_CREATE_SERVICE      0x00000002
        SC_MANAGER_ENUMERATE_SERVICE   0x00000004
        SC_MANAGER_LOCK                0x00000008
        SC_MANAGER_QUERY_LOCK_STATUS   0x00000010
        SC_MANAGER_MODIFY_BOOT_CONFIG  0x00000020
        SC_MANAGER_ALL_ACCESS          0x000F003F

        KEY_QUERY_VALUE                0x00000001
        KEY_SET_VALUE                  0x00000002
        KEY_CREATE_SUB_KEY             0x00000004
        KEY_ENUMERATE_SUB_KEYS         0x00000008
        KEY_NOTIFY                     0x00000010
        KEY_CREATE_LINK                0x00000020
        KEY_WOW64_32KEY                0x00000200
        KEY_WOW64_64KEY                0x00000100
        KEY_WOW64_RES                  0x00000300
        KEY_READ                       0x00020019
        KEY_WRITE                      0x00020006
        KEY_EXECUTE                    0x00020019
        KEY_ALL_ACCESS                 0x000F003F

        POLICY_VIEW_LOCAL_INFORMATION   0x00000001
        POLICY_VIEW_AUDIT_INFORMATION   0x00000002
        POLICY_GET_PRIVATE_INFORMATION  0x00000004
        POLICY_TRUST_ADMIN              0x00000008
        POLICY_CREATE_ACCOUNT           0x00000010
        POLICY_CREATE_SECRET            0x00000020
        POLICY_CREATE_PRIVILEGE         0x00000040
        POLICY_SET_DEFAULT_QUOTA_LIMITS 0x00000080
        POLICY_SET_AUDIT_REQUIREMENTS   0x00000100
        POLICY_AUDIT_LOG_ADMIN          0x00000200
        POLICY_SERVER_ADMIN             0x00000400
        POLICY_LOOKUP_NAMES             0x00000800
        POLICY_NOTIFICATION             0x00001000
        POLICY_READ                     0X00020006
        POLICY_WRITE                    0X000207F8
        POLICY_EXECUTE                  0X00020801
        POLICY_ALL_ACCESS               0X000F0FFF

        DESKTOP_READOBJECTS         0x0001
        DESKTOP_CREATEWINDOW        0x0002
        DESKTOP_CREATEMENU          0x0004
        DESKTOP_HOOKCONTROL         0x0008
        DESKTOP_JOURNALRECORD       0x0010
        DESKTOP_JOURNALPLAYBACK     0x0020
        DESKTOP_ENUMERATE           0x0040
        DESKTOP_WRITEOBJECTS        0x0080
        DESKTOP_SWITCHDESKTOP       0x0100

        WINSTA_ENUMDESKTOPS         0x0001
        WINSTA_READATTRIBUTES       0x0002
        WINSTA_ACCESSCLIPBOARD      0x0004
        WINSTA_CREATEDESKTOP        0x0008
        WINSTA_WRITEATTRIBUTES      0x0010
        WINSTA_ACCESSGLOBALATOMS    0x0020
        WINSTA_EXITWINDOWS          0x0040
        WINSTA_ENUMERATE            0x0100
        WINSTA_READSCREEN           0x0200
        WINSTA_ALL_ACCESS           0x37f

        PROCESS_TERMINATE              0x0001
        PROCESS_CREATE_THREAD          0x0002
        PROCESS_SET_SESSIONID          0x0004
        PROCESS_VM_OPERATION           0x0008
        PROCESS_VM_READ                0x0010
        PROCESS_VM_WRITE               0x0020
        PROCESS_DUP_HANDLE             0x0040
        PROCESS_CREATE_PROCESS         0x0080
        PROCESS_SET_QUOTA              0x0100
        PROCESS_SET_INFORMATION        0x0200
        PROCESS_QUERY_INFORMATION      0x0400
        PROCESS_SUSPEND_RESUME         0x0800

        THREAD_TERMINATE               0x00000001
        THREAD_SUSPEND_RESUME          0x00000002
        THREAD_GET_CONTEXT             0x00000008
        THREAD_SET_CONTEXT             0x00000010
        THREAD_SET_INFORMATION         0x00000020
        THREAD_QUERY_INFORMATION       0x00000040
        THREAD_SET_THREAD_TOKEN        0x00000080
        THREAD_IMPERSONATE             0x00000100
        THREAD_DIRECT_IMPERSONATION    0x00000200
        THREAD_SET_LIMITED_INFORMATION   0x00000400
        THREAD_QUERY_LIMITED_INFORMATION 0x00000800

        EVENT_MODIFY_STATE             0x00000002
        EVENT_ALL_ACCESS               0x001F0003

        SEMAPHORE_MODIFY_STATE         0x00000002
        SEMAPHORE_ALL_ACCESS           0x001F0003

        MUTANT_QUERY_STATE             0x00000001
        MUTANT_ALL_ACCESS              0x001F0001

        MUTEX_MODIFY_STATE             0x00000001
        MUTEX_ALL_ACCESS               0x001F0001

        TIMER_QUERY_STATE              0x00000001
        TIMER_MODIFY_STATE             0x00000002
        TIMER_ALL_ACCESS               0x001F0003

        FILE_READ_DATA                 0x00000001
        FILE_LIST_DIRECTORY            0x00000001
        FILE_WRITE_DATA                0x00000002
        FILE_ADD_FILE                  0x00000002
        FILE_APPEND_DATA               0x00000004
        FILE_ADD_SUBDIRECTORY          0x00000004
        FILE_CREATE_PIPE_INSTANCE      0x00000004
        FILE_READ_EA                   0x00000008
        FILE_WRITE_EA                  0x00000010
        FILE_EXECUTE                   0x00000020
        FILE_TRAVERSE                  0x00000020
        FILE_DELETE_CHILD              0x00000040
        FILE_READ_ATTRIBUTES           0x00000080
        FILE_WRITE_ATTRIBUTES          0x00000100

        FILE_ALL_ACCESS                0x001F01FF
        FILE_GENERIC_READ              0x00120089
        FILE_GENERIC_WRITE             0x00120116
        FILE_GENERIC_EXECUTE           0x001200A0

        DELETE                         0x00010000
        READ_CONTROL                   0x00020000
        WRITE_DAC                      0x00040000
        WRITE_OWNER                    0x00080000
        SYNCHRONIZE                    0x00100000

        COM_RIGHTS_EXECUTE 1
        COM_RIGHTS_EXECUTE_LOCAL 2
        COM_RIGHTS_EXECUTE_REMOTE 4
        COM_RIGHTS_ACTIVATE_LOCAL 8
        COM_RIGHTS_ACTIVATE_REMOTE 16
    }

    if {[min_os_version 6]} {
        array set security_defs {
            PROCESS_QUERY_LIMITED_INFORMATION      0x00001000
            PROCESS_ALL_ACCESS             0x001fffff
            THREAD_ALL_ACCESS              0x001fffff
        }
    } else {
        array set security_defs {
            PROCESS_ALL_ACCESS             0x001f0fff
            THREAD_ALL_ACCESS              0x001f03ff
        }
    }

    # Make next call a no-op
    proc _init_security_defs {} {}
}

# Map a set of access right symbols to a flag. Concatenates
# all the arguments, and then OR's the individual elements. Each
# element may either be a integer or one of the access rights
proc twapi::_access_rights_to_mask {args} {
    _init_security_defs

    proc _access_rights_to_mask args {
        variable security_defs
        set rights 0
        foreach right [concat {*}$args] {
            # The mandatory label access rights are not in security_defs
            # because we do not want them to mess up the int->name mapping
            # for DACL's
            set right [dict* {
                no_write_up 1
                system_mandatory_label_no_write_up 1
                no_read_up 2
                system_mandatory_label_no_read_up  2
                no_execute_up 4
                system_mandatory_label_no_execute_up 4
            } $right]
            if {![string is integer $right]} {
                if {[catch {set right $security_defs([string toupper $right])}]} {
                    error "Invalid access right symbol '$right'"
                }
            }
            set rights [expr {$rights | $right}]
        }
        return $rights
    }
    return [_access_rights_to_mask {*}$args]
}


# Map an access mask to a set of rights
proc twapi::_access_mask_to_rights {access_mask {type ""}} {
    _init_security_defs

    proc _access_mask_to_rights {access_mask {type ""}} {
        variable security_defs

        set rights [list ]

        if {$type eq "mandatory_label"} {
            if {$access_mask & 1} {
                lappend rights system_mandatory_label_no_write_up
            }
            if {$access_mask & 2} {
                lappend rights system_mandatory_label_no_read_up
            }
            if {$access_mask & 4} {
                lappend rights system_mandatory_label_no_execute_up
            }
            return $rights
        }

        # The returned list will include rights that map to multiple bits
        # as well as the individual bits. We first add the multiple bits
        # and then the individual bits (since we clear individual bits
        # after adding)

        #
        # Check standard multiple bit masks
        #
        foreach x {STANDARD_RIGHTS_REQUIRED STANDARD_RIGHTS_READ STANDARD_RIGHTS_WRITE STANDARD_RIGHTS_EXECUTE STANDARD_RIGHTS_ALL SPECIFIC_RIGHTS_ALL} {
            if {($security_defs($x) & $access_mask) == $security_defs($x)} {
                lappend rights [string tolower $x]
            }
        }

        #
        # Check type specific multiple bit masks.
        #
        
        set type_mask_map {
            file {FILE_ALL_ACCESS FILE_GENERIC_READ FILE_GENERIC_WRITE FILE_GENERIC_EXECUTE}
            process {PROCESS_ALL_ACCESS}
            pipe {FILE_ALL_ACCESS}
            policy {POLICY_READ POLICY_WRITE POLICY_EXECUTE POLICY_ALL_ACCESS}
            registry {KEY_READ KEY_WRITE KEY_EXECUTE KEY_ALL_ACCESS}
            service {SERVICE_ALL_ACCESS}
            thread {THREAD_ALL_ACCESS}
            token {TOKEN_READ TOKEN_WRITE TOKEN_EXECUTE TOKEN_ALL_ACCESS}
            desktop {}
            winsta {WINSTA_ALL_ACCESS}
        }
        if {[dict exists $type_mask_map $type]} {
            foreach x [dict get $type_mask_map $type] {
                if {($security_defs($x) & $access_mask) == $security_defs($x)} {
                    lappend rights [string tolower $x]
                }
            }
        }

        #
        # OK, now map individual bits

        # First map the common bits
        foreach x {DELETE READ_CONTROL WRITE_DAC WRITE_OWNER SYNCHRONIZE} {
            if {$security_defs($x) & $access_mask} {
                lappend rights [string tolower $x]
                resetbits access_mask $security_defs($x)
            }
        }

        # Then the generic bits
        foreach x {GENERIC_READ GENERIC_WRITE GENERIC_EXECUTE GENERIC_ALL} {
            if {$security_defs($x) & $access_mask} {
                lappend rights [string tolower $x]
                resetbits access_mask $security_defs($x)
            }
        }

        # Then the type specific
        set type_mask_map {
            file { FILE_READ_DATA FILE_WRITE_DATA FILE_APPEND_DATA
                FILE_READ_EA FILE_WRITE_EA FILE_EXECUTE
                FILE_DELETE_CHILD FILE_READ_ATTRIBUTES
                FILE_WRITE_ATTRIBUTES }
            pipe { FILE_READ_DATA FILE_WRITE_DATA FILE_CREATE_PIPE_INSTANCE
                FILE_READ_ATTRIBUTES FILE_WRITE_ATTRIBUTES }
            service { SERVICE_QUERY_CONFIG SERVICE_CHANGE_CONFIG
                SERVICE_QUERY_STATUS SERVICE_ENUMERATE_DEPENDENTS
                SERVICE_START SERVICE_STOP SERVICE_PAUSE_CONTINUE
                SERVICE_INTERROGATE SERVICE_USER_DEFINED_CONTROL }
            registry { KEY_QUERY_VALUE KEY_SET_VALUE KEY_CREATE_SUB_KEY
                KEY_ENUMERATE_SUB_KEYS KEY_NOTIFY KEY_CREATE_LINK
                KEY_WOW64_32KEY KEY_WOW64_64KEY KEY_WOW64_RES }
            policy { POLICY_VIEW_LOCAL_INFORMATION POLICY_VIEW_AUDIT_INFORMATION
                POLICY_GET_PRIVATE_INFORMATION POLICY_TRUST_ADMIN
                POLICY_CREATE_ACCOUNT POLICY_CREATE_SECRET
                POLICY_CREATE_PRIVILEGE POLICY_SET_DEFAULT_QUOTA_LIMITS
                POLICY_SET_AUDIT_REQUIREMENTS POLICY_AUDIT_LOG_ADMIN
                POLICY_SERVER_ADMIN POLICY_LOOKUP_NAMES }
            process { PROCESS_TERMINATE PROCESS_CREATE_THREAD
                PROCESS_SET_SESSIONID PROCESS_VM_OPERATION
                PROCESS_VM_READ PROCESS_VM_WRITE PROCESS_DUP_HANDLE
                PROCESS_CREATE_PROCESS PROCESS_SET_QUOTA
                PROCESS_SET_INFORMATION PROCESS_QUERY_INFORMATION
                PROCESS_SUSPEND_RESUME} 
            thread { THREAD_TERMINATE THREAD_SUSPEND_RESUME
                THREAD_GET_CONTEXT THREAD_SET_CONTEXT
                THREAD_SET_INFORMATION THREAD_QUERY_INFORMATION
                THREAD_SET_THREAD_TOKEN THREAD_IMPERSONATE
                THREAD_DIRECT_IMPERSONATION
                THREAD_SET_LIMITED_INFORMATION
                THREAD_QUERY_LIMITED_INFORMATION }
            token { TOKEN_ASSIGN_PRIMARY TOKEN_DUPLICATE TOKEN_IMPERSONATE
                TOKEN_QUERY TOKEN_QUERY_SOURCE TOKEN_ADJUST_PRIVILEGES
                TOKEN_ADJUST_GROUPS TOKEN_ADJUST_DEFAULT TOKEN_ADJUST_SESSIONID }
            desktop { DESKTOP_READOBJECTS DESKTOP_CREATEWINDOW
                DESKTOP_CREATEMENU DESKTOP_HOOKCONTROL
                DESKTOP_JOURNALRECORD DESKTOP_JOURNALPLAYBACK
                DESKTOP_ENUMERATE DESKTOP_WRITEOBJECTS DESKTOP_SWITCHDESKTOP }
            windowstation { WINSTA_ENUMDESKTOPS WINSTA_READATTRIBUTES
                WINSTA_ACCESSCLIPBOARD WINSTA_CREATEDESKTOP
                WINSTA_WRITEATTRIBUTES WINSTA_ACCESSGLOBALATOMS
                WINSTA_EXITWINDOWS WINSTA_ENUMERATE WINSTA_READSCREEN }
            winsta { WINSTA_ENUMDESKTOPS WINSTA_READATTRIBUTES
                WINSTA_ACCESSCLIPBOARD WINSTA_CREATEDESKTOP
                WINSTA_WRITEATTRIBUTES WINSTA_ACCESSGLOBALATOMS
                WINSTA_EXITWINDOWS WINSTA_ENUMERATE WINSTA_READSCREEN }
            com { COM_RIGHTS_EXECUTE COM_RIGHTS_EXECUTE_LOCAL 
                COM_RIGHTS_EXECUTE_REMOTE COM_RIGHTS_ACTIVATE_LOCAL 
                COM_RIGHTS_ACTIVATE_REMOTE 
            }
        }

        if {[min_os_version 6]} {
            dict lappend type_mask_map process PROCESS_QUERY_LIMITED_INFORMATION
        }

        if {[dict exists $type_mask_map $type]} {
            foreach x [dict get $type_mask_map $type] {
                if {$security_defs($x) & $access_mask} {
                    lappend rights [string tolower $x]
                    # Reset the bit so is it not included in unknown bits below
                    resetbits access_mask $security_defs($x)
                }
            }
        }

        # Finally add left over bits if any
        for {set i 0} {$i < 32} {incr i} {
            set x [expr {1 << $i}]
            if {$access_mask & $x} {
                lappend rights [hex32 $x]
            }
        }

        return $rights
    }

    return [_access_mask_to_rights $access_mask $type]
}

# Map the symbolic CreateDisposition parameter of CreateFile to integer values
proc twapi::_create_disposition_to_code {sym} {
    if {[string is integer -strict $sym]} {
        return $sym
    }
    # CREATE_NEW          1
    # CREATE_ALWAYS       2
    # OPEN_EXISTING       3
    # OPEN_ALWAYS         4
    # TRUNCATE_EXISTING   5
    return [dict get {
        create_new 1
        create_always 2
        open_existing 3
        open_always 4
        truncate_existing 5} $sym]
}

# Wrapper around CreateFile
proc twapi::create_file {path args} {
    array set opts [parseargs args {
        {access.arg {generic_read}}
        {share.arg {read write delete}}
        {inherit.bool 0}
        {secd.arg ""}
        {createdisposition.arg open_always}
        {flags.int 0}
        {templatefile.arg NULL}
    } -maxleftover 0]

    set access_mode [_access_rights_to_mask $opts(access)]
    set share_mode [_share_mode_to_mask $opts(share)]
    set create_disposition [_create_disposition_to_code $opts(createdisposition)]
    return [CreateFile $path \
                $access_mode \
                $share_mode \
                [_make_secattr $opts(secd) $opts(inherit)] \
                $create_disposition \
                $opts(flags) \
                $opts(templatefile)]
}

# Map a set of share mode symbols to a flag. Concatenates
# all the arguments, and then OR's the individual elements. Each
# element may either be a integer or one of the share modes
proc twapi::_share_mode_to_mask {modelist} {
    # Values correspond to FILE_SHARE_* defines
    return [_parse_symbolic_bitmask $modelist {read 1 write 2 delete 4}]
}

# Construct a security attributes structure out of a security descriptor
# and inheritance. The command is here because we do not want to
# have to load the twapi_security package for the common case of
# null security attributes.
proc twapi::_make_secattr {secd inherit} {
    if {$inherit} {
        set sec_attr [list $secd 1]
    } else {
        if {[llength $secd] == 0} {
            # If a security descriptor not specified, keep
            # all security attributes as an empty list (ie. NULL)
            set sec_attr [list ]
        } else {
            set sec_attr [list $secd 0]
        }
    }
    return $sec_attr
}

# Returns the sid, domain and type for an account
proc twapi::lookup_account_name {name args} {
    variable _name_to_sid_cache

    # Fast path - no options specified and cached
    if {[llength $args] == 0 && [dict exists $_name_to_sid_cache "" $name]} {
        return [lindex [dict get $_name_to_sid_cache "" $name] 0]
    }

    array set opts [parseargs args \
                        [list all \
                             sid \
                             domain \
                             type \
                             [list system.arg ""]\
                            ]]

    if {! [dict exists $_name_to_sid_cache $opts(system) $name]} {
        dict set _name_to_sid_cache $opts(system) $name [LookupAccountName $opts(system) $name]
    }    
    lassign [dict get $_name_to_sid_cache $opts(system) $name] sid domain type

    set result [list ]
    if {$opts(all) || $opts(domain)} {
        lappend result -domain $domain
    }
    if {$opts(all) || $opts(type)} {
        if {[info exists twapi::sid_type_names($type)]} {
            lappend result -type $twapi::sid_type_names($type)
        } else {
            # Could be the "logonid" dummy type we added above
            lappend result -type $type
        }
    }

    if {$opts(all) || $opts(sid)} {
        lappend result -sid $sid
    }

    # If no options specified, only return the sid/name
    if {[llength $result] == 0} {
        return $sid
    }

    return $result
}


# Returns the name, domain and type for an account
proc twapi::lookup_account_sid {sid args} {
    variable _sid_to_name_cache

    # Fast path - no options specified and cached
    if {[llength $args] == 0 && [dict exists $_sid_to_name_cache "" $sid]} {
        return [lindex [dict get $_sid_to_name_cache "" $sid] 0]
    }

    array set opts [parseargs args \
                        [list all \
                             name \
                             domain \
                             type \
                             [list system.arg ""]\
                            ]]

    if {! [dict exists $_sid_to_name_cache $opts(system) $sid]} {
        # Not in cache. Need to look up

        # LookupAccountSid returns an error for this SID
        if {[is_valid_sid_syntax $sid] &&
            [string match -nocase "S-1-5-5-*" $sid]} {
            set name "Logon SID"
            set domain "NT AUTHORITY"
            set type "logonid"
            dict set _sid_to_name_cache $opts(system) $sid [list $name $domain $type]
        } else {
            set data [LookupAccountSid $opts(system) $sid]
            lassign $data name domain type
            dict set _sid_to_name_cache $opts(system) $sid $data
        }
    } else {
        lassign [dict get $_sid_to_name_cache $opts(system) $sid] name domain type
    }


    set result [list ]
    if {$opts(all) || $opts(domain)} {
        lappend result -domain $domain
    }
    if {$opts(all) || $opts(type)} {
        if {[info exists twapi::sid_type_names($type)]} {
            lappend result -type $twapi::sid_type_names($type)
        } else {
            # Could be the "logonid" dummy type we added above
            lappend result -type $type
        }
    }

    if {$opts(all) || $opts(name)} {
        lappend result -name $name
    }

    # If no options specified, only return the sid/name
    if {[llength $result] == 0} {
        return $name
    }

    return $result
}

# Returns the sid for a account - may be given as a SID or name
proc twapi::map_account_to_sid {account args} {
    array set opts [parseargs args {system.arg} -nulldefault]

    # Treat empty account as null SID (self)
    if {[string length $account] == ""} {
        return ""
    }

    if {[is_valid_sid_syntax $account]} {
        return $account
    } else {
        return [lookup_account_name $account -system $opts(system)]
    }
}


# Returns the name for a account - may be given as a SID or name
proc twapi::map_account_to_name {account args} {
    array set opts [parseargs args {system.arg} -nulldefault]

    if {[is_valid_sid_syntax $account]} {
        return [lookup_account_sid $account -system $opts(system)]
    } else {
        # Verify whether a valid account by mapping to an sid
        if {[catch {map_account_to_sid $account -system $opts(system)}]} {
            # As a special case, change LocalSystem to SYSTEM. Some Windows
            # API's (such as services) return LocalSystem which cannot be
            # resolved by the security functions. This name is really the
            # same a the built-in SYSTEM
            if {$account == "LocalSystem"} {
                return "SYSTEM"
            }
            error "Unknown account '$account'"
        } 
        return $account
    }
}

# Return the user account for the current process
proc twapi::get_current_user {{format -samcompatible}} {

    set return_sid false
    switch -exact -- $format {
        -fullyqualifieddn {set format 1}
        -samcompatible {set format 2}
        -display {set format 3}
        -uniqueid {set format 6}
        -canonical {set format 7}
        -userprincipal {set format 8}
        -canonicalex {set format 9}
        -serviceprincipal {set format 10}
        -dnsdomain {set format 12}
        -sid {set format 2 ; set return_sid true}
        default {
            error "Unknown user name format '$format'"
        }
    }

    set user [GetUserNameEx $format]

    if {$return_sid} {
        return [map_account_to_sid $user]
    } else {
        return $user
    }
}

# Get a new uuid
proc twapi::new_uuid {{opt ""}} {
    if {[string length $opt]} {
        if {[string equal $opt "-localok"]} {
            set local_ok 1
        } else {
            error "Invalid or unknown argument '$opt'"
        }
    } else {
        set local_ok 0
    }
    return [UuidCreate $local_ok] 
}
proc twapi::nil_uuid {} {
    return [UuidCreateNil]
}

proc twapi::new_guid {} {
    return [canonicalize_guid [new_uuid]]
}

# Get a handle to a LSA policy. TBD - document
proc twapi::get_lsa_policy_handle {args} {
    array set opts [parseargs args {
        {system.arg ""}
        {access.arg policy_read}
    } -maxleftover 0]

    set access [_access_rights_to_mask $opts(access)]
    return [Twapi_LsaOpenPolicy $opts(system) $access]
}

# Close a LSA policy handle. TBD - document
proc twapi::close_lsa_policy_handle {h} {
    LsaClose $h
    return
}

# Eventlog stuff in the base package

namespace eval twapi {
    # Keep track of event log handles - values are "r" or "w"
    variable eventlog_handles
    array set eventlog_handles {}
}

# Open an eventlog for reading or writing
proc twapi::eventlog_open {args} {
    variable eventlog_handles

    array set opts [parseargs args {
        system.arg
        source.arg
        file.arg
        write
    } -nulldefault -maxleftover 0]
    if {$opts(source) == ""} {
        # Source not specified
        if {$opts(file) == ""} {
            # No source or file specified, default to current event log 
            # using executable name as source
            set opts(source) [file rootname [file tail [info nameofexecutable]]]
        } else {
            if {$opts(write)} {
                error "Option -file may not be used with -write"
            }
        }
    } else {
        # Source explicitly specified
        if {$opts(file) != ""} {
            error "Option -file may not be used with -source"
        }
    }

    if {$opts(write)} {
        set handle [RegisterEventSource $opts(system) $opts(source)]
        set mode write
    } else {
        if {$opts(source) != ""} {
            set handle [OpenEventLog $opts(system) $opts(source)]
        } else {
            set handle [OpenBackupEventLog $opts(system) $opts(file)]
        }
        set mode read
    }

    set eventlog_handles($handle) $mode
    return $handle
}

# Close an event log opened for writing
proc twapi::eventlog_close {hevl} {
    variable eventlog_handles

    if {[_eventlog_valid_handle $hevl read]} {
        CloseEventLog $hevl
    } else {
        DeregisterEventSource $hevl
    }

    unset eventlog_handles($hevl)
}


# Log an event
proc twapi::eventlog_write {hevl id args} {
    _eventlog_valid_handle $hevl write raise

    array set opts [parseargs args {
        {type.arg information {success error warning information auditsuccess auditfailure}}
        {category.int 1}
        loguser
        params.arg
        data.arg
    } -nulldefault]


    switch -exact -- $opts(type) {
        success          {set opts(type) 0}
        error            {set opts(type) 1}
        warning          {set opts(type) 2}
        information      {set opts(type) 4}
        auditsuccess     {set opts(type) 8}
        auditfailure     {set opts(type) 16}
        default {error "Invalid value '$opts(type)' for option -type"}
    }
    
    if {$opts(loguser)} {
        set user [get_current_user -sid]
    } else {
        set user ""
    }

    ReportEvent $hevl $opts(type) $opts(category) $id \
        $user $opts(params) $opts(data)
}


# Log a message 
proc twapi::eventlog_log {message args} {
    array set opts [parseargs args {
        system.arg
        source.arg
        {type.arg information}
        {category.int 0}
    } -nulldefault]

    set hevl [eventlog_open -write -source $opts(source) -system $opts(system)]

    trap {
        eventlog_write $hevl 1 -params [list $message] -type $opts(type) -category $opts(category)
    } finally {
        eventlog_close $hevl
    }
    return
}

proc twapi::make_logon_identity {username password domain} {
    if {[concealed? $password]} {
        return [list $username $domain $password]
    } else {
        return [list $username $domain [conceal $password]]
    }
}

proc twapi::read_credentials {args} {
    array set opts [parseargs args {
        target.arg
        winerror.int
        username.arg
        password.arg
        persist.bool
        {type.sym generic {domain 0 generic 0x40000 runas 0x80000}}
        {forceui.bool 0 0x80}
        {showsaveoption.bool true}
        {expectconfirmation.bool 0 0x20000}
    } -maxleftover 0 -nulldefault]

    if {$opts(persist) && ! $opts(expectconfirmation)} {
        badargs! "Option -expectconfirmation must be specified as true if -persist is true"
    }

    # 0x8 -> CREDUI_FLAGS_EXCLUDE_CERTIFICATES (needed for console)
    set flags [expr {0x8 | $opts(forceui) | $opts(expectconfirmation)}]

    if {$opts(persist)} {
        if {! $opts(showsaveoption)} {
            incr flags 0x1000;  # CREDUI_FLAGS_PERSIST
        }
    } else {
        incr flags 0x2;         # CREDUI_FLAGS_DO_NOT_PERSIST
        if {$opts(showsaveoption)} {
            incr flags 0x40;    # CREDUI_FLAGS_SHOW_SAVE_CHECK_BOX
        }
    }

    incr flags $opts(type)

    return [CredUICmdLinePromptForCredentials $opts(target) NULL $opts(winerror) $opts(username) $opts(password) $opts(persist) $flags]
}

# Prompt for a password at the console
proc twapi::credentials_dialog {args} {
    array set opts [parseargs args {
        target.arg
        winerror.int
        username.arg
        password.arg
        persist.bool
        {type.sym generic {domain 0 generic 0x40000 runas 0x80000}}
        {forceui.bool 0 0x80}
        {showsaveoption.bool true}
        {expectconfirmation.bool 0 0x20000}
        {fillusername.bool 0 0x800}
        {filllocaladmins.bool 0 0x4}
        {notifyfail.bool 0 0x1}
        {passwordonly.bool 0 0x200}
        {requirecertificate.bool 0 0x10}
        {requiresmartcard.bool 0 0x100}
        {validateusername.bool 0 0x400}
        {parent.arg NULL}
        message.arg
        caption.arg
        {bitmap.arg NULL}
    } -maxleftover 0 -nulldefault]

    if {$opts(persist) && ! $opts(expectconfirmation)} {
        badargs! "Option -willconfirm must be specified as true if -persist is true"
    }

    set flags [expr { 0x8 | $opts(forceui) | $opts(notifyfail) | $opts(expectconfirmation) | $opts(fillusername) | $opts(filllocaladmins)}]

    if {$opts(persist)} {
        if {! $opts(showsaveoption)} {
            incr flags 0x1000;  # CREDUI_FLAGS_PERSIST
        }
    } else {
        incr flags 0x2;         # CREDUI_FLAGS_DO_NOT_PERSIST
        if {$opts(showsaveoption)} {
            incr flags 0x40;    # CREDUI_FLAGS_SHOW_SAVE_CHECK_BOX
        }
    }

    incr flags $opts(type)

    return [CredUIPromptForCredentials [list $opts(parent) $opts(message) $opts(caption) $opts(bitmap)] $opts(target) NULL $opts(winerror) $opts(username) $opts(password) $opts(persist) $flags]
}

proc twapi::confirm_credentials {target valid} {
    return [CredUIConfirmCredential $target $valid]
}

# Validate a handle for a mode. Always raises error if handle is invalid
# If handle valid but not for that mode, will raise error iff $raise_error
# is non-empty. Returns 1 if valid, 0 otherwise
proc twapi::_eventlog_valid_handle {hevl mode {raise_error ""}} {
    variable eventlog_handles
    if {![info exists eventlog_handles($hevl)]} {
        error "Invalid event log handle '$hevl'"
    }

    if {[string compare $eventlog_handles($hevl) $mode]} {
        if {$raise_error != ""} {
            error "Eventlog handle '$hevl' not valid for $mode"
        }
        return 0
    } else {
        return 1
    }
}

### Common disk related

# Map bit mask to list of drive letters
proc twapi::_drivemask_to_drivelist {drivebits} {
    set drives [list ]
    set i 0
    foreach drive {A B C D E F G H I J K L M N O P Q R S T U V W X Y Z} {
        if {$drivebits == 0} break
        set drivemask [expr {1 << $i}]
        if {[expr {$drivebits & $drivemask}]} {
            lappend drives $drive:
            set drivebits [expr {$drivebits & ~ $drivemask}]
        }
        incr i
    }
    return $drives
}

### Type casts
proc twapi::tclcast {type val} {
    # Only permit these because wideInt, for example, cannot be reliably
    # converted -> it can return an int instead.
    set types {"" empty null int boolean double string list dict}
    if {$type ni $types} {
        badargs! "Bad cast to \"$type\". Must be one of: $types"
    }
    return [Twapi_InternalCast $type $val]
}

if {[info commands ::lmap] eq "::lmap"} {
    proc twapi::safearray {type l} {
        set type [dict! {
            variant ""
            boolean boolean
            bool boolean
            int  int
            i4   int
            double double
            r8   double
            string string
            bstr string
        } $type]
        return [lmap val $l {tclcast $type $val}]
    }
} else {
    proc twapi::safearray {type l} {
        set type [dict! {
            variant ""
            boolean boolean
            bool boolean
            int  int
            i4   int
            double double
            r8   double
            string string
            bstr string
        } $type]
        set l2 {}
        foreach val $l {
            lappend l2 [tclcast $type $val]
        }
        return $l2
    }
}

namespace eval twapi::recordarray {}

proc twapi::recordarray::size {ra} {
    return [llength [lindex $ra 1]]
}

proc twapi::recordarray::fields {ra} {
    return [lindex $ra 0]
}

proc twapi::recordarray::index {ra row args} {
    set r [lindex $ra 1 $row]
    if {[llength $r] == 0} {
        return $r
    }
    ::twapi::parseargs args {
        {format.arg list {list dict}}
        slice.arg
    } -setvars -maxleftover 0

    set fields [lindex $ra 0]
    if {[info exists slice]} {
        set new_fields {}        
        set new_r {}
        foreach field $slice {
            set i [twapi::enum $fields $field]
            lappend new_r [lindex $r $i]
            lappend new_fields [lindex $fields $i]
        }
        set r $new_r
        set fields $new_fields
    }

    if {$format eq "list"} {
        return $r
    } else {
        return [::twapi::twine $fields $r]
    }
}

proc twapi::recordarray::range {ra low high} {
    return [list [lindex $ra 0] [lrange [lindex $ra 1] $low $high]]
}

proc twapi::recordarray::column {ra field args} {
    # TBD - time to see if a script loop would be faster
    ::twapi::parseargs args {
        filter.arg
    } -nulldefault -maxleftover 0 -setvars
    _recordarray -slice [list $field] -filter $filter -format flat $ra
}

proc twapi::recordarray::cell {ra row field} {
    return [lindex [lindex $ra 1 $row] [twapi::enum [lindex $ra 0] $field]]
}

proc twapi::recordarray::get {ra args} {
    ::twapi::parseargs args {
        {format.arg list {list dict flat}}
        key.arg
    } -ignoreunknown -setvars

    # format & key are options just to stop them flowing down to _recordarray
    # We do not pass it in

    return [_recordarray {*}$args $ra]
}

proc twapi::recordarray::getlist {ra args} {
    # key is an option just to stop in flowing down to _recordarray
    # We do not pass it in

    if {[llength $args] == 0} {
        return [lindex $ra 1]
    }

    ::twapi::parseargs args {
        {format.arg list {list dict flat}}
        key.arg
    } -ignoreunknown -setvars


    return [_recordarray {*}$args -format $format $ra]
}

proc twapi::recordarray::getdict {ra args} {
    ::twapi::parseargs args {
        {format.arg list {list dict}}
        key.arg
    } -ignoreunknown -setvars

    if {![info exists key]} {
        set key [lindex $ra 0 0]
    }

    # Note _recordarray has different (putting it politely) semantics
    # of how -format and -key option are handled so the below might
    # look a bit strange in that we pass -format as list and get
    # back a dict
    return [_recordarray {*}$args -format $format -key $key $ra]
}

proc twapi::recordarray::iterate {arrayvarname ra args} {

    if {[llength $args] == 0} {
        badargs! "No script supplied"
    }

    set body [lindex $args end]
    set args [lrange $args 0 end-1]

    upvar 1 $arrayvarname var

    # TBD - Can this be optimized by prepending a ::foreach to body
    # and executing that in uplevel 1 ?

    foreach rec [getlist $ra {*}$args -format dict] {
        array set var $rec
        set code [catch {uplevel 1 $body} result]
        switch -exact -- $code {
            0 {}
            1 {
                return -errorinfo $::errorInfo -errorcode $::errorCode -code error $result
            }
            3 {
                return;          # break
            }
            4 {
                # continue
            }
            default {
                return -code $code $result
            }
        }
    }
    return
}

proc twapi::recordarray::rename {ra renames} {
    set new_fields {}
    foreach field [lindex $ra 0] {
        if {[dict exists $renames $field]} {
            lappend new_fields [dict get $renames $field]
        } else {
            lappend new_fields $field
        }
    }
    return [list $new_fields [lindex $ra 1]]
}

proc twapi::recordarray::concat {args} {
    if {[llength $args] == 0} {
        return {}
    }
    set args [lassign $args ra]
    set fields [lindex $ra 0]
    set values [list [lindex $ra 1]]
    set width [llength $fields]
    foreach ra $args {
        foreach fld1 $fields fld2 [lindex $ra 0] {
            if {$fld1 ne $fld2} {
                twapi::badargs! "Attempt to concat record arrays with different fields ([join $fields ,] versus [join [lindex $ra 0] ,])"
            }
        }
        lappend values [lindex $ra 1]
    }

    return [list $fields [::twapi::lconcat {*}$values]]
}

namespace eval twapi::recordarray {
    namespace export cell column concat fields get getdict getlist index iterate range rename size
    namespace ensemble create
}

# Return a suitable cstruct definition based on a C definition
proc twapi::struct {struct_name s} {
    variable _struct_defs

    regsub -all {(/\*.* \*/){1,1}?} $s {} s
    regsub -line -all {//.*$} $s { } s
    set l {}
    foreach def [split $s ";"] {
        set def [string trim $def]
        if {$def eq ""} continue
        if {![regexp {^(.+[^[:alnum:]_])([[:alnum:]_]+)\s*(\[.+\])?$} $def ->  type name array]} {
            error "Invalid definition $def"
        }
        
        set child {}
        switch -regexp -matchvar matchvar -- [string trim $type] {
            {^char$} {set type i1}
            {^BYTE$} -
            {^unsigned char$} {set type ui1}
            {^short$} {set type i2}
            {^WORD$} -
            {^unsigned\s+short$} {set type ui2}
            {^BOOLEAN$} {set type bool}
            {^LONG$} -
            {^int$} {set type i4}
            {^UINT$} -
            {^ULONG$} -
            {^DWORD$} -
            {^unsigned\s+int$} {set type ui4}
            {^__int64$} {set type i8}
            {^unsigned\s+__int64$} {set type ui8}
            {^double$} {set type r8}
            {^LPCSTR$} -
            {^LPSTR$} -
            {^char\s*\*$} {set type lpstr}
            {^LPCWSTR$} -
            {^LPWSTR$} -
            {^WCHAR\s*\*$} {set type lpwstr}
            {^HANDLE$} {set type handle}
            {^PSID$} {set type psid}
            {^struct\s+([[:alnum:]_]+)$} {
                # Embedded struct. It should be defined already. Calling
                # it with no args returns its definition but doing that
                # to retrieve the definition could be a security hole
                # (could be passed any Tcl command!) if unwary apps
                # pass in input from unknown sources. So we explicitly
                # remember definitions instead.
                set child_name [lindex $matchvar 1]
                if {![info exists _struct_defs($child_name)]} {
                    error "Unknown struct $child_name"
                }
                set child $_struct_defs($child_name)
                set type struct
            }
            default {error "Unknown type $type"}
        }
        set count 0
        if {$array ne ""} {
            set count [string trim [string range $array 1 end-1]]
            if {![string is integer -strict $count]} {
                error "Non-integer array size"
            }
        }

        if {[string equal -nocase $name "cbSize"] &&
            $type in {i4 ui4} && $count == 0} {
            set type cbsize
        }

        lappend l [list $name $type $count $child]
    }

    set proc_body [format {
        set def %s
        if {[llength $args] == 0} {
            return $def
        } else {
            return [list $def $args]
        }
    } [list $l]]
    uplevel 1 [list proc $struct_name args $proc_body]
    set _struct_defs($struct_name) $l
    return
}

