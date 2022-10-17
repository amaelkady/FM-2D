#
# Copyright (c) 2003-2012 Ashok P. Nadkarni
# All rights reserved.
#
# See the file LICENSE for license

# TBD - define a C function and way to implement window callback so
# that SetWindowLong(GWL_WNDPROC) can be implemente
#


# TBD  - document the following class names
#  SciCalc            CALC.EXE
#  CalWndMain         CALENDAR.EXE
#  Cardfile           CARDFILE.EXE
#  Clipboard          CLIPBOARD.EXE
#  Clock              CLOCK.EXE
#  CtlPanelClass      CONTROL.EXE
#  XLMain             EXCEL.EXE
#  Session            MS-DOS.EXE
#  Notepad            NOTEPAD.EXE
#  pbParent           PBRUSH.EXE
#  Pif                PIFEDIT.EXE
#  PrintManager       PRINTMAN.EXE
#  Progman            PROGMAN.EXE   (Windows Program Manager)
#  Recorder           RECORDER.EXE
#  Reversi            REVERSI.EXE
#  #32770             SETUP.EXE
#  Solitaire          SOL.EXE
#  Terminal           TERMINAL.EXE
#  WFS_Frame          WINFILE.EXE
#  MW_WINHELP         WINHELP.EXE
#  #32770             WINVER.EXE
#  OpusApp            WINWORD.EXE
#  MSWRITE_MENU       WRITE.EXE
#  OMain  Microsoft Access
#  XLMAIN  Microsoft Excel
#  rctrl_renwnd32  Microsoft Outlook
#  PP97FrameClass  Microsoft PowerPoint
#  OpusApp  Microsoft Word

namespace eval twapi {
    struct POINT {LONG x;  LONG y;}
    struct RECT { LONG left; LONG top; LONG right; LONG bottom; }
    struct WINDOWPLACEMENT {
        UINT   cbSize;
        UINT   flags;
        UINT  showCmd;
        struct POINT ptMinPosition;
        struct POINT ptMaxPosition;
        struct RECT  rcNormalPosition;
    }
}

proc twapi::get_window_placement {hwin} {
    GetWindowPlacement $hwin [WINDOWPLACEMENT]
}

# Set the focus to the given window
proc twapi::set_focus {hwin} {
    return [_return_window [_attach_hwin_and_eval $hwin {SetFocus $hwin}]]
}

# Enumerate toplevel windows
proc twapi::get_toplevel_windows {args} {

    array set opts [parseargs args {
        {pid.arg}
        {pids.arg}
    }]

    set toplevels [twapi::EnumWindows]

    if {[info exists opts(pids)]} {
        set pids $opts(pids)
    } elseif {[info exists opts(pid)]} {
        set pids [list $opts(pid)]
    } else {
        return $toplevels
    }

    set process_toplevels [list ]
    foreach toplevel $toplevels {
        set pid [get_window_process $toplevel]
        if {[lsearch -exact -integer $pids $pid] >= 0} {
            lappend process_toplevels $toplevel
        }
    }

    return $process_toplevels
}


# Find a window based on given criteria
proc twapi::find_windows {args} {
    # TBD - would incorporating FindWindowEx be faster
    # TBD - apparently on Windows 8, you need to use FindWindowEx to
    # get non-toplevel Metro windows

    array set opts [parseargs args {
        ancestor.arg
        caption.bool
        child.bool
        class.arg
        {match.arg string {string glob regexp}}
        maximize.bool
        maximizebox.bool
        messageonlywindow.bool
        minimize.bool
        minimizebox.bool
        overlapped.bool
        pids.arg
        popup.bool
        single
        style.arg
        text.arg
        toplevel.bool
        visible.bool
    } -maxleftover 0]

    if {[info exists opts(style)]
        ||[info exists opts(overlapped)]
        || [info exists opts(popup)]
        || [info exists opts(child)]
        || [info exists opts(minimizebox)]
        || [info exists opts(maximizebox)]
        || [info exists opts(minimize)]
        || [info exists opts(maximize)]
        || [info exists opts(visible)]
        || [info exists opts(caption)]
    } {
        set need_style 1
    } else {
        set need_style 0
    }

    # Figure out the type of match if -text specified
    if {[info exists opts(text)]} {
        switch -exact -- $opts(match) {
            glob {
                set text_compare [list string match -nocase $opts(text)]
            }
            string {
                set text_compare [list string equal -nocase $opts(text)]
            }
            regexp {
                set text_compare [list regexp -nocase $opts(text)]
            }
            default {
                error "Invalid value '$opts(match)' specified for -match option"
            }
        }
    }

    # First build a list of potential candidates. There are two main
    # categories we have to look at - ordinary windows and message-only
    # windows. Normally, both are included. However, if -messageonlywindow
    # is specified, then we only include the former or the latter
    # depending on the value of the -messageonlywindow option

    set include_ordinary true
    if {[info exists opts(messageonlywindow)]} {
        if {$opts(messageonlywindow)} {
            if {[info exists opts(toplevel)] && $opts(toplevel)} {
                error "Options -toplevel and -messageonlywindow cannot be both specified as true"
            }
            if {[info exists opts(text)]} {
                # See bug 3213001
                error "Option -text cannot be specified if -messageonlywindow is specified as true"
            }
            if {[info exists opts(ancestor)]} {
                error "Option -ancestor cannot be specified if -messageonlywindow is specified as true"
            }
            set include_ordinary false
        }
        set include_messageonly $opts(messageonlywindow)
    } else {
        # -messageonlywindow not specified at all. Only include
        # messageonly windows if toplevel is not specified as true
        # Also, if opts(text) is specified, will never match messageonly
        # so set it to false to we do not pick up messageonly windows
        # (which will hang if we go looking for them with -text : see
        # bug 3213001).
        if {([info exists opts(toplevel)] && $opts(toplevel)) ||
            [info exists opts(ancestor)] || [info exists opts(text)]
        } {
            set include_messageonly false
        } else {
            set include_messageonly true
        }
    }

    if {$include_messageonly} {
        set class ""
        if {[info exists opts(class)]} {
            set class $opts(class)
        }
        set text ""
        if {[info exists opts(text)] &&
            $opts(match) eq "string"} {
            set text $opts(text)
        }
        set messageonly_candidates [_get_message_only_windows]
    } else {
        set messageonly_candidates [list ]
    }

    if {$include_ordinary} {
        # TBD - make use of FindWindowEx function if possible

        # If only interested in toplevels, just start from there
        if {[info exists opts(toplevel)]} {
            if {$opts(toplevel)} {
                set ordinary_candidates [get_toplevel_windows]
                if {[info exists opts(ancestor)]} {
                    error "Option -ancestor may not be specified together with -toplevel true"
                }
            } else {
                # We do not want windows to be toplevels. Remember list
                # so we can check below.
                set toplevels [get_toplevel_windows]
            }
        }

        if {![info exists ordinary_candidates]} {
            # -toplevel TRuE not specified.
            # If ancestor is not specified, we start from the desktop window
            # Note ancestor, if specified, is never included in the search
            if {[info exists opts(ancestor)] && ![pointer_null? $opts(ancestor)]} {
                set ordinary_candidates [get_descendent_windows $opts(ancestor)]
            } else {
                set desktop [get_desktop_window]
                set ordinary_candidates [concat [list $desktop] [get_descendent_windows $desktop]]
            }
        }
    } else {
        set ordinary_candidates [list ]
    }


    set matches [list ]
    foreach win [concat $messageonly_candidates $ordinary_candidates] {
        # Why are we not using a trap here instead of catch ? TBD
        set status [catch {
            if {[info exists toplevels]} {
                # We do NOT want toplevels
                if {[lsearch -exact $toplevels $win] >= 0} {
                    # This is toplevel, which we don't want
                    continue
                }
            }

            # TBD - what is the right order to check from a performance
            # point of view

            if {$need_style} {
                set win_styles [get_window_style $win]
                set win_style [lindex $win_styles 0]
                set win_exstyle [lindex $win_styles 1]
                set win_styles [lrange $win_styles 2 end]
            }

            if {[info exists opts(style)] && [llength $opts(style)]} {
                lassign $opts(style)  style exstyle
                if {[string length $style] && ($style != $win_style)} continue
                if {[string length $exstyle] && ($exstyle != $win_exstyle)} continue
            }

            set match 1
            foreach opt {visible overlapped popup child minimizebox
                maximizebox minimize maximize caption
            } {
                if {[info exists opts($opt)]} {
                    if {(! $opts($opt)) == ([lsearch -exact $win_styles $opt] >= 0)} {
                        set match 0
                        break
                    }
                }
            }
            if {! $match} continue

            # TBD - should we use get_window_class or get_window_real_class
            if {[info exists opts(class)] &&
                [string compare -nocase $opts(class) [get_window_class $win]]} {
                continue
            }

            if {[info exists opts(pids)]} {
                set pid [get_window_process $win]
                if {[lsearch -exact -integer $opts(pids) $pid] < 0} continue
            }

            if {[info exists opts(text)]} {
                set text [get_window_text $win]
                if {![eval $text_compare [list [get_window_text $win]]]} continue
            }
            # Matches all criteria. If we only want one, return it, else
            # add to match list
            if {$opts(single)} {
                return $win
            }
            lappend matches $win
        } result ]

        switch -exact -- $status {
            0 {
                # No error, just keep going
            }
            1 {
                # Error, see if error code is no window and if so, ignore
                lassign $::errorCode subsystem code msg
                if {$subsystem == "TWAPI_WIN32"} {
                    # Window has disappeared so just do not include it
                    # Cannot just actual code since many different codes
                    # might be returned in this case
                } else {
                    error $result $::errorInfo $::errorCode
                }
            }
            2 {
                return $result;         # Block executed a return
            }
            3 {
                break;                  # Block executed a break
            }
            4 {
                continue;               # Block executed a continue
            }
        }
    }

    return $matches

}


# Return all descendent windows
proc twapi::get_descendent_windows {parent_hwin} {
    return [EnumChildWindows $parent_hwin]
}

# Return the parent window
proc twapi::get_parent_window {hwin} {
    # Note - we use GetAncestor and not GetParent because the latter
    # will return the owner in the case of a toplevel window
    # 1 -> GA_PARENT -> 1
    return [_return_window [GetAncestor $hwin 1]]
}

# Return owner window
proc twapi::get_owner_window {hwin} {
    # GW_OWNER -> 4
    return [_return_window [twapi::GetWindow $hwin 4]]
}

# Return immediate children of a window (not all children)
proc twapi::get_child_windows {hwin} {
    set children [list ]
    # TBD - maybe get_first_child/get_next_child would be more efficient
    foreach w [get_descendent_windows $hwin] {
        if {[_same_window $hwin [get_parent_window $w]]} {
            lappend children $w
        }
    }
    return $children
}

# Return first child in z-order
proc twapi::get_first_child {hwin} {
    # GW_CHILD -> 5
    return [_return_window [twapi::GetWindow $hwin 5]]
}


# Return the next sibling window in z-order
proc twapi::get_next_sibling_window {hwin} {
    # GW_HWNDNEXT -> 2
    return [_return_window [twapi::GetWindow $hwin 2]]
}

# Return the previous sibling window in z-order
proc twapi::get_prev_sibling_window {hwin} {
    # GW_HWNDPREV -> 3
    return [_return_window [twapi::GetWindow $hwin 3]]
}

# Return the sibling window that is highest in z-order
proc twapi::get_first_sibling_window {hwin} {
    # GW_HWNDFIRST -> 0
    return [_return_window [twapi::GetWindow $hwin 0]]
}

# Return the sibling window that is lowest in z-order
proc twapi::get_last_sibling_window {hwin} {
    # GW_HWNDLAST -> 1
    return [_return_window [twapi::GetWindow $hwin 1]]
}

# Return the desktop window
proc twapi::get_desktop_window {} {
    return [_return_window [twapi::GetDesktopWindow]]
}

# Return the shell window
proc twapi::get_shell_window {} {
    return [_return_window [twapi::GetShellWindow]]
}

# Return the pid for a window
proc twapi::get_window_process {hwin} {
    return [lindex [GetWindowThreadProcessId $hwin] 1]
}

# Return the thread for a window
proc twapi::get_window_thread {hwin} {
    return [lindex [GetWindowThreadProcessId $hwin] 0]
}

# Return the style of the window. Returns a list of two integers
# the first contains the style bits, the second the extended style bits
proc twapi::get_window_style {hwin} {
    # GWL_STYLE -> -16, GWL_EXSTYLE -20
    set style   [GetWindowLongPtr $hwin -16]
    set exstyle [GetWindowLongPtr $hwin -20]
    return [concat [list $style $exstyle] [_style_mask_to_symbols $style $exstyle]]
}


# Set the style of the window. Returns a list of two integers
# the first contains the original style bits, the second the
# original extended style bits
proc twapi::set_window_style {hwin style exstyle} {
    # GWL_STYLE -> -16, GWL_EXSTYLE -20
    set style [SetWindowLongPtr $hwin -16 $style]
    set exstyle [SetWindowLongPtr $hwin -20 $exstyle]

    redraw_window_frame $hwin
    return
}


# Return the class of the window
proc twapi::get_window_class {hwin} {
    return [GetClassName $hwin]
}

# Return the real class of the window
proc twapi::get_window_real_class {hwin} {
    return [RealGetWindowClass $hwin]
}

# Return the identifier corrpsonding to the application instance
proc twapi::get_window_application {hwin} {
    # GWL_HINSTANCE -> -6
    return [GetWindowLongPtr $hwin -6]
}

# Return the window id (this is different from the handle!)
proc twapi::get_window_id {hwin} {
    # GWL_ID -> -12
    return [GetWindowLongPtr $hwin -12]
}

# Return the user data associated with a window
proc twapi::get_window_userdata {hwin} {
    # GWL_USERDATA -> -21
    return [GetWindowLongPtr $hwin -21]
}


# Get the foreground window
proc twapi::get_foreground_window {} {
    return [_return_window [GetForegroundWindow]]
}

# Set the foreground window - returns 1/0 on success/fail
proc twapi::set_foreground_window {hwin} {
    return [SetForegroundWindow $hwin]
}


# Activate a window - this is only brought the foreground if its application
# is in the foreground
proc twapi::set_active_window_for_thread {hwin} {
    return [_return_window [_attach_hwin_and_eval $hwin {SetActiveWindow $hwin}]]
}

# Get active window for an application
proc twapi::get_active_window_for_thread {tid} {
    return [_return_window [_get_gui_thread_info $tid hwndActive]]
}


# Get focus window for an application
proc twapi::get_focus_window_for_thread {tid} {
    return [_get_gui_thread_info $tid hwndFocus]
}

# Get active window for current thread
proc twapi::get_active_window_for_current_thread {} {
    return [_return_window [GetActiveWindow]]
}

# Update the frame - needs to be called after setting certain style bits
proc twapi::redraw_window_frame {hwin} {
    # 0x4037 -> SWP_ASYNCWINDOWPOS | SWP_NOACTIVATE |
    #    SWP_NOMOVE | SWP_NOSIZE |
    #    SWP_NOZORDER | SWP_FRAMECHANGED
    SetWindowPos $hwin 0 0 0 0 0 0x4037
}

# Redraw the window
proc twapi::redraw_window {hwin {opt ""}} {
    if {[string length $opt]} {
        if {[string compare $opt "-force"]} {
            error "Invalid option '$opt'"
        }
        invalidate_screen_region -hwin $hwin -rect [list ] -bgerase
    }

    UpdateWindow $hwin
}

# Set the window position
proc twapi::move_window {hwin x y args} {
    array set opts [parseargs args {
        {sync}
    }]

    # Not using MoveWindow because that will require knowing the width
    # and height (or retrieving it)
    # 0x15 -> SWP_NOACTIVATE | SWP_NOSIZE | SWP_NOZORDER
    set flags 0x15
    if {! $opts(sync)} {
        setbits flags 0x4000; # SWP_ASYNCWINDOWPOS
    }
    SetWindowPos $hwin 0 $x $y 0 0 $flags
}

# Resize window
proc twapi::resize_window {hwin w h args} {
    array set opts [parseargs args {
        {sync}
    }]


    # Not using MoveWindow because that will require knowing the x and y pos
    # (or retrieving them)
    # 0x16 -> SWP_NOACTIVATE | SWP_NOMOVE | SWP_NOZORDER
    set flags 0x16
    if {! $opts(sync)} {
        setbits flags 0x4000; # SWP_ASYNCWINDOWPOS
    }
    SetWindowPos $hwin 0 0 0 $w $h $flags
}

# Sets the window's z-order position
# pos is either window handle or a symbol
proc twapi::set_window_zorder {hwin pos} {
    switch -exact -- $pos {
        top       {
            set pos [pointer_from_address 0 HWND];          #HWND_TOP
        }
        bottom    {
            set pos [pointer_from_address 1 HWND];          #HWND_BOTTOM
        }   
        toplayer   {
            set pos [pointer_from_address -1 HWND];         #HWND_TOPMOST
        }
        bottomlayer {
            set pos [pointer_from_address -2 HWND];         #HWND_NOTOPMOST
        }
    }

    # 0x4013 -> SWP_ASYNCWINDOWPOS|SWP_NOACTIVATE|SWP_NOSIZE|SWP_NOMOVE
    SetWindowPos $hwin $pos 0 0 0 0 0x4013
}


# Show the given window. Returns 1 if window was previously visible, else 0
proc twapi::show_window {hwin args} {
    array set opts [parseargs args {sync activate normal startup}]

    set show 0
    if {$opts(startup)} {
        set show 10; #SW_SHOWDEFAULT
    } else {
        if {$opts(activate)} {
            if {$opts(normal)} {
                set show 1; #SW_SHOWNORMAL
            } else {
                set show 5; #SW_SHOW
            }
        } else {
            if {$opts(normal)} {
                set show 4; #SW_SHOWNOACTIVATE
            } else {
                set show 8; #SW_SHOWNA
            }
        }
    }

    _show_window $hwin $show $opts(sync)
}

# Hide the given window. Returns 1 if window was previously visible, else 0
proc twapi::hide_window {hwin args} {
    array set opts [parseargs args {sync}]
    _show_window $hwin 0 $opts(sync); # 0 -> SW_HIDE
}

# Restore the given window. Returns 1 if window was previously visible, else 0
proc twapi::restore_window {hwin args} {
    array set opts [parseargs args {sync activate}]
    if {$opts(activate)} {
        _show_window $hwin 9 $opts(sync); # 9 -> SW_RESTORE
    } else {
        OpenIcon $hwin
    }
}

# Maximize the given window. Returns 1 if window was previously visible, else 0
proc twapi::maximize_window {hwin args} {
    array set opts [parseargs args {sync}]
    _show_window $hwin 3 $opts(sync); # 3 -> SW_SHOWMAXIMIZED
}


# Minimize the given window. Returns 1 if window was previously visible, else 0
proc twapi::minimize_window {hwin args} {
    array set opts [parseargs args {sync activate shownext}]

    # TBD - when should we use SW_FORCEMINIMIZE ?
    # TBD - do we need to attach to the window's thread?
    # TBD - when should we use CloseWindow instead?

    if $opts(activate) {
        set show 2; #SW_SHOWMINIMIZED
    } else {
        if {$opts(shownext)} {
            set show 6; #SW_MINIMIZE
        } else {
            set show 7; #SW_SHOWMINNOACTIVE
        }
    }

    _show_window $hwin $show $opts(sync)
}


# Hides popup windows
proc twapi::hide_owned_popups {hwin} {
    ShowOwnedPopups $hwin 0
}

# Show hidden popup windows
proc twapi::show_owned_popups {hwin} {
    ShowOwnedPopups $hwin 1
}

# Close a window
proc twapi::close_window {hwin args} {
    array set opts [parseargs args {
        block
        {wait.int 10}
    } -maxleftover 0]

    if {0} {
        Cannot close Explorer windows using SendMessage*
        if {$opts(block)} {
            set block 3; #SMTO_BLOCK|SMTO_ABORTIFHUNG
        } else {
            set block 2; #SMTO_NORMAL|SMTO_ABORTIFHUNG
        }

        # WM_CLOSE -> 0x10
        if {[catch {SendMessageTimeout $hwin 0x10 0 0 $block $opts(wait)} msg]} {
            # Do no treat timeout as an error
            set erCode $::errorCode
            set erInfo $::errorInfo
            if {[lindex $erCode 0] != "TWAPI_WIN32" ||
                ([lindex $erCode 1] != 0 && [lindex $erCode 1] != 1460)} {
                error $msg $erInfo $erCode
            }
        }
    } else {
        # Implement using PostMessage since that allows closing of
        # Explorer windows

        # Note - opts(block) is ignored here

        # 0x10 -> WM_CLOSE
        PostMessage $hwin 0x10 0 0
        if {$opts(wait)} {
            wait [list ::twapi::window_exists $hwin] 0 $opts(wait)
        }
    }
    return [twapi::window_exists $hwin]
}

# CHeck if window is minimized
proc twapi::window_minimized {hwin} {
    return [IsIconic $hwin]
}

# CHeck if window is maximized
proc twapi::window_maximized {hwin} {
    return [IsZoomed $hwin]
}

# Check if window is visible
proc twapi::window_visible {hwin} {
    return [IsWindowVisible $hwin]
}

# Check if a window exists
proc twapi::window_exists {hwin} {
    return [IsWindow $hwin]
}

# CHeck if window input is enabled
proc twapi::window_unicode_enabled {hwin} {
    return [IsWindowUnicode $hwin]
}

# Check if child is a child of parent
proc twapi::window_is_child {parent child} {
    return [IsChild $parent $child]
}

# Flash the given window
proc twapi::flash_window_caption {hwin args} {
    array set opts [parseargs args {toggle}]

    return [FlashWindow $hwin $opts(toggle)]
}

# FlashWindow not in binary any more, emulate it
proc twapi::FlashWindow {hwin toggle} {
    FlashWindowEx [list $hwin 1 $toggle 0]
}

# Flash the given window and/or the taskbar icon
proc twapi::flash_window {hwin args} {
    array set opts [parseargs args {
        period.int
        count.int
        nocaption
        notaskbar
        start
        stop
        untilforeground
    } -maxleftover 0 -nulldefault]

    set flags 0

    if {! $opts(stop)} {
        # Flash title bar?
        if {! $opts(nocaption)} {
            incr flags 1;           # FLASHW_CAPTION
        }

        # Flash taskbar icon ?
        if {! $opts(notaskbar)} {
            incr flags 2;           # FLASHW_TRAY
        }

        # Continuous modes ?
        if {$opts(untilforeground)} {
            # Continuous until foreground window
            # NOTE : FLASHW_TIMERNOFG is no implemented because it seems to be
            # broken - it only flashes once, at least on Windows XP. Keep
            # it in case other platforms work correctly.
            incr flags 0xc;         # FLASHW_TIMERNOFG
        } elseif {$opts(start)} {
            # Continuous until stopped
            incr flags 4;           # FLASHW_TIMER
        } elseif {$opts(count) == 0} {
            set opts(count) 1
        }
    }

    return [FlashWindowEx [list $hwin $flags $opts(count) $opts(period)]]
}


# Show/hide window caption buttons. hwin must be a toplevel
proc twapi::configure_window_titlebar {hwin args} {

    array set opts [parseargs args {
        visible.bool
        sysmenu.bool
        minimizebox.bool
        maximizebox.bool
        contexthelp.bool
    } -maxleftover 0]

    # Get the current style setting
    lassign [get_window_style $hwin] style exstyle

    # See if each option is specified. Else use current setting
    # 0x00080000 -> WS_SYSMENU
    # 0x00020000 -> WS_MINIMIZEBOX
    # 0x00010000 -> WS_MAXIMIZEBOX
    # 0x00C00000 -> WS_CAPTION
    foreach {opt def} {
        sysmenu     0x00080000
        minimizebox 0x00020000
        maximizebox 0x00010000
        visible     0x00C00000
    } {
        if {[info exists opts($opt)]} {
            set $opt [expr {$opts($opt) ? $def : 0}]
        } else {
            set $opt [expr {$style & $def}]
        }
    }

    # Ditto for extended style and context help
    if {[info exists opts(contexthelp)]} {
        # WS_EX_CONTEXTHELP -> 0x00000400
        set contexthelp [expr {$opts(contexthelp) ? 0x00000400 : 0}]
    } else {
        set contexthelp [expr {$exstyle & 0x00000400}]
    }

    # The min/max/help buttons all depend on sysmenu being set.
    if {($minimizebox || $maximizebox || $contexthelp) && ! $sysmenu} {
        # Don't bother raising error, since the underlying API allows it
        #error "Cannot enable minimize, maximize and context help buttons unless system menu is present"
    }

    # Reset existing sysmenu,minimizebox,maximizebox,caption
    set style [expr {$style & 0xff34ffff}]
    ; # Add back new settings
    set style [expr {$style | $sysmenu | $minimizebox | $maximizebox | $visible}]

    # Reset contexthelp and add new setting back
    set exstyle [expr {$exstyle & 0xfffffbff}]
    set exstyle [expr {$exstyle | $contexthelp}]

    set_window_style $hwin $style $exstyle
}

# Arrange window icons
proc twapi::arrange_icons {{hwin ""}} {
    if {$hwin == ""} {
        set hwin [get_desktop_window]
    }
    ArrangeIconicWindows $hwin
}

# Get the window text/caption
proc twapi::get_window_text {hwin} {
    # TBD - see http://blogs.msdn.com/oldnewthing/archive/2003/08/21/54675.aspx
    twapi::GetWindowText $hwin
}

# Set the window text/caption
proc twapi::set_window_text {hwin text} {
    twapi::SetWindowText $hwin $text
}

# Get size of client area
proc twapi::get_window_client_area_size {hwin} {
    return [lrange [GetClientRect $hwin] 2 3]
}

# Get window coordinates
proc twapi::get_window_coordinates {hwin} {
    return [GetWindowRect $hwin]
}

# Get the window under the point
proc twapi::get_window_at_location {x y} {
    return [WindowFromPoint [list $x $y]]
}

# Marks a screen region as invalid forcing a redraw
proc twapi::invalidate_screen_region {args} {
    array set opts [parseargs args {
        {hwin.arg 0}
        rect.arg
        bgerase
    } -nulldefault -maxleftover 0]

    InvalidateRect $opts(hwin) $opts(rect) $opts(bgerase)
}

# Get the caret blink time
proc twapi::get_caret_blink_time {} {
    return [GetCaretBlinkTime]
}

# Set the caret blink time
proc twapi::set_caret_blink_time {ms} {
    return [SetCaretBlinkTime $ms]
}

# Hide the caret
proc twapi::hide_caret {} {
    HideCaret 0
}

# Show the caret
proc twapi::show_caret {} {
    ShowCaret 0
}

# Get the caret position
proc twapi::get_caret_location {} {
    return [GetCaretPos]
}

# Get the caret position
proc twapi::set_caret_location {point} {
    return [SetCaretPos [lindex $point 0] [lindex $point 1]]
}


# Get display size
proc twapi::get_display_size {} {
    return [lrange [get_window_coordinates [get_desktop_window]] 2 3]
}


# Get path to the desktop wallpaper
interp alias {} twapi::get_desktop_wallpaper {} twapi::get_system_parameters_info SPI_GETDESKWALLPAPER


# Set desktop wallpaper
proc twapi::set_desktop_wallpaper {path args} {

    array set opts [parseargs args {
        persist
    }]

    if {$opts(persist)} {
        set flags 3;                    # Notify all windows + persist
    } else {
        set flags 2;                    # Notify all windows
    }

    if {$path == "default"} {
        SystemParametersInfo 0x14 0 NULL 0
        return
    }

    if {$path == "none"} {
        set path ""
    }

    set mem_size [expr {2 * ([string length $path] + 1)}]
    set mem [malloc $mem_size]
    trap {
        twapi::Twapi_WriteMemory 3 $mem 0 $mem_size $path
        SystemParametersInfo 0x14 0 $mem $flags
    } finally {
        free $mem
    }
}

# Get desktop work area
interp alias {} twapi::get_desktop_workarea {} twapi::get_system_parameters_info SPI_GETWORKAREA



# Get the color depth of the display
proc twapi::get_color_depth {{hwin 0}} {
    set h [GetDC $hwin]
    trap {
        return [GetDeviceCaps $h 12]
    } finally {
        ReleaseDC $hwin $h
    }
}


# Enumerate the display adapters in a system
proc twapi::get_display_devices {} {
    set devs [list ]
    for {set i 0} {true} {incr i} {
        trap {
            set dev [EnumDisplayDevices "" $i 0]
        } onerror {TWAPI_WIN32} {
            # We don't check for a specific error since experimentation
            # shows the error code returned at the end of enumeration
            # is not fixed - can be 2, 18, 87 and maybe others
            break
        }
        lappend devs [_format_display_device $dev]
    }

    return $devs
}

# Enumerate the display monitors for an display device
proc twapi::get_display_monitors {args} {
    array set opts [parseargs args {
        device.arg
        activeonly
    } -maxleftover 0]

    if {[info exists opts(device)]} {
        set devs [list $opts(device)]
    } else {
        set devs [list ]
        foreach dev [get_display_devices] {
            lappend devs [kl_get $dev -name]
        }
    }

    set monitors [list ]
    foreach dev $devs {
        for {set i 0} {true} {incr i} {
            trap {
                set monitor [EnumDisplayDevices $dev $i 0]
            } onerror {} {
                # We don't check for a specific error since experimentation
                # shows the error code returned at the end of enumeration
                # is not fixed - can be 2, 18, 87 and maybe others
                break
            }
            if {(! $opts(activeonly)) ||
                ([lindex $monitor 2] & 1)} {
                lappend monitors [_format_display_monitor $monitor]
            }
        }
    }

    return $monitors
}

# Return the monitor corresponding to a window
proc twapi::get_display_monitor_from_window {hwin args} {
    array set opts [parseargs args {
        default.arg
    } -maxleftover 0]

    # hwin may be a window id or a Tk window. On error we assume it is
    # a window id
    catch {
        set hwin [pointer_from_address [winfo id $hwin] HWND]
    }

    set flags 0
    if {[info exists opts(default)]} {
        switch -exact -- $opts(default) {
            primary { set flags 1 }
            nearest { set flags 2 }
            default { error "Invalid value '$opts(default)' for -default option" }
        }
    }

    trap {
        return [MonitorFromWindow $hwin $flags]
    } onerror {TWAPI_WIN32 0} {
        win32_error 1461 "Window does not map to a monitor."
    }
}

# Return the monitor corresponding to a screen cocordinates
proc twapi::get_display_monitor_from_point {x y args} {
    array set opts [parseargs args {
        default.arg
    } -maxleftover 0]

    set flags 0
    if {[info exists opts(default)]} {
        switch -exact -- $opts(default) {
            primary { set flags 1 }
            nearest { set flags 2 }
            default { error "Invalid value '$opts(default)' for -default option" }
        }
    }

    trap {
        return [MonitorFromPoint [list $x $y] $flags]
    } onerror {TWAPI_WIN32 0} {
        win32_error 1461 "Virtual screen coordinates ($x,$y) do not map to a monitor."
    }
}


# Return the monitor corresponding to a screen rectangle
proc twapi::get_display_monitor_from_rect {rect args} {
    array set opts [parseargs args {
        default.arg
    } -maxleftover 0]

    set flags 0
    if {[info exists opts(default)]} {
        switch -exact -- $opts(default) {
            primary { set flags 1 }
            nearest { set flags 2 }
            default { error "Invalid value '$opts(default)' for -default option" }
        }
    }

    trap {
        return [MonitorFromRect $rect $flags]
    } onerror {TWAPI_WIN32 0} {
        win32_error 1461 "Virtual screen rectangle <[join $rect ,]> does not map to a monitor."
    }
}

proc twapi::get_display_monitor_info {hmon} {
    return [_format_monitor_info [GetMonitorInfo $hmon]]
}

proc twapi::get_multiple_display_monitor_info {} {
    set result [list ]
    foreach elem [EnumDisplayMonitors NULL ""] {
        lappend result [get_display_monitor_info [lindex $elem 0]]
    }
    return $result
}


proc twapi::tkpath_to_hwnd {tkpath} {
    return [cast_handle [winfo id $tkpath] HWND]
}

################################################################
# Utility routines

# Helper function to wrap GetGUIThreadInfo
# Returns the value of the given fields. If a single field is requested,
# returns it as a scalar else returns a flat list of FIELD VALUE pairs
proc twapi::_get_gui_thread_info {tid args} {
    array set gtinfo [GetGUIThreadInfo $tid]
    set result [list ]
    foreach field $args {
        set value $gtinfo($field)
        switch -exact -- $field {
            cbSize { }
            rcCaret {
                set value [list $value(left) \
                               $value(top) \
                               $value(right) \
                               $value(bottom)]
            }
        }
        lappend result $value
    }

    if {[llength $args] == 1} {
        return [lindex $result 0]
    } else {
        return $result
    }
}


# if $hwin corresponds to a null window handle, returns an empty string
proc twapi::_return_window {hwin} {
    if {[pointer_null? $hwin HWND]} {
        return $twapi::null_hwin
    }
    return $hwin
}

# Return 1 if same window
proc twapi::_same_window {hwin1 hwin2} {
    # If either is a empty/null handle, no match, even if both empty/null
    if {[string length $hwin1] == 0 || [string length $hwin2] == 0} {
        return 0
    }
    if {[pointer_null? $hwin1] || [pointer_null? $hwin2]} {
        return 0
    }

    # Need integer compare
    return [pointer_equal? $hwin1 $hwin2]
}

# Helper function for showing/hiding windows
proc twapi::_show_window {hwin cmd {wait 0}} {
    # If either our thread owns the window or we want to wait for it to
    # process the command, use the synchrnous form of the function
    if {$wait || ([get_window_thread $hwin] == [GetCurrentThreadId])} {
        ShowWindow $hwin $cmd
    } else {
        ShowWindowAsync $hwin $cmd
    }
}



# Map style bits to a style symbol list
proc twapi::_style_mask_to_symbols {style exstyle} {
    set attrs [list ]
    if {$style & 0x80000000} {
        lappend attrs popup
        if {$style & 0x00020000} { lappend attrs group }
        if {$style & 0x00010000} { lappend attrs tabstop }
    } else {
        if {$style & 0x40000000} {
            lappend attrs child
        } else {
            lappend attrs overlapped
        }
        if {$style & 0x00020000} { lappend attrs minimizebox }
        if {$style & 0x00010000} { lappend attrs maximizebox }
    }

    # Note WS_BORDER, WS_DLGFRAME and WS_CAPTION use same bits
    if {$style & 0x00C00000} {
        lappend attrs caption
    } else {
        if {$style & 0x00800000} { lappend attrs border }
        if {$style & 0x00400000} { lappend attrs dlgframe }
    }

    foreach {sym mask} {
        minimize 0x20000000
        visible 0x10000000
        disabled 0x08000000
        clipsiblings 0x04000000
        clipchildren 0x02000000
        maximize 0x01000000
        vscroll 0x00200000
        hscroll 0x00100000
        sysmenu 0x00080000
        thickframe 0x00040000
    } {
        if {$style & $mask} {
            lappend attrs $sym
        }
    }

    if {$exstyle & 0x00001000} {
        lappend attrs right
    } else {
        lappend attrs left
    }
    if {$exstyle & 0x00002000} {
        lappend attrs rtlreading
    } else {
        lappend attrs ltrreading
    }
    if {$exstyle & 0x00004000} {
        lappend attrs leftscrollbar
    } else {
        lappend attrs rightscrollbar
    }

    foreach {sym mask} {
        dlgmodalframe 0x00000001
        noparentnotify 0x00000004
        topmost 0x00000008
        acceptfiles 0x00000010
        transparent 0x00000020
        mdichild 0x00000040
        toolwindow 0x00000080
        windowedge 0x00000100
        clientedge 0x00000200
        contexthelp 0x00000400
        controlparent 0x00010000
        staticedge 0x00020000
        appwindow 0x00040000
    } {
        if {$exstyle & $mask} {
            lappend attrs $sym
        }
    }

    return $attrs
}


# Test proc for displaying all colors for a class
proc twapi::_show_theme_colors {class part {state ""}} {
    set w [toplevel .themetest$class$part$state]

    set h [OpenThemeData [tkpath_to_hwnd $w] $class]
    wm title $w "$class Colors"

    label $w.title -text "$class, $part, $state" -bg white
    grid $w.title -

    if {![string is integer -strict $part]} {
        set part [TwapiGetThemeDefine $part]
    }

    if {![string is integer -strict $state]} {
        set state [TwapiGetThemeDefine $state]
    }

    foreach x {BORDERCOLOR FILLCOLOR TEXTCOLOR EDGELIGHTCOLOR EDGESHADOWCOLOR EDGEFILLCOLOR TRANSPARENTCOLOR GRADIENTCOLOR1 GRADIENTCOLOR2 GRADIENTCOLOR3 GRADIENTCOLOR4 GRADIENTCOLOR5 SHADOWCOLOR GLOWCOLOR TEXTBORDERCOLOR TEXTSHADOWCOLOR GLYPHTEXTCOLOR FILLCOLORHINT BORDERCOLORHINT ACCENTCOLORHINT BLENDCOLOR} {
        set prop [TwapiGetThemeDefine TMT_$x]
        if {![catch {GetThemeColor $h $part $state $prop} color]} {
            label $w.l-$x -text $x
            label $w.c-$x -text $color -bg $color
            grid $w.l-$x $w.c-$x
        } else {
            label $w.l-$x -text $x
            label $w.c-$x -text "Not defined"
            grid $w.l-$x $w.c-$x
        }
    }
    CloseThemeData $h
}

# Test proc for displaying all sys colors for a class
# class might be "WINDOW"
proc twapi::_show_theme_syscolors {class} {
    destroy .themetest$class
    set w [toplevel .themetest$class]

    set h [OpenThemeData [tkpath_to_hwnd $w] $class]
    wm title $w "$class SysColors"

    label $w.title -text "$class" -bg white
    grid $w.title -


    for {set x 0} {$x <= 30} {incr x} {
        if {![catch {GetThemeSysColor $h $x} color]} {
            set color #[format %6.6x $color]
            label $w.l-$x -text $x
            label $w.c-$x -text $color -bg $color
            grid $w.l-$x $w.c-$x
        } else {
            label $w.l-$x -text $x
            label $w.c-$x -text "Not defined"
            grid $w.l-$x $w.c-$x
        }
    }
    CloseThemeData $h
}

# Test proc for displaying all fonts for a class
proc twapi::_show_theme_fonts {class part {state ""}} {
    set w [toplevel .themetest$class$part$state]

    set h [OpenThemeData [tkpath_to_hwnd $w] $class]
    wm title $w "$class fonts"

    label $w.title -text "$class, $part, $state" -bg white
    grid $w.title -

    set part [TwapiGetThemeDefine $part]
    set state [TwapiGetThemeDefine $state]

    foreach x {GLYPHTYPE FONT} {
        set prop [TwapiGetThemeDefine TMT_$x]
        if {![catch {GetThemeFont $h NULL $part $state $prop} font]} {
            label $w.l-$x -text $x
            label $w.c-$x -text $font
            grid $w.l-$x $w.c-$x
        }
    }
    CloseThemeData $h
}



# Formats a display device as returned by C into a keyed list
proc twapi::_format_display_device {dev} {

    # Field names - SAME ORDER AS IN $dev!!
    set fields {-name -description -flags -id -key}

    set flags [lindex $dev 2]
    foreach {opt flag} {
        desktop         0x00000001
        multidriver     0x00000002
        primary         0x00000004
        mirroring       0x00000008
        vgacompatible   0x00000010
        removable       0x00000020
        modespruned         0x08000000
        remote              0x04000000
        disconnect          0x02000000
    } {
        lappend fields -$opt
        lappend dev [expr { $flags & $flag ? true : false }]
    }

    return [kl_create2 $fields $dev]
}

# Formats a display monitor as returned by C into a keyed list
proc twapi::_format_display_monitor {dev} {

    # Field names - SAME ORDER AS IN $dev!!
    set fields {-name -description -flags -id -key}

    set flags [lindex $dev 2]
    foreach {opt flag} {
        active         0x00000001
        attached       0x00000002
    } {
        lappend fields -$opt
        lappend dev [expr { $flags & $flag ? true : false }]
    }

    return [kl_create2 $fields $dev]
}

# Format a monitor info struct
proc twapi::_format_monitor_info {hmon} {
    return [kl_create2 {-extent -workarea -primary -name} $hmon]
}

# Get message-only windows
proc twapi::_get_message_only_windows {} {

    set wins [list ]
    set prev 0
    # -3 -> HWND_MESSAGE windows

    while true {
        set win [FindWindowEx [list -3 HWND] $prev "" ""]
        if {[pointer_null? $win]} break
        lappend wins $win
        set prev $win
    }

    return $wins
}

