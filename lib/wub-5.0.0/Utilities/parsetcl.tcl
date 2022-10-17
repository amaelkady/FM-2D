##
## This is file `parsetcl.tcl',
## generated with the docstrip utility.
##
## The original source files were:
##
## parsetcl.dtx  (with options: `pkg')
## 
## In other words:
##  ***************************************
##  * This Source is not the True Source. *
##  ***************************************
## The True Source is parsetcl.dtx in (at the moment)
##   http://abel.math.umu.se/~lars/tcl/
## 
## This file is dual-licenced under the Tcl licence (BSD-style) and
## the LaTeX Project Public License (LPPL). It is preferred that you
## try to obey the distribution and modification conditions of the LPPL
## even if you choose to use and redistribute this file under the terms
## of the Tcl licence. The latest version of the LPPL is in
##    http://www.latex-project.org/lppl.txt
## and version 1.2 or later is part of all distributions of LaTeX
## version 1999/12/01 or later.
## 
namespace eval ::parsetcl {}
package require Tcl 8.4
package provide parsetcl 0.2
proc ::parsetcl::flush_whitespace {script index_var cmdsep} {
   upvar 1 $index_var index
   if {[
      if {$cmdsep} then {
        regexp -start $index -- {\A([ \t-\r;]|\\\n)+} $script match
      } else {
        regexp -start $index -- {\A([ \t\v\f\r]|\\\n)+} $script match
      }
   ]} then {
      incr index [string length $match]
      return [string length $match]
   } else {
      return 0
   }
}
proc ::parsetcl::parse_command {script index_var nested} {
   upvar 1 $index_var index
   flush_whitespace $script index 1
   switch -- "[string index $script $index]$nested" {#0} - {#1} {
      regexp -start $index -indices -- {\A#([^\n\\]|\\.)*(\\$)?}\
        $script interval
      incr index
      regsub -all -- {\\\n[ \t]*}\
        [string range $script $index [lindex $interval 1]]\
        { } text
      set index [expr {[lindex $interval 1] + 1}]
      return [list Nc $interval $text]
   } 0 - 1 - \]1 {
      return [list Np "" ""]
   }
   set res [list Cd [list $index ""] ""]
   set next [parse_word $script index $nested]
   while {[lindex $next 0] ne "Np"} {
      lappend res $next
      set next [parse_word $script index $nested]
   }
   lset res 1 1 [lindex $res end 1 1]
   set res2 [list Ce [lindex $res 1] ""]
   set item [list Cp]
   foreach subtree [lrange $res 3 end] {
      if {[lindex $subtree 0] ne "Cx"} then {
         if {[llength $item]<2} then {
            lappend item [lindex $subtree 1] ""
         }
         lappend item $subtree
         lset item 1 1 [lindex $subtree 1 1]
      } else {
         if {[llength $item]>1} then {lappend res2 $item}
         lappend res2 $subtree
         set item [list Cr]
      }
   }
   if {[llength $res2]<4} then {
      return $res
   } else {
      if {[llength $item]>1} then {lappend res2 $item}
      return $res2
   }
}
proc ::parsetcl::basic_parse_script {script} {
   set index 0
   set res [list Rs [list $index ""] ""]
   while {[lindex [set next [parse_command $script index 0]] 0] ne "Np"} {
      lappend res $next
   }
   incr index -1
   lset res 1 1 $index
   return $res
}
proc ::parsetcl::parse_word {script index_var nested} {
   upvar 1 $index_var index
   switch -- [string index $script $index] \{ {
      if {$nested ? [
         regexp -start $index -- {(?x)
           \A \{(expand|\*)\} ( [^ \t-\r;\\\]] | \\[^\n] )
         } $script
      ] : [
         regexp -start $index -- {(?x)
           \A \{(expand|\*)\} ( [^ \t-\r;\\]   | \\[^\n] )
         } $script
      ]} then {
         set res [list Cx [list $index ""] ""]
         set index [string first \} $script $index]
         incr index
         switch -- [string index $script $index] \{ {
            lappend res [parse_braced_word $script index $nested]
         } \" {
            lappend res [parse_quoted_word $script index $nested]
         } default {
            lappend res [parse_raw_word $script index $nested]
         }
         lset res 1 1 [lindex $res end 1 1]
         return $res
      }
      parse_braced_word $script index $nested
   } \" {
      parse_quoted_word $script index $nested
   } "" - \; - \n {
      list Np "" ""
   } \] {
      if {$nested} then {
         list Np "" ""
      } else {
         parse_raw_word $script index $nested
      }
   } default {
      parse_raw_word $script index $nested
   }
}
proc ::parsetcl::parse_braced_word {script index_var nested} {
   upvar 1 $index_var index
   set res [list Lb [list $index ""]]
   set depth 1
   set text ""
   incr index
   while {$depth>0} {
      regexp -start $index -- {\A([^{}\\]|\\[^\n])*} $script match
      append text $match
      incr index [string length $match]
      switch -- [string index $script $index] \{ {
         append text \{
         incr depth
         incr index
      } \} {
         if {$depth > 1} then {append text \}}
         incr depth -1
         incr index
      } \\ {
         if {[regexp -start $index -- {\A\\\n[ \t]*} $script match]}\
         then {
            incr index [string length $match]
            append text { }
         } else {
            append text \\
            break
         }
      } "" {
         break
      }
   }
   if {$depth>0} then {
      lset res 1 1 $index
      lappend res $text [list Ne [list "" $index] {missing close-brace}]
      lset res 3 1 0 [incr index]
      return $res
   }
   lset res 1 1 [expr {$index - 1}]
   lappend res $text
   if {$nested == 2} then {return $res}
   if {[flush_whitespace $script index 0]} then {return $res}
   switch -- [string index $script $index] \n - {} {
      return $res
   } \; {
      if {$nested >= 0} then {return $res}
   } \] {
      if {$nested >= 1} then {return $res}
   }
   lappend res [list Ne [list $index [expr {$index - 1}]]\
     {missing space after close-brace}]
   return $res
}
proc ::parsetcl::parse_quoted_word {script index_var nested} {
   upvar 1 $index_var index
   set res [list Lq [list $index ""] ""]
   set text ""
   incr index
   while {1} {
      switch -- [string index $script $index] \\ {
         lappend res [parse_backslash $script index]
         append text [lindex $res end 2]
      } \$ {
         lappend res [parse_dollar $script index]
         lset res 0 Mq
      } \[ {
         lappend res [parse_bracket $script index]
         lset res 0 Mq
      } \" {
         incr index
         break
      } "" {
         lappend res [list Ne [list $index [expr {$index - 1}]]\
           {missing close-quote}]
         break
      } default {
         regexp -start $index -- {[^\\$\["]*} $script match
         set t $index
         incr index [string length $match]
         lappend res [list Lr [list $t [expr {$index - 1}]] $match]
         append text $match
      }
   }
   lset res 1 1 [expr {$index - 1}]
   if {[lindex $res 0] eq "Lq"} then {
      lset res 2 $text
      if {[llength $res] == 4 && [lindex $res 3 0] eq "Lr"} then {
         set res [lrange $res 0 2]
      }
   }
   if {$nested == 2} then {return $res}
   if {[flush_whitespace $script index 0]} then {return $res}
   switch -- [string index $script $index] \n - {} {
      return $res
   } \; {
      if {$nested >= 0} then {return $res}
   } \] {
      if {$nested >= 1} then {return $res}
   }
   lappend res [list Ne [list $index [expr {$index - 1}]]\
     {missing space after close-quote}]
   return $res
}
proc ::parsetcl::parse_raw_word {script index_var nested} {
   upvar 1 $index_var index
   set res [list]
   set type Lr
   set interval [list $index]
   set text ""
   while {1} {
      switch -- [string index $script $index] \\ {
         if {[string index $script [expr {$index+1}]] eq "\n"} then {
            break
         }
         lappend res [parse_backslash $script index]
         append text [lindex $res end 2]
         continue
      } \$ {
         lappend res [parse_dollar $script index]
         set type Mr
         continue
      } \[ {
         lappend res [parse_bracket $script index]
         set type Mr
         continue
      } \t - \n - \v - \f - \r - " " - \; - "" {
         break
      }
      if {$nested} then {
         if {![
            regexp -start $index -- {\A[^\\$\[\]\t-\r ;]+} $script match
         ]} then {break}
      } else {
         regexp -start $index -- {\A[^\\$\[\t-\r ;]+} $script match
      }
      set t $index
      incr index [string length $match]
      lappend res [list Lr [list $t [expr {$index - 1}]] $match]
      append text $match
   }
   if {[llength $res]==1} then {
      set res [lindex $res 0]
   } else {
      lappend interval [expr {$index - 1}]
      if {$type ne "Lr"} then {set text ""}
      set res [linsert $res 0 $type $interval $text]
   }
   flush_whitespace $script index 0
   return $res
}
proc ::parsetcl::parse_backslash {script index_var} {
   upvar 1 $index_var index
   set start $index
   incr index
   set ch [string index $script $index]
   set res [list Lr [list $index $index] $ch]
   switch -- $ch a {
      set res [list Sb [list $start $index] \a $res]
   } b {
      set res [list Sb [list $start $index] \b $res]
   } f {
      set res [list Sb [list $start $index] \f $res]
   } n {
      set res [list Sb [list $start $index] \n $res]
   } r {
      set res [list Sb [list $start $index] \r $res]
   } t {
      set res [list Sb [list $start $index] \t $res]
   } v {
      set res [list Sb [list $start $index] \v $res]
   } x {
      if {[regexp -start [expr {$index + 1}] -- {\A[0-9A-Fa-f]+}\
        $script match]} then {
         scan [string range $match end-1 end] %x code
         incr index [string length $match]
         lset res 1 1 $index
         lset res 2 "x$match"
         set res [list Sb [list $start $index]\
           [format %c $code] $res]
      } else {
         set res [list Sb [list $start $index] x $res]
      }
   } u {
      if {[regexp -start [expr {$index + 1}] -- {\A[0-9A-Fa-f]{1,4}}\
        $script match]} then {
         scan $match %x code
         incr index [string length $match]
         lset res 1 1 $index
         lset res 2 "u$match"
         set res [list Sb [list $start $index]\
           [format %c $code] $res]
      } else {
         set res [list Sb [list $start $index] u $res]
      }
   } \n {
      regexp -start [expr {$index + 1}] -- {\A[ \t]*} $script match
      incr index [string length $match]
      lset res 1 1 $index
      lset res 2 "\n$match"
      set res [list Sb [list $start $index] " " $res]
   } "" {
      return [list Sb [list $start $start] \\]
   } default {
      if {[regexp -start $index -- {\A[0-7]{1,3}} $script match]} then {
         scan $match %o code
         incr index [expr {[string length $match]-1}]
         lset res 1 1 $index
         lset res 2 $match
         set res [list Sb [list $start $index] [format %c $code] $res]
      } else {
         set res [list Sb [list $start $index] $ch $res]
      }

   }
   incr index
   return $res
}
proc ::parsetcl::parse_bracket {script index_var} {
   upvar 1 $index_var index
   set res [list Sc [list $index ""] ""]
   incr index
   while {[lindex [set next [parse_command $script index 1]] 0] ne "Np"} {
      lappend res $next
   }
   if {[string index $script $index] eq "\]"} then {
      lset res 1 1 $index
      incr index
      return $res
   } else {
      lappend res [list Ne [list $index [expr {$index-1}]]\
        {missing close-bracket}]
      lset res 1 1 [expr {$index-1}]
      return $res
   }
}
set parsetcl::varname_RE {\A(\w|::)+}
proc ::parsetcl::parse_dollar {script index_var} {
   upvar 1 $index_var index
   set res [list "" [list $index ""] ""]
   incr index
   if {[string index $script $index] eq "\{"} then {
      lset res 0 Sv
      set end [string first \} $script $index]
      if {$end<0} then {
         set end [expr {[string length $script] - 1}]
         lappend res [list Lb [list $index $end]\
           [string range $script [expr {$index + 1}] end]]\
           [list Ne [list [expr {$end+1}] $end]\
             {missing close-brace for variable name}]
      } else {
         lappend res [list Lb [list $index $end]\
           [string range $script [expr {$index + 1}] [expr {$end-1}]]]
      }
      lset res 1 1 $end
      set index [expr {$end + 1}]
      return $res
   }
   variable varname_RE
   if {![regexp -start $index -- $varname_RE $script match]} then {
      if {[string index $script $index] eq "("} then {
         set match ""
      } else {
         return [list Lr [list [lindex $res 1 0] [lindex $res 1 0]] \$]
      }
   }
   set t $index
   incr index [string length $match]
   lappend res [list Lr [list $t [expr {$index-1}]] $match]
   if {[string index $script $index] ne "("} then {
      lset res 0 Sv
      lset res 1 1 [lindex $res 3 1 1]
      return $res
   }
   lset res 0 Sa
   incr index
   set subres [list Lr [list $index ""] ""]
   lappend res ""
   set text ""
   while {1} {
      switch -- [string index $script $index] \\ {
         lappend subres [parse_backslash $script index]
         append text [lindex $subres end 2]
      } \$ {
         lappend subres [parse_dollar $script index]
         lset subres 0 Mr
      } \[ {
         lappend subres [parse_bracket $script index]
         lset subres 0 Mr
      } ) {
         lset subres 1 1 [expr {$index - 1}]
         break
      } "" {
         lappend res\
           [list Ne [list $index [incr index -1]] {missing )}]
         lset subres 1 1 $index
         break
      } default {
         regexp -start $index -- {[^\\$\[)]*} $script match
         set t $index
         incr index [string length $match]
         lappend subres [list Lr [list $t [expr {$index - 1}]] $match]
         append text $match
      }
   }
   if {[lindex $subres 0] eq "Lr"} then {lset subres 2 $text}
   if {[llength $subres] == 4} then {set subres [lindex $subres 3]}
   lset res 1 1 $index
   incr index
   lset res 4 $subres
   return $res
}
proc ::parsetcl::format_tree {tree base step} {
   set res $base
   append res \{ [lrange $tree 0 1] { }
   if {[regexp {[\n\r]} [lindex $tree 2]]} then {
      append res [string range [list "[lindex $tree 2]\{"] 0 end-2]
   } else {
      append res [lrange $tree 2 2]
   }
   if {[llength $tree]<=3} then {
      append res \}
      return $res
   } elseif {[llength $tree] == 4 &&\
     [string match {S[bv]} [lindex $tree 0]]} then {
      append res " " [format_tree [lindex $tree 3] "" ""] \}
      return $res
   }
   append res \n
   foreach subtree [lrange $tree 3 end] {
      append res [format_tree $subtree $base$step $step] \n
   }
   append res $base \}
}
proc ::parsetcl::offset_intervals {tree offset} {
   set res [lrange $tree 0 2]
   foreach i {0 1} {
      lset res 1 $i [expr {[lindex $res 1 $i] + $offset}]
   }
   foreach subtree [lrange $tree 3 end] {
      lappend res [offset_intervals $subtree $offset]
   }
   return $res
}
proc ::parsetcl::reparse_Lb_as_script {tree_var index parsed} {
   upvar 1 $tree_var tree
   set node [lindex $tree $index]
   switch -- [lindex $node 0] Lb - Lr - Lq {
      set base [expr {[lindex $node 1 0] + 1}]
      if {[lindex $node 0] eq "Lb"} then {
         set script [string range $parsed $base\
           [expr {[lindex $node 1 1] - 1}]]
      } else {
         set script [lindex $node 2]
      }
      lset tree $index\
        [offset_intervals [basic_parse_script $script] $base]
      if {[lindex $node 0] eq "Lb"} then {
         return 2
      } else {
         return 1
      }
   } default {
      return 0
   }
}
proc ::parsetcl::walk_tree {tree_var index_var args} {
   upvar 1 $tree_var tree $index_var idxL
   set idxL [list]
   set i 0
   while {$i>=0} {
      if {$i==0} then {
         uplevel 1 [list switch -regexp --\
           [lindex [lindex $tree $idxL] 0] $args]
         set i 3
      } elseif {$i < [llength [lindex $tree $idxL]]} then {
         lappend idxL $i
         set i 0
      } elseif {[llength $idxL]} then {
         set i [lindex $idxL end]
         set idxL [lrange $idxL 0 end-1]
         incr i
      } else {
         set i -1
      }
   }
}
proc ::parsetcl::simple_parse_script {script} {
   set tree [basic_parse_script $script]
   walk_tree tree indices {^Cd$} {
      switch -- [lindex [lindex $tree $indices] 3 2] if {
         for {set i 3} {$i < [llength [lindex $tree $indices]]}\
           {incr i} {
            switch -- [lindex [lindex $tree $indices] $i 2]\
              if - elseif {
               incr i
               reparse_Lb_as_Mb tree [linsert $indices end $i] $script
               continue
            } then - else {
               incr i
            }
            reparse_Lb_as_script tree [linsert $indices end $i]\
              $script
         }
      } while {
         reparse_Lb_as_Mb     tree [linsert $indices end 4] $script
         reparse_Lb_as_script tree [linsert $indices end 5] $script
      } for {
         reparse_Lb_as_script tree [linsert $indices end 4] $script
         reparse_Lb_as_Mb     tree [linsert $indices end 5] $script
         reparse_Lb_as_script tree [linsert $indices end 6] $script
         reparse_Lb_as_script tree [linsert $indices end 7] $script
      } foreach {
         reparse_Lb_as_script tree [linsert $indices end end] $script
      } catch {
         reparse_Lb_as_script tree [linsert $indices end 4] $script
      } proc {
         reparse_Lb_as_script tree [linsert $indices end 6] $script
      } expr {
         for {set i 4} {$i < [llength [lindex $tree $indices]]}\
           {incr i} {
            reparse_Lb_as_Mb tree [linsert $indices end $i] $script
         }
      }
   }
   return $tree
}
proc ::parsetcl::reinsert_indentation {tree script} {
   set nlL [regexp -all -inline -indices {\n\s*} $script]
   walk_tree tree where {^Rs$} - {^Sc$} {
      set newnode [lrange [lindex $tree $where] 0 2]
      set subtreeL [lrange [lindex $tree $where] 3 end]
      set first [lindex $newnode 1 0]
      set last [lindex $newnode 1 1]
      foreach interval $nlL {
         if {
           [lindex $interval 0] >= $first &&\
           [lindex $interval 1] <= $last
         } then {
            lappend subtreeL [list Ni $interval\
              [eval [linsert $interval 0 string range $script]]]
         }
      }
      set last -1
      foreach subtree [lsort -dictionary -index 1 $subtreeL] {
         if {[lindex $subtree 1 1] > $last} then {
            lappend newnode $subtree
            set last [lindex $subtree 1 1]
         }
      }
      lset tree $where $newnode
   }
   return $tree
}
proc ::parsetcl::parse_semiwords {string} {
   set res [list]
   set index 0
   while {$index < [string length $string]} {
      regexp -start $index -- {\A([^"\[\{$])*} $string match
      if {$match ne ""} then {
         lappend res [list Lr [list $index ?] $match]
         incr index [string length $match]
         lset res end 1 1 [expr {$index-1}]
         if {[
            regsub -all -- {((^|[^\\])(\\\\)*)\\\n[ \t]*}\
              $match {\1 } match
         ]} then {
            lset res end 2 $match
         }
      }
      switch -- [string index $string $index] \{ {
         lappend res [parse_braced_word $string index 2]
      } \" {
         lappend res [parse_quoted_word $string index 2]
      } \$ {
         lappend res [parse_dollar $string index]
      } \[ {
         lappend res [parse_bracket $string index]
      } "" {
         break
      } default {
         error "This can't happen."
      }
   }
   return $res
}
proc ::parsetcl::reparse_Lb_as_Mb {tree_var index parsed} {
   upvar 1 $tree_var tree
   set node [lindex $tree $index]
   switch -- [lindex $node 0] Lb - Lr - Lq {
      set base [expr {[lindex $node 1 0] + 1}]
      if {[lindex $node 0] eq "Lb"} then {
         set string [string range $parsed $base\
           [expr {[lindex $node 1 1] - 1}]]
      } else {
         set string [lindex $node 2]
      }
      set newnode [lrange $node 0 2]
      lset newnode 0 Mb
      foreach subtree [parse_semiwords $string] {
         lappend newnode [offset_intervals $subtree $base]
      }
      lset tree $index $newnode
      if {[lindex $node 0] eq "Lb"} then {
         return 2
      } else {
         return 1
      }
   } default {
      return 0
   }
}

namespace eval ::parsetcl {
    proc unparse {tree} {
	eval $tree
    }

    # Lr - literal raw
    proc Lr {interval text args} {
	return $text
    }

    # Lb - literal braced
    proc Lb {interval text args} {
	return \{$text\}
    }

    # Lb - literal quoted
    proc Lq {interval text args} {
	return \"$text\"
    }

    # Sb - backslash substitution
    proc Sb {interval text args} {
	return "\\$text"
    }

    # Sv - scalar variable substitution
    proc Sv {interval text args} {
	return "\$[eval [lindex $args 0]]"
    }

    # Sa - array variable substitution
    proc Sa {interval text args} {
	foreach a [lrange $args 1 end] {
	    append result [eval $a]
	}
	return "\$[eval [lindex $args 0]]($result)"
    }

    # Sc - command substitution
    proc Sc {interval text args} {
	set cmd {}
	foreach a $args {
	    lappend cmd [eval $a]
	}
	return "\[[join $cmd]\]"
    }

    # Mr - raw merge
    proc Mr {interval text args} {
	foreach a $args {
	    append result [eval $a]
	}
	return $result
    }

    # Mq - quoted merge
    proc Mq {interval text args} {
	foreach a $args {
	    append result [eval $a]
	}
	return \"$result\"
    }

    # Mb - braced merge
    proc Mb {interval text args} {
	foreach a $args {
	    append result [eval $a]
	}
	return \{$result\}
    }

    # Cd - complete command sans {*}
    proc Cd {interval text args} {
	set cmd {}
	foreach a $args {
	    lappend cmd [eval $a]
	}
	return [join $cmd]
    }

    # Cx - {*}-construct
    proc Cx {interval text args} {
	set c {}
	foreach a $args {
	    lappend c [eval $a]
	}
	return \{*\}[join $c]
    }

    # Ce - complete commands with {*}-constructs
    proc Ce {interval text args} {
	set c {}
	foreach a $args {
	    lappend c [eval $a]
	}
	return [join $c]
    }

    # Cp - command prefix in Ce node
    proc Cp {interval text args} {
	set c {}
	foreach a $args {
	    lappend c [eval $a]
	}
	return [join $c]
    }

    # Cr - non-prefix range of command words in a Ce node
    proc Cr {interval text args} {
	set c {}
	foreach a $args {
	    lappend c [eval $a]
	}
	return [join $c]
    }

    # Rs - script - each arg is a command
    proc Rs {interval text args} {
	set cmd {}
	foreach a $args {
	    lappend cmd [eval $a]
	}
	return "\{\n[join $cmd \n]\n\}"
    }

    # Rx - parsed expr
    proc Rx {interval text args} {
	set cmd {}
	foreach a $args {
	    lappend cmd [eval $a]
	}
	return "\{\n[join $cmd]\n\}"
    }

    namespace export -clear *
    namespace ensemble create -subcommands {}
}

## 
##
## End of file `parsetcl.tcl'.
