package provide captcha 1.0

proc captcha {captcha args} {
    if {[llength $args] == 1} {
	set args [lindex $args 0]
    }
    array set opts {file captcha.jpg wave 5x50 swirl 50 size 300x240}
    array set opts $args
    lassign [split $opts(size) x] opt(width) opt(height)
    if {![info exists ::captcha_lines]} {
	for {set i 7} {$i < 100} {incr i 7} {
	    lappend x "M 5,$i L $opt(width),$i"
	}
	set ::captcha_lines [join $x]
    }
    catch {file delete $opts(file)}
    exec convert -background lightblue -fill blue -font Bookman-DemiItalic -size $opts(size) -gravity center label:$captcha -trim -fill yellow -draw [list path '$::captcha_lines'] -wave $opts(wave) -swirl $opts(swirl) $opts(file)
}
#exec convert -size 200x120 xc:lightblue -font Bookman-DemiItalic -pointsize 32 -fill blue -draw [list text 10,20 '$text'] -fill yellow -draw [list path 'M 5,5 L 140,5 M 5,10 L 140,10 M 5,15 L 140,15'] -trim -wave 6x70 -swirl 30 captcha.jpg

if {[info exists argv0] && ($argv0 eq [info script])} {
    captcha DFGHI ;#JKLMNOP
    #ABCF
    #D G
}
