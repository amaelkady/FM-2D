#
# Copyright (c) 2003-2007, Ashok P. Nadkarni
# All rights reserved.
#
# See the file LICENSE for license

namespace eval twapi {
    # When the process hosts Windows services, service_state
    # is used to keep state of each service. The variable
    # is indexed by NAME,FIELD where NAME is the name
    # of the service and FIELD is one of "state", "script",
    # "checkpoint", "waithint", "exitcode", "servicecode",
    # "seq", "seqack"
    variable service_state

    # Map service state names to integers
    variable service_state_values
    array set service_state_values {
        stopped       1
        start_pending 2
        stop_pending  3
        running       4
        continue_pending 5
        pause_pending 6
        paused        7
    }
}


# Return 1/0 depending on whether the given service exists
# $name may be either the internal or display name
proc twapi::service_exists {name args} {
    array set opts [parseargs args {system.arg database.arg} -nulldefault]
    # 0x00020000 -> STANDARD_RIGHTS_READ
    set scm [OpenSCManager $opts(system) $opts(database) 0x00020000]

    trap {
        GetServiceKeyName $scm $name
        set exists 1
    } onerror {TWAPI_WIN32 1060} {
        # "no such service" error for internal name.
        # Try display name
        trap {
            GetServiceDisplayName $scm $name
            set exists 1
        } onerror {TWAPI_WIN32 1060} {
            set exists 0
        }
    } finally {
        CloseServiceHandle $scm
    }

    return $exists
}


# Create a service of the specified name
proc twapi::create_service {name command args} {
    array set opts [parseargs args {
        displayname.arg
        {servicetype.arg     win32_own_process {win32_own_process win32_share_process file_system_driver kernel_driver}}
        {interactive.bool    0}
        {starttype.arg       auto_start {auto_start boot_start demand_start disabled system_start}}
        {errorcontrol.arg    normal {ignore normal severe critical}}
        loadordergroup.arg
        dependencies.arg
        account.arg
        password.arg
        system.arg
        database.arg
    } -nulldefault]


    if {[string length $opts(displayname)] == 0} {
        set opts(displayname) $name
    }

    if {[string length $command] == 0} {
        error "The executable path must not be null when creating a service"
    }
    set opts(command) $command

    switch -exact -- $opts(servicetype) {
        file_system_driver -
        kernel_driver {
            if {$opts(interactive)} {
                error "Option -interactive cannot be specified when -servicetype is $opts(servicetype)."
            }
        }
        default {
            if {$opts(interactive) && [string length $opts(account)]} {
                error "Option -interactive cannot be specified with the -account option as interactive services must run under the LocalSystem account."
            }
            if {[string equal $opts(starttype) "boot_start"]
                || [string equal $opts(starttype) "system_start"]} {
                error "Option -starttype value must be one of auto_start, demand_start or disabled when -servicetype is '$opts(servicetype)'."
            }
        }
    }

    # Map keywords to integer values
    set opts(servicetype)  [_map_servicetype_sym $opts(servicetype)]
    set opts(starttype)    [_map_starttype_sym $opts(starttype)]
    set opts(errorcontrol) [_map_errorcontrol_sym $opts(errorcontrol)]

    # If interactive, add the flag to the service type
    if {$opts(interactive)} {
        setbits opts(servicetype) 0x100; # SERVICE_INTERACTIVE_PROCESS
    }

    # Ignore password if username not specified
    if {[string length $opts(account)] == 0} {
        set opts(password) ""
    } else {
        # If domain/system not specified, tack on ".\" for local system
        if {[string first \\ $opts(account)] < 0} {
            set opts(account) ".\\$opts(account)"
        }
    }

    # 2 -> SC_MANAGER_CREATE_SERVICE
    set scm [OpenSCManager $opts(system) $opts(database) 2]
    trap {
        # 0x000F01FF -> SERVICE_ALL_ACCESS
        set svch [CreateService \
                      $scm \
                      $name \
                      $opts(displayname) \
                      0x000F01FF \
                      $opts(servicetype) \
                      $opts(starttype) \
                      $opts(errorcontrol) \
                      $opts(command) \
                      $opts(loadordergroup) \
                      "" \
                      $opts(dependencies) \
                      $opts(account) \
                      $opts(password)]

        CloseServiceHandle $svch

    } finally {
        CloseServiceHandle $scm
    }

    return
}


# Delete the given service
proc twapi::delete_service {name args} {

    array set opts [parseargs args {system.arg database.arg} -nulldefault]

    # 0x00010000 -> DELETE access
    set opts(scm_priv) 0x00010000 
    set opts(svc_priv) 0x00010000 
    set opts(proc)     twapi::DeleteService

    _service_fn_wrapper $name opts

    return
}


# Get the internal name of a service
proc twapi::get_service_internal_name {name args} {
    array set opts [parseargs args {system.arg database.arg} -nulldefault]
    # 0x00020000 -> STANDARD_RIGHTS_READ
    set scm [OpenSCManager $opts(system) $opts(database) 0x00020000]

    trap {
        if {[catch {GetServiceKeyName $scm $name} internal_name]} {
            # Maybe this is an internal name itself
            GetServiceDisplayName $scm $name; # Will throw an error if not internal name
            set internal_name $name
        }
    } finally {
        CloseServiceHandle $scm
    }

    return $internal_name
}

proc twapi::get_service_display_name {name args} {
    array set opts [parseargs args {system.arg database.arg} -nulldefault]
    # 0x00020000 -> STANDARD_RIGHTS_READ
    set scm [OpenSCManager $opts(system) $opts(database) 0x00020000]

    trap {
        if {[catch {GetServiceDisplayName $scm $name} display_name]} {
            # Maybe this is an display name itself
            GetServiceKeyName $scm $name; # Will throw an error if not display name
            set display_name $name
        }
    } finally {
        CloseServiceHandle $scm
    }

    return $display_name
}

proc twapi::start_service {name args} {
    array set opts [parseargs args {
        system.arg
        database.arg
        params.arg
        wait.int
    } -nulldefault]
    set opts(svc_priv) 0x10;    # SERVICE_START
    set opts(proc)     twapi::StartService
    set opts(args)     [list $opts(params)]
    unset opts(params)

    trap {
        _service_fn_wrapper $name opts
    } onerror {TWAPI_WIN32 1056} {
        # Error 1056 means service already running
    }

    return [wait {twapi::get_service_state $name -system $opts(system) -database $opts(database)} running $opts(wait)]
}

# TBD - document and test
proc twapi::notify_service {name code args} {
    array set opts [parseargs args {
        system.arg
        database.arg
        ignorecodes.arg
    } -nulldefault]

    if {[string is integer -strict $code] && $code >= 128 && $code <= 255} {
        # 0x100 -> SERVICE_USER_DEFINED_CONTROL 
        set access 0x100
    } elseif {$code eq "paramchange"} {
        # 0x40 -> SERVICE_PAUSE_CONTINUE
        set access 0x40
        set code 6;             # PARAMCHANGE
    } else {
        badargs! "Invalid service notification code \"$code\"."
    }

    set scm [OpenSCManager $opts(system) $opts(database) 0x00020000]
    trap {
        set svch [OpenService $scm $name $access]
    } finally {
        CloseServiceHandle $scm
    }
    
    trap {
        ControlService $svch $code
    } onerror {TWAPI_WIN32} {
        if {[lsearch -exact -integer $opts(ignorecodes) [lindex $::errorCode 1]] < 0} {
            # Not one of the error codes we can ignore. 
            rethrow
        }
    } finally {
        CloseServiceHandle $svch
    }
    return
}

proc twapi::control_service {name code access finalstate args} {
    array set opts [parseargs args {
        system.arg
        database.arg
        ignorecodes.arg
        wait.int
    } -nulldefault]
    # 0x00020000 -> STANDARD_RIGHTS_READ
    set scm [OpenSCManager $opts(system) $opts(database) 0x00020000]
    trap {
        set svch [OpenService $scm $name $access]
    } finally {
        CloseServiceHandle $scm
    }

    trap {
        ControlService $svch $code
    } onerror {TWAPI_WIN32} {
        if {[lsearch -exact -integer $opts(ignorecodes) [lindex $::errorCode 1]] < 0} {
            # Not one of the error codes we can ignore. 
            rethrow
        }
    } finally {
        CloseServiceHandle $svch
    }

    if {[string length $finalstate]} {
        # Wait until service is in specified state
        return [wait {twapi::get_service_state $name -system $opts(system) -database $opts(database)} $finalstate $opts(wait)]
    } else {
        return 0
    }
}

proc twapi::stop_service {name args} {
    # 1 -> SERVICE_CONTROL_STOP
    # 0x20 -> SERVICE_STOP
    control_service $name 1 0x20 stopped -ignorecodes 1062 {*}$args
}

proc twapi::pause_service {name args} {
    # 2 -> SERVICE_CONTROL_PAUSE
    # 0x40 -> SERVICE_PAUSE_CONTINUE
    control_service $name 2 0x40 paused {*}$args
}

proc twapi::continue_service {name args} {
    # 3 -> SERVICE_CONTROL_CONTINUE
    # 0x40 -> SERVICE_PAUSE_CONTINUE
    control_service $name 3 0x40 running {*}$args
}

proc twapi::interrogate_service {name args} {
    # 4 -> SERVICE_CONTROL_INTERROGATE
    # 0x80 -> SERVICE_INTERROGATE
    control_service $name 4 0x80 "" {*}$args
    return
}


# Retrieve status information for a service
proc twapi::get_service_status {name args} {
    array set opts [parseargs args {system.arg database.arg} -nulldefault]
    # 0x00020000 -> STANDARD_RIGHTS_READ
    set scm [OpenSCManager $opts(system) $opts(database) 0x00020000]
    trap {
        # 4 -> SERVICE_QUERY_STATUS
        set svch [OpenService $scm $name 4]
    } finally {
        # Do not need SCM anymore
        CloseServiceHandle $scm
    }

    trap {
        return [QueryServiceStatusEx $svch 0]
    } finally {
        CloseServiceHandle $svch
    }
}


# Get the state of the service
proc twapi::get_service_state {name args} {
    return [kl_get [get_service_status $name {*}$args] state]
}


# Get the current configuration for a service
proc twapi::get_service_configuration {name args} {
    array set opts [parseargs args {
        system.arg
        database.arg
        all
        servicetype
        interactive
        errorcontrol
        starttype
        command
        loadordergroup
        account
        displayname
        dependencies
        description
        scm_handle.arg
        tagid
        failureactions
    } -nulldefault -hyphenated]

    if {$opts(-scm_handle) eq ""} {
        # Use 0x00020000 -> STANDARD_RIGHTS_READ for SCM 
        set scmh [OpenSCManager $opts(-system) $opts(-database) 0x00020000]
        trap {
            set svch [OpenService $scmh $name 1]; # 1 -> SERVICE_QUERY_CONFIG
        } finally {
            CloseServiceHandle $scmh
        }
    } else {
        set svch [OpenService $scmh $name 1]; # 1 -> SERVICE_QUERY_CONFIG
    }

    trap {
        set result [QueryServiceConfig $svch]
        if {$opts(-all) || $opts(-description)} {
            dict set result -description {}
            # For backwards compatibility, ignore errors if description
            # cannot be obtained
            catch {
                dict set result -description [QueryServiceConfig2 $svch 1]; # 1 -> SERVICE_CONFIG_DESCRIPTION
            }
        }

        if {$opts(-all) || $opts(-failureactions)} {
            # 2 -> SERVICE_CONFIG_FAILURE_ACTIONS
            lassign  [QueryServiceConfig2 $svch 2] resetperiod rebootmsg command failure_actions
            set actions {}
            foreach action $failure_actions {
                lappend actions [list [dict* {0 none 1 restart 2 reboot 3 run} [lindex $action 0]] [lindex $action 1]]
            }
            dict set result -failureactions [list -resetperiod $resetperiod -rebootmsg $rebootmsg -command $command -actions $actions]
        }
    } finally {
        CloseServiceHandle $svch
    }

    if {! $opts(-all)} {
        set result [dict filter $result script {k val} {set opts($k)}]
    }

    if {[dict exists $result -errorcontrol]} {
        dict set result -errorcontrol [_map_errorcontrol_code [dict get $result -errorcontrol]]
    }

    if {[dict exists $result -starttype]} {
        dict set result -starttype [_map_starttype_code [dict get $result -starttype]]
    }

    return $result
}

# Sets a service configuration
proc twapi::set_service_configuration {name args} {
    # Get the current values - we will need these for validation
    # with the new values
    array set current [get_service_configuration $name -all]
    set current(-password) ""; # This is not returned by get_service_configuration

    # Now parse arguments, filling in defaults
    array set opts [parseargs args {
        displayname.arg
        servicetype.arg
        interactive.bool
        starttype.arg
        errorcontrol.arg
        command.arg
        loadordergroup.arg
        dependencies.arg
        account.arg
        password.arg
        {system.arg ""}
        {database.arg ""}
    }]

    if {[info exists opts(account)] && ! [info exists opts(password)]} {
        error "Option -password must also be specified when -account is specified."
    }

    # Merge current configuration with specified options
    foreach opt {
        displayname
        servicetype
        interactive
        starttype
        errorcontrol
        command
        loadordergroup
        dependencies
        account
        password
    } {
        if {[info exists opts($opt)]} {
            set winparams($opt) $opts($opt)
        } else {
            set winparams($opt) $current(-$opt)
        }
    }

    # Validate the new configuration
    switch -exact -- $winparams(servicetype) {
        file_system_driver -
        kernel_driver {
            if {$winparams(interactive)} {
                error "Option -interactive cannot be specified when -servicetype is $winparams(servicetype)."
            }
        }
        default {
            if {$winparams(interactive) &&
                [string length $winparams(account)] &&
                [string compare -nocase $winparams(account) "LocalSystem"]
            } {
                error "Option -interactive cannot be specified with the -account option as interactive services must run under the LocalSystem account."
            }
            if {[string equal $winparams(starttype) "boot_start"]
                || [string equal $winparams(starttype) "system_start"]} {
                error "Option -starttype value must be one of auto_start, demand_start or disabled when -servicetype is '$winparams(servicetype)'."
            }
        }
    }

    # Map keywords to integer values
    set winparams(servicetype)  [_map_servicetype_sym $winparams(servicetype)]
    set winparams(starttype)    [_map_starttype_sym $winparams(starttype)]
    set winparams(errorcontrol) [_map_errorcontrol_sym $winparams(errorcontrol)]

    # Merge the interactive setting
    # 0x100 -> SERVICE_INTERACTIVE_PROCESS
    if {$winparams(interactive)} {
        setbits winparams(servicetype) 0x100
    } else {
        resetbits winparams(servicetype) 0x100 
    }

    # If domain/system not specified, tack on ".\" for local system
    if {[string length $winparams(account)]} {
        if {[string first \\ $winparams(account)] < 0} {
            set winparams(account) ".\\$winparams(account)"
        }
    }

    # Now replace any options that were not specified with "no change"
    # tokens.
    foreach opt {servicetype starttype errorcontrol} {
        if {![info exists opts($opt)]} {
            set winparams($opt) 0xffffffff;  # SERVICE_NO_CHANGE
        }
    }
    # -servicetype and -interactive go in same field
    if {![info exists opts(servicetype)] && ![info exists opts(interactive)]} {
        set winparams(servicetype) 0xffffffff; # SERVICE_NO_CHANGE
    }

    foreach opt {command loadordergroup dependencies account password displayname} {
        if {![info exists opts($opt)]} {
            set winparams($opt) $twapi::nullptr
        }
    }

    set opts(scm_priv) 0x00020000; # 0x00020000 -> STANDARD_RIGHTS_READ
    set opts(svc_priv) 2;    # 2 -> SERVICE_CHANGE_CONFIG

    set opts(proc)     twapi::ChangeServiceConfig
    set opts(args) \
        [list \
             $winparams(servicetype) \
             $winparams(starttype) \
             $winparams(errorcontrol) \
             $winparams(command) \
             $winparams(loadordergroup) \
             "" \
             $winparams(dependencies) \
             $winparams(account) \
             $winparams(password) \
             $winparams(displayname)]

    _service_fn_wrapper $name opts

    return
}

proc twapi::set_service_description {name description args} {
    array set opts [parseargs args {
        {system.arg ""}
        {database.arg ""}
    } -maxleftover 0]

    set opts(scm_priv) 0x00020000; # 0x00020000 -> STANDARD_RIGHTS_READ
    set opts(svc_priv) 2;    # 2 -> SERVICE_CHANGE_CONFIG

    set opts(proc) twapi::ChangeServiceConfig2
    set opts(args) [list 1 $description]
    
    _service_fn_wrapper $name opts
    return
}

proc twapi::set_service_failure_actions {name args} {
    array set opts [parseargs args {
        {system.arg ""}
        {database.arg ""}
        resetperiod.arg
        {rebootmsg.arg __null__}
        {command.arg __null__}
        actions.arg
    } -maxleftover 0]

    set opts(scm_priv) 0x00020000; # 0x00020000 -> STANDARD_RIGHTS_READ
    set opts(svc_priv) 2;    # 2 -> SERVICE_CHANGE_CONFIG

    # If option actions is not specified, actions for the service
    # are left unchanged.
    if {[info exists opts(actions)]} {
        set actions {}
        foreach action $opts(actions) {
            if {[llength $action] != 2} {
                error "Invalid format for failure action"
            }
            set action_code [dict* {none 0 restart 1 reboot 2 run 3} [lindex $action 0]]
            if {$action_code == 1} {
                # Also need SERVICE_START access right for restart action
                set opts(svc_priv) [expr {$opts(svc_priv) | 0x10}]
            }
            lappend actions [list $action_code [lindex $action 1]]
        }
        if {![info exists opts(resetperiod)] || $opts(resetperiod) eq "infinite"} {
            set opts(resetperiod) 0xffffffff
        }
        set fail_params [list $opts(resetperiod) $opts(rebootmsg) $opts(command) $actions]
    } else {
        if {[info exists opts(resetperiod)]} {
            badargs! "Option -resetperiod can only be used if the -actions option is also specified."
        }
        set fail_params [list 0 $opts(rebootmsg) $opts(command)]
    }

    set opts(proc) twapi::ChangeServiceConfig2
    set opts(args) [list 2 $fail_params]; # 2 -> SERVICE_CONFIG_FAILURE_ACTIONS
    _service_fn_wrapper $name opts
    return
}

# Get status for the specified service types
proc twapi::get_multiple_service_status {args} {
    set service_types [list \
                           kernel_driver \
                           file_system_driver \
                           adapter \
                           recognizer_driver \
                           win32_own_process \
                           win32_share_process]
    set switches [concat $service_types \
                      [list active inactive] \
                      [list system.arg database.arg]]
    array set opts [parseargs args $switches -nulldefault]

    set servicetype 0
    foreach type $service_types {
        if {$opts($type)} {
            set servicetype [expr { $servicetype | [_map_servicetype_sym $type]}]
        }
    }
    if {$servicetype == 0} {
        # No type specified, return all
        set servicetype 0x3f
    }

    set servicestate 0
    if {$opts(active)} {
        set servicestate 1;     # 1 -> SERVICE_ACTIVE
    }
    if {$opts(inactive)} {
        set servicestate [expr {$servicestate | 2}]; # 2 -> SERVICE_INACTIVE
    }
    if {$servicestate == 0} {
        # No state specified, include all
        set servicestate 3
    }

    # 4 -> SC_MANAGER_ENUMERATE_SERVICE
    set scm [OpenSCManager $opts(system) $opts(database) 4]
    trap {
        set fields {
            servicetype state controls_accepted  exitcode service_code
            checkpoint wait_hint pid serviceflags name displayname interactive 
        }
        return [list $fields [EnumServicesStatusEx $scm 0 $servicetype $servicestate __null__]]
    } finally {
        CloseServiceHandle $scm
    }
}


# Get status for the dependents of the specified service
proc twapi::get_dependent_service_status {name args} {
    array set opts [parseargs args \
                        [list active inactive system.arg database.arg] \
                        -nulldefault]

    set servicestate 0
    if {$opts(active)} {
        set servicestate 1;     # 1 -> SERVICE_ACTIVE
    }
    if {$opts(inactive)} {
        set servicestate [expr {$servicestate | 2}]; # SERVICE_INACTIVE
    }
    if {$servicestate == 0} {
        # No state specified, include all
        set servicestate 3
    }

    set opts(svc_priv) 8; # SERVICE_ENUMERATE_DEPENDENTS
    set opts(proc)     twapi::EnumDependentServices
    set opts(args)     [list $servicestate]

    set fields {
        servicetype state controls_accepted  exitcode service_code
        checkpoint wait_hint name displayname interactive 
    }

    return [list $fields [_service_fn_wrapper $name opts]]


}


################################################################
# Commands for running as a service

proc twapi::run_as_service {services args} {
    variable service_state

    if {[llength $services] == 0} {
        win32_error 87 "No services specified"
    }

    array set opts [parseargs args {
        interactive.bool
        {controls.arg {stop shutdown}}
    } -nulldefault -maxleftover 0]

    # Currently service controls are per process, not per service and
    # are fixed for the duration of the process.
    # TBD - C code actually allows for per service controls. Expose?
    set service_state(controls) [_parse_service_accept_controls $opts(controls)]
    if {![min_os_version 5 1]} {
        # Not accepted on Win2k
        if {$service_state(controls) & 0x80} {
            error "Service control type 'sessionchange' is not valid on this platform"
        }
    }

    if {[llength $services] == 1} {
        set type 0x10;          # WIN32_OWN_PROCESS
    } else {
        set type 0x20;          # WIN32_SHARE_PROCESS
    }
    if {$opts(interactive)} {
        setbits type 0x100;     # INTERACTIVE_PROCESS
    }

    set service_defs [list ]
    foreach service $services {
        lassign $service name script
        set name [string tolower $name]
        lappend service_defs [list $name $service_state(controls)]
        set service_state($name,state)       stopped
        set service_state($name,script)      $script
        set service_state($name,checkpoint)  0
        set service_state($name,waithint)    2000; # 2 seconds
        set service_state($name,exitcode)    0
        set service_state($name,servicecode) 0
        set service_state($name,seq)         0
        set service_state($name,seqack)      0
    }

    twapi::Twapi_BecomeAService $type {*}$service_defs

    # Turn off console events by installing our own handler,
    # else tclsh will exit when a user logs off even if it is running
    # as a service
    # COMMENTED OUT because now done in C code itself
    # proc ::twapi::_service_console_handler args { return 1 }
    # set_console_control_handler ::twapi::_service_console_handler

    # Redefine ourselves as we should not be called again
    proc ::twapi::run_as_service args {
        error "Already running as a service"
    }
}


# Callback that handles requests from the service control manager
proc twapi::_service_handler {name service_status_handle control args} {
    # TBD - should we catch the error or let the C code see it ?
    if {[catch {
        _service_handler_unsafe $name $service_status_handle $control $args
    } msg]} {
        # TBD - log error message
        catch {eventlog_log "Error in service handler for service $name. $msg Stack: $::errorInfo" -type error}
    }
}

# Can raise an error
proc twapi::_service_handler_unsafe {name service_status_handle control extra_args} {
    variable service_state

    set name [string tolower $name]

    # The service handler will receive control codes from the service
    # control manager and modify the state of a service accordingly.
    # It also calls the script registered by the application for
    # the service. The caller is expected to complete the state change
    # by calling service_change_state_complete either inside the
    # callback or at some later point.

    set tell_app true;          # Does app need to be notified ?
    set report_status true;     # Whether we should update status
    set need_response true;     # App should report status back

    switch -glob -- "$service_state($name,state),$control" {
        stopped,start {
            set service_state($name,state) start_pending
            set service_state($name,checkpoint) 1
        }
        start_pending,shutdown -
        paused,shutdown        -
        pause_pending,shutdown -
        continue_pending,shutdown -
        running,shutdown -
        start_pending,stop -
        paused,stop        -
        pause_pending,stop -
        continue_pending,stop -
        running,stop {
            set service_state($name,state) stop_pending
            set service_state($name,checkpoint) 1
        }
        running,pause {
            set service_state($name,state) pause_pending
            set service_state($name,checkpoint) 1
        }
        pause_pending,continue -
        paused,continue {
            set service_state($name,state) continue_pending
            set service_state($name,checkpoint) 1
        }
        *,interrogate {
            # No state change, we will simply report status below
            set tell_app false; # No need to bother the application
        }
        *,userdefined -
        *,paramchange -
        *,netbindadd -
        *,netbindremove -
        *,netbindenable -
        *,netbinddisable -
        *,deviceevent -
        *,hardwareprofilechange -
        *,powerevent -
        *,sessionchange {
            # Notifications, should not report status.
            set report_status false
            set need_response false
        }
        default {
            # All other cases are no-ops (e.g. paused,pause) or
            # don't make logical sense (e.g. stop_pending,continue)
            # For now, we simply ignore them but not sure
            # if we should just update service status anyways
            return
        }
    }

    if {$report_status} {
        _report_service_status $name
    }

    set result 0
    if {$tell_app} {
        if {[catch {
            if {$need_response} {
                set seq [incr service_state($name,seq)]
            } else {
                set seq -1
            }
            set result [uplevel #0 [linsert $service_state($name,script) end $control $name $seq {*}$extra_args]]
            # Note that if the above script may call back into us,
            # via update_service_status for example, the service
            # state may be updated at this point
        } msg]} {
            # TBD - report if the script throws errors
        }
    }

    if {$result eq "allow"} {
        set result 0
    } elseif {$result eq "deny"} {
        set result  0x424D5144; # BROADCAST_QUERY_DENY
    }

    return $result
}

# Called by the application to update it's status
# status should be one of "running", "paused" or "stopped"
# seq is 0 or the sequence number of a previous callback to
# the application to which this is the response.
proc twapi::update_service_status {name seq state args} {
    variable service_state

    if {$state ni {running paused stopped}} {
        error "Invalid state token $state"
    }

    if {$seq == -1} {
        # This was a notification. App should not have responded.
        # Just ignore it
        return ignored
    }

    array set opts [parseargs args {
        exitcode.int
        servicecode.int
        waithint.int
    } -maxleftover 0]

    set name [string tolower $name]

    # Depending on the current state of the application,
    # we may or may not be able to change state. For
    # example, if the current state is "running" and
    # the new state is "stopped", that is ok. But the
    # converse is not allowed since we cannot
    # transition from stopped to running unless
    # the SCM has sent us a start signal.

    # If the seq is greater than the last one we sent, bug somewhere
    if {$service_state($name,seq) < $seq} {
        error "Invalid sequence number $seq (too large) for service status update."
    }

    # If we have a request outstanding (to the app) that the app
    # has not yet responded to, then all calls from the app with
    # no seq number (i.e. 0) or calls with an older sequence number
    # are ignored.
    if {($service_state($name,seq) > $service_state($name,seqack)) &&
        ($seq == 0 || $seq < $service_state($name,seq))} {
        # Ignore this request
        return ignored
    }

    set service_state($name,seqack) $seq; # last responded sequence number

    # If state specified as stopped, store the exit codes
    if {$state eq "stopped"} {
        if {[info exists opts(exitcode)]} {
            set service_state($name,exitcode) $opts(exitcode)
        }
        if {[info exists opts(servicecode)]} {
            set service_state($name,servicecode) $opts(servicecode)
        }
    }

    upvar 0 service_state($name,state) current_state

    # If there is no state change, nothing to do
    if {$state eq $current_state} {
        return nochange
    }

    switch -exact -- $state {
        stopped {
            # Application can stop at any time from any other state.
            # No questions asked.
        }
        running {
            if {$current_state eq "stopped" || $current_state eq "paused"} {
                # This should not happen if all the rules are followed by the
                # application code.
                #error "Service $name attempted to transition directly from stopped or paused state to running state without an intermediate pending state"
                return invalidchange
            }
        }
        paused {
            if {$current_state ne "pause_pending" &&
                $current_state ne "continue_pending"} {
                # This should not happen if all the rules are followed by the
                # application code.
                #error "Service $name attempted to transition from $current_state state to paused state"
                return invalidchange
            }
        }
    }

    set current_state $state
    _report_service_status $name

    if {$state eq "stopped"} {
        # If all services have stopped, tell the app
        set all_stopped true
        foreach {entry val} [array get service_state *,state] {
            if {$val ne "stopped"} {
                set all_stopped false
                break
            }
        }
        if {$all_stopped} {
            uplevel #0 [linsert $service_state($name,script) end all_stopped $name 0]
        }
    }

    return changed;             # State changed
}


# Report the status of a service back to the SCM
proc twapi::_report_service_status {name} {
    variable service_state
    upvar 0 service_state($name,state) current_state

    # If the state is a pending state, then make sure we
    # increment the checkpoint value
    if {[string match *pending $current_state]} {
        incr service_state($name,checkpoint)
        set waithint $service_state($name,waithint)
    } else {
        set service_state($name,checkpoint) 0
        set waithint 0
    }

    # Currently service controls are per process, not per service and
    # are fixed for the duration of the process. So we always pass
    # service_state(controls). Applications has to ensure it can handle
    # all control signals in all states (ignoring them as desired)
    if {[catch {
        Twapi_SetServiceStatus $name $::twapi::service_state_values($current_state) $service_state($name,exitcode) $service_state($name,servicecode) $service_state($name,checkpoint) $waithint $service_state(controls)
    } msg]} {
        # TBD - report error - but how ? bgerror?
        catch {twapi::eventlog_log "Error setting service status: $msg"}
    }

    # If we had supplied a wait hint, we are telling the SCM, we will call
    # it back within that period of time, so schedule ourselves.
    if {$waithint} {
        set delay [expr {($waithint*3)/4}]
        after $delay ::twapi::_call_scm_within_waithint $name $current_state $service_state($name,checkpoint)
    }

    return
}


# Queued to regularly update the SCM when we are in any of the pending states
proc ::twapi::_call_scm_within_waithint {name orig_state orig_checkpoint} {
    variable service_state

    # We only call to update staus if the state and checkpoint have
    # not changed since the routine was queued
    if {($service_state($name,state) eq $orig_state) &&
        ($service_state($name,checkpoint) == $orig_checkpoint)} {
        _report_service_status $name
    }
}


################################################################
# Utility procedures

# Map an integer service type code into a list consisting of
# {SERVICETYPESYMBOL BOOLEAN}. If there is not symbolic service type
# for the service, just the integer code is returned. The BOOLEAN
# is 1/0 depending on whether the service type code is interactive
proc twapi::_map_servicetype_code {servicetype} {
    # 0x100 -> SERVICE_INTERACTIVE_PROCESS
    set interactive [expr {($servicetype & 0x100) != 0}]
    set servicetype [expr {$servicetype & (~ 0x100)}]
    set servicetype [kl_get [list \
                                 16 win32_own_process 32 win32_share_process 1 kernel_driver \
                                 2 file_system_driver 4 adapter 8 recognizer_driver \
                                 ] $servicetype $servicetype]
    return [list $servicetype $interactive]
}

# Map service type sym to int code
proc twapi::_map_servicetype_sym {sym} {
    return [dict get {kernel_driver 1 file_system_driver 2 adapter 4 recognizer_driver 8 win32_own_process 16 win32_share_process 32} $sym]
}

# Map a start type code into a symbol. Returns the integer code if
# no mapping possible
proc twapi::_map_starttype_code {code} {
    incr code 0;                # Make canonical int
    set type [lindex {boot_start system_start auto_start demand_start disabled} $code]
    if {$type eq ""} {
        return $code
    } else {
        return $type
    }
}

# Map starttype sym to int code
proc twapi::_map_starttype_sym {sym} {
    return [dict get {boot_start 0 system_start 1 auto_start 2 demand_start 3 disabled 4} $sym]
}

# Map a error control code into a symbol. Returns the integer code if
# no mapping possible
proc twapi::_map_errorcontrol_code {code} {
    incr code 0;                # Make canonical int
    set error [lindex {ignore normal severe critical} $code]
    if {$error eq ""} {
        return $code
    } else {
        return $error
    }
}

# Map error control sym to int code
proc twapi::_map_errorcontrol_sym {sym} {
    return [dict get {ignore 0 normal 1 severe 2 critical 3} $sym]
}

# Standard template for calling a service function. v_opts should refer
# to an array with the following elements:
# opts(system) - target system. Must be specified
# opts(database) - target database. Must be specified
# opts(scm_priv) - requested privilege when opening SCM. STANDARD_RIGHTS_READ
#   is used if unspecified. Not used if scm_handle is specified
# opts(scm_handle) - handle to service control manager. Optional
# opts(svc_priv) - requested privilege when opening service. Must be present
# opts(proc) - proc/function to call. The first arg is the service handle
# opts(args) - additional arguments to pass to the function.
#   Empty if unspecified
proc twapi::_service_fn_wrapper {name v_opts} {
    upvar $v_opts opts

    # Use 0x00020000 -> STANDARD_RIGHTS_READ for SCM if not specified
    set scm_priv [expr {[info exists opts(scm_priv)] ? $opts(scm_priv) : 0x00020000}]

    if {[info exists opts(scm_handle)] &&
        $opts(scm_handle) ne ""} {
        set scm $opts(scm_handle)
    } else {
        set scm [OpenSCManager $opts(system) $opts(database) $scm_priv]             }
    trap {
        set svch [OpenService $scm $name $opts(svc_priv)]
    } finally {
        # No need for scm handle anymore. Close it unless it was
        # passed to us
        if {(![info exists opts(scm_handle)]) ||
            ($opts(scm_handle) eq "")} {
            CloseServiceHandle $scm
        }
    }

    set proc_args [expr {[info exists opts(args)] ? $opts(args) : ""}]
    trap {
        set results [eval [list $opts(proc) $svch] $proc_args]
    } finally {
        CloseServiceHandle $svch
    }

    return $results
}

# Called back for reporting background errors. Note this is called
# from the C++ services code, not from scripts.
proc twapi::_service_background_error {winerror msg} {
    twapi::win32_error $winerror $msg
}

# Parse symbols for controls accepted by a service
proc twapi::_parse_service_accept_controls {controls} {
    return [_parse_symbolic_bitmask $controls {
        stop                    0x00000001
        pause_continue          0x00000002
        shutdown                0x00000004
        paramchange             0x00000008
        netbindchange           0x00000010
        hardwareprofilechange   0x00000020
        powerevent              0x00000040
        sessionchange           0x00000080
    }]
}
