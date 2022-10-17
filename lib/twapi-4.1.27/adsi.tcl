#
# Copyright (c) 2010-2012, Ashok P. Nadkarni
# All rights reserved.
#
# See the file LICENSE for license

# ADSI routines

# TBD - document
proc twapi::adsi_translate_name {name to {from 0}} {
    set map {
        unknown 0 fqdn 1 samcompatible 2 display 3 uniqueid 6
        canonical 7 userprincipal 8 canonicalex 9 serviceprincipal 10
        dnsdomain 12
    }
    if {! [string is integer -strict $to]} {
        set to [dict get $map $to]
        if {$to == 0} {
            error "'unknown' is not a valid target format."
        }
    }

    if {! [string is integer -strict $from]} {
        set from [dict get $map $from]
    }
        
    return [TranslateName $name $from $to]
}