#
# Copyright (c) 2003-2014, Ashok P. Nadkarni
# All rights reserved.
#
# See the file LICENSE for license

namespace eval twapi {
}

#
# Return list of toplevel performance objects
proc twapi::pdh_enumerate_objects {args} {

    array set opts [parseargs args {
        datasource.arg
        machine.arg
        {detail.arg wizard}
        refresh
    } -nulldefault]
    
    # TBD - PdhEnumObjects enables the SeDebugPrivilege the first time it
    # is called. Should we reset it if it was not already enabled?
    # This seems to only happen on the first call

    return [PdhEnumObjects $opts(datasource) $opts(machine) \
                [_perf_detail_sym_to_val $opts(detail)] \
                $opts(refresh)]
}

proc twapi::_pdh_enumerate_object_items_helper {selector objname args} {
    array set opts [parseargs args {
        datasource.arg
        machine.arg
        {detail.arg wizard}
        refresh
    } -nulldefault]
    
    if {$opts(refresh)} {
        _refresh_perf_objects $opts(machine) $opts(datasource)
    }

    return [PdhEnumObjectItems $opts(datasource) $opts(machine) \
                $objname \
                [_perf_detail_sym_to_val $opts(detail)] \
                $selector]
}

interp alias {} twapi::pdh_enumerate_object_items {} twapi::_pdh_enumerate_object_items_helper 0
interp alias {} twapi::pdh_enumerate_object_counters {} twapi::_pdh_enumerate_object_items_helper 1
interp alias {} twapi::pdh_enumerate_object_instances {} twapi::_pdh_enumerate_object_items_helper 2


#
# Construct a counter path
proc twapi::pdh_counter_path {object counter args} {
    array set opts [parseargs args {
        machine.arg
        instance.arg
        parent.arg
        {instanceindex.int -1}
        {localized.bool false}
    } -nulldefault]
    
    if {$opts(instanceindex) == 0} {
        # For XP. For first instance (index 0), the path should not contain
        # "#0" but on XP it does. Reset it to -1 for Vista+ consistency
        set opts(instanceindex) -1
    }


    if {! $opts(localized)} {
        # Need to localize the counter names
        set object [_pdh_localize $object]
        set counter [_pdh_localize $counter]
        # TBD - not sure we need to localize parent
        set opts(parent) [_pdh_localize $opts(parent)]
    }

    # TBD - add options PDH_PATH_WBEM as documented in PdhMakeCounterPath
    return [PdhMakeCounterPath $opts(machine) $object $opts(instance) \
                $opts(parent) $opts(instanceindex) $counter 0]

}

#
# Parse a counter path and return the individual elements
proc twapi::pdh_parse_counter_path {counter_path} {
    return [twine {machine object instance parent instanceindex counter} [PdhParseCounterPath $counter_path 0]]
}


interp alias {} twapi::pdh_get_scalar {} twapi::_pdh_get 1
interp alias {} twapi::pdh_get_array {} twapi::_pdh_get 0

proc twapi::_pdh_get {scalar hcounter args} {

    array set opts [parseargs args {
        {format.arg large {long large double}}
        {scale.arg {} {{} none x1000 nocap100}}
        var.arg
    } -ignoreunknown -nulldefault]
    
    set flags [_pdh_fmt_sym_to_val $opts(format)]

    if {$opts(scale) ne ""} {
        set flags [expr {$flags | [_pdh_fmt_sym_to_val $opts(scale)]}]
    }

    set status 1
    set result ""
    trap {
        if {$scalar} {
            set result [PdhGetFormattedCounterValue $hcounter $flags]
        } else {
            set result [PdhGetFormattedCounterArray $hcounter $flags]
        }
    } onerror {TWAPI_WIN32 0x800007d1} {
        # Error is that no such instance exists.
        # If result is being returned in a variable, then
        # we will not generate an error but pass back a return value
        # of 0
        if {[string length $opts(var)] == 0} {
            rethrow
        }
        set status 0
    }
    
    if {[string length $opts(var)]} {
        uplevel [list set $opts(var) $result]
        return $status
    } else {
        return $result
    }
}

#
# Get the value of a counter identified by the path.
# Should not be used to collect
# rate based options.
# TBD - document
proc twapi::pdh_counter_path_value {counter_path args} {

    array set opts [parseargs args {
        {format.arg long}
        scale.arg
        datasource.arg
        var.arg
        full.bool
    } -nulldefault]
    
    # Open the query
    set hquery [pdh_query_open -datasource $opts(datasource)]
    trap {
        set hcounter [pdh_add_counter $hquery $counter_path]
        pdh_query_refresh $hquery
        if {[string length $opts(var)]} {
            # Need to pass up value in a variable if so requested
            upvar $opts(var) myvar
            set opts(var) myvar
        }
        set value [pdh_get_scalar $hcounter -format $opts(format) \
                       -scale $opts(scale) -full $opts(full) \
                       -var $opts(var)]
    } finally {
        pdh_query_close $hquery
    }

    return $value
}


#
# Constructs one or more counter paths for getting process information. 
# Returned as a list of sublists. Each sublist corresponds to a counter path 
# and has the form {counteroptionname datatype counterpath rate}
# datatype is the recommended format when retrieving counter value (eg. double)
# rate is 0 or 1 depending on whether the counter is a rate based counter or 
# not (requires at least two readings when getting the value)
proc twapi::get_perf_process_counter_paths {pids args} {
    variable _process_counter_opt_map

    if {![info exists _counter_opt_map]} {
        #  "descriptive string" format rate
        array set _process_counter_opt_map {
            privilegedutilization {"% Privileged Time"   double 1}
            processorutilization  {"% Processor Time"    double 1}
            userutilization       {"% User Time"         double 1}
            parent                {"Creating Process ID" long   0}
            elapsedtime           {"Elapsed Time"        large  0}
            handlecount           {"Handle Count"        long   0}
            pid                   {"ID Process"          long   0}
            iodatabytesrate       {"IO Data Bytes/sec"   large  1}
            iodataopsrate         {"IO Data Operations/sec"  large 1}
            iootherbytesrate      {"IO Other Bytes/sec"      large 1}
            iootheropsrate        {"IO Other Operations/sec" large 1}
            ioreadbytesrate       {"IO Read Bytes/sec"       large 1}
            ioreadopsrate         {"IO Read Operations/sec"  large 1}
            iowritebytesrate      {"IO Write Bytes/sec"      large 1}
            iowriteopsrate        {"IO Write Operations/sec" large 1}
            pagefaultrate         {"Page Faults/sec"         large 1}
            pagefilebytes         {"Page File Bytes"         large 0}
            pagefilebytespeak     {"Page File Bytes Peak"    large 0}
            poolnonpagedbytes     {"Pool Nonpaged Bytes"     large 0}
            poolpagedbytes        {"Pool Paged Bytes"        large 1}
            basepriority          {"Priority Base"           large 1}
            privatebytes          {"Private Bytes"           large 1}
            threadcount           {"Thread Count"            large 1}
            virtualbytes          {"Virtual Bytes"           large 1}
            virtualbytespeak      {"Virtual Bytes Peak"      large 1}
            workingset            {"Working Set"             large 1}
            workingsetpeak        {"Working Set Peak"        large 1}
        }
    }

    set optdefs {
        machine.arg
        datasource.arg
        all
        refresh
    }

    # Add counter names to option list
    foreach cntr [array names _process_counter_opt_map] {
        lappend optdefs $cntr
    }

    # Parse options
    array set opts [parseargs args $optdefs -nulldefault]

    # Force a refresh of object items
    if {$opts(refresh)} {
        # Silently ignore. The above counters are predefined and refreshing
        # is just a time-consuming no-op. Keep the option for backward
        # compatibility
        if {0} {
            _refresh_perf_objects $opts(machine) $opts(datasource)
        }
    }

    # TBD - could we not use get_perf_instance_counter_paths instead of rest of this code

    # Get the path to the process.
    set pid_paths [get_perf_counter_paths \
                       [_pdh_localize "Process"] \
                       [list [_pdh_localize "ID Process"]] \
                       $pids \
                       -machine $opts(machine) -datasource $opts(datasource) \
                       -all]

    if {[llength $pid_paths] == 0} {
        # No thread
        return [list ]
    }

    # Construct the requested counter paths
    set counter_paths [list ]
    foreach {pid pid_path} $pid_paths {

        # We have to filter out an entry for _Total which might be present
        # if pid includes "0"
        # TBD - does _Total need to be localized?
        if {$pid == 0 && [string match -nocase *_Total\#0* $pid_path]} {
            continue
        }

        # Break it down into components and store in array
        array set path_components [pdh_parse_counter_path $pid_path]

        # Construct counter paths for this pid
        foreach {opt counter_info} [array get _process_counter_opt_map] {
            if {$opts(all) || $opts($opt)} {
                lappend counter_paths \
                    [list -$opt $pid [lindex $counter_info 1] \
                         [pdh_counter_path $path_components(object) \
                              [_pdh_localize [lindex $counter_info 0]] \
                              -localized true \
                              -machine $path_components(machine) \
                              -parent $path_components(parent) \
                              -instance $path_components(instance) \
                              -instanceindex $path_components(instanceindex)] \
                         [lindex $counter_info 2] \
                        ]
            }
        }                        
    }

    return $counter_paths
}


# Returns the counter path for the process with the given pid. This includes
# the pid counter path element
proc twapi::get_perf_process_id_path {pid args} {
    return [get_unique_counter_path \
                [_pdh_localize "Process"] \
                [_pdh_localize "ID Process"] $pid]
}


#
# Constructs one or more counter paths for getting thread information. 
# Returned as a list of sublists. Each sublist corresponds to a counter path 
# and has the form {counteroptionname datatype counterpath rate}
# datatype is the recommended format when retrieving counter value (eg. double)
# rate is 0 or 1 depending on whether the counter is a rate based counter or 
# not (requires at least two readings when getting the value)
proc twapi::get_perf_thread_counter_paths {tids args} {
    variable _thread_counter_opt_map

    if {![info exists _thread_counter_opt_map]} {
        array set _thread_counter_opt_map {
            privilegedutilization {"% Privileged Time"       double 1}
            processorutilization  {"% Processor Time"        double 1}
            userutilization       {"% User Time"             double 1}
            contextswitchrate     {"Context Switches/sec"    long 1}
            elapsedtime           {"Elapsed Time"            large 0}
            pid                   {"ID Process"              long 0}
            tid                   {"ID Thread"               long 0}
            basepriority          {"Priority Base"           long 0}
            priority              {"Priority Current"        long 0}
            startaddress          {"Start Address"           large 0}
            state                 {"Thread State"            long 0}
            waitreason            {"Thread Wait Reason"      long 0}
        }
    }

    set optdefs {
        machine.arg
        datasource.arg
        all
        refresh
    }

    # Add counter names to option list
    foreach cntr [array names _thread_counter_opt_map] {
        lappend optdefs $cntr
    }

    # Parse options
    array set opts [parseargs args $optdefs -nulldefault]

    # Force a refresh of object items
    if {$opts(refresh)} {
        # Silently ignore. The above counters are predefined and refreshing
        # is just a time-consuming no-op. Keep the option for backward
        # compatibility
        if {0} {
            _refresh_perf_objects $opts(machine) $opts(datasource)
        }
    }

    # TBD - could we not use get_perf_instance_counter_paths instead of rest of this code

    # Get the path to the thread
    set tid_paths [get_perf_counter_paths \
                       [_pdh_localize "Thread"] \
                       [list [_pdh_localize "ID Thread"]] \
                       $tids \
                      -machine $opts(machine) -datasource $opts(datasource) \
                      -all]
    
    if {[llength $tid_paths] == 0} {
        # No thread
        return [list ]
    }

    # Now construct the requested counter paths
    set counter_paths [list ]
    foreach {tid tid_path} $tid_paths {
        # Break it down into components and store in array
        array set path_components [pdh_parse_counter_path $tid_path]
        foreach {opt counter_info} [array get _thread_counter_opt_map] {
            if {$opts(all) || $opts($opt)} {
                lappend counter_paths \
                    [list -$opt $tid [lindex $counter_info 1] \
                         [pdh_counter_path $path_components(object) \
                              [_pdh_localize [lindex $counter_info 0]] \
                              -localized true \
                              -machine $path_components(machine) \
                              -parent $path_components(parent) \
                              -instance $path_components(instance) \
                              -instanceindex $path_components(instanceindex)] \
                         [lindex $counter_info 2]
                    ]
            }
        }                            
    }

    return $counter_paths
}


# Returns the counter path for the thread with the given tid. This includes
# the tid counter path element
proc twapi::get_perf_thread_id_path {tid args} {

    return [get_unique_counter_path [_pdh_localize"Thread"] [_pdh_localize "ID Thread"] $tid]
}


#
# Constructs one or more counter paths for getting processor information. 
# Returned as a list of sublists. Each sublist corresponds to a counter path 
# and has the form {counteroptionname datatype counterpath rate}
# datatype is the recommended format when retrieving counter value (eg. double)
# rate is 0 or 1 depending on whether the counter is a rate based counter or 
# not (requires at least two readings when getting the value)
# $processor should be the processor number or "" to get total
proc twapi::get_perf_processor_counter_paths {processor args} {
    variable _processor_counter_opt_map

    if {![string is integer -strict $processor]} {
        if {[string length $processor]} {
            error "Processor id must be an integer or null to retrieve information for all processors"
        }
        set processor "_Total"
    }

    if {![info exists _processor_counter_opt_map]} {
        array set _processor_counter_opt_map {
            dpcutilization        {"% DPC Time"              double 1}
            interruptutilization  {"% Interrupt Time"        double 1}
            privilegedutilization {"% Privileged Time"       double 1}
            processorutilization  {"% Processor Time"        double 1}
            userutilization       {"% User Time"             double 1}
            dpcrate               {"DPC Rate"                double 1}
            dpcqueuerate          {"DPCs Queued/sec"         double 1}
            interruptrate         {"Interrupts/sec"          double 1}
        }
    }

    set optdefs {
        machine.arg
        datasource.arg
        all
        refresh
    }

    # Add counter names to option list
    foreach cntr [array names _processor_counter_opt_map] {
        lappend optdefs $cntr
    }

    # Parse options
    array set opts [parseargs args $optdefs -nulldefault -maxleftover 0]

    # Force a refresh of object items
    if {$opts(refresh)} {
        # Silently ignore. The above counters are predefined and refreshing
        # is just a time-consuming no-op. Keep the option for backward
        # compatibility
        if {0} {
            _refresh_perf_objects $opts(machine) $opts(datasource)
        }
    }

    # Now construct the requested counter paths
    set counter_paths [list ]
    foreach {opt counter_info} [array get _processor_counter_opt_map] {
        if {$opts(all) || $opts($opt)} {
            lappend counter_paths \
                [list $opt $processor [lindex $counter_info 1] \
                     [pdh_counter_path \
                          [_pdh_localize "Processor"] \
                          [_pdh_localize [lindex $counter_info 0]] \
                          -localized true \
                          -machine $opts(machine) \
                          -instance $processor] \
                     [lindex $counter_info 2] \
                    ]
        }
    }

    return $counter_paths
}



#
# Returns a list comprising of the counter paths for counters with
# names in the list $counters from those instance(s) whose counter
# $key_counter matches the specified $key_counter_value
proc twapi::get_perf_instance_counter_paths {object counters
                                             key_counter key_counter_values
                                             args} {
    # Parse options
    array set opts [parseargs args {
        machine.arg
        datasource.arg
        {matchop.arg "exact"}
        skiptotal.bool
        refresh
    } -nulldefault]

    # Force a refresh of object items
    if {$opts(refresh)} {
        _refresh_perf_objects $opts(machine) $opts(datasource)
    }

    # Get the list of instances that have the specified value for the
    # key counter
    set instance_paths [get_perf_counter_paths $object \
                            [list $key_counter] $key_counter_values \
                            -machine $opts(machine) \
                            -datasource $opts(datasource) \
                            -matchop $opts(matchop) \
                            -skiptotal $opts(skiptotal) \
                            -all]

    # Loop through all instance paths, and all counters to generate 
    # We store in an array to get rid of duplicates
    array set counter_paths {}
    foreach {key_counter_value instance_path} $instance_paths {
        # Break it down into components and store in array
        array set path_components [pdh_parse_counter_path $instance_path]

        # Now construct the requested counter paths
        # TBD - what should -localized be here ?
        foreach counter $counters {
            set counter_path \
                [pdh_counter_path $path_components(object) \
                     $counter \
                     -localized true \
                     -machine $path_components(machine) \
                     -parent $path_components(parent) \
                     -instance $path_components(instance) \
                     -instanceindex $path_components(instanceindex)]
            set counter_paths($counter_path) ""
        }                            
    }

    return [array names counter_paths]


}


#
# Returns a list comprising of the counter paths for all counters
# whose values match the specified criteria
proc twapi::get_perf_counter_paths {object counters counter_values args} {
    array set opts [parseargs args {
        machine.arg
        datasource.arg
        {matchop.arg "exact"}
        skiptotal.bool
        all
        refresh
    } -nulldefault]

    if {$opts(refresh)} {
        _refresh_perf_objects $opts(machine) $opts(datasource)
    }

    set items [pdh_enum_object_items $object \
                   -machine $opts(machine) \
                   -datasource $opts(datasource)]
    lassign $items object_counters object_instances

    if {[llength $counters]} {
        set object_counters $counters
    }
    set paths [_make_counter_path_list \
                   $object $object_instances $object_counters \
                   -skiptotal $opts(skiptotal) -machine $opts(machine)]
    set result_paths [list ]
    trap {
        # Set up the query with the process id for all processes
        set hquery [pdh_query_open -datasource $opts(datasource)]
        foreach path $paths {
            set hcounter [pdh_add_counter $hquery $path]
            set lookup($hcounter) $path
        }

        # Now collect the info
        pdh_query_refresh $hquery
        
        # Now lookup each counter value to find a matching one
        foreach hcounter [array names lookup] {
            if {! [pdh_get_scalar $hcounter -var value]} {
                # Counter or instance no longer exists
                continue
            }

            set match_pos [lsearch -$opts(matchop) $counter_values $value]
            if {$match_pos >= 0} {
                lappend result_paths \
                    [lindex $counter_values $match_pos] $lookup($hcounter)
                if {! $opts(all)} {
                    break
                }
            }
        }
    } finally {
        # TBD - should we have a catch to throw errors?
        pdh_query_close $hquery
    }

    return $result_paths
}


#
# Returns the counter path for counter $counter with a value $value
# for object $object. Returns "" on no matches but exception if more than one
proc twapi::get_unique_counter_path {object counter value args} {
    set matches [get_perf_counter_paths $object [list $counter ] [list $value] {*}$args -all]
    if {[llength $matches] > 1} {
        error "Multiple counter paths found matching criteria object='$object' counter='$counter' value='$value"
    }
    return [lindex $matches 0]
}



#
# Utilities
# 
proc twapi::_refresh_perf_objects {machine datasource} {
    pdh_enumerate_objects -refresh
    return
}


#
# Return the localized form of a counter name
# TBD - assumes machine is local machine!
proc twapi::_pdh_localize {name} {
    variable _perf_counter_ids
    variable _localized_perf_counter_names
    
    set name_index [string tolower $name]

    # If we already have a translation, return it
    if {[info exists _localized_perf_counter_names($name_index)]} {
        return $_localized_perf_counter_names($name_index)
    }

    # Didn't already have it. Go generate the mappings

    # Get the list of counter names in English if we don't already have it
    if {![info exists _perf_counter_ids]} {
        foreach {id label} [registry get {HKEY_PERFORMANCE_DATA} {Counter 009}] {
            set _perf_counter_ids([string tolower $label]) $id
        }
    }

    # If we have do not have id for the given name, we will just use
    # the passed name as the localized version
    if {! [info exists _perf_counter_ids($name_index)]} {
        # Does not seem to exist. Just set localized name to itself
        return [set _localized_perf_counter_names($name_index) $name]
    }

    # We do have an id. THen try to get a translated name
    if {[catch {PdhLookupPerfNameByIndex "" $_perf_counter_ids($name_index)} xname]} {
        set _localized_perf_counter_names($name_index) $name
    } else {
        set _localized_perf_counter_names($name_index) $xname
    }

    return $_localized_perf_counter_names($name_index)
}


# Given a list of instances and counters, return a cross product of the 
# corresponding counter paths.
# The list is expected to be already localized
# Example: _make_counter_path_list "Process" (instance list) {{ID Process} {...}}
# TBD - bug - does not handle -parent in counter path
proc twapi::_make_counter_path_list {object instance_list counter_list args} {
    array set opts [parseargs args {
        machine.arg
        skiptotal.bool
    } -nulldefault]

    array set instances {}
    foreach instance $instance_list {
        if {![info exists instances($instance)]} {
            set instances($instance) 1
        } else {
            incr instances($instance)
        }
    }

    if {$opts(skiptotal)} {
        catch {array unset instances "*_Total"}
    }

    set counter_paths [list ]
    foreach {instance count} [array get instances] {
        while {$count} {
            incr count -1
            foreach counter $counter_list {
                lappend counter_paths [pdh_counter_path \
                                           $object $counter \
                                           -localized true \
                                           -machine $opts(machine) \
                                           -instance $instance \
                                           -instanceindex $count]
            }
        }
    }

    return $counter_paths
}


#
# Given a set of counter paths in the format returned by 
# get_perf_thread_counter_paths, get_perf_processor_counter_paths etc.
# return the counter information as a flat list of field value pairs
proc twapi::get_perf_values_from_metacounter_info {metacounters args} {
    array set opts [parseargs args {{interval.int 100}}]

    set result [list ]
    set counters [list ]
    if {[llength $metacounters]} {
        set hquery [pdh_query_open]
        trap {
            set counter_info [list ]
            set need_wait 0
            foreach counter_elem $metacounters {
                lassign $counter_elem pdh_opt key data_type counter_path wait
                incr need_wait $wait
                set hcounter [pdh_add_counter $hquery $counter_path]
                lappend counters $hcounter
                lappend counter_info $pdh_opt $key $counter_path $data_type $hcounter
            }
            
            pdh_query_refresh $hquery
            if {$need_wait} {
                after $opts(interval)
                pdh_query_refresh $hquery
            }
            
            foreach {pdh_opt key counter_path data_type hcounter} $counter_info {
                if {[pdh_get_scalar $hcounter -format $data_type -var value]} {
                    lappend result $pdh_opt $key $value
                }
            }
        } onerror {} {
            #puts "Error: $msg"
        } finally {
            pdh_query_close $hquery
        }
    }

    return $result

}

proc twapi::pdh_query_open {args} {
    variable _pdh_queries

    array set opts [parseargs args {
        datasource.arg
        cookie.int
    } -nulldefault]

    set qh [PdhOpenQuery $opts(datasource) $opts(cookie)]
    set id pdh[TwapiId]
    dict set _pdh_queries($id) Qh $qh
    dict set _pdh_queries($id) Counters {}
    dict set _pdh_queries($id) Meta {}
    return $id
}

proc twapi::pdh_query_refresh {qid args} {
    variable _pdh_queries
    _pdh_query_check $qid
    PdhCollectQueryData [dict get $_pdh_queries($qid) Qh]
    return
}

proc twapi::pdh_query_close {qid} {
    variable _pdh_queries
    _pdh_query_check $qid

    dict for {ctrh -} [dict get $_pdh_queries($qid) Counters] {
        PdhRemoveCounter $ctrh
    }

    PdhCloseQuery [dict get $_pdh_queries($qid) Qh]
    unset _pdh_queries($qid)
}

proc twapi::pdh_add_counter {qid ctr_path args} {
    variable _pdh_queries

    _pdh_query_check $qid

    parseargs args {
        {format.arg large {long large double}}
        {scale.arg {} {{} none x1000 nocap100}}
        name.arg
        cookie.int
        array.bool
    } -nulldefault -maxleftover 0 -setvars
    
    if {$name eq ""} {
        set name $ctr_path
    }

    if {[dict exists $_pdh_queries($qid) Meta $name]} {
        error "A counter with name \"$name\" already present in the query."
    }

    set flags [_pdh_fmt_sym_to_val $format]

    if {$scale ne ""} {
        set flags [expr {$flags | [_pdh_fmt_sym_to_val $scale]}]
    }

    set hctr [PdhAddCounter [dict get $_pdh_queries($qid) Qh] $ctr_path $flags]
    dict set _pdh_queries($qid) Counters $hctr 1
    dict set _pdh_queries($qid) Meta $name [list Counter $hctr FmtFlags $flags Array $array]

    return $hctr
}

proc twapi::pdh_remove_counter {qid ctrname} {
    variable _pdh_queries
    _pdh_query_check $qid
    if {![dict exists $_pdh_queries($qid) Meta $ctrname]} {
        badargs! "Counter \"$ctrname\" not present in query."
    }
    set hctr [dict get $_pdh_queries($qid) Meta $ctrname Counter]
    dict unset _pdh_queries($qid) Counters $hctr
    dict unset _pdh_queries($qid) Meta $ctrname
    PdhRemoveCounter $hctr
    return
}

proc twapi::pdh_query_get {qid args} {
    variable _pdh_queries

    _pdh_query_check $qid

    # Refresh the data
    PdhCollectQueryData [dict get $_pdh_queries($qid) Qh]

    set meta [dict get $_pdh_queries($qid) Meta]

    if {[llength $args] != 0} {
        set names $args
    } else {
        set names [dict keys $meta]
    }        

    set result {}
    foreach name $names {
        if {[dict get $meta $name Array]} {
		lappend result $name [PdhGetFormattedCounterArray [dict get $meta $name Counter] [dict get $meta $name FmtFlags]]
	} else {
		lappend result $name [PdhGetFormattedCounterValue [dict get $meta $name Counter] [dict get $meta $name FmtFlags]]
	}
    }

    return $result
}

twapi::proc* twapi::pdh_system_performance_query args {
    variable _sysperf_defs

    set _sysperf_defs {
        event_count { {Objects Events} {} }
        mutex_count { {Objects Mutexes} {} }
        process_count { {Objects Processes} {} }
        section_count { {Objects Sections} {} }
        semaphore_count { {Objects Semaphores} {} }
        thread_count { {Objects Threads} {} }
        handle_count { {Process "Handle Count" -instance _Total} {-format long} }
        commit_limit { {Memory "Commit Limit"} {} }
        committed_bytes { {Memory "Committed Bytes"} {} }
        committed_percent { {Memory "% Committed Bytes In Use"} {-format double} }
        memory_free_mb { {Memory "Available MBytes"} {} }
        memory_free_kb { {Memory "Available KBytes"} {} }
        page_fault_rate { {Memory "Page Faults/sec"} {} }
        page_input_rate { {Memory "Pages Input/sec"} {} }
        page_output_rate { {Memory "Pages Output/sec"} {} }

        disk_bytes_rate { {PhysicalDisk "Disk Bytes/sec" -instance _Total} {} }
        disk_readbytes_rate { {PhysicalDisk "Disk Read Bytes/sec" -instance _Total} {} }
        disk_writebytes_rate { {PhysicalDisk "Disk Write Bytes/sec" -instance _Total} {} }
        disk_transfer_rate { {PhysicalDisk "Disk Transfers/sec" -instance _Total} {} }
        disk_read_rate { {PhysicalDisk "Disk Reads/sec" -instance _Total} {} }
        disk_write_rate { {PhysicalDisk "Disk Writes/sec" -instance _Total} {} }
        disk_idle_percent { {PhysicalDisk "% Idle Time" -instance _Total} {-format double} }
    }

    # Per-processor counters are based on above but the object name depends
    # on the system in order to support > 64 processors
    set obj_name [expr {[min_os_version 6 1] ? "Processor Information" : "Processor"}]
    dict for {key ctr_name} {
        interrupt_utilization "% Interrupt Time"
        privileged_utilization "% Privileged Time"
        processor_utilization  "% Processor Time"
        user_utilization "% User Time"
        idle_utilization "% Idle Time"
    } {
        lappend _sysperf_defs $key \
            [list \
                 [list $obj_name $ctr_name -instance _Total] \
                 [list -format double]]

        lappend _sysperf_defs ${key}_per_cpu \
            [list \
                 [list $obj_name $ctr_name -instance *] \
                 [list -format double -array 1]]
    }
} {
    variable _sysperf_defs

    if {[llength $args] == 0} {
        return [lsort -dictionary [dict keys $_sysperf_defs]]
    }

    set qid [pdh_query_open]
    trap {
        foreach arg $args {
            set def [dict! $_sysperf_defs $arg]
            set ctr_path [pdh_counter_path {*}[lindex $def 0]]
            pdh_add_counter $qid $ctr_path -name $arg {*}[lindex $def 1]
        }
        pdh_query_refresh $qid
    } onerror {} {
        pdh_query_close $qid
        rethrow
    }

    return $qid
}

#
# Internal utility procedures
proc twapi::_pdh_query_check {qid} {
    variable _pdh_queries 

    if {![info exists _pdh_queries($qid)]} {
        error "Invalid query id $qid"
    }
}

proc twapi::_perf_detail_sym_to_val {sym} {
    # PERF_DETAIL_NOVICE          100
    # PERF_DETAIL_ADVANCED        200
    # PERF_DETAIL_EXPERT          300
    # PERF_DETAIL_WIZARD          400
    # PERF_DETAIL_COSTLY   0x00010000
    # PERF_DETAIL_STANDARD 0x0000FFFF

    return [dict get {novice 100 advanced 200 expert 300 wizard 400 costly 0x00010000 standard 0x0000ffff } $sym]
}


proc twapi::_pdh_fmt_sym_to_val {sym} {
    # PDH_FMT_RAW     0x00000010
    # PDH_FMT_ANSI    0x00000020
    # PDH_FMT_UNICODE 0x00000040
    # PDH_FMT_LONG    0x00000100
    # PDH_FMT_DOUBLE  0x00000200
    # PDH_FMT_LARGE   0x00000400
    # PDH_FMT_NOSCALE 0x00001000
    # PDH_FMT_1000    0x00002000
    # PDH_FMT_NODATA  0x00004000
    # PDH_FMT_NOCAP100 0x00008000

    return [dict get {
        raw     0x00000010
        ansi    0x00000020
        unicode 0x00000040
        long    0x00000100
        double  0x00000200
        large   0x00000400
        noscale 0x00001000
        none    0x00001000
        1000     0x00002000
        x1000    0x00002000
        nodata  0x00004000
        nocap100 0x00008000
        nocap 0x00008000
    } $sym]
}
