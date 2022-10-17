#
# Copyright (c) 2006-2014 Ashok P. Nadkarni
# All rights reserved.
#
# See the file LICENSE for license

# TBD - tests  comobj? works with derived classes of Automation
# TBD - document and test -iterate -cleanup option

# TBD - object identity comparison 
#   - see http://blogs.msdn.com/ericlippert/archive/2005/04/26/412199.aspx
# TBD - we seem to resolve UDT's every time a COM method is actually invoked.
# Optimize by doing it when prototype is stored or only the first time it
# is called.
# TBD - optimize by caching UDT's within a type library when the library
# is read.

namespace eval twapi {
    # Maps TYPEKIND data values to symbols
    variable _typekind_map
    array set _typekind_map {
        0 enum
        1 record
        2 module
        3 interface
        4 dispatch
        5 coclass
        6 alias
        7 union
    }

    # Cache of Interface names - IID mappings
    variable _name_to_iid_cache
    array set _name_to_iid_cache {
        iunknown  {{00000000-0000-0000-C000-000000000046}}
        idispatch {{00020400-0000-0000-C000-000000000046}}
        idispatchex {{A6EF9860-C720-11D0-9337-00A0C90DCAA9}}
        itypeinfo {{00020401-0000-0000-C000-000000000046}}
        itypecomp {{00020403-0000-0000-C000-000000000046}}
        ienumvariant {{00020404-0000-0000-C000-000000000046}}
        iprovideclassinfo {{B196B283-BAB4-101A-B69C-00AA00341D07}}

        ipersist  {{0000010c-0000-0000-C000-000000000046}}
        ipersistfile {{0000010b-0000-0000-C000-000000000046}}

        iprovidetaskpage {{4086658a-cbbb-11cf-b604-00c04fd8d565}}
        itasktrigger {{148BD52B-A2AB-11CE-B11F-00AA00530503}}
        ischeduleworkitem {{a6b952f0-a4b1-11d0-997d-00aa006887ec}}
        itask {{148BD524-A2AB-11CE-B11F-00AA00530503}}
        ienumworkitems {{148BD528-A2AB-11CE-B11F-00AA00530503}}
        itaskscheduler {{148BD527-A2AB-11CE-B11F-00AA00530503}}
        imofcompiler {{6daf974e-2e37-11d2-aec9-00c04fb68820}}
    }
}

proc twapi::IUnknown_QueryInterface {ifc iid} {
    set iidname void
    catch {set iidname [registry get HKEY_CLASSES_ROOT\\Interface\\$iid ""]}
    return [Twapi_IUnknown_QueryInterface $ifc $iid $iidname]
}

proc twapi::CoGetObject {name bindopts iid} {
    set iidname void
    catch {set iidname [registry get HKEY_CLASSES_ROOT\\Interface\\$iid ""]}
    return [Twapi_CoGetObject $name $bindopts $iid $iidname]
}

proc twapi::progid_to_clsid {progid} { return [CLSIDFromProgID $progid] }
proc twapi::clsid_to_progid {progid} { return [ProgIDFromCLSID $progid] }

proc twapi::com_security_blanket {args} {
    # mutualauth.bool - docs for EOLE_AUTHENTICATION_CAPABILITIES. Learning
    # DCOM says it is only for CoInitializeSecurity. Either way, 
    # that option is not applicable here
    parseargs args {
        {authenticationservice.arg default}
        serverprincipal.arg
        {authenticationlevel.arg default}
        {impersonationlevel.arg default}
        credentials.arg
        cloaking.arg
    } -maxleftover 0 -setvars

    set authenticationservice [_com_name_to_authsvc $authenticationservice]
    set authenticationlevel [_com_name_to_authlevel $authenticationlevel]
    set impersonationlevel [_com_name_to_impersonation $impersonationlevel]

    if {![info exists cloaking]} {
        set eoac 0x800;         # EOAC_DEFAULT
    } else {
        set eoac [dict! {none 0 static 0x20 dynamic 0x40} $cloaking]
    }

    if {[info exists credentials]} {
        # Credentials specified. Empty list -> NULL, ie use thread token
        set creds_tag 1
    } else {
        # Credentials not to be changed
        set creds_tag 0
        set credentials {};     # Ignored
    }

    if {[info exists serverprincipal]} {
        if {$serverprincipal eq ""} {
            set serverprincipaltag 0; # Default based on com_initialize_security
        } else {
            set serverprincipaltag 2
        }
    } else {
        set serverprincipaltag 1; # Unchanged server principal
        set serverprincipal ""
    }

    return [list $authenticationservice 0 $serverprincipaltag $serverprincipal $authenticationlevel $impersonationlevel $creds_tag $credentials $eoac]
}

# TBD - document
proc twapi::com_query_client_blanket {} {
    lassign [CoQueryClientBlanket] authn authz server authlevel implevel client capabilities
    if {$capabilities & 0x20} {
        # EOAC_STATIC_CLOAKING
        set cloaking static
    } elseif {$capabilities & 0x40} {
        set cloaking dynamic
    } else {
        set cloaking none
    }

    # Note there is no implevel set as CoQueryClientBlanket does
    # not return that information and implevel is a dummy value
    return [list \
                -authenticationservice [_com_authsvc_to_name $authn] \
                -authorizationservice [dict* {0 none 1 name 2 dce} $authz] \
                -serverprincipal $server \
                -authenticationlevel [_com_authlevel_to_name $authlevel] \
                -clientprincipal $client \
                -cloaking $cloaking \
               ]
}

# TBD - document
proc twapi::com_query_proxy_blanket {ifc} {
    lassign [CoQueryProxyBlanket [lindex $args 0]] authn authz server authlevel implevel client capabilities
    if {$capabilities & 0x20} {
        # EOAC_STATIC_CLOAKING
        set cloaking static
    } elseif {$capabilities & 0x40} {
        set cloaking dynamic
    } else {
        set cloaking none
    }

    return [list \
                -authenticationservice [_com_authsvc_to_name $authn] \
                -authorizationservice [dict* {0 none 1 name 2 dce} $authz] \
                -serverprincipal $server \
                -authenticationlevel [_com_authlevel_to_name $authlevel] \
                -impersonationlevel [_com_impersonation_to_name $implevel] \
                -clientprincipal $client \
                -cloaking $cloaking \
               ]
            
}

# TBD - document
proc twapi::com_initialize_security {args} {
    # TBD - mutualauth?
    # TBD - securerefs?
    parseargs args {
        {authenticationlevel.arg default}
        {impersonationlevel.arg impersonate}
        {cloaking.sym none {none 0 static 0x20 dynamic 0x40}}
        secd.arg
        appid.arg
        authenticationservices.arg
    } -maxleftover 0 -setvars
    
    if {[info exists secd] && [info exists appid]} {
        badargs! "Only one of -secd and -appid can be specified."
    }

    set impersonationlevel [_com_name_to_impersonation $impersonationlevel]
    set authenticationlevel [_com_name_to_authlevel $authenticationlevel]

    set eoac $cloaking
    if {[info exists appid]} {
        incr eoac 8;     # 8 -> EOAC_APPID
        set secarg $appid
    } else {
        if {[info exists secd]} {
            set secarg $secd
        } else {
            set secarg {}
        }
    }

    set authlist {}
    if {[info exists authenticationservices]} {
        foreach authsvc $authenticationservices {
            lappend authlist [list [_com_name_to_authsvc [lindex $authsvc 0]] 0 [lindex $authsvc 1]]
        }
    }

    CoInitializeSecurity $secarg "" "" $authenticationlevel $impersonationlevel $authlist $eoac ""
}

interp alias {} twapi::com_make_credentials {} twapi::make_logon_identity

# TBD - document
proc twapi::com_create_instance {clsid args} {
    array set opts [parseargs args {
        {model.arg any}
        download.bool
        {disablelog.bool false}
        enableaaa.bool
        {nocustommarshal.bool false 0x1000}
        {interface.arg IUnknown}
        {authenticationservice.arg none}
        {impersonationlevel.arg impersonate}
        {credentials.arg {}}
        {serverprincipal.arg {}}
        {authenticationlevel.arg default}
        {mutualauth.bool 0 0x1}
        securityblanket.arg
        system.arg
        raw
    } -maxleftover 0]

    set opts(authenticationservice) [_com_name_to_authsvc $opts(authenticationservice)]
    set opts(authenticationlevel) [_com_name_to_authlevel $opts(authenticationlevel)]
    set opts(impersonationlevel) [_com_name_to_impersonation $opts(impersonationlevel)]

    # CLSCTX_NO_CUSTOM_MARSHAL ?
    set flags $opts(nocustommarshal)

    set model 0
    if {[info exists opts(model)]} {
        foreach m $opts(model) {
            switch -exact -- $m {
                any           {setbits model 23}
                inprocserver  {setbits model 1}
                inprochandler {setbits model 2}
                localserver   {setbits model 4}
                remoteserver  {setbits model 16}
            }
        }
    }

    setbits flags $model

    if {[info exists opts(download)]} {
        if {$opts(download)} {
            setbits flags 0x2000;       # CLSCTX_ENABLE_CODE_DOWNLOAD
        } else {
            setbits flags 0x400;       # CLSCTX_NO_CODE_DOWNLOAD
        }
    }

    if {$opts(disablelog)} {
        setbits flags 0x4000;           # CLSCTX_NO_FAILURE_LOG
    }

    if {[info exists opts(enableaaa)]} {
        if {$opts(enableaaa)} {
            setbits flags 0x10000;       # CLSCTX_ENABLE_AAA
        } else {
            setbits flags 0x8000;       # CLSCTX_DISABLE_AAA
        }
    }

    if {[info exists opts(system)]} {
        set coserverinfo [list 0 $opts(system) \
                              [list $opts(authenticationservice) \
                                   0 \
                                   $opts(serverprincipal) \
                                   $opts(authenticationlevel) \
                                   $opts(impersonationlevel) \
                                   $opts(credentials) \
                                   $opts(mutualauth) \
                                   ] \
                              0]
        set activation_blanket \
            [com_security_blanket \
                 -authenticationservice $opts(authenticationservice) \
                 -serverprincipal $opts(serverprincipal) \
                 -authenticationlevel $opts(authenticationlevel) \
                 -impersonationlevel $opts(impersonationlevel) \
                 -credentials $opts(credentials)]
    } else {
        set coserverinfo {}
    }

    # If remote, set the specified security blanket on the proxy. Note
    # that the blanket settings passed to CoCreateInstanceEx are used
    # only for activation and do NOT get passed down to method calls
    # If a remote component is activated with specific identity, we
    # assume method calls require the same security settings.

    if {([info exists activation_blanket] || [llength $opts(credentials)]) &&
        ![info exists opts(securityblanket)]} {
        if {[info exists activation_blanket]} {
            set opts(securityblanket) $activation_blanket
        } else {
            set opts(securityblanket) [com_security_blanket -credentials $opts(credentials)]
        }
    }

    lassign [_resolve_iid $opts(interface)] iid iid_name

    # TBD - is all this OleRun still necessary or is there a check we can make
    # before going down that path ?
    # Microsoft Office (and maybe others) have some, uhhm, quirks.
    # If they are loaded as inproc, all calls to retrieve an interface other 
    # than IUnknown fails. We have to get the IUnknown interface,
    # call OleRun and then retrieve the desired interface.
    # This does not happen if the localserver model was requested.
    # We could check for a specific error code but no guarantee that
    # the error is same in all versions so we catch and retry on all errors.
    # 3rd element of each sublist is status. Non-0 -> Failure code
    if {[catch {set ifcs [CoCreateInstanceEx $clsid NULL $flags $coserverinfo [list $iid]]}] || [lindex $ifcs 0 2] != 0} {
        # Try through IUnknown
        set ifcs [CoCreateInstanceEx $clsid NULL $flags $coserverinfo [list [_iid_iunknown]]]

        if {[lindex $ifcs 0 2] != 0} {
            win32_error [lindex $ifcs 0 2]
        }
        set iunk [lindex $ifcs 0 1]

        # Need to set security blanket if specified before invoking any method
        # else will get access denied
        if {[info exists opts(securityblanket)]} {
            trap {
                CoSetProxyBlanket $iunk {*}$opts(securityblanket)
            } onerror {} {
                IUnknown_Release $iunk
                rethrow
            }
        }

        trap {
            # Wait for it to run, then get desired interface from it
            twapi::OleRun $iunk
            set ifc [Twapi_IUnknown_QueryInterface $iunk $iid $iid_name]
        } finally {
            IUnknown_Release $iunk
        }
    } else {
        set ifc [lindex $ifcs 0 1]
    }

    # All interfaces are returned typed as IUnknown by the C level
    # even though they are actually the requested type.
    set ifc [cast_handle $ifc $iid_name]

    if {[info exists activation_blanket]} {
        # In order for servers to release objects properly, the IUnknown 
        # interface must have the same security settings as were used in 
        # the object creation
        _com_set_iunknown_proxy $ifc $activation_blanket
    }

    if {$opts(raw)} {
        if {[info exists opts(securityblanket)]} {
            trap {
                CoSetProxyBlanket $ifc {*}$opts(securityblanket)
            } onerror {} {
                IUnknown_Release $ifc
                rethrow
            }
        }
        return $ifc
    } else {
        set proxy [make_interface_proxy $ifc]
        if {[info exists opts(securityblanket)]} {
            trap {
                $proxy @SetSecurityBlanket $opts(securityblanket)
            } onerror {} {
                catch {$proxy Release}
                rethrow
            }
        }
        return $proxy
    }
}


proc twapi::comobj_idispatch {ifc {addref 0} {objclsid ""} {lcid 0}} {
    if {[pointer_null? $ifc]} {
        return ::twapi::comobj_null
    }

    if {[pointer? $ifc IDispatch]} {
        if {$addref} { IUnknown_AddRef $ifc }
        set proxyobj [IDispatchProxy new $ifc $objclsid]
    } elseif {[pointer? $ifc IDispatchEx]} {
        if {$addref} { IUnknown_AddRef $ifc }
        set proxyobj [IDispatchExProxy new $ifc $objclsid]
    } else {
        error "'$ifc' does not reference an IDispatch interface"
    }

    return [Automation new $proxyobj $lcid]
}

#
# Create an object command for a COM object from a name
proc twapi::comobj_object {path args} {
    array set opts [parseargs args {
        progid.arg
        {interface.arg IDispatch {IDispatch IDispatchEx}}
        {lcid.int 0}
    } -maxleftover 0]

    set clsid ""
    if {[info exists opts(progid)]} {
        # TBD - document once we have a test case for this
        # Specify which app to use to open the file.
        # See "Mapping Visual Basic to Automation" in SDK help
        set clsid [_convert_to_clsid $opts(progid)]
        set ipersistfile [com_create_instance $clsid -interface IPersistFile]
        trap {
            IPersistFile_Load $ipersistfile $path 0
            set idisp [Twapi_IUnknown_QueryInterface $ipersistfile [_iid_idispatch] IDispatch]
        } finally {
            IUnknown_Release $ipersistfile
        }
    } else {
        # TBD - can we get the CLSID for this case
        set idisp [::twapi::Twapi_CoGetObject $path {} [name_to_iid $opts(interface)] $opts(interface)]
    }

    return [comobj_idispatch $idisp 0 $clsid $opts(lcid)]
}

#
# Create a object command for a COM object IDispatch interface
# comid is either a CLSID or a PROGID
proc twapi::comobj {comid args} {
    array set opts [parseargs args {
        {interface.arg IDispatch {IDispatch IDispatchEx}}
        active
        {lcid.int 0}
    } -ignoreunknown]
    set clsid [_convert_to_clsid $comid]
    if {$opts(active)} {
        set iunk [GetActiveObject $clsid]
        twapi::trap {
            # TBD - do we need to deal with security blanket here? How do
            # know what blanket is to be used on an already active object?
            # Get the IDispatch interface
            set idisp [IUnknown_QueryInterface $iunk {{00020400-0000-0000-C000-000000000046}}]
            return [comobj_idispatch $idisp 0 $clsid $opts(lcid)]
        } finally {
            IUnknown_Release $iunk
        }
    } else {
        set proxy [com_create_instance $clsid -interface $opts(interface) {*}$args]
        $proxy @SetCLSID $clsid
        return [Automation new $proxy $opts(lcid)]
    }
}

proc twapi::comobj_destroy args {
    foreach arg $args {
        catch {$arg -destroy}
    }
}

# Return an interface to a typelib
# TBD - document
proc twapi::ITypeLibProxy_from_path {path args} {
    array set opts [parseargs args {
        {registration.arg none {none register default}}
    } -maxleftover 0]

    return [make_interface_proxy [LoadTypeLibEx $path [kl_get {default 0 register 1 none 2} $opts(registration) $opts(registration)]]]
}

#
# Return an interface to a typelib from the registry
# TBD - document
proc twapi::ITypeLibProxy_from_guid {uuid major minor args} {
    array set opts [parseargs args {
        lcid.int
    } -maxleftover 0 -nulldefault]
    
    return [make_interface_proxy [LoadRegTypeLib $uuid $major $minor $opts(lcid)]]
}

#
# Unregister a typelib
proc twapi::unregister_typelib {uuid major minor args} {
    array set opts [parseargs args {
        lcid.int
    } -maxleftover 0 -nulldefault]

    UnRegisterTypeLib $uuid $major $minor $opts(lcid) 1
}

#
# Returns the path to the typelib based on a guid
proc twapi::get_typelib_path_from_guid {guid major minor args} {
    array set opts [parseargs args {
        lcid.int
    } -maxleftover 0 -nulldefault]


    set path [variant_value [QueryPathOfRegTypeLib $guid $major $minor $opts(lcid)] 0 0 $opts(lcid)]
    # At least some versions have a bug in that there is an extra \0
    # at the end.
    if {[string equal [string index $path end] \0]} {
        set path [string range $path 0 end-1]
    }
    return $path
}

#
# Map interface name to IID
proc twapi::name_to_iid {iname} {
    set iname [string tolower $iname]

    if {[info exists ::twapi::_name_to_iid_cache($iname)]} {
        return $::twapi::_name_to_iid_cache($iname)
    }

    # Look up the registry
    set iids {}
    foreach iid [registry keys HKEY_CLASSES_ROOT\\Interface] {
        if {![catch {
            set val [registry get HKEY_CLASSES_ROOT\\Interface\\$iid ""]
        }]} {
            if {[string equal -nocase $iname $val]} {
                lappend iids $iid
            }
        }
    }

    if {[llength $iids] == 1} {
        return [set ::twapi::_name_to_iid_cache($iname) [lindex $iids 0]]
    } elseif {[llength $iids]} {
        error "Multiple interfaces found matching name $iname: [join $iids ,]"
    } else {
        return [set ::twapi::_name_to_iid_cache($iname) ""]
    }
}


#
# Map interface IID to name
proc twapi::iid_to_name {iid} {
    set iname ""
    catch {set iname [registry get HKEY_CLASSES_ROOT\\Interface\\$iid ""]}
    return $iname
}

#
# Convert a variant time to a time list
proc twapi::variant_time_to_timelist {double} {
    return [VariantTimeToSystemTime $double]
}

#
# Convert a time list time to a variant time
proc twapi::timelist_to_variant_time {timelist} {
    return [SystemTimeToVariantTime $timelist]
}


proc twapi::typelib_print {path args} {
    array set opts [parseargs args {
        type.arg
        name.arg
        output.arg
    } -maxleftover 0 -nulldefault]

    
    if {$opts(output) ne ""} {
        if {[file exists $opts(output)]} {
            error "File $opts(output) already exists."
        }
        set outfd [open $opts(output) a]
    } else {
        set outfd stdout
    }

    trap {
        set tl [ITypeLibProxy_from_path $path -registration none]
        puts $outfd [$tl @Text -type $opts(type) -name $opts(name)]
    } finally {
        if {[info exists tl]} {
            $tl Release
        }
        if {$outfd ne "stdout"} {
            close $outfd
        }
    }        

    return
}

proc twapi::generate_code_from_typelib {path args} {
    array set opts [parseargs args {
        output.arg
    } -ignoreunknown]

    if {[info exists opts(output)]} {
        if {$opts(output) ne "stdout"} {
            if {[file exists $opts(output)]} {
                error "File $opts(output) already exists."
            }
            set outfd [open $opts(output) a]
        } else {
            set outfd stdout
        }
    }

    trap {
        set tl [ITypeLibProxy_from_path $path -registration none]
        set code [$tl @GenerateCode {*}$args]
        if {[info exists outfd]} {
            puts $outfd "package require twapi_com"
            puts $outfd $code
            return
        } else {
            return $code
        }
    } finally {
        if {[info exists tl]} {
            $tl Release
        }
        if {[info exists outfd] && $outfd ne "stdout"} {
            close $outfd
        }
    }        
}




proc twapi::_interface_text {ti} {
    # ti must be TypeInfo for an interface or module (or enum?) - TBD
    set desc ""
    array set attrs [$ti @GetTypeAttr -all]
    set desc "Functions:\n"
    for {set j 0} {$j < $attrs(-fncount)} {incr j} {
        array set funcdata [$ti @GetFuncDesc $j -all]
        if {$funcdata(-funckind) eq "dispatch"} {
            set funckind "(dispid $funcdata(-memid))"
        } else {
            set funckind "(vtable $funcdata(-vtbloffset))"
        }
        append desc "\t$funckind [::twapi::_resolve_com_type_text $ti $funcdata(-datatype)] $funcdata(-name) $funcdata(-invkind) [::twapi::_resolve_com_params_text $ti $funcdata(-params) $funcdata(-paramnames)]\n"
    }
    append desc "Variables:\n"
    for {set j 0} {$j < $attrs(-varcount)} {incr j} {
        array set vardata [$ti @GetVarDesc $j -all]
        set vardesc "($vardata(-memid)) $vardata(-varkind) [::twapi::_flatten_com_type [::twapi::_resolve_com_type_text $ti $vardata(-datatype)]] $vardata(-name)"
        if {$attrs(-typekind) eq "enum" || $vardata(-varkind) eq "const"} {
            append vardesc " = $vardata(-value)"
        } else {
            append vardesc " (offset $vardata(-value))"
        }
        append desc "\t$vardesc\n"
    }
    return $desc
}

#
# Print methods in an interface, including inherited names
proc twapi::dispatch_print {di args} {
    array set opts [parseargs args {
        output.arg
    } -maxleftover 0 -nulldefault]

    if {$opts(output) ne ""} {
        if {[file exists $opts(output)]} {
            error "File $opts(output) already exists."
        }
        set outfd [open $opts(output) a]
    } else {
        set outfd stdout
    }

    trap {
        set ti [$di @GetTypeInfo]
        twapi::_dispatch_print_helper $ti $outfd
    } finally {
        if {[info exists ti]} {
            $ti Release
        }
        if {$outfd ne "stdout"} {
            close $outfd
        }
    }

    return
}

proc twapi::_dispatch_print_helper {ti outfd {names_already_done ""}} {
    set name [$ti @GetName]
    if {$name in $names_already_done} {
        # Already printed this
        return $names_already_done
    }
    lappend names_already_done $name

    # Check for dual interfaces - we want to print both vtable and disp versions
    set tilist [list $ti]
    if {![catch {set ti2 [$ti @GetRefTypeInfoFromIndex $ti -1]}]} {
        lappend tilist $ti2
    }

    trap {
        foreach tifc $tilist {
            puts $outfd $name
            puts $outfd [_interface_text $tifc]
        }
    } finally {
        if {[info exists ti2]} {
            $ti2 Release
        }
    }

    # Now get any referenced typeinfos and print them
    array set tiattrs [$ti GetTypeAttr]
    for {set j 0} {$j < $tiattrs(cImplTypes)} {incr j} {
        set ti2 [$ti @GetRefTypeInfoFromIndex $j]
        trap {
            set names_already_done [_dispatch_print_helper $ti2 $outfd $names_already_done]
        } finally {
            $ti2 Release
        }
    }

    return $names_already_done
}



#
# Resolves references to parameter definition
proc twapi::_resolve_com_params_text {ti params paramnames} {
    set result [list ]
    foreach param $params paramname $paramnames {
        set paramdesc [_flatten_com_type [_resolve_com_type_text $ti [lindex $param 0]]]
        if {[llength $param] > 1 && [llength [lindex $param 1]] > 0} {
            set paramdesc "\[[lindex $param 1]\] $paramdesc"
        }
        if {[llength $param] > 2} {
            append paramdesc " [lrange $param 2 end]"
        }
        append paramdesc " $paramname"
        lappend result $paramdesc
    }
    return "([join $result {, }])"
}

# Flattens the output of _resolve_com_type_text
proc twapi::_flatten_com_type {com_type_desc} {
    if {[llength $com_type_desc] < 2} {
        return $com_type_desc
    }

    if {[lindex $com_type_desc 0] eq "ptr"} {
        return "[_flatten_com_type [lindex $com_type_desc 1]]*"
    } else {
        return "([lindex $com_type_desc 0] [_flatten_com_type [lindex $com_type_desc 1]])"
    }
}

#
# Resolves typedefs
proc twapi::_resolve_com_type_text {ti typedesc} {
    
    switch -exact -- [lindex $typedesc 0] {
        26 -
        ptr {
            # Recurse to resolve any inner types
            set typedesc [list ptr [_resolve_com_type_text $ti [lindex $typedesc 1]]]
        }
        29 -
        userdefined {
            set hreftype [lindex $typedesc 1]
            set ti2 [$ti @GetRefTypeInfo $hreftype]
            set typedesc "[$ti2 @GetName]"
            $ti2 Release
        }
        default {
            set typedesc [_vttype_to_string $typedesc]
        }
    }

    return $typedesc
}


#
# Given a COM type descriptor, resolved all user defined types (UDT) in it
# The descriptor must be in raw form as returned by the C code
proc twapi::_resolve_comtype {ti typedesc} {
    
    if {[lindex $typedesc 0] == 26} {
        # VT_PTR - {26 INNER_TYPEDESC}
        # If pointing to a UDT, convert to appropriate base type if possible
        set inner [_resolve_comtype $ti [lindex $typedesc 1]]
        if {[lindex $inner 0] == 29} {
            # When the referenced type is a UDT (29) which is actually
            # a dispatch or other interface, replace the
            # "pointer to UDT" with VT_DISPATCH/VT_INTERFACE
            switch -exact -- [lindex $inner 1] {
                dispatch  {set typedesc [list 9]}
                interface {set typedesc [list 13]}
                default {
                    # TBD - need to decode all the other types (record etc.)
                    set typedesc [list 26 $inner]
                }
            }
        } else {
            set typedesc [list 26 $inner]
        }
    } elseif {[lindex $typedesc 0] == 29} {
        # VT_USERDEFINED - {29 HREFTYPE}
        set ti2 [$ti @GetRefTypeInfo [lindex $typedesc 1]]
        array set tattr [$ti2 @GetTypeAttr -guid -typekind]
        if {$tattr(-typekind) eq "enum"} {
            set typedesc [list 3]; # 3 -> i4
        } else {
            if {$tattr(-typekind) eq "alias"} {
                set typedesc [_resolve_comtype $ti2 [kl_get [$ti2 GetTypeAttr] tdescAlias]]
            } else {
                set typedesc [list 29 $tattr(-typekind) $tattr(-guid)]
            }
        }
        $ti2 Release
    }

    return $typedesc
}

proc twapi::_resolve_params_for_prototype {ti paramdescs} {
    set params {}
    foreach paramdesc $paramdescs {
        lappend params \
            [lreplace $paramdesc 0 0 [::twapi::_resolve_comtype $ti [lindex $paramdesc 0]]]
    }
    return $params
}

proc twapi::_variant_values_from_safearray {sa ndims {raw false} {addref false} {lcid 0}} {
    set result {}
    if {[incr ndims -1] > 0} {
	foreach elem $sa {
	    lappend result [_variant_values_from_safearray $elem $ndims $raw $addref $lcid]
	}
    } else {
	foreach elem $sa {
	    lappend result [twapi::variant_value $elem $raw $addref $lcid]
	}
    }
    return $result
}

proc twapi::outvar {varname} { return [Twapi_InternalCast outvar $varname] }

# TBD - document
# Returns a string value from a formatted variant value pair {VT_xxx value}
# $addref controls whether we do an AddRef when the value is a pointer to
# an interface. $raw controls whether interface pointers are returned
# as raw interface handles or objects.
proc twapi::variant_value {variant raw addref lcid} {
    # TBD - format appropriately depending on variant type for dates and
    # currency
    if {[llength $variant] == 0} {
        return ""
    }
    set vt [lindex $variant 0]

    if {$vt & 0x2000} {
        # VT_ARRAY - second element is {dimensions value}
        if {[llength $variant] < 2} {
            return [list ]
        }
        lassign [lindex $variant 1] dimensions values
        set vt [expr {$vt & ~ 0x2000}]
        if {$vt == 12} {
            # Array of variants. Recursively convert values
            return [_variant_values_from_safearray \
                        $values \
                        [expr {[llength $dimensions] / 2}] \
                        $raw $addref $lcid]
        } else {
            return $values
        }
    } else {
        if {$vt == 9} {
            set idisp [lindex $variant 1]; # May be NULL!
            if {$addref && ! [pointer_null? $idisp]} {
                IUnknown_AddRef $idisp
            }
            if {$raw} {
                return $idisp
            } else {
                # Note comobj_idispatch takes care of NULL
                return [comobj_idispatch $idisp 0 "" $lcid]
            }
        } elseif {$vt == 13} {
            set iunk [lindex $variant 1]; # May be NULL!
            if {$addref && ! [pointer_null? $iunk]} {
                IUnknown_AddRef $iunk
            }
            if {$raw} {
                return $iunk
            } else {
                return [make_interface_proxy $iunk]
            }
        }
    }
    return [lindex $variant 1]
}

proc twapi::variant_type {variant} {
    return [lindex $variant 0]
}

proc twapi::vt_null {} {
    return [tclcast null ""]
}

proc twapi::vt_empty {} {
    return [tclcast empty ""]
}

#
# General dispatcher for callbacks from event sinks. Invokes the actual
# registered script after mapping dispid's
proc twapi::_eventsink_callback {comobj script callee args} {
    # Check if the comobj is still active
    if {[llength [info commands $comobj]] == 0} {
        if {$::twapi::log_config(twapi_com)} {
            debuglog "COM event received for inactive object"
        }
        return;                         # Object has gone away, ignore
    }

    set retcode [catch {
        # We are invoked with cooked values so no need to call variant_value
        uplevel #0 $script [list $callee] $args
    } result]

    if {$::twapi::log_config(twapi_com) && $retcode} {
        debuglog "Event sink callback error ($retcode): $result\n$::errorInfo"
    }

    # $retcode is returned as HRESULT by the Invoke
    return -code $retcode $result
}

#
# Return clsid from a string. If $clsid is a valid CLSID - returns as is
# else tries to convert it from progid. An error is generated if neither
# works
proc twapi::_convert_to_clsid {comid} {
    if {! [Twapi_IsValidGUID $comid]} {
        return [progid_to_clsid $comid]
    }
    return $comid
}

#
# Format a prototype definition for human consumption
# Proto is in the form {DISPID LCID INVOKEFLAGS RETTYPE PARAMTYPES PARAMNAMES}
proc twapi::_format_prototype {name proto} {
    set dispid_lcid [lindex $proto 0]/[lindex $proto 1]
    set ret_type [_vttype_to_string [lindex $proto 3]]
    set invkind [_invkind_to_string [lindex $proto 2]]
    # Distinguish between no parameters and parameters not known
    set paramstr ""
    if {[llength $proto] > 4} {
        set params {}
        foreach param [lindex $proto 4] paramname [lindex $proto 5] {
            if {[string length $paramname]} {
                set paramname " $paramname"
            }
            lassign $param type paramdesc
            set type [_vttype_to_string $type]
            set parammods [_paramflags_to_tokens [lindex $paramdesc 0]]
            if {[llength [lindex $paramdesc 1]]} {
                # Default specified
                lappend parammods "default:[lindex [lindex $paramdesc 1] 1]"
            }
            lappend params "\[$parammods\] $type$paramname"
        }
        set paramstr " ([join $params {, }])"
    }
    return "$dispid_lcid $invkind $ret_type ${name}${paramstr}"
}

# Convert parameter modifiers to string tokens.
# modifiers is list of integer flags or tokens.
proc twapi::_paramflags_to_tokens {modifiers} {
    array set tokens {}
    foreach mod $modifiers {
        if {! [string is integer -strict $mod]} {
            # mod is a token itself
            set tokens($mod) ""
        } else {
            foreach tok [_make_symbolic_bitmask $mod {
                in 1
                out 2
                lcid 4
                retval 8
                optional 16
                hasdefault 32
                hascustom  64
            }] {
                set tokens($tok) ""
            }
        }
    }

    # For cosmetic reasons, in/out should be first and remaining sorted
    # Also (in,out) -> inout
    if {[info exists tokens(in)]} {
        if {[info exists tokens(out)]} {
            set inout [list inout]
            unset tokens(in)
            unset tokens(out)
        } else {
            set inout [list in]
            unset tokens(in)
        }
    } else {
        if {[info exists tokens(out)]} {
            set inout [list out]
            unset tokens(out)
        }
    }

    if {[info exists inout]} {
        return [linsert [lsort [array names tokens]] 0 $inout]
    } else {
        return [lsort [array names tokens]]
    }
}

#
# Map method invocation code to string
# Return code itself if no match
proc twapi::_invkind_to_string {code} {
    return [kl_get {
        1  func
        2  propget
        4  propput
        8  propputref
    } $code $code]
}

#
# Map string method invocation symbol to code
# Error if no match and not an integer
proc twapi::_string_to_invkind {s} {
    if {[string is integer $s]} { return $s }
    return [kl_get {
        func    1
        propget 2
        propput 4
        propputref 8
    } $s]
}


#
# Convert a VT typedef to a string
# vttype may be nested
proc twapi::_vttype_to_string {vttype} {
    set vts [_vtcode_to_string [lindex $vttype 0]]
    if {[llength $vttype] < 2} {
        return $vts
    }

    return [list $vts [_vttype_to_string [lindex $vttype 1]]]
}

#
# Convert VT codes to strings
proc twapi::_vtcode_to_string {vt} {
    return [kl_get {
        2        i2
        3        i4
        4       r4
        5       r8
        6       cy
        7       date
        8       bstr
        9       idispatch
        10       error
        11       bool
        12       variant
        13       iunknown
        14       decimal
        16       i1
        17       ui1
        18       ui2
        19       ui4
        20       i8
        21       ui8
        22       int
        23       uint
        24       void
        25       hresult
        26       ptr
        27       safearray
        28       carray
        29       userdefined
        30       lpstr
        31       lpwstr
        36       record
    } $vt $vt]
}

proc twapi::_string_to_base_vt {tok} {
    # Only maps base VT tokens to numeric value
    # TBD - record and userdefined?
    return [dict get {
        i2 2
        i4 3
        r4 4
        r8 5
        cy 6
        date 7
        bstr 8
        idispatch 9
        error 10
        bool 11
        iunknown 13
        decimal 14
        i1 16
        ui1 17
        ui2 18
        ui4 19
        i8 20
        ui8 21
        int 22
        uint 23
        hresult 25
        userdefined 29
        record 36
    } [string tolower $tok]]

}

#
# Get ADSI provider service
proc twapi::_adsi {{prov WinNT} {path {//.}}} {
    return [comobj_object "${prov}:$path"]
}

# Get cached IDispatch and IUNknown IID's
proc twapi::_iid_iunknown {} {
    return $::twapi::_name_to_iid_cache(iunknown)
}
proc twapi::_iid_idispatch {} {
    return $::twapi::_name_to_iid_cache(idispatch)
}

#
# Return IID and name given a IID or name
proc twapi::_resolve_iid {name_or_iid} {

    # IID -> name mapping is more efficient so first assume it is
    # an IID else we will unnecessarily trundle through the whole
    # registry area looking for an IID when we already have it
    # Assume it is a name
    set other [iid_to_name $name_or_iid]
    if {$other ne ""} {
        # It was indeed the IID. Return the pair
        return [list $name_or_iid $other]
    }

    # Else resolve as a name
    set other [name_to_iid $name_or_iid]
    if {$other ne ""} {
        # Yep
        return [list $other $name_or_iid]
    }

    win32_error 0x80004002 "Could not find IID $name_or_iid"
}


namespace eval twapi {
    # Enable use of TclOO for new Tcl versions. To override setting
    # applications should define and set before sourcing this file.
    variable use_tcloo_for_com 
    if {![info exists use_tcloo_for_com]} {
        set use_tcloo_for_com [package vsatisfies [package require Tcl] 8.6b2]
    }
    if {$use_tcloo_for_com} {
        interp alias {} ::twapi::class {} ::oo::class
        proc ::oo::define::twapi_exportall {} {
            uplevel 1 export [info class methods [lindex [info level -1] 1] -private]
        }
        proc comobj? {cobj} {
            # TBD - would it be faster to keep explicit track through
            # a dictionary ?
            set cobj [uplevel 1 [list namespace which -command $cobj]]
            if {[info object isa object $cobj] &&
                [info object isa typeof $cobj ::twapi::Automation]} {
                return 1
            } else {
                return 0
            }
        }
        proc comobj_instances {} {
            set comobj_classes [list ::twapi::Automation]
            set objs {}
            while {[llength $comobj_classes]} {
                set comobj_classes [lassign $comobj_classes class]
                lappend objs {*}[info class instances $class]
                lappend comobj_classes {*}[info class subclasses $class]
            }
            # Get rid of dups which may occur if subclasses use
            # multiple (diamond type) inheritance
            return [lsort -unique $objs]
        }
    } else {
        package require metoo
        interp alias {} ::twapi::class {} ::metoo::class
        namespace eval ::metoo::define {
            proc twapi_exportall {args} {
                # args is dummy to match metoo's class definition signature
                # Nothing to do, all methods are metoo are public
            }
        }
        proc comobj? {cobj} {
            set cobj [uplevel 1 [list namespace which -command $cobj]]
            return [metoo::introspect object isa $cobj ::twapi::Automation]
        }
        proc comobj_instances {} {
            return [metoo::introspect object list ::twapi::Automation]
        }
    }

    # The prototype cache is indexed a composite key consisting of
    #  - the GUID of the interface,
    #  - the name of the function
    #  - the LCID
    #  - the invocation kind (as an integer)
    # Each value contains the full prototype in a form
    # that can be passed to IDispatch_Invoke. This is a list with the
    # elements {DISPID LCID INVOKEFLAGS RETTYPE PARAMTYPES PARAMNAMES}
    # Here PARAMTYPES is a list each element of which describes a
    # parameter in the following format:
    #     {TYPE {FLAGS DEFAULT} NAMEDARGVALUE} where DEFAULT is optional
    # and NAMEDARGVALUE only appears (optionally) when the prototype is
    # passed to Invoke, not in the cached prototype itself.
    # PARAMNAMES is list of parameter names in order and is
    # only present if PARAMTYPES is also present.
    
    variable _dispatch_prototype_cache
    array set _dispatch_prototype_cache {}
}


interp alias {} twapi::_dispatch_prototype_get {} twapi::dispatch_prototype_get
proc twapi::dispatch_prototype_get {guid name lcid invkind vproto} {
    variable _dispatch_prototype_cache
    set invkind [::twapi::_string_to_invkind $invkind]
    if {[info exists _dispatch_prototype_cache($guid,$name,$lcid,$invkind)]} {
        # Note this may be null if that name does not exist in the interface
        upvar 1 $vproto proto
        set proto $_dispatch_prototype_cache($guid,$name,$lcid,$invkind)
        return 1
    }
    return 0
}

# Update a prototype in cache. Note lcid and invkind cannot be
# picked up from prototype since it might be empty.
interp alias {} twapi::_dispatch_prototype_set {} twapi::dispatch_prototype_set
proc twapi::dispatch_prototype_set {guid name lcid invkind proto} {
    # If the prototype does not contain the 5th element (params)
    # it is a constructed prototype and we do NOT cache it as the
    # disp id can change. Note empty prototypes are cached so
    # we don't keep looking up something that does not exist
    # Bug 130

    if {[llength $proto] == 4} {
        return
    }

    variable _dispatch_prototype_cache
    set invkind [_string_to_invkind $invkind]
    set _dispatch_prototype_cache($guid,$name,$lcid,$invkind) $proto
    return
}

# Explicitly set prototypes for a guid 
# protolist is a list of alternating name and prototype pairs.
# Each prototype must contain the LCID and invkind fields
proc twapi::_dispatch_prototype_load {guid protolist} {
    foreach {name proto} $protolist {
        dispatch_prototype_set $guid $name [lindex $proto 1] [lindex $proto 2] $proto
    }
}

proc twapi::_parse_dispatch_paramdef {paramdef} {
    set errormsg "Invalid parameter or return type declaration '$paramdef'"

    set paramregex {^(\[[^\]]*\])?\s*(\w+)\s*(\[\s*\])?\s*([*]?)\s*(\w+)?$}
    if {![regexp $paramregex [string trim $paramdef] def attrs paramtype safearray ptr paramname]} {
        error $errormsg
    }

    if {[string length $paramname]} {
        lappend paramnames $paramname
    }
    # attrs can be in, out, opt separated by spaces
    set paramflags 0
    foreach attr [string range $attrs 1 end-1] {
        switch -exact -- $attr {
            in {set paramflags [expr {$paramflags | 1}]}
            out {set paramflags [expr {$paramflags | 2}]}
            inout {set paramflags [expr {$paramflags | 3}]}
            opt -
            optional {set paramflags [expr {$paramflags | 16}]}
            default {error "Unknown parameter attribute $attr"}
        }
    }
    if {($paramflags & 3) == 0} {
        set paramflags [expr {$paramflags | 1}]; # in param if unspecified
    }
    # Resolve parameter type. It can be 
    #  - a safearray of base types or "variant"s (not pointers)
    #  - a pointer to a base type
    #  - a pointer to a safearray
    #  - a base type or "variant"
    switch -exact -- $paramtype {
        variant { set paramtype 12 }
        void    { set paramtype 24 }
        default { set paramtype [_string_to_base_vt $paramtype] }
    }
    if {[string length $safearray]} {
        if {$paramtype == 24} {
            # Safearray of type void is an invalid type decl
            error $errormsg
        }
        set paramtype [list 27 $paramtype]
    }
    if {[string length $ptr]} {
        if {$paramtype == 24} {
            # Pointer to type void is an invalid type
            error $errormsg
        }
        set paramtype [list 26 $paramtype]
    }

    return [list $paramflags $paramtype $paramname]
}

proc twapi::define_dispatch_prototypes {guid protos args} {
    array set opts [parseargs args {
        {lcid.int 0}
    } -maxleftover 0]

    set guid [canonicalize_guid $guid]

    set defregx {^\s*(\w+)\s+(\d+)\s+(\w[^\(]*)\(([^\)]*)\)(.*)$}
    set parsed_protos {}
    # Loop picking out one prototype in each interation
    while {[regexp $defregx $protos -> membertype memid rettype paramstring protos]} {
        set params {}
        set paramnames {}
        foreach paramdef [split $paramstring ,] {
            lassign [_parse_dispatch_paramdef $paramdef] paramflags paramtype paramname
            if {[string length $paramname]} {
                lappend paramnames $paramname
            }
            lappend params [list $paramtype [list $paramflags]]
        }
        if {[llength $paramnames] &&
            [llength $params] != [llength $paramnames]} {
            error "Missing parameter name in '$paramstring'. All parameter names must be specified or none at all."
        }

        lassign [_parse_dispatch_paramdef $rettype] _ rettype name 
        set invkind [_string_to_invkind $membertype]
        set proto [list $memid $opts(lcid) $invkind $rettype $params $paramnames]
        lappend parsed_protos $name $proto
    }

    set protos [string trim $protos]
    if {[string length $protos]} {
        error "Invalid dispatch prototype: '$protos'"
    }
    
    _dispatch_prototype_load $guid $parsed_protos
}

# Used to track when interface proxies are renamed/deleted
proc twapi::_interface_proxy_tracer {ifc oldname newname op} {
    variable _interface_proxies
    if {$op eq "rename"} {
        if {$oldname eq $newname} return
        set _interface_proxies($ifc) $newname
    } else {
        unset _interface_proxies($ifc)
    }
}


# Return a COM interface proxy object for the specified interface.
# If such an object already exists, it is returned. Otherwise a new one
# is created. $ifc must be a valid COM Interface pointer for which
# the caller is holding a reference. Caller relinquishes ownership
# of the interface and must solely invoke operations through the
# returned proxy object. When done with the object, call the Release
# method on it, NOT destroy.
# TBD - how does this interact with security blankets ?
proc twapi::make_interface_proxy {ifc} {
    variable _interface_proxies

    if {[info exists _interface_proxies($ifc)]} {
        set proxy $_interface_proxies($ifc)
        $proxy AddRef
        if {! [pointer_null? $ifc]} {
            # Release the caller's ref to the interface since we are holding
            # one in the proxy object
            ::twapi::IUnknown_Release $ifc
        }
    } else {
        if {[pointer_null? $ifc]} {
            set proxy [INullProxy new $ifc]
        } else {
            set ifcname [pointer_type $ifc]
            set proxy [${ifcname}Proxy new $ifc]
        }
        set _interface_proxies($ifc) $proxy
        trace add command $proxy {rename delete} [list ::twapi::_interface_proxy_tracer $ifc]
    }
    return $proxy
}

# "Null" object - clones IUnknownProxy but will raise error on method calls
# We could have inherited but IUnknownProxy assumes non-null ifc so it
# and its inherited classes do not have to check for null in every method.
twapi::class create ::twapi::INullProxy {
    constructor {ifc} {
        my variable _ifc
        # We keep the interface pointer because it encodes type information
        if {! [::twapi::pointer_null? $ifc]} {
            error "Attempt to create a INullProxy with non-NULL interface"
        }

        set _ifc $ifc

        my variable _nrefs;   # Internal ref count (held by app)
        set _nrefs 1
    }

    method @Null? {} { return 1 }
    method @Type {} {
        my variable _ifc
        return [::twapi::pointer_type $_ifc]
    }
    method @Type? {type} {
        my variable _ifc
        return [::twapi::pointer? $_ifc $type]
    }
    method AddRef {} {
        my variable _nrefs
        # We maintain our own ref counts. _ifc is null so do not
        # call the COM AddRef !
        incr _nrefs
    }

    method Release {} {
        my variable _nrefs
        if {[incr _nrefs -1] == 0} {
            my destroy
        }
    }

    method DebugRefCounts {} {
        my variable _nrefs

        # Return out internal ref as well as the COM ones
        # Note latter is always 0 since _ifc is always NULL.
        return [list $_nrefs 0]
    }

    method QueryInterface {name_or_iid} {
        error "Attempt to call QueryInterface called on NULL pointer"
    }

    method @QueryInterface {name_or_iid} {
        error "Attempt to call QueryInterface called on NULL pointer"
    }

    # Parameter is for compatibility with IUnknownProxy
    method @Interface {{addref 1}} {
        my variable _ifc
        return $_ifc
    }

    twapi_exportall
}

twapi::class create ::twapi::IUnknownProxy {
    # Note caller must hold ref on the ifc. This ref is passed to
    # the proxy object and caller must not make use of that ref
    # unless it does an AddRef on it.
    constructor {ifc {objclsid ""}} {
        if {[::twapi::pointer_null? $ifc]} {
            error "Attempt to register a NULL interface"
        }

        my variable _ifc
        set _ifc $ifc

        my variable _clsid
        set _clsid $objclsid

        my variable _blanket;   # Security blanket
        set _blanket [list ]

        # We keep an internal reference count instead of explicitly
        # calling out to the object's AddRef/Release every time.
        # When the internal ref count goes to 0, we will invoke the 
        # object's "native" Release.
        #
        # Note the primary purpose of maintaining our internal reference counts
        # is not efficiency by shortcutting the "native" AddRefs. It is to
        # prevent crashes by bad application code; we can just generate an
        # error instead by having the command go away.
        my variable _nrefs;   # Internal ref count (held by app)

        set _nrefs 1
    }

    destructor {
        my variable _ifc
        ::twapi::IUnknown_Release $_ifc
    }

    method AddRef {} {
        my variable _nrefs
        # We maintain our own ref counts. Not pass it on to the actual object
        incr _nrefs
    }

    method Release {} {
        my variable _nrefs
        if {[incr _nrefs -1] == 0} {
            my destroy
        }
    }

    method DebugRefCounts {} {
        my variable _nrefs
        my variable _ifc

        # Return out internal ref as well as the COM ones
        # Note latter are unstable and only to be used for
        # debugging
        twapi::IUnknown_AddRef $_ifc
        return [list $_nrefs [twapi::IUnknown_Release $_ifc]]
    }

    method QueryInterface {name_or_iid} {
        my variable _ifc
        lassign [::twapi::_resolve_iid $name_or_iid] iid name
        return [::twapi::Twapi_IUnknown_QueryInterface $_ifc $iid $name]
    }

    # Same as QueryInterface except return "" instead of exception
    # if interface not found and returns proxy object instead of interface
    method @QueryInterface {name_or_iid {set_blanket 0}} {
        my variable _blanket
        ::twapi::trap {
            set proxy [::twapi::make_interface_proxy [my QueryInterface $name_or_iid]]
            if {$set_blanket && [llength $_blanket]} {
                $proxy @SetSecurityBlanket $_blanket
            }
            return $proxy
        } onerror {TWAPI_WIN32 0x80004002} {
            # No such interface, return "", don't generate error
            return ""
        } onerror {} {
            if {[info exists proxy]} {
                catch {$proxy Release}
            }
            rethrow
        }
    }

    method @Type {} {
        my variable _ifc
        return [::twapi::pointer_type $_ifc]
    }

    method @Type? {type} {
        my variable _ifc
        return [::twapi::pointer? $_ifc $type]
    }

    method @Null? {} {
        my variable _ifc
        return [::twapi::pointer_null? $_ifc]
    }

    # Returns raw interface. Caller must call IUnknown_Release on it
    # iff addref is passed as true (default)
    method @Interface {{addref 1}} {
        my variable _ifc
        if {$addref} {
            ::twapi::IUnknown_AddRef $_ifc
        }
        return $_ifc
    }

    # Returns out class id - old deprecated - use GetCLSID
    method @Clsid {} {
        my variable _clsid
        return $_clsid
    }

    method @GetCLSID {} {
        my variable _clsid
        return $_clsid
    }

    method @SetCLSID {clsid} {
        my variable _clsid
        set _clsid $clsid
        return
    }

    method @SetSecurityBlanket blanket {
        my variable _ifc _blanket
        # In-proc components will not support IClientSecurity interface
        # and will raise an error. That's the for the caller to be careful
        # about.
        twapi::CoSetProxyBlanket $_ifc {*}$blanket
        set _blanket $blanket
        return
    }

    method @GetSecurityBlanket {} {
        my variable _blanket
        return $_blanket
    }
    

    twapi_exportall
}

twapi::class create ::twapi::IDispatchProxy {
    superclass ::twapi::IUnknownProxy

    destructor {
        my variable _typecomp
        if {[info exists _typecomp] && $_typecomp ne ""} {
            $_typecomp Release
        }
        next
    }

    method GetTypeInfoCount {} {
        my variable _ifc
        return [::twapi::IDispatch_GetTypeInfoCount $_ifc]
    }

    # names is list - method name followed by parameter names
    # Returns list of name dispid pairs
    method GetIDsOfNames {names {lcid 0}} {
        my variable _ifc
        return [::twapi::IDispatch_GetIDsOfNames $_ifc $names $lcid]
    }

    # Get dispid of a method (without parameter names)
    method @GetIDOfOneName {name {lcid 0}} {
        return [lindex [my GetIDsOfNames [list $name] $lcid] 1]
    }

    method GetTypeInfo {{infotype 0} {lcid 0}} {
        my variable _ifc
        if {$infotype != 0} {error "Parameter infotype must be 0"}
        return [::twapi::IDispatch_GetTypeInfo $_ifc $infotype $lcid]
    }

    method @GetTypeInfo {{lcid 0}} {
        return [::twapi::make_interface_proxy [my GetTypeInfo 0 $lcid]]
    }

    method Invoke {prototype args} {
        my variable _ifc
        if {[llength $prototype] == 0 && [llength $args] == 0} {
            # Treat as a property get DISPID_VALUE (default value)
            # {dispid=0, lcid=0 cmd=propget(2) ret type=bstr(8) {} (no params)}
            set prototype {0 0 2 8 {}}
        } else {
            # TBD - optimize by precomputing if a prototype needs this processing
            # If any arguments are comobjs, may need to replace with the 
            # IDispatch interface.
            # Moreover, we have to manage the reference counts for both
            # IUnknown and IDispatch - 
            #  - If the parameter is an IN parameter, ref counts do not need
            #    to change.
            #  - If the parameter is an OUT parameter, we are not passing
            #    an interface in, so nothing to do
            #  - If the parameter is an INOUT, we need to AddRef it since
            #    the COM method will Release it when storing a replacement
            # HERE WE ONLY DO THE CHECK FOR COMOBJ. The AddRef checks are
            # DONE IN THE C CODE (if necessary)

            set iarg -1
            set args2 {}
            foreach arg $args {
                incr iarg
                # TBD - optimize this loop
                set argtype  [lindex $prototype 4 $iarg 0]
                set argflags 0
                if {[llength [lindex $prototype 4 $iarg 1]]} {
                    set argflags [lindex $prototype 4 $iarg 1 0]
                }
                if {$argflags & 1} {
                    # IN param
                    if {$argflags & 2} {
                        # IN/OUT
                        # We currently do NOT handle a In/Out - skip for now TBD
                        # In the future we will have to check contents of
                        # the passed arg as a variable in the CALLER's context
                    } else {
                        # Pure IN param. Check if it is VT_DISPATCH or
                        # VT_VARIANT. Else nothing
                        # to do
                        if {[lindex $argtype 0] == 26} {
                            # Pointer, get base type
                            set argtype [lindex $argtype 1]
                        }
                        if {[lindex $argtype 0] == 9 || [lindex $argtype 0] == 12} {
                            # If a comobj was passed, need to extract the
                            # dispatch pointer.
                            # We do not want change the internal type so
                            # save it since comobj? changes it to cmdProc.
                            # Moreover, do not check for some types that
                            # could not be a comobj. In particular,
                            # if a list type, we do not even check
                            # because it cannot be a comobj and even checking
                            # will result in nested list types being
                            # destroyed which affects safearray type detection
                            if {[twapi::tcltype $arg] ni {bytecode TwapiOpaque list int double bytearray dict wideInt booleanString}} {
                                if {[twapi::comobj? $arg]} {
                                    # Note we do not addref when getting the interface
                                    # (last param 0) because not necessary for IN
                                    # params, AND it is the C code's responsibility
                                    # anyways
                                    set arg [$arg -interface 0]
                                }
                            }
                        }
                    }

                } else {
                    # Not an IN param. Nothing to be done
                }
                
                lappend args2 $arg
            }
            set args $args2
        }

        # The uplevel is so that if some parameters are output, the varnames
        # are resolved in caller
        uplevel 1 [list ::twapi::IDispatch_Invoke $_ifc $prototype] $args
    }

    # Methods are tried in the order specified by invkinds.
    method @Invoke {name invkinds lcid params {namedargs {}}} {
        if {$name eq ""} {
            # Default method
            return [uplevel 1 [list [self] Invoke {}] $params]
        } else {
            set nparams [llength $params]

            # We will try for each invkind to match. matches can be of
            # different degrees, in descending priority -
            # 1. prototype has parameter info and num params match exactly
            # 2. prototype has parameter info and num params is greater
            #    than supplied arguments (assumes others have defaults)
            # 3. prototype has no parameter information
            # Within these classes, the order of invkinds determines
            # priority

            foreach invkind $invkinds {
                set proto [my @Prototype $name $invkind $lcid]
                if {[llength $proto]} {
                    if {[llength $proto] < 5} {
                        # No parameter information
                        lappend class3 $proto
                    } else {
                        if {[llength [lindex $proto 4]] == $nparams} {
                            lappend class1 $proto
                            break; # Class 1 match, no need to try others
                        } elseif {[llength [lindex $proto 4]] > $nparams} {
                            lappend class2 $proto
                        } else {
                            # Ignore - proto has fewer than supplied params
                            # Could not be a match
                        }
                    }
                }
            }

            # For exact match (class1), we do not need the named arguments as
            # positional arguments take priority. When number of passed parameters
            # is fewer than those in prototype, check named arguments and use those
            # values. If no parameter information, we can't use named arguments
            # anyways.
            if {[info exists class1]} {
                set proto [lindex $class1 0]
            } elseif {[info exists class2]} {
                set proto [lindex $class2 0]
                # If we are passed named arguments AND the prototype also
                # has parameter name information, replace the default values
                # in the parameter definitions with the named arg value if
                # it exists.
                if {[llength $namedargs] &&
                    [llength [set paramnames [lindex $proto 5]]]} {
                    foreach {paramname paramval} $namedargs {
                        set paramindex [lsearch -nocase $paramnames $paramname]
                        if {$paramindex < 0} {
                            twapi::win32_error 0x80020004 "No parameter with name '$paramname' found for method '$name'"
                        }

                        # Set the default value field of the
                        # appropriate parameter to the named arg value
                        set paramtype [lindex $proto 4 $paramindex 0]

                        # If parameter is VT_DISPATCH or VT_VARIANT, 
                        # convert from comobj if necessary.
                        if {$paramtype == 9 || $paramtype == 12} {
                            # We do not want to change the internal type by
                            # shimmering. See similar comments in Invoke
                            if {[twapi::tcltype $paramval] ni {"" TwapiOpaque list int double bytearray dict wideInt booleanString}} {
                                if {[::twapi::comobj? $paramval]} {
                                    # Note no AddRef when getting the interface
                                    # (last param 0) because it is the C code's
                                    # responsibility based on in/out direction
                                    set paramval [$paramval -interface 0]
                                }
                            }
                        }

                        # Replace the default value field for that param def
                        lset proto 4 $paramindex [linsert [lrange [lindex $proto 4 $paramindex] 0 1] 2 $paramval]
                    }
                }
            } elseif {[info exists class3]} {
                set proto [lindex $class3 0]
            } else {
                # No prototype via typecomp / typeinfo available. No lcid worked.
                # We have to use the last resort of GetIDsOfNames
                set dispid [my @GetIDOfOneName [list $name] 0]
                # TBD - should we cache result ? Probably not.
                if {$dispid ne ""} {
                    # Note params field (last) is missing signifying we do not
                    # know prototypes
                    set proto [list $dispid 0 [lindex $invkinds 0] 8]
                } else {
                    twapi::win32_error 0x80020003 "No property or method found with name '$name'."
                }
            }

            # Need uplevel so by-ref param vars are resolved correctly
            return [uplevel 1 [list [self] Invoke $proto] $params]
        }
    }

    # Get prototype that match the specified name
    method @Prototype {name invkind lcid} {
        my variable  _ifc  _guid  _typecomp

        # Always need the GUID so get it we have not done so already
        if {![info exists _guid]} {
            my @InitTypeCompAndGuid
        }
        # Note above call may still have failed to init _guid

        # If we have been through here before and have our guid,
        # check if a prototype exists and return it. 
        if {[info exists _guid] && $_guid ne "" &&
            [::twapi::_dispatch_prototype_get $_guid $name $lcid $invkind proto]} {
            return $proto
        }

        # Not in cache, have to look for it
        # Use the ITypeComp for this interface if we do not
        # already have it. We trap any errors because we will retry with
        # different LCID's below.
        set proto {}
        if {![info exists _typecomp]} {
            my @InitTypeCompAndGuid
        }
        if {$_typecomp ne ""} {
            ::twapi::trap {

                set invkind [::twapi::_string_to_invkind $invkind]
                set lhash   [::twapi::LHashValOfName $lcid $name]

                if {![catch {$_typecomp Bind $name $lhash $invkind} binddata] &&
                    [llength $binddata]} {
                    lassign $binddata type data ifc
                    if {$type eq "funcdesc" ||
                        ($type eq "vardesc" && [::twapi::kl_get $data varkind] == 3)} {
                        set params {}
                        set bindti [::twapi::make_interface_proxy $ifc]
                        ::twapi::trap {
                            set params [::twapi::_resolve_params_for_prototype $bindti [::twapi::kl_get $data lprgelemdescParam]]
                            # Param names are needed for named arguments. Index 0 is method name so skip it
                            if {[catch {lrange [$bindti GetNames [twapi::kl_get $data memid]] 1 end} paramnames]} {
                                set paramnames {}
                            }
                        } finally {
                            $bindti Release
                        }
                        set proto [list [::twapi::kl_get $data memid] \
                                       $lcid \
                                       $invkind \
                                       [::twapi::kl_get $data elemdescFunc.tdesc] \
                                       $params $paramnames]
                    } else {
                        ::twapi::IUnknown_Release $ifc; # Don't need ifc but must release
                        twapi::debuglog "IDispatchProxy::@Prototype: Unexpected Bind type: $type, data: $data"
                    }
                }
            } onerror {} {
                # Ignore and retry with other LCID's below
            }
        }


        # If we do not have a guid return because even if we do not
        # have a proto yet,  falling through to try another lcid will not
        # help and in fact will cause infinite recursion.
        
        if {$_guid eq ""} {
            return $proto
        }

        # We do have a guid, store the proto in cache (even if negative)
        ::twapi::dispatch_prototype_set $_guid $name $lcid $invkind $proto

        # If we have the proto return it
        if {[llength $proto]} {
            return $proto
        }

        # Could not find a matching prototype from the typeinfo/typecomp.
        # We are not done yet. We will try and fall back to other lcid's
        # Note we do this AFTER setting the prototype in the cache. That
        # way we prevent (infinite) mutual recursion between lcid fallbacks.
        # The fallback sequence is $lcid -> 0 -> 1033
        # (1033 is US English). Note lcid could itself be 1033
        # default and land up being checked twice times but that's
        # ok since that's a one-time thing, and not very expensive either
        # since the second go-around will hit the cache (negative). 
        # Note the time this is really useful is when the cache has
        # been populated explicitly from a type library since in that
        # case many interfaces land up with a US ENglish lcid (MSI being
        # just one example)

        if {$lcid == 0} {
            # Note this call may further recurse and return either a
            # proto or empty (fail)
            set proto [my @Prototype $name $invkind 1033]
        } else {
            set proto [my @Prototype $name $invkind 0]
        }
        
        # Store it as *original* lcid.
        ::twapi::dispatch_prototype_set $_guid $name $lcid $invkind $proto
        
        return $proto
    }


    # Initialize _typecomp and _guid. Not in constructor because may
    # not always be required. Raises error if not available
    method @InitTypeCompAndGuid {} {
        my variable   _guid   _typecomp
        
        if {[info exists _typecomp]} {
            # Based on code below, if _typecomp exists
            # _guid also exists so no need to check for that
            return
        }

        ::twapi::trap {
            set ti [my @GetTypeInfo 0]
        } onerror {} {
            # We do not raise an error because
            # even without the _typecomp we can try invoking
            # methods via IDispatch::GetIDsOfNames
            twapi::debuglog "Could not ITypeInfo: [twapi::trapresult]"
            if {![info exists _guid]} {
                # Do not overwrite if already set thru @SetGuid or constructor
                # Set to empty otherwise so we know we tried and failed
                set _guid ""
            }
            set _typecomp ""
            return
        }

        ::twapi::trap {
            # In case of dual interfaces, we need the typeinfo for the 
            # dispatch. Again, errors handled in try handlers
            switch -exact -- [::twapi::kl_get [$ti GetTypeAttr] typekind] {
                4 {
                    # Dispatch type, fine, just what we want
                }
                3 {
                    # Interface type, Get the dispatch interface
                    set ti2 [$ti @GetRefTypeInfo [$ti GetRefTypeOfImplType -1]]
                    $ti Release
                    set ti $ti2
                }
                default {
                    error "Interface is not a dispatch interface"
                }
            }
            if {![info exists _guid]} {
                # _guid might have already been valid, do not overwrite
                set _guid [::twapi::kl_get [$ti GetTypeAttr] guid]
            }
            set _typecomp [$ti @GetTypeComp]; # ITypeComp
        } finally {
            $ti Release
        }
    }            

    # Some COM objects like MSI do not have TypeInfo interfaces from
    # where the GUID and TypeComp can be extracted. So we allow caller
    # to explicitly set the GUID so we can look up methods in the
    # dispatch prototype cache if it was populated directly by the
    # application. If guid is not a valid GUID, an attempt is made
    # to look it up as an IID name.
    method @SetGuid {guid} {
        my variable _guid
        if {$guid eq ""} {
            if {![info exists _guid]} {
                my @InitTypeCompAndGuid
            }
        } else {
            if {![::twapi::Twapi_IsValidGUID $guid]} {
                set resolved_guid [::twapi::name_to_iid $guid]
                if {$resolved_guid eq ""} {
                    error "Could not resolve $guid to a Interface GUID."
                }
                set guid $resolved_guid
            }

            if {[info exists _guid] && $_guid ne ""} {
                if {[string compare -nocase $guid $_guid]} {
                    error "Attempt to set the GUID to $guid when the dispatch proxy has already been initialized to $_guid"
                }
            } else {
                set _guid $guid
            }
        }

        return $_guid
    }

    method @GetCoClassTypeInfo {} {
        my variable _ifc

        # We can get the typeinfo for the coclass in one of two ways:
        # If the object supports IProvideClassInfo, we use it. Else
        # we try the following:
        #   - from the idispatch, we get its typeinfo
        #   - from the typeinfo, we get the containing typelib
        #   - then we search the typelib for the coclass clsid

        ::twapi::trap {
            set pci_ifc [my QueryInterface IProvideClassInfo]
            set ti_ifc [::twapi::IProvideClassInfo_GetClassInfo $pci_ifc]
            return [::twapi::make_interface_proxy $ti_ifc]
        } onerror {} {
            # Ignore - try the longer route if we were given the coclass clsid
        } finally {
            if {[info exists pci_ifc]} {
                ::twapi::IUnknown_Release $pci_ifc
            }
            # Note - do not do anything with ti_ifc here, EVEN on error
        }

        set co_clsid [my @Clsid]
        if {$co_clsid eq ""} {
            # E_FAIL
            twapi::win32_error 0x80004005 "Could not get ITypeInfo for coclass: object does not support IProvideClassInfo and clsid not specified."
        }

        set ti [my @GetTypeInfo]
        ::twapi::trap {
            set tl [lindex [$ti @GetContainingTypeLib] 0]
            if {0} {
                $tl @Foreach -guid $co_clsid -type coclass coti {
                    break
                }
                if {[info exists coti]} {
                    return $coti
                }
            } else {
                return [$tl @GetTypeInfoOfGuid $co_clsid]
            }
            twapi::win32_error 0x80004005 "Could not find coclass."; # E_FAIL
        } finally {
            if {[info exists ti]} {
                $ti Release
            }
            if {[info exists tl]} {
                $tl Release
            }
        }
    }

    twapi_exportall
}


twapi::class create ::twapi::IDispatchExProxy {
    superclass ::twapi::IDispatchProxy

    method DeleteMemberByDispID {dispid} {
        my variable _ifc
        return [::twapi::IDispatchEx_DeleteMemberByDispID $_ifc $dispid]
    }

    method DeleteMemberByName {name {lcid 0}} {
        my variable _ifc
        return [::twapi::IDispatchEx_DeleteMemberByName $_ifc $name $lcid]
    }

    method GetDispID {name flags} {
        my variable _ifc
        return [::twapi::IDispatchEx_GetDispID $_ifc $name $flags]
    }

    method GetMemberName {dispid} {
        my variable _ifc
        return [::twapi::IDispatchEx_GetMemberName $_ifc $dispid]
    }

    method GetMemberProperties {dispid flags} {
        my variable _ifc
        return [::twapi::IDispatchEx_GetMemberProperties $_ifc $dispid $flags]
    }

    # For some reason, order of args is different for this call!
    method GetNextDispID {flags dispid} {
        my variable _ifc
        return [::twapi::IDispatchEx_GetNextDispID $_ifc $flags $dispid]
    }

    method GetNameSpaceParent {} {
        my variable _ifc
        return [::twapi::IDispatchEx_GetNameSpaceParent $_ifc]
    }

    method @GetNameSpaceParent {} {
        return [::twapi::make_interface_proxy [my GetNameSpaceParent]]
    }

    method @Prototype {name invkind {lcid 0}} {
        set invkind [::twapi::_string_to_invkind $invkind]

        # First try IDispatch
        ::twapi::trap {
            set proto [next $name $invkind $lcid]
            if {[llength $proto]} {
                return $proto
            }
            # Note negative results ignored, as new members may be added/deleted
            # to an IDispatchEx at any time. We will try below another way.

        } onerror {} {
            # Ignore the error - we will try below using another method
        }

        # Not a simple dispatch interface method. Could be expando
        # type which is dynamically created. NOTE: The member is NOT
        # created until the GetDispID call is made.

        # 10 -> case insensitive, create if required
        set dispid [my GetDispID $name 10]

        # IMPORTANT : prototype retrieval results MUST NOT be cached since
        # underlying object may add/delete members at any time.

        # No type information is available for dynamic members.
        # TBD - is that really true?
        
        # Invoke kind - 1 (method), 2 (propget), 4 (propput)
        if {$invkind == 1} {
            # method
            set flags 0x100
        } elseif {$invkind == 2} {
            # propget
            set flags 0x1
        } elseif {$invkind == 4} {
            # propput
            set flags 0x4
        } else {
            # TBD - what about putref (flags 0x10)
            error "Internal error: Invalid invkind value $invkind"
        }

        # Try at least getting the invocation type but even that is not
        # supported by all objects in which case we assume it can be invoked.
        # TBD - in that case, why even bother doing GetMemberProperties?
        if {! [catch {
            set flags [expr {[my GetMemberProperties 0x115] & $flags}]
        }]} {
            if {! $flags} {
                return {};      # EMpty proto -> no valid name for this invkind
            }
        }

        # Valid invkind or object does not support GetMemberProperties
        # Return type is 8 (BSTR) but does not really matter as 
        # actual type will be set based on what is returned.
        return [list $dispid $lcid $invkind 8]
    }

    twapi_exportall
}


# ITypeInfo 
#-----------

twapi::class create ::twapi::ITypeInfoProxy {
    superclass ::twapi::IUnknownProxy

    method GetRefTypeOfImplType {index} {
        my variable _ifc
        return [::twapi::ITypeInfo_GetRefTypeOfImplType $_ifc $index]
    }

    method GetDocumentation {memid} {
        my variable _ifc
        return [::twapi::ITypeInfo_GetDocumentation $_ifc $memid]
    }

    method GetImplTypeFlags {index} {
        my variable _ifc
        return [::twapi::ITypeInfo_GetImplTypeFlags $_ifc $index]
    }

    method GetNames {index} {
        my variable _ifc
        return [::twapi::ITypeInfo_GetNames $_ifc $index]
    }

    method GetTypeAttr {} {
        my variable _ifc
        return [::twapi::ITypeInfo_GetTypeAttr $_ifc]
    }

    method GetFuncDesc {index} {
        my variable _ifc
        return [::twapi::ITypeInfo_GetFuncDesc $_ifc $index]
    }

    method GetVarDesc {index} {
        my variable _ifc
        return [::twapi::ITypeInfo_GetVarDesc $_ifc $index]
    }

    method GetIDsOfNames {names} {
        my variable _ifc
        return [::twapi::ITypeInfo_GetIDsOfNames $_ifc $names]
    }

    method GetRefTypeInfo {hreftype} {
        my variable _ifc
        return [::twapi::ITypeInfo_GetRefTypeInfo $_ifc $hreftype]
    }

    method @GetRefTypeInfo {hreftype} {
        return [::twapi::make_interface_proxy [my GetRefTypeInfo $hreftype]]
    }

    method GetTypeComp {} {
        my variable _ifc
        return [::twapi::ITypeInfo_GetTypeComp $_ifc]
    }

    method @GetTypeComp {} {
        return [::twapi::make_interface_proxy [my GetTypeComp]]
    }

    method GetContainingTypeLib {} {
        my variable _ifc
        return [::twapi::ITypeInfo_GetContainingTypeLib $_ifc]
    }

    method @GetContainingTypeLib {} {
        lassign [my GetContainingTypeLib] itypelib index
        return [list [::twapi::make_interface_proxy $itypelib] $index]
    }

    method @GetRefTypeInfoFromIndex {index} {
        return [my @GetRefTypeInfo [my GetRefTypeOfImplType $index]]
    }

    # Friendlier version of GetTypeAttr
    method @GetTypeAttr {args} {

        array set opts [::twapi::parseargs args {
            all
            guid
            lcid
            constructorid
            destructorid
            schema
            instancesize
            typekind
            fncount
            varcount
            interfacecount
            vtblsize
            alignment
            majorversion
            minorversion
            aliasdesc
            flags
            idldesc
            memidmap
        } -maxleftover 0]

        array set data [my GetTypeAttr]
        set result [list ]
        foreach {opt key} {
            guid guid
            lcid lcid
            constructorid memidConstructor
            destructorid  memidDestructor
            schema lpstrSchema
            instancesize cbSizeInstance
            fncount cFuncs
            varcount cVars
            interfacecount cImplTypes
            vtblsize cbSizeVft
            alignment cbAlignment
            majorversion wMajorVerNum
            minorversion wMinorVerNum
            aliasdesc tdescAlias
        } {
            if {$opts(all) || $opts($opt)} {
                lappend result -$opt $data($key)
            }
        }

        if {$opts(all) || $opts(typekind)} {
            set typekind $data(typekind)
            if {[info exists ::twapi::_typekind_map($typekind)]} {
                set typekind $::twapi::_typekind_map($typekind)
            }
            lappend result -typekind $typekind
        }

        if {$opts(all) || $opts(flags)} {
            lappend result -flags [::twapi::_make_symbolic_bitmask $data(wTypeFlags) {
                appobject       1
                cancreate       2
                licensed        4
                predeclid       8
                hidden         16
                control        32
                dual           64
                nonextensible 128
                oleautomation 256
                restricted    512
                aggregatable 1024
                replaceable  2048
                dispatchable 4096
                reversebind  8192
                proxy       16384
            }]
        }

        if {$opts(all) || $opts(idldesc)} {
            lappend result -idldesc [::twapi::_make_symbolic_bitmask $data(idldescType) {
                in 1
                out 2
                lcid 4
                retval 8
            }]
        }

        if {$opts(all) || $opts(memidmap)} {
            set memidmap [list ]
            for {set i 0} {$i < $data(cFuncs)} {incr i} {
                array set fninfo [my @GetFuncDesc $i -memid -name]
                lappend memidmap $fninfo(-memid) $fninfo(-name)
            }
            lappend result -memidmap $memidmap
        }

        return $result
    }

    #
    # Get a variable description associated with a type
    method @GetVarDesc {index args} {
        # TBD - add support for retrieving elemdescVar.paramdesc fields

        array set opts [::twapi::parseargs args {
            all
            name
            memid
            schema
            datatype
            value
            valuetype
            varkind
            flags
        } -maxleftover 0]

        array set data [my GetVarDesc $index]
        
        set result [list ]
        foreach {opt key} {
            memid memid
            schema lpstrSchema
            datatype elemdescVar.tdesc
        } {
            if {$opts(all) || $opts($opt)} {
                lappend result -$opt $data($key)
            }
        }


        if {$opts(all) || $opts(value)} {
            if {[info exists data(lpvarValue)]} {
                # Const value
                lappend result -value [lindex $data(lpvarValue) 1]
            } else {
                lappend result -value $data(oInst)
            }
        }

        if {$opts(all) || $opts(valuetype)} {
            if {[info exists data(lpvarValue)]} {
                lappend result -valuetype [lindex $data(lpvarValue) 0]
            } else {
                lappend result -valuetype int
            }
        }

        if {$opts(all) || $opts(varkind)} {
            lappend result -varkind [::twapi::kl_get {
                0 perinstance
                1 static
                2 const
                3 dispatch
            } $data(varkind) $data(varkind)]
        }

        if {$opts(all) || $opts(flags)} {
            lappend result -flags [::twapi::_make_symbolic_bitmask $data(wVarFlags) {
                readonly       1
                source       2
                bindable        4
                requestedit       8
                displaybind         16
                defaultbind        32
                hidden           64
                restricted 128
                defaultcollelem 256
                uidefault    512
                nonbrowsable 1024
                replaceable  2048
                immediatebind 4096
            }]
        }
        
        if {$opts(all) || $opts(name)} {
            set result [concat $result [my @GetDocumentation $data(memid) -name]]
        }    

        return $result
    }

    method @GetFuncDesc {index args} {
        array set opts [::twapi::parseargs args {
            all
            name
            memid
            funckind
            invkind
            callconv
            params
            paramnames
            flags
            datatype
            resultcodes
            vtbloffset
        } -maxleftover 0]

        array set data [my GetFuncDesc $index]
        set result [list ]

        if {$opts(all) || $opts(paramnames)} {
            lappend result -paramnames [lrange [my GetNames $data(memid)] 1 end]
        }
        foreach {opt key} {
            memid       memid
            vtbloffset  oVft
            datatype    elemdescFunc.tdesc
            resultcodes lprgscode
        } {
            if {$opts(all) || $opts($opt)} {
                lappend result -$opt $data($key)
            }
        }

        if {$opts(all) || $opts(funckind)} {
            lappend result -funckind [::twapi::kl_get {
                0 virtual
                1 purevirtual
                2 nonvirtual
                3 static
                4 dispatch
            } $data(funckind) $data(funckind)]
        }

        if {$opts(all) || $opts(invkind)} {
            lappend result -invkind [::twapi::_string_to_invkind $data(invkind)]
        }

        if {$opts(all) || $opts(callconv)} {
            lappend result -callconv [::twapi::kl_get {
                0 fastcall
                1 cdecl
                2 pascal
                3 macpascal
                4 stdcall
                5 fpfastcall
                6 syscall
                7 mpwcdecl
                8 mpwpascal
            } $data(callconv) $data(callconv)]
        }

        if {$opts(all) || $opts(flags)} {
            lappend result -flags [::twapi::_make_symbolic_bitmask $data(wFuncFlags) {
                restricted   1
                source       2
                bindable     4
                requestedit  8
                displaybind  16
                defaultbind  32
                hidden       64
                usesgetlasterror  128
                defaultcollelem 256
                uidefault    512
                nonbrowsable 1024
                replaceable  2048
                immediatebind 4096
            }]
        }

        if {$opts(all) || $opts(params)} {
            set params [list ]
            foreach param $data(lprgelemdescParam) {
                lassign $param paramtype paramdesc
                set paramflags [::twapi::_paramflags_to_tokens [lindex $paramdesc 0]]
                if {[llength $paramdesc] > 1} {
                    # There is a default value associated with the parameter
                    lappend params [list $paramtype $paramflags [lindex $paramdesc 1]]
                } else {
                    lappend params [list $paramtype $paramflags]
                }
            }
            lappend result -params $params
        }

        if {$opts(all) || $opts(name)} {
            set result [concat $result [my @GetDocumentation $data(memid) -name]]
        }    

        return $result
    }

    #
    # Get documentation for a element of a type
    method @GetDocumentation {memid args} {
        array set opts [::twapi::parseargs args {
            all
            name
            docstring
            helpctx
            helpfile
        } -maxleftover 0]

        lassign [my GetDocumentation $memid] name docstring helpctx helpfile

        set result [list ]
        foreach opt {name docstring helpctx helpfile} {
            if {$opts(all) || $opts($opt)} {
                lappend result -$opt [set $opt]
            }
        }
        return $result
    }

    method @GetName {{memid -1}} {
        return [lindex [my @GetDocumentation $memid -name] 1]
    }

    method @GetImplTypeFlags {index} {
        return [::twapi::_make_symbolic_bitmask \
                    [my GetImplTypeFlags $index] \
                    {
                        default      1
                        source       2
                        restricted   4
                        defaultvtable 8
                    }]  
    }

    #
    # Get the typeinfo for the default source interface of a coclass
    # This object must be the typeinfo of the coclass
    method @GetDefaultSourceTypeInfo {} {
        set count [lindex [my @GetTypeAttr -interfacecount] 1]
        for {set i 0} {$i < $count} {incr i} {
            set flags [my GetImplTypeFlags $i]
            # default 0x1, source 0x2
            if {($flags & 3) == 3} {
                # Our source interface implementation can only handle IDispatch
                # so check if the source interface is that else keep looking.
                # We even ignore dual interfaces because we cannot then
                # assume caller will use the dispatch version
                set ti [my @GetRefTypeInfoFromIndex $i]
                array set typeinfo [$ti GetTypeAttr]
                # typekind == 4 -> IDispatch,
                # flags - 0x1000 -> dispatchable, 0x40 -> dual
                if {$typeinfo(typekind) == 4 &&
                    ($typeinfo(wTypeFlags) & 0x1000) &&
                    !($typeinfo(wTypeFlags) & 0x40)} {
                    return $ti
                }
                $ti destroy
            }
        }
        return ""
    }

    twapi_exportall
}


# ITypeLib
#----------

twapi::class create ::twapi::ITypeLibProxy {
    superclass ::twapi::IUnknownProxy

    method GetDocumentation {index} {
        my variable _ifc
        return [::twapi::ITypeLib_GetDocumentation $_ifc $index]
    }
    method GetTypeInfoCount {} {
        my variable _ifc
        return [::twapi::ITypeLib_GetTypeInfoCount $_ifc]
    }
    method GetTypeInfoType {index} {
        my variable _ifc
        return [::twapi::ITypeLib_GetTypeInfoType $_ifc $index]
    }
    method GetLibAttr {} {
        my variable _ifc
        return [::twapi::ITypeLib_GetLibAttr $_ifc]
    }
    method GetTypeInfo {index} {
        my variable _ifc
        return [::twapi::ITypeLib_GetTypeInfo $_ifc $index]
    }
    method @GetTypeInfo {index} {
        return [::twapi::make_interface_proxy [my GetTypeInfo $index]]
    }
    method GetTypeInfoOfGuid {guid} {
        my variable _ifc
        return [::twapi::ITypeLib_GetTypeInfoOfGuid $_ifc $guid]
    }
    method @GetTypeInfoOfGuid {guid} {
        return [::twapi::make_interface_proxy [my GetTypeInfoOfGuid $guid]]
    }
    method @GetTypeInfoType {index} {
        set typekind [my GetTypeInfoType $index]
        if {[info exists ::twapi::_typekind_map($typekind)]} {
            set typekind $::twapi::_typekind_map($typekind)
        }
        return $typekind
    }

    method @GetDocumentation {id args} {
        array set opts [::twapi::parseargs args {
            all
            name
            docstring
            helpctx
            helpfile
        } -maxleftover 0]

        lassign [my GetDocumentation $id] name docstring helpctx helpfile
        set result [list ]
        foreach opt {name docstring helpctx helpfile} {
            if {$opts(all) || $opts($opt)} {
                lappend result -$opt [set $opt]
            }
        }
        return $result
    }

    method @GetName {} {
        return [lindex [my GetDocumentation -1] 0]
    }

    method @GetLibAttr {args} {
        array set opts [::twapi::parseargs args {
            all
            guid
            lcid
            syskind
            majorversion
            minorversion
            flags
        } -maxleftover 0]

        array set data [my GetLibAttr]
        set result [list ]
        foreach {opt key} {
            guid guid
            lcid lcid
            majorversion wMajorVerNum
            minorversion wMinorVerNum
        } {
            if {$opts(all) || $opts($opt)} {
                lappend result -$opt $data($key)
            }
        }

        if {$opts(all) || $opts(flags)} {
            lappend result -flags [::twapi::_make_symbolic_bitmask $data(wLibFlags) {
                restricted      1
                control         2
                hidden          4
                hasdiskimage    8
            }]
        }

        if {$opts(all) || $opts(syskind)} {
            lappend result -syskind [::twapi::kl_get {
                0 win16
                1 win32
                2 mac
            } $data(syskind) $data(syskind)]
        }

        return $result
    }

    #
    # Iterate through a typelib. Caller is responsible for releasing
    # each ITypeInfo passed to it
    # 
    method @Foreach {args} {

        array set opts [::twapi::parseargs args {
            type.arg
            name.arg
            guid.arg
        } -maxleftover 2 -nulldefault]

        if {[llength $args] != 2} {
            error "Syntax error: Should be '[self] @Foreach ?options? VARNAME SCRIPT'"
        }

        lassign $args varname script
        upvar $varname varti

        set count [my GetTypeInfoCount]
        for {set i 0} {$i < $count} {incr i} {
            if {$opts(type) ne "" && $opts(type) ne [my @GetTypeInfoType $i]} {
                continue;                   # Type does not match
            }
            if {$opts(name) ne "" &&
                [string compare -nocase $opts(name) [lindex [my @GetDocumentation $i -name] 1]]} {
                continue;                   # Name does not match
            }
            set ti [my @GetTypeInfo $i]
            if {$opts(guid) ne ""} {
                if {[string compare -nocase [lindex [$ti @GetTypeAttr -guid] 1] $opts(guid)]} {
                    $ti Release
                    continue
                }
            }
            set varti $ti
            set ret [catch {uplevel 1 $script} result]
            switch -exact -- $ret {
                1 {
                    error $result $::errorInfo $::errorCode
                }
                2 {
                    return -code return $result; # TCL_RETURN
                }
                3 {
                    set i $count; # TCL_BREAK
                }
            }
        }
        return
    }

    method @Register {path {helppath ""}} {
        my variable _ifc
        ::twapi::RegisterTypeLib $_ifc $path $helppath
    }

    method @LoadDispatchPrototypes {} {
        set data [my @Read -type dispatch]
        if {![dict exists $data dispatch]} {
            return
        }

        dict for {guid guiddata} [dict get $data dispatch] {
            foreach type {methods properties} {
                if {[dict exists $guiddata -$type]} {
                    dict for {name namedata} [dict get $guiddata -$type] {
                        dict for {lcid lciddata} $namedata {
                            dict for {invkind proto} $lciddata {
                                ::twapi::dispatch_prototype_set \
                                    $guid $name $lcid $invkind $proto
                            }
                        }
                    }
                }
            }
        }
    }

    method @Text {args} {
        array set opts [::twapi::parseargs args {
            type.arg
            name.arg
        } -maxleftover 0 -nulldefault]

        set text {}
        my @Foreach -type $opts(type) -name $opts(name) ti {
            ::twapi::trap {
                array set attrs [$ti @GetTypeAttr -all]
                set docs [$ti @GetDocumentation -1 -name -docstring]
                set desc "[string totitle $attrs(-typekind)] [::twapi::kl_get $docs -name] $attrs(-guid) - [::twapi::kl_get $docs -docstring]\n"
                switch -exact -- $attrs(-typekind) {
                    record -
                    union  -
                    enum {
                        for {set j 0} {$j < $attrs(-varcount)} {incr j} {
                            array set vardata [$ti @GetVarDesc $j -all]
                            set vardesc "$vardata(-varkind) [::twapi::_resolve_com_type_text $ti $vardata(-datatype)] $vardata(-name)"
                            if {$attrs(-typekind) eq "enum"} {
                                append vardesc " = $vardata(-value) ([::twapi::_resolve_com_type_text $ti $vardata(-valuetype)])"
                            } else {
                                append vardesc " (offset $vardata(-value))"
                            }
                            append desc "\t$vardesc\n"
                        }
                    }
                    alias {
                        append desc "\ttypedef $attrs(-aliasdesc)\n"
                    }
                    module -
                    dispatch -
                    interface {
                        append desc [::twapi::_interface_text $ti]
                    }
                    coclass {
                        for {set j 0} {$j < $attrs(-interfacecount)} {incr j} {
                            set ti2 [$ti @GetRefTypeInfoFromIndex $j]
                            set idesc [$ti2 @GetName]
                            set iflags [$ti @GetImplTypeFlags $j]
                            if {[llength $iflags]} {
                                append idesc " ([join $iflags ,])"
                            }
                            append desc \t$idesc
                            $ti2 Release
                            unset ti2
                        }
                    }
                    default {
                        append desc "Unknown typekind: $attrs(-typekind)\n"
                    }
                }
                append text \n$desc
            } finally {
                $ti Release
                if {[info exists ti2]} {
                    $ti2 Release
                }
            }
        }
        return $text
    }

    method @GenerateCode {args} {
        array set opts [twapi::parseargs args {
            namespace.arg
        } -ignoreunknown]

        if {![info exists opts(namespace)]} {
            set opts(namespace) [string tolower [my @GetName]]
        }

        set data [my @Read {*}$args]
        
        set code {}
        if {[dict exists $data dispatch]} {
            dict for {guid guiddata} [dict get $data dispatch] {
                set dispatch_name [dict get $guiddata -name]
                append code "\n# Dispatch Interface $dispatch_name\n"
                foreach type {methods properties} {
                    if {[dict exists $guiddata -$type]} {
                        append code "# $dispatch_name [string totitle $type]\n"
                        dict for {name namedata} [dict get $guiddata -$type] {
                            dict for {lcid lciddata} $namedata {
                                dict for {invkind proto} $lciddata {
                                    append code [list ::twapi::dispatch_prototype_set \
                                                     $guid $name $lcid $invkind $proto]
                                    append code \n
                                }
                            }
                        }
                    }
                }
            }
        }

        # If namespace specfied as empty string (as opposed to unspecified)
        # do not output a namespace
        if {$opts(namespace) ne "" &&
            ([dict exists $data enum] ||
             [dict exists $data module] ||
             [dict exists $data coclass])
        } {
            append code "\nnamespace eval $opts(namespace) \{"
            append code \n
        }

        if {[dict exists $data module]} {
            dict for {guid guiddata} [dict get $data module] {
                # Some modules may not have constants (-values).
                # We currently only output constants from modules, not functions
                if {[dict exists $guiddata -values]} {
                    set module_name [dict get $guiddata -name]
                    append code "\n    # Module $module_name ($guid)\n"
                    append code "    [list array set $module_name [dict get $guiddata -values]]"
                    append code \n
                }
            }
        }

        if {[dict exists $data enum]} {
            dict for {name def} [dict get $data enum] {
                append code "\n    # Enum $name\n"
                append code "    [list array set $name [dict get $def -values]]"
                append code \n
            }
        }

        if {[dict exists $data coclass]} {
            dict for {guid def} [dict get $data coclass] {
                append code "\n    # Coclass [dict get $def -name]"
                # Look for the default interface so we can remember its GUID.
                # This is necessary for the cases where the Dispatch interface
                # GUID is not available via a TypeInfo interface (e.g.
                # a 64-bit COM component not registered with the 32-bit
                # COM registry)
                set default_dispatch_guid ""
                if {[dict exists $def -interfaces]} {
                    dict for {ifc_guid ifc_def} [dict get $def -interfaces] {
                        if {[dict exists $data dispatch $ifc_guid]} {
                            # Yes it is a dispatch interface
                            # Make sure it is marked as default interface
                            if {[dict exists $ifc_def -flags] &&
                                [dict get $ifc_def -flags] == 1} {
                                set default_dispatch_guid $ifc_guid
                                break
                            }
                        }
                    }
                }
                
                # We assume here that coclass has a default interface
                # which is dispatchable. Else an error will be generated
                # at runtime.
                append code [format {
    twapi::class create %1$s {
        superclass ::twapi::Automation
        constructor {args} {
            set ifc [twapi::com_create_instance "%2$s" -interface IDispatch -raw {*}$args]
            next [twapi::IDispatchProxy new $ifc "%2$s"]
            if {[string length "%3$s"]} {
                my -interfaceguid "%3$s"
            }
        }
    }} [dict get $def -name] $guid $default_dispatch_guid]
                append code \n
            }
        }

        if {$opts(namespace) ne "" &&
            ([dict exists $data enum] ||
             [dict exists $data module] ||
             [dict exists $data coclass])
        } {
            append code "\}"
            append code \n
        }


        return $code
    }

    method @Read {args} {
        array set opts [::twapi::parseargs args {
            type.arg
            name.arg
        } -maxleftover 0 -nulldefault]

        set data [dict create]
        my @Foreach -type $opts(type) -name $opts(name) ti {
            ::twapi::trap {
                array set attrs [$ti @GetTypeAttr -guid -lcid -varcount -fncount -interfacecount -typekind]
                set name [lindex [$ti @GetDocumentation -1 -name] 1]
                # dict set data $attrs(-typekind) $name {}
                switch -exact -- $attrs(-typekind) {
                    record -
                    union  -
                    enum {
                        # For consistency with the coclass and dispatch dict structure
                        # we have a separate key for 'name' even though it is the same
                        # as the dict key
                        dict set data $attrs(-typekind) $name -name $name
                        for {set j 0} {$j < $attrs(-varcount)} {incr j} {
                            array set vardata [$ti @GetVarDesc $j -name -value]
                            dict set data $attrs(-typekind) $name -values $vardata(-name) $vardata(-value)
                        }
                    }
                    alias {
                        # TBD - anything worth importing ?
                    }
                    dispatch {
                        # Load up the functions
                        dict set data $attrs(-typekind) $attrs(-guid) -name $name
                        for {set j 0} {$j < $attrs(-fncount)} {incr j} {
                            array set funcdata [$ti GetFuncDesc $j]
                            if {$funcdata(funckind) != 4} {
                                # Not a dispatch function (4), ignore
                                # TBD - what else could it be if already filtering
                                # typeinfo on dispatch
                                # Vtable set funckind "(vtable $funcdata(-oVft))"
                                ::twapi::debuglog "Unexpected funckind value '$funcdata(funckind)' ignored. funcdata: [array get funcdata]"
                                continue;
                            }
                            
                            set proto [list $funcdata(memid) \
                                           $attrs(-lcid) \
                                           $funcdata(invkind) \
                                           $funcdata(elemdescFunc.tdesc) \
                                           [::twapi::_resolve_params_for_prototype $ti $funcdata(lprgelemdescParam)]]
                            # Param names are needed for named arguments. Index 0 is method name so skip it
                            if {[catch {lappend proto [lrange [$ti GetNames $funcdata(memid)] 1 end]}]} {
                                # Could not get param names
                                lappend proto {}
                            }

                            dict set data "$attrs(-typekind)" \
                                $attrs(-guid) \
                                -methods \
                                [$ti @GetName $funcdata(memid)] \
                                $attrs(-lcid) \
                                $funcdata(invkind) \
                                $proto
                        }
                        # Load up the properties
                        for {set j 0} {$j < $attrs(-varcount)} {incr j} {
                            array set vardata [$ti GetVarDesc $j]
                            # We will add both propput and propget.
                            # propget:
                            dict set data "$attrs(-typekind)" \
                                $attrs(-guid) \
                                -properties \
                                [$ti @GetName $vardata(memid)] \
                                $attrs(-lcid) \
                                2 \
                                [list $vardata(memid) $attrs(-lcid) 2 $vardata(elemdescVar.tdesc) {} {}]

                            # TBD - mock up the parameters for the property set
                            # Single parameter corresponding to return type of
                            # property. Param list is of the form
                            # {PARAM1 PARAM2} where PARAM is {TYPE {FLAGS ?DEFAULT}}
                            # So param list with one param is
                            # {{TYPE {FLAGS ?DEFAULT?}}}
                            # propput:
                            if {! ($vardata(wVarFlags) & 1)} {
                                # Not read-only
                                dict set data "$attrs(-typekind)" \
                                    $attrs(-guid) \
                                    -properties \
                                    [$ti @GetName $vardata(memid)] \
                                    $attrs(-lcid) \
                                    4 \
                                    [list $vardata(memid) $attrs(-lcid) 4 24 [list [list $vardata(elemdescVar.tdesc) [list 1]]] {}]
                            }
                        }
                    }


                    module {
                        dict set data $attrs(-typekind) $attrs(-guid) -name $name
                        # TBD - Load up the functions

                        # Now load up the variables
                        for {set j 0} {$j < $attrs(-varcount)} {incr j} {
                            array set vardata [$ti @GetVarDesc $j -name -value]
                            dict set data $attrs(-typekind) $attrs(-guid) -values $vardata(-name) $vardata(-value)
                        }
                    }

                    interface {
                        # TBD
                    }
                    coclass {
                        dict set data "coclass" $attrs(-guid) -name $name
                        for {set j 0} {$j < $attrs(-interfacecount)} {incr j} {
                            set ti2 [$ti @GetRefTypeInfoFromIndex $j]
                            set iflags [$ti GetImplTypeFlags $j]
                            set iguid [twapi::kl_get [$ti2 GetTypeAttr] guid]
                            set iname [$ti2 @GetName]
                            $ti2 Release
                            unset ti2; # So finally clause does not relese again on error

                            dict set data "coclass" $attrs(-guid) -interfaces $iguid -name $iname
                            dict set data "coclass" $attrs(-guid) -interfaces $iguid -flags $iflags
                        }
                    }
                    default {
                        # TBD
                    }
                }
            } finally {
                $ti Release
                if {[info exists ti2]} {
                    $ti2 Release
                }
            }
        }
        return $data
    }

    twapi_exportall
}

# ITypeComp
#----------
twapi::class create ::twapi::ITypeCompProxy {
    superclass ::twapi::IUnknownProxy

    method Bind {name lhash flags} {
        my variable _ifc
        return [::twapi::ITypeComp_Bind $_ifc $name $lhash $flags]
    }

    # Returns empty list if bind not found
    method @Bind {name flags {lcid 0}} {
        ::twapi::trap {
            set binding [my Bind $name [::twapi::LHashValOfName $lcid $name] $flags]
        } onerror {TWAPI_WIN32 0x80028ca0} {
            # Found but type mismatch (flags not correct)
            return {}
        }

        lassign $binding type data tifc
        return [list $type $data [::twapi::make_interface_proxy $tifc]]
    }

    twapi_exportall
}

# IEnumVARIANT
#-------------

twapi::class create ::twapi::IEnumVARIANTProxy {
    superclass ::twapi::IUnknownProxy

    method Next {count {value_only 0}} {
        my variable _ifc
        return [::twapi::IEnumVARIANT_Next $_ifc $count $value_only]
    }
    method Clone {} {
        my variable _ifc
        return [::twapi::IEnumVARIANT_Clone $_ifc]
    }
    method @Clone {} {
        return [::twapi::make_interface_proxy [my Clone]]
    }
    method Reset {} {
        my variable _ifc
        return [::twapi::IEnumVARIANT_Reset $_ifc]
    }
    method Skip {count} {
        my variable _ifc
        return [::twapi::IEnumVARIANT_Skip $_ifc $count]
    }

    twapi_exportall
}

# Automation
#-----------
twapi::class create ::twapi::Automation {

    # Caller gives up ownership of proxy in all cases, even errors.
    # $proxy will eventually be Release'ed. If caller wants to keep
    # a reference to it, it must do an *additional* AddRef on it to
    # keep it from going away when the Automation object releases it.
    constructor {proxy {lcid 0}} {
        my variable _proxy _lcid  _sinks _connection_pts

        set type [$proxy @Type]
        if {$type ne "IDispatch" && $type ne "IDispatchEx"} {
            $proxy Release;     # Even on error, responsible for releasing
            error "Automation objects do not support interfaces of type '$type'"
        }
        if {$type eq "IDispatchEx"} {
            my variable _have_dispex
            # If _have_dispex variable
            #   - does not exist, have not tried to get IDispatchEx yet
            #   - is 0, have tried but failed
            #   - is 1, already have IDispatchEx
            set _have_dispex 1
        }

        set _proxy $proxy
        set _lcid $lcid
        array set _sinks {}
        array set _connection_pts {}
    }

    destructor {
        my variable _proxy  _sinks

        # Release sinks, connection points
        foreach sinkid [array names _sinks] {
            my -unbind $sinkid
        }

        if {[info exists _proxy]} {
            $_proxy Release
        }
        return
    }

    # Intended to be called only from another method. Not directly.
    # Does an uplevel 2 to get to application context.
    # On failures, retries with IDispatchEx interface
    # TBD - get rid of this uplevel business by having internal
    # callers to equivalent of "uplevel 1 my _invoke ...
    method _invoke {name invkinds params args} {
        my variable  _proxy  _lcid

        if {[$_proxy @Null?]} {
            error "Attempt to invoke method $name on NULL COM object"
        }

        array set opts [twapi::parseargs args {
            raw.bool
            namedargs.arg
        } -nulldefault -maxleftover 0]

        ::twapi::trap {
            set vtval [uplevel 2 [list $_proxy @Invoke $name $invkinds $_lcid $params $opts(namedargs)]]
            if {$opts(raw)} {
                return $vtval
            } else {
                return [::twapi::variant_value $vtval 0 0 $_lcid]
            }
        } onerror {} {
            # TBD - should we only drop down below to check for IDispatchEx
            # for specific error codes. Right now we do it for all.
            set erinfo $::errorInfo
            set ercode $::errorCode
            set ermsg [::twapi::trapresult]
        }

        # We plan on trying to get a IDispatchEx interface in case
        # the method/property is the "expando" type
        my variable  _have_dispex
        if {[info exists _have_dispex]} {
            # We have already tried for IDispatchEx, either successfully
            # or not. Either way, no need to try again
            error $ermsg $erinfo $ercode
        }

        # Try getting a IDispatchEx interface
        if {[catch {$_proxy @QueryInterface IDispatchEx 1} proxy_ex] ||
            $proxy_ex eq ""} {
            set _have_dispex 0
            error $ermsg $erinfo $ercode
        }

        set _have_dispex 1
        $_proxy Release
        set _proxy $proxy_ex
        
        # Retry with the IDispatchEx interface
        set vtval [uplevel 2 [list $_proxy @Invoke $name $invkinds $_lcid $params $opts(namedargs)]]
        if {$opts(raw)} {
            return $vtval
        } else {
            return [::twapi::variant_value $vtval 0 0 $_lcid]
        }
    }

    method -get {name args} {
        return [my _invoke $name [list 2] $args]
    }

    method -set {name args} {
        return [my _invoke $name [list 4] $args]
    }

    method -call {name args} {
        return [my _invoke $name [list 1] $args]
    }

    method -callnamedargs {name args} {
        return [my _invoke $name [list 1] {} -namedargs $args]
    }

    # Need a wrapper around _invoke in order for latter's uplevel 2
    # to work correctly
    # TBD - document, test
    method -invoke {name invkinds params args} {
        return [my _invoke $name $invkinds $params {*}$args]
    }

    method -destroy {} {
        my destroy
    }

    method -isnull {} {
        my variable _proxy
        return [$_proxy @Null?]
    }

    method -default {} {
        my variable _proxy _lcid
        return [::twapi::variant_value [$_proxy Invoke ""] 0 0 $_lcid]
    }

    # Caller must call release on the proxy
    method -proxy {} {
        my variable _proxy
        $_proxy AddRef
        return $_proxy
    }

    # Only for debugging
    method -proxyrefcounts {} {
        my variable _proxy
        return [$_proxy DebugRefCounts]
    }

    # Returns the raw interface. Caller must call IUnknownRelease on it
    # iff addref is passed as true (default)
    method -interface {{addref 1}} {
        my variable _proxy
        return [$_proxy @Interface $addref]
    }

    # Validates internal structures
    method -validate {} {
        twapi::ValidateIUnknown [my -interface 0]
    }

    # Set/return the GUID for the interface
    method -interfaceguid {{guid ""}} {
        my variable _proxy
        return [$_proxy @SetGuid $guid]
    }

    # Return the disp id for a method/property
    method -dispid {name} {
        my variable _proxy
        return [$_proxy @GetIDOfOneName $name]
    }

    # Prints methods in an interface
    method -print {} {
        my variable _proxy
        ::twapi::dispatch_print $_proxy
    }

    method -with {subobjlist args} {
        # $obj -with SUBOBJECTPATHLIST arguments
        # where SUBOBJECTPATHLIST is list each element of which is
        # either a property or a method of the previous element in
        # the list. The element may itself be a list in which case
        # the first element is the property/method and remaining
        # are passed to it
        #
        # Note that 'arguments' may themselves be comobj subcommands!
        set next [self]
        set releaselist [list ]
        ::twapi::trap {
            while {[llength $subobjlist]} {
                set nextargs [lindex $subobjlist 0]
                set subobjlist [lrange $subobjlist 1 end]
                set next [uplevel 1 [list $next] $nextargs]
                lappend releaselist $next
            }
            # We use uplevel here because again we want to run in caller
            # context 
            return [uplevel 1 [list $next] $args]
        } finally {
            foreach next $releaselist {
                $next -destroy
            }
        }
    }

    method -iterate {args} {
        my variable _lcid

        array set opts [::twapi::parseargs args {
            cleanup
        }]

        if {[llength $args] < 2} {
            error "Syntax: COMOBJ -iterate ?options? VARNAME SCRIPT"
        }
        upvar 1 [lindex $args 0] var
        set script [lindex $args 1]

        # TBD - need more comprehensive test cases when return/break/continue
        # are used in the script

        # First get IEnumVariant iterator using the _NewEnum method
        # TBD - As per MS OLE Automation spec, it appears _NewEnum
        # MUST have dispid -4. Can we use this information when
        # this object does not have an associated interface guid or
        # when no prototype is available ?
        set enumerator [my -get _NewEnum]
        # This gives us an IUnknown.
        ::twapi::trap {
            # Convert the IUnknown to IEnumVARIANT
            set iter [$enumerator @QueryInterface IEnumVARIANT]
            if {! [$iter @Null?]} {
                set more 1
                while {$more} {
                    # Get the next item from iterator
                    set next [$iter Next 1]
                    lassign $next more values
                    if {[llength $values]} {
                        set var [::twapi::variant_value [lindex $values 0] 0 0 $_lcid]
                        set ret [catch {uplevel 1 $script} msg options]
                        switch -exact -- $ret {
                            0 -
                            4 {
                                # Body executed successfully, or invoked continue
                                if {$opts(cleanup)} {
                                    $var destroy
                                }
                            }
                            3 {
                                if {$opts(cleanup)} {
                                    $var destroy
                                }
                                set more 0; # TCL_BREAK
                            }
                            1 -
                            2 -
                            default {
                                if {$opts(cleanup)} {
                                    $var destroy
                                }
                                dict incr options -level
                                return -options $options $msg
                            }

                        }
                    }
                }
            }
        } finally {
            $enumerator Release
            if {[info exists iter] && ![$iter @Null?]} {
                $iter Release
            }
        }
        return
    }

    method -bind {script} {
        my variable   _proxy   _sinks    _connection_pts

        # Get the coclass typeinfo and  locate the source interface
        # within it and retrieve disp id mappings
        ::twapi::trap {
            set coti [$_proxy @GetCoClassTypeInfo]

            # $coti is the coclass information. Get dispids for the default
            # source interface for events and its guid
            set srcti [$coti @GetDefaultSourceTypeInfo]
            array set srcinfo [$srcti @GetTypeAttr -memidmap -guid]

            # TBD - implement IConnectionPointContainerProxy
            # Now we need to get the actual connection point itself
            set container [$_proxy QueryInterface IConnectionPointContainer]
            set connpt_ifc [::twapi::IConnectionPointContainer_FindConnectionPoint $container $srcinfo(-guid)]

            # Finally, create our sink object
            # TBD - need to make sure Automation object is not deleted or
            # should the callback itself check?
            # TBD - what guid should we be passing? CLSID or IID ?
            set sink_ifc [::twapi::Twapi_ComServer $srcinfo(-guid) $srcinfo(-memidmap) [list ::twapi::_eventsink_callback [self] $script]]

            # OK, we finally have everything we need. Tell the event source
            set sinkid [::twapi::IConnectionPoint_Advise $connpt_ifc $sink_ifc]
            
            set _sinks($sinkid) $sink_ifc
            set _connection_pts($sinkid) $connpt_ifc
            return $sinkid
        } onerror {} {
            # These are released only on error as otherwise they have
            # to be kept until unbind time
            foreach ifc {connpt_ifc sink_ifc} {
                if {[info exists $ifc] && [set $ifc] ne ""} {
                    ::twapi::IUnknown_Release [set $ifc]
                }
            }
            twapi::rethrow
        } finally {
            # In all cases, release any interfaces we created
            # Note connpt_ifc and sink_ifc are released at unbind time except
            # on error
            foreach obj {coti srcti} {
                if {[info exists $obj]} {
                    [set $obj] Release
                }
            }
            if {[info exists container]} {
                ::twapi::IUnknown_Release $container
            }
        }
    }

    method -unbind {sinkid} {
        my variable   _proxy   _sinks    _connection_pts

        if {[info exists _connection_pts($sinkid)]} {
            ::twapi::IConnectionPoint_Unadvise $_connection_pts($sinkid) $sinkid
            unset _connection_pts($sinkid)
        }

        if {[info exists _sinks($sinkid)]} {
            ::twapi::IUnknown_Release $_sinks($sinkid)
            unset _sinks($sinkid)
        }
        return
    }

    method -securityblanket {args} {
        my variable _proxy
        if {[llength $args]} {
            $_proxy @SetSecurityBlanket [lindex $args 0]
            return
        } else {
            return [$_proxy @GetSecurityBlanket]
        }
    }

    method -lcid {{lcid ""}} {
        my variable _lcid
        if {$lcid ne ""} {
            if {![string is integer -strict $lcid]} {
                error "Invalid LCID $lcid"
            }
            set _lcid $lcid
        }
        return $_lcid
    }

    method unknown {name args} {
        # Try to figure out whether it is a property or method

        # We have to figure out if it is a property get, property put
        # or a method. We make a guess based on number of parameters.
        # We specify an order to try based on this. The invoke will try
        # all invocations in that order.
        # TBD - what about propputref ?
        set nargs [llength $args]
        if {$nargs == 0} {
            # No arguments, cannot be propput. Try propget and method
            set invkinds [list 2 1]
        } elseif {$nargs == 1} {
            # One argument, likely propput, method, propget
            set invkinds [list 4 1 2]
        } else {
            # Multiple arguments, likely method, propput, propget
            set invkinds [list 1 4 2]
        }

        # TBD - should this do an uplevel ?
        return [my _invoke $name $invkinds $args]
    }

    twapi_exportall
}

#
# Singleton NULL comobj object. We want to override default destroy methods
# to prevent object from being destroyed. This is a backward compatibility
# hack and not fool proof since the command could just be renamed away.
twapi::class create twapi::NullAutomation {
    superclass twapi::Automation
    constructor {} {
        next [twapi::make_interface_proxy {0 IDispatch}]
    }
    method -destroy {}  {
        # Silently ignore
    }
    method destroy {}  {
        # Silently ignore
    }
    twapi_exportall
}

twapi::NullAutomation create twapi::comobj_null
# twapi::Automation create twapi::comobj_null [twapi::make_interface_proxy {0 IDispatch}]

proc twapi::_comobj_cleanup {} {
    foreach obj [comobj_instances] {
        $obj destroy
    }
}

# In order for servers to release objects properly, the IUnknown interface
# must have the same security settings as were used in the object creation
# call. This is a helper for that.
proc twapi::_com_set_iunknown_proxy {ifc blanket} {
    set iunk [Twapi_IUnknown_QueryInterface $ifc [_iid_iunknown] IUnknown]
    trap {
        CoSetProxyBlanket $iunk {*}$blanket
    } finally {
        IUnknown_Release $iunk
    }
}


twapi::proc* twapi::_init_authnames {} {
    variable _com_authsvc_to_name 
    variable _com_name_to_authsvc
    variable _com_impersonation_to_name
    variable _com_name_to_impersonation
    variable _com_authlevel_to_name
    variable _com_name_to_authlevel

    set _com_authsvc_to_name {0 none 9 negotiate 10 ntlm 14 schannel 16 kerberos 0xffffffff default}
    set _com_name_to_authsvc [swapl $_com_authsvc_to_name]
    set _com_name_to_impersonation {default 0 anonymous 1 identify 2 impersonate 3 delegate 4}
    set _com_impersonation_to_name [swapl $_com_name_to_impersonation]
    set _com_name_to_authlevel {default 0 none 1 connect 2 call 3 packet 4 packetintegrity 5 privacy 6}
    set _com_authlevel_to_name [swapl $_com_name_to_authlevel]
} {
}

twapi::proc* twapi::_com_authsvc_to_name {authsvc} {
    _init_authnames
} {
    variable _com_authsvc_to_name
    return [dict* $_com_authsvc_to_name $authsvc]
}

twapi::proc* twapi::_com_name_to_authsvc {name} {
    _init_authnames
} {
    variable _com_name_to_authsvc
    if {[string is integer -strict $name]} {
        return $name
    }
    return [dict! $_com_name_to_authsvc $name]
}

twapi::proc* twapi::_com_authlevel_to_name {authlevel} {
    _init_authnames
} {
    variable _com_authlevel_to_name
    return [dict* $_com_authlevel_to_name $authlevel]
}

twapi::proc* twapi::_com_name_to_authlevel {name} {
    _init_authnames
} {
    variable _com_name_to_authlevel
    if {[string is integer -strict $name]} {
        return $name
    }
    return [dict! $_com_name_to_authlevel $name]
}


twapi::proc* twapi::_com_impersonation_to_name {imp} {
    _init_authnames
} {
    variable _com_impersonation_to_name
    return [dict* $_com_impersonation_to_name $imp]
}

twapi::proc* twapi::_com_name_to_impersonation {name} {
    _init_authnames
} {
    variable _com_name_to_impersonation
    if {[string is integer -strict $name]} {
        return $name
    }
    return [dict! $_com_name_to_impersonation $name]
}

#################################################################
# COM server implementation
# WARNING: do not use any fancy TclOO features because it has to
# run under 8.5/metoo as well
# TBD - test scripts?

twapi::class create twapi::ComFactory {
    constructor {clsid member_map create_command_prefix} {
        my variable _clsid _create_command_prefix _member_map _ifc

        set _clsid $clsid
        set _member_map $member_map
        set _create_command_prefix $create_command_prefix

        set _ifc [twapi::Twapi_ClassFactory $_clsid [list [self] _create_instance]]
    }

    destructor {
        # TBD - what happens if factory is destroyed while objects still
        # exist ?
        # App MUST explicitly destroy objects before exiting
        my variable _class_registration_id
        if {[info exists _class_registration_id]} {
            twapi::CoRevokeClassObject $_class_registration_id
        }
    }

    # Called from Twapi_ClassFactory_CreateInstance to create a new object
    # Should not be called from elsewhere
    method _create_instance {iid} {
        my variable _create_command_prefix _member_map
        # Note [list {*}$foo] != $foo - consider when foo contains a ";"
        set obj_prefix [uplevel #0 [list {*}$_create_command_prefix]]
        twapi::trap {
            # Since we are not holding on to this interface ourselves,
            # we can pass it on without AddRef'ing it
            return [twapi::Twapi_ComServer $iid $_member_map $obj_prefix]
        } onerror {} {
            $obj_prefix destroy
            twapi::rethrow
        }
    }

    method register {args} {
        my variable _clsid _create_command_prefix _member_map _ifc _class_registration_id
        twapi::parseargs args {
            {model.arg any}
        } -setvars -maxleftover 0
        set model_flags 0
        foreach m $model {
            switch -exact -- $m {
                any           {twapi::setbits model_flags 20}
                localserver   {twapi::setbits model_flags 4}
                remoteserver  {twapi::setbits model_flags 16}
                default {twapi::badargs! "Invalid COM class model '$m'"}
            }
        }
        
        # 0x6 -> REGCLS_MULTI_SEPARATE | REGCLS_SUSPENDED
        set _class_registration_id [twapi::CoRegisterClassObject $_clsid $_ifc $model_flags 0x6]
        return
    }
    
    export _create_instance
}

proc twapi::comserver_factory {clsid member_map command_prefix {name {}}} {
    if {$name ne ""} {
        uplevel 1 [list [namespace current]::ComFactory create $name $clsid $member_map $command_prefix]
    } else {
        uplevel 1 [list [namespace current]::ComFactory new $clsid $member_map $command_prefix]
    }
}

proc twapi::start_factories {{cmd {}}} {
    # TBD - what if no class objects ?
    CoResumeClassObjects

    if {[llength $cmd]} {
        # TBD - normalize $cmd so to run in right namespace etc.
        trace add variable [namspace current]::com_shutdown_signal write $cmd
        return
    }

    # This is set from the C code when we are not serving up any
    # COM objects (either event callbacks or com servers)
    vwait [namespace current]::com_shutdown_signal
}

proc twapi::suspend_factories {} {
    CoSuspendClassObjects
}

proc twapi::resume_factories {} {
    CoResumeClassObjects
}

proc twapi::install_coclass_script {progid clsid version script_path args} {
    # Need to extract params so we can prefix script name
    set saved_args $args
    array set opts [parseargs args {
        params.arg
    } -ignoreunknown]

    set script_path [file normalize $script_path]

    # Try to locate the wish executable to run the component
    if {[info commands wm] eq ""} {
        set dir [file dirname [info nameofexecutable]]
        set wishes [glob -nocomplain -directory $dir wish*.exe]
        if {[llength $wishes] == 0} {
            error "Could not locate wish program."
        }
        set wish [lindex $wishes 0]
    } else {
        # We are running wish already
        set wish [info nameofexecutable]
    }

    set exe_path [file nativename [file attributes $wish -shortname]]

    set params "\"$script_path\""
    if {[info exists opts(params)]} {
        append params " $params"
    }
    return [install_coclass $progid $clsid $version $exe_path {*}$args -outproc -params $params]
}

proc twapi::install_coclass {progid clsid version path args} {
    array set opts [twapi::parseargs args {
        {scope.arg user {user system}}
        appid.arg
        appname.arg
        inproc
        outproc
        service
        params.arg
        name.arg
    } -maxleftover 0]

    switch [tcl::mathop::+ $opts(inproc) $opts(outproc) $opts(service)] {
        0 {
            # Need to figure out the type
            switch [file extension $path] {
                .exe { set opts(outproc) 1 }
                .ocx -
                .dll { set opts(inproc) 1 }
                default { set opts(service) 1 }
            }
        }
        1 {}
        default {
            badargs! "Only one of -inproc, -outproc or -service may be specified"
        }
    }

    if {(! [string is integer -strict $version]) || $version <= 0} {
        twapi::badargs! "Invalid version '$version'. Must be a positive integer"
    }
    if {![regexp {^[[:alpha:]][[:alnum:]]*\.[[:alpha:]][[:alnum:]]*$} $progid]} {
        badargs! "Invalid PROGID syntax '$progid'"
    }
    set clsid [canonicalize_guid $clsid]
    if {![info exists opts(appid)]} {
        # This is what dcomcnfg and oleview do - default to the CLSID
        set opts(appid) $clsid
    } else {
        set opts(appid) [canonicalize_guid $opts(appid)]
    }

    if {$opts(scope) eq "user"} {
        if {$opts(service)} {
            twapi::badargs! "Option -service cannot be specified if -scope is \"user\""
        }
        set regtop HKEY_CURRENT_USER
    } else {
        set regtop HKEY_LOCAL_MACHINE
    }

    set progid_path "$regtop\\Software\\Classes\\$progid"
    set clsid_path "$regtop\\Software\\Classes\\CLSID\\$clsid"
    set appid_path "$regtop\\Software\\Classes\\AppID\\$opts(appid)"

    if {$opts(service)} {
        # TBD
        badargs! "Option -service is not implemented"
    } elseif {$opts(outproc)} {
        if {[info exists opts(params)]} {
            registry set "$clsid_path\\LocalServer32" "" "\"[file nativename [file normalize $path]]\" $opts(params)"
        } else {
            registry set "$clsid_path\\LocalServer32" "" "\"[file nativename [file normalize $path]]\""
        }
        # TBD - We do not quote path for ServerExecutable, should we ?
        registry set "$clsid_path\\LocalServer32" "ServerExecutable" [file nativename [file normalize $path]]
    } else {
        # TBD - We do not quote path here either, should we ?
        registry set "$clsid_path\\InprocServer32" "" [file nativename [file normalize $path]]
    }
    
    registry set "$clsid_path\\ProgID" "" "$progid.$version"
    registry set "$clsid_path\\VersionIndependentProgID" "" $progid

    # Set the registry under the progid and progid.version
    registry set "$progid_path\\CLSID" "" $clsid
    registry set "$progid_path\\CurVer" "" "$progid.$version"
    if {[info exists opts(name)]} {
        registry set $progid_path "" $opts(name)
    }

    append progid_path ".$version"
    registry set "$progid_path\\CLSID" "" $clsid
    if {[info exists opts(name)]} {
        registry set $progid_path "" $opts(name)
    }
    
    registry set $clsid_path "AppID" $opts(appid)
    registry set $appid_path;   # Always create the key even if nothing below
    if {[info exists opts(appname)]} {
        registry set $appid_path "" $opts(appname)
    }
    
    if {$opts(service)} {
        registry set $appid_path "LocalService" $path
        if {[info exists opts(params)]} {
            registry set $appid_path "ServiceParameters" $opts(params)
        }
    }

    return
}

proc twapi::uninstall_coclass {progid args} {
    # Note "CLSID" itself is a valid ProgID (it has a CLSID key below it)
    # Also we want to protect against horrible errors that blow away
    # entire branches if progid is empty, wrong value, etc.
    # So only work with keys of the form X.X
    if {![regexp {^[[:alpha:]][[:alnum:]]*\.[[:alpha:]][[:alnum:]]*$} $progid]} {
        badargs! "Invalid PROGID syntax '$progid'"
    }

    # Do NOT want to delete the CLSID key by mistake. Note below checks
    # will not protect against this since they will return a valid value 
    # if progid is "CLSID" since that has a CLSID key below it as well.
    if {[string equal -nocase $progid CLSID]} {
        badargs! "Attempt to delete protected key 'CLSID'"
    }

    array set opts [twapi::parseargs args {
        {scope.arg user {user system}}
        keepappid
    } -maxleftover 0]

    switch -exact -- $opts(scope) {
        user { set regtop HKEY_CURRENT_USER }
        system { set regtop HKEY_LOCAL_MACHINE }
        default {
            badargs! "Invalid class registration scope '$opts(scope)'. Must be 'user' or 'system'"
        }
    }

    if {0} {
        # Do NOT use this. If running under elevated, it will ignore
        # HKEY_CURRENT_USER.
        set clsid [progid_to_clsid $progid]; # Also protects against bogus progids
    } else {
        set clsid [registry get "$regtop\\Software\\Classes\\$progid\\CLSID" ""]
    }

    # Should not be empty at this point but do not want to delete the 
    # whole Classes tree in case progid or clsid are empty strings
    # because of some bug! That would be an epic disaster so try and
    # protect.
    if {$clsid eq ""} {
        badargs! "CLSID corresponding to PROGID '$progid' is empty"
    }
    
    # See if we need to delete the linked current version
    if {! [catch {
        registry get "$regtop\\Software\\Classes\\$progid\\CurVer" ""
    } curver]} {
        if {[string match -nocase ${progid}.* $curver]} {
            registry delete "$regtop\\Software\\Classes\\$curver"
        }
    }

    # See if we need to delete the APPID
    if {! $opts(keepappid)} {
        if {! [catch {
            registry get "$regtop\\Software\\Classes\\CLSID\\$clsid" "AppID"
        } appid]} {
            # Validate it is a real GUID
            if {![catch {canonicalize_guid $appid}]} {
                registry delete "$regtop\\Software\\Classes\\AppID\\$appid"
            }
        }
    }

    # Finally delete the keys and hope we have not trashed the system
    registry delete "$regtop\\Software\\Classes\\CLSID\\$clsid"
    registry delete "$regtop\\Software\\Classes\\$progid"

    return
}


