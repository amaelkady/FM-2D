#
# Copyright (c) 2012 Ashok P. Nadkarni
# All rights reserved.
#
# See the file LICENSE for license

# Generate sound for the specified duration
proc twapi::beep {args} {
    array set opts [parseargs args {
        {frequency.int 1000}
        {duration.int 100}
        {type.arg}
    }]

    if {[info exists opts(type)]} {
        switch -exact -- $opts(type) {
            ok           {MessageBeep 0}
            hand         {MessageBeep 0x10}
            question     {MessageBeep 0x20}
            exclaimation {MessageBeep 0x30}
            exclamation {MessageBeep 0x30}
            asterisk     {MessageBeep 0x40}
            default      {error "Unknown sound type '$opts(type)'"}
        }
        return
    }
    Beep $opts(frequency) $opts(duration)
    return
}

# Play the specified sound
proc twapi::play_sound {name args} {
    array set opts [parseargs args {
        alias
        async
        loop
        nodefault
        wait
        nostop
    }]

    if {$opts(alias)} {
        set flags 0x00010000; #SND_ALIAS
    } else {
        set flags 0x00020000; #SND_FILENAME
    }
    if {$opts(loop)} {
        # Note LOOP requires ASYNC
        setbits flags 0x9; #SND_LOOP | SND_ASYNC
    } else {
        if {$opts(async)} {
            setbits flags 0x0001; #SND_ASYNC
        } else {
            setbits flags 0x0000; #SND_SYNC
        }
    }

    if {$opts(nodefault)} {
        setbits flags 0x0002; #SND_NODEFAULT
    }

    if {! $opts(wait)} {
        setbits flags 0x00002000; #SND_NOWAIT
    }

    if {$opts(nostop)} {
        setbits flags 0x0010; #SND_NOSTOP
    }

    return [PlaySound $name 0 $flags]
}

proc twapi::stop_sound {} {
    PlaySound "" 0 0x0040; #SND_PURGE
}
