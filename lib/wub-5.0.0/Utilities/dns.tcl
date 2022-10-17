# Terry Dawson's "very educated guess" algorithm:
#
# You can reasonably assume that the 'local' DNS server is (one of) 
# the DNS server(s) serving the local domain.
#
# So iff the local hostname is set correctly you could use:
# gethostname(), identify the domain component,
# and then undertake a DNS request for NS records for that domain.
#
# That should provide you with a list of usable 'local' DNS servers."
# It won't help you find topologically local DNS proxies for example,
# but it will help you find usable DNS servers.

package require dns
#package require udp

proc doit {addr {server localhost}} {
    set token [::dns::resolve $addr]
    if {[::dns::wait $token] eq "ok"} {
	puts [::dns::result $token]
    } else {
	puts [::dns::error $token]
    }
    ::dns::cleanup $token
}

proc findDNS {} {
    set host [info hostname]
}

doit [lindex $argv 0]
