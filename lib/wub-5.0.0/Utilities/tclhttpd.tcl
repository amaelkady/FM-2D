# some conformance with tclhttpd APIs
package provide tclhttpd 1.0

proc Doc_Dynamic {} {
    upvar 1 req req
    dict set req -dynamic 1
}
proc Doc_Static {} {
    upvar 1 req req
    dict set req -dynamic 0
}
