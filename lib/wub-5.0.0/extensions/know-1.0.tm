package provide know 1.0

proc know {cond body} {
    if {![info complete $body]} {error "incomplete command(s) $body"}
    proc ::unknown {args} [string map [list @c@ $cond @b@ $body] {
        if {![catch {expr {@c@}} res eo] && $res} {
            return [eval {@b@}]
	}
    }][info body ::unknown]
} ;# RS
