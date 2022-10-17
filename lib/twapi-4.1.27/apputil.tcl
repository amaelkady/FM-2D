#
# Copyright (c) 2003-2012, Ashok P. Nadkarni
# All rights reserved.
#
# See the file LICENSE for license

namespace eval twapi {}

# Get the command line
proc twapi::get_command_line {} {
    return [GetCommandLineW]
}

# Parse the command line
proc twapi::get_command_line_args {cmdline} {
    # Special check for empty line. CommandLinetoArgv returns process
    # exe name in this case.
    if {[string length $cmdline] == 0} {
        return [list ]
    }
    return [CommandLineToArgv $cmdline]
}

# Read an ini file int
proc twapi::read_inifile_key {section key args} {
    array set opts [parseargs args {
        {default.arg ""}
        inifile.arg
    } -maxleftover 0]

    if {[info exists opts(inifile)]} {
        set values [read_inifile_section $section -inifile $opts(inifile)]
    } else {
        set values [read_inifile_section $section]
    }

    # Cannot use kl_get or arrays here because we want case insensitive compare
    foreach {k val} $values {
        if {[string equal -nocase $key $k]} {
            return $val
        }
    }
    return $opts(default)
}

# Write an ini file string
proc twapi::write_inifile_key {section key value args} {
    array set opts [parseargs args {
        inifile.arg
    } -maxleftover 0]

    if {[info exists opts(inifile)]} {
        WritePrivateProfileString $section $key $value $opts(inifile)
    } else {
        WriteProfileString $section $key $value
    }
}

# Delete an ini file string
proc twapi::delete_inifile_key {section key args} {
    array set opts [parseargs args {
        inifile.arg
    } -maxleftover 0]

    if {[info exists opts(inifile)]} {
        WritePrivateProfileString $section $key $twapi::nullptr $opts(inifile)
    } else {
        WriteProfileString $section $key $twapi::nullptr
    }
}

# Get names of the sections in an inifile
proc twapi::read_inifile_section_names {args} {
    array set opts [parseargs args {
        inifile.arg
    } -nulldefault -maxleftover 0]

    return [GetPrivateProfileSectionNames $opts(inifile)]
}

# Get keys and values in a section in an inifile
proc twapi::read_inifile_section {section args} {
    array set opts [parseargs args {
        inifile.arg
    } -nulldefault -maxleftover 0]

    set result [list ]
    foreach line [GetPrivateProfileSection $section $opts(inifile)] {
        set pos [string first "=" $line]
        if {$pos >= 0} {
            lappend result [string range $line 0 [expr {$pos-1}]] [string range $line [incr pos] end]
        }
    }
    return $result
}


# Delete an ini file section
proc twapi::delete_inifile_section {section args} {
    variable nullptr

    array set opts [parseargs args {
        inifile.arg
    }]

    if {[info exists opts(inifile)]} {
        WritePrivateProfileString $section $nullptr $nullptr $opts(inifile)
    } else {
        WriteProfileString $section $nullptr $nullptr
    }
}



