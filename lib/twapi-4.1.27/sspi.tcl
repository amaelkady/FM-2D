#
# Copyright (c) 2007-2013, Ashok P. Nadkarni
# All rights reserved.
#
# See the file LICENSE for license

namespace eval twapi {


    # Holds SSPI security contexts indexed by a handle
    # Each element is a dict with the following keys:
    #   State - state of the security context - see sspi_step
    #   Handle - the Win32 SecHandle for the context
    #   Input - Pending input from remote end to be passed in to
    #    SSPI provider (only valid for streams)
    #   Output - list of SecBuffers that contain data to be sent
    #    to remote end during a SSPI negotiation
    #   Inattr - requested context attributes
    #   Outattr - context attributes returned from service provider
    #    (currently not used)
    #   Expiration - time when context will expire
    #   Ctxtype - client, server
    #   Target -
    #   Datarep - data representation format
    #   Credentials - handle for credentials to pass to sspi provider
    variable _sspi_state
    array set _sspi_state {}

    proc* _init_security_context_syms {} {
        variable _server_security_context_syms
        variable _client_security_context_syms
        variable _secpkg_capability_syms


        # Symbols used for mapping server security context flags
        array set _server_security_context_syms {
            confidentiality      0x10
            connection           0x800
            delegate             0x1
            extendederror        0x8000
            identify             0x80000
            integrity            0x20000
            mutualauth           0x2
            replaydetect         0x4
            sequencedetect       0x8
            stream               0x10000
        }

        # Symbols used for mapping client security context flags
        array set _client_security_context_syms {
            confidentiality      0x10
            connection           0x800
            delegate             0x1
            extendederror        0x4000
            identify             0x20000
            integrity            0x10000
            manualvalidation     0x80000
            mutualauth           0x2
            replaydetect         0x4
            sequencedetect       0x8
            stream               0x8000
            usesessionkey        0x20
            usesuppliedcreds     0x80
        }

        # Symbols used for mapping security package capabilities
        array set _secpkg_capability_syms {
            integrity                   0x00000001
            privacy                     0x00000002
            tokenonly                  0x00000004
            datagram                    0x00000008
            connection                  0x00000010
            multirequired              0x00000020
            clientonly                 0x00000040
            extendederror              0x00000080
            impersonation               0x00000100
            acceptwin32name           0x00000200
            stream                      0x00000400
            negotiable                  0x00000800
            gsscompatible              0x00001000
            logon                       0x00002000
            asciibuffers               0x00004000
            fragment                    0x00008000
            mutualauth                 0x00010000
            delegation                  0x00020000
            readonlywithchecksum      0x00040000
            restrictedtokens           0x00080000
            negoextender               0x00100000
            negotiable2                 0x00200000
            appcontainerpassthrough  0x00400000
            appcontainerchecks  0x00800000
        }
    } {}
}

# Return list of security packages
proc twapi::sspi_enumerate_packages {args} {
    set pkgs [EnumerateSecurityPackages]
    if {[llength $args] == 0} {
        set names [list ]
        foreach pkg $pkgs {
            lappend names [kl_get $pkg Name]
        }
        return $names
    }

    # TBD - why is this hyphenated ?
    array set opts [parseargs args {
        all capabilities version rpcid maxtokensize name comment
    } -maxleftover 0 -hyphenated]

    _init_security_context_syms
    variable _secpkg_capability_syms
    set retdata {}
    foreach pkg $pkgs {
        set rec {}
        if {$opts(-all) || $opts(-capabilities)} {
            lappend rec -capabilities [_make_symbolic_bitmask [kl_get $pkg fCapabilities] _secpkg_capability_syms]
        }
        foreach {opt field} {-version wVersion -rpcid wRPCID -maxtokensize cbMaxToken -name Name -comment Comment} {
            if {$opts(-all) || $opts($opt)} {
                lappend rec $opt [kl_get $pkg $field]
            }
        }
        dict set recdata [kl_get $pkg Name] $rec
    }
    return $recdata
}

proc twapi::sspi_schannel_credentials args {
    # TBD - do all these options work ? Check before documenting
    # since they seem to be duplicated in InitializeSecurityContext
    parseargs args {
        certificates.arg
        {rootstore.arg NULL}
        sessionlifespan.int
        usedefaultclientcert.bool
        {disablereconnects.bool 0 0x80}
        {revocationcheck.arg none {full endonly excluderoot none}}
        {ignoreerrorrevocationoffline.bool 0 0x1000}
        {ignoreerrornorevocationcheck.bool 0 0x800}
        {validateservercert.bool 1}
        cipherstrength.arg
        protocols.arg
    } -setvars -nulldefault -maxleftover 0

    set flags [expr {$disablereconnects | $ignoreerrornorevocationcheck | $ignoreerrorrevocationoffline}]
    incr flags [dict get {
        none 0 full 0x200 excluderoot 0x400 endonly 0x100
    } $revocationcheck]
        
    if {$validateservercert} {
        incr flags 0x20;        # SCH_CRED_AUTO_CRED_VALIDATION
    } else {
        incr flags 0x8;         # SCH_CRED_MANUAL_CRED_VALIDATION
    }
    if {$usedefaultclientcert} {
        incr flags 0x40;         # SCH_CRED_USE_DEFAULT_CREDS
    } else {
        incr flags 0x10;         # SCH_CRED_NO_DEFAULT_CREDS 
    }

    set protbits 0
    foreach prot $protocols {
        set protbits [expr {
                            $protbits | [dict! {
                                ssl2 0xc ssl3 0x30 tls1 0xc0 tls1.1 0x300 tls1.2 0xc00
                            } $prot]
                        }]
    }

    switch [llength $cipherstrength] {
        0 { set minbits 0 ; set maxbits 0 }
        1 { set minbits [lindex $cipherstrength 0] ; set maxbits $minbits }
        2 {
            set minbits [lindex $cipherstrength 0]
            set maxbits [lindex $cipherstrength 1]
        }
        default {
            error "Invalid value '$cipherstrength' for option -cipherstrength"
        }
    }

    # 4 -> SCHANNEL_CRED_VERSION
    return [list 4 $certificates $rootstore {} {} $protbits $minbits $maxbits $sessionlifespan $flags 0]
}

proc twapi::sspi_winnt_identity_credentials {user domain password} {
    return [list $user $domain $password]
}

proc twapi::sspi_acquire_credentials {args} {
    parseargs args {
        {credentials.arg {}}
        principal.arg
        {package.arg NTLM}
        {role.arg both {client server inbound outbound both}}
        getexpiration
    } -maxleftover 0 -setvars -nulldefault

    set creds [AcquireCredentialsHandle $principal \
                   [dict* {
                       unisp {Microsoft Unified Security Protocol Provider}
                       ssl {Microsoft Unified Security Protocol Provider}
                       tls {Microsoft Unified Security Protocol Provider}
                   } $package] \
                   [kl_get {inbound 1 server 1 outbound 2 client 2 both 3} $role] \
                   "" $credentials]

    if {$getexpiration} {
        return [kl_create2 {-handle -expiration} $creds]
    } else {
        return [lindex $creds 0]
    }
}

# Frees credentials
proc twapi::sspi_free_credentials {cred} {
    FreeCredentialsHandle $cred
}

# Return a client context
proc twapi::sspi_client_context {cred args} {
    _init_security_context_syms
    variable _client_security_context_syms

    parseargs args {
        target.arg
        {datarep.arg network {native network}}
        confidentiality.bool
        connection.bool
        delegate.bool
        extendederror.bool
        identify.bool
        integrity.bool
        manualvalidation.bool
        mutualauth.bool
        replaydetect.bool
        sequencedetect.bool
        stream.bool
        usesessionkey.bool
        usesuppliedcreds.bool
    } -maxleftover 0 -nulldefault -setvars

    set context_flags 0
    foreach {opt flag} [array get _client_security_context_syms] {
        if {[set $opt]} {
            set context_flags [expr {$context_flags | $flag}]
        }
    }

    set drep [kl_get {native 0x10 network 0} $datarep]
    return [_construct_sspi_security_context \
                sspiclient#[TwapiId] \
                [InitializeSecurityContext \
                     $cred \
                     "" \
                     $target \
                     $context_flags \
                     0 \
                     $drep \
                     [list ] \
                     0] \
                client \
                $context_flags \
                $target \
                $cred \
                $drep \
               ]
}

# Delete a security context
proc twapi::sspi_delete_context {ctx} {
    variable _sspi_state
    set h [_sspi_context_handle $ctx]
    if {[llength $h]} {
        DeleteSecurityContext $h
    }
    unset _sspi_state($ctx)
}

# Shuts down a security context in orderly fashion
# Caller should start sspi_step
proc twapi::sspi_shutdown_context {ctx} {
    variable _sspi_state

    _sspi_context_handle $ctx;  # Verify handle
    dict with _sspi_state($ctx) {
        switch -nocase -- [lindex [QueryContextAttributes $Handle 10] 4] {
            schannel - 
            "Microsoft Unified Security Protocol Provider" {}
            default { return }
        }

        # Signal to security provider we want to shutdown
        Twapi_ApplyControlToken_SCHANNEL_SHUTDOWN $Handle

        if {$Ctxtype eq "client"} {
            set rawctx [InitializeSecurityContext \
                            $Credentials \
                            $Handle \
                            $Target \
                            $Inattr \
                            0 \
                            $Datarep \
                            [list ] \
                            0]
        } else {
            set rawctx [AcceptSecurityContext \
                            $Credentials \
                            $Handle \
                            [list ] \
                            $Inattr \
                            $Datarep]
        }
        lassign $rawctx State Handle out Outattr Expiration extra
        if {$State in {ok expired}} {
            return [list done [_gather_secbuf_data $out]]
        } else {
            return [list continue [_gather_secbuf_data $out]]
        }
    }
}

# Take the next step in an SSPI negotiation
# Returns
#   {done data extradata}
#   {continue data}
#   {expired data}
proc twapi::sspi_step {ctx {received ""}} {
    variable _sspi_state

    _sspi_validate_handle $ctx

    dict with _sspi_state($ctx) {
        # Note the dictionary content variables are
        #   State, Handle, Output, Outattr, Expiration,
        #   Ctxtype, Inattr, Target, Datarep, Credentials

        # Append new input to existing input
        append Input $received
        switch -exact -- $State {
            ok {
                set data [_gather_secbuf_data $Output]
                set Output {}

                # $Input at this point contains left over input that is
                # actually application data (streaming case).
                # Application should pass this to decrypt commands
                return [list done $data $Input[set Input ""]]
            }
            continue {
                # Continue with the negotiation
                if {[string length $Input] != 0} {
                    # Pass in received data to SSPI.
                    # Most providers take only the first buffer
                    # but SChannel/UNISP need the second. Since
                    # others don't seem to mind the second buffer
                    # we always always include it
                    # 2 -> SECBUFFER_TOKEN, 0 -> SECBUFFER_EMPTY
                    set inbuflist [list [list 2 $Input] [list 0]]
                    if {$Ctxtype eq "client"} {
                        set rawctx [InitializeSecurityContext \
                                        $Credentials \
                                        $Handle \
                                        $Target \
                                        $Inattr \
                                        0 \
                                        $Datarep \
                                        $inbuflist \
                                        0]
                    } else {
                        set rawctx [AcceptSecurityContext \
                                        $Credentials \
                                        $Handle \
                                        $inbuflist \
                                        $Inattr \
                                        $Datarep]
                    }
                    lassign $rawctx State Handle out Outattr Expiration extra
                    lappend Output {*}$out
                    set Input $extra
                    # Will recurse at proc end
                } else {
                    # There was no received data. Return any data
                    # to be sent to remote end
                    set data [_gather_secbuf_data $Output]
                    set Output {}
                    return [list continue $data ""]
                }
            }
            incomplete_message {
                # Caller has to get more data from remote end
                set State continue
                return [list continue "" ""]
            }
            expired {
                # Remote end closed in middle of negotiation
                return [list disconnected "" ""]
            }
            incomplete_credentials -
            complete -
            complete_and_continue {
                # TBD
                error "State $State handling not implemented."
            }
        }
    }

    # Recurse to return next state.
    # This has to be OUTSIDE the [dict with] above else it will not
    # see the updated values
    return [sspi_step $ctx]
}

# Return a server context
proc twapi::sspi_server_context {cred clientdata args} {
    _init_security_context_syms
    variable _server_security_context_syms

    parseargs args {
        {datarep.arg network {native network}}
        confidentiality.bool
        connection.bool
        delegate.bool
        extendederror.bool
        identify.bool
        integrity.bool
        mutualauth.bool
        replaydetect.bool
        sequencedetect.bool
        stream.bool
    } -maxleftover 0 -nulldefault -setvars

    set context_flags 0
    foreach {opt flag} [array get _server_security_context_syms] {
        if {[set $opt]} {
            set context_flags [expr {$context_flags | $flag}]
        }
    }

    set drep [kl_get {native 0x10 network 0} $datarep]
    return [_construct_sspi_security_context \
                sspiserver#[TwapiId] \
                [AcceptSecurityContext \
                     $cred \
                     "" \
                     [list [list 2 $clientdata]] \
                     $context_flags \
                     $drep] \
                server \
                $context_flags \
                "" \
                $cred \
                $drep \
               ]
}


# Get the security context flags after completion of request
proc ::twapi::sspi_context_features {ctx} {
    variable _sspi_state

    set ctxh [_sspi_context_handle $ctx]

    _init_security_context_syms

    # We could directly look in the context itself but intead we make
    # an explicit call, just in case they change after initial setup
    set flags [QueryContextAttributes $ctxh 14]

        # Mapping of symbols depends on whether it is a client or server
        # context
    if {[dict get $_sspi_state($ctx) Ctxtype] eq "client"} {
        upvar 0 [namespace current]::_client_security_context_syms syms
    } else {
        upvar 0 [namespace current]::_server_security_context_syms syms
    }

    set result [list -raw $flags]
    foreach {sym flag} [array get syms] {
        lappend result -$sym [expr {($flag & $flags) != 0}]
    }

    return $result
}

# Get the user name for a security context
proc twapi::sspi_context_username {ctx} {
    return [QueryContextAttributes [_sspi_context_handle $ctx] 1]
}

# Get the field size information for a security context
# TBD - update for SSL
proc twapi::sspi_context_sizes {ctx} {
    set sizes [QueryContextAttributes [_sspi_context_handle $ctx] 0]
    return [twine {-maxtoken -maxsig -blocksize -trailersize} $sizes]
}

proc twapi::sspi_remote_cert {ctx} {
    return [QueryContextAttributes [_sspi_context_handle $ctx] 0x53]
}

proc twapi::sspi_local_cert {ctx} {
    return [QueryContextAttributes [_sspi_context_handle $ctx] 0x54]
}

proc twapi::sspi_issuers_accepted_by_peer {ctx} {
    return [QueryContextAttributes [_sspi_context_handle $ctx] 0x59]
}

# Returns a signature
proc twapi::sspi_sign {ctx data args} {
    parseargs args {
        {seqnum.int 0}
        {qop.int 0}
    } -maxleftover 0 -setvars

    return [MakeSignature \
                [_sspi_context_handle $ctx] \
                $qop \
                $data \
                $seqnum]
}

# Verify signature
proc twapi::sspi_verify_signature {ctx sig data args} {
    parseargs args {
        {seqnum.int 0}
    } -maxleftover 0 -setvars

    # Buffer type 2 - Token, 1- Data
    return [VerifySignature \
                [_sspi_context_handle $ctx] \
                [list [list 2 $sig] [list 1 $data]] \
                $seqnum]
}

# Encrypts a data as per a context
# Returns {securitytrailer encrypteddata padding}
# TBD - docment options
proc twapi::sspi_encrypt {ctx data args} {
    parseargs args {
        {seqnum.int 0}
        {qop.int 0}
    } -maxleftover 0 -setvars

    return [EncryptMessage \
                [_sspi_context_handle $ctx] \
                $qop \
                $data \
                $seqnum]
}

proc twapi::sspi_encrypt_stream {ctx data args} {
    variable _sspi_state
    
    set h [_sspi_context_handle $ctx]

    # TBD - docment options
    parseargs args {
        {qop.int 0}
    } -maxleftover 0 -setvars

    set enc ""
    while {[string length $data]} {
        lassign [EncryptStream $h $qop $data] fragment data
        lappend enc $fragment
    }

    return [join $enc ""]
}

# chan must be in binary mode
proc twapi::sspi_encrypt_and_write {ctx data chan args} {
    variable _sspi_state
    
    set h [_sspi_context_handle $ctx]

    parseargs args {
        {qop.int 0}
        {flush.bool 1}
    } -maxleftover 0 -setvars

    while {[string length $data]} {
        lassign [EncryptStream $h $qop $data] fragment data
        puts -nonewline $chan $fragment
    }

    if {$flush} {
        chan flush $chan
    }
}


# Decrypts a message
# TBD - why does this not return a status like sspi_decrypt_stream ?
proc twapi::sspi_decrypt {ctx sig data padding args} {
    variable _sspi_state
    _sspi_validate_handle $ctx

    # TBD - document options
    parseargs args {
        {seqnum.int 0}
    } -maxleftover 0 -setvars

    # Buffer type 2 - Token, 1- Data, 9 - padding
    set decrypted [DecryptMessage \
                       [dict get $_sspi_state($ctx) Handle] \
                       [list [list 2 $sig] [list 1 $data] [list 9 $padding]] \
                       $seqnum]
    set plaintext {}
    # Pick out only the data buffers, ignoring pad buffers and signature
    # Optimize copies by keeping as a list so in the common case of a 
    # single buffer can return it as is. Multiple buffers are expensive
    # because Tcl will shimmer each byte array into a list and then
    # incur additional copies during joining
    foreach buf $decrypted {
        # SECBUFFER_DATA -> 1
        if {[lindex $buf 0] == 1} {
            lappend plaintext [lindex $buf 1]
        }
    }

    if {[llength $plaintext] < 2} {
        return [lindex $plaintext 0]
    } else {
        return [join $plaintext ""]
    }
}

# Decrypts a stream
proc twapi::sspi_decrypt_stream {ctx data} {
    variable _sspi_state
    set hctx [_sspi_context_handle $ctx]

    # SSL decryption is done in max size chunks.
    # We will loop collecting as much data as possible. Collecting
    # as a list and joining at end minimizes internal byte copies
    set plaintext {}
    lassign [DecryptStream $hctx [dict get $_sspi_state($ctx) Input] $data] status decrypted extra
    lappend plaintext $decrypted
    
    # TBD - handle renegotiate status
    while {$status eq "ok" && [string length $extra]} {
        # See if additional data and loop again
        lassign [DecryptStream $hctx $extra] status decrypted extra
        lappend plaintext $decrypted
    }

    dict set _sspi_state($ctx) Input $extra
    if {$status eq "incomplete_message"} {
        set status ok
    }
    return [list $status [join $plaintext ""]]
}


################################################################
# Utility procs


# Construct a high level SSPI security context structure
# rawctx is context as returned from C level code
proc twapi::_construct_sspi_security_context {id rawctx ctxtype inattr target credentials datarep} {
    variable _sspi_state
    
    set _sspi_state($id) [dict merge [dict create Ctxtype $ctxtype \
                                          Inattr $inattr \
                                          Target $target \
                                          Datarep $datarep \
                                          Credentials $credentials] \
                              [twine \
                                   {State Handle Output Outattr Expiration Input} \
                                   $rawctx]]

    return $id
}

proc twapi::_sspi_validate_handle {ctx} {
    variable _sspi_state

    if {![info exists _sspi_state($ctx)]} {
        badargs! "Invalid SSPI security context handle $ctx" 3
    }
}

proc twapi::_sspi_context_handle {ctx} {
    variable _sspi_state

    if {![info exists _sspi_state($ctx)]} {
        badargs! "Invalid SSPI security context handle $ctx" 3
    }

    return [dict get $_sspi_state($ctx) Handle]
}

proc twapi::_gather_secbuf_data {bufs} {
    if {[llength $bufs] == 1} {
        return [lindex [lindex $bufs 0] 1]
    } else {
        set data {}
        foreach buf $bufs {
            # First element is buffer type, which we do not care
            # Second element is actual data
            lappend data [lindex $buf 1]
        }
        return [join $data {}]
    }
}

if {0} {
    TBD - delete
    set cred [sspi_acquire_credentials -package ssl -role client]
    set client [sspi_client_context $cred -stream 1 -manualvalidation 1]
    set out [sspi_step $client]
    set so [socket 192.168.1.127 443]
    fconfigure $so -blocking 0 -buffering none -translation binary
    puts -nonewline $so [lindex $out 1]
    
    set data [read $so]
    set out [sspi_step $client $data]
    puts -nonewline $so [lindex $out 1]

    set data [read $so]
    set out [sspi_step $client $data]
    
    set out [sspi_encrypt_stream $client "GET / HTTP/1.0\r\n\r\n"]
    puts -nonewline $so $out
    set data [read $so]
    set d [sspi_decrypt_stream $client $data]
    sspi_shutdown_context $client
    close $so ; sspi_free_credentials $cred ; sspi_free_context $client
    sspi_context_free $client
    sspi_shutdown_context $client

    # INTERNAL client-server
    proc 'sslsetup {} {
        uplevel #0 {
            twapi
            source ../tests/testutil.tcl
            set ca [make_test_certs]
            set cacert [cert_store_find_certificate $ca subject_substring twapitestca]
            set scert [cert_store_find_certificate $ca subject_substring twapitestserver]
            set scred [sspi_acquire_credentials -package ssl -role server -credentials [sspi_schannel_credentials -certificates [list $scert]]]
            set ccert [cert_store_find_certificate $ca subject_substring twapitestclient]
            set ccred [sspi_acquire_credentials -package ssl -role client -credentials [sspi_schannel_credentials]]
            set cctx [sspi_client_context $ccred -stream 1 -manualvalidation 1]
            set cstep [sspi_step $cctx]

            set sctx [sspi_server_context $scred [lindex $cstep 1] -stream 1]
            set sstep [sspi_step $sctx]
            set cstep [sspi_step $cctx [lindex $sstep 1]]
            set sstep [sspi_step $sctx [lindex $cstep 1]]
            set cstep [sspi_step $cctx [lindex $sstep 1]]
        }
    }
    set out [sspi_encrypt_stream $cctx "This is a test"]

    sspi_decrypt_stream $sctx $out
    sspi_decrypt_stream $sctx ""
    set out [sspi_encrypt_stream $sctx "This is a testx"]
    sspi_decrypt_stream $cctx $out

    proc 'ccred {} {
        set store [cert_system_store_open twapitest user]
        set ccert [cert_store_find_certificate $store subject_substring twapitestclient]
        set ccred [sspi_acquire_credentials -package ssl -role client -credentials [sspi_schannel_credentials -certificates [list $ccert]]]
        cert_store_release $store
        cert_release $ccert
        return $ccred
    }

}
