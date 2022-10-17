#
# Copyright (c) 2003-2015, Ashok P. Nadkarni
# All rights reserved.
#
# See the file LICENSE for license

# TBD - allow access rights to be specified symbolically using procs
# from security.tcl
# TBD - add -user option to get_process_info and get_thread_info
# TBD - add wrapper for GetProcessExitCode

namespace eval twapi {}


# Create a process
proc twapi::create_process {path args} {
    array set opts [parseargs args {
        {debugchildtree.bool  0 0x1}
        {debugchild.bool      0 0x2}
        {createsuspended.bool 0 0x4}
        {detached.bool        0 0x8}
        {newconsole.bool      0 0x10}
        {newprocessgroup.bool 0 0x200}
        {separatevdm.bool     0 0x800}
        {sharedvdm.bool       0 0x1000}
        {inheriterrormode.bool 1 0x04000000}
        {noconsole.bool       0 0x08000000}
        {priority.arg normal {normal abovenormal belownormal high realtime idle}}

        {feedbackcursoron.bool  0 0x40}
        {feedbackcursoroff.bool 0 0x80}
        {fullscreen.bool        0 0x20}

        {cmdline.arg ""}
        {inheritablechildprocess.bool 0}
        {inheritablechildthread.bool 0}
        {childprocesssecd.arg ""}
        {childthreadsecd.arg ""}
        {inherithandles.bool 0}
        {env.arg ""}
        {startdir.arg ""}
        {desktop.arg __null__}
        {title.arg ""}
        windowpos.arg
        windowsize.arg
        screenbuffersize.arg
        background.arg
        foreground.arg
        {showwindow.arg ""}
        {stdhandles.arg ""}
        {stdchannels.arg ""}
        {returnhandles.bool 0}

        token.arg
    } -maxleftover 0]
                    
    set process_sec_attr [_make_secattr $opts(childprocesssecd) $opts(inheritablechildprocess)]
    set thread_sec_attr [_make_secattr $opts(childthreadsecd) $opts(inheritablechildthread)]

    # Check incompatible options
    if {$opts(newconsole) && $opts(detached)} {
        error "Options -newconsole and -detached cannot be specified together"
    }
    if {$opts(sharedvdm) && $opts(separatevdm)} {
        error "Options -sharedvdm and -separatevdm cannot be specified together"
    }

    # Create the start up info structure
    set si_flags 0
    if {[info exists opts(windowpos)]} {
        lassign [_parse_integer_pair $opts(windowpos)] xpos ypos
        setbits si_flags 0x4
    } else {
        set xpos 0
        set ypos 0
    }
    if {[info exists opts(windowsize)]} {
        lassign [_parse_integer_pair $opts(windowsize)] xsize ysize
        setbits si_flags 0x2
    } else {
        set xsize 0
        set ysize 0
    }
    if {[info exists opts(screenbuffersize)]} {
        lassign [_parse_integer_pair $opts(screenbuffersize)] xscreen yscreen
        setbits si_flags 0x8
    } else {
        set xscreen 0
        set yscreen 0
    }

    set fg 7;                           # Default to white
    set bg 0;                           # Default to black
    if {[info exists opts(foreground)]} {
        set fg [_map_console_color $opts(foreground) 0]
        setbits si_flags 0x10
    }
    if {[info exists opts(background)]} {
        set bg [_map_console_color $opts(background) 1]
        setbits si_flags 0x10
    }

    set si_flags [expr {$si_flags |
                        $opts(feedbackcursoron) | $opts(feedbackcursoroff) |
                        $opts(fullscreen)}]

    switch -exact -- $opts(showwindow) {
        ""        {set opts(showwindow) 1 }
        hidden    {set opts(showwindow) 0}
        normal    {set opts(showwindow) 1}
        minimized {set opts(showwindow) 2}
        maximized {set opts(showwindow) 3}
        default   {error "Invalid value '$opts(showwindow)' for -showwindow option"}
    }
    if {[string length $opts(showwindow)]} {
        setbits si_flags 0x1
    }

    if {[llength $opts(stdhandles)] && [llength $opts(stdchannels)]} {
        error "Options -stdhandles and -stdchannels cannot be used together"
    }

    if {[llength $opts(stdhandles)]} {
        if {! $opts(inherithandles)} {
            error "Cannot specify -stdhandles option if option -inherithandles is specified as 0"
        }

        setbits si_flags 0x100
    }

    # Figure out process creation flags
    # 0x400 -> CREATE_UNICODE_ENVIRONMENT
    set flags [expr {0x00000400 |
                     $opts(createsuspended) | $opts(debugchildtree) |
                     $opts(debugchild) | $opts(detached) | $opts(newconsole) |
                     $opts(newprocessgroup) | $opts(separatevdm) |
                     $opts(sharedvdm) | $opts(inheriterrormode) |
                     $opts(noconsole) }]

    switch -exact -- $opts(priority) {
        normal      {set priority 0x00000020}
        abovenormal {set priority 0x00008000}
        belownormal {set priority 0x00004000}
        ""          {set priority 0}
        high        {set priority 0x00000080}
        realtime    {set priority 0x00000100}
        idle        {set priority 0x00000040}
        default     {error "Unknown priority '$priority'"}
    }
    set flags [expr {$flags | $priority}]

    # Create the environment strings
    if {[llength $opts(env)]} {
        set child_env [list ]
        foreach {envvar envval} $opts(env) {
            lappend child_env "$envvar=$envval"
        }
    } else {
        set child_env "__null__"
    }

    trap {
        # This is inside the trap because duplicated handles have
        # to be closed.
        if {[llength $opts(stdchannels)]} {
            if {! $opts(inherithandles)} {
                error "Cannot specify -stdhandles option if option -inherithandles is specified as 0"
            }
            if {[llength $opts(stdchannels)] != 3} {
                error "Must specify 3 channels for -stdchannels option corresponding stdin, stdout and stderr"
            }

            setbits si_flags 0x100

            # Convert the channels to handles
            lappend opts(stdhandles) [duplicate_handle [get_tcl_channel_handle [lindex $opts(stdchannels) 0] read] -inherit]
            lappend opts(stdhandles) [duplicate_handle [get_tcl_channel_handle [lindex $opts(stdchannels) 1] write] -inherit]
            lappend opts(stdhandles) [duplicate_handle [get_tcl_channel_handle [lindex $opts(stdchannels) 2] write] -inherit]
        }

        set startup [list $opts(desktop) $opts(title) $xpos $ypos \
                         $xsize $ysize $xscreen $yscreen \
                         [expr {$fg|$bg}] $si_flags $opts(showwindow) \
                         $opts(stdhandles)]

        if {[info exists opts(token)]} {
            lassign [CreateProcessAsUser $opts(token) [file nativename $path] \
                         $opts(cmdline) \
                         $process_sec_attr $thread_sec_attr \
                         $opts(inherithandles) $flags $child_env \
                         [file normalize $opts(startdir)] $startup \
                        ]   ph   th   pid   tid

        } else {
            lassign [CreateProcess [file nativename $path] \
                         $opts(cmdline) \
                         $process_sec_attr $thread_sec_attr \
                         $opts(inherithandles) $flags $child_env \
                         [file normalize $opts(startdir)] $startup \
                        ]   ph   th   pid   tid
        }
    } finally {
        # If opts(stdchannels) is not an empty list, we duplicated the handles
        # into opts(stdhandles) ourselves so free them
        if {[llength $opts(stdchannels)]} {
            # Free corresponding handles in opts(stdhandles)
            close_handles $opts(stdhandles)
        }
    }

    # From the Tcl source code - (tclWinPipe.c)
    #     /*
    #      * "When an application spawns a process repeatedly, a new thread
    #      * instance will be created for each process but the previous
    #      * instances may not be cleaned up.  This results in a significant
    #      * virtual memory loss each time the process is spawned.  If there
    #      * is a WaitForInputIdle() call between CreateProcess() and
    #      * CloseHandle(), the problem does not occur." PSS ID Number: Q124121
    #      */
    # WaitForInputIdle $ph 5000 -- Apparently this is only needed for NT 3.5


    if {$opts(returnhandles)} {
        return [list $pid $tid $ph $th]
    } else {
        CloseHandle $th
        CloseHandle $ph
        return [list $pid $tid]
    }
}

# Wait until the process is ready
proc twapi::process_waiting_for_input {pid args} {
    array set opts [parseargs args {
        {wait.int 0}
    } -maxleftover 0]

    if {$pid == [pid]} {
        variable my_process_handle
        return [WaitForInputIdle $my_process_handle $opts(wait)]
    }

    set hpid [get_process_handle $pid]
    trap {
        return [WaitForInputIdle $hpid $opts(wait)]
    } finally {
        CloseHandle $hpid
    }
}



# Get a handle to a process
proc twapi::get_process_handle {pid args} {
    # OpenProcess masks off the bottom two bits thereby converting
    # an invalid pid to a real one.
    if {(![string is integer -strict $pid]) || ($pid & 3)} {
        win32_error 87 "Invalid PID '$pid'.";  # "The parameter is incorrect"
    }
    array set opts [parseargs args {
        {access.arg process_query_information}
        {inherit.bool 0}
    } -maxleftover 0]
    return [OpenProcess [_access_rights_to_mask $opts(access)] $opts(inherit) $pid]
}

# Return true if passed pid is system
proc twapi::is_system_pid {pid} {
    # Note Windows 2000 System PID was 8 but we no longer support it.
    return [expr {$pid == 4}]
}

# Return true if passed pid is of idle process
proc twapi::is_idle_pid {pid} {
    return [expr {$pid == 0}]
}

# Get my process id
proc twapi::get_current_process_id {} {
    return [::pid]
}

# Get my thread id
proc twapi::get_current_thread_id {} {
    return [GetCurrentThreadId]
}

# Get the exit code for a process. Returns "" if still running.
proc twapi::get_process_exit_code {hpid} {
    set code [GetExitCodeProcess $hpid]
    return [expr {$code == 259 ? "" : $code}]
}

# Return list of process ids
# Note if -path or -name is specified, then processes for which this
# information cannot be obtained are skipped
proc twapi::get_process_ids {args} {

    set save_args $args;                # Need to pass to process_exists
    array set opts [parseargs args {
        user.arg
        path.arg
        name.arg
        logonsession.arg
        glob} -maxleftover 0]

    if {[info exists opts(path)] && [info exists opts(name)]} {
        error "Options -path and -name are mutually exclusive"
    }

    if {$opts(glob)} {
        set match_op ~
    } else {
        set match_op eq
    }

    # If we do not care about user or path, Twapi_GetProcessList
    # is faster than EnumProcesses or the WTS functions
    if {[info exists opts(user)] == 0 &&
        [info exists opts(logonsession)] == 0 &&
        [info exists opts(path)] == 0} {
        if {[info exists opts(name)] == 0} {
            return [Twapi_GetProcessList -1 0]
        }
        # We need to match against the name
        return [recordarray column [Twapi_GetProcessList -1 2] -pid \
                    -filter [list [list "-name" $match_op $opts(name) -nocase]]]
    }

    # Only want pids with a specific user or path or logon session

    # If is the name we are looking for, try using the faster WTS
    # API's first. If they are not available, we try a slower method
    # If we need to match paths or logon sessions, we don't try this
    # at all as the wts api's don't provide that info
    if {[info exists opts(path)] == 0 &&
        [info exists opts(logonsession)] == 0} {
        if {![info exists opts(user)]} {
            # How did we get here? 
            error "Internal error - option -user not specified where expected"
        }
        if {[catch {map_account_to_sid $opts(user)} sid]} {
            # No such user. Return empty list (no processes)
            return [list ]
        }

        if {[info exists opts(name)]} {
            set filter_expr [list [list pUserSid eq $sid -nocase] [list pProcessName $match_op $opts(name) -nocase]]
        } else {
            set filter_expr [list [list pUserSid eq $sid -nocase]]
        }

        # Catch failures so we can try other means
        if {! [catch {recordarray column [WTSEnumerateProcesses NULL] \
                          ProcessId -filter $filter_expr} wtslist]} {
            return $wtslist
        }
    }

    set process_pids [list ]


    # Either we are matching on path/logonsession, or the WTS call failed
    # Try yet another way.

    # Note that in the code below, we use "file join" with a single arg
    # to convert \ to /. Do not use file normalize as that will also
    # land up converting relative paths to full paths
    if {[info exists opts(path)]} {
        set opts(path) [file join $opts(path)]
    }

    set process_pids [list ]
    if {[info exists opts(name)]} {
        # Note we may reach here if the WTS call above failed
        set all_pids [recordarray column [Twapi_GetProcessList -1 2] ProcessId -filter [list [list ProcessName $match_op $opts(name) -nocase]]]
    } else {
        set all_pids [Twapi_GetProcessList -1 0]
    }

    set filter_expr {}
    set popts [list ]
    if {[info exists opts(path)]} {
        lappend popts -path
        lappend filter_expr [list -path $match_op $opts(path) -nocase]
    } 

    if {[info exists opts(user)]} {
        lappend popts -user
        lappend filter_expr [list -user eq $opts(user) -nocase]
    } 
    if {[info exists opts(logonsession)]} {
        lappend popts -logonsession
        lappend filter_expr [list -logonsession eq $opts(logonsession) -nocase]
    } 


    set matches [recordarray get [get_multiple_process_info -matchpids $all_pids {*}$popts] -filter $filter_expr]
    return [recordarray column $matches -pid]
}


# Return list of modules handles for a process
proc twapi::get_process_modules {pid args} {
    variable my_process_handle

    array set opts [parseargs args {handle name path base size entry all}]

    if {$opts(all)} {
        foreach opt {handle name path base size entry} {
            set opts($opt) 1
        }
    }
    set noopts [expr {($opts(name) || $opts(path) || $opts(base) || $opts(size) || $opts(entry) || $opts(handle)) == 0}]

    if {! $noopts} {
        # Returning a record array
        set fields {}
        # ORDER MUST be same a value order below
        foreach opt {handle name path base size entry} {
            if {$opts($opt)} {
                lappend fields -$opt
            }
        }
        
    }

    if {$pid == [pid]} {
        set hpid $my_process_handle
    } else {
        set hpid [get_process_handle $pid -access {process_query_information process_vm_read}]
    }

    set results [list ]
    trap {
        foreach module [EnumProcessModules $hpid] {
            if {$noopts} {
                lappend results $module
                continue
            }
            set rec {}
            if {$opts(handle)} {
                lappend rec $module
            }
            if {$opts(name)} {
                if {[catch {GetModuleBaseName $hpid $module} name]} {
                    set name ""
                }
                lappend rec $name
            }
            if {$opts(path)} {
                if {[catch {GetModuleFileNameEx $hpid $module} path]} {
                    set path ""
                }
                lappend rec [_normalize_path $path]
            }
            if {$opts(base) || $opts(size) || $opts(entry)} {
                if {[catch {GetModuleInformation $hpid $module} imagedata]} {
                    set base ""
                    set size ""
                    set entry ""
                } else {
                    lassign $imagedata base size entry
                }
                foreach opt {base size entry} {
                    if {$opts($opt)} {
                        lappend rec [set $opt]
                    }
                }
            }
            lappend results $rec
        }
    } finally {
        if {$hpid != $my_process_handle} {
            CloseHandle $hpid
        }
    }

    if {$noopts} {
        return $results
    } else {
        return [list $fields $results]
    }
}


# Kill a process
# Returns 1 if process was ended, 0 if not ended within timeout
proc twapi::end_process {pid args} {

    if {$pid == [pid]} {
        error "The passed PID is the PID of the current process. end_process cannot be used to commit suicide."
    }

    array set opts [parseargs args {
        {exitcode.int 1}
        force
        {wait.int 0}
    }]

    # In order to verify the process is really gone, we open the process
    # if possible and then wait on its handle. If access restrictions prevent
    # us from doing so, we ignore the issue and will simply check for the
    # the PID later (which is not a sure check since PID's can be reused
    # immediately)
    catch {set hproc [get_process_handle $pid -access synchronize]}

    # First try to close nicely. We need to send messages to toplevels
    # as well as message-only windows. We could make use of get_toplevel_windows
    # and find_windows but those would require pulling in the whole 
    # twapi_ui package so do it ourselves.
    set toplevels {}
    foreach toplevel [EnumWindows] {
        # Check if it belongs to pid. Errors are ignored, we simply
        # will not send a message to that window
        catch {
            if {[lindex [GetWindowThreadProcessId $toplevel] 1] == $pid} {
                lappend toplevels $toplevel
            }
        }
    }
    # Repeat for message only windows as EnumWindows skips them
    set prev 0
    while {1} {
        # Again, errors are ignored
        # -3 -> HWND_MESSAGE windows
        if {[catch {
            set toplevel [FindWindowEx [list -3 HWND] $prev "" ""]
        }]} {
            break
        }
        if {[pointer_null? $toplevel]} break
        catch {
            if {[lindex [GetWindowThreadProcessId $toplevel] 1] == $pid} {
                lappend toplevels $toplevel
            }
        }
        set prev $toplevel
    }
    
    if {[llength $toplevels]} {
        # Try and close by sending them a message. WM_CLOSE is 0x10
        foreach toplevel $toplevels {
            # Send a message but come back right away
            # See Bug #139 as to why PostMessage instead of SendNotifyMessage
            catch {PostMessage $toplevel 0x10 0 0}
        }

        # Wait for the specified time to verify process has gone away
        if {[info exists hproc]} {
            set status [WaitForSingleObject $hproc $opts(wait)]
            CloseHandle $hproc
            set gone [expr {! $status}]
        } else {
            # We could not get a process handle to wait on, just check if
            # PID still exists. This COULD be a false positive...
            set gone [twapi::wait {process_exists $pid} 0 $opts(wait)]
        }
        if {$gone || ! $opts(force)} {
            # Succeeded or do not want to force a kill
            return $gone
        }

        # Only wait 10 ms since we have already waited above
        if {$opts(wait)} {
            set opts(wait) 10
        }
    }

    # Open the process for terminate access. IF access denied (5), retry after
    # getting the required privilege
    trap {
        set hproc [get_process_handle $pid -access {synchronize process_terminate}]
    } onerror {TWAPI_WIN32 5} {
        # Retry - if still fail, then just throw the error
        eval_with_privileges {
            set hproc [get_process_handle $pid -access {synchronize process_terminate}]
        } SeDebugPrivilege
    } onerror {TWAPI_WIN32 87} {
        # Process does not exist, we must have succeeded above but just
        # took a bit longer for it to exit
        return 1
    }

    trap {
        TerminateProcess $hproc $opts(exitcode)
        set status [WaitForSingleObject $hproc $opts(wait)]
        if {$status == 0} {
            return 1
        }
    } finally {
        CloseHandle $hproc
    }

    return 0
}

# Get the path of a process
proc twapi::get_process_path {pid args} {
    return [twapi::_get_process_name_path_helper $pid path {*}$args]
}

# Get the path of a process
proc twapi::get_process_name {pid args} {
    return [twapi::_get_process_name_path_helper $pid name {*}$args]
}


# Return list of device drivers
proc twapi::get_device_drivers {args} {
    array set opts [parseargs args {name path base all}]

    set fields {}
    # Order MUST be same as order of values below
    foreach opt {base name path} {
        if {$opts($opt) || $opts(all)} {
            lappend fields -$opt
        }
    }

    set results [list ]
    foreach module [EnumDeviceDrivers] {
        unset -nocomplain rec
        if {$opts(base) || $opts(all)} {
            lappend rec $module
        }
        if {$opts(name) || $opts(all)} {
            if {[catch {GetDeviceDriverBaseName $module} name]} {
                    set name ""
            }
            lappend rec $name
        }
        if {$opts(path) || $opts(all)} {
            if {[catch {GetDeviceDriverFileName $module} path]} {
                set path ""
            }
            lappend rec [_normalize_path $path]
        }
        if {[info exists rec]} {
            lappend results $rec
        }
    }

    return [list $fields $results]
}

# Check if the given process exists
# 0 - does not exist or exists but paths/names do not match,
# 1 - exists and matches path (or no -path or -name specified)
# -1 - exists but do not know path and cannot compare
proc twapi::process_exists {pid args} {
    array set opts [parseargs args { path.arg name.arg glob}]

    # Simplest case - don't care about name or path
    if {! ([info exists opts(path)] || [info exists opts(name)])} {
        if {$pid == [pid]} {
            return 1
        }
        # TBD - would it be faster to do OpenProcess ? If success or 
        # access denied, process exists.

        if {[llength [Twapi_GetProcessList $pid 0]] == 0} {
            return 0
        } else {
            return 1
        }
    }

    # Can't specify both name and path
    if {[info exists opts(path)] && [info exists opts(name)]} {
        error "Options -path and -name are mutually exclusive"
    }

    if {$opts(glob)} {
        set string_cmd match
    } else {
        set string_cmd equal
    }
    
    if {[info exists opts(name)]} {
        # Name is specified
        set pidlist [Twapi_GetProcessList $pid 2]
        if {[llength $pidlist] == 0} {
            return 0
        }
        return [string $string_cmd -nocase $opts(name) [lindex $pidlist 1 0 1]]
    }

    # Need to match on the path
    set process_path [get_process_path $pid -noexist "" -noaccess "(unknown)"]
    if {[string length $process_path] == 0} {
        # No such process
        return 0
    }

    # Process with this pid exists
    # Path still has to match
    if {[string equal $process_path "(unknown)"]} {
        # Exists but cannot check path/name
        return -1
    }

    # Note we do not use file normalize here since that will tack on
    # absolute paths which we do not want for glob matching

    # We use [file join ] to convert \ to / to avoid special
    # interpretation of \ in string match command
    return [string $string_cmd -nocase [file join $opts(path)] [file join $process_path]]
}

# Get the parent process of a thread. Return "" if no such thread
proc twapi::get_thread_parent_process_id {tid} {
    set status [catch {
        set th [get_thread_handle $tid]
        trap {
            set pid [lindex [lindex [Twapi_NtQueryInformationThreadBasicInformation $th] 2] 0]
        } finally {
            CloseHandle $th
        }
    }]

    if {$status == 0} {
        return $pid
    }


    # Could not use undocumented function. Try slooooow perf counter method
    set pid_paths [get_perf_thread_counter_paths $tid -pid]
    if {[llength $pid_paths] == 0} {
        return ""
    }

    if {[pdh_counter_path_value [lindex [lindex $pid_paths 0] 3] -var pid]} {
        return $pid
    } else {
        return ""
    }
}

# Get the thread ids belonging to a process
proc twapi::get_process_thread_ids {pid} {
    return [recordarray cell [get_multiple_process_info -matchpids [list $pid] -tids] 0 -tids]
}


# Get process information
proc twapi::get_process_info {pid args} {
    # To avert a common mistake where pid is unspecified, use current pid
    # so [get_process_info -name] becomes [get_process_info [pid] -name]
    # TBD - should this be documented ?

    if {![string is integer -strict $pid]} {
        set args [linsert $args 0 $pid]
        set pid [pid]
    }

    set rec [recordarray index [get_multiple_process_info {*}$args -matchpids [list $pid]] 0 -format dict]
    if {"-pid" ni $args && "-all" ni $args} {
        dict unset rec -pid
    }
    return $rec
}


# Get multiple process information
# TBD - document and write tests
proc twapi::get_multiple_process_info {args} {

    # Options that are directly available from Twapi_GetProcessList
    # Dict value is the flags to pass to Twapi_GetProcessList
    set base_opts {
        basepriority       1
        parent             1        tssession          1
        name               2
        createtime         4        usertime           4
        privilegedtime     4        handlecount        4
        threadcount        4
        pagefaults         8        pagefilebytes      8
        pagefilebytespeak  8        poolnonpagedbytes  8
        poolnonpagedbytespeak  8    poolpagedbytes     8
        poolpagedbytespeak 8        virtualbytes       8
        virtualbytespeak   8        workingset         8
        workingsetpeak     8
        ioreadops         16        iowriteops        16
        iootherops        16        ioreadbytes       16
        iowritebytes      16        iootherbytes      16
    }
    # Options that also dependent on Twapi_GetProcessList but not
    # directly available
    set base_calc_opts { elapsedtime 4   tids 32 }

    # Note -user is also a potential token opt but not listed below
    # because it can be gotten by other means
    set token_opts {
        disabledprivileges elevation enabledprivileges groupattrs groups
        integrity integritylabel logonsession  primarygroup primarygroupsid
        privileges restrictedgroupattrs restrictedgroups virtualized
    }

    set optdefs [lconcat {all pid user path commandline priorityclass {noexist.arg {(no such process)}} {noaccess.arg {(unknown)}} matchpids.arg} \
                     [dict keys $base_opts] \
                     [dict keys $base_calc_opts] \
                     $token_opts]
    array set opts [parseargs args $optdefs -maxleftover 0]
    set opts(pid) 1; # Always return pid, -pid option is for backward compat

    if {[info exists opts(matchpids)]} {
        set pids $opts(matchpids)
    } else {
        set pids [Twapi_GetProcessList -1 0]
    }

    set now [get_system_time]

    # We will return a record array. $records tracks a dict of record
    # values keyed by pid, $fields tracks the names in the list elements
    # [llength $fields] == [llength [lindex $records *]]
    set records {}
    set fields {}

    # If user is requested, try getting it through terminal services
    # if possible since the token method fails on some newer platforms
    if {$opts(all) || $opts(user)} {
        _get_wts_pids wtssids wtsnames
    }

    # See if any Twapi_GetProcessList options are requested and if
    # so, calculate the appropriate flags
    set baseflags 0
    set basenoexistvals {}
    dict for {opt flag} $base_opts {
        if {$opts($opt) || $opts(all)} {
            set baseflags [expr {$baseflags | $flag}]
            lappend basefields -$opt
            lappend basenoexistvals $opts(noexist)
        }
    }
    dict for {opt flag} $base_calc_opts {
        if {$opts($opt) || $opts(all)} {
            set baseflags [expr {$baseflags | $flag}]
        }
    }

    # See if we need to retrieve any base options
    if {$baseflags} {
        set pidarg [expr {[llength $pids] == 1 ? [lindex $pids 0] : -1}]
        set data [twapi::Twapi_GetProcessList $pidarg [expr {$baseflags|1}]]
        if {$opts(all) || $opts(elapsedtime) || $opts(tids)} {
            array set baserawdata [recordarray getdict $data -key "-pid" -format dict]
        }
        if {[info exists basefields]} {
            set fields $basefields
            set records [recordarray getdict $data -slice $basefields -key "-pid"]
        }
    }
    if {$opts(pid)} {
        lappend fields -pid
    }
    foreach pid $pids {
        # If base values were requested, but this pid does not exist
        # use the "noexist" values
        if {![dict exists $records $pid]} {
            dict set records $pid $basenoexistvals
        }
        if {$opts(pid)} {
            dict lappend records $pid $pid
        }
    }

    # If all we need are baseline options, and no massaging is required
    # (as for elapsedtime, for example), we can return what we have
    # without looping through below. Saves significant time.
    set done 1
    foreach opt [list all user elapsedtime tids path commandline priorityclass \
                     {*}$token_opts] {
        if {$opts($opt)} {
            set done 0
            break
        }
    }

    if {$done} {
        set return_data {}
        foreach pid $pids {
            lappend return_data [dict get $records $pid]
        }
        return [list $fields $return_data]
    }

    set requested_token_opts {}
    foreach opt $token_opts {
        if {$opts(all) || $opts($opt)} {
            lappend requested_token_opts -$opt
        }
    }

    if {$opts(elapsedtime) || $opts(all)} {
        lappend fields -elapsedtime
        foreach pid $pids {
            if {[info exists baserawdata($pid)]} {
                set elapsed [twapi::kl_get $baserawdata($pid) -createtime]
                if {$elapsed} {
                    # 100ns -> seconds
                    dict lappend records $pid [expr {($now-$elapsed)/10000000}]
                } else {
                    # For some processes like, System and Idle, kernel
                    # returns start time of 0. Just use system uptime
                    if {![info exists system_uptime]} {
                        # Store locally so no refetch on each iteration
                        set system_uptime [get_system_uptime]
                    }
                    dict lappend records $pid $system_uptime
                }
            } else {
                dict lappend records $pid $opts(noexist)
            }
        }
    }

    if {$opts(tids) || $opts(all)} {
        lappend fields -tids
        foreach pid $pids {
            if {[info exists baserawdata($pid)]} {
                dict lappend records $pid [recordarray column [kl_get $baserawdata($pid) Threads] -tid]
            } else {
                dict lappend records $pid $opts(noexist)
            }
        }
    }

    if {$opts(all) || $opts(path)} {
        lappend fields -path
        foreach pid $pids {
            dict lappend records $pid [get_process_path $pid -noexist $opts(noexist) -noaccess $opts(noaccess)]
        }
    }

    if {$opts(all) || $opts(priorityclass)} {
        lappend fields -priorityclass
        foreach pid $pids {
            trap {
                set prioclass [get_priority_class $pid]
            } onerror {TWAPI_WIN32 5} {
                set prioclass $opts(noaccess)
            } onerror {TWAPI_WIN32 87} {
                set prioclass $opts(noexist)
            }
            dict lappend records $pid $prioclass
        }
    }

    if {$opts(all) || $opts(commandline)} {
        lappend fields -commandline
        foreach pid $pids {
            dict lappend records $pid [get_process_commandline $pid -noexist $opts(noexist) -noaccess $opts(noaccess)]
        }
    }


    if {$opts(all) || $opts(user) || [llength $requested_token_opts]} {
        foreach pid $pids {
            # Now get token related info, if any requested
            # For returning as a record array, we have to be careful that
            # each field is added in a specific order for every pid
            # keeping in mind a different method might be used for different
            # pids. So we collect the data in dictionary token_records and add 
            # at the end in a fixed order
            set token_records {}
            set requested_opts $requested_token_opts
            unset -nocomplain user
            if {$opts(all) || $opts(user)} {
                # See if we already have the user. Note sid of system idle
                # will be empty string
                if {[info exists wtssids($pid)]} {
                    if {$wtssids($pid) == ""} {
                        # Put user as System
                        set user SYSTEM
                    } else {
                        # We speed up account lookup by caching sids
                        if {[info exists sidcache($wtssids($pid))]} {
                            set user $sidcache($wtssids($pid))
                        } else {
                            set user [lookup_account_sid $wtssids($pid)]
                            set sidcache($wtssids($pid)) $user
                        }
                    }
                } else {
                    lappend requested_opts -user
                }
            }

            if {[llength $requested_opts]} {
                trap {
                    dict set token_records $pid [_token_info_helper -pid $pid {*}$requested_opts]
                } onerror {TWAPI_WIN32 5} {
                    foreach opt $requested_opts {
                        dict set token_records $pid $opt $opts(noaccess)
                    }
                    # The NETWORK SERVICE and LOCAL SERVICE processes cannot
                    # be accessed. If we are looking for the logon session for
                    # these, try getting it from the witssid if we have it
                    # since the logon session is hardcoded for these accounts
                    if {"-logonsession" in  $requested_opts} {
                        if {![info exists wtssids]} {
                            _get_wts_pids wtssids wtsnames
                        }
                        if {[info exists wtssids($pid)]} {
                            # Map user SID to logon session
                            switch -exact -- $wtssids($pid) {
                                S-1-5-18 {
                                    # SYSTEM
                                    dict set token_records $pid -logonsession 00000000-000003e7
                                }
                                S-1-5-19 {
                                    # LOCAL SERVICE
                                    dict set token_records $pid -logonsession 00000000-000003e5
                                }
                                S-1-5-20 {
                                    # LOCAL SERVICE
                                    dict set token_records $pid -logonsession 00000000-000003e4
                                }
                            }
                        }
                    }
                    
                    # Similarly, if we are looking for user account, special case
                    # system and system idle processes
                    if {"-user" in  $requested_opts} {
                        if {[is_idle_pid $pid] || [is_system_pid $pid]} {
                            set user SYSTEM
                        }
                    }
                    
                } onerror {TWAPI_WIN32 87} {
                    foreach opt $requested_opts {
                        if {$opt eq "-user"} {
                            if {[is_idle_pid $pid] || [is_system_pid $pid]} {
                                set user SYSTEM
                            } else {
                                set user $opts(noexist)
                            }
                        } else {
                            dict set token_records $pid $opt $opts(noexist)
                        }
                    }
                }
            }
            # Now add token values in a specific order - MUST MATCH fields BELOW
            if {$opts(all) || $opts(user)} {
                dict lappend records $pid $user
            }
            foreach opt $requested_token_opts {
                if {[dict exists $token_records $pid $opt]} {
                    dict lappend records $pid [dict get $token_records $pid $opt]
                }
            }
        }
        # Now add token field names in a specific order - MUST MATCH ABOVE
        if {$opts(all) || $opts(user)} {
            lappend fields -user
        }
        foreach opt $requested_token_opts {
            if {[dict exists $token_records $pid $opt]} {
                lappend fields $opt
            }
        }
    }

    set return_data {}
    foreach pid $pids {
        lappend return_data [dict get $records $pid]
    }
    return [list $fields $return_data]
}



# Get thread information
# TBD - add info from GetGUIThreadInfo
proc twapi::get_thread_info {tid args} {
    # TBD - modify so tid is optional like for get_process_info

    # Options that are directly available from Twapi_GetProcessList
    if {![info exists ::twapi::get_thread_info_base_opts]} {
        # Array value is the flags to pass to Twapi_GetProcessList
        array set ::twapi::get_thread_info_base_opts {
            pid 32
            elapsedtime 96
            waittime 96
            usertime 96
            createtime 96
            privilegedtime 96
            contextswitches 96
            basepriority 160
            priority 160
            startaddress 160
            state 160
            waitreason 160
        }
    }

    set token_opts {
        user
        primarygroup
        primarygroupsid
        groups
        restrictedgroups
        groupattrs
        restrictedgroupattrs
        privileges
        enabledprivileges
        disabledprivileges
    }

    array set opts [parseargs args \
                        [concat [list all \
                                     relativepriority \
                                     tid \
                                     [list noexist.arg "(no such thread)"] \
                                     [list noaccess.arg "(unknown)"]] \
                             [array names ::twapi::get_thread_info_base_opts] \
                             $token_opts ]]

    set requested_opts [_array_non_zero_switches opts $token_opts $opts(all)]
    # Now get token info, if any
    if {[llength $requested_opts]} {
        trap {
            trap {
                set results [_token_info_helper -tid $tid {*}$requested_opts]
            } onerror {TWAPI_WIN32 1008} {
                # Thread does not have its own token. Use it's parent process
                set results [_token_info_helper -pid [get_thread_parent_process_id $tid] {*}$requested_opts]
            }
        } onerror {TWAPI_WIN32 5} {
            # No access
            foreach opt $requested_opts {
                lappend results $opt $opts(noaccess)
            }
        } onerror {TWAPI_WIN32 87} {
            # Thread does not exist
            foreach opt $requested_opts {
                lappend results $opt $opts(noexist)
            }
        }

    } else {
        set results [list ]
    }

    # Now get the base options
    set flags 0
    foreach opt [array names ::twapi::get_thread_info_base_opts] {
        if {$opts($opt) || $opts(all)} {
            set flags [expr {$flags | $::twapi::get_thread_info_base_opts($opt)}]
        }
    }

    if {$flags} {
        # We need at least one of the base options
        foreach tdata [recordarray column [twapi::Twapi_GetProcessList -1 $flags] Threads] {
            set tdict [recordarray getdict $tdata -key "-tid" -format dict]
            if {[dict exists $tdict $tid]} {
                array set threadinfo [dict get $tdict $tid]
                break
            }
        }
        # It is possible that we looped through all the processes without
        # a thread match. Hence we check again that we have threadinfo for
        # each option value
        foreach opt {
            pid            
            waittime
            usertime
            createtime
            privilegedtime
            basepriority
            priority
            startaddress
            state
            waitreason
            contextswitches
        } {
            if {$opts($opt) || $opts(all)} {
                if {[info exists threadinfo]} {
                    lappend results -$opt $threadinfo(-$opt)
                } else {
                    lappend results -$opt $opts(noexist)
                }
            }
        }

        if {$opts(elapsedtime) || $opts(all)} {
            if {[info exists threadinfo(-createtime)]} {
                lappend results -elapsedtime [expr {[clock seconds]-[large_system_time_to_secs $threadinfo(-createtime)]}]
            } else {
                lappend results -elapsedtime $opts(noexist)
            }
        }
    }


    if {$opts(all) || $opts(relativepriority)} {
        trap {
            lappend results -relativepriority [get_thread_relative_priority $tid]
        } onerror {TWAPI_WIN32 5} {
            lappend results -relativepriority $opts(noaccess)
        } onerror {TWAPI_WIN32 87} {
            lappend results -relativepriority $opts(noexist)
        }
    }

    if {$opts(all) || $opts(tid)} {
        lappend results -tid $tid
    }

    return $results
}

# Get a handle to a thread
proc twapi::get_thread_handle {tid args} {
    # OpenThread masks off the bottom two bits thereby converting
    # an invalid tid to a real one. We do not want this.
    if {$tid & 3} {
        win32_error 87;         # "The parameter is incorrect"
    }

    array set opts [parseargs args {
        {access.arg thread_query_information}
        {inherit.bool 0}
    }]
    return [OpenThread [_access_rights_to_mask $opts(access)] $opts(inherit) $tid]
}

# Suspend a thread
proc twapi::suspend_thread {tid} {
    set htid [get_thread_handle $tid -access thread_suspend_resume]
    trap {
        set status [SuspendThread $htid]
    } finally {
        CloseHandle $htid
    }
    return $status
}

# Resume a thread
proc twapi::resume_thread {tid} {
    set htid [get_thread_handle $tid -access thread_suspend_resume]
    trap {
        set status [ResumeThread $htid]
    } finally {
        CloseHandle $htid
    }
    return $status
}

# Get the command line for a process
proc twapi::get_process_commandline {pid args} {

    if {[is_system_pid $pid] || [is_idle_pid $pid]} {
        return ""
    }

    array set opts [parseargs args {
        {noexist.arg "(no such process)"}
        {noaccess.arg "(unknown)"}
    }]

    trap {
        # Assume max command line len is 1024 chars (2048 bytes)
        trap {
            set hpid [get_process_handle $pid -access {process_query_information process_vm_read}]
        } onerror {TWAPI_WIN32 87} {
            # Process does not exist
            return $opts(noexist)
        }

        # Get the address where the PEB is stored - see Nebbett
        set peb_addr [lindex [Twapi_NtQueryInformationProcessBasicInformation $hpid] 1]

        # Read the PEB as binary
        # The pointer to the process parameter block is the 5th pointer field.
        # The struct looks like:
        # 32 bit -
        # typedef struct _PEB {
        # BYTE                          Reserved1[2];
        # BYTE                          BeingDebugged;
        # BYTE                          Reserved2[1];
        # PVOID                         Reserved3[2];
        # PPEB_LDR_DATA                 Ldr;
        # PRTL_USER_PROCESS_PARAMETERS  ProcessParameters;
        # BYTE                          Reserved4[104];
        # PVOID                         Reserved5[52];
        # PPS_POST_PROCESS_INIT_ROUTINE PostProcessInitRoutine;
        # BYTE                          Reserved6[128];
        # PVOID                         Reserved7[1];
        # ULONG                         SessionId;
        # } PEB, *PPEB;
        # 64 bit -
        # typedef struct _PEB {
        #   BYTE Reserved1[2];
        #   BYTE BeingDebugged;
        #   BYTE Reserved2[21];
        #   PPEB_LDR_DATA LoaderData;
        #   PRTL_USER_PROCESS_PARAMETERS ProcessParameters;
        #   BYTE Reserved3[520];
        #   PPS_POST_PROCESS_INIT_ROUTINE PostProcessInitRoutine;
        #   BYTE Reserved4[136];
        #   ULONG SessionId;
        # } PEB;
        # So in both cases the pointer is 4 pointers from the start

        if {[info exists ::tcl_platform(pointerSize)]} {
            set pointer_size $::tcl_platform(pointerSize)
        } else {
            set pointer_size 4
        }
        if {$pointer_size == 4} {
            set pointer_scanner n
        } else {
            set pointer_scanner m
        }
        set mem [ReadProcessMemory $hpid [expr {$peb_addr+(4*$pointer_size)}] $pointer_size]
        if {![binary scan $mem $pointer_scanner proc_param_addr]} {
            error "Could not read PEB of process $pid"
        }

        # Now proc_param_addr contains the address of the Process parameter
        # structure which looks like:
        # typedef struct _RTL_USER_PROCESS_PARAMETERS {
        #                      Offsets:     x86  x64
        #    BYTE           Reserved1[16];   0    0
        #    PVOID          Reserved2[10];  16   16
        #    UNICODE_STRING ImagePathName;  56   96
        #    UNICODE_STRING CommandLine;    64  112
        # } RTL_USER_PROCESS_PARAMETERS, *PRTL_USER_PROCESS_PARAMETERS;
        # UNICODE_STRING is defined as
        # typedef struct _UNICODE_STRING {
        #  USHORT Length;
        #  USHORT MaximumLength;
        #  PWSTR  Buffer;
        # } UNICODE_STRING;

        # Note - among twapi supported builds, tcl_platform(pointerSize)
        # not existing implies 32-bits
        if {[info exists ::tcl_platform(pointerSize)] &&
            $::tcl_platform(pointerSize) == 8} {
            # Read the CommandLine field
            set mem [ReadProcessMemory $hpid [expr {$proc_param_addr + 112}] 16]
            if {![binary scan $mem tutunum cmdline_bytelen cmdline_bufsize unused cmdline_addr]} {
                error "Could not get address of command line"
            }
        } else {
            # Read the CommandLine field
            set mem [ReadProcessMemory $hpid [expr {$proc_param_addr + 64}] 8]
            if {![binary scan $mem tutunu cmdline_bytelen cmdline_bufsize cmdline_addr]} {
                error "Could not get address of command line"
            }
        }

        if {1} {
            if {$cmdline_bytelen == 0} {
                set cmdline ""
            } else {
                trap {
                    set mem [ReadProcessMemory $hpid $cmdline_addr $cmdline_bytelen]
                } onerror {TWAPI_WIN32 299} {
                    # ERROR_PARTIAL_COPY
                    # Rumour has it this can be a transient error if the
                    # process is initializing, so try once more
                    Sleep 0;    # Relinquish control to OS to run other process
                    # Retry
                    set mem [ReadProcessMemory $hpid $cmdline_addr $cmdline_bytelen]
                }
            }
        } else {
            THIS CODE NEEDS TO BE MODIFIED IF REINSTATED. THE ReadProcessMemory
            parameters have changed
            # Old pre-2.3 code
            # Now read the command line itself. We do not know the length
            # so assume MAX_PATH (1024) chars (2048 bytes). However, this may
            # fail if the memory beyond the command line is not allocated in the
            # target process. So we have to check for this error and retry with
            # smaller read sizes
            set max_len 2048
            while {$max_len > 128} {
                trap {
                    ReadProcessMemory $hpid $cmdline_addr $pgbl $max_len
                    break
                } onerror {TWAPI_WIN32 299} {
                    # Reduce read size
                    set max_len [expr {$max_len / 2}]
                }
            }
            # OK, got something. It's in Unicode format, may not be null terminated
            # or may have multiple null terminated strings. THe command line
            # is the first string.
        }
        set cmdline [encoding convertfrom unicode $mem]
        set null_offset [string first "\0" $cmdline]
        if {$null_offset >= 0} {
            set cmdline [string range $cmdline 0 [expr {$null_offset-1}]]
        }

    } onerror {TWAPI_WIN32 5} {
        # Access denied
        set cmdline $opts(noaccess)
    } onerror {TWAPI_WIN32 299} {
        # Only part of the Read* could be completed
        # Access denied
        set cmdline $opts(noaccess)
    } onerror {TWAPI_WIN32 87} {
        # The parameter is incorrect
        # Access denied (or should it be noexist?)
        set cmdline $opts(noaccess)
    } finally {
        if {[info exists hpid]} {
            CloseHandle $hpid
        }
    }

    return $cmdline
}


# Get process parent - can return ""
proc twapi::get_process_parent {pid args} {
    array set opts [parseargs args {
        {noexist.arg "(no such process)"}
        {noaccess.arg "(unknown)"}
    }]

    if {[is_system_pid $pid] || [is_idle_pid $pid]} {
        return ""
    }

    trap {
        set parent [recordarray cell [twapi::Twapi_GetProcessList $pid 1] 0 InheritedFromProcessId]
        if {$parent ne ""} {
            return $parent
        }
    } onerror {} {
        # Just try the other methods below
    }

    trap {
        set hpid [get_process_handle $pid]
        return [lindex [Twapi_NtQueryInformationProcessBasicInformation $hpid] 5]

    } onerror {TWAPI_WIN32 5} {
        set error noaccess
    } onerror {TWAPI_WIN32 87} {
        set error noexist
    } finally {
        if {[info exists hpid]} {
            CloseHandle $hpid
        }
    }

    return $opts($error)
}

# Get the base priority class of a process
proc twapi::get_priority_class {pid} {
    set ph [get_process_handle $pid]
    trap {
        return [GetPriorityClass $ph]
    } finally {
        CloseHandle $ph
    }
}

# Get the base priority class of a process
proc twapi::set_priority_class {pid priority} {
    if {$pid == [pid]} {
        variable my_process_handle
        SetPriorityClass $my_process_handle $priority
        return
    }

    set ph [get_process_handle $pid -access process_set_information]
    trap {
        SetPriorityClass $ph $priority
    } finally {
        CloseHandle $ph
    }
}

# Get the priority of a thread
proc twapi::get_thread_relative_priority {tid} {
    set h [get_thread_handle $tid]
    trap {
        return [GetThreadPriority $h]
    } finally {
        CloseHandle $h
    }
}

# Set the priority of a thread
proc twapi::set_thread_relative_priority {tid priority} {
    switch -exact -- $priority {
        abovenormal { set priority 1 }
        belownormal { set priority -1 }
        highest     { set priority 2 }
        idle        { set priority -15 }
        lowest      { set priority -2 }
        normal      { set priority 0 }
        timecritical { set priority 15 }
        default {
            if {![string is integer -strict $priority]} {
                error "Invalid priority value '$priority'."
            }
        }
    }

    set h [get_thread_handle $tid -access thread_set_information]
    trap {
        SetThreadPriority $h $priority
    } finally {
        CloseHandle $h
    }
}

# Return type of process elevation
proc twapi::get_process_elevation {args} {
    lappend args -elevation
    return [lindex [_token_info_helper $args] 1]
}

# Return integrity level of process
proc twapi::get_process_integrity {args} {
    lappend args -integrity
    return [lindex [_token_info_helper $args] 1]
}

# Return whether a process is running under WoW64
proc twapi::wow64_process {args} {
    array set opts [parseargs args {
        pid.arg
        hprocess.arg
    } -maxleftover 0]

    if {[info exists opts(hprocess)]} {
        if {[info exists opts(pid)]} {
            error "Options -pid and -hprocess cannot be used together."
        }
        return [IsWow64Process $opts(hprocess)]
    }

    if {[info exists opts(pid)] && $opts(pid) != [pid]} {
        trap {
            set hprocess [get_process_handle $opts(pid)]
            return [IsWow64Process $hprocess]
        } finally {
            if {[info exists hprocess]} {
                CloseHandle $hprocess
            }
        }
    }

    # Common case - checking about ourselves
    variable my_process_handle
    return [IsWow64Process $my_process_handle]
}

# Check whether a process is virtualized
proc twapi::virtualized_process {args} {
    lappend args -virtualized
    return [lindex [_token_info_helper $args] 1]
}

proc twapi::set_process_integrity {level args} {
    lappend args -integrity $level
    _token_set_helper $args
}

proc twapi::set_process_virtualization {enable args} {
    lappend args -virtualized $enable
    _token_set_helper $args
}

# Map a process handle to its pid
proc twapi::get_pid_from_handle {hprocess} {
    return [lindex [Twapi_NtQueryInformationProcessBasicInformation $hprocess] 4]
}

# Check if current process is an administrative process or not
proc twapi::process_in_administrators {} {

    # Administrators group SID - S-1-5-32-544

    if {[get_process_elevation] ne "limited"} {
        return [CheckTokenMembership NULL S-1-5-32-544]
    }

    # When running as with a limited token under UAC, we cannot check
    # if the process is in administrators group or not since the group
    # will be disabled in the token. Rather, we need to get the linked
    # token (which is unfiltered) and check that.
    set tok [lindex [_token_info_helper -linkedtoken] 1]
    trap {
        return [CheckTokenMembership $tok S-1-5-32-544]
    } finally {
        close_token $tok
    }
}

# Get a module handle
# TBD - document
proc twapi::get_module_handle {args} {
    array set opts [parseargs args {
        path.arg
        pin.bool
    } -nulldefault -maxleftover 0]

    return [GetModuleHandleEx $opts(pin) [file nativename $opts(path)]]
}

# Get a module handle from an address
# TBD - document
proc twapi::get_module_handle_from_address {addr args} {
    array set opts [parseargs args {
        pin.bool
    } -nulldefault -maxleftover 0]

    return [GetModuleHandleEx [expr {$opts(pin) ? 5 : 4}] $addr]
}


proc twapi::load_user_profile {token args} {
    # PI_NOUI -> 0x1
    parseargs args {
        username.arg
        {noui.bool 0 0x1}
        defaultuserpath.arg
        servername.arg
        roamingprofilepath.arg
    } -maxleftover 0 -setvars -nulldefault

    if {$username eq ""} {
        set username [get_token_user $token -name]
    }

    return [eval_with_privileges {
        LoadUserProfile [list $token $noui $username $roamingprofilepath $defaultuserpath $servername]
    } {SeRestorePrivilege SeBackupPrivilege}]
}

# TBD - document
proc twapi::get_profile_type {} {
    return [dict* {0 local 1 temporary 2 roaming 4 mandatory} [GetProfileType]]
}


proc twapi::_env_block_to_dict {block normalize} {
    set env_dict {}
    foreach env_str $block {
        set pos [string first = $env_str]
        set key [string range $env_str 0 $pos-1]
        if {$normalize} {
            set key [string toupper $key]
        }
        lappend env_dict $key [string range $env_str $pos+1 end]
    }
    return $env_dict
}

proc twapi::get_system_environment_vars {args} {
    parseargs args {normalize.bool} -nulldefault -setvars -maxleftover 0
    return [_env_block_to_dict [CreateEnvironmentBlock 0 0] $normalize]
}

proc twapi::get_user_environment_vars {token args} {
    parseargs args {inherit.bool normalize.bool} -nulldefault -setvars -maxleftover 0
    return [_env_block_to_dict [CreateEnvironmentBlock $token $inherit] $normalize]
}

proc twapi::expand_system_environment_vars {s} {
    return [ExpandEnvironmentStringsForUser 0 $s]
}

proc twapi::expand_user_environment_vars {tok s} {
    return [ExpandEnvironmentStringsForUser $tok $s]
}

#
# Utility procedures

# Get the path of a process
proc twapi::_get_process_name_path_helper {pid {type name} args} {

    if {$pid == [pid]} {
        # It is our process!
        set exe [info nameofexecutable]
        if {$type eq "name"} {
            return [file tail $exe]
        } else {
            return $exe
        }
    }

    array set opts [parseargs args {
        {noexist.arg "(no such process)"}
        {noaccess.arg "(unknown)"}
    } -maxleftover 0]

    if {![string is integer $pid]} {
        error "Invalid non-numeric pid $pid"
    }
    if {[is_system_pid $pid]} {
        return "System"
    }
    if {[is_idle_pid $pid]} {
        return "System Idle Process"
    }

    # Try the quicker way if looking for a name
    if {$type eq "name" &&
        ![catch {
            Twapi_GetProcessList $pid 2
        } plist]} {
        set name [lindex $plist 1 0 1]
        if {$name ne ""} {
            return $name
        }
    }

    # We first try using GetProcessImageFileName as that does not require
    # the PROCESS_VM_READ privilege
    if {[min_os_version 6 0]} {
        set privs [list process_query_limited_information]
    } else {
        set privs [list process_query_information]
    }

    trap {
        set hprocess [get_process_handle $pid -access $privs]
        set path [GetProcessImageFileName $hprocess]
        if {$type eq "name"} {
            return [file tail $path]
        }
        # Returned path is in native format, convert to win32
        return [normalize_device_rooted_path $path]
    } onerror {TWAPI_WIN32 87} {
        return $opts(noexist)
    } onerror {} {
        # Other errors, continue on to other methods
    } finally {
        if {[info exists hprocess]} {
            twapi::close_handle $hprocess
        }
    }

    trap {
        set hprocess [get_process_handle $pid -access {process_query_information process_vm_read}]
    } onerror {TWAPI_WIN32 87} {
        return $opts(noexist)
    } onerror {TWAPI_WIN32 5} {
        # Access denied
        # If it is the name we want, first try WTS and if that
        # fails try getting it from PDH (slowest)

        if {[string equal $type "name"]} {
            if {! [catch {WTSEnumerateProcesses NULL} precords]} {
                
                return [lindex [recordarray column $precords pProcessName -filter [list [list ProcessId == $pid]]] 0]
            }

            # That failed as well, try PDH. TBD - get rid of PDH
            set pdh_path [lindex [lindex [twapi::get_perf_process_counter_paths [list $pid] -pid] 0] 3]
            array set pdhinfo [pdh_parse_counter_path $pdh_path]
            return $pdhinfo(instance)
        }
        return $opts(noaccess)
    }

    trap {
        set module [lindex [EnumProcessModules $hprocess] 0]
        if {[string equal $type "name"]} {
            set path [GetModuleBaseName $hprocess $module]
        } else {
            set path [_normalize_path [GetModuleFileNameEx $hprocess $module]]
        }
    } onerror {TWAPI_WIN32 5} {
        # Access denied
        # On win2k (and may be Win2k3), if the process has exited but some
        # app still has a handle to the process, the OpenProcess succeeds
        # but the EnumProcessModules call returns access denied. So
        # check for this case
        if {[min_os_version 5 0]} {
            # Try getting exit code. 259 means still running.
            # Anything else means process has terminated
            if {[GetExitCodeProcess $hprocess] == 259} {
                return $opts(noaccess)
            } else {
                return $opts(noexist)
            }
        } else {
            rethrow
        }
    } onerror {TWAPI_WIN32 299} {
        # Partial read - usually means either we are WOW64 and target
        # is 64bit, or process is exiting / starting and not all mem is
        # reachable yet
        return $opts(noaccess)
    } finally {
        CloseHandle $hprocess
    }
    return $path
}

# Fill in arrays with result from WTSEnumerateProcesses if available
proc twapi::_get_wts_pids {v_sids v_names} {
    # Note this call is expected to fail on NT 4.0 without terminal server
    if {! [catch {WTSEnumerateProcesses NULL} precords]} {
        upvar $v_sids wtssids
        upvar $v_names wtsnames
        array set wtssids [recordarray getlist $precords -slice {ProcessId pUserSid} -format flat]
        array set wtsnames [recordarray getlist $precords -slice {ProcessId pUserSid} -format flat]
    }
}

# Return various information from a process token
proc twapi::_token_info_helper {args} {
    package require twapi_security
    proc _token_info_helper {args} {
        if {[llength $args] == 1} {
            # All options specified as one argument
            set args [lindex $args 0]
        }

        if {0} {
            Following options are passed on to get_token_info:
            elevation
            virtualized
            groups
            restrictedgroups
            primarygroup
            primarygroupsid
            privileges
            enabledprivileges
            disabledprivileges
            logonsession
            linkedtoken
            Option -integrity is not passed on because it has to deal with
            -raw and -label options
        }

        array set opts [parseargs args {
            pid.arg
            hprocess.arg
            tid.arg
            hthread.arg
            integrity
            raw
            label
            user
        } -ignoreunknown]

        if {[expr {[info exists opts(pid)] + [info exists opts(hprocess)] +
                   [info exists opts(tid)] + [info exists opts(hthread)]}] > 1} {
            error "At most one option from -pid, -tid, -hprocess, -hthread can be specified."
        }

        if {$opts(user)} {
            lappend args -usersid
        }

        if {[info exists opts(hprocess)]} {
            set tok [open_process_token -hprocess $opts(hprocess)]
        } elseif {[info exists opts(pid)]} {
            set tok [open_process_token -pid $opts(pid)]
        } elseif {[info exists opts(hthread)]} {
            set tok [open_thread_token -hthread $opts(hthread)]
        } elseif {[info exists opts(tid)]} {
            set tok [open_thread_token -tid $opts(tid)]
        } else {
            # Default is current process
            set tok [open_process_token]
        }

        trap {
            array set result [get_token_info $tok {*}$args]
            if {[info exists result(-usersid)]} {
                set result(-user) [lookup_account_sid $result(-usersid)]
                unset result(-usersid)
            }
            if {$opts(integrity)} {
                if {$opts(raw)} {
                    set integrity [get_token_integrity $tok -raw]
                } elseif {$opts(label)} {
                    set integrity [get_token_integrity $tok -label]
                } else {
                    set integrity [get_token_integrity $tok]
                }
                set result(-integrity) $integrity
            }
        } finally {
            close_token $tok
        }

        return [array get result]
    }

    return [_token_info_helper {*}$args]
}

# Set various information for a process token
# Caller assumed to have enabled appropriate privileges
proc twapi::_token_set_helper {args} {
    package require twapi_security

    proc _token_set_helper {args} {
        if {[llength $args] == 1} {
            # All options specified as one argument
            set args [lindex $args 0]
        }

        array set opts [parseargs args {
            virtualized.bool
            integrity.arg
            {noexist.arg "(no such process)"}
            {noaccess.arg "(unknown)"}
            pid.arg
            hprocess.arg
        } -maxleftover 0]

        if {[info exists opts(pid)] && [info exists opts(hprocess)]} {
            error "Options -pid and -hprocess cannot be specified together."
        }

        # Open token with appropriate access rights depending on request.
        set access [list token_adjust_default]

        if {[info exists opts(hprocess)]} {
            set tok [open_process_token -hprocess $opts(hprocess) -access $access]
        } elseif {[info exists opts(pid)]} {
            set tok [open_process_token -pid $opts(pid) -access $access]
        } else {
            # Default is current process
            set tok [open_process_token -access $access]
        }

        set result [list ]
        trap {
            if {[info exists opts(integrity)]} {
                set_token_integrity $tok $opts(integrity)
            }
            if {[info exists opts(virtualized)]} {
                set_token_virtualization $tok $opts(virtualized)
            }
        } finally {
            close_token $tok
        }

        return $result
    }
    return [_token_set_helper {*}$args]
}

# Map console color name to integer attribute
proc twapi::_map_console_color {colors background} {
    set attr 0
    foreach color $colors {
        switch -exact -- $color {
            blue   {setbits attr 1}
            green  {setbits attr 2}
            red    {setbits attr 4}
            white  {setbits attr 7}
            bright {setbits attr 8}
            black  { }
            default {error "Unknown color name $color"}
        }
    }
    if {$background} {
        set attr [expr {$attr << 4}]
    }
    return $attr
}

