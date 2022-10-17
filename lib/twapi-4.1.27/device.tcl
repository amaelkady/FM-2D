#
# Copyright (c) 2008-2014 Ashok P. Nadkarni
# All rights reserved.
#
# See the file LICENSE for license

namespace eval twapi {
    struct _PREVENT_MEDIA_REMOVAL {
            BOOLEAN PreventMediaRemoval;
    }
    record device_element { class_guid device_instance reserved }
}

interp alias {} close_devinfoset {} devinfoset_close

proc twapi::rescan_devices {} {
    CM_Reenumerate_DevNode_Ex [CM_Locate_DevNode_Ex "" 0] 0
}


# Callback invoked for device changes.
# Does some processing of passed data and then invokes the
# real callback script
proc twapi::_device_notification_handler {id args} {
    variable _device_notifiers
    set idstr "devnotifier#$id"
    if {![info exists _device_notifiers($idstr)]} {
        # Notifications that expect a response default to "true"
        return 1
    }
    set script [lindex $_device_notifiers($idstr) 1]

    # For volume notifications, change drive bitmask to
    # list of drives before passing back to script
    set event [lindex $args 0]
    if {[lindex $args 1] eq "volume" &&
        ($event eq "deviceremovecomplete" || $event eq "devicearrival")} {
        lset args 2 [_drivemask_to_drivelist [lindex $args 2]]

        # Also indicate whether network volume and whether change is a media
        # change or physical change
        set attrs [list ]
        set flags [lindex $args 3]
        if {$flags & 1} {
            lappend attrs mediachange
        }
        if {$flags & 2} {
            lappend attrs networkvolume
        }
        lset args 3 $attrs
    }

    return [uplevel #0 [linsert $script end $idstr {*}$args]]
}

proc twapi::start_device_notifier {script args} {
    variable _device_notifiers

    set script [lrange $script 0 end]; # Verify syntactically a list

    array set opts [parseargs args {
        deviceinterface.arg
        handle.arg
    } -maxleftover 0]

    # For reference - some common device interface classes
    # NOTE: NOT ALL HAVE BEEN VERIFIED!
    # Network Card      {ad498944-762f-11d0-8dcb-00c04fc3358c}
    # Human Interface Device (HID)      {4d1e55b2-f16f-11cf-88cb-001111000030}
    # GUID_DEVINTERFACE_DISK          - {53f56307-b6bf-11d0-94f2-00a0c91efb8b}
    # GUID_DEVINTERFACE_CDROM         - {53f56308-b6bf-11d0-94f2-00a0c91efb8b}
    # GUID_DEVINTERFACE_PARTITION     - {53f5630a-b6bf-11d0-94f2-00a0c91efb8b}
    # GUID_DEVINTERFACE_TAPE          - {53f5630b-b6bf-11d0-94f2-00a0c91efb8b}
    # GUID_DEVINTERFACE_WRITEONCEDISK - {53f5630c-b6bf-11d0-94f2-00a0c91efb8b}
    # GUID_DEVINTERFACE_VOLUME        - {53f5630d-b6bf-11d0-94f2-00a0c91efb8b}
    # GUID_DEVINTERFACE_MEDIUMCHANGER - {53f56310-b6bf-11d0-94f2-00a0c91efb8b}
    # GUID_DEVINTERFACE_FLOPPY        - {53f56311-b6bf-11d0-94f2-00a0c91efb8b}
    # GUID_DEVINTERFACE_CDCHANGER     - {53f56312-b6bf-11d0-94f2-00a0c91efb8b}
    # GUID_DEVINTERFACE_STORAGEPORT   - {2accfe60-c130-11d2-b082-00a0c91efb8b}
    # GUID_DEVINTERFACE_KEYBOARD      - {884b96c3-56ef-11d1-bc8c-00a0c91405dd}
    # GUID_DEVINTERFACE_MOUSE         - {378de44c-56ef-11d1-bc8c-00a0c91405dd}
    # GUID_DEVINTERFACE_PARALLEL      - {97F76EF0-F883-11D0-AF1F-0000F800845C}
    # GUID_DEVINTERFACE_COMPORT       - {86e0d1e0-8089-11d0-9ce4-08003e301f73}
    # GUID_DEVINTERFACE_DISPLAY_ADAPTER - {5b45201d-f2f2-4f3b-85bb-30ff1f953599}
    # GUID_DEVINTERFACE_USB_HUB       - {f18a0e88-c30c-11d0-8815-00a0c906bed8}
    # GUID_DEVINTERFACE_USB_DEVICE    - {A5DCBF10-6530-11D2-901F-00C04FB951ED}
    # GUID_DEVINTERFACE_USB_HOST_CONTROLLER - {3abf6f2d-71c4-462a-8a92-1e6861e6af27}


    if {[info exists opts(deviceinterface)] && [info exists opts(handle)]} {
        error "Options -deviceinterface and -handle are mutually exclusive."
    }

    if {![info exists opts(deviceinterface)]} {
        set opts(deviceinterface) ""
    }
    if {[info exists opts(handle)]} {
        set type 6
    } else {
        set opts(handle) NULL
        switch -exact -- $opts(deviceinterface) {
            port            { set type 3 ; set opts(deviceinterface) "" }
            volume          { set type 2 ; set opts(deviceinterface) "" }
            default {
                # device interface class guid or empty string (for all device interfaces)
                set type 5
            }
        }
    }

    set id [Twapi_RegisterDeviceNotification $type $opts(deviceinterface) $opts(handle)]
    set idstr "devnotifier#$id"

    set _device_notifiers($idstr) [list $id $script]
    return $idstr
}

proc twapi::stop_device_notifier {idstr} {
    variable _device_notifiers

    if {![info exists _device_notifiers($idstr)]} {
        return;
    }

    Twapi_UnregisterDeviceNotification [lindex $_device_notifiers($idstr) 0]
    unset _device_notifiers($idstr)
}

proc twapi::devinfoset {args} {
    array set opts [parseargs args {
        {guid.arg ""}
        {classtype.arg setup {interface setup}}
        {presentonly.bool false 0x2}
        {currentprofileonly.bool false 0x8}
        {deviceinfoset.arg NULL}
        {hwin.int 0}
        {system.arg ""}
        {pnpenumerator.arg ""}
    } -maxleftover 0]

    # DIGCF_ALLCLASSES is bitmask 4
    set flags [expr {$opts(guid) eq "" ? 0x4 : 0}]
    if {$opts(classtype) eq "interface"} {
        if {$opts(pnpenumerator) ne ""} {
            error "The -pnpenumerator option cannot be used when -classtype interface is specified."
        }
        # DIGCF_DEVICEINTERFACE
        set flags [expr {$flags | 0x10}]
    }

    # DIGCF_PRESENT
    set flags [expr {$flags | $opts(presentonly)}]

    # DIGCF_PRESENT
    set flags [expr {$flags | $opts(currentprofileonly)}]

    return [SetupDiGetClassDevsEx \
                $opts(guid) \
                $opts(pnpenumerator) \
                $opts(hwin) \
                $flags \
                $opts(deviceinfoset) \
                $opts(system)]
}


# Given a device information set, returns the device elements within it
proc twapi::devinfoset_elements {hdevinfo} {
    set result [list ]
    set i 0
    trap {
        while {true} {
            lappend result [SetupDiEnumDeviceInfo $hdevinfo $i]
            incr i
        }
    } onerror {TWAPI_WIN32 0x103} {
        # Fine, Just means no more items
    } onerror {TWAPI_WIN32 0x80070103} {
        # Fine, Just means no more items (HRESULT version of above code)
    }

    return $result
}

# Given a device information set, returns the device elements within it
proc twapi::devinfoset_instance_ids {hdevinfo} {
    set result [list ]
    set i 0
    trap {
        while {true} {
            lappend result [device_element_instance_id $hdevinfo [SetupDiEnumDeviceInfo $hdevinfo $i]]
            incr i
        }
    } onerror {TWAPI_WIN32 0x103} {
        # Fine, Just means no more items
    } onerror {TWAPI_WIN32 0x80070103} {
        # Fine, Just means no more items (HRESULT version of above code)
    }

    return $result
}

# Returns a device instance element from a devinfoset
proc twapi::devinfoset_element {hdevinfo instance_id} {
    return [SetupDiOpenDeviceInfo $hdevinfo $instance_id 0 0]
}

# Get the registry property for a devinfoset element
proc twapi::devinfoset_element_registry_property {hdevinfo develem prop} {
    Twapi_SetupDiGetDeviceRegistryProperty $hdevinfo $develem [_device_registry_sym_to_code $prop]
}

# Given a device information set, returns a list of specified registry
# properties for all elements of the set
# args is list of properties to retrieve
proc twapi::devinfoset_registry_properties {hdevinfo args} {
    set result [list ]
    trap {
        # Keep looping until there is an error saying no more items
        set i 0
        while {true} {

            # First element is the DEVINFO_DATA element
            set devinfo_data [SetupDiEnumDeviceInfo $hdevinfo $i]
            set item [list -deviceelement $devinfo_data ]

            # Get all specified property values
            foreach prop $args {
                set intprop [_device_registry_sym_to_code $prop]
                trap {
                    lappend item $prop \
                        [list success \
                             [Twapi_SetupDiGetDeviceRegistryProperty \
                                  $hdevinfo $devinfo_data $intprop]]
                } onerror {} {
                    lappend item $prop [list fail [list [trapresult] $::errorCode]]
                }
            }
            lappend result $item

            incr i
        }
    } onerror {TWAPI_WIN32 0x103} {
        # Fine, Just means no more items
    } onerror {TWAPI_WIN32 0x80070103} {
        # Fine, Just means no more items (HRESULT version of above code)
    }

    return $result
}


# Given a device information set, returns specified device interface
# properties
# TBD - document ?
proc twapi::devinfoset_interface_details {hdevinfo guid args} {
    set result [list ]

    array set opts [parseargs args {
        {matchdeviceelement.arg {}}
        interfaceclass
        flags
        devicepath
        deviceelement
        ignoreerrors
    } -maxleftover 0]

    trap {
        # Keep looping until there is an error saying no more items
        set i 0
        while {true} {
            set interface_data [SetupDiEnumDeviceInterfaces $hdevinfo \
                                    $opts(matchdeviceelement) $guid $i]
            set item [list ]
            if {$opts(interfaceclass)} {
                lappend item -interfaceclass [lindex $interface_data 0]
            }
            if {$opts(flags)} {
                set flags    [lindex $interface_data 1]
                set symflags [_make_symbolic_bitmask $flags {active 1 default 2 removed 4} false]
                lappend item -flags [linsert $symflags 0 $flags]
            }

            if {$opts(devicepath) || $opts(deviceelement)} {
                # Need to get device interface detail.
                trap {
                    foreach {devicepath deviceelement} \
                        [SetupDiGetDeviceInterfaceDetail \
                             $hdevinfo \
                             $interface_data \
                             $opts(matchdeviceelement)] \
                        break

                    if {$opts(deviceelement)} {
                        lappend item -deviceelement $deviceelement
                    }
                    if {$opts(devicepath)} {
                        lappend item -devicepath $devicepath
                    }
                } onerror {} {
                    if {! $opts(ignoreerrors)} {
                        rethrow
                    }
                }
            }
            lappend result $item

            incr i
        }
    } onerror {TWAPI_WIN32 0x103} {
        # Fine, Just means no more items
    } onerror {TWAPI_WIN32 0x80070103} {
        # Fine, Just means no more items (HRESULT version of above code)
    }

    return $result
}


# Return the guids associated with a device class set name. Note
# the latter is not unique so multiple guids may be associated.
proc twapi::device_setup_class_name_to_guids {name args} {
    array set opts [parseargs args {
        system.arg
    } -maxleftover 0 -nulldefault]

    return [twapi::SetupDiClassGuidsFromNameEx $name $opts(system)]
}

# Utility functions

proc twapi::_init_device_registry_code_maps {} {
    variable _device_registry_syms
    variable _device_registry_codes

    # Note this list is ordered based on the corresponding integer codes
    set _device_registry_code_syms {
        devicedesc hardwareid compatibleids unused0 service unused1
        unused2 class classguid driver configflags mfg friendlyname
        location_information physical_device_object_name capabilities
        ui_number upperfilters lowerfilters
        bustypeguid legacybustype busnumber enumerator_name security
        security_sds devtype exclusive characteristics address
        ui_number_desc_format device_power_data
        removal_policy removal_policy_hw_default removal_policy_override
        install_state location_paths base_containerid
    }

    set i 0
    foreach sym $_device_registry_code_syms {
        set _device_registry_codes($sym) $i
        incr i
    }
}

# Map a device registry property to a symbol
proc twapi::_device_registry_code_to_sym {code} {
    _init_device_registry_code_maps

    # Once we have initialized, redefine ourselves so we do not do so
    # every time. Note define at global ::twapi scope!
    proc ::twapi::_device_registry_code_to_sym {code} {
        variable _device_registry_code_syms
        if {$code >= [llength $_device_registry_code_syms]} {
            return $code
        } else {
            return [lindex $_device_registry_code_syms $code]
        }
    }
    # Call the redefined proc
    return [_device_registry_code_to_sym $code]
}

# Map a device registry property symbol to a numeric code
proc twapi::_device_registry_sym_to_code {sym} {
    _init_device_registry_code_maps

    # Once we have initialized, redefine ourselves so we do not do so
    # every time. Note define at global ::twapi scope!
    proc ::twapi::_device_registry_sym_to_code {sym} {
        variable _device_registry_codes
        # Return the value. If non-existent, an error will be raised
        if {[info exists _device_registry_codes($sym)]} {
            return $_device_registry_codes($sym)
        } elseif {[string is integer -strict $sym]} {
            return $sym
        } else {
            error "Unknown or unsupported device registry property symbol '$sym'"
        }
    }
    # Call the redefined proc
    return [_device_registry_sym_to_code $sym]
}

# Do a device ioctl, returning result as a binary
# TBD - document that caller has to handle errors 122 (ERROR_INSUFFICIENT_BUFFER) and (ERROR_MORE_DATA)
proc twapi::device_ioctl {h code args} {
    array set opts [parseargs args {
        {input.arg {}}
        {outputcount.int 0}
    } -maxleftover 0]

    return [DeviceIoControl $h $code $opts(input) $opts(outputcount)]
}


# Return a list of physical disks. Note CD-ROMs and floppies not included
proc twapi::find_physical_disks {} {
    # Disk interface class guid
    set guid {{53F56307-B6BF-11D0-94F2-00A0C91EFB8B}}
    set hdevinfo [devinfoset \
                      -guid $guid \
                      -presentonly true \
                      -classtype interface]
    trap {
        return [kl_flatten [devinfoset_interface_details $hdevinfo $guid -devicepath] -devicepath]
    } finally {
        devinfoset_close $hdevinfo
    }
}

# Return information about a physical disk
proc twapi::get_physical_disk_info {disk args} {
    set result [list ]

    array set opts [parseargs args {
        geometry
        layout
        all
    } -maxleftover 0]

    if {$opts(all) || $opts(geometry) || $opts(layout)} {
        set h [create_file $disk -createdisposition open_existing]
    }

    trap {
        if {$opts(all) || $opts(geometry)} {
            # IOCTL_DISK_GET_DRIVE_GEOMETRY - 0x70000
            if {[binary scan [device_ioctl $h 0x70000 -outputcount 24] "wiiii" geom(-cylinders) geom(-mediatype) geom(-trackspercylinder) geom(-sectorspertrack) geom(-bytespersector)] != 5} {
                error "DeviceIoControl 0x70000 on disk '$disk' returned insufficient data."
            }
            lappend result -geometry [array get geom]
        }

        if {$opts(all) || $opts(layout)} {
            # XP and later - IOCTL_DISK_GET_DRIVE_LAYOUT_EX
            set data [device_ioctl $h 0x70050 -outputcount 624]
            if {[binary scan $data "i i" partstyle layout(-partitioncount)] != 2} {
                error "DeviceIoControl 0x70050 on disk '$disk' returned insufficient data."
            }
            set layout(-partitionstyle) [_partition_style_sym $partstyle]
            switch -exact -- $layout(-partitionstyle) {
                mbr {
                    if {[binary scan $data "@8 i" layout(-signature)] != 1} {
                        error "DeviceIoControl 0x70050 on disk '$disk' returned insufficient data."
                    }
                }
                gpt {
                    set pi(-diskid) [_binary_to_guid $data 32]
                    if {[binary scan $data "@8 w w i" layout(-startingusableoffset) layout(-usablelength) layout(-maxpartitioncount)] != 3} {
                        error "DeviceIoControl 0x70050 on disk '$disk' returned insufficient data."
                    }
                }
                raw -
                unknown {
                    # No fields to add
                }
            }

            set layout(-partitions) [list ]
            for {set i 0} {$i < $layout(-partitioncount)} {incr i} {
                # Decode each partition in turn. Sizeof of PARTITION_INFORMATION_EX is 144
                lappend layout(-partitions) [_decode_PARTITION_INFORMATION_EX_binary $data [expr {48 + (144*$i)}]]
            }
            lappend result -layout [array get layout]
        }

    } finally {
        if {[info exists h]} {
            CloseHandle $h
        }
    }

    return $result
}

# Given a Tcl binary and offset, decode the PARTITION_INFORMATION_EX record
proc twapi::_decode_PARTITION_INFORMATION_EX_binary {bin off} {
    if {[binary scan $bin "@$off i x4 w w i c" \
             pi(-partitionstyle) \
             pi(-startingoffset) \
             pi(-partitionlength) \
             pi(-partitionnumber) \
             pi(-rewritepartition)] != 5} {
        error "Truncated partition structure."
    }

    set pi(-partitionstyle) [_partition_style_sym $pi(-partitionstyle)]

    # MBR/GPT are at offset 32 in the structure
    switch -exact -- $pi(-partitionstyle) {
        mbr {
            if {[binary scan $bin "@$off x32 c c c x i" pi(-partitiontype) pi(-bootindicator) pi(-recognizedpartition) pi(-hiddensectors)] != 4} {
                error "Truncated partition structure."
            }
            # Show partition type in hex, not negative number
            set pi(-partitiontype) [format 0x%2.2x [expr {0xff & $pi(-partitiontype)}]]
        }
        gpt {
            set pi(-partitiontype) [_binary_to_guid $bin [expr {$off+32}]]
            set pi(-partitionif)   [_binary_to_guid $bin [expr {$off+48}]]
            if {[binary scan $bin "@$off x64 w" pi(-attributes)] != 1} {
                error "Truncated partition structure."
            }
            set pi(-name) [_ucs16_binary_to_string [string range $bin [expr {$off+72}] end]]
        }
        raw -
        unknown {
            # No fields to add
        }

    }

    return [array get pi]
}

#  IOCTL_STORAGE_EJECT_MEDIA
interp alias {} twapi::eject {} twapi::eject_media
proc twapi::eject_media device {
    # http://support.microsoft.com/default.aspx?scid=KB;EN-US;Q165721&
    set h [_open_disk_device $device]
    trap {
        device_ioctl $h 0x90018; # FSCTL_LOCK_VOLUME
        device_ioctl $h 0x90020; # FSCTL_DISMOUNT_VOLUME
        #  IOCTL_STORAGE_MEDIA_REMOVAL (0)
        device_ioctl $h 0x2d4804 -input [_PREVENT_MEDIA_REMOVAL 0]
        device_ioctl $h 0x2d4808; # IOCTL_STORAGE_EJECT_MEDIA
    } finally {
        close_handle $h
    }
}

# IOCTL_DISK_LOAD_MEDIA
# Note - should we use IOCTL_DISK_LOAD_MEDIA2 instead (0x2d080c) see
# SDK, faster if read / write access not necessary. We are closing
# the handle right away anyway but would that stop other apps from
# acessing the file system on the CD ? Need to try (note device
# has to be opened with FILE_READ_ATTRIBUTES only in that case)

interp alias {} twapi::load_media {} twapi::_issue_disk_ioctl 0x2d480c

#  FSCTL_LOCK_VOLUME
# TBD - interp alias {} twapi::lock_volume {} twapi::_issue_disk_ioctl 0x90018
#  FSCTL_LOCK_VOLUME
# TBD - interp alias {} twapi::unlock_volume {} twapi::_issue_disk_ioctl 0x9001c

proc twapi::_lock_media {lock device} {
    # IOCTL_STORAGE_MEDIA_REMOVAL
    _issue_disk_ioctl 0x2d4804 $device -input [_PREVENT_MEDIA_REMOVAL $lock]
}
interp alias {} twapi::lock_media {} twapi::_lock_media 1
interp alias {} twapi::unlock_media {} twapi::_lock_media 0

proc twapi::_issue_disk_ioctl {ioctl device args} {
    set h [_open_disk_device $device]
    trap {
        device_ioctl $h $ioctl {*}$args
    } finally {
        close_handle $h
    }
}

twapi::proc* twapi::_open_disk_device {device} {
    package require twapi_storage
} {
    # device must be "cdrom", X:, X:\\, X:/, a volume or a physical disk as 
    # returned from find_physical_disks
    switch -regexp -nocase -- $device {
        {^cdrom$} {
            foreach drive [find_logical_drives] {
                if {![catch {get_drive_type $drive} drive_type]} {
                    if {$drive_type eq "cdrom"} {
                        set device "\\\\.\\$drive"
                        break
                    }
                }
            }
            if {$device eq "cdrom"} {
                error "Could not find a CD-ROM device."
            }
        }
        {^[[:alpha:]]:(/|\\)?$} { 
            set device "\\\\.\\[string range $device 0 1]"
        }
        {^\\\\\?\\.*#\{[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}\}$} {
            # Device name ok
        }
        {^\\\\\?\\Volume\{[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}\}\\?$} {
            # Volume name ok. But make sure we trim off any trailing 
            # \ since create_file will open the root dir instead of the device
            set device [string trimright $device \\]
        }
        default {
            # Just to prevent us from opening some file instead
            error "Invalid device name '$device'"
        }
    }

    # http://support.microsoft.com/default.aspx?scid=KB;EN-US;Q165721&
    return [create_file $device -access {generic_read generic_write} \
                -createdisposition open_existing \
                -share {read write}]
}


# Map a partition style code to a symbol
proc twapi::_partition_style_sym {partstyle} {
    set partstyle [lindex {mbr gpt raw} $partstyle]
    if {$partstyle ne ""} {
        return $partstyle
    }
    return "unknown"
}

