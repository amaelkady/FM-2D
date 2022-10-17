#
# Tcl package index file
#
# Note sqlite*3* init specifically
#
package ifneeded sqlite3 3.20.1 \
    [list load [file join $dir sqlite3201.dll] Sqlite3]
