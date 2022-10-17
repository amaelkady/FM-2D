package provide memoize 1.0

# call memoize at the beginning of another proc that is expensive to run
# and it will save the return value so it doesn't need to be recomputed.
# This makes use of [info level] to examining the stack as well as 
# [return -code] to cause the calling proc to return.
# from Richard Suchenwirth, http://mini.net/tcl/memoizing
proc memoize {} {
    global memo
    if {[info exists memo()]
	&& ([array size memo] > $memo())
    } {
	# limit size of memo array
	set max $memo()
	unset memo
	set memo() $max
	return
    }

    set cmd [info level -1]
    if {[info level] > 2 && [lindex [info level -2] 0] eq "memoize"} return
    if { ![info exists memo($cmd)]} {set memo($cmd) [eval $cmd]}
    return -code return $memo($cmd)
}
set memo() 100000	;# set an arbitrary (large) size limit on memoizing
