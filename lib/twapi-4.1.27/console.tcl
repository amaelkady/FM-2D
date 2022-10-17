#
# Copyright (c) 2004-2014, Ashok P. Nadkarni
# All rights reserved.
#
# See the file LICENSE for license

namespace eval twapi {
}

# Allocate a new console
proc twapi::allocate_console {} {
    AllocConsole
}

# Free a console
proc twapi::free_console {} {
    FreeConsole
}

# Get a console handle
proc twapi::get_console_handle {type} {
    switch -exact -- $type {
        0 -
        stdin { set fn "CONIN\$" }
        1 -
        stdout -
        2 -
        stderr { set fn "CONOUT\$" }
        default {
            error "Unknown console handle type '$type'"
        }
    }

    # 0xC0000000 -> GENERIC_READ | GENERIC_WRITE
    # 3 -> FILE_SHARE_READ | FILE_SHARE_WRITE
    # 3 -> OPEN_EXISTING
    return [CreateFile $fn \
                0xC0000000 \
                3 \
                {{} 1} \
                3 \
                0 \
                NULL]
}

# Get a console handle
proc twapi::get_standard_handle {type} {
    switch -exact -- $type {
        0 -
        -11 -
        stdin { set type -11 }
        1 -
        -12 -
        stdout { set type -12 }
        2 -
        -13 -
        stderr { set type -13 }
        default {
            error "Unknown console handle type '$type'"
        }
    }
    return [GetStdHandle $type]
}

# Set a console handle
proc twapi::set_standard_handle {type handle} {
    switch -exact -- $type {
        0 -
        -11 -
        stdin { set type -11 }
        1 -
        -12 -
        stdout { set type -12 }
        2 -
        -13 -
        stderr { set type -13 }
        default {
            error "Unknown console handle type '$type'"
        }
    }
    return [SetStdHandle $type $handle]
}

proc twapi::_console_output_attr_to_flags {attrs} {
    set flags 0
    foreach {attr bool} $attrs {
        if {$bool} {
            set flags [expr {$flags | [_console_output_attr $attr]}]
        }
    }
    return $flags
}

proc twapi::_flags_to_console_output_attr {flags} {
    # Check for multiple bit attributes first, in order
    set attrs {}
    foreach attr {
        -fgwhite -bgwhite -fggray -bggray
        -fgturquoise -bgturquoise -fgpurple -bgpurple -fgyellow -bgyellow
        -fgred -bgred -fggreen -bggreen -fgblue -bgblue
        -fgbright -bgbright
    } {
        if {($flags & [_console_output_attr $attr]) == [_console_output_attr $attr]} {
            lappend attrs $attr 1
            set flags [expr {$flags & ~ [_console_output_attr $attr]}]
            if {$flags == 0} {
                break
            }
        }
    }
        
    return $attrs
}


# Get the current mode settings for the console
proc twapi::_get_console_input_mode {conh} {
    set mode [GetConsoleMode $conh]
    return [_bitmask_to_switches $mode [_console_input_mode_syms]]
}
interp alias {} twapi::get_console_input_mode {} twapi::_do_console_proc twapi::_get_console_input_mode stdin

# Get the current mode settings for the console
proc twapi::_get_console_output_mode {conh} {
    set mode [GetConsoleMode $conh]
    return [_bitmask_to_switches $mode [_console_output_mode_syms]]
}
interp alias {} twapi::get_console_output_mode {} twapi::_do_console_proc twapi::_get_console_output_mode stdout

# Set console input mode
proc twapi::_set_console_input_mode {conh args} {
    set mode [_switches_to_bitmask $args [_console_input_mode_syms]]
    # If insertmode or quickedit mode are set, make sure to set extended bit
    if {$mode & 0x60} {
        setbits mode 0x80;              # ENABLE_EXTENDED_FLAGS
    }

    SetConsoleMode $conh $mode
}
interp alias {} twapi::set_console_input_mode {} twapi::_do_console_proc twapi::_set_console_input_mode stdin

# Modify console input mode
proc twapi::_modify_console_input_mode {conh args} {
    set prev [GetConsoleMode $conh]
    set mode [_switches_to_bitmask $args [_console_input_mode_syms] $prev]
    # If insertmode or quickedit mode are set, make sure to set extended bit
    if {$mode & 0x60} {
        setbits mode 0x80;              # ENABLE_EXTENDED_FLAGS
    }

    SetConsoleMode $conh $mode
    # Returns the old modes
    return [_bitmask_to_switches $prev [_console_input_mode_syms]]
}
interp alias {} twapi::modify_console_input_mode {} twapi::_do_console_proc twapi::_modify_console_input_mode stdin

#
# Set console output mode
proc twapi::_set_console_output_mode {conh args} {
    set mode [_switches_to_bitmask $args [_console_output_mode_syms]]

    SetConsoleMode $conh $mode

}
interp alias {} twapi::set_console_output_mode {} twapi::_do_console_proc twapi::_set_console_output_mode stdout

# Set console output mode
proc twapi::_modify_console_output_mode {conh args} {
    set prev [GetConsoleMode $conh]
    set mode [_switches_to_bitmask $args [_console_output_mode_syms] $prev]

    SetConsoleMode $conh $mode
    # Returns the old modes
    return [_bitmask_to_switches $prev [_console_output_mode_syms]]
}
interp alias {} twapi::modify_console_output_mode {} twapi::_do_console_proc twapi::_modify_console_output_mode stdout


# Create and return a handle to a screen buffer
proc twapi::create_console_screen_buffer {args} {
    array set opts [parseargs args {
        {inherit.bool 0}
        {mode.arg readwrite {read write readwrite}}
        {secd.arg ""}
        {share.arg readwrite {none read write readwrite}}
    } -maxleftover 0]

    switch -exact -- $opts(mode) {
        read       { set mode [_access_rights_to_mask generic_read] }
        write      { set mode [_access_rights_to_mask generic_write] }
        readwrite  {
            set mode [_access_rights_to_mask {generic_read generic_write}]
        }
    }
    switch -exact -- $opts(share) {
        none {
            set share 0
        }
        read       {
            set share 1 ;# FILE_SHARE_READ
        }
        write      {
            set share 2 ;# FILE_SHARE_WRITE
        }
        readwrite  {
            set share 3
        }
    }
    
    return [CreateConsoleScreenBuffer \
                $mode \
                $share \
                [_make_secattr $opts(secd) $opts(inherit)] \
                1]
}

# Retrieve information about a console screen buffer
proc twapi::_get_console_screen_buffer_info {conh args} {
    array set opts [parseargs args {
        all
        textattr
        cursorpos
        maxwindowsize
        size
        windowlocation
        windowpos
        windowsize
    } -maxleftover 0]

    lassign [GetConsoleScreenBufferInfo $conh] size cursorpos textattr windowlocation maxwindowsize

    set result [list ]
    foreach opt {size cursorpos maxwindowsize windowlocation} {
        if {$opts($opt) || $opts(all)} {
            lappend result -$opt [set $opt]
        }
    }

    if {$opts(windowpos) || $opts(all)} {
        lappend result -windowpos [lrange $windowlocation 0 1]
    }

    if {$opts(windowsize) || $opts(all)} {
        lassign $windowlocation left top right bot
        lappend result -windowsize [list [expr {$right-$left+1}] [expr {$bot-$top+1}]]
    }

    if {$opts(textattr) || $opts(all)} {
        lappend result -textattr [_flags_to_console_output_attr $textattr]
    }

    return $result
}
interp alias {} twapi::get_console_screen_buffer_info {} twapi::_do_console_proc twapi::_get_console_screen_buffer_info stdout

# Set the cursor position
proc twapi::_set_console_cursor_position {conh pos} {
    SetConsoleCursorPosition $conh $pos
}
interp alias {} twapi::set_console_cursor_position {} twapi::_do_console_proc twapi::_set_console_cursor_position stdout

# Get the cursor position
proc twapi::get_console_cursor_position {conh} {
    return [lindex [get_console_screen_buffer_info $conh -cursorpos] 1]
}

# Write the specified string to the console
proc twapi::_console_write {conh s args} {
    # Note writes are always in raw mode, 
    # TBD - support for  scrolling
    # TBD - support for attributes

    array set opts [parseargs args {
        position.arg
        {newlinemode.arg column {line column}}
        {restoreposition.bool 0}
    } -maxleftover 0]

    # Get screen buffer info including cursor position
    array set csbi [get_console_screen_buffer_info $conh -cursorpos -size]

    # Get current console mode for later restoration
    # If console is in processed mode, set it to raw mode
    set oldmode [get_console_output_mode $conh]
    set processed_index [lsearch -exact $oldmode "processed"]
    if {$processed_index >= 0} {
        # Console was in processed mode. Set it to raw mode
        set newmode [lreplace $oldmode $processed_index $processed_index]
        set_console_output_mode $conh $newmode
    }
    
    trap {
        # x,y are starting position to write
        if {[info exists opts(position)]} {
            lassign [_parse_integer_pair $opts(position)] x y
        } else {
            # No position specified, get current cursor position
            lassign $csbi(-cursorpos) x y
        }
        
        set startx [expr {$opts(newlinemode) == "column" ? $x : 0}]

        # Get screen buffer limits
        lassign  $csbi(-size)  width height

        # Ensure line terminations are just \n
        set s [string map [list \r\n \n] $s]

        # Write out each line at ($x,$y)
        # Either \r or \n is considered a newline
        foreach line [split $s \r\n] {
            if {$y >= $height} break
            set_console_cursor_position $conh [list $x $y]
            if {$x < $width} {
                # Write the characters - do not write more than buffer width
                set num_chars [expr {$width-$x}]
                if {[string length $line] < $num_chars} {
                    set num_chars [string length $line]
                }
                WriteConsole $conh $line $num_chars
            }
            
            
            # Calculate starting position of next line
            incr y
            set x $startx
        }

    } finally {
        # Restore cursor if requested
        if {$opts(restoreposition)} {
            set_console_cursor_position $conh $csbi(-cursorpos)
        }
        # Restore output mode if changed
        if {[info exists newmode]} {
            set_console_output_mode $conh $oldmode
        }
    }

    return
}
interp alias {} twapi::write_console {} twapi::_do_console_proc twapi::_console_write stdout
interp alias {} twapi::console_write {} twapi::_do_console_proc twapi::_console_write stdout

# Fill an area of the console with the specified attribute
proc twapi::_fill_console {conh args} {
    array set opts [parseargs args {
        position.arg
        numlines.int
        numcols.int
        {mode.arg column {line column}}
        window.bool
        fillchar.arg
    } -ignoreunknown]

    # args will now contain attribute switches if any
    set attr [_console_output_attr_to_flags $args]

    # Get screen buffer info for window and size of buffer
    array set csbi [get_console_screen_buffer_info $conh -windowpos -windowsize -size]
    # Height and width of the console
    lassign $csbi(-size) conx cony

    # Figure out what area we want to fill
    # startx,starty are starting position to write
    # sizex, sizey are the number of rows/lines
    if {[info exists opts(window)]} {
        if {[info exists opts(numlines)] || [info exists opts(numcols)]
            || [info exists opts(position)]} {
            error "Option -window cannot be used togther with options -position, -numlines or -numcols"
        }
        lassign  [_parse_integer_pair $csbi(-windowpos)] startx starty
        lassign  [_parse_integer_pair $csbi(-windowsize)] sizex sizey
    } else {
        if {[info exists opts(position)]} {
            lassign [_parse_integer_pair $opts(position)] startx starty
        } else {
            set startx 0
            set starty 0
        }
        if {[info exists opts(numlines)]} {
            set sizey $opts(numlines)
        } else {
            set sizey $cony
        }
        if {[info exists opts(numcols)]} {
            set sizex $opts(numcols)
        } else {
            set sizex [expr {$conx - $startx}]
        }
    }
    
    set firstcol [expr {$opts(mode) == "column" ? $startx : 0}]

    # Fill attribute at ($x,$y)
    set x $startx
    set y $starty
    while {$y < $cony && $y < ($starty + $sizey)} {
        if {$x < $conx} {
            # Write the characters - do not write more than buffer width
            set max [expr {$conx-$x}]
            if {[info exists attr]} {
                FillConsoleOutputAttribute $conh $attr [expr {$sizex > $max ? $max : $sizex}] [list $x $y]
            }
            if {[info exists opts(fillchar)]} {
                FillConsoleOutputCharacter $conh $opts(fillchar) [expr {$sizex > $max ? $max : $sizex}] [list $x $y]
            }
        }
        
        # Calculate starting position of next line
        incr y
        set x $firstcol
    }
    
    return
}
interp alias {} twapi::fill_console {} twapi::_do_console_proc twapi::_fill_console stdout

# Clear the console
proc twapi::_clear_console {conh args} {
    # I support we could just call fill_console but this code was already
    # written and is faster
    array set opts [parseargs args {
        {fillchar.arg " "}
        {windowonly.bool 0}
    } -maxleftover 0]

    array set cinfo [get_console_screen_buffer_info $conh -size -windowpos -windowsize]
    lassign  $cinfo(-size) width height
    if {$opts(windowonly)} {
        # Only clear portion visible in the window. We have to do this
        # line by line since we do not want to erase text scrolled off
        # the window either in the vertical or horizontal direction
        lassign $cinfo(-windowpos) x y
        lassign $cinfo(-windowsize) w h
        for {set i 0} {$i < $h} {incr i} {
            FillConsoleOutputCharacter \
                $conh \
                $opts(fillchar)  \
                $w \
                [list $x [expr {$y+$i}]]
        }
    } else {
        FillConsoleOutputCharacter \
            $conh \
            $opts(fillchar)  \
            [expr {($width*$height) }] \
            [list 0 0]
    }
    return
}
interp alias {} twapi::clear_console {} twapi::_do_console_proc twapi::_clear_console stdout
#
# Flush console input
proc twapi::_flush_console_input {conh} {
    FlushConsoleInputBuffer $conh
}
interp alias {} twapi::flush_console_input {} twapi::_do_console_proc twapi::_flush_console_input stdin

# Return number of pending console input events
proc twapi::_get_console_pending_input_count {conh} {
    return [GetNumberOfConsoleInputEvents $conh]
}
interp alias {} twapi::get_console_pending_input_count {} twapi::_do_console_proc twapi::_get_console_pending_input_count stdin

# Generate a console control event
proc twapi::generate_console_control_event {event {procgrp 0}} {
    switch -exact -- $event {
        ctrl-c {set event 0}
        ctrl-break {set event 1}
        default {error "Invalid event definition '$event'"}
    }
    GenerateConsoleCtrlEvent $event $procgrp
}

# Get number of mouse buttons
proc twapi::num_console_mouse_buttons {} {
    return [GetNumberOfConsoleMouseButtons]
}

# Get console title text
proc twapi::get_console_title {} {
    return [GetConsoleTitle]
}

# Set console title text
proc twapi::set_console_title {title} {
    return [SetConsoleTitle $title]
}

# Get the handle to the console window
proc twapi::get_console_window {} {
    return [GetConsoleWindow]
}

# Get the largest console window size
proc twapi::_get_console_window_maxsize {conh} {
    return [GetLargestConsoleWindowSize $conh]
}
interp alias {} twapi::get_console_window_maxsize {} twapi::_do_console_proc twapi::_get_console_window_maxsize stdout

proc twapi::_set_console_active_screen_buffer {conh} {
    SetConsoleActiveScreenBuffer $conh
}
interp alias {} twapi::set_console_active_screen_buffer {} twapi::_do_console_proc twapi::_set_console_active_screen_buffer stdout

# Set the size of the console screen buffer
proc twapi::_set_console_screen_buffer_size {conh size} {
    SetConsoleScreenBufferSize $conh [_parse_integer_pair $size]
}
interp alias {} twapi::set_console_screen_buffer_size {} twapi::_do_console_proc twapi::_set_console_screen_buffer_size stdout

# Set the default text attribute
proc twapi::_set_console_default_attr {conh args} {
    SetConsoleTextAttribute $conh [_console_output_attr_to_flags $args]
}
interp alias {} twapi::set_console_default_attr {} twapi::_do_console_proc twapi::_set_console_default_attr stdout

# Set the console window position
proc twapi::_set_console_window_location {conh rect args} {
    array set opts [parseargs args {
        {absolute.bool true}
    } -maxleftover 0]

    SetConsoleWindowInfo $conh $opts(absolute) $rect
}
interp alias {} twapi::set_console_window_location {} twapi::_do_console_proc twapi::_set_console_window_location stdout

proc twapi::get_console_window_location {conh} {
    return [lindex [get_console_screen_buffer_info $conh -windowlocation] 1]
}

# Get the console code page
proc twapi::get_console_output_codepage {} {
    return [GetConsoleOutputCP]
}

# Set the console code page
proc twapi::set_console_output_codepage {cp} {
    SetConsoleOutputCP $cp
}

# Get the console input code page
proc twapi::get_console_input_codepage {} {
    return [GetConsoleCP]
}

# Set the console input code page
proc twapi::set_console_input_codepage {cp} {
    SetConsoleCP $cp
}

# Read a line of input
proc twapi::_console_read {conh args} {
    if {[llength $args]} {
        set oldmode [modify_console_input_mode $conh {*}$args]
    }
    trap {
        return [ReadConsole $conh 1024]
    } finally {
        if {[info exists oldmode]} {
            set_console_input_mode $conh {*}$oldmode
        }
    }
}
interp alias {} twapi::console_read {} twapi::_do_console_proc twapi::_console_read stdin

proc twapi::_map_console_controlkeys {control} {
    return [_make_symbolic_bitmask $control {
        capslock 0x80
        enhanced 0x100
        leftalt 0x2
        leftctrl 0x8
        numlock 0x20
        rightalt 0x1
        rightctrl 4
        scrolllock 0x40
        shift 0x10
    } 0]
}

proc twapi::_console_read_input_records {conh args} {
    parseargs args {
        {count.int 1}
        peek
    } -setvars -maxleftover 0
    set recs {}
    if {$peek} {
        set input [PeekConsoleInput $conh $count]
    } else {
        set input [ReadConsoleInput $conh $count]
    }
    foreach rec $input {
        switch [format %d [lindex $rec 0]] {
            1 {
                lassign [lindex $rec 1] keydown repeat keycode scancode char controlstate
                lappend recs \
                    [list key [list \
                                   keystate [expr {$keydown ? "down" : "up"}] \
                                   repeat $repeat keycode $keycode \
                                   scancode $scancode char $char \
                                   controls [_map_console_controlkeys $controlstate]]]
            }
            2 {
                lassign [lindex $rec 1] position buttonstate controlstate flags
                set buttons {}
                if {[expr {$buttonstate & 0x1}]} {lappend buttons left}
                if {[expr {$buttonstate & 0x2}]} {lappend buttons right}
                if {[expr {$buttonstate & 0x4}]} {lappend buttons left2}
                if {[expr {$buttonstate & 0x8}]} {lappend buttons left3}
                if {[expr {$buttonstate & 0x10}]} {lappend buttons left4}
                if {$flags & 0x8} {
                    set horizontalwheel [expr {$buttonstate >> 16}]
                } else {
                    set horizontalwheel 0
                }
                if {$flags & 0x4} {
                    set verticalwheel [expr {$buttonstate >> 16}]
                } else {
                    set verticalwheel 0
                }
                lappend recs \
                    [list mouse [list \
                                     position $position \
                                     buttons $buttons \
                                     controls [_map_console_controlkeys $controlstate] \
                                     doubleclick [expr {$flags & 0x2}] \
                                     horizontalwheel $horizontalwheel \
                                     moved [expr {$flags & 0x1}] \
                                     verticalwheel $verticalwheel]]
            }
            default {
                lappend recs [list \
                                  [dict* {4 buffersize 8 menu 16 focus} [lindex $rec 0]] \
                                  [lindex $rec 1]]
            }
        }
    }
    return $recs
}
interp alias {} twapi::console_read_input_records {} twapi::_do_console_proc twapi::_console_read_input_records stdin

# Set up a console handler
proc twapi::_console_ctrl_handler {ctrl} {
    variable _console_control_script
    if {[info exists _console_control_script]} {
        return [uplevel #0 [linsert $_console_control_script end $ctrl]]
    }
    return 0;                   # Not handled
}
proc twapi::set_console_control_handler {script} {
    variable _console_control_script
    if {[string length $script]} {
        if {![info exists _console_control_script]} {
            Twapi_ConsoleEventNotifier 1
        }
        set _console_control_script $script
    } else {
        if {[info exists _console_control_script]} {
            Twapi_ConsoleEventNotifier 0
            unset _console_control_script
        }
    }
}

# 
# Utilities
#

# Helper to call a proc after doing a stdin/stdout/stderr -> handle
# mapping. The handle is closed after calling the proc. The first
# arg in $args must be the console handle if $args is not an empty list
proc twapi::_do_console_proc {proc default args} {
    if {[llength $args] == 0} {
        set args [list $default]
    }
    set conh [lindex $args 0]
    switch -exact -- [string tolower $conh] {
        stdin  -
        stdout -
        stderr {
            set real_handle [get_console_handle $conh]
            trap {
                lset args 0 $real_handle
                return [uplevel 1 [list $proc] $args]
            } finally {
                CloseHandle $real_handle
            }
        }
    }
    
    return [uplevel 1 [list $proc] $args]
}

proc twapi::_console_input_mode_syms {} {
    return {
        -processedinput 0x0001
        -lineinput      0x0002
        -echoinput      0x0004
        -windowinput    0x0008
        -mouseinput     0x0010
        -insertmode     0x0020
        -quickeditmode  0x0040
        -extendedmode   0x0080
        -autoposition   0x0100
    }
}

proc twapi::_console_output_mode_syms {} {
    return { -processedoutput 1 -wrapoutput 2 }
}

twapi::proc* twapi::_console_output_attr {sym} {
    variable _console_output_attr_syms
    array set _console_output_attr_syms {
        -fgblue 1
        -fggreen 2
        -fgturquoise 3
        -fgred 4
        -fgpurple 5
        -fgyellow 6
        -fggray 7
        -fgbright 8
        -fgwhite 15
        -bgblue 16
        -bggreen 32
        -bgturquoise 48
        -bgred 64
        -bgpurple 80
        -bgyellow 96
        -bggray 112
        -bgbright 128
        -bgwhite 240
    }
} {
    variable _console_output_attr_syms
    if {[info exists _console_output_attr_syms($sym)]} {
        return $_console_output_attr_syms($sym)
    }

    badargs! "Invalid console output attribute '$sym'" 3
}

