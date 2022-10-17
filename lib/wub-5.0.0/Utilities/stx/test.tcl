proc char {text} {
    set text [string map {
	\[\[ \x84
	\]\] \x85
    } $text]

    variable refs
    while {[regexp -- {\[[^]]+\]} $text ref]} {
	set index [array size refs] 
	puts stderr "$index: $ref"
	set refs($index) $ref
	regsub -- {\[[^]]+\]} $text "\x86$index" text
    }
    return $text
}
