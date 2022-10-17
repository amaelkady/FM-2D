#
# Copyright (c) 2004-2011 Ashok P. Nadkarni
# All rights reserved.
#
# See the file LICENSE for license

namespace eval twapi {}


# Get the specified shell folder
proc twapi::get_shell_folder {csidl args} {
    variable csidl_lookup

    array set opts [parseargs args {create} -maxleftover 0]

    # Following are left out because they refer to virtual folders
    # and will return error if used here
    #    CSIDL_BITBUCKET - 0xa
    if {![info exists csidl_lookup]} {
        array set csidl_lookup {
            CSIDL_ADMINTOOLS 0x30
            CSIDL_COMMON_ADMINTOOLS 0x2f
            CSIDL_APPDATA 0x1a
            CSIDL_COMMON_APPDATA 0x23
            CSIDL_COMMON_DESKTOPDIRECTORY 0x19
            CSIDL_COMMON_DOCUMENTS 0x2e
            CSIDL_COMMON_FAVORITES 0x1f
            CSIDL_COMMON_MUSIC 0x35
            CSIDL_COMMON_PICTURES 0x36
            CSIDL_COMMON_PROGRAMS 0x17
            CSIDL_COMMON_STARTMENU 0x16
            CSIDL_COMMON_STARTUP 0x18
            CSIDL_COMMON_TEMPLATES 0x2d
            CSIDL_COMMON_VIDEO 0x37
            CSIDL_COOKIES 0x21
            CSIDL_DESKTOPDIRECTORY 0x10
            CSIDL_FAVORITES 0x6
            CSIDL_HISTORY 0x22
            CSIDL_INTERNET_CACHE 0x20
            CSIDL_LOCAL_APPDATA 0x1c
            CSIDL_MYMUSIC 0xd
            CSIDL_MYPICTURES 0x27
            CSIDL_MYVIDEO 0xe
            CSIDL_NETHOOD 0x13
            CSIDL_PERSONAL 0x5
            CSIDL_PRINTHOOD 0x1b
            CSIDL_PROFILE 0x28
            CSIDL_PROFILES 0x3e
            CSIDL_PROGRAMS 0x2
            CSIDL_PROGRAM_FILES 0x26
            CSIDL_PROGRAM_FILES_COMMON 0x2b
            CSIDL_RECENT 0x8
            CSIDL_SENDTO 0x9
            CSIDL_STARTMENU 0xb
            CSIDL_STARTUP 0x7
            CSIDL_SYSTEM 0x25
            CSIDL_TEMPLATES 0x15
            CSIDL_WINDOWS 0x24
            CSIDL_CDBURN_AREA 0x3b
        }
    }

    if {![string is integer $csidl]} {
        set csidl_key [string toupper $csidl]
        if {![info exists csidl_lookup($csidl_key)]} {
            # Try by adding a CSIDL prefix
            set csidl_key "CSIDL_$csidl_key"
            if {![info exists csidl_lookup($csidl_key)]} {
                error "Invalid CSIDL value '$csidl'"
            }
        }
        set csidl $csidl_lookup($csidl_key)
    }

    trap {
        set path [SHGetSpecialFolderPath 0 $csidl $opts(create)]
    } onerror {} {
        # Try some other way to get the information
        switch -exact -- [format %x $csidl] {
            1a { catch {set path $::env(APPDATA)} }
            2b { catch {set path $::env(CommonProgramFiles)} }
            26 { catch {set path $::env(ProgramFiles)} }
            24 { catch {set path $::env(windir)} }
            25 { catch {set path [file join $::env(systemroot) system32]} }
        }
        if {![info exists path]} {
            return ""
        }
    }

    return $path
}

# Displays a shell property dialog for the given object
proc twapi::shell_object_properties_dialog {path args} {
    array set opts [parseargs args {
        {type.arg file {file printer volume}}
        {hwin.int 0}
        {page.arg ""}
    } -maxleftover 0]


    if {$opts(type) eq "file"} {
        set path [file nativename [file normalize $path]]
    }

    SHObjectProperties $opts(hwin) \
        [string map {printer 1 file 2 volume 4} $opts(type)] \
        $path \
        $opts(page)
}

# Writes a shell shortcut
proc twapi::write_shortcut {link args} {
    
    array set opts [parseargs args {
        path.arg
        idl.arg
        args.arg
        desc.arg
        hotkey.arg
        iconpath.arg
        iconindex.int
        {showcmd.arg normal}
        workdir.arg
        relativepath.arg
        runas.bool
    } -nulldefault -maxleftover 0]

    # Map hot key to integer if needed
    if {![string is integer -strict $opts(hotkey)]} {
        if {$opts(hotkey) eq ""} {
            set opts(hotkey) 0
        } else {
            # Try treating it as symbolic
            lassign [_hotkeysyms_to_vk $opts(hotkey)]  modifiers vk
            set opts(hotkey) $vk
            if {$modifiers & 1} {
                set opts(hotkey) [expr {$opts(hotkey) | (4<<8)}]
            }
            if {$modifiers & 2} {
                set opts(hotkey) [expr {$opts(hotkey) | (2<<8)}]
            }
            if {$modifiers & 4} {
                set opts(hotkey) [expr {$opts(hotkey) | (1<<8)}]
            }
            if {$modifiers & 8} {
                set opts(hotkey) [expr {$opts(hotkey) | (8<<8)}]
            }
        }
    }

    # IF a known symbol translate it. Note caller can pass integer
    # values as well which will be kept as they are. Bogus valuse and
    # symbols will generate an error on the actual call so we don't
    # check here.
    switch -exact -- $opts(showcmd) {
        minimized { set opts(showcmd) 7 }
        maximized { set opts(showcmd) 3 }
        normal    { set opts(showcmd) 1 }
    }

    Twapi_WriteShortcut $link $opts(path) $opts(idl) $opts(args) \
        $opts(desc) $opts(hotkey) $opts(iconpath) $opts(iconindex) \
        $opts(relativepath) $opts(showcmd) $opts(workdir) $opts(runas)
}


# Read a shortcut
proc twapi::read_shortcut {link args} {
    array set opts [parseargs args {
        timeout.int
        {hwin.int 0}

        {_comment {Path format flags}}
        {shortnames {} 1}
        {uncpath    {} 2}
        {rawpath    {} 4}

        {_comment {Resolve flags}}
        {install {} 128}
        {nolinkinfo {} 64}
        {notrack {} 32}
        {nosearch {} 16}
        {anymatch {} 2}
        {noui {} 1}
    } -maxleftover 0]

    set pathfmt [expr {$opts(shortnames) | $opts(uncpath) | $opts(rawpath)}]

    # 4 -> SLR_UPDATE
    set resolve_flags [expr {4 | $opts(install) | $opts(nolinkinfo) |
                             $opts(notrack) | $opts(nosearch) |
                             $opts(anymatch) | $opts(noui)}]

    array set shortcut [twapi::Twapi_ReadShortcut $link $pathfmt $opts(hwin) $resolve_flags]

    switch -exact -- $shortcut(-showcmd) {
        1 { set shortcut(-showcmd) normal }
        3 { set shortcut(-showcmd) maximized }
        7 { set shortcut(-showcmd) minimized }
    }

    return [array get shortcut]
}



# Writes a url shortcut
proc twapi::write_url_shortcut {link url args} {
    
    array set opts [parseargs args {
        {missingprotocol.arg 0}
    } -nulldefault -maxleftover 0]

    switch -exact -- $opts(missingprotocol) {
        guess {
            set opts(missingprotocol) 1; # IURL_SETURL_FL_GUESS_PROTOCOL
        }
        usedefault {
            # 3 -> IURL_SETURL_FL_GUESS_PROTOCOL | IURL_SETURL_FL_USE_DEFAULT_PROTOCOL
            # The former must also be specified (based on experimentation)
            set opts(missingprotocol) 3
        }
        default {
            if {![string is integer -strict $opts(missingprotocol)]} {
                error "Invalid value '$opts(missingprotocol)' for -missingprotocol option."
            }
        }
    }

    Twapi_WriteUrlShortcut $link $url $opts(missingprotocol)
}

# Read a url shortcut
proc twapi::read_url_shortcut {link} {
    return [Twapi_ReadUrlShortcut $link]
}

# Invoke a url shortcut
proc twapi::invoke_url_shortcut {link args} {
    
    array set opts [parseargs args {
        verb.arg
        {hwin.int 0}
        allowui
    } -maxleftover 0]

    set flags 0
    if {$opts(allowui)} {setbits flags 1}
    if {! [info exists opts(verb)]} {
        setbits flags 2
        set opts(verb) ""
    }
    

    Twapi_InvokeUrlShortcut $link $opts(verb) $flags $opts(hwin)
}

# Send a file to the recycle bin
proc twapi::recycle_file {fn args} {
    array set opts [parseargs args {
        confirm.bool
        showerror.bool
    } -maxleftover 0 -nulldefault]

    set fn [file nativename [file normalize $fn]]

    if {$opts(confirm)} {
        set flags 0x40;         # FOF_ALLOWUNDO
    } else {
        set flags 0x50;         # FOF_ALLOWUNDO | FOF_NOCONFIRMATION
    }

    if {! $opts(showerror)} {
        set flags [expr {$flags | 0x0400}]; # FOF_NOERRORUI
    }

    return [expr {[lindex [Twapi_SHFileOperation 0 3 [list $fn] __null__ $flags ""] 0] ? false : true}]
}

proc twapi::shell_execute args {
    # TBD - Document following shell_execute options after testing.
    # [opt_def [cmd -class] [arg BOOLEAN]]
    # [opt_def [cmd -connect] [arg BOOLEAN]]
    # [opt_def [cmd -hicon] [arg HANDLE]]
    # [opt_def [cmd -hkeyclass] [arg BOOLEAN]]
    # [opt_def [cmd -hotkey] [arg HOTKEY]]
    # [opt_def [cmd -nozonechecks] [arg BOOLEAN]]

    array set opts [parseargs args {
        class.arg
        dir.arg
        {hicon.arg NULL}
        {hkeyclass.arg NULL}
        {hmonitor.arg NULL}
        hotkey.arg
        hwin.int
        idl.arg
        params.arg
        path.arg
        {show.arg 1}
        verb.arg

        {getprocesshandle.bool 0 0x00000040}
        {connect.bool 0 0x00000080}
        {wait.bool 0x00000100 0x00000100}
        {substenv.bool 0 0x00000200}
        {noui.bool 0 0x00000400}
        {unicode.bool 0 0x00004000}
        {noconsole.bool 0 0x00008000}
        {asyncok.bool 0 0x00100000}
        {nozonechecks.bool 0 0x00800000}
        {waitforinputidle.bool 0 0x02000000}
        {logusage.bool 0 0x04000000}
        {invokeidlist.bool 0 0x0000000C}
    } -maxleftover 0 -nulldefault]

    set fmask 0

    foreach {opt mask} {
        class     1
        idl       4
    } {
        if {$opts($opt) ne ""} {
            setbits fmask $mask
        }
    }

    if {$opts(hkeyclass) ne "NULL"} {
        setbits fmask 3
    }

    set fmask [expr {$fmask |
                     $opts(getprocesshandle) | $opts(connect) | $opts(wait) |
                     $opts(substenv) | $opts(noui) | $opts(unicode) |
                     $opts(noconsole) | $opts(asyncok) | $opts(nozonechecks) |
                     $opts(waitforinputidle) | $opts(logusage) |
                     $opts(invokeidlist)}]

    if {$opts(hicon) ne "NULL" && $opts(hmonitor) ne "NULL"} {
        error "Cannot specify -hicon and -hmonitor options together."
    }

    set hiconormonitor NULL
    if {$opts(hicon) ne "NULL"} {
        set hiconormonitor $opts(hicon)
        set flags [expr {$flags | 0x00000010}]
    } elseif {$opts(hmonitor) ne "NULL"} {
        set hiconormonitor $opts(hmonitor)
        set flags [expr {$flags | 0x00200000}]
    }

    if {![string is integer -strict $opts(show)]} {
        set opts(show) [dict get {
            hide             0
            shownormal       1
            normal           1
            showminimized    2
            showmaximized    3
            maximize         3
            shownoactivate   4
            show             5
            minimize         6
            showminnoactive  7
            showna           8
            restore          9
            showdefault      10
            forceminimize    11
        } $opts(show)]
    }

    if {$opts(hotkey) eq ""} {
        set hotkey 0
    } else {
        lassign [_hotkeysyms_to_vk $opts(hotkey) {
            shift 1
            ctrl 2
            control 2
            alt 4
            menu 4
            ext 8
        }] modifiers vk
        set hotkey [expr {($modifiers << 16) | $vk}]
    }
    if {$hotkey != 0} {
        setbits fmask 0x00000020
    }

    return [Twapi_ShellExecuteEx \
                $fmask \
                $opts(hwin) \
                $opts(verb) \
                $opts(path) \
                $opts(params) \
                $opts(dir) \
                $opts(show) \
                $opts(idl) \
                $opts(class) \
                $opts(hkeyclass) \
                $hotkey \
                $hiconormonitor]
}


namespace eval twapi::systemtray {

    namespace path [namespace parent]

    # Dictionary mapping id->handler, hicon
    variable _icondata
    set _icondata [dict create]

    variable _icon_id_ctr

    variable _message_map
    array set _message_map {
        123 contextmenu
        512 mousemove
        513 lbuttondown
        514 lbuttonup
        515 lbuttondblclk
        516 rbuttondown
        517 rbuttonup
        518 rbuttondblclk
        519 mbuttondown
        520 mbuttonup
        521 mbuttondblclk
        522 mousewheel
        523 xbuttondown
        524 xbuttonup
        525 xbuttondblclk
        1024 select
        1025 keyselect
        1026 balloonshow
        1027 balloonhide
        1028 balloontimeout
        1029 balloonuserclick
    }
        
    proc _make_NOTIFYICONW {id args} {
        # TBD - implement -hiddenicon and -sharedicon using
        # dwState and dwStateMask
        set state     0
        set statemask 0
        array set opts [parseargs args {
            hicon.arg
            tip.arg
            balloon.arg
            timeout.int
            version.int
            balloontitle.arg
            {balloonicon.arg none {info warning error user none}}
            {silent.bool 0}
        } -maxleftover 0]

        set timeout_or_version 0
        if {[info exists opts(version)]} {
            if {[info exists opts(timeout)]} {
                error "Cannot simultaneously specify -timeout and -version."
            }
            set timeout_or_version $opts(version)
        } else {
            if {[info exists opts(timeout)]} {
                set timeout_or_version $opts(timeout)
            }
        }

        set flags 0x1;          # uCallbackMessage member is valid
        if {[info exists opts(hicon)]} {
            incr flags 0x2;     # hIcon member is valid
        } else {
            set opts(hicon) NULL
        }

        if {[info exists opts(tip)]} {
            incr flags 0x4
            # Truncate if necessary to 127 chars
            set opts(tip) [string range $opts(tip) 0 127]
        } else {
            set opts(tip) ""
        }

        if {[info exists opts(balloon)] || [info exists opts(balloontitle)]} {
            incr flags 0x10
        }

        if {[info exists opts(balloon)]} {
            set opts(balloon) [string range $opts(balloon) 0 255]
        } else {
            set opts(balloon) ""
        }

        if {[info exists opts(balloontitle)]} {
            set opts(balloontitle) [string range $opts(balloontitle) 0 63]
        } else {
            set opts(balloontitle) ""
        }

        # Calculate padding for text fields (in bytes so 2*num padchars)
        set tip_padcount [expr {2*(128 - [string length $opts(tip)])}]
        set balloon_padcount [expr {2*(256 - [string length $opts(balloon)])}]
        set balloontitle_padcount [expr {2 * (64 - [string length $opts(balloontitle)])}]
        if {$opts(balloonicon) eq "user"} {
            if {![min_os_version 5 1 2]} {
                # 'user' not supported before XP SP2
                set opts(balloonicon) none
            }
        }

        set balloonflags [dict get {
            none 0
            info 1
            warning 2
            error 3
            user 4
        } $opts(balloonicon)]
        
        if {$balloonflags == 4} {
            if {![info exists opts(hicon)]} {
                error "Option -hicon must be specified if value of -balloonicon option is 'user'"
            }
        }

        if {$opts(silent)} {
            incr balloonflags 0x10
        }

        if {$::tcl_platform(pointerSize) == 8} {
            set addrfmt m
            set alignment x4
        } else {
            set addrfmt n
            set alignment x0
        }

        set hwnd  [pointer_to_address [Twapi_GetNotificationWindow]]
        set opts(hicon) [pointer_to_address $opts(hicon)]

        set bin [binary format "${alignment}${addrfmt}nnn" $hwnd $id $flags [_get_script_wm NOTIFY_ICON_CALLBACK]]
        append bin \
            [binary format ${alignment}${addrfmt} $opts(hicon)] \
            [encoding convertto unicode $opts(tip)] \
            [binary format "x${tip_padcount}nn" $state $statemask] \
            [encoding convertto unicode $opts(balloon)] \
            [binary format "x${balloon_padcount}n" $timeout_or_version] \
            [encoding convertto unicode $opts(balloontitle)] \
            [binary format "x${balloontitle_padcount}nx16" $balloonflags]
        return "[binary format n [expr {4+[string length $bin]}]]$bin"
    }

    proc addicon {hicon {cmdprefix ""}} {
        variable _icon_id_ctr
        variable _icondata

        _register_script_wm_handler [_get_script_wm NOTIFY_ICON_CALLBACK] [list [namespace current]::_icon_handler] 1
        _register_script_wm_handler [_get_script_wm TASKBAR_RESTART] [list [namespace current]::_taskbar_restart_handler] 1
        
        set id [incr _icon_id_ctr]
        
        # 0 -> Add
        Shell_NotifyIcon 0 [_make_NOTIFYICONW $id -hicon $hicon]

        # 4 -> set version (controls notification behaviour) to 3 (Win2K+)
        if {[catch {
            Shell_NotifyIcon 4 [_make_NOTIFYICONW $id -version 3]
        } ermsg]} {
            set ercode $::errorCode
            set erinfo $::errorInfo
            removeicon $id
            error $ermsg $erinfo $ercode
        }

        if {[llength $cmdprefix]} {
            dict set _icondata $id handler $cmdprefix
        }
        dict set _icondata $id hicon   $hicon

        return $id
    }

    proc removeicon {id} {
        variable _icondata

        # Ignore errors in case dup call
        catch {Shell_NotifyIcon 2 [_make_NOTIFYICONW $id]}
        dict unset _icondata $id
    }

    proc modifyicon {id args} {
        # TBD - do we need to [dict set _icondata hicon ...] ?
        Shell_NotifyIcon 1 [_make_NOTIFYICONW $id {*}$args]
    }

    proc _icon_handler {msg id notification msgpos ticks} {
        variable _icondata
        variable _message_map

        if {![dict  exists $_icondata $id handler]} {
            return;             # Stale or no handler specified
        }

        # Translate the notification into text
        if {[info exists _message_map($notification)]} {
            set notification $_message_map($notification)
        }
        
        uplevel #0 [linsert [dict get $_icondata $id handler] end $id $notification $msgpos $ticks]
    }

    proc _taskbar_restart_handler {args} {
        variable _icondata
        # Need to add icons back into taskbar
        dict for {id icodata} $_icondata {
            # 0 -> Add
            Shell_NotifyIcon 0 [_make_NOTIFYICONW $id -hicon [dict get $icodata hicon]]
        }
    }

    namespace export addicon modifyicon removeicon
    namespace ensemble create
}
