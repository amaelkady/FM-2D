namespace eval twapi::tls {
    # Each element of _channels is dictionary with the following keys
    #  Socket - the underlying socket. This key will not exist if
    #   socket has been closed.
    #  State - SERVERINIT, CLIENTINIT, LISTENERINIT, OPEN, NEGOTIATING, CLOSED
    #  Type - SERVER, CLIENT, LISTENER
    #  Blocking - 0/1 indicating whether blocking or non-blocking channel
    #  WatchMask - list of {read write} indicating what events to post
    #  Target - Name for server cert
    #  Credentials - credentials handle to use for local end of connection
    #  FreeCredentials - if credentials should be freed on connection cleanup
    #  AcceptCallback - application callback on a listener and server socket.
    #    On listener, it is the accept command prefix. On a server 
    #    (accepted socket) it is the prefix plus arguments passed to
    #    accept callback. On client and on servers sockets initialized
    #    with starttls, this key must NOT be present
    #  SspiContext - SSPI context for the connection
    #  Input  - plaintext data to pass to app
    #  Output - plaintext data to encrypt and output
    #  ReadEventPosted - if this key exists, a chan postevent for read
    #    is already in progress and a second one should not be posted
    #  WriteEventPosted - if this key exists, a chan postevent for write
    #    is already in progress and a second one should not be posted

    variable _channels
    array set _channels {}

    namespace path [linsert [namespace path] 0 [namespace parent]]

}

interp alias {} twapi::tls_socket {} twapi::tls::_socket
proc twapi::tls::_socket {args} {
    variable _channels

    debuglog [info level 0]

    parseargs args {
        myaddr.arg
        myport.int
        async
        server.arg
        peersubject.arg
        {credentials.arg {}}
        {verifier.arg {}}
    } -setvars

    set chan [chan create {read write} [list [namespace current]]]

    set socket_args {}
    foreach opt {myaddr myport} {
        if {[info exists $opt]} {
            lappend socket_args -$opt [set $opt]
        }
    }

    if {[info exists server]} {
        if {$server eq ""} {
            badargs! "Cannot specify an empty value for -server."
        }

        if {[info exists peersubject]} {
            badargs! "Option -peersubject cannot be specified for with -server"
        }
        set peersubject ""
        set type LISTENER
        lappend socket_args -server [list [namespace current]::_accept $chan]
        if {[llength $credentials] == 0} {
            badargs! "Option -credentials must be specified for server sockets"
        }
    } else {
        if {![info exists peersubject]} {
            set peersubject [lindex $args 0]
        }
        set server ""
        set type CLIENT
    }

    trap {
        set so [socket {*}$socket_args {*}$args]
        _init $chan $type $so $credentials $peersubject [lrange $verifier 0 end] $server

        if {$type eq "CLIENT"} {
            if {! $async} {
                _client_blocking_negotiate $chan
                if {(![info exists _channels($chan)]) ||
                    [dict get $_channels($chan) State] ne "OPEN"} {
                    if {[info exists _channels($chan)] &&
                        [dict exists $_channels($chan) ErrorResult]} {
                        error [dict get $_channels($chan) ErrorResult]
                    } else {
                        error "TLS negotiation aborted"
                    }
                }
            }
        }
    } onerror {} {
        # If _init did not even go as far initializing _channels($chan),
        # close socket ourselves. If it was initialized, the socket
        # would have been closed even on error
        if {![info exists _channels($chan)]} {
            catch {chan close $so}
        }
        catch {chan close $chan}
        # DON'T ACCESS _channels HERE ON
        if {[string match "wrong # args*" [trapresult]]} {
            badargs! "wrong # args: should be \"tls_socket ?-credentials creds? ?-verifier command? ?-peersubject peer? ?-myaddr addr? ?-myport myport? ?-async? host port\" or \"tls_socket ?-credentials creds? ?-verifier command? -server command ?-myaddr addr? port\""
        } else {
            rethrow
        }
    }

    return $chan
}

interp alias {} twapi::starttls {} twapi::tls::_starttls
proc twapi::tls::_starttls {so args} {
    variable _channels

    debuglog [info level 0]

    parseargs args {
        server
        peersubject.arg
        {credentials.arg {}}
        {verifier.arg {}}
    } -setvars -maxleftover 0

    set chan [chan create {read write} [list [namespace current]]]

    if {$server} {
        if {[info exists peersubject]} {
            badargs! "Option -peersubject cannot be specified for with -server"
        }
        if {[llength $credentials] == 0} {
            error "Option -credentials must be specified for server sockets"
        }
        set peersubject ""
        set type SERVER
    } else {
        if {![info exists peersubject]} {
            # TBD - even if verifier is specified ?
            badargs! "Option -peersubject must be specified for client connections."
        }
        set type CLIENT
    }

    trap {
        # Get config from the wrapped socket and reset its handlers
        # Do not get all options because that results in reverse name
        # lookups for -peername and -sockname causing a stall.
        foreach opt {
            -blocking -buffering -buffersize -encoding -eofchar -translation
        } {
            lappend so_opts $opt [chan configure $so $opt]
        }

        # NOTE: we do NOT save read and write handlers and attach
        # them to the new channel because the channel name is different.
        # Thus in most cases the callbacks, which often are passed the
        # channel name as an arg, would not be valid. It is up
        # to the caller to reestablish handlers
        # TBD - maybe keep handlers but replace $so with $chan in them ?
        chan event $so readable {}
        chan event $so writable {}
        _init $chan $type $so $credentials $peersubject [lrange $verifier 0 end] ""
        # Copy saved config to wrapper channel
        chan configure $chan {*}$so_opts
        if {$type eq "CLIENT"} {
            _client_blocking_negotiate $chan
            if {(![info exists _channels($chan)]) ||
                [dict get $_channels($chan) State] ne "OPEN"} {
                if {[info exists _channels($chan)] &&
                    [dict exists $_channels($chan) ErrorResult]} {
                    error [dict get $_channels($chan) ErrorResult]
                } else {
                    error "TLS negotiation aborted"
                }
            }
        } else {
            # Note: unlike the tls_socket server case, here we
            # do not need to switch a blocking socket to non-blocking
            # and then switch back, primarily because the socket
            # is already open and there is no need for a callback
            # when connection opens.
            if {! [dict get $_channels($chan) Blocking]} {
                chan configure $so -blocking 0
                chan event $so readable [list [namespace current]::_so_read_handler $chan]
            }
            _negotiate $chan
        }
    } onerror {} {
        # If _init did not even go as far initializing _channels($chan),
        # close socket ourselves. If it was initialized, the socket
        # would have been closed even on error
        if {![info exists _channels($chan)]} {
            catch {chan close $so}
        }
        catch {chan close $chan}
        # DON'T ACCESS _channels HERE ON
        if {[string match "wrong # args*" [trapresult]]} {
            badargs! "wrong # args: should be \"tls_socket ?-credentials creds? ?-verifier command? ?-peersubject peer? ?-myaddr addr? ?-myport myport? ?-async? host port\" or \"tls_socket ?-credentials creds? ?-verifier command? -server command ?-myaddr addr? port\""
        } else {
            rethrow
        }
    }

    return $chan
}


proc twapi::tls::_accept {listener so raddr raport} {
    variable _channels

    debuglog [info level 0]

    trap {
        set chan [chan create {read write} [list [namespace current]]]
        _init $chan SERVER $so [dict get $_channels($listener) Credentials] "" [dict get $_channels($listener) Verifier] [linsert [dict get $_channels($listener) AcceptCallback] end $chan $raddr $raport]
        # If we negotiate the connection, the socket is blocking so
        # will hang the whole operation. Instead we mark it non-blocking
        # and the switch back to blocking when the connection gets opened.
        # For accepts to work, the event loop has to be running anyways.
        chan configure $so -blocking 0
        chan event $so readable [list [namespace current]::_so_read_handler $chan]
        _negotiate $chan
    } onerror {} {
        catch {_cleanup $chan}
        rethrow
    }
    return
}

proc twapi::tls::initialize {chan mode} {
    debuglog [info level 0]

    # All init is done in chan creation routine after base socket is created
    return {initialize finalize watch blocking read write configure cget cgetall}
}

proc twapi::tls::finalize {chan} {
    debuglog [info level 0]
    _cleanup $chan
    return
}

proc twapi::tls::blocking {chan mode} {
    debuglog [info level 0]

    variable _channels

    dict with _channels($chan) {
        set Blocking $mode

        if {![info exists Socket]} {
            # We do not currently generate an error because the Tcl socket
            # command does not either on a fconfigure when remote has
            # closed connection
            return
        }

        chan configure $Socket -blocking $mode
        if {$mode == 0} {
            # Since we need to negotiate TLS we always have socket event
            # handlers irrespective of the state of the watch mask
            chan event $Socket readable [list [namespace current]::_so_read_handler $chan]
            chan event $Socket writable [list [namespace current]::_so_write_handler $chan]
        } else {
            chan event $Socket readable {}
            chan event $Socket writable {}
        }
    }
    return
}

proc twapi::tls::watch {chan watchmask} {
    debuglog [info level 0]
    variable _channels

    dict with _channels($chan) {
        set WatchMask $watchmask
        if {"read" in $watchmask} {
            # Post a read even if we already have input or if the 
            # underlying socket has gone away.
            # TBD - do we have a mechanism for continuously posting
            # events when socket has gone away ? Do we even post once
            # when socket is closed (on error for example)
            if {[string length $Input] || ![info exists Socket]} {
                _post_read_event $chan
            }
            # Turn read handler back on in case it had been turned off.
            chan event $Socket readable [list [namespace current]::_so_read_handler $chan]
        }

        # TBD - do we need to turn write handler back on?
        if {"write" in $watchmask} {
            # We will mark channel as writable even if we are still
            # initializing. This is to deal with the case where 
            # the -async option is used and caller waits for the
            # writable event to do the actual write (which will then
            # trigger the negotiation if needed)
            if {$State in {OPEN SERVERINIT CLIENTINIT NEGOTIATING}} {
                _post_write_event $chan
            }
        }
    }

    return
}

proc twapi::tls::read {chan nbytes} {
    variable _channels

    debuglog [info level 0]

    if {$nbytes == 0} {
        return {}
    }

    # This is not inside the dict with because _negotiate will update the dict
    if {[dict get $_channels($chan) State] in {SERVERINIT CLIENTINIT NEGOTIATING}} {
        _negotiate $chan
        if {[dict get $_channels($chan) State] in {SERVERINIT CLIENTINIT NEGOTIATING}} {
            # If a blocking channel, should have come back with negotiation
            # complete. If non-blocking, return EAGAIN to indicate no
            # data yet
            if {[dict get $_channels($chan) Blocking]} {
                error "TLS negotiation failed on blocking channel" 
            } else {
                return -code error EAGAIN
            }
        }
    }

    dict with _channels($chan) {
        # Try to read more bytes if don't have enough AND conn is open
        set status ok
        if {[string length $Input] < $nbytes && $State eq "OPEN"} {
            if {$Blocking} {
                # For blocking channels, we do not want to block if some
                # bytes are already available. The refchan will call us
                # with number of bytes corresponding to its buffer size,
                # not what app's read call has asked. It expects us
                # to return whatever we have (but at least one byte)
                # and block only if nothing is available
                while {[string length $Input] == 0 && $status eq "ok"} {
                    # The channel does not compress so we need to read in
                    # at least $needed bytes. Because of TLS overhead, we may
                    # actually need even more
                    set status ok
                    set data [_blocking_read $Socket]
                    if {[string length $data]} {
                        lassign [sspi_decrypt_stream $SspiContext $data] status plaintext
                        # Note plaintext might be "" if complete cipher block
                        # was not received
                        append Input $plaintext
                    } else {
                        set status eof
                    }
                }
            } else {
                # Non-blocking - read all that we can
                set status ok
                set data [chan read $Socket]
                if {[string length $data]} {
                    lassign [sspi_decrypt_stream $SspiContext $data] status plaintext
                    append Input $plaintext
                } else {
                    if {[chan eof $Socket]} {
                        set status eof
                    }
                }
                if {[string length $Input] == 0} {
                    # Do not have enough data. See if connection closed
                    # TBD - also handle status == renegotiate
                    if {$status eq "ok"} {
                        # Not closed, just waiting for data
                        return -code error EAGAIN
                    }
                }
            }
        }

        # TBD - use inline K operator to make this faster? Probably no use
        # since Input is also referred to from _channels($chan)
        set ret [string range $Input 0 $nbytes-1]
        set Input [string range $Input $nbytes end]
        if {"read" in [dict get $_channels($chan) WatchMask] && [string length $Input]} {
            _post_read_event $chan
        }
        if {$status ne "ok"} {
            # TBD - handle renegotiate
            set State CLOSED
            lassign [sspi_shutdown_context $SspiContext] _ outdata
            if {[info exists Socket]} {
                if {[string length $outdata] && $status ne "eof"} {
                    puts -nonewline $Socket $outdata
                }
                catch {close $Socket}
                unset Socket
            }
        }
        return $ret;            # Note ret may be ""
    }
}

proc twapi::tls::write {chan data} {
    debuglog [info level 0]
    variable _channels

    # This is not inside the dict with because _negotiate will update the dict
    if {[dict get $_channels($chan) State] in {SERVERINIT CLIENTINIT NEGOTIATING}} {
        _negotiate $chan
        if {[dict get $_channels($chan) State] in {SERVERINIT CLIENTINIT NEGOTIATING}} {
            # If a blocking channel, should have come back with negotiation
            # complete. If non-blocking, return EAGAIN to indicate channel
            # not open yet.
            if {[dict get $_channels($chan) Blocking]} {
                error "TLS negotiation failed on blocking channel" 
            } else {
                # TBD - should we just accept the data ?
                return -code error EAGAIN
            }
        }
    }

    dict with _channels($chan) {
        switch $State {
            CLOSED {
                # Just like a Tcl socket, we do not raise an error.
                # Simply throw away the data
            }
            OPEN {
                # There might be pending output if channel has just
                # transitioned to OPEN state
                # TBD - use sspi_encrypt_and_write instead
                if {[string length $Output]} {
                    chan puts -nonewline $Socket [sspi_encrypt_stream $SspiContext $Output]
                    set Output ""
                }
                chan puts -nonewline $Socket [sspi_encrypt_stream $SspiContext $data]
                flush $Socket
            }
            default {
                append Output $data
            }
        }
    }
    return [string length $data]
}

proc twapi::tls::configure {chan opt val} {
    debuglog [info level 0]
    # Does not make sense to change creds and verifier after creation
    switch $opt {
        -context -
        -verifier -
        -credentials {
            error "$opt is a read-only option."
        }
        default {
            chan configure [_chansocket $chan] $opt $val
        }
    }

    return
}

proc twapi::tls::cget {chan opt} {
    debuglog [info level 0]
    variable _channels

    switch $opt {
        -credentials {
            return [dict get $_channels($chan) Credentials]
        }
        -verifier {
            return [dict get $_channels($chan) Verifier]
        }
        -context {
            return [dict get $_channels($chan) SspiContext]
        }
        default {
            return [chan configure [_chansocket $chan] $opt]
        }
    }
}

proc twapi::tls::cgetall {chan} {
    debuglog [info level 0]
    variable _channels

    dict with _channels($chan) {
        if {[info exists Socket]} {
            foreach opt {-peername -sockname} {
                lappend config $opt [chan configure $Socket $opt]
            }
        }
        lappend config -credentials $Credentials \
        -verifier $Verifier \
        -context $SspiContext
    }
    return $config
}

proc twapi::tls::_chansocket {chan} {
    debuglog [info level 0]
    variable _channels
    if {![info exists _channels($chan)]} {
        error "Channel $chan not found."
    }
    return [dict get $_channels($chan) Socket]
}

proc twapi::tls::_init {chan type so creds peersubject verifier {accept_callback {}}} {
    debuglog [info level 0]
    variable _channels

    # TBD - verify that -buffering none is the right thing to do
    # as the scripted channel interface takes care of this itself
    chan configure $so -translation binary -buffering none
    set _channels($chan) [list Socket $so \
                              State ${type}INIT \
                              Type $type \
                              Blocking [chan configure $so -blocking] \
                              WatchMask {} \
                              Verifier $verifier \
                              SspiContext {} \
                              PeerSubject $peersubject \
                              Input {} Output {}]

    if {[llength $creds]} {
        set free_creds 0
    } else {
        set creds [sspi_acquire_credentials -package tls -role client -credentials [sspi_schannel_credentials]]
        set free_creds 1
    }
    dict set _channels($chan) Credentials $creds
    dict set _channels($chan) FreeCredentials $free_creds

    if {[string length $accept_callback] &&
        ($type eq "LISTENER" || $type eq "SERVER")} {
        dict set _channels($chan) AcceptCallback $accept_callback
    }
}

proc twapi::tls::_cleanup {chan} {
    debuglog [info level 0]
    variable _channels
    if {[info exists _channels($chan)]} {
        # Note _cleanup can be called in inconsistent state so not all
        # keys may be set up
        dict with _channels($chan) {
            if {[info exists SspiContext]} {
                if {$State eq "OPEN"} {
                    lassign [sspi_shutdown_context $SspiContext] _ outdata
                    if {[string length $outdata] && [info exists Socket]} {
                        if {[catch {puts -nonewline $Socket $outdata} msg]} {
                            # TBD - debug log
                        }
                    }
                }
                if {[catch {sspi_delete_context $SspiContext} msg]} {
                    # TBD - debug log
                }
            }
            if {[info exists Socket]} {
                if {[catch {chan close $Socket} msg]} {
                    # TBD - debug log socket close error
                }
            }
            if {[info exists Credentials] && $FreeCredentials} {
                if {[catch {sspi_free_credentials $Credentials} msg]} {
                    # TBD - debug log
                }
            }
        }
        unset _channels($chan)
    }
}

proc twapi::tls::_so_read_handler {chan} {
    debuglog [info level 0]
    variable _channels

    if {[info exists _channels($chan)]} {
        if {[dict get $_channels($chan) State] in {SERVERINIT CLIENTINIT NEGOTIATING}} {
            _negotiate $chan
        }

        if {"read" in [dict get $_channels($chan) WatchMask]} {
            _post_read_event $chan
        } else {
            # We are not asked to generate read events, turn off the read
            # event handler unless we are negotiating
            if {[dict get $_channels($chan) State] ni {SERVERINIT CLIENTINIT NEGOTIATING}} {
                if {[dict exists $_channels($chan) Socket]} {
                    chan event [dict get $_channels($chan) Socket] readable {}
                }
            }
        }
    }
    return
}

proc twapi::tls::_so_write_handler {chan} {
    debuglog [info level 0]
    variable _channels

    if {[info exists _channels($chan)]} {
        dict with _channels($chan) {}

        # If we are not actually asked to generate write events,
        # the only time we want a write handler is on a client -async
        # Once it runs, we never want it again else it will keep triggering
        # as sockets are always writable
        if {"write" ni $WatchMask} {
            if {[info exists Socket]} {
                chan event $Socket writable {}
            }
        }

        if {$State in {SERVERINIT CLIENTINIT NEGOTIATING}} {
            _negotiate $chan
        }

        # Do not use local var $State because _negotiate might have updated it
        if {"write" in $WatchMask && [dict get $_channels($chan) State] eq "OPEN"} {
            _post_write_event $chan
        }
    }
    return
}

proc twapi::tls::_negotiate chan {
    debuglog [info level 0]
    trap {
        _negotiate2 $chan
    } onerror {} {
        variable _channels
        if {[info exists _channels($chan)]} {
            dict set _channels($chan) State CLOSED
            dict set _channels($chan) ErrorOptions [trapoptions]
            dict set _channels($chan) ErrorResult [trapresult]
            if {[dict exists $_channels($chan) Socket]} {
                catch {close [dict get $_channels($chan) Socket]}
                dict unset _channels($chan) Socket
            }
        }
        rethrow
    }
}

proc twapi::tls::_negotiate2 {chan} {
    variable _channels
        
    dict with _channels($chan) {}; # dict -> local vars

    debuglog [info level 0]
    switch $State {
        NEGOTIATING {
            if {$Blocking && ![info exists AcceptCallback]} {
                error "Internal error: NEGOTIATING state not expected on a blocking client socket"
            }

            set data [chan read $Socket]
            if {[string length $data] == 0} {
                if {[chan eof $Socket]} {
                    error "Unexpected EOF during TLS negotiation (NEGOTIATING)"
                } else {
                    # No data yet, just keep waiting
                    debuglog "Waiting (chan $chan) for more data on Socket $Socket"
                    return
                }
            } else {
                lassign [sspi_step $SspiContext $data] status outdata leftover
                debuglog "sspi_step returned status $status with [string length $outdata] bytes"
                if {[string length $outdata]} {
                    chan puts -nonewline $Socket $outdata
                    chan flush $Socket
                }
                switch $status {
                    done {
                        if {[string length $leftover]} {
                            lassign [sspi_decrypt_stream $SspiContext $leftover] status plaintext
                            dict append _channels($chan) Input $plaintext
                            if {$status ne "ok"} {
                                # TBD - shutdown channel or let _cleanup do it?
                            }
                        }
                        _open $chan
                    }
                    continue {
                        # Keep waiting for next input
                    }
                    default {
                        debuglog "sspi_step returned $status"
                        error "Unexpected status $status from sspi_step"
                    }
                }
            }
        }

        CLIENTINIT {
            if {$Blocking} {
                _client_blocking_negotiate $chan
            } else {
                dict set _channels($chan) State NEGOTIATING
                set SspiContext [sspi_client_context $Credentials -stream 1 -target $PeerSubject -manualvalidation [expr {[llength $Verifier] > 0}]]
                dict set _channels($chan) SspiContext $SspiContext
                lassign [sspi_step $SspiContext] status outdata
                if {[string length $outdata]} {
                    chan puts -nonewline $Socket $outdata
                    chan flush $Socket
                }
                if {$status ne "continue"} {
                    error "Unexpected status $status from sspi_step"
                }
            }
        }
        
        SERVERINIT {
            # For server sockets created from tls_socket, we
            # always take the non-blocking path as we set the socket
            # to be non-blocking so as to not hold up the whole app
            # For server sockets created with starttls 
            # (AcceptCallback will not exist), we can do a blocking
            # negotiate.
            if {$Blocking && ![info exists AcceptCallback]} {
                _server_blocking_negotiate $chan
            } else {
                set data [chan read $Socket]
                if {[string length $data] == 0} {
                    if {[chan eof $Socket]} {
                        error "Unexpected EOF during TLS negotiation (SERVERINIT)"
                    } else {
                        # No data yet, just keep waiting
                        debuglog "$chan: no data from socket $Socket. Waiting..."
                        return
                    }
                } else {
                    debuglog "Setting $chan State=NEGOTIATING"

                    dict set _channels($chan) State NEGOTIATING
                    set SspiContext [sspi_server_context $Credentials $data -stream 1]
                    dict set _channels($chan) SspiContext $SspiContext
                    lassign [sspi_step $SspiContext] status outdata leftover
                    debuglog "sspi_step returned status $status with [string length $outdata] bytes"
                    if {[string length $outdata]} {
                        debuglog "Writing [string length $outdata] bytes to socket $Socket"
                        chan puts -nonewline $Socket $outdata
                        chan flush $Socket
                    }
                    switch $status {
                        done {
                            if {[string length $leftover]} {
                                lassign [sspi_decrypt_stream $SspiContext $leftover] status plaintext
                                dict append _channels($chan) Input $plaintext
                                if {$status ne "ok"} {
                                    # TBD - shut down channel
                                }
                            }
                            debuglog "Marking channel $chan open"
                            _open $chan
                        }
                        continue {
                            # Keep waiting for next input
                        }
                        default {
                            error "Unexpected status $status from sspi_step"
                        }
                    }
                }
            }
        }

        default {
            error "Internal error: _negotiate called in state [dict get $_channels($chan) State]"
        }
    }

    return
}

proc twapi::tls::_client_blocking_negotiate {chan} {
    debuglog [info level 0]
    variable _channels
    dict with _channels($chan) {
        set State NEGOTIATING
        set SspiContext [sspi_client_context $Credentials -stream 1 -target $PeerSubject -manualvalidation [expr {[llength $Verifier] > 0}]]
    }
    return [_blocking_negotiate_loop $chan]
}

proc twapi::tls::_server_blocking_negotiate {chan} {
    debuglog [info level 0]
    variable _channels
    dict set _channels($chan) State NEGOTIATING
    set so [dict get $_channels($chan) Socket]
    set indata [_blocking_read $so]
    if {[chan eof $so]} {
        error "Unexpected EOF during TLS negotiation (server)."
    }
    dict set _channels($chan) SspiContext [sspi_server_context [dict get $_channels($chan) Credentials] $indata -stream 1]
    return [_blocking_negotiate_loop $chan]
}

proc twapi::tls::_blocking_negotiate_loop {chan} {
    debuglog [info level 0]
    variable _channels

    dict with _channels($chan) {}; # dict -> local vars

    lassign [sspi_step $SspiContext] status outdata
    debuglog "sspi_step status $status"
    # Keep looping as long as the SSPI state machine tells us to 
    while {$status eq "continue"} {
        # If the previous step had any output, send it out
        if {[string length $outdata]} {
            debuglog "Writing [string length $outdata] to socket $Socket"
            chan puts -nonewline $Socket $outdata
            chan flush $Socket
        }

        set indata [_blocking_read $Socket]
        debuglog "Read [string length $indata] from socket $Socket"
        if {[chan eof $Socket]} {
            error "Unexpected EOF during TLS negotiation."
        }
        trap {
            lassign [sspi_step $SspiContext $indata] status outdata leftover
        } onerror {} {
            debuglog "sspi_step returned error: [trapresult]"
            close $Socket
            unset Socket
            rethrow
        }
        debuglog "sspi_step status $status"
    }

    # Send output irrespective of status
    if {[string length $outdata]} {
        chan puts -nonewline $Socket $outdata
        chan flush $Socket
    }

    if {$status eq "done"} {
        if {[string length $leftover]} {
            lassign [sspi_decrypt_stream $SspiContext $leftover] status plaintext
            dict append _channels($chan) Input $plaintext
            if {$status ne "ok"} {
                error "Error status $status decrypting data"
            }
        }
        _open $chan
    } else {
        # Should not happen. Negotiation failures will raise an error,
        # not return a value
        error "TLS negotiation failed: status $status."
    }

    return
}

proc twapi::tls::_blocking_read {so} {
    debuglog [info level 0]
    # Read from a blocking socket. We do not know how much data is needed
    # so read a single byte and then read any pending
    set input [chan read $so 1]
    if {[string length $input]} {
        set more [chan pending input $so]
        if {$more > 0} {
            append input [chan read $so $more]
        }
    }    
    return $input
}

# Transitions connection to OPEN or throws error if verifier returns false
# or fails
proc twapi::tls::_open {chan} {
    debuglog [info level 0]
    variable _channels

    dict with _channels($chan) {}; # dict -> local vars

    if {[llength $Verifier] == 0} {
        # No verifier specified. In this case, we would not have specified
        # -manualvalidation in creating the context and the system would
        # have done the verification already for client. For servers,
        # there is no verification of clients to be done by default

        # For compatibility with TLS we call accept callbacks AFTER verification
        dict set _channels($chan) State OPEN
        if {[info exists AcceptCallback]} {
            # Server sockets are set up to be non-blocking during negotiation
            # Change them back to original state before notifying app
            chan configure $Socket -blocking [dict get $_channels($chan) Blocking]
            chan event $Socket readable {}
            after 0 $AcceptCallback
        }
        return
    }

    # TBD - what if verifier closes the channel
    if {[{*}$Verifier $chan $SspiContext]} {
        dict set _channels($chan) State OPEN
        # For compatibility with TLS we call accept callbacks AFTER verification
        if {[info exists AcceptCallback]} {
            # Server sockets are set up to be non-blocking during 
            # negotiation. Change them back to original state
            # before notifying app
            chan configure $Socket -blocking [dict get $_channels($chan) Blocking]
            chan event $Socket readable {}
            after 0 $AcceptCallback
        }
        return
    } else {
        error "SSL/TLS negotiation failed. Verifier callback returned false." "" [list TWAPI TLS VERIFYFAIL]
    }
}

# Calling [chan postevent] results in filevent handlers being called right
# away which can recursively call back into channel code making things
# more than a bit messy. So we always schedule them through the event loop
proc twapi::tls::_post_read_event_callback {chan} {
    debuglog [info level 0]
    variable _channels
    if {[info exists _channels($chan)]} {
        dict unset _channels($chan) ReadEventPosted
        if {"read" in [dict get $_channels($chan) WatchMask]} {
            chan postevent $chan read
        }
    }
}
proc twapi::tls::_post_read_event {chan} {
    debuglog [info level 0]
    variable _channels
    if {![dict exists $_channels($chan) ReadEventPosted]} {
        # Note after 0 after idle does not work - (never get called)
        # not sure why so just do after 0
        dict set _channels($chan) ReadEventPosted \
            [after 0 [namespace current]::_post_read_event_callback $chan]
    }
}
proc twapi::tls::_post_write_event_callback {chan} {
    debuglog [info level 0]
    variable _channels
    if {[info exists _channels($chan)]} {
        dict unset _channels($chan) WriteEventPosted
        if {"write" in [dict get $_channels($chan) WatchMask] &&
            [dict get $_channels($chan) State] in {OPEN SERVERINIT CLIENTINIT NEGOTIATING}} {
            chan postevent $chan write
        }
    }
}
proc twapi::tls::_post_write_event {chan} {
    debuglog [info level 0]
    variable _channels
    if {![dict exists $_channels($chan) WriteEventPosted]} {
        # Note after 0 after idle does not work - (never get called)
        # not sure why so just do after 0
        dict set _channels($chan) WriteEventPosted \
            [after 0 [namespace current]::_post_write_event_callback $chan]
    }
}

namespace eval twapi::tls {
    namespace ensemble create -subcommands {
        initialize finalize blocking watch read write configure cget cgetall
    }
}
