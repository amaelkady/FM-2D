#
# Copyright (c) 2004-2104, Ashok P. Nadkarni
# All rights reserved.
#
# See the file LICENSE for license

namespace eval twapi {
    record IP_ADAPTER_ADDRESSES_XP {
        -ipv4ifindex -adaptername -unicastaddresses -anycastaddresses
        -multicastaddresses -dnsservers -dnssuffix -description
        -friendlyname -physicaladdress -flags -mtu -type -operstatus
        -ipv6ifindex -zoneindices -prefixes
    }

    if {[min_os_version 6]} {
        record IP_ADAPTER_ADDRESSES [list {*}[IP_ADAPTER_ADDRESSES_XP] -transmitspeed -receivespeed -winsaddresses -gatewayaddresses -ipv4metric -ipv6metric -luid -dhcpv4server -compartmentid -networkguid -connectiontype -tunneltype -dhcpv6server -dhcpv6clientduid -dhcpv6iaid -dnssuffixes]
    } else {
        record IP_ADAPTER_ADDRESSES [IP_ADAPTER_ADDRESSES_XP]
    }

    record IP_ADAPTER_UNICAST_ADDRESS {
        -flags -address -prefixorigin -suffixorigin -dadstate -validlifetime -preferredlifetime -leaselifetime 
    }

    record IP_ADAPTER_ANYCAST_ADDRESS {-flags -address}
    record IP_ADAPTER_MULTICAST_ADDRESS [IP_ADAPTER_ANYCAST_ADDRESS]
    record IP_ADAPTER_DNS_SERVER_ADDRESS [IP_ADAPTER_ANYCAST_ADDRESS]
}

proc twapi::get_network_adapters {} {
    # 0x20 -> SKIP_FRIENDLYNAME
    # 0x0f -> SKIP_DNS_SERVER, SKIP_UNICAST/MULTICAST/ANYCAST
    return [lpick [GetAdaptersAddresses 0 0x2f] [enum [IP_ADAPTER_ADDRESSES] -adaptername]]
}

proc twapi::get_network_adapters_detail {} {
    set recs {}
    # We only return fields common to all platforms
    set fields [IP_ADAPTER_ADDRESSES_XP]
    foreach rec [GetAdaptersAddresses 0 0] {
        set rec [IP_ADAPTER_ADDRESSES set $rec \
                     -physicaladdress [_hwaddr_binary_to_string [IP_ADAPTER_ADDRESSES -physicaladdress $rec]] \
                     -unicastaddresses [ntwine [IP_ADAPTER_UNICAST_ADDRESS] [IP_ADAPTER_ADDRESSES -unicastaddresses $rec]] \
                     -multicastaddresses [ntwine [IP_ADAPTER_MULTICAST_ADDRESS] [IP_ADAPTER_ADDRESSES -multicastaddresses $rec]] \
                     -anycastaddresses [ntwine [IP_ADAPTER_ANYCAST_ADDRESS] [IP_ADAPTER_ADDRESSES -anycastaddresses $rec]] \
                     -dnsservers [ntwine [IP_ADAPTER_DNS_SERVER_ADDRESS] [IP_ADAPTER_ADDRESSES -dnsservers $rec]]]

        lappend recs [IP_ADAPTER_ADDRESSES select $rec $fields]
    }
    return [list $fields $recs]
}

# Get the list of local IP addresses
proc twapi::get_system_ipaddrs {args} {
    array set opts [parseargs args {
        {ipversion.arg 0}
        {types.arg unicast}
        adaptername.arg
    } -maxleftover 0]

    # 0x20 -> SKIP_FRIENDLYNAME
    # 0x08 -> SKIP_DNS_SERVER
    set flags 0x2f
    if {"all" in $opts(types)} {
        set flags 0x20
    } else {
        if {"unicast" in $opts(types)} {incr flags -1}
        if {"anycast" in $opts(types)} {incr flags -2}
        if {"multicast" in $opts(types)} {incr flags -4}
    }

    set addrs {}
    trap {
        set entries [GetAdaptersAddresses [_ipversion_to_af $opts(ipversion)] $flags]
    } onerror {TWAPI_WIN32 232} {
        # Not installed, so no addresses
        return {}
    }

    foreach entry $entries {
        if {[info exists opts(adaptername)] &&
            [string compare -nocase [IP_ADAPTER_ADDRESSES -adaptername $entry] $opts(adaptername)]} {
            continue
        }

        foreach rec [IP_ADAPTER_ADDRESSES -unicastaddresses $entry] {
            lappend addrs [IP_ADAPTER_UNICAST_ADDRESS -address $rec]
        }
        foreach rec [IP_ADAPTER_ADDRESSES -anycastaddresses $entry] {
            lappend addrs [IP_ADAPTER_ANYCAST_ADDRESS -address $rec]
        }
        foreach rec [IP_ADAPTER_ADDRESSES -multicastaddresses $entry] {
            lappend addrs [IP_ADAPTER_MULTICAST_ADDRESS -address $rec]
        }
    }

    return [lsort -unique $addrs]
}

# Get network related information
proc twapi::get_network_info {args} {
    # Map options into the positions in result of GetNetworkParams
    array set getnetworkparams_opts {
        hostname     0
        domain       1
        dnsservers   2
        dhcpscopeid  4
        routingenabled  5
        arpproxyenabled 6
        dnsenabled      7
    }

    array set opts [parseargs args \
                        [concat [list all] \
                             [array names getnetworkparams_opts]]]
    set result [list ]
    foreach opt [array names getnetworkparams_opts] {
        if {!$opts(all) && !$opts($opt)} continue
        if {![info exists netparams]} {
            set netparams [GetNetworkParams]
        }
        lappend result -$opt [lindex $netparams $getnetworkparams_opts($opt)]
    }

    return $result
}


proc twapi::get_network_adapter_info {interface args} {
    array set opts [parseargs args {
        all
        adaptername
        anycastaddresses
        description
        dhcpenabled
        dnsservers
        dnssuffix
        friendlyname
        ipv4ifindex
        ipv6ifindex
        multicastaddresses
        mtu
        operstatus
        physicaladdress
        prefixes
        type
        unicastaddresses
        zoneindices

        {ipversion.arg 0}
    } -maxleftover 0 -hyphenated]
    
    set ipversion [_ipversion_to_af $opts(-ipversion)]

    set flags 0
    if {! $opts(-all)} {
        # If not asked for some fields, don't bother getting them
        if {! $opts(-unicastaddresses)} { incr flags 0x1 }
        if {! $opts(-anycastaddresses)} { incr flags 0x2 }
        if {! $opts(-multicastaddresses)} { incr flags 0x4 }
        if {! $opts(-dnsservers)} { incr flags 0x8 }
        if {! $opts(-friendlyname)} { incr flags 0x20 }

        if {$opts(-prefixes)} { incr flags 0x10 }
    } else {
        incr flags 0x10;        # Want prefixes also
    }
    
    set entries [GetAdaptersAddresses $ipversion $flags]
    set nameindex [enum [IP_ADAPTER_ADDRESSES] -adaptername]
    set entry [lsearch -nocase -exact -inline -index $nameindex $entries $interface]
    if {[llength $entry] == 0} {
        error "No interface matching '$interface'."
    }

    array set result [IP_ADAPTER_ADDRESSES $entry]
    if {$opts(-all) || $opts(-dhcpenabled)} {
        set result(-dhcpenabled) [expr {($result(-flags) & 0x4) != 0}]
    }
    # Note even if -all is specified, we still loop through because
    # the fields of IP_ADAPTER_ADDRESSES are a superset of options
    foreach opt [IP_ADAPTER_ADDRESSES] {
        # Select only those fields that have an option defined
        # and that option is selected
        if {!([info exists opts($opt)] && ($opts(-all) || $opts($opt)))} {
            unset result($opt)
        }
    }
    if {[info exists result(-physicaladdress)]} {
        set result(-physicaladdress) [_hwaddr_binary_to_string $result(-physicaladdress)]
    }
    if {[info exists result(-unicastaddresses)]} {
        set result(-unicastaddresses) [ntwine [IP_ADAPTER_UNICAST_ADDRESS] $result(-unicastaddresses)]
    }
    if {[info exists result(-multicastaddresses)]} {
        set result(-multicastaddresses) [ntwine [IP_ADAPTER_MULTICAST_ADDRESS] $result(-multicastaddresses)]
    }
    if {[info exists result(-anycastaddresses)]} {
        set result(-anycastaddresses) [ntwine [IP_ADAPTER_ANYCAST_ADDRESS] $result(-anycastaddresses)]
    }
    if {[info exists result(-dnsservers)]} {
        set result(-dnsservers) [ntwine [IP_ADAPTER_DNS_SERVER_ADDRESS] $result(-dnsservers)]
    }

    return [array get result]
}

# Get the address->h/w address table
proc twapi::get_arp_table {args} {
    array set opts [parseargs args {
        sort
    }]

    set arps [list ]

    foreach arp [GetIpNetTable $opts(sort)] {
        lassign $arp  ifindex hwaddr ipaddr type
        # Token for enry   0     1      2      3        4
        set type [lindex {other other invalid dynamic static} $type]
        if {$type == ""} {
            set type other
        }
        lappend arps [list $ifindex [_hwaddr_binary_to_string $hwaddr] $ipaddr $type]
    }
    return [list [list ifindex hwaddr ipaddr type] $arps]
}

# Return IP address for a hw address
proc twapi::ipaddr_to_hwaddr {ipaddr {varname ""}} {
    if {![Twapi_IPAddressFamily $ipaddr]} {
        error "$ipaddr is not a valid IP V4 address"
    }

    foreach arp [GetIpNetTable 0] {
        if {[lindex $arp 3] == 2} continue;       # Invalid entry type
        if {[string equal $ipaddr [lindex $arp 2]]} {
            set result [_hwaddr_binary_to_string [lindex $arp 1]]
            break
        }
    }

    # If could not get from ARP table, see if it is one of our own
    # Ignore errors
    if {![info exists result]} {
        foreach ifc [get_network_adapters] {
            catch {
                array set netifinfo [get_network_adapter_info $ifc -unicastaddresses -physicaladdress]
                if {$netifinfo(-physicaladdress) eq ""} continue
                foreach elem $netifinfo(-unicastaddresses) {
                    if {[dict get $elem -address] eq $ipaddr} {
                        set result $netifinfo(-physicaladdress)
                        break
                    }
                }
            }
            if {[info exists result]} {
                break
            }
        }
    }

    if {[info exists result]} {
        if {$varname == ""} {
            return $result
        }
        upvar $varname var
        set var $result
        return 1
    } else {
        if {$varname == ""} {
            error "Could not map IP address $ipaddr to a hardware address"
        }
        return 0
    }
}

# Return hw address for a IP address
proc twapi::hwaddr_to_ipaddr {hwaddr {varname ""}} {
    set hwaddr [string map {- "" : ""} $hwaddr]
    foreach arp [GetIpNetTable 0] {
        if {[lindex $arp 3] == 2} continue;       # Invalid entry type
        if {[string equal $hwaddr [_hwaddr_binary_to_string [lindex $arp 1] ""]]} {
            set result [lindex $arp 2]
            break
        }
    }

    # If could not get from ARP table, see if it is one of our own
    # Ignore errors
    if {![info exists result]} {
        foreach ifc [get_network_adapters] {
            catch {
                array set netifinfo [get_network_adapter_info $ifc -unicastaddresses -physicaladdress]
                if {$netifinfo(-physicaladdress) eq ""} continue
                set ifhwaddr [string map {- ""} $netifinfo(-physicaladdress)]
                if {[string equal -nocase $hwaddr $ifhwaddr]} {
                    foreach elem $netifinfo(-unicastaddresses) {
                        if {[dict get $elem -address] ne ""} {
                            set result [dict get $elem -address]
                            break
                        }
                    }
                }
            }
            if {[info exists result]} {
                break
            }
        }
    }

    if {[info exists result]} {
        if {$varname == ""} {
            return $result
        }
        upvar $varname var
        set var $result
        return 1
    } else {
        if {$varname == ""} {
            error "Could not map hardware address $hwaddr to an IP address"
        }
        return 0
    }
}

# Flush the arp table for a given interface
proc twapi::flush_arp_tables {args} {
    if {[llength $args] == 0} {
        set args [get_network_adapters]
    }
    foreach arg $args {
        array set ifc [get_network_adapter_info $arg -type -ipv4ifindex]
        if {$ifc(-type) != 24} {
            trap {
                FlushIpNetTable $ifc(-ipv4ifindex)
            } onerror {} {
                # Ignore - flush not supported for that interface type
            }
        }
    }
}

# Return the list of TCP connections
twapi::proc* twapi::get_tcp_connections {args} {
    variable tcp_statenames
    variable tcp_statevalues

    array set tcp_statevalues {
        closed            1
        listen            2
        syn_sent          3
        syn_rcvd          4
        estab             5
        fin_wait1         6
        fin_wait2         7
        close_wait        8
        closing           9
        last_ack         10
        time_wait        11
        delete_tcb       12
    }
    foreach {name val} [array get tcp_statevalues] {
        set tcp_statenames($val) $name
    }
} {
    variable tcp_statenames
    variable tcp_statevalues

    array set opts [parseargs args {
        state
        {ipversion.arg 0}
        localaddr
        remoteaddr
        localport
        remoteport
        pid
        modulename
        modulepath
        bindtime
        all
        matchstate.arg
        matchlocaladdr.arg
        matchremoteaddr.arg
        matchlocalport.int
        matchremoteport.int
        matchpid.int
    } -maxleftover 0]

    set opts(ipversion) [_ipversion_to_af $opts(ipversion)]

    if {! ($opts(state) || $opts(localaddr) || $opts(remoteaddr) || $opts(localport) || $opts(remoteport) || $opts(pid) || $opts(modulename) || $opts(modulepath) || $opts(bindtime))} {
        set opts(all) 1
    }

    # Convert state to appropriate symbol if necessary
    if {[info exists opts(matchstate)]} {
        set matchstates [list ]
        foreach stateval $opts(matchstate) {
            if {[info exists tcp_statevalues($stateval)]} {
                lappend matchstates $stateval
                continue
            }
            if {[info exists tcp_statenames($stateval)]} {
                lappend matchstates $tcp_statenames($stateval)
                continue
            }
            error "Unrecognized connection state '$stateval' specified for option -matchstate"
        }
    }

    foreach opt {matchlocaladdr matchremoteaddr} {
        if {[info exists opts($opt)]} {
            # Note this also normalizes the address format
            set $opt [_hosts_to_ip_addrs $opts($opt)]
            if {[llength [set $opt]] == 0} {
                return [list ]; # No addresses, so no connections will match
            }
        }
    }

    # Get the complete list of connections
    if {$opts(modulename) || $opts(modulepath) || $opts(bindtime) || $opts(all)} {
        set level 8
    } else {
        set level 5
    }

    # See if any matching needs to be done
    if {[info exists opts(matchlocaladdr)] || [info exists opts(matchlocalport)] ||
        [info exist opts(matchremoteaddr)] || [info exists opts(matchremoteport)] ||
        [info exists opts(matchpid)] || [info exists opts(matchstate)]} {
        set need_matching 1
    } else {
        set need_matching 0
    }
        

    set conns [list ]
    foreach entry [_get_all_tcp 0 $level $opts(ipversion)] {
        lassign $entry state localaddr localport remoteaddr remoteport pid bindtime modulename modulepath

        if {[string equal $remoteaddr 0.0.0.0]} {
            # Socket not connected. WIndows passes some random value
            # for remote port in this case. Set it to 0
            set remoteport 0
        }

        if {[info exists tcp_statenames($state)]} {
            set state $tcp_statenames($state)
        }
        if {$need_matching} {
            if {[info exists opts(matchpid)]} {
                # See if this platform even returns the PID
                if {$pid == ""} {
                    error "Connection process id not available on this system."
                }
                if {$pid != $opts(matchpid)} {
                    continue
                }
            }
            if {[info exists matchlocaladdr] &&
                [lsearch -exact $matchlocaladdr $localaddr] < 0} {
                # Not in match list
                continue
            }
            if {[info exists matchremoteaddr] &&
                [lsearch -exact $matchremoteaddr $remoteaddr] < 0} {
                # Not in match list
                continue
            }
            if {[info exists opts(matchlocalport)] &&
                $opts(matchlocalport) != $localport} {
                continue
            }
            if {[info exists opts(matchremoteport)] &&
                $opts(matchremoteport) != $remoteport} {
                continue
            }
            if {[info exists matchstates] && [lsearch -exact $matchstates $state] < 0} {
                continue
            }
        }

        # OK, now we have matched. Include specified fields in the result
        set conn [list ]
        foreach opt {localaddr localport remoteaddr remoteport state pid bindtime modulename modulepath} {
            if {$opts(all) || $opts($opt)} {
                lappend conn [set $opt]
            }
        }
        lappend conns $conn
    }

    # ORDER MUST MATCH ORDER ABOVE
    set fields [list ]
    foreach opt {localaddr localport remoteaddr remoteport state pid bindtime modulename modulepath} {
        if {$opts(all) || $opts($opt)} {
            lappend fields -$opt
        }
    }

    return [list $fields $conns]
}


# Return the list of UDP connections
proc twapi::get_udp_connections {args} {
    array set opts [parseargs args {
        {ipversion.arg 0}
        localaddr
        localport
        pid
        modulename
        modulepath
        bindtime
        all
        matchlocaladdr.arg
        matchlocalport.int
        matchpid.int
    } -maxleftover 0]

    set opts(ipversion) [_ipversion_to_af $opts(ipversion)]

    if {! ($opts(localaddr) || $opts(localport) || $opts(pid) || $opts(modulename) || $opts(modulepath) || $opts(bindtime))} {
        set opts(all) 1
    }

    if {[info exists opts(matchlocaladdr)]} {
        # Note this also normalizes the address format
        set matchlocaladdr [_hosts_to_ip_addrs $opts(matchlocaladdr)]
        if {[llength $matchlocaladdr] == 0} {
            return [list ]; # No addresses, so no connections will match
        }
    }

    # Get the complete list of connections
    # Get the complete list of connections
    if {$opts(modulename) || $opts(modulepath) || $opts(bindtime) || $opts(all)} {
        set level 2
    } else {
        set level 1
    }
    set conns [list ]
    foreach entry [_get_all_udp 0 $level $opts(ipversion)] {
        foreach {localaddr localport pid bindtime modulename modulepath} $entry {
            break
        }
        if {[info exists opts(matchpid)]} {
            # See if this platform even returns the PID
            if {$pid == ""} {
                error "Connection process id not available on this system."
            }
            if {$pid != $opts(matchpid)} {
                continue
            }
        }
        if {[info exists matchlocaladdr] &&
            [lsearch -exact $matchlocaladdr $localaddr] < 0} {
            continue
        }
        if {[info exists opts(matchlocalport)] &&
            $opts(matchlocalport) != $localport} {
            continue
        }

        # OK, now we have matched. Include specified fields in the result
        set conn [list ]
        foreach opt {localaddr localport pid bindtime modulename modulepath} {
            if {$opts(all) || $opts($opt)} {
                lappend conn [set $opt]
            }
        }
        lappend conns $conn
    }

    # ORDER MUST MATCH THAT ABOVE
    set fields [list ]
    foreach opt {localaddr localport pid bindtime modulename modulepath} {
        if {$opts(all) || $opts($opt)} {
            lappend fields -$opt
        }
    }

    return [list $fields $conns]
}

# Terminates a TCP connection. Does not generate an error if connection
# does not exist
proc twapi::terminate_tcp_connections {args} {
    array set opts [parseargs args {
        matchstate.arg
        matchlocaladdr.arg
        matchremoteaddr.arg
        matchlocalport.int
        matchremoteport.int
        matchpid.int
    } -maxleftover 0]

    # TBD - ignore 'no such connection' errors

    # If local and remote endpoints fully specified, just directly call
    # SetTcpEntry. Note pid must NOT be specified since we must then
    # fall through and check for that pid
    if {[info exists opts(matchlocaladdr)] && [info exists opts(matchlocalport)] &&
        [info exists opts(matchremoteaddr)] && [info exists opts(matchremoteport)] &&
        ! [info exists opts(matchpid)]} {
        # 12 is "delete" code
        catch {
            SetTcpEntry [list 12 $opts(matchlocaladdr) $opts(matchlocalport) $opts(matchremoteaddr) $opts(matchremoteport)]
        }
        return
    }

    # Get connection list and go through matching on each
    # TBD - optimize by precalculating if *ANY* matching is to be done
    # and if not, skip the whole matching sequence
    foreach conn [twapi::recordarray getlist [get_tcp_connections {*}[_get_array_as_options opts]] -format dict] {
        array set aconn $conn
        # TBD - should we handle integer values of opts(state) ?
        if {[info exists opts(matchstate)] &&
            $opts(matchstate) != $aconn(-state)} {
            continue
        }
        if {[info exists opts(matchlocaladdr)] &&
            $opts(matchlocaladdr) != $aconn(-localaddr)} {
            continue
        }
        if {[info exists opts(matchlocalport)] &&
            $opts(matchlocalport) != $aconn(-localport)} {
            continue
        }
        if {[info exists opts(matchremoteaddr)] &&
            $opts(matchremoteaddr) != $aconn(-remoteaddr)} {
            continue
        }
        if {[info exists opts(remoteport)] &&
            $opts(matchremoteport) != $aconn(-remoteport)} {
            continue
        }
        if {[info exists opts(matchpid)] &&
            $opts(matchpid) != $aconn(-pid)} {
            continue
        }
        # Matching conditions fulfilled
        # 12 is "delete" code
        catch {
            SetTcpEntry [list 12 $aconn(-localaddr) $aconn(-localport) $aconn(-remoteaddr) $aconn(-remoteport)]
        }
    }
    return
}

# Flush cache of host names and ports.
# Backward compatibility - no op since we no longer have a cache
proc twapi::flush_network_name_cache {} {}

# IP addr -> hostname
proc twapi::resolve_address {addr args} {

    # flushcache is ignored (for backward compatibility only)
    array set opts [parseargs args {
        flushcache
        async.arg
    } -maxleftover 0]

    # Note as a special case, we treat 0.0.0.0 explicitly since
    # win32 getnameinfo translates this to the local host name which
    # is completely bogus.
    if {$addr eq "0.0.0.0"} {
        if {[info exists opts(async)]} {
            after idle [list after 0 $opts(async) [list $addr success $addr]]
            return ""
        } else {
            return $addr
        }
    }

    # If async option, we will call back our internal function which
    # will update the cache and then invoke the caller's script
    if {[info exists opts(async)]} {
        variable _address_handler_scripts
        set id [Twapi_ResolveAddressAsync $addr]
        set _address_handler_scripts($id) [list $addr $opts(async)]
        return ""
    }

    # Synchronous
    set name [lindex [twapi::getnameinfo [list $addr] 8] 0]
    if {$name eq $addr} {
        # Could not resolve.
        set name ""
    }

    return $name
}

# host name -> IP addresses
proc twapi::resolve_hostname {name args} {
    set name [string tolower $name]

    # -flushcache option ignored (for backward compat only)
    array set opts [parseargs args {
        flushcache
        async.arg
        {ipversion.arg 0}
    } -maxleftover 0]

    set opts(ipversion) [_ipversion_to_af $opts(ipversion)]
    set flags 0
    if {[min_os_version 6] && $opts(ipversion) == 0} {
        # IPv6 not returned if AF_UNSPEC specified unless AI_ALL is set
        set flags 0x100;        # AI_ALL
    }

    # If async option, we will call back our internal function which
    # will update the cache and then invoke the caller's script
    if {[info exists opts(async)]} {
        variable _hostname_handler_scripts
        set id [Twapi_ResolveHostnameAsync $name $opts(ipversion) $flags]
        set _hostname_handler_scripts($id) [list $name $opts(async)]
        return ""
    }

    # Resolve address synchronously
    set addrs [list ]
    trap {
        foreach endpt [twapi::getaddrinfo $name 0 $opts(ipversion) 0 0 $flags] {
            lappend addrs [lindex $endpt 0]
        }
    } onerror {TWAPI_WIN32 11001} {
        # Ignore - 11001 -> no such host, so just return empty list
    } onerror {TWAPI_WIN32 11002} {
        # Ignore - 11002 -> no such host, non-authoritative
    } onerror {TWAPI_WIN32 11003} {
        # Ignore - 11001 -> no such host, non recoverable
    } onerror {TWAPI_WIN32 11004} {
        # Ignore - 11004 -> no such host, though valid syntax
    }

    return $addrs
}

# Look up a port name
proc twapi::port_to_service {port} {
    set name ""
    trap {
        set name [lindex [twapi::getnameinfo [list 0.0.0.0 $port] 2] 1]
	if {[string is integer $name] && $name == $port} {
	    # Some platforms return the port itself if no name exists
	    set name ""
	}
    } onerror {TWAPI_WIN32 11001} {
        # Ignore - 11001 -> no such host, so just return empty list
    } onerror {TWAPI_WIN32 11002} {
        # Ignore - 11002 -> no such host, non-authoritative
    } onerror {TWAPI_WIN32 11003} {
        # Ignore - 11001 -> no such host, non recoverable
    } onerror {TWAPI_WIN32 11004} {
        # Ignore - 11004 -> no such host, though valid syntax
    }

    # If we did not get a name back, check for some well known names
    # that windows does not translate. Note some of these are names
    # that windows does translate in the reverse direction!
    if {$name eq ""} {
        foreach {p n} {
            123 ntp
            137 netbios-ns
            138 netbios-dgm
            500 isakmp
            1900 ssdp
            4500 ipsec-nat-t
        } {
            if {$port == $p} {
                set name $n
                break
            }
        }
    }

    return $name
}


# Port name -> number
proc twapi::service_to_port {name} {

    # TBD - add option for specifying protocol
    set protocol 0

    if {[string is integer $name]} {
        return $name
    }

    if {[catch {
        # Return the first port
        set port [lindex [lindex [twapi::getaddrinfo "" $name $protocol] 0] 1]
    }]} {
        set port ""
    }
    return $port
}

# Get the routing table
proc twapi::get_routing_table {args} {
    array set opts [parseargs args {
        sort
    } -maxleftover 0]

    set routes [list ]
    foreach route [twapi::GetIpForwardTable $opts(sort)] {
        lappend routes [_format_route $route]
    }

    return $routes
}

# Get the best route for given destination
proc twapi::get_route {args} {
    array set opts [parseargs args {
        {dest.arg 0.0.0.0}
        {source.arg 0.0.0.0}
    } -maxleftover 0]
    return [_format_route [GetBestRoute $opts(dest) $opts(source)]]
}

# Get the interface for a destination
proc twapi::get_outgoing_interface {{dest 0.0.0.0}} {
    return [GetBestInterfaceEx $dest]
}

proc twapi::get_ipaddr_version {addr} {
    set af [Twapi_IPAddressFamily $addr]
    if {$af == 2} {
        return 4
    } elseif {$af == 23} {
        return 6
    } else {
        return 0
    }
}

################################################################
# Utility procs

# Convert a route as returned by C code to Tcl format route
proc twapi::_format_route {route} {
    foreach fld {
        addr
        mask
        policy
        nexthop
        ifindex
        type
        protocol
        age
        nexthopas
        metric1
        metric2
        metric3
        metric4
        metric5
    } val $route {
        set r(-$fld) $val
    }

    switch -exact -- $r(-type) {
        2       { set r(-type) invalid }
        3       { set r(-type) local }
        4       { set r(-type) remote }
        1       -
        default { set r(-type) other }
    }

    switch -exact -- $r(-protocol) {
        2 { set r(-protocol) local }
        3 { set r(-protocol) netmgmt }
        4 { set r(-protocol) icmp }
        5 { set r(-protocol) egp }
        6 { set r(-protocol) ggp }
        7 { set r(-protocol) hello }
        8 { set r(-protocol) rip }
        9 { set r(-protocol) is_is }
        10 { set r(-protocol) es_is }
        11 { set r(-protocol) cisco }
        12 { set r(-protocol) bbn }
        13 { set r(-protocol) ospf }
        14 { set r(-protocol) bgp }
        1       -
        default { set r(-protocol) other }
    }

    return [array get r]
}


# Convert binary hardware address to string format
proc twapi::_hwaddr_binary_to_string {b {joiner -}} {
    if {[binary scan $b H* str]} {
        set s ""
        foreach {x y} [split $str ""] {
            lappend s $x$y
        }
        return [join $s $joiner]
    } else {
        error "Could not convert binary hardware address"
    }
}

# Callback for address resolution
proc twapi::_address_resolve_handler {id status hostname} {
    variable _address_handler_scripts

    if {![info exists _address_handler_scripts($id)]} {
        # Queue a background error
        after 0 [list error "Error: No entry found for id $id in address request table"]
        return
    }
    lassign  $_address_handler_scripts($id)  addr script
    unset _address_handler_scripts($id)

    # Before invoking the callback, store result if available
    uplevel #0 [linsert $script end $addr $status $hostname]
    return
}

# Callback for hostname resolution
proc twapi::_hostname_resolve_handler {id status addrandports} {
    variable _hostname_handler_scripts

    if {![info exists _hostname_handler_scripts($id)]} {
        # Queue a background error
        after 0 [list error "Error: No entry found for id $id in hostname request table"]
        return
    }
    lassign  $_hostname_handler_scripts($id)  name script
    unset _hostname_handler_scripts($id)

    set addrs {}
    if {$status eq "success"} {
        foreach addr $addrandports {
            lappend addrs [lindex $addr 0]
        }
    } elseif {$addrandports == 11001 || $addrandports == 11004} {
        # For compatibility with the sync version and address resolution,
        # We return an success if empty list if in fact the failure was
        # that no name->address mapping exists
        set status success
    }

    uplevel #0 [linsert $script end $name $status $addrs]
    return
}

# Return list of all TCP connections
# Uses GetExtendedTcpTable if available, else AllocateAndGetTcpExTableFromStack
# $level is passed to GetExtendedTcpTable and dtermines format of returned
# data. Level 5 (default) matches what AllocateAndGetTcpExTableFromStack
# returns. Note level 6 and higher is two orders of magnitude more expensive
# to get for IPv4 and crashes in Windows for IPv6 (silently downgraded to
# level 5 for IPv6)
twapi::proc* twapi::_get_all_tcp {sort level address_family} {
    variable _tcp_buf
    set _tcp_buf(ptr) NULL
    set _tcp_buf(size) 0
} {
    variable _tcp_buf

    if {$address_family == 0} {
        return [concat [_get_all_tcp $sort $level 2] [_get_all_tcp $sort $level 23]]
    }

    if {$address_family == 23 && $level > 5} {
        set level 5;            # IPv6 crashes for levels > 5 - Windows bug
    }

    # Get required size of buffer. This also verifies that the
    # GetExtendedTcpTable API exists on this system
    # TBD - modify to do this check only once and not on every call

    if {[catch {twapi::GetExtendedTcpTable $_tcp_buf(ptr) $_tcp_buf(size) $sort $address_family $level} bufsz]} {
        # No workee, try AllocateAndGetTcpExTableFromStack
        # Note if GetExtendedTcpTable is not present, ipv6 is not
        # available
        if {$address_family == 2} {
            return [AllocateAndGetTcpExTableFromStack $sort 0]
        } else {
            return {}
        }
    }

    # The required buffer size might change as connections
    # are added or deleted. So we sit in a loop.
    # Non-0 value indicates buffer was not large enough
    # For safety, we only retry 10 times
    set i 0
    while {$bufsz && [incr i] <= 10} {
        if {! [pointer_null? $_tcp_buf(ptr)]} {
            free $_tcp_buf(ptr)
            set _tcp_buf(ptr) NULL
            set _tcp_buf(size) 0
        }
        
        set _tcp_buf(ptr) [malloc $bufsz]
        set _tcp_buf(size) $bufsz

        set bufsz [GetExtendedTcpTable $_tcp_buf(ptr) $_tcp_buf(size) $sort $address_family $level]
    }

    if ($bufsz) {
        # Repeated attempts failed
        win32_error 122
    }

    return [Twapi_FormatExtendedTcpTable $_tcp_buf(ptr) $address_family $level]
}

# See comments for _get_all_tcp above except this is for _get_all_udp
twapi::proc* twapi::_get_all_udp {sort level address_family} {
    variable _udp_buf
    set _udp_buf(ptr) NULL
    set _udp_buf(size) 0
} {
    variable _udp_buf

    if {$address_family == 0} {
        return [concat [_get_all_udp $sort $level 2] [_get_all_udp $sort $level 23]]
    }

    if {$address_family == 23 && $level > 5} {
        set level 5;            # IPv6 crashes for levels > 5 - Windows bug
    }

    # Get required size of buffer. This also verifies that the
    # GetExtendedTcpTable API exists on this system
    if {[catch {twapi::GetExtendedUdpTable $_udp_buf(ptr) $_udp_buf(size) $sort $address_family $level} bufsz]} {
        # No workee, try AllocateAndGetUdpExTableFromStack
        if {$address_family == 2} {
            return [AllocateAndGetUdpExTableFromStack $sort 0]
        } else {
            return {}
        }
    }

    # The required buffer size might change as connections
    # are added or deleted. So we sit in a loop.
    # Non-0 value indicates buffer was not large enough
    # For safety, we only retry 10 times
    set i 0
    while {$bufsz && [incr i] <= 10} {
        if {! [pointer_null? $_udp_buf(ptr)]} {
            free $_udp_buf(ptr)
            set _udp_buf(ptr) NULL
            set _udp_buf(size) 0
        }
        
        set _udp_buf(ptr) [malloc $bufsz]
        set _udp_buf(size) $bufsz

        set bufsz [GetExtendedUdpTable $_udp_buf(ptr) $_udp_buf(size) $sort $address_family $level]
    }

    if ($bufsz) {
        # Repeated attempts failed
        win32_error 122
    }

    return [Twapi_FormatExtendedUdpTable $_udp_buf(ptr) $address_family $level]
}


# valid IP address
proc twapi::_valid_ipaddr_format {ipaddr} {
    return [expr {[Twapi_IPAddressFamily $ipaddr] != 0}]
}

# Given lists of IP addresses and DNS names, returns
# a list purely of IP addresses in normalized form
proc twapi::_hosts_to_ip_addrs hosts {
    set addrs [list ]
    foreach host $hosts {
        if {[_valid_ipaddr_format $host]} {
            lappend addrs [Twapi_NormalizeIPAddress $host]
        } else {
            # Not IP address. Try to resolve, ignoring errors
            if {![catch {resolve_hostname $host} hostaddrs]} {
                foreach addr $hostaddrs {
                    lappend addrs [Twapi_NormalizeIPAddress $addr]
                }
            }
        }
    }
    return $addrs
}

proc twapi::_ipversion_to_af {opt} {
    if {[string is integer -strict $opt]} {
        incr opt 0;             # Normalize ints for switch
    }
    switch -exact -- [string tolower $opt] {
        4 -
        inet  { return 2 }
        6 -
        inet6 { return 23 }
        0 -
        any -
        all   { return 0 }
    }
    error "Invalid IP version '$opt'"
}
