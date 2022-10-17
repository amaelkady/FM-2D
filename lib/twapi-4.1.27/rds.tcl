#
# Copyright (c) 2010, Ashok P. Nadkarni
# All rights reserved.
#
# See the file LICENSE for license

# Remote Desktop Services - TBD - document and test

namespace eval twapi {}

proc twapi::rds_enumerate_sessions {args} {
    array set opts [parseargs args {
        {hserver.arg 0}
        state.arg
    } -maxleftover 0]

    set states {active connected connectquery shadow disconnected idle listen reset down init}
    if {[info exists opts(state)]} {
        if {[string is integer -strict $opts(state)]} {
            set state $opts(state)
        } else {
            set state [lsearch -exact $states $opts(state)]
            if {$state < 0} {
                error "Invalid value '$opts(state)' specified for -state option."
            }
        }
    }

    set sessions [WTSEnumerateSessions $opts(hserver)]

    if {[info exists state]} {
        set sessions [recordarray get $sessions -filter [list [list State == $state]]]
    }

    set result {}
    foreach {sess rec} [recordarray getdict $sessions -key SessionId -format dict] {
        set state [lindex $states [kl_get $rec State]]
        if {$state eq ""} {
            set state [kl_get $rec State]
        }
        lappend result $sess [list -tssession [kl_get $rec SessionId] \
                                  -winstaname [kl_get $rec pWinStationName] \
                                  -state $state]
    }
    return $result
}

proc twapi::rds_disconnect_session args {
    array set opts [parseargs args {
        {hserver.arg 0}
        {tssession.int -1}
        {async.bool false}
    } -maxleftover 0]

    WTSDisconnectSession $opts(hserver) $opts(tssession) [expr {! $opts(async)}]

}

proc twapi::rds_logoff_session args {
    array set opts [parseargs args {
        {hserver.arg 0}
        {tssession.int -1}
        {async.bool false}
    } -maxleftover 0]

    WTSLogoffSession $opts(hserver) $opts(tssession) [expr {! $opts(async)}]
}

proc twapi::rds_query_session_information {infoclass args} {
    array set opts [parseargs args {
        {hserver.arg 0}
        {tssession.int -1}
    } -maxleftover 0]

    return [WTSQuerySessionInformation $opts(hserver) $opts(tssession) $infoclass]
}

interp alias {} twapi::rds_get_session_appname {} twapi::rds_query_session_information 1
interp alias {} twapi::rds_get_session_clientdir {} twapi::rds_query_session_information 11
interp alias {} twapi::rds_get_session_clientname {} twapi::rds_query_session_information 10
interp alias {} twapi::rds_get_session_userdomain {} twapi::rds_query_session_information 7
interp alias {} twapi::rds_get_session_initialprogram {} twapi::rds_query_session_information 0
interp alias {} twapi::rds_get_session_oemid {} twapi::rds_query_session_information 3
interp alias {} twapi::rds_get_session_user {} twapi::rds_query_session_information 5
interp alias {} twapi::rds_get_session_winsta {} twapi::rds_query_session_information 6
interp alias {} twapi::rds_get_session_intialdir {} twapi::rds_query_session_information 2
interp alias {} twapi::rds_get_session_clientbuild {} twapi::rds_query_session_information 9
interp alias {} twapi::rds_get_session_clienthwid {} twapi::rds_query_session_information 13
interp alias {} twapi::rds_get_session_state {} twapi::rds_query_session_information 8
interp alias {} twapi::rds_get_session_id {} twapi::rds_query_session_information 4
interp alias {} twapi::rds_get_session_productid {} twapi::rds_query_session_information 12
interp alias {} twapi::rds_get_session_protocol {} twapi::rds_query_session_information 16


proc twapi::rds_send_message {args} {

    array set opts [parseargs args {
        {hserver.arg 0}
        tssession.int
        title.arg
        message.arg
        {buttons.arg ok}
        {icon.arg information}
        defaultbutton.arg
        {modality.arg task {task appl application system}}
        {justify.arg left {left right}}
        rtl.bool
        foreground.bool
        topmost.bool
        showhelp.bool
        service.bool
        timeout.int
        async.bool
    } -maxleftover 0 -nulldefault]

    if {![kl_vget {
        ok             {0 {ok}}
        okcancel       {1 {ok cancel}}
        abortretryignore {2 {abort retry ignore}}
        yesnocancel    {3 {yes no cancel}}
        yesno          {4 {yes no}}
        retrycancel    {5 {retry cancel}}
        canceltrycontinue {6 {cancel try continue}}
    } $opts(buttons) buttons]} {
        error "Invalid value '$opts(buttons)' specified for option -buttons."
    }

    set style [lindex $buttons 0]
    switch -exact -- $opts(icon) {
        warning -
        exclamation {setbits style 0x30}
        asterisk -
        information {setbits style 0x40}
        question    {setbits style 0x20}
        error -
        hand  -
        stop        {setbits style 0x10}
        default {
            error "Invalid value '$opts(icon)' specified for option -icon."
        }
    }

    # Map the default button
    switch -exact -- [lsearch -exact [lindex $buttons 1] $opts(defaultbutton)] {
        1 {setbits style 0x100 }
        2 {setbits style 0x200 }
        3 {setbits style 0x300 }
        default {
            # First button,
            # setbits style 0x000
        }
    }

    switch -exact -- $opts(modality) {
        system { setbits style 0x1000 }
        task   { setbits style 0x2000 }
        appl -
        application -
        default {
            # setbits style 0x0000
        }
    }

    if {$opts(showhelp)} { setbits style 0x00004000 }
    if {$opts(rtl)} { setbits style 0x00100000 }
    if {$opts(justify) eq "right"} { setbits style 0x00080000 }
    if {$opts(topmost)} { setbits style 0x00040000 }
    if {$opts(foreground)} { setbits style 0x00010000 }
    if {$opts(service)} { setbits style 0x00200000 }

    set response [WTSSendMessage $opts(hserver) $opts(tssession) $opts(title) \
                      $opts(message) $style $opts(timeout) \
                      [expr {!$opts(async)}]]
    
    switch -exact -- $response {
        1 { return ok }
        2 { return cancel }
        3 { return abort }
        4 { return retry }
        5 { return ignore }
        6 { return yes }
        7 { return no }
        8 { return close }
        9 { return help }
        10 { return tryagain }
        11 { return continue }
        32000 { return timeout }
        32001 { return async }
        default { return $response }
    }
}
