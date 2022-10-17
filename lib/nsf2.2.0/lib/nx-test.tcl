package provide nx::test 1.0
package require nx

namespace eval ::nx {

  # @file Simple regression test support for XOTcl / NX

  nx::Class create nx::test {
    #
    # Class Test is used to configure test instances, which can 
    # be configured by the following parameters:
    #
    # @param cmd the command to be executed
    # @param expected  the expected result
    # @param count  number of executions of cmd
    # @param pre a command to be executed at the begin of the test (before cmd)
    # @param post a command to be executed after the test (after all cmds)
    # @param namespace in which pre, post and cmd are evaluated; default "::"
    #
    # The defined tests can be executed by [:cmd "Test run"]

    :property {name ""}
    :property cmd 
    :property {namespace ::}
    :property {verbose:boolean 0} 
    :property {expected:any 1}
    :property {count:integer 1} 
    :property msg 
    :property setResult 
    :property errorReport
    :property pre 
    :property post

    :object property {count:integer 1} 
    :object property {verbose:boolean 0} 
    :object variable success 0
    :object variable failure 0
    :object variable testfile ""
    :object variable ms 0
    :object variable case "test"

    :public object method success {} {
      incr :success
    }
    :public object method failure {} {
      incr :failure
    }
    :public object method ms {ms:double} {
      set :ms [expr {${:ms} + $ms}]
    }
    :public object method destroy {} {
      lappend msg \
	  Test-set [file rootname [file tail ${:testfile}]] \
	  tests [expr {${:success} + ${:failure}}] \
	  success ${:success} \
	  failure ${:failure} \
	  ms ${:ms} 
      puts "Summary: $msg\n"
      array set "" $::argv
      if {[info exists (-testlog)]} {
	set f [open $(-testlog) a]; puts $f $msg; close $f
      }
      next
    }

    :public object method case {name arg:optional} {
      #
      # Experimental version of Test case, which (1) accepts test case as argument
      # and (2) destroys all created objects on exit (auto cleanup)
      #
      # General limitation: namespace resolving differs in nested evals
      # from global evals. So, this approach is not suitable for all tests
      # (but for most).
      #
      # Current limitations: 
      #   - cleanup for nx::Objects,
      #   - no method/mixin cleanup
      #   - no var cleanup
      #
      set :case $name 
      nsf::log notice "Running test case: [info script] $name"

      if {[info exists arg]} {
	foreach o [Object info instances -closure] {set pre_exist($o) 1}

        # namespace eval :: [list [current] eval $arg]
        apply [list {} $arg ::]
        
        foreach o [Object info instances -closure] {
          if {[info exists pre_exist($o)]} continue
          if {$o eq "::xotcl::Attribute"} continue
          if {[namespace tail $o] in {slot per-object-slot}} continue
          if {[string match {*::slot::__*} $o]} continue
          if {[::nsf::object::exists $o]} {$o destroy}
	}
      }
    }

    :public object method new args {
      set testfile [file rootname [file tail [info script]]]
      set :testfile $testfile
      if {![info exists :ccount(${:case})]} {set :ccount(${:case}) 0}
      set :name $testfile/${:case}.[format %.3d [incr :ccount(${:case})]]
      :create ${:name} -name ${:name} -count ${:count} -verbose ${:verbose} {*}$args
    }

    :public object method run {} {
      set startTime [clock clicks -milliseconds]
      foreach example [lsort [:info instances -closure]] {
	$example run
      }
      set ms [expr {[clock clicks -milliseconds]-$startTime}]
      puts stderr "Total Time: $ms ms"
    }
    
    :public method call {msg cmd} {
      if {${:verbose}} {puts stderr "$msg: $cmd"}
      return [::namespace eval ${:namespace} $cmd]
    }
   
    :public method run args {
      set startTime [clock clicks -milliseconds]
      :exitOn
      if {[info exists :pre]} {:call "pre" ${:pre}}
      if {![info exists :msg]} {set :msg ${:cmd}}
      #set gotError [catch {:call "run" ${:cmd}} r]
      if {[catch {
        set r [:call run ${:cmd}]
      } errorMsg opts]} {
        set errorCode [dict get $opts -errorcode]
        if {$errorCode ne "NONE"} {
          set r $errorMsg
        } else {
          set r $errorMsg
        }
        set gotError 1
      } else {
        set gotError 0
        set errorCode "NONE"
      }

      #
      # When 8.5 support is dropped, use:
      #
      # try {
      #   :call run ${:cmd}
      # } on error {errorMsg opts} {
      #   set errorCode [dict get $opts -errorcode]
      #   if {$errorCode ne "NONE"} {
      #     set r $errorMsg
      #   } else {
      #     set r $errorMsg
      #   }
      #   set gotError 1
      # } on ok {r} {
      #   set gotError 0
      #   set errorCode "NONE"
      # }
      
      #puts stderr "gotError = $gotError // $r == ${:expected} // [info exists :setResult]"
      if {[info exists :setResult]} {set r [eval [set :setResult]]}
      if {$r eq ${:expected} || $errorCode eq ${:expected}} {
        if {$gotError} {
          set c 1
          if {$errorCode ne "NONE" && $errorCode ne ${:expected}} {
            puts stderr "[set :name] hint: we could compare with errorCode: $errorCode"
          }
        } else {
          if {[info exists :count]} {set c ${:count}} {set c 1000}
        }
	#puts stderr "running test $c times"
	if {${:verbose}} {puts stderr "running test $c times"}
	if {$c > 1} {
	  #
	  # The following line was used to calculate calling-overhead.
	  # deactivated for now, since sometimes the reported calling
	  # overhead was larger than the call.
	  #
	  #set r0 [time {time {::namespace eval ${:namespace} ";"} $c}]
	  #regexp {^(-?[0-9]+) +} $r0 _ mS0
	  set r1 [time {time {::namespace eval ${:namespace} ${:cmd}} $c}]
	  #puts stderr "running {time {::namespace eval ${:namespace} ${:cmd}} $c} => $r1"
	  regexp {^(-?[0-9]+) +} $r1 _ mS1
	  #set ms [expr {($mS1 - $mS0) * 1.0 / $c}]
	  set ms [expr {$mS1 * 1.0 / $c}]
	  # if for some reason the run of the test is faster than the
	  # body-less eval, don't report negative values.
	  #if {$ms < 0} {set ms 0.0}
	  #puts stderr "[set :name]:\t[format %6.2f $ms]\tmms, ${:msg} (overhead [format %.2f [expr {$mS0*1.0/$c}]])"
	  puts stderr "[set :name]:\t[format %6.2f $ms]\tmms, ${:msg}"
	} else {
	  puts stderr "[set :name]: ${:msg} ok"
	}
	::nx::test success
      } else {
	puts stderr "[set :name]:\tincorrect result for '${:msg}', expected:"
	puts stderr "'${:expected}', got\n\"$r\""
	puts stderr "\tin test file [info script]"
	if {[info exists :errorReport]} {eval [set :errorReport]}
	::nx::test failure
	#
	# Make sure that the script exits with an error code, but
	# unwind the callstack via return with an error code.  Using
	# [exit -1] would leave us with a partially unwinded callstack
	# with garbage complicating debugging (e.g. MEM_COUNT
	# statistics would indicate unbalanced refCounts, etc.).
	:exit -1
      }
      if {[info exists :post]} {:call "post" ${:post}}
      ::nx::test ms [expr {[clock clicks -milliseconds]-$startTime}]
      :exitOff
    }

    :public method exit {{statuscode "1"}} {
      array set map {1 ok -1 error}
      set errorcode $map($statuscode)
      :exitOff

      
      set lvls [info level]
      # for {set i 0} {$i<=$lvls} {incr i} {puts $i-->[info level $i]}
      return -code $errorcode -level $lvls "Test was exited with code $statuscode"
    }

    :public method exitOn {} {
      interp hide {} exit; 
      interp alias {} ::exit {} [current] exit
    }

    :public method exitOff {} {
      interp alias {} ::exit {}
      interp expose {} exit; 
    }


  }

  ::namespace export Test
}

proc ? {cmd expected {msg ""}} {
  set namespace [uplevel {::namespace current}]
  #puts stderr "eval in namespace $namespace"
  if {$msg ne ""} {
    set t [nx::test new -cmd $cmd -msg $msg -namespace $namespace]
  } else {
    set t [nx::test new -cmd $cmd -namespace $namespace]
  }
  $t configure -expected $expected 
  $t run
  nsf::__db_run_assertions
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 2
#    indent-tabs-mode: nil
# End:



