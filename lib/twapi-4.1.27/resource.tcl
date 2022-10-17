# Commands related to resource manipulation
#
# Copyright (c) 2003-2012 Ashok P. Nadkarni
# All rights reserved.
#
# See the file LICENSE for license

package require twapi_nls

# Retrieve version info for a file
proc twapi::get_file_version_resource {path args} {
    # TBD add -datetime opt to return date and time from fixed version struct
    array set opts [parseargs args {
        all
        datetime
        signature
        structversion
        fileversion
        productversion
        flags
        fileos
        filetype
        foundlangid
        foundcodepage
        langid.arg
        codepage.arg
    }]


    set ver [Twapi_GetFileVersionInfo $path]

    trap {
        array set verinfo [Twapi_VerQueryValue_FIXEDFILEINFO $ver]

        set result [list ]
        if {$opts(all) || $opts(signature)} {
            lappend result -signature [format 0x%x $verinfo(dwSignature)]
        }

        if {$opts(all) || $opts(structversion)} {
            lappend result -structversion "[expr {0xffff & ($verinfo(dwStrucVersion) >> 16)}].[expr {0xffff & $verinfo(dwStrucVersion)}]"
        }

        if {$opts(all) || $opts(fileversion)} {
            lappend result -fileversion "[expr {0xffff & ($verinfo(dwFileVersionMS) >> 16)}].[expr {0xffff & $verinfo(dwFileVersionMS)}].[expr {0xffff & ($verinfo(dwFileVersionLS) >> 16)}].[expr {0xffff & $verinfo(dwFileVersionLS)}]"
        }

        if {$opts(all) || $opts(productversion)} {
            lappend result -productversion "[expr {0xffff & ($verinfo(dwProductVersionMS) >> 16)}].[expr {0xffff & $verinfo(dwProductVersionMS)}].[expr {0xffff & ($verinfo(dwProductVersionLS) >> 16)}].[expr {0xffff & $verinfo(dwProductVersionLS)}]"
        }

        if {$opts(all) || $opts(flags)} {
            set flags [expr {$verinfo(dwFileFlags) & $verinfo(dwFileFlagsMask)}]
            lappend result -flags \
                [_make_symbolic_bitmask \
                     [expr {$verinfo(dwFileFlags) & $verinfo(dwFileFlagsMask)}] \
                     {
                         debug 1
                         prerelease 2
                         patched 4
                         privatebuild 8
                         infoinferred 16
                         specialbuild 32
                     } \
                     ]
        }

        if {$opts(all) || $opts(fileos)} {
            switch -exact -- [format %08x $verinfo(dwFileOS)] {
                00010000 {set os dos}
                00020000 {set os os216}
                00030000 {set os os232}
                00040000 {set os nt}
                00050000 {set os wince}
                00000001 {set os windows16}
                00000002 {set os pm16}
                00000003 {set os pm32}
                00000004 {set os windows32}
                00010001 {set os dos_windows16}
                00010004 {set os dos_windows32}
                00020002 {set os os216_pm16}
                00030003 {set os os232_pm32}
                00040004 {set os nt_windows32}
                default {set os $verinfo(dwFileOS)}
            }
            lappend result -fileos $os
        }

        if {$opts(all) || $opts(filetype)} {
            switch -exact -- [expr {0+$verinfo(dwFileType)}] {
                1 {set type application}
                2 {set type dll}
                3 {
                    set type "driver."
                    switch -exact -- [expr {0+$verinfo(dwFileSubtype)}] {
                        1 {append type printer}
                        2 {append type keyboard}
                        3 {append type language}
                        4 {append type display}
                        5 {append type mouse}
                        6 {append type network}
                        7 {append type system}
                        8 {append type installable}
                        9  {append type sound}
                        10 {append type comm}
                        11 {append type inputmethod}
                        12 {append type versionedprinter}
                        default {append type $verinfo(dwFileSubtype)}
                    }
                }
                4 {
                    set type "font."
                    switch -exact -- [expr {0+$verinfo(dwFileSubtype)}] {
                        1 {append type raster}
                        2 {append type vector}
                        3 {append type truetype}
                        default {append type $verinfo(dwFileSubtype)}
                    }
                }
                5 { set type "vxd.$verinfo(dwFileSubtype)" }
                7 {set type staticlib}
                default {
                    set type "$verinfo(dwFileType).$verinfo(dwFileSubtype)"
                }
            }
            lappend result -filetype $type
        }

        if {$opts(all) || $opts(datetime)} {
            lappend result -datetime [expr {($verinfo(dwFileDateMS) << 32) + $verinfo(dwFileDateLS)}]
        }

        # Any remaining arguments are treated as string names

        if {[llength $args] || $opts(foundlangid) || $opts(foundcodepage) || $opts(all)} {
            # Find list of langid's and codepages and do closest match
            set langid [expr {[info exists opts(langid)] ? $opts(langid) : [get_user_ui_langid]}]
            set primary_langid [extract_primary_langid $langid]
            set sub_langid     [extract_sublanguage_langid $langid]
            set cp [expr {[info exists opts(codepage)] ? $opts(codepage) : 0}]

            # Find a match in the following order:
            # 0 Exact match for both langid and codepage
            # 1 Exact match for langid
            # 2 Primary langid matches (sublang does not) and exact codepage
            # 3 Primary langid matches (sublang does not)
            # 4 Language neutral
            # 5 English
            # 6 First langcp in list or "00000000"
            set match(7) "00000000";    # In case list is empty
            foreach langcp [Twapi_VerQueryValue_TRANSLATIONS $ver] {
                set verlangid 0x[string range $langcp 0 3]
                set vercp 0x[string range $langcp 4 7]
                if {$verlangid == $langid && $vercp == $cp} {
                    set match(0) $langcp
                    break;              # No need to look further
                }
                if {[info exists match(1)]} continue
                if {$verlangid == $langid} {
                    set match(1) $langcp
                    continue;           # Continue to look for match(0)
                }
                if {[info exists match(2)]} continue
                set verprimary [extract_primary_langid $verlangid]
                if {$verprimary == $primary_langid && $vercp == $cp} {
                    set match(2) $langcp
                    continue;       # Continue to look for match(1) or better
                }
                if {[info exists match(3)]} continue
                if {$verprimary == $primary_langid} {
                    set match(3) $langcp
                    continue;       # Continue to look for match(2) or better
                }
                if {[info exists match(4)]} continue
                if {$verprimary == 0} {
                    set match(4) $langcp; # LANG_NEUTRAL
                    continue;       # Continue to look for match(3) or better
                }
                if {[info exists match(5)]} continue
                if {$verprimary == 9} {
                    set match(5) $langcp; # English
                    continue;       # Continue to look for match(4) or better
                }
                if {![info exists match(6)]} {
                    set match(6) $langcp
                }
            }

            # Figure out what is the best match we have
            for {set i 0} {$i <= 7} {incr i} {
                if {[info exists match($i)]} {
                    break
                }
            }

            if {$opts(foundlangid) || $opts(all)} {
                set langid 0x[string range $match($i) 0 3] 
                lappend result -foundlangid [list $langid [VerLanguageName $langid]]
            }

            if {$opts(foundcodepage) || $opts(all)} {
                lappend result -foundcodepage 0x[string range $match($i) 4 7]
            }

            foreach sname $args {
                lappend result $sname [Twapi_VerQueryValue_STRING $ver $match($i) $sname]
            }

        }

    } finally {
        Twapi_FreeFileVersionInfo $ver
    }

    return $result
}

proc twapi::begin_resource_update {path args} {
    array set opts [parseargs args {
        deleteall
    } -maxleftover 0]

    return [BeginUpdateResource $path $opts(deleteall)]
}

# Note this is not an alias because we want to control arguments
# to UpdateResource (which can take more args that specified here)
proc twapi::delete_resource {hmod restype resname langid} {
    UpdateResource $hmod $restype $resname $langid
}


# Note this is not an alias because we want to make sure $bindata is specified
# as an argument else it will have the effect of deleting a resource
proc twapi::update_resource {hmod restype resname langid bindata} {
    UpdateResource $hmod $restype $resname $langid $bindata
}

proc twapi::end_resource_update {hmod args} {
    array set opts [parseargs args {
        discard
    } -maxleftover 0]

    return [EndUpdateResource $hmod $opts(discard)]
}

proc twapi::read_resource {hmod restype resname langid} {
    return [Twapi_LoadResource $hmod [FindResourceEx $hmod $restype $resname $langid]]
}

proc twapi::read_resource_string {hmod resname langid} {
    # As an aside, note that we do not use a LoadString call
    # because it does not allow for specification of a langid
    
    # For a reference to how strings are stored, see
    # http://blogs.msdn.com/b/oldnewthing/archive/2004/01/30/65013.aspx
    # or http://support.microsoft.com/kb/196774

    if {![string is integer -strict $resname]} {
        error "String resources must have an integer id"
    }

    lassign [resource_stringid_to_stringblockid $resname]  block_id index_within_block

    return [lindex \
                [resource_stringblock_to_strings \
                     [read_resource $hmod 6 $block_id $langid] ] \
                $index_within_block]
}

# Give a list of strings, formats it as a string block. Number of strings
# must not be greater than 16. If less than 16 strings, remaining are
# treated as empty.
proc twapi::strings_to_resource_stringblock {strings} {
    if {[llength $strings] > 16} {
        error "Cannot have more than 16 strings in a resource string block."
    }

    for {set i 0} {$i < 16} {incr i} {
        set s [lindex $strings $i]
        set n [string length $s]
        append bin [binary format sa* $n [encoding convertto unicode $s]]
    }

    return $bin
}

proc twapi::resource_stringid_to_stringblockid {id} {
    # Strings are stored in blocks of 16, with block id's beginning at 1, not 0
    return [list [expr {($id / 16) + 1}] [expr {$id & 15}]]
}

proc twapi::extract_resources {hmod {withdata 0}} {
    set result [dict create]
    foreach type [enumerate_resource_types $hmod] {
        set typedict [dict create]
        foreach name [enumerate_resource_names $hmod $type] {
            set namedict [dict create]
            foreach lang [enumerate_resource_languages $hmod $type $name] {
                if {$withdata} {
                    dict set namedict $lang [read_resource $hmod $type $name $lang]
                } else {
                    dict set namedict $lang {}
                }
            }
            dict set typedict $name $namedict
        }
        dict set result $type $typedict
    }
    return $result
}

# TBD - do we document this?
proc twapi::write_bmp_file {filename bmp} {
    # Assumes $bmp is clipboard content in format 8 (CF_DIB)

    # First parse the bitmap data to collect header information
    binary scan $bmp "iiissiiiiii" size width height planes bitcount compression sizeimage xpelspermeter ypelspermeter clrused clrimportant

    # We only handle BITMAPINFOHEADER right now (size must be 40)
    if {$size != 40} {
        error "Unsupported bitmap format. Header size=$size"
    }

    # We need to figure out the offset to the actual bitmap data
    # from the start of the file header. For this we need to know the
    # size of the color table which directly follows the BITMAPINFOHEADER
    if {$bitcount == 0} {
        error "Unsupported format: implicit JPEG or PNG"
    } elseif {$bitcount == 1} {
        set color_table_size 2
    } elseif {$bitcount == 4} {
        # TBD - Not sure if this is the size or the max size
        set color_table_size 16
    } elseif {$bitcount == 8} {
        # TBD - Not sure if this is the size or the max size
        set color_table_size 256
    } elseif {$bitcount == 16 || $bitcount == 32} {
        if {$compression == 0} {
            # BI_RGB
            set color_table_size $clrused
        } elseif {$compression == 3} {
            # BI_BITFIELDS
            set color_table_size 3
        } else {
            error "Unsupported compression type '$compression' for bitcount value $bitcount"
        }
    } elseif {$bitcount == 24} {
        set color_table_size $clrused
    } else {
        error "Unsupported value '$bitcount' in bitmap bitcount field"
    }

    set filehdr_size 14;                # sizeof(BITMAPFILEHEADER)
    set bitmap_file_offset [expr {$filehdr_size+$size+($color_table_size*4)}]
    set filehdr [binary format "a2 i x2 x2 i" "BM" [expr {$filehdr_size + [string length $bmp]}] $bitmap_file_offset]

    set fd [open $filename w]
    fconfigure $fd -translation binary

    puts -nonewline $fd $filehdr
    puts -nonewline $fd $bmp

    close $fd
}

proc twapi::_load_image {flags type hmod path args} {
    # The flags arg is generally 0x10 (load from file), or 0 (module)
    # or'ed with 0x8000 (shared). The latter can be overridden by
    # the -shared option but should not be except when loading from module.
    array set opts [parseargs args {
        {createdibsection.bool 0 0x2000}
        {defaultsize.bool  0  0x40}
        height.int
        {loadtransparent.bool 0 0x20}
        {monochrome.bool  0  0x1}
        {shared.bool  0  0x8000}
        {vgacolor.bool  0  0x80}
        width.int
    } -maxleftover 0 -nulldefault]

    set flags [expr {$flags | $opts(defaultsize) | $opts(loadtransparent) | $opts(monochrome) | $opts(shared) | $opts(vgacolor)}]

    set h [LoadImage $hmod $path $type $opts(width) $opts(height) $flags]
    # Cast as _SHARED if required to offer some protection against
    # being freed using DestroyIcon etc.
    set type [lindex {HGDIOBJ HICON HCURSOR} $type]
    if {$flags & 0x8000} {
        append type _SHARED
    }
    return [cast_handle $h $type]
}


proc twapi::_load_image_from_system {type id args} {
    variable _oem_image_syms

    if {![string is integer -strict $id]} {
        if {![info exists _oem_image_syms]} {
            # Bitmap symbols (type 0)
            dict set _oem_image_syms 0 {
                CLOSE           32754            UPARROW         32753
                DNARROW         32752            RGARROW         32751
                LFARROW         32750            REDUCE          32749
                ZOOM            32748            RESTORE         32747
                REDUCED         32746            ZOOMD           32745
                RESTORED        32744            UPARROWD        32743
                DNARROWD        32742            RGARROWD        32741
                LFARROWD        32740            MNARROW         32739
                COMBO           32738            UPARROWI        32737
                DNARROWI        32736            RGARROWI        32735
                LFARROWI        32734            SIZE            32766
                BTSIZE          32761            CHECK           32760
                CHECKBOXES      32759            BTNCORNERS      32758
            }            
            # Icon symbols (type 1)
            dict set _oem_image_syms 1 {
                SAMPLE          32512            HAND            32513
                QUES            32514            BANG            32515
                NOTE            32516            WINLOGO         32517
                WARNING         32515            ERROR           32513
                INFORMATION     32516            SHIELD          32518
            }
            # Cursor symbols (type 2)
            dict set _oem_image_syms 2 {
                NORMAL          32512            IBEAM           32513
                WAIT            32514            CROSS           32515
                UP              32516            SIZENWSE        32642
                SIZENESW        32643            SIZEWE          32644
                SIZENS          32645            SIZEALL         32646
                NO              32648            HAND            32649
                APPSTARTING     32650
            }

        }
    }
        
    set id [dict get $_oem_image_syms $type [string toupper $id]]
    # Built-in system images must always be loaded shared (0x8000)
    return [_load_image 0x8000 $type NULL $id {*}$args]
}


# 0x10 -> LR_LOADFROMFILE. Also 0x8000 not set (meaning unshared)
interp alias {} twapi::load_bitmap_from_file {} twapi::_load_image 0x10 0 NULL
interp alias {} twapi::load_icon_from_file {} twapi::_load_image 0x10 1 NULL
interp alias {} twapi::load_cursor_from_file {} twapi::_load_image 0x10 2 NULL

interp alias {} twapi::load_bitmap_from_module {} twapi::_load_image 0 0
interp alias {} twapi::load_icon_from_module {} twapi::_load_image   0 1
interp alias {} twapi::load_cursor_from_module {} twapi::_load_image 0 2

interp alias {} twapi::load_bitmap_from_system {} twapi::_load_image_from_system 0
interp alias {} twapi::load_icon_from_system {} twapi::_load_image_from_system   1
interp alias {} twapi::load_cursor_from_system {} twapi::_load_image_from_system 2

interp alias {} twapi::free_icon {} twapi::DestroyIcon
interp alias {} twapi::free_bitmap {} twapi::DeleteObject
interp alias {} twapi::free_cursor {} twapi::DestroyCursor
