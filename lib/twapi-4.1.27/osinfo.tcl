#
# Copyright (c) 2003-2012, Ashok P. Nadkarni
# All rights reserved.
#
# See the file LICENSE for license

namespace eval twapi {}

# Returns an keyed list with the following elements:
#   os_major_version
#   os_minor_version
#   os_build_number
#   platform - currently always NT
#   sp_major_version
#   sp_minor_version
#   suites - one or more from backoffice, blade, datacenter, enterprise,
#            smallbusiness, smallbusiness_restricted, terminal, personal
#   system_type - workstation, server
proc twapi::get_os_info {} {
    variable _osinfo

    if {[info exists _osinfo]} {
        return [array get _osinfo]
    }

    array set verinfo [GetVersionEx]
    set _osinfo(os_major_version) $verinfo(dwMajorVersion)
    set _osinfo(os_minor_version) $verinfo(dwMinorVersion)
    set _osinfo(os_build_number)  $verinfo(dwBuildNumber)
    set _osinfo(platform)         "NT"

    set _osinfo(sp_major_version) $verinfo(wServicePackMajor)
    set _osinfo(sp_minor_version) $verinfo(wServicePackMinor)

    set _osinfo(suites) [list ]
    set suites $verinfo(wSuiteMask)
    foreach {suite def} {
        backoffice 0x4 blade 0x400 communications 0x8 compute_server 0x4000
        datacenter 0x80 embeddednt 0x40 embedded_restricted 0x800
        enterprise 0x2 personal 0x200 security_appliance 0x1000
        singleuserts 0x100 smallbusiness 0x1 
        smallbusiness_restricted 0x20 storage_server 0x2000
        terminal 0x10 wh_server 0x8000
    } {
        if {$suites & $def} {
            lappend _osinfo(suites) $suite
        }
    }

    set system_type $verinfo(wProductType)
    if {$system_type == 1} {
        set _osinfo(system_type) "workstation";         # VER_NT_WORKSTATION
    } elseif {$system_type == 3} {
        set _osinfo(system_type) "server";         # VER_NT_SERVER
    } elseif {$system_type == 2} {
        set _osinfo(system_type) "domain_controller"; # VER_NT_DOMAIN_CONTROLLER
    } else {
        set _osinfo(system_type) "unknown"
    }

    return [array get _osinfo]
}

# Return a text string describing the OS version and options
# If specified, osinfo should be a keyed list containing
# data returned by get_os_info
proc twapi::get_os_description {} {

    array set osinfo [get_os_info]

    # Assume not terminal server
    set tserver ""

    # Version
    set osversion "$osinfo(os_major_version).$osinfo(os_minor_version)"

    set systype ""

    # Base OS name
    switch -exact -- $osversion {
        "5.0" {
            set osname "Windows 2000"
            if {[string equal $osinfo(system_type) "workstation"]} {
                set systype "Professional"
            } else {
                if {"datacenter" in $osinfo(suites)} {
                    set systype "Datacenter Server"
                } elseif {"enterprise" in $osinfo(suites)} {
                    set systype "Advanced Server"
                } else {
                    set systype "Server"
                }
            }
        }
        "5.1" {
            set osname "Windows XP"
            if {"personal" in $osinfo(suites)} {
                set systype "Home Edition"
            } else {
                set systype "Professional"
            }
        }
        "5.2" {
            set osname "Windows Server 2003"
            if {[GetSystemMetrics 89]} {
                append osname " R2"
            }
            if {"datacenter" in $osinfo(suites)} {
                set systype "Datacenter Edition"
            } elseif {"enterprise" in  $osinfo(suites)} {
                set systype "Enterprise Edition"
            } elseif {"blade" in  $osinfo(suites)} {
                set systype "Web Edition"
            } else {
                set systype "Standard Edition"
            }
        }
        "6.0" {
            set prodtype [GetProductInfo]
            if {$osinfo(system_type) eq "workstation"} {
                set osname "Windows Vista"
            } else {
                set osname "Windows Server 2008"
            }
        }
        "6.1" {
            set prodtype [GetProductInfo]
            if {$osinfo(system_type) eq "workstation"} {
                set osname "Windows 7"
            } else {
                set osname "Windows Server 2008 R2"
            }
        }
        "6.2" {
            if {$osinfo(system_type) eq "workstation"} {
                # Win8 does not follow the systype table below
                switch -exact -- [format %x [GetProductInfo]] {
                    3 {set systype ""}
                    6 {set systype Pro}
                    default {set systype Enterprise}
                }
                set osname "Windows 8"
            } else {
                set prodtype [GetProductInfo]

                set osname "Windows Server 2012"
            }
            
        }
        "6.3" {
            if {$osinfo(system_type) eq "workstation"} {
                # Win8.1 probably (TBD) does not follow the systype table below
                switch -exact -- [format %x [GetProductInfo]] {
                    3 {set systype ""}
                    6 {set systype Pro}
                    default {set systype Enterprise}
                }
                set osname "Windows 8.1"
            } else {
                set prodtype [GetProductInfo]
                set osname "Windows Server 2012 R2"
            }
        }
        default {
            # Future release - can't really name, just make something up
            catch {set prodtype [GetProductInfo]}
            set osname "Windows"
        }
    }

    if {[info exists prodtype] && $prodtype} {
        catch {
            set systype [dict get {
                1 "Ultimate"
                2 "Home Basic"
                3 "Home Premium"
                4 "Enterprise"
                5 "Home Basic N"
                6 "Business"
                7 "Standard"
                8 "Datacenter"
                9 "Small Business Server"
                a "Enterprise Server"
                b "Starter"
                c "Datacenter Server Core"
                d "Standard Server Core"
                e "Enterprise Server Core"
                f "Enterprise Server Ia64"
                10 "Business N"
                11 "Web Server"
                12 "HPC Edition"
                13 "Home Server"
                14 "Storage Server Express"
                15 "Storage Server Standard"
                16 "Storage Server Workgroup"
                17 "Storage Server Enterprise"
                18 "Essential Server Solutions"
                19 "Small Business Server Premium"
                1a "Home Premium N"
                1b "Enterprise N"
                1c "Ultimate N"
                1d "Web Server Core"
                1e "Essential Business Server Management Server"
                1f "Essential Business Server Security Server"
                20 "Essential Business Server Messaging Server"
                21 "Server Foundation"
                22 "Home Premium Server"
                23 "Essential Server Solutions without Hyper-V"
                24 "Standard without Hyper-V"
                25 "Datacenter without Hyper-V"
                26 "Enterprise without Hyper-V"
                26 "Enterprise Server V"
                27 "Datacenter Server Core without Hyper-V"
                28 "Standard Core without Hyper-V"
                29 "Enterprise Server Core without Hyper-V"
                2a "Hyper-V Server"
                2b "Storage Express Server Core"
                2c "Storage Standard Server Core"
                2d "Storage Workgroup Server Core"
                2e "Storage Enterprise Server Core"
                2f "Starter N"
                30 "Professional"
                31 "Professional N"
                32 "Small Business Server 2011 Essentials"
                33 "Server For SB Solutions"
                34 "Standard Server Solutions"
                35 "Standard Server Solutions Core"
                36 "Server For SB Solutions EM"
                37 "Server For SB Solutions EM"
                38 "Windows MultiPoint Server"
                39 "Solution Embeddedserver Core"
                3a "Professional Embedded"
                3b "Windows Essential Server Solution Management"
                3c "Windows Essential Server Solution Additional"
                3d "Windows Essential Server Solution SVC"
                3e "Windows Essential Server Solution Additional SVC"
                3f "Small Business Premium Server Core"
                40 "Hyper Core V"
                41 "Embedded"
                42 "Starter E"
                43 "Home Basic E"
                44 "Home Premium E"
                45 "Professional E"
                46 "Enterprise E"
                47 "Ultimate E"
                48 "Enterprise Evaluation"
                4c "Multipoint Standard Server"
                4d "Multipoint Premium Server"
                4f "Standard Evaluation Server"
                50 "Datacenter Evaluation"
                54 "Enterprise N Evaluation"
                55 "Embedded Automotive"
                56 "Embedded Industry A"
                57 "Thin PC"
                58 "Embedded A"
                59 "Embedded Industry"
                5a "Embedded E"
                5b "Embedded Industry E"
                5c "Embedded Industry A E"
                5f "Storage Workgroup Evaluation Server"
                60 "Storage Standard Evaluation Server"
                61 "Core Arm"
                62 "N"
                63 "China"
                64 "Single Language"
                65 ""
                67 "Professional Wmc"
                68 "Mobile Core"
                69 "Embedded Industry Eval"
                6a "Embedded Industry E Eval"
                6b "Embedded Eval"
                6c "Embedded E Eval"
                6d "Core Server"
                6e "Cloud Storage Server"
                abcdabcd "unlicensed"
            } [format %x $prodtype]]
        }
    }

    if {"terminal" in  $osinfo(suites)} {
        set tserver " with Terminal Services"
    }

    # Service pack
    if {$osinfo(sp_major_version) != 0} {
        set spver " Service Pack $osinfo(sp_major_version)"
    } else {
        set spver ""
    }

    if {$systype ne ""} {
        return "$osname $systype ${osversion} (Build $osinfo(os_build_number))${spver}${tserver}"
    } else {
        return "$osname ${osversion} (Build $osinfo(os_build_number))${spver}${tserver}"
    }
}

proc twapi::get_processor_group_config {} {
    trap {
        set info [GetLogicalProcessorInformationEx 4]
        if {[llength $info]} {
            set maxgroupcount [lindex $info 0 1 0]
            set groups {}
            set num -1
            foreach group [lindex $info 0 1 1] {
                lappend groups [incr num] [twine {-maxprocessorcount -activeprocessorcount -processormask} $group]
            }
        }
        return [list -maxgroupcount $maxgroupcount -activegroups $groups]
    } onerror {TWAPI_WIN32 127} {
        # Just try older APIs
        set processor_count [lindex [GetSystemInfo] 5]
        return [list -maxgroupcount 1 -activegroups [list 0 [list -maxprocessorcount $processor_count -activeprocessorcount $processor_count -processormask [expr {(1 << $processor_count) - 1}]]]]
    }

}

proc twapi::get_numa_config {} {
    trap {
        set result {}
        foreach rec [GetLogicalProcessorInformationEx 1] {
            lappend result [lindex $rec 1 0] [twine {-processormask -group} [lindex $rec 1 1]]
        }
        return $result
    } onerror {TWAPI_WIN32 127} {
        # Use older APIs below
    }

    # If GetLogicalProcessorInformation is available, records of type "1"
    # indicate NUMA information. Use it.
    trap {
        set result {}
        foreach rec [GetLogicalProcessorInformation] {
            if {[lindex $rec 1] == 1} {
                lappend result [lindex $rec 2] [list -processormask [lindex $rec 0] -group 0]
            }
        }
        return $result
    } onerror {TWAPI_WIN32 127} {
        # API not present, fake it
    }

    return $result
}

# Returns proc information
#  $processor should be processor number or "" for "total"
proc twapi::get_processor_info {processor args} {

    if {![string is integer $processor]} {
        error "Invalid processor number \"$processor\". Should be a processor identifier or the empty string to signify all processors"
    }

    if {![info exists ::twapi::get_processor_info_base_opts]} {
        array set ::twapi::get_processor_info_base_opts {
            idletime    IdleTime
            privilegedtime  KernelTime
            usertime    UserTime
            dpctime     DpcTime
            interrupttime InterruptTime
            interrupts    InterruptCount
        }
    }

    set sysinfo_opts {
        arch
        processorlevel
        processorrev
        processorname
        processormodel
        processorspeed
    }

    array set opts [parseargs args \
                        [concat all \
                             [array names ::twapi::get_processor_info_base_opts] \
                             $sysinfo_opts] -maxleftover 0]

    # Registry lookup for processor description
    # If no processor specified, use 0 under the assumption all processors
    # are the same
    set reg_hwkey "HKEY_LOCAL_MACHINE\\HARDWARE\\DESCRIPTION\\System\\CentralProcessor\\[expr {$processor == "" ? 0 : $processor}]"

    set results [list ]

    set processordata [Twapi_SystemProcessorTimes]
    if {$processor ne ""} {
        if {[llength $processordata] <= $processor} {
            error "Invalid processor number '$processor'"
        }
        array set times [lindex $processordata $processor]
        foreach {opt field} [array get ::twapi::get_processor_info_base_opts] {
            if {$opts(all) || $opts($opt)} {
                lappend results -$opt $times($field)
            }
        }
    } else {
        # Need information across all processors
        foreach instancedata $processordata {
            foreach {opt field} [array get ::twapi::get_processor_info_base_opts] {
                incr times($field) [kl_get $instancedata $field]
            }
            foreach {opt field} [array get ::twapi::get_processor_info_base_opts] {
                if {$opts(all) || $opts($opt)} {
                    lappend results -$opt $times($field)
                }
            }
        }
    }

    if {$opts(all) || $opts(arch) || $opts(processorlevel) || $opts(processorrev)} {
        set sysinfo [GetSystemInfo]
        if {$opts(all) || $opts(arch)} {
            lappend results -arch [dict* {
                0 intel
                5 arm
                6 ia64
                9 amd64
                10 ia32_win64
                65535 unknown
            } [lindex $sysinfo 0]]
        }

        if {$opts(all) || $opts(processorlevel)} {
            lappend results -processorlevel [lindex $sysinfo 8]
        }

        if {$opts(all) || $opts(processorrev)} {
            lappend results -processorrev [format %x [lindex $sysinfo 9]]
        }
    }

    if {$opts(all) || $opts(processorname)} {
        if {[catch {registry get $reg_hwkey "ProcessorNameString"} val]} {
            set val "unknown"
        }
        lappend results -processorname $val
    }

    if {$opts(all) || $opts(processormodel)} {
        if {[catch {registry get $reg_hwkey "Identifier"} val]} {
            set val "unknown"
        }
        lappend results -processormodel $val
    }

    if {$opts(all) || $opts(processorspeed)} {
        if {[catch {registry get $reg_hwkey "~MHz"} val]} {
            set val "unknown"
        }
        lappend results -processorspeed $val
    }

    return $results
}

# Get mask of active processors
# TBD - handle processor groups
proc twapi::get_active_processor_mask {} {
    return [format 0x%x [lindex [GetSystemInfo] 4]]
}


# Get number of active processors
proc twapi::get_processor_count {} {
    trap {
        set info [GetLogicalProcessorInformationEx 4]
        if {[llength $info]} {
            set count 0
            foreach group [lindex $info 0 1 1] {
                incr count [lindex $group 1]
            }
        }
        return $count
    } onerror {TWAPI_WIN32 127} {
        # GetLogicalProcessorInformationEx call does not exist
        # so system does not support processor groups
        return [lindex [GetSystemInfo] 5]
    }
}

# Get system memory information
proc twapi::get_memory_info {args} {
    array set opts [parseargs args {
        all
        allocationgranularity
        availcommit
        availphysical
        kernelpaged
        kernelnonpaged
        minappaddr
        maxappaddr
        pagesize
        peakcommit
        physicalmemoryload
        processavailcommit
        processcommitlimit
        processtotalvirtual
        processavailvirtual
        swapfiles
        swapfiledetail
        systemcache
        totalcommit
        totalphysical
        usedcommit
    } -maxleftover 0]


    set results [list ]
    set mem [GlobalMemoryStatus]
    foreach {opt fld} {
        physicalmemoryload     dwMemoryLoad
        totalphysical  ullTotalPhys
        availphysical  ullAvailPhys
        processcommitlimit    ullTotalPageFile
        processavailcommit    ullAvailPageFile
        processtotalvirtual   ullTotalVirtual
        processavailvirtual   ullAvailVirtual
    } {
        if {$opts(all) || $opts($opt)} {
            lappend results -$opt [kl_get $mem $fld]
        }
    }

    if {$opts(all) || $opts(swapfiles) || $opts(swapfiledetail)} {
        set swapfiles [list ]
        set swapdetail [list ]

        foreach item [Twapi_SystemPagefileInformation] {
            lassign $item current_size total_used peak_used path
            set path [_normalize_path $path]
            lappend swapfiles $path
            lappend swapdetail $path [list $current_size $total_used $peak_used]
        }
        if {$opts(all) || $opts(swapfiles)} {
            lappend results -swapfiles $swapfiles
        }
        if {$opts(all) || $opts(swapfiledetail)} {
            lappend results -swapfiledetail $swapdetail
        }
    }

    if {$opts(all) || $opts(allocationgranularity) ||
        $opts(minappaddr) || $opts(maxappaddr) || $opts(pagesize)} {
        set sysinfo [twapi::GetSystemInfo]
        foreach {opt fmt index} {
            pagesize %u 1 minappaddr 0x%lx 2 maxappaddr 0x%lx 3 allocationgranularity %u 7} {
            if {$opts(all) || $opts($opt)} {
                lappend results -$opt [format $fmt [lindex $sysinfo $index]]
            }
        }
    }

    # This call is slightly expensive so check if it is really needed 
    if {$opts(all) || $opts(totalcommit) || $opts(usedcommit) ||
        $opts(availcommit) ||
        $opts(kernelpaged) || $opts(kernelnonpaged)
    } {
        set mem [GetPerformanceInformation]
        set page_size [kl_get $mem PageSize]
        foreach {opt fld} {
            totalcommit CommitLimit
            usedcommit  CommitTotal
            peakcommit  CommitPeak
            systemcache SystemCache
            kernelpaged KernelPaged
            kernelnonpaged KernelNonpaged
        } {
            if {$opts(all) || $opts($opt)} {
                lappend results -$opt [expr {[kl_get $mem $fld] * $page_size}]
            }
        }
        if {$opts(all) || $opts(availcommit)} {
            lappend results -availcommit [expr {$page_size * ([kl_get $mem CommitLimit]-[kl_get $mem CommitTotal])}]
        }
    }
        
    return $results
}

# Get the netbios name
proc twapi::get_computer_netbios_name {} {
    return [GetComputerName]
}

# Get the computer name
proc twapi::get_computer_name {{typename netbios}} {
    if {[string is integer $typename]} {
        set type $typename
    } else {
        set type [lsearch -exact {netbios dnshostname dnsdomain dnsfullyqualified physicalnetbios physicaldnshostname physicaldnsdomain physicaldnsfullyqualified} $typename]
        if {$type < 0} {
            error "Unknown computer name type '$typename' specified"
        }
    }
    return [GetComputerNameEx $type]
}

# Suspend system
proc twapi::suspend_system {args} {
    array set opts [parseargs args {
        {state.arg standby {standby hibernate}}
        force.bool
        disablewakeevents.bool
    } -maxleftover 0 -nulldefault]

    eval_with_privileges {
        SetSuspendState [expr {$opts(state) eq "hibernate"}] $opts(force) $opts(disablewakeevents)
    } SeShutdownPrivilege
}

# Shut down the system
proc twapi::shutdown_system {args} {
    array set opts [parseargs args {
        system.arg
        {message.arg "System shutdown has been initiated"}
        {timeout.int 60}
        force
        restart
    } -nulldefault]

    eval_with_privileges {
        InitiateSystemShutdown $opts(system) $opts(message) \
            $opts(timeout) $opts(force) $opts(restart)
    } SeShutdownPrivilege
}

# Abort a system shutdown
proc twapi::abort_system_shutdown {args} {
    array set opts [parseargs args {system.arg} -nulldefault]
    eval_with_privileges {
        AbortSystemShutdown $opts(system)
    } SeShutdownPrivilege
}

twapi::proc* twapi::get_system_uptime {} {
    package require twapi_pdh
    variable _system_start_time    
    set ctr_path [pdh_counter_path System "System Up Time"]
    set uptime [pdh_counter_path_value $ctr_path -format double]
    set now [clock seconds]
    set _system_start_time [expr {$now - round($uptime+0.5)}]
} {
    variable _system_start_time
    return [expr {[clock seconds] - $_system_start_time}]
}

proc twapi::get_system_sid {} {
    set lsah [get_lsa_policy_handle -access policy_view_local_information]
    trap {
        return [lindex [LsaQueryInformationPolicy $lsah 5] 1]
    } finally {
        close_lsa_policy_handle $lsah
    }
}

# Get the primary domain controller
proc twapi::get_primary_domain_controller {args} {
    array set opts [parseargs args {system.arg domain.arg} -nulldefault -maxleftover 0]
    return [NetGetDCName $opts(system) $opts(domain)]
}

# Get a domain controller for a domain
proc twapi::find_domain_controller {args} {
    array set opts [parseargs args {
        system.arg
        avoidself.bool
        domain.arg
        domainguid.arg
        site.arg
        rediscover.bool
        allowstale.bool
        require.arg
        prefer.arg
        justldap.bool
        {inputnameformat.arg any {dns flat netbios any}}
        {outputnameformat.arg any {dns flat netbios any}}
        {outputaddrformat.arg any {ip netbios any}}
        getdetails
    } -maxleftover 0 -nulldefault]


    set flags 0

    if {$opts(outputaddrformat) eq "ip"} {
        setbits flags 0x200
    }

    # Set required bits.
    foreach req $opts(require) {
        if {[string is integer $req]} {
            setbits flags $req
        } else {
            switch -exact -- $req {
                directoryservice { setbits flags 0x10 }
                globalcatalog    { setbits flags 0x40 }
                pdc              { setbits flags 0x80 }
                kdc              { setbits flags 0x400 }
                timeserver       { setbits flags 0x800 }
                writable         { setbits flags 0x1000 }
                default {
                    error "Invalid token '$req' specified in value for option '-require'"
                }
            }
        }
    }

    # Set preferred bits.
    foreach req $opts(prefer) {
        if {[string is integer $req]} {
            setbits flags $req
        } else {
            switch -exact -- $req {
                directoryservice {
                    # If required flag is already set, don't set this
                    if {! ($flags & 0x10)} {
                        setbits flags 0x20
                    }
                }
                timeserver {
                    # If required flag is already set, don't set this
                    if {! ($flags & 0x800)} {
                        setbits flags 0x2000
                    }
                }
                default {
                    error "Invalid token '$req' specified in value for option '-prefer'"
                }
            }
        }
    }

    if {$opts(rediscover)} {
        setbits flags 0x1
    } else {
        # Only look at this option if rediscover is not set
        if {$opts(allowstale)} {
            setbits flags 0x100
        }
    }

    if {$opts(avoidself)} {
        setbits flags 0x4000
    }

    if {$opts(justldap)} {
        setbits flags 0x8000
    }

    switch -exact -- $opts(inputnameformat) {
        any  { }
        netbios -
        flat { setbits flags 0x10000 }
        dns  { setbits flags 0x20000 }
        default {
            error "Invalid value '$opts(inputnameformat)' for option '-inputnameformat'"
        }
    }

    switch -exact -- $opts(outputnameformat) {
        any  { }
        netbios -
        flat { setbits flags 0x80000000 }
        dns  { setbits flags 0x40000000 }
        default {
            error "Invalid value '$opts(outputnameformat)' for option '-outputnameformat'"
        }
    }

    array set dcinfo [DsGetDcName $opts(system) $opts(domain) $opts(domainguid) $opts(site) $flags]

    if {! $opts(getdetails)} {
        return $dcinfo(DomainControllerName)
    }

    set result [list \
                    -dcname $dcinfo(DomainControllerName) \
                    -dcaddr [string trimleft $dcinfo(DomainControllerAddress) \\] \
                    -domainguid $dcinfo(DomainGuid) \
                    -domain $dcinfo(DomainName) \
                    -dnsforest $dcinfo(DnsForestName) \
                    -dcsite $dcinfo(DcSiteName) \
                    -clientsite $dcinfo(ClientSiteName) \
                   ]


    if {$dcinfo(DomainControllerAddressType) == 1} {
        lappend result -dcaddrformat ip
    } else {
        lappend result -dcaddrformat netbios
    }

    if {$dcinfo(Flags) & 0x20000000} {
        lappend result -dcnameformat dns
    } else {
        lappend result -dcnameformat netbios
    }

    if {$dcinfo(Flags) & 0x40000000} {
        lappend result -domainformat dns
    } else {
        lappend result -domainformat netbios
    }

    if {$dcinfo(Flags) & 0x80000000} {
        lappend result -dnsforestformat dns
    } else {
        lappend result -dnsforestformat netbios
    }

    set features [list ]
    foreach {flag feature} {
        0x1    pdc
        0x4    globalcatalog
        0x8    ldap
        0x10   directoryservice
        0x20   kdc
        0x40   timeserver
        0x80   closest
        0x100  writable
        0x200  goodtimeserver
    } {
        if {$dcinfo(Flags) & $flag} {
            lappend features $feature
        }
    }

    lappend result -features $features

    return $result
}

# Get the primary domain info
proc twapi::get_primary_domain_info {args} {
    array set opts [parseargs args {
        all
        name
        dnsdomainname
        dnsforestname
        domainguid
        sid
        type
    } -maxleftover 0]

    set result [list ]
    set lsah [get_lsa_policy_handle -access policy_view_local_information]
    trap {
        lassign  [LsaQueryInformationPolicy $lsah 12]  name dnsdomainname dnsforestname domainguid sid
        if {[string length $sid] == 0} {
            set type workgroup
            set domainguid ""
        } else {
            set type domain
        }
        foreach opt {name dnsdomainname dnsforestname domainguid sid type} {
            if {$opts(all) || $opts($opt)} {
                lappend result -$opt [set $opt]
            }
        }
    } finally {
        close_lsa_policy_handle $lsah
    }

    return $result
}

# Get a element from SystemParametersInfo
proc twapi::get_system_parameters_info {uiaction} {
    variable SystemParametersInfo_uiactions_get
    # Format of an element is
    #  uiaction_indexvalue uiparam binaryscanstring malloc_size modifiers
    # uiparam may be an int or "sz" in which case the malloc size
    # is substribnuted for it.
    # If modifiers contains "cbsize" the first dword is initialized
    # with malloc_size
    # TBD - use dict instead
    if {![info exists SystemParametersInfo_uiactions_get]} {
        array set SystemParametersInfo_uiactions_get {
            SPI_GETDESKWALLPAPER {0x0073 2048 unicode 4096}
            SPI_GETBEEP  {0x0001 0 i 4}
            SPI_GETMOUSE {0x0003 0 i3 12}
            SPI_GETBORDER {0x0005 0 i 4}
            SPI_GETKEYBOARDSPEED {0x000A 0 i 4}
            SPI_ICONHORIZONTALSPACING {0x000D 0 i 4}
            SPI_GETSCREENSAVETIMEOUT {0x000E 0 i 4}
            SPI_GETSCREENSAVEACTIVE {0x0010 0 i 4}
            SPI_GETKEYBOARDDELAY {0x0016 0 i 4}
            SPI_ICONVERTICALSPACING {0x0018 0 i 4}
            SPI_GETICONTITLEWRAP {0x0019 0 i 4}
            SPI_GETMENUDROPALIGNMENT {0x001B 0 i 4}
            SPI_GETDRAGFULLWINDOWS {0x0026 0 i 4}
            SPI_GETNONCLIENTMETRICS {0x0029 sz {i6 i5 cu8 A64 i2 i5 cu8 A64 i2 i5 cu8 A64 i5 cu8 A64 i5 cu8 A64} 500 cbsize}
            SPI_GETMINIMIZEDMETRICS {0x002B sz i5 20 cbsize}
            SPI_GETWORKAREA {0x0030 0 i4 16}
            SPI_GETKEYBOARDPREF {0x0044 0 i 4 }
            SPI_GETSCREENREADER {0x0046 0 i 4}
            SPI_GETANIMATION {0x0048 sz i2 8 cbsize}
            SPI_GETFONTSMOOTHING {0x004A 0 i 4}
            SPI_GETLOWPOWERTIMEOUT {0x004F 0 i 4}
            SPI_GETPOWEROFFTIMEOUT {0x0050 0 i 4}
            SPI_GETLOWPOWERACTIVE {0x0053 0 i 4}
            SPI_GETPOWEROFFACTIVE {0x0054 0 i 4}
            SPI_GETMOUSETRAILS {0x005E 0 i 4}
            SPI_GETSCREENSAVERRUNNING {0x0072 0 i 4}
            SPI_GETFILTERKEYS {0x0032 sz i6 24 cbsize}
            SPI_GETTOGGLEKEYS {0x0034 sz i2 8 cbsize}
            SPI_GETMOUSEKEYS {0x0036 sz i7 28 cbsize}
            SPI_GETSHOWSOUNDS {0x0038 0 i 4}
            SPI_GETSTICKYKEYS {0x003A sz i2 8 cbsize}
            SPI_GETACCESSTIMEOUT {0x003C 12 i3 12 cbsize}
            SPI_GETSNAPTODEFBUTTON {0x005F 0 i 4}
            SPI_GETMOUSEHOVERWIDTH {0x0062 0 i 4}
            SPI_GETMOUSEHOVERHEIGHT {0x0064 0 i 4 }
            SPI_GETMOUSEHOVERTIME {0x0066 0 i 4}
            SPI_GETWHEELSCROLLLINES {0x0068 0 i 4}
            SPI_GETMENUSHOWDELAY {0x006A 0 i 4}
            SPI_GETSHOWIMEUI {0x006E 0 i 4}
            SPI_GETMOUSESPEED {0x0070 0 i 4}
            SPI_GETACTIVEWINDOWTRACKING {0x1000 0 i 4}
            SPI_GETMENUANIMATION {0x1002 0 i 4}
            SPI_GETCOMBOBOXANIMATION {0x1004 0 i 4}
            SPI_GETLISTBOXSMOOTHSCROLLING {0x1006 0 i 4}
            SPI_GETGRADIENTCAPTIONS {0x1008 0 i 4}
            SPI_GETKEYBOARDCUES {0x100A 0 i 4}
            SPI_GETMENUUNDERLINES            {0x100A 0 i 4}
            SPI_GETACTIVEWNDTRKZORDER {0x100C 0 i 4}
            SPI_GETHOTTRACKING {0x100E 0 i 4}
            SPI_GETMENUFADE {0x1012 0 i 4}
            SPI_GETSELECTIONFADE {0x1014 0 i 4}
            SPI_GETTOOLTIPANIMATION {0x1016 0 i 4}
            SPI_GETTOOLTIPFADE {0x1018 0 i 4}
            SPI_GETCURSORSHADOW {0x101A 0 i 4}
            SPI_GETMOUSESONAR {0x101C 0 i 4 }
            SPI_GETMOUSECLICKLOCK {0x101E 0 i 4}
            SPI_GETMOUSEVANISH {0x1020 0 i 4}
            SPI_GETFLATMENU {0x1022 0 i 4}
            SPI_GETDROPSHADOW {0x1024 0 i 4}
            SPI_GETBLOCKSENDINPUTRESETS {0x1026 0 i 4}
            SPI_GETUIEFFECTS {0x103E 0 i 4}
            SPI_GETFOREGROUNDLOCKTIMEOUT {0x2000 0 i 4}
            SPI_GETACTIVEWNDTRKTIMEOUT {0x2002 0 i 4}
            SPI_GETFOREGROUNDFLASHCOUNT {0x2004 0 i 4}
            SPI_GETCARETWIDTH {0x2006 0 i 4}
            SPI_GETMOUSECLICKLOCKTIME {0x2008 0 i 4}
            SPI_GETFONTSMOOTHINGTYPE {0x200A 0 i 4}
            SPI_GETFONTSMOOTHINGCONTRAST {0x200C 0 i 4}
            SPI_GETFOCUSBORDERWIDTH {0x200E 0 i 4}
            SPI_GETFOCUSBORDERHEIGHT {0x2010 0 i 4}
        }
    }

    set key [string toupper $uiaction]

    # TBD -
    # SPI_GETHIGHCONTRAST {0x0042 }
    # SPI_GETSOUNDSENTRY {0x0040 }
    # SPI_GETICONMETRICS {0x002D }
    # SPI_GETICONTITLELOGFONT {0x001F }
    # SPI_GETDEFAULTINPUTLANG {0x0059 }
    # SPI_GETFONTSMOOTHINGORIENTATION {0x2012}

    if {![info exists SystemParametersInfo_uiactions_get($key)]} {
        set key SPI_$key
        if {![info exists SystemParametersInfo_uiactions_get($key)]} {
            error "Unknown SystemParametersInfo index symbol '$uiaction'"
        }
    }

    lassign  $SystemParametersInfo_uiactions_get($key) index uiparam fmt sz modifiers
    if {$uiparam eq "sz"} {
        set uiparam $sz
    }
    set mem [malloc $sz]
    trap {
        if {[lsearch -exact $modifiers cbsize] >= 0} {
            # A structure that needs first field set to its size
            Twapi_WriteMemory 1 $mem 0 $sz [binary format i $sz]
        }
        SystemParametersInfo $index $uiparam $mem 0
        if {$fmt eq "unicode"} {
            return [Twapi_ReadMemory 3 $mem 0 $sz 1]
        } else {
            set n [binary scan [Twapi_ReadMemory 1 $mem 0 $sz] $fmt {*}[lrange {val0 val1 val2 val3 val4 val5 val6 val7 val8 val9 val10 val11 val12 val13 val14 val15 val16 val17 val17} 0 [llength $fmt]-1]]
            if {$n == 1} {
                return $val0
            } else {
                set result {}
                for {set i 0} {$i < $n} {incr i} {
                    lappend result {*}[set val$i]
                }
                return $result
            }
        }
    } finally {
        free $mem
    }
}

proc twapi::set_system_parameters_info {uiaction val args} {
    variable SystemParametersInfo_uiactions_set

    # Format of an element is
    #  uiaction_indexvalue uiparam binaryscanstring malloc_size modifiers
    # uiparam may be an int or "sz" in which case the malloc size
    # is substribnuted for it.
    # If modifiers contains "cbsize" the first dword is initialized
    # with malloc_size
    if {![info exists SystemParametersInfo_uiactions_set]} {
        array set SystemParametersInfo_uiactions_set {
            SPI_SETBEEP                 {0x0002 bool}
            SPI_SETMOUSE                {0x0004 unsupported}
            SPI_SETBORDER               {0x0006 int}
            SPI_SETKEYBOARDSPEED        {0x000B int}
            SPI_ICONHORIZONTALSPACING   {0x000D int}
            SPI_SETSCREENSAVETIMEOUT    {0x000F int}
            SPI_SETSCREENSAVEACTIVE     {0x0011 bool}
            SPI_SETDESKWALLPAPER        {0x0014 unsupported}
            SPI_SETDESKPATTERN          {0x0015 int}
            SPI_SETKEYBOARDDELAY        {0x0017 int}
            SPI_ICONVERTICALSPACING     {0x0018 int}
            SPI_SETICONTITLEWRAP        {0x001A bool}
            SPI_SETMENUDROPALIGNMENT    {0x001C bool}
            SPI_SETDOUBLECLKWIDTH       {0x001D int}
            SPI_SETDOUBLECLKHEIGHT      {0x001E int}
            SPI_SETDOUBLECLICKTIME      {0x0020 int}
            SPI_SETMOUSEBUTTONSWAP      {0x0021 bool}
            SPI_SETICONTITLELOGFONT     {0x0022 LOGFONT}
            SPI_SETDRAGFULLWINDOWS      {0x0025 bool}
            SPI_SETNONCLIENTMETRICS     {0x002A NONCLIENTMETRICS}
            SPI_SETMINIMIZEDMETRICS     {0x002C MINIMIZEDMETRICS}
            SPI_SETICONMETRICS          {0x002E ICONMETRICS}
            SPI_SETWORKAREA             {0x002F RECT}
            SPI_SETPENWINDOWS           {0x0031}
            SPI_SETHIGHCONTRAST         {0x0043 HIGHCONTRAST}
            SPI_SETKEYBOARDPREF         {0x0045 bool}
            SPI_SETSCREENREADER         {0x0047 bool}
            SPI_SETANIMATION            {0x0049 ANIMATIONINFO}
            SPI_SETFONTSMOOTHING        {0x004B bool}
            SPI_SETDRAGWIDTH            {0x004C int}
            SPI_SETDRAGHEIGHT           {0x004D int}
            SPI_SETHANDHELD             {0x004E}
            SPI_SETLOWPOWERTIMEOUT      {0x0051 int}
            SPI_SETPOWEROFFTIMEOUT      {0x0052 int}
            SPI_SETLOWPOWERACTIVE       {0x0055 bool}
            SPI_SETPOWEROFFACTIVE       {0x0056 bool}
            SPI_SETCURSORS              {0x0057 int}
            SPI_SETICONS                {0x0058 int}
            SPI_SETDEFAULTINPUTLANG     {0x005A HKL}
            SPI_SETLANGTOGGLE           {0x005B int}
            SPI_SETMOUSETRAILS          {0x005D int}
            SPI_SETFILTERKEYS          {0x0033 FILTERKEYS}
            SPI_SETTOGGLEKEYS          {0x0035 TOGGLEKEYS}
            SPI_SETMOUSEKEYS           {0x0037 MOUSEKEYS}
            SPI_SETSHOWSOUNDS          {0x0039 bool}
            SPI_SETSTICKYKEYS          {0x003B STICKYKEYS}
            SPI_SETACCESSTIMEOUT       {0x003D ACCESSTIMEOUT}
            SPI_SETSERIALKEYS          {0x003F SERIALKEYS}
            SPI_SETSOUNDSENTRY         {0x0041 SOUNDSENTRY}
            SPI_SETSNAPTODEFBUTTON     {0x0060 bool}
            SPI_SETMOUSEHOVERWIDTH     {0x0063 int}
            SPI_SETMOUSEHOVERHEIGHT    {0x0065 int}
            SPI_SETMOUSEHOVERTIME      {0x0067 int}
            SPI_SETWHEELSCROLLLINES    {0x0069 int}
            SPI_SETMENUSHOWDELAY       {0x006B int}
            SPI_SETSHOWIMEUI          {0x006F bool}
            SPI_SETMOUSESPEED         {0x0071 castint}
            SPI_SETACTIVEWINDOWTRACKING         {0x1001 castbool}
            SPI_SETMENUANIMATION                {0x1003 castbool}
            SPI_SETCOMBOBOXANIMATION            {0x1005 castbool}
            SPI_SETLISTBOXSMOOTHSCROLLING       {0x1007 castbool}
            SPI_SETGRADIENTCAPTIONS             {0x1009 castbool}
            SPI_SETKEYBOARDCUES                 {0x100B castbool}
            SPI_SETMENUUNDERLINES               {0x100B castbool}
            SPI_SETACTIVEWNDTRKZORDER           {0x100D castbool}
            SPI_SETHOTTRACKING                  {0x100F castbool}
            SPI_SETMENUFADE                     {0x1013 castbool}
            SPI_SETSELECTIONFADE                {0x1015 castbool}
            SPI_SETTOOLTIPANIMATION             {0x1017 castbool}
            SPI_SETTOOLTIPFADE                  {0x1019 castbool}
            SPI_SETCURSORSHADOW                 {0x101B castbool}
            SPI_SETMOUSESONAR                   {0x101D castbool}
            SPI_SETMOUSECLICKLOCK               {0x101F bool}
            SPI_SETMOUSEVANISH                  {0x1021 castbool}
            SPI_SETFLATMENU                     {0x1023 castbool}
            SPI_SETDROPSHADOW                   {0x1025 castbool}
            SPI_SETBLOCKSENDINPUTRESETS         {0x1027 bool}
            SPI_SETUIEFFECTS                    {0x103F castbool}
            SPI_SETFOREGROUNDLOCKTIMEOUT        {0x2001 castint}
            SPI_SETACTIVEWNDTRKTIMEOUT          {0x2003 castint}
            SPI_SETFOREGROUNDFLASHCOUNT         {0x2005 castint}
            SPI_SETCARETWIDTH                   {0x2007 castint}
            SPI_SETMOUSECLICKLOCKTIME           {0x2009 int}
            SPI_SETFONTSMOOTHINGTYPE            {0x200B castint}
            SPI_SETFONTSMOOTHINGCONTRAST        {0x200D unsupported}
            SPI_SETFOCUSBORDERWIDTH             {0x200F castint}
            SPI_SETFOCUSBORDERHEIGHT            {0x2011 castint}
        }
    }


    array set opts [parseargs args {
        persist
        notify
    } -nulldefault]

    set flags 0
    if {$opts(persist)} {
        setbits flags 1
    }

    if {$opts(notify)} {
        # Note that actually the notify flag has no effect if persist
        # is not set.
        setbits flags 2
    }

    set key [string toupper $uiaction]

    if {![info exists SystemParametersInfo_uiactions_set($key)]} {
        set key SPI_$key
        if {![info exists SystemParametersInfo_uiactions_set($key)]} {
            error "Unknown SystemParametersInfo index symbol '$uiaction'"
        }
    }

    lassign $SystemParametersInfo_uiactions_set($key) index fmt

    switch -exact -- $fmt {
        int  { SystemParametersInfo $index $val NULL $flags }
        bool {
            set val [expr {$val ? 1 : 0}]
            SystemParametersInfo $index $val NULL $flags
        }
        castint {
            # We have to pass the value as a cast pointer
            SystemParametersInfo $index 0 [Twapi_AddressToPointer $val] $flags
        }
        castbool {
            # We have to pass the value as a cast pointer
            set val [expr {$val ? 1 : 0}]
            SystemParametersInfo $index 0 [Twapi_AddressToPointer $val] $flags
        }
        default {
            error "The data format for $uiaction is not currently supported"
        }
    }

    return
}
