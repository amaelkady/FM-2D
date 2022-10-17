#
# Copyright (c) 2012 Ashok P. Nadkarni
# All rights reserved.
#
# See the file LICENSE for license

package require twapi_com

# TBD - document?

twapi::class create ::twapi::IMofCompilerProxy {
    superclass ::twapi::IUnknownProxy

    constructor {args} {
        if {[llength $args] == 0} {
            set args [list [::twapi::com_create_instance "{6daf9757-2e37-11d2-aec9-00c04fb68820}" -interface IMofCompiler -raw]]
        }
        next {*}$args
    }

    method CompileBuffer args {
        my variable _ifc
        return [::twapi::IMofCompiler_CompileBuffer $_ifc {*}$args]
    }

    method CompileFile args {
        my variable _ifc
        return [::twapi::IMofCompiler_CompileFile $_ifc {*}$args]
    }

    method CreateBMOF args {
        my variable _ifc
        return [::twapi::IMofCompiler_CreateBMOF $_ifc {*}$args]
    }

    twapi_exportall
}


#
# Get WMI service - TBD document
proc twapi::wmi_root {args} {
    array set opts [parseargs args {
        {root.arg cimv2}
        {impersonationlevel.arg impersonate {default anonymous identify delegate impersonate} }
    } -maxleftover 0]

    # TBD - any injection attacks possible ? Need to quote ?
    return [comobj_object "winmgmts:{impersonationLevel=$opts(impersonationlevel)}!//./root/$opts(root)"]
}
# Backwards compat
proc twapi::_wmi {{top cimv2}} {
    return [wmi_root -root $top]
}

# TBD - see if using ExecQuery would be faster if it supports all the options
proc twapi::wmi_collect_classes {swbemservices args} {
    array set opts [parseargs args {
        {ancestor.arg {}}
        shallow
        first
        matchproperties.arg
        matchsystemproperties.arg
        matchqualifiers.arg
        {collector.arg {lindex}}
    } -maxleftover 0]
    
    
    # Create a forward only enumerator for efficiency
    # wbemFlagUseAmendedQualifiers | wbemFlagReturnImmediately | wbemFlagForwardOnly
    set flags 0x20030
    if {$opts(shallow)} {
        incr flags 1;           # 0x1 -> wbemQueryFlagShallow
    }

    set classes [$swbemservices SubclassesOf $opts(ancestor) $flags]
    set matches {}
    set delete_on_error {}
    twapi::trap {
        $classes -iterate class {
            set matched 1
            foreach {opt fn} {
                matchproperties Properties_
                matchsystemproperties SystemProperties_
                matchqualifiers Qualifiers_
            } {
                if {[info exists opts($opt)]} {
                    foreach {name matcher} $opts($opt) {
                        if {[catch {
                            if {! [{*}$matcher [$class -with [list [list -get $fn] [list Item $name]] Value]]} {
                                set matched 0
                                break; # Value does not match
                            }
                        } msg ]} {
                            # TBD - log debug error if not property found
                            # No such property or no access
                            set matched 0
                            break
                        }
                    }
                }
                if {! $matched} {
                    # Already failed to match, no point continuing looping
                    break
                }
            }

            if {$matched} {
                # Note collector code is responsible for disposing
                # of $class as appropriate. But we take care of deleting
                # when an error occurs after some accumulation has
                # already occurred.
                lappend delete_on_error $class
                if {$opts(first)} {
                    return [{*}$opts(collector) $class]
                } else {
                    lappend matches [{*}$opts(collector) $class]
                }
            } else {
                $class destroy
            }
        }
    } onerror {} {
        foreach class $delete_on_error {
            if {[comobj? $class]} {
                $class destroy
            }
        }
        rethrow
    } finally {
        $classes destroy
    }

    return $matches
}

proc twapi::wmi_extract_qualifier {qual} {
    foreach prop {name value isamended propagatestoinstance propagatestosubclass isoverridable} {
        dict set result $prop [$qual -get $prop]
    }
    return $result
}

proc twapi::wmi_extract_property {propobj} {
    foreach prop {name value cimtype isarray islocal origin} {
        dict set result $prop [$propobj -get $prop]
    }

    $propobj -with Qualifiers_ -iterate -cleanup qual {
        set rec [wmi_extract_qualifier $qual]
        dict set result qualifiers [string tolower [dict get $rec name]] $rec
    }

    return $result
}

proc twapi::wmi_extract_systemproperty {propobj} {
    # Separate from wmi_extract_property because system properties do not
    # have Qualifiers_
    foreach prop {name value cimtype isarray islocal origin} {
        dict set result $prop [$propobj -get $prop]
    }

    return $result
}


proc twapi::wmi_extract_method {mobj} {
    foreach prop {name origin} {
        dict set result $prop [$mobj -get $prop]
    }

    # The InParameters and OutParameters properties are SWBEMObjects
    # the properties of which describe the parameters.
    foreach inout {inparameters outparameters} {
        set paramsobj [$mobj -get $inout]
        if {[$paramsobj -isnull]} {
            dict set result $inout {}
        } else {
            $paramsobj -with Properties_ -iterate -cleanup pobj {
                set rec [wmi_extract_property $pobj]
                dict set result $inout [string tolower [dict get $rec name]] $rec
            }
        }
    }

    $mobj -with Qualifiers_ -iterate qual {
        set rec [wmi_extract_qualifier $qual]
        dict set result qualifiers [string tolower [dict get $rec name]] $rec
        $qual destroy
    }

    return $result
}


proc twapi::wmi_extract_class {obj} {
    
    set result [dict create]

    # Class qualifiers
    $obj -with Qualifiers_ -iterate -cleanup qualobj {
        set rec [wmi_extract_qualifier $qualobj]
        dict set result qualifiers [string tolower [dict get $rec name]] $rec
    }

    $obj -with Properties_ -iterate -cleanup propobj {
        set rec [wmi_extract_property $propobj]
        dict set result properties [string tolower [dict get $rec name]] $rec
    }

    $obj -with SystemProperties_ -iterate -cleanup propobj {
        set rec [wmi_extract_systemproperty $propobj]
        dict set result systemproperties [string tolower [dict get $rec name]] $rec
    }
    
    $obj -with Methods_ -iterate -cleanup mobj {
        set rec [wmi_extract_method $mobj]
        dict set result methods [string tolower [dict get $rec name]] $rec
    }

    return $result
}
