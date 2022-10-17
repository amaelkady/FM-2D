if {$::tcl_platform(os) ne "Windows NT" ||
    ($::tcl_platform(machine) ne "intel" &&
     $::tcl_platform(machine) ne "amd64")} {
    return
}

namespace eval twapi {}
proc twapi::package_setup {dir pkg version type {file {}} {commands {}}} {
    global auto_index

    if {$file eq ""} {
        set file $pkg
    }
    if {$::tcl_platform(pointerSize) == 8} {
        set fn [file join $dir "${file}64.dll"]
    } else {
        set fn [file join $dir "${file}.dll"]
    }

    if {$fn ne ""} {
        if {![file exists $fn]} {
            set fn "";          # Assume twapi statically linked in
        }
    }

    if {$pkg eq "twapi_base"} {
        # Need the twapi base of the same version
        # In tclkit builds, twapi_base is statically linked in
        foreach pair [info loaded] {
            if {$pkg eq [lindex $pair 1]} {
                set fn [lindex $pair 0]; # Possibly statically loaded
                break
            }
        }
        set loadcmd [list load $fn $pkg]
    } else {
        package require twapi_base $version
        if {$type eq "load"} {
            # Package could be statically linked or to be loaded
            if {[twapi::get_build_config single_module]} {
                # Modules are statically bound. Reset fn
                set fn {}
            }
            set loadcmd [list load $fn $pkg]
        } else {
            # A pure Tcl script package
            set loadcmd [list twapi::Twapi_SourceResource $file 1]
        }
    }

    if {[llength $commands] == 0} {
        # No commands specified, load the package right away
        # TBD - what about the exports table?
        uplevel #0 $loadcmd
    } else {
        # Set up the load for when commands are actually accessed
        # TBD - add a line to export commands here ?
        foreach {ns cmds} $commands {
            foreach cmd $cmds {
                if {[string index $cmd 0] ne "_"} {
                    dict lappend ::twapi::exports $ns $cmd
                }
                set auto_index(${ns}::$cmd) $loadcmd
            }
        }
    }

    # TBD - really necessary? The C modules do this on init anyways.
    # Maybe needed for pure scripts
    package provide $pkg $version
}

# The build process will append package ifneeded commands below
# to create an appropriate pkgIndex.tcl file for included modules
package ifneeded twapi_base 4.1.27 [list twapi::package_setup $dir twapi_base 4.1.27 load twapi_base {}]
package ifneeded metoo 4.1.27 [list twapi::package_setup $dir metoo 4.1.27 source {} {}]
package ifneeded twapi_com 4.1.27 [list twapi::package_setup $dir twapi_com 4.1.27 load {} {}]
package ifneeded twapi_msi 4.1.27 [list twapi::package_setup $dir twapi_msi 4.1.27 source {} {}]
package ifneeded twapi_power 4.1.27 [list twapi::package_setup $dir twapi_power 4.1.27 source {} {}]
package ifneeded twapi_printer 4.1.27 [list twapi::package_setup $dir twapi_printer 4.1.27 source {} {}]
package ifneeded twapi_synch 4.1.27 [list twapi::package_setup $dir twapi_synch 4.1.27 source {} {}]
package ifneeded twapi_security 4.1.27 [list twapi::package_setup $dir twapi_security 4.1.27 load {} {}]
package ifneeded twapi_account 4.1.27 [list twapi::package_setup $dir twapi_account 4.1.27 load {} {}]
package ifneeded twapi_apputil 4.1.27 [list twapi::package_setup $dir twapi_apputil 4.1.27 load {} {}]
package ifneeded twapi_clipboard 4.1.27 [list twapi::package_setup $dir twapi_clipboard 4.1.27 load {} {}]
package ifneeded twapi_console 4.1.27 [list twapi::package_setup $dir twapi_console 4.1.27 load {} {}]
package ifneeded twapi_crypto 4.1.27 [list twapi::package_setup $dir twapi_crypto 4.1.27 load {} {}]
package ifneeded twapi_device 4.1.27 [list twapi::package_setup $dir twapi_device 4.1.27 load {} {}]
package ifneeded twapi_etw 4.1.27 [list twapi::package_setup $dir twapi_etw 4.1.27 load {} {}]
package ifneeded twapi_eventlog 4.1.27 [list twapi::package_setup $dir twapi_eventlog 4.1.27 load {} {}]
package ifneeded twapi_mstask 4.1.27 [list twapi::package_setup $dir twapi_mstask 4.1.27 load {} {}]
package ifneeded twapi_multimedia 4.1.27 [list twapi::package_setup $dir twapi_multimedia 4.1.27 load {} {}]
package ifneeded twapi_namedpipe 4.1.27 [list twapi::package_setup $dir twapi_namedpipe 4.1.27 load {} {}]
package ifneeded twapi_network 4.1.27 [list twapi::package_setup $dir twapi_network 4.1.27 load {} {}]
package ifneeded twapi_nls 4.1.27 [list twapi::package_setup $dir twapi_nls 4.1.27 load {} {}]
package ifneeded twapi_os 4.1.27 [list twapi::package_setup $dir twapi_os 4.1.27 load {} {}]
package ifneeded twapi_pdh 4.1.27 [list twapi::package_setup $dir twapi_pdh 4.1.27 load {} {}]
package ifneeded twapi_process 4.1.27 [list twapi::package_setup $dir twapi_process 4.1.27 load {} {}]
package ifneeded twapi_rds 4.1.27 [list twapi::package_setup $dir twapi_rds 4.1.27 load {} {}]
package ifneeded twapi_resource 4.1.27 [list twapi::package_setup $dir twapi_resource 4.1.27 load {} {}]
package ifneeded twapi_service 4.1.27 [list twapi::package_setup $dir twapi_service 4.1.27 load {} {}]
package ifneeded twapi_share 4.1.27 [list twapi::package_setup $dir twapi_share 4.1.27 load {} {}]
package ifneeded twapi_shell 4.1.27 [list twapi::package_setup $dir twapi_shell 4.1.27 load {} {}]
package ifneeded twapi_storage 4.1.27 [list twapi::package_setup $dir twapi_storage 4.1.27 load {} {}]
package ifneeded twapi_ui 4.1.27 [list twapi::package_setup $dir twapi_ui 4.1.27 load {} {}]
package ifneeded twapi_input 4.1.27 [list twapi::package_setup $dir twapi_input 4.1.27 load {} {}]
package ifneeded twapi_winsta 4.1.27 [list twapi::package_setup $dir twapi_winsta 4.1.27 load {} {}]
package ifneeded twapi_wmi 4.1.27 [list twapi::package_setup $dir twapi_wmi 4.1.27 load {} {}]
package ifneeded twapi 4.1.27 {
  package require twapi_base 4.1.27
  package require metoo 4.1.27
  package require twapi_com 4.1.27
  package require twapi_msi 4.1.27
  package require twapi_power 4.1.27
  package require twapi_printer 4.1.27
  package require twapi_synch 4.1.27
  package require twapi_security 4.1.27
  package require twapi_account 4.1.27
  package require twapi_apputil 4.1.27
  package require twapi_clipboard 4.1.27
  package require twapi_console 4.1.27
  package require twapi_crypto 4.1.27
  package require twapi_device 4.1.27
  package require twapi_etw 4.1.27
  package require twapi_eventlog 4.1.27
  package require twapi_mstask 4.1.27
  package require twapi_multimedia 4.1.27
  package require twapi_namedpipe 4.1.27
  package require twapi_network 4.1.27
  package require twapi_nls 4.1.27
  package require twapi_os 4.1.27
  package require twapi_pdh 4.1.27
  package require twapi_process 4.1.27
  package require twapi_rds 4.1.27
  package require twapi_resource 4.1.27
  package require twapi_service 4.1.27
  package require twapi_share 4.1.27
  package require twapi_shell 4.1.27
  package require twapi_storage 4.1.27
  package require twapi_ui 4.1.27
  package require twapi_input 4.1.27
  package require twapi_winsta 4.1.27
  package require twapi_wmi 4.1.27

  package provide twapi 4.1.27
}
