package require nx

package require XOTcl 2.2
package provide nx::serializer 2.2

# For the time being, we require classical XOTcl.

# TODO: separate into two packages (i.e. make one XOTcl specific
# serializer package, and (a) load this package on a load of this
# package (when ::xotcl::Object is defined), and (b) load it from
# "xotcl*.tcl", when the serializer is alreaded loaded (e.g. via nx).

namespace eval ::nx::serializer {
  namespace eval ::xotcl {} ;# just to make mk_pkgIndex happy
  namespace import -force ::xotcl::* ;# just needed for the time being for @
  namespace import -force ::nx::*

  @ @File {
    description {
      This package provides the class Serializer, which can be used to
      generate a snapshot of the current state of the workspace
      in the form of XOTcl source code.
    }
    authors {
      Gustaf Neumann, Gustaf.Neumann@wu-wien.ac.at
    }
  }

  @ Serializer proc all {
                 ?-ignoreVarsRE&nbsp;RE?
                 "provide regular expression; matching vars are ignored"
                 ?-ignore&nbsp;obj1&nbsp;obj2&nbsp;...?
                 "provide a list of objects to be omitted"} {
    Description {
      Serialize all objects and classes that are currently
      defined (except the specified omissions and the current
               Serializer object).
      <p>Examples:<@br>
      <@pre class='code'>Serializer all -ignoreVarsRE {::b$}</@pre>
      Do not serialize any instance variable named b (of any object).<p>
      <@pre class='code'>Serializer all -ignoreVarsRE {^::o1::.*text.*$|^::o2::x$}</@pre>
      Do not serialize any variable of c1 whose name contains
      the string "text" and do not serialze the variable x of o2.<p>
      <@pre class='code'>Serializer all -ignore obj1 obj2 ... </@pre>
      do not serizalze the specified objects
    }
    return "script"
  }

  @ Serializer proc deepSerialize {
                   ?-ignoreVarsRE&nbsp;RE?
                   "provide regular expression; matching vars are ignored"
                   ?-ignore&nbsp;obj1&nbsp;obj2&nbsp;...?
                   "provide a list of objects to be omitted"
                   ?-map&nbsp;list? "translate object names in serialized code"
                   objs "Objects to be serialized"
                                 } {
    Description {
      Serialize object with all child objects (deep operation)
      except the specified omissions. For the description of
      <@tt>ignore</@tt> and <@tt>ignoreVarsRE</@tt> see
      <@tt>Serizalizer all</@tt>. <@tt>map</@tt> can be used
      in addition to provide pairs of old-string and new-string
      (like in the Tcl command <@tt>string map</@tt>). This option
      can be used to regenerate the serialized object under a different
      object or under an different name, or to translate relative
      object names in the serialized code.<p>

      Examples:
      <@pre class='code'>Serializer deepSerialize -map {::a::b ::x::y} ::a::b::c</@pre>
      Serialize the object <@tt>c</@tt> which is a child of <@tt>a::b</@tt>;
      the object will be reinitialized as object <@tt>::x::y::c</@tt>,
      all references <@tt>::a::b</@tt> will be replaced by <@tt>::x::y</@tt>.<p>

      <@pre class='code'>Serializer deepSerialize -map {::a::b [self]} ::a::b::c</@pre>
      The serizalized object can be reinstantiated under some current object,
      under which the script is evaluated.<p>

      <@pre class='code'>Serializer deepSerialize -map {::a::b::c ${var} ::a::b::c}</@pre>
      The serizalized object will be reinstantiated under a name specified
      by the variable <@tt>var<@tt> in the recreation context.
    }
    return "script"
  }

  @ Serializer proc methodSerialize {
                     object "object or class"
                     method "name of method"
                     prefix "either empty or 'inst' (latter for instprocs)"
                                   } {
    Description {
      Serialize the specified method. In order to serialize
      an instproc, <@tt>prefix</@tt> should be 'inst'; to serialze
      procs, it should be empty.<p>

      Examples:
      <@pre class='code'>Serializer methodSerialize Serializer deepSerialize ""</@pre>
      This command serializes the proc <@tt>deepSerialize</@tt>
      of the Class <@tt>Serializer</@tt>.<p>

      <@pre class='code'>Serializer methodSerialize Serializer serialize inst</@pre>
      This command serializes the instproc <@tt>serialize</@tt>
      of the Class <@tt>Serializer</@tt>.<p>
    }
    return {Script, which can be used to recreate the specified method}
  }
  @ Serializer proc exportMethods {
        list "list of methods of the form 'object proc|instproc methodname'"
      } {
    Description {
      This method can be used to specify methods that should be
      exported in every <@tt>Serializer all<@/tt>. The rationale
      behind this is that the serializer does not serialize objects
      from the namespaces of the basic object systems, which are
      used for the object system internals and volatile objects.

      TODO
      It is however often useful to define
      methods on ::xotcl::Class or ::xotcl::Objects, which should
      be exported. One can export procs, instprocs, forward and instforward<p>
      Example:
      <@pre class='code'>      Serializer exportMethods {
        ::xotcl::Object instproc __split_arguments
        ::xotcl::Object instproc __make_doc
        ::xotcl::Object instproc ad_proc
        ::xotcl::Class  instproc ad_instproc
        ::xotcl::Object forward  expr
      }<@/pre>
    }
  }


  @ Serializer instproc serialize {entity "Object or Class"} {
    Description {
      Serialize the specified object or class.
    }
    return {Object or Class with all currently defined methods,
      variables, invariants, filters and mixins}
  }

  ###########################################################################
  # Serializer Class, independent from Object System
  ###########################################################################

  Class create Serializer {
    :property -accessor public ignoreVarsRE

    :public method ignore args {
      # Ignore the objects passed via args.
      # :skip is used for filtering only in the topological sort.
      foreach element $args {
        foreach o [Serializer allChildren $element] {
          set :skip($o) 1
        }
      }
    }
    :public method objmap {map} {
      array set :objmap $map
    }

    :method init {} {
      # Never serialize the (volatile) serializer object
      :ignore [::nsf::current object]
    }

    :method warn msg {
      if {[info command ns_log] ne ""} {
        ns_log Warning "serializer: $msg"
      } else {
        puts stderr "Warning: serializer: $msg"
      }
    }

    :public method addPostCmd {cmd} {
      if {$cmd ne ""} {append :post_cmds $cmd "\n"}
    }

    :public method setObjectSystemSerializer {o serializer} {
      #puts stderr "set :serializer($o) $serializer"
      set :serializer($o) $serializer
    }

    :public method isExportedObject {o} {
      # Check, whether o is exported. For exported objects.
      # we export the object tree.
      set oo $o
      while {1} {
        if {[::nsf::var::exists [::nsf::current class] exportObjects($o)]} {
          return 1
        }
        # we do this for object trees without object-less namespaces
        if {![::nsf::object::exists $o]} {
          return 0
        }
        set o [::nsf::dispatch $o ::nsf::methods::object::info::parent]
      }
    }

    :public method getTargetName {sourceName} {
      # TODO: make more efficient;
      if {![string match ::* $sourceName]} {
        set sourceName ::$sourceName
      }
      set targetName $sourceName
      if {[array exists :objmap]} {
        foreach {source target} [array get :objmap] {
          #puts "[list regsub ^$source $targetName $target targetName]"
          regsub ^$source $targetName $target targetName
        }
      }

      #puts stderr "targetName of <$sourceName> = <$targetName>"

      return $targetName
    }

    :method topoSort {set all} {
      if {[array exists :s]} {array unset :s}
      if {[array exists :level]} {array unset :level}

      # TODO generalize?
      set ns_excluded(::ns) 1
      foreach c $set {
        set ns [namespace qualifiers $c]
        if {!$all &&
            [info exists ns_excluded($ns)] &&
            ![:isExportedObject $c]} continue
        if {[info exists :skip($c)]} continue
        set :s($c) 1
      }
      set stratum 0
      while {1} {
        set set [array names :s]
        if {[llength $set] == 0} break
        incr stratum
        # :warn "$stratum set=$set"
        set :level($stratum) {}
        foreach c $set {
          set oss [set :serializer($c)]
          if {[$oss needsNothing $c [::nsf::current object]]} {
            lappend :level($stratum) $c
          } else {
            #puts stderr "$c needs something from $set"
          }
        }
        if {[set :level($stratum)] eq ""} {
          set :level($stratum) $set
          :warn "Cyclic dependency in $set"
        }
        foreach i [set :level($stratum)] {unset :s($i)}
      }
    }

    :public method needsOneOf list {
      foreach e $list {if {[info exists :s($e)]} {return 1}}
      return 0
    }

    :public method serialize-objects {list all} {
      set :post_cmds ""

      :topoSort $list $all
      #foreach i [lsort [array names :level]] { :warn "$i: [set :level($i)]"}
      set result ""
      foreach l [lsort -integer [array names :level]] {
        foreach i [set :level($l)] {
          #:warn "serialize $i"
          #append result "# Stratum $l\n"
          set oss [set :serializer($i)]
          append result [$oss serialize $i [::nsf::current object]] \n
        }
      }
      foreach e $list {
        set namespace($e) 1
        set namespace([namespace qualifiers $e]) 1
      }

      # Handling of variable traces: traces might require a
      # different topological sort, which is hard to handle.
      # Similar as with filters, we deactivate the variable
      # traces during initialization. This happens by
      # (1) replacing the next's trace method by a no-op
      # (2) collecting variable traces through collect-var-traces
      # (3) re-activating the traces after variable initialization

      set exports ""
      set pre_cmds ""

      # delete ::ns from the namespace list, if it exists...
      catch {unset namespace(::ns)}

      foreach ns [array name namespace] {
        if {![namespace exists $ns]} continue
        if {![::nsf::object::exists $ns]} {
          append pre_cmds "namespace eval $ns {}\n"
        } elseif {$ns ne [namespace origin $ns] } {
          append pre_cmds "namespace eval $ns {}\n"
        }
        set exp [namespace eval $ns {::namespace export}]
        if {$exp ne ""} {
          append exports "namespace eval $ns {::namespace export $exp}" \n
        }
      }
      return $pre_cmds$result${:post_cmds}$exports
    }

    :public method deepSerialize {o} {
      # assumes $o to be fully qualified
      set instances [Serializer allChildren $o]
      foreach oss [ObjectSystemSerializer info instances] {
        $oss registerSerializer [::nsf::current object] $instances
      }
      :serialize-objects $instances 1
    }

    ###############################
    # class object specific methods
    ###############################

    :public object method allChildren o {
      # return o and all its children fully qualified
      set set [::nsf::directdispatch $o -frame method ::nsf::current]
      foreach c [::nsf::directdispatch $o ::nsf::methods::object::info::children] {
        lappend set {*}[:allChildren $c]
      }
      return $set
    }

    :public object method exportMethods list {
      foreach {o p m} $list {set :exportMethods([list $o $p $m]) 1}
    }

    :public object method exportObjects list {
      foreach o $list {set :exportObjects($o) 1}
    }

    :public object method exportedMethods {} {array names :exportMethods}
    :public object method exportedObjects {} {array names :exportObjects}

    :public object method resetPattern {} {array unset :ignorePattern}
    :public object method addPattern {p} {set :ignorePattern($p) 1}

    :object method checkExportedMethods {} {
      foreach k [array names :exportMethods] {
        lassign $k o p m
        set ok 0
        foreach p [array names :ignorePattern] {
          if {[string match $p $o]} {
            set ok 1; break
          }
        }
        if {!$ok} {
          error "method export is only for classes in\
                [join [array names :ignorePattern] {, }] not for $o"
        }
      }
    }

    :object method checkExportedObject {} {
      foreach o [array names :exportObjects] {
        if {![::nsf::object::exists $o]} {
          :warn "Serializer exportObject: ignore non-existing object $o"
          unset :exportObjects($o)
        } else {
          # add all child objects
          foreach o [:allChildren $element] {
            set :exportObjects($o) 1
          }
        }
      }
    }

    :public object method all {-ignoreVarsRE -ignore} {
      #
      # Remove objects which should not be included in the
      # blueprint. TODO: this is not the best place to do this, since
      # this the function is defined by OpenACS
      catch ::xo::at_cleanup

      # don't filter anything during serialization
      set filterstate [::nsf::configure filter off]
      set s [:new -childof [::nsf::current object]]
      if {[info exists ignoreVarsRE]} {$s ignoreVarsRE set $ignoreVarsRE}
      if {[info exists ignore]} {$s ignore $ignore}

      set r [subst {
        set ::nsf::__filterstate \[::nsf::configure filter off\]
        #::nx::Slot mixin add ::nx::Slot::Nocheck
        ::nsf::exithandler set [list [::nsf::exithandler get]]
      }]
      foreach option {debug softrecreate keepcmds checkresults checkarguments} {
        append r \t [list ::nsf::configure $option [::nsf::configure $option]] \n
      }
      :resetPattern

      #
      # export all nsf_procs
      #
      append r [:export_nsfprocs ::]

      #
      # export objects and classes
      #
      set instances [list]
      foreach oss [ObjectSystemSerializer info instances] {
        append r [$oss serialize-all-start $s]
        lappend instances {*}[$oss instances $s]
      }

      # provide error messages for invalid exports
      :checkExportedMethods

      # export the objects and classes
      #$s warn "export objects = [array names :exportObjects]"
      #$s warn "export objects = [array names :exportMethods]"

      append r [$s serialize-objects $instances 0]

      foreach oss [ObjectSystemSerializer info instances] {
        append r [$oss serialize-all-end $s]
      }
      $s destroy

      append r {
        #::nx::Slot mixin delete ::nx::Slot::Nocheck
        ::nsf::configure filter $::nsf::__filterstate
        unset ::nsf::__filterstate
      }
      ::nsf::configure filter $filterstate

      return $r
    }

    :public object method finalize_application_classes {oss} {
      #
      # Delete all the application objects and classes from the
      # specified object system.
      #
      set objs [$oss list_instances]
      #puts stderr "///// we have [llength $objs] $objs"
      #set objs [$Object info instances -closure]
      #
      # Delete first object but no classes, such that the destroy
      # methods can be executed in most cases.
      #
      foreach o $objs {
        if {![nsf::is object $o] || [nsf::is class $o]} {
          continue
        }
        catch {rename $o ""} errorMsg
      }

      #
      # Delete the surving classes.
      #
      set objs [$oss list_instances]
      #puts stderr "///// we have [llength $objs] $objs"
      foreach o $objs {
        set ns [namespace qualifiers $o]
        #puts stderr "DELETE class $o ns <$ns>"
        if {![nsf::is class $o] || [nsf::is metaclass $o] } {
          continue
        }
        catch {rename $o ""} errorMsg
      }
      #
      # Delete the metaclasses at the end.
      #
      set objs [$oss list_instances]
      #puts stderr "///// we have [llength $objs] $objs"
      foreach o $objs {
        set ns [namespace qualifiers $o]
        #puts stderr "DELETE class $o ns <$ns>"
        if {![nsf::is metaclass $o]} {
          continue
        }
        catch {rename $o ""} errorMsg
      }

    }

    :object method add_child_namespaces {ns} {
      if {$ns eq "::nsf"} return
      lappend :namespaces $ns
      foreach n [namespace children $ns] {
        :add_child_namespaces $n
      }
    }
    :public object method application_namespaces {ns} {
      set :namespaces ""
      :add_child_namespaces $ns
      return ${:namespaces}
    }
    :public object method export_nsfprocs {ns} {
      set result ""
      foreach n [:application_namespaces $ns] {
        foreach p [:info methods -type nsfproc ${n}::*] {
          append result [::nsf::cmd::info definition $p] \n
        }
      }
      return $result
    }

    :public object method methodSerialize {object method prefix} {
      foreach oss [ObjectSystemSerializer info instances] {
        if {[$oss responsibleSerializer $object]} {
          set result [$oss serializeExportedMethod $object $prefix $method [self]]
          break
        }
      }
      return $result
    }

    :public object method deepSerialize {-ignoreVarsRE -ignore -map -objmap args} {
      :resetPattern
      set s [:new -childof [::nsf::current object]]
      if {[info exists ignoreVarsRE]} {$s ignoreVarsRE set $ignoreVarsRE}
      if {[info exists ignore]} {$s ignore $ignore}
      if {[info exists objmap]} {$s objmap $objmap}
      foreach o $args {
        append r [$s deepSerialize [::nsf::directdispatch $o -frame method ::nsf::current]]
      }
      $s destroy
      if {[info exists map]} {return [string map $map $r]}
      return $r
    }

    # include Serializer in the serialized code
    :exportObjects [::nsf::current object]

  }


  ###########################################################################
  # Object System specific serializer
  ###########################################################################

  Class create ObjectSystemSerializer {

    :method init {} {
      # Include object system serializers and the meta-class in "Serializer all"
      Serializer exportObjects [::nsf::current class]
      Serializer exportObjects [::nsf::current object]
    }

    # reuse warn here as well
    :alias warn [Serializer info method registrationhandle warn]

    #
    # Methods to be executed at the begin and end of serialize all
    #
    :public method serialize-all-start {s} {
      :getExported
      return [:serializeExportedMethods $s]
    }

    :public method serialize-all-end {s} {
      set cmd ""
      foreach o [list ${:rootClass} ${:rootMetaClass}] {
        append cmd \
            [:frameWorkCmd ::nsf::relation::get $o object-mixin] \
            [:frameWorkCmd ::nsf::relation::get $o class-mixin] \
            [:frameWorkCmd ::nsf::method::assertion $o object-invar] \
            [:frameWorkCmd ::nsf::method::assertion $o class-invar]
      }
      #puts stderr "*** array unset [nsf::current object] alias_dependency // size [array size :alias_dependency]"
      array unset :alias_dependency
      return $cmd
    }

    #
    # Handle association between objects and responsible serializers
    #
    :public method responsibleSerializer {object} {
      return [::nsf::dispatch $object ::nsf::methods::object::info::hastype ${:rootClass}]
    }

    :public method registerSerializer {s instances} {
      # Communicate responsibility to serializer object $s
      foreach i $instances {
        if {![::nsf::dispatch $i ::nsf::methods::object::info::hastype ${:rootClass}]} continue
        $s setObjectSystemSerializer $i [::nsf::current object]
      }
    }

    :public method instances {s} {
      #
      # Compute all instances, for which we are responsible and
      # notify serializer object $s.
      #
      set instances [list]
      foreach i [${:rootClass} info instances -closure] {
        if {[:matchesIgnorePattern $i] && ![$s isExportedObject $i]} {
          continue
        }
        $s setObjectSystemSerializer $i [::nsf::current object]
        lappend instances $i
      }
      #:warn "[::nsf::current object] handles instances: $instances"
      return $instances
    }

    :public method list_instances {} {
      #
      # Compute all instances, for which we are responsible, just
      # ignoring content matching the matchpatterns
      #
      set instances [list]
      foreach i [${:rootClass} info instances -closure] {
        if {[:matchesIgnorePattern $i]} {
          continue
        }
        lappend instances $i
      }
      #:warn "[::nsf::current object] handles instances: $instances"
      return $instances
    }


    :public method getExported {} {
      #
      # get exported objects and methods from main Serializer for
      # which this object specific serializer is responsible
      #
      foreach k [Serializer exportedMethods] {
        lassign $k o p m
        if {![::nsf::object::exists $o]} {
          :warn "$o is not an object"
        } elseif {[::nsf::dispatch $o ::nsf::methods::object::info::hastype ${:rootClass}]} {
          set :exportMethods($k) 1
        }
      }
      foreach o [Serializer exportedObjects] {
        if {![::nsf::object::exists $o]} {
          :warn "$o is not an object"
        } elseif {[nsf::dispatch $o ::nsf::methods::object::info::hastype ${:rootClass}]} {
          set :exportObjects($o) 1
        }
      }
      foreach p [array names :ignorePattern] {Serializer addPattern $p}
    }


    ###############################
    # general method serialization
    ###############################

    :method classify {o} {
      if {[::nsf::dispatch $o ::nsf::methods::object::info::hastype ${:rootMetaClass}]} \
          {return Class} {return Object}
    }

    :method collectVars {{-serializeSlot:boolean false} o s} {
      set setcmd [list]
      foreach v [lsort [$o info vars]] {
        if {![::nsf::var::exists $s ignoreVarsRE]
            || [::nsf::var::set $s ignoreVarsRE] eq ""
            || ![regexp [::nsf::var::set $s ignoreVarsRE] ${o}::$v]} {
          if {[::nsf::var::exists $o $v] == 0} {
            puts stderr "strange, [list $o info vars] returned $v, but it does not seem to exist"
            continue
          }
          if {[::nsf::var::exists -array $o $v]} {
            lappend setcmd [list array set :$v [::nsf::var::set -array $o $v]]
          } else {
            set value [::nsf::var::set $o $v]
            if {$serializeSlot && $v in {domain manager}} {
              # map the values for these variables in the slot
              set value [$s getTargetName $value]
            }
            lappend setcmd [list set :$v $value]
          }
        }
      }
      return $setcmd
    }

    :method frameWorkCmd {cmd o relation -unless} {
      set v [$cmd $o $relation]
      if {$v eq ""} {return ""}
      if {[info exists unless] && $v eq $unless} {return ""}
      regsub -all {::get$} $cmd ::set cmd
      return [list $cmd ${:targetName} $relation $v]\n
    }

    :method extraMethodProperties {o perObject m} {
      #
      #  Preserve special method properties like "debug" and
      #  "deprecated" for arbitrary kind of methods via
      #  "nsf::method::property" calls.
      #
      set extra ""
      if {[::nsf::method::property $o {*}$perObject $m exists]} {
        if {[::nsf::method::property $o {*}$perObject $m debug]} {
          append extra "\n::nsf::method::property [list ${:targetName}] $perObject $m debug true"
        }
        if {[::nsf::method::property $o {*}$perObject $m deprecated]} {
          append extra "\n::nsf::method::property [list ${:targetName}] $perObject $m deprecated true"
        }
      } else {
        nsf::log warning "method <$o> <$perObject> <$m> does not exist"
        #catch {nsf::__db_show_stack}
      }
      return $extra
    }

    :method serializeExportedMethods {s} {
      set r ""
      foreach k [array names :exportMethods] {
        lassign $k o p m
        if {![:methodExists $o $p $m]} {
          :warn "Method does not exist: $o $p $m"
          continue
        }
        set :targetName [$s getTargetName $o]
        append methods($o) [:serializeExportedMethod $o $p $m $s]\n
      }
      foreach o [array names methods] {set ($o) 1}
      foreach o [list ${:rootClass} ${:rootMetaClass}] {
        if {[info exists ($o)]} {unset ($o)}
      }
      foreach o [concat ${:rootClass} ${:rootMetaClass} [array names ""]] {
        if {![info exists methods($o)]} continue
        append r \n $methods($o)
      }
      #puts stderr "[::nsf::current object] ... exportedMethods <$r\n>"
      return "$r\n"
    }

    ###############################
    # general object serialization
    ###############################

    :public method serialize {objectOrClass s} {
      set :targetName [$s getTargetName $objectOrClass]
      :[:classify $objectOrClass]-serialize $objectOrClass $s
    }

    :method matchesIgnorePattern {o} {
      foreach p [array names :ignorePattern] {
        if {[string match $p $o]} {return 1}
      }
      return 0
    }

    :method collect-var-traces {o s} {
      set traces {}
      foreach v [$o info vars] {
        # Use directdispatch to query existing traces without the need
        # of an extra method.
        set t [::nsf::directdispatch $o -frame object ::trace info variable $v]

        if {$t ne ""} {
          foreach ops $t {
            lassign $ops op cmd
            # save traces in post_cmds
            set traceCmd [list ::nsf::directdispatch $o -frame object ::trace add variable $v $op $cmd]
            $s addPostCmd $traceCmd
            append traces $traceCmd \n

            # remove trace from object
            ::nsf::directdispatch $o -frame object ::trace remove variable $v $op $cmd
          }
        }
      }
      return $traces
    }

    ###############################
    # general dependency handling
    ###############################

    :public method needsNothing {x s} {
      return [:[:classify $x]-needsNothing $x $s]
    }

    :method alias-dependency {x where} {
      set handle :alias_dependency($x,$where)
      if {[info exists $handle]} {
        return [set $handle]
      }
      set needed [list]
      foreach alias [$x ::nsf::methods::${where}::info::methods -type alias -callprotection all -path] {
        set definition [$x ::nsf::methods::${where}::info::method definition $alias]
        set aliasedCmd [lindex $definition end]
        #
        # The aliasedCmd is fully qualified and could be a method
        # handle or a primitive cmd.  For a primitive cmd, we have no
        # alias dependency. If the cmd is registered on an object, we
        # report the dependency.
        #
        set regObj [::nsf::method::registered $aliasedCmd]
        if {$regObj ne ""} {
          if {$regObj eq $x} {
            :warn "Dependency for alias $alias from $x to $x not handled (no guarantee on method order)"
          } else {
            lappend needed $regObj
          }
        }
      }
      # if {[llength $needed]>0} {
      #  puts stderr "aliases: $x needs $needed"
      #  puts stderr "set alias-deps for $x - $handle - $needed"
      # }
      set $handle $needed
      return $needed
    }

    :method Class-needsNothing {x s} {
      if {![:Object-needsNothing $x $s]} {return 0}
      set scs [$x ::nsf::methods::class::info::superclass]
      if {[$s needsOneOf $scs]} {return 0}
      if {[$s needsOneOf [::nsf::relation::get $x class-mixin]]} {return 0}
      foreach sc $scs {if {[$s needsOneOf [$sc ::nsf::methods::class::info::slotobjects]]} {return 0}}
      if {[$s needsOneOf [:alias-dependency $x class]]} {return 0}
      return 1
    }

    :method Object-needsNothing {x s} {
      set p [::nsf::directdispatch $x ::nsf::methods::object::info::parent]
      set cl [::nsf::directdispatch $x ::nsf::methods::object::info::class]
      if {$p ne "::"  && [$s needsOneOf $p]} {return 0}
      if {[$s needsOneOf $cl]} {return 0}
      if {[$s needsOneOf [$cl ::nsf::methods::class::info::slotobjects -closure -source application]]} {return 0}
      if {[$s needsOneOf [:alias-dependency $x object]]} {return 0}
      return 1
    }

    :method forward-serialize {o m s perObject} {
      if {$perObject ne ""} {
        set scope "object"
      } else {
        set scope "class"
      }
      set def [$o ::nsf::methods::${scope}::info::method definition $m]
      if {${:targetName} ne $o} {
        #
        # Handle targets of forwarders: when target object mapping
        # is activated, we might have to adapt the forwarding target
        # as well. This is in particular important for per-object
        # forwarders, which are used frequently in the slot objects
        # (but not necessarily only there).
        #
        set forwardTarget [nsf::method::forward::property $o {*}$perObject $m target]
        set mappedForwardTarget [$s getTargetName $forwardTarget]
        if {$forwardTarget ne $mappedForwardTarget} {
          nsf::method::forward::property $o {*}$perObject $m target $mappedForwardTarget
          set def [$o ::nsf::methods::${scope}::info::method definition $m]
          nsf::method::forward::property $o {*}$perObject $m target $forwardTarget
        }
      }
      return $def
    }

  }

  ###########################################################################
  # nx specific serializer
  ###########################################################################

  ObjectSystemSerializer create nx {

    set :rootClass ::nx::Object
    set :rootMetaClass ::nx::Class
    array set :ignorePattern [list "::nsf::*" 1 "::nx::*" 1 "::xotcl::*" 1]

    :public object method serialize-all-start {s} {
      #
      # Code to be executed at the begin of the serialization of nx.
      #

      #
      # The blueprint in OpenACS might be evaluated against either a
      # virgin interpreter (e.g. thread startup) or an existing
      # interpreter when the blueprint script was changed. In the
      # latter case, we have already in the current interpreter
      # predefined objects and classes. When objects are created at
      # runtime and staying the connection threads, these object will
      # be turned into base class objects, when the classes are
      # deleted and newly defined. Therefore, we cleanup the interp in
      # a first step. Alternate approaches could be to handle these
      # cases before classes/metaclasses are define (per class), or to
      # define a callback via (ns_ictl update).
      #
      # Since this might be an issue happening in all kind of
      # interpreters, and this is mostly serializer specific, we
      # handle this here via "finalize_application_classes".
      #
      set intro [subst {
        if {\[info commands ::xotcl::Object\] ne ""
            && \[info command ::nx::serializer::Serializer\] ne ""
          } {
          ::nx::serializer::Serializer finalize_application_classes [self]
        } else {
          package require nx
        }
      }]
      append intro [subst {
        ::nx::configure defaultMethodCallProtection [::nx::configure defaultMethodCallProtection]
        ::nx::configure defaultAccessor [::nx::configure defaultAccessor]
      }]
      foreach pkg {nx::mongo} {
        if {![catch {package present $pkg}]} {
          append intro "package require $pkg\n"
        }
      }
      if {[info command ::Object] ne "" && [namespace origin ::Object] eq "::nx::Object"} {
        append intro "\n" "namespace import -force ::nx::*"
      }
      return "$intro\n[next]"
    }

    ###############################
    # nx method serialization
    ###############################

    :object method methodExists {object kind name} {
      expr {[$object info method type $name] ne ""}
    }

    :public object method serializeExportedMethod {object kind name s} {
      set :targetName $object
      switch $kind {
        "inst" -
        "method" {
          set modifier ""
        }
        "nsfproc" {
          return [::nsf::cmd::info definition $name]
        }
        default {
          set modifier "object"
        }
      }
      return [:method-serialize $object $name $modifier $s]
    }

    :object method method-serialize {o m modifier s} {
      if {![::nsf::is class $o]} {set modifier "object"}
      if {$modifier eq "object"} {
        set perObject "-per-object"
        set scope object
      } else {
        set perObject ""
        set scope class
      }
      set perObject [expr {$modifier eq "object" ? "-per-object" : ""}]
      set methodType [$o ::nsf::methods::${scope}::info::method type $m]
      set def [$o ::nsf::methods::${scope}::info::method definition $m]
      switch -exact -- $methodType {
        "object" {
          # object serialization is fully handled by the serializer
          return "# $def"
        }
        "setter" {
          return ""
        }
        "forward" {
          set def [:forward-serialize $o $m $s $perObject]
        }
      }
      if {${:targetName} ne $o} {
        set def [lreplace $def 0 0 ${:targetName}]
      }
      return $def[:extraMethodProperties $o $perObject $m]
    }

    ###############################
    # nx object serialization
    ###############################

    :object method Object-serialize {o s} {
      if {[$o ::nsf::methods::object::info::hastype ::nx::EnsembleObject]} {
        return ""
      }

      set traces [:collect-var-traces $o $s]

      set serializeSlot [$o info has type ::nx::Slot]

      set evalList [:collectVars -serializeSlot $serializeSlot $o $s]

      if {$serializeSlot} {
        # Slots need to be explicitly initialized to ensure
        # __invalidateobjectparameter to be called
        lappend evalList ": init"
      }

      set objectName [::nsf::directdispatch $o -frame method ::nsf::current object]
      set isSlotContainer [::nx::isSlotContainer $objectName]
      if {$isSlotContainer} {
        append cmd [list ::nx::slotObj -container [namespace tail $objectName] \
                        [$s getTargetName [$objectName ::nsf::methods::object::info::parent]]]\n
        if {[llength $evalList] > 0} {
          append cmd [list ${:targetName} eval [join $evalList "\n   "]]\n
        }
      } else {
        #puts stderr "CREATE targetName '${:targetName}'"
        append cmd [list ::nsf::object::alloc [$o info class] ${:targetName} [join $evalList "\n   "]]\n
        foreach i [lsort [$o ::nsf::methods::object::info::methods -callprotection all -path]] {
          append cmd [:method-serialize $o $i "object" $s] "\n"
        }
      }

      append cmd \
          [:frameWorkCmd ::nsf::relation::get $o object-mixin] \
          [:frameWorkCmd ::nsf::method::assertion $o object-invar] \
          [:frameWorkCmd ::nsf::object::property $o keepcallerself -unless 0] \
          [:frameWorkCmd ::nsf::object::property $o perobjectdispatch -unless 0]

      eval $traces

      $s addPostCmd [:frameWorkCmd ::nsf::relation::get $o object-filter]
      return $cmd
    }

    ###############################
    # nx class serialization
    ###############################

    :object method Class-serialize {o s} {

      set cmd [:Object-serialize $o $s]

      foreach i [lsort [$o ::nsf::methods::class::info::methods -callprotection all -path]] {
        append cmd [:method-serialize $o $i "" $s] "\n"
      }
      append cmd \
          [:frameWorkCmd ::nsf::relation::get $o superclass -unless ${:rootClass}] \
          [:frameWorkCmd ::nsf::relation::get $o class-mixin] \
          [:frameWorkCmd ::nsf::method::assertion $o class-invar]

      $s addPostCmd [:frameWorkCmd ::nsf::relation::get $o class-filter]
      return $cmd\n
    }

    # register serialize a global method
    ::nx::Object public method serialize {-target} {
      set objmap [expr {[info exists target] ? [list [::nsf::current object] $target] : ""}]
      ::Serializer deepSerialize -objmap $objmap [::nsf::current object]
    }

  }



  ###########################################################################
  # XOTcl specific serializer
  ###########################################################################

  ObjectSystemSerializer create xotcl {

    set :rootClass ::xotcl::Object
    set :rootMetaClass ::xotcl::Class
    #array set :ignorePattern [list "::xotcl::*" 1]
    array set :ignorePattern [list "::nsf::*" 1 "::nx::*" 1 "::xotcl::*" 1]

    :public object method serialize-all-start {s} {
      set intro [subst {
        if {\[info commands ::xotcl::Object\] ne ""
            && \[info command ::nx::serializer::Serializer\] ne ""
          } {
          ::nx::serializer::Serializer finalize_application_classes [self]
        } else {
          package require XOTcl 2.0
        }
      }]
      if {[info command ::Object] ne "" && [namespace origin ::Object] eq "::xotcl::Object"} {
        append intro "\nnamespace import -force ::xotcl::*"
      }
      return "$intro\n::xotcl::Object instproc trace args {}\n[next]"
    }

    :public object method serialize-all-end {s} {
      return "[next]\n::nsf::method::alias ::xotcl::Object trace -frame object ::trace\n"
    }


    ###############################
    # XOTcl method serialization
    ###############################

    :object method methodExists {object kind name} {
      switch $kind {
        proc - instproc {
          return [expr {[$object info ${kind}s $name] ne ""}]
        }
        forward - instforward {
          return [expr {[$object info ${kind} $name] ne ""}]
        }
      }
    }

    :public object method serializeExportedMethod {object kind name s} {
      set :targetName $object
      set code ""
      switch $kind {
        "" - inst {
          # legacy; kind is prefix
          set code [:method-serialize $object $name $kind $s]\n
        }
        proc - instproc {
          if {[$object info ${kind}s $name] ne ""} {
            set prefix [expr {$kind eq "proc" ? "" : "inst"}]
            set code [:method-serialize $object $name $prefix $s]\n
          }
        }
        forward - instforward {
          if {[$object info $kind $name] ne ""} {
            set code [concat [list $object] $kind $name [$object info $kind -definition $name]]\n
          }
        }
      }
      return $code
    }

    :object method method-serialize {o m prefix s} {
      if {![nsf::is class $o] || $prefix eq ""} {
        set scope object
        set perObject "-per-object"
      } else {
        set scope class
        set perObject ""
      }
      set methodType [$o ::nsf::methods::${scope}::info::method type $m]

      if {$methodType eq "forward"} {
        set def [:forward-serialize $o $m $s $perObject]
        if {$perObject eq ""} {
          regsub "(public|protected|private) forward" $def "instforward" def
        } else {
          regsub "(public|protected|private) object forward" $def "forward" def
        }
      } elseif {$methodType eq "alias"} {
        set def [$o ::nsf::methods::${scope}::info::method definition $m]
        if {$perObject eq ""} {
          regsub "^(.*) (public|protected|private) alias" $def {::nsf::method::alias \1} def
        } else {
          regsub "^(.*) (public|protected|private) object alias" $def {::nsf::method::alias \1 -per-object} def
        }
      } else {
        if {$perObject eq ""} {
          set returns [::nsf::method::property $o $m returns]
        } else {
          set returns [::nsf::method::property $o -per-object $m returns]
        }
        set arglist [$o ::nsf::methods::${scope}::info::method parameter $m]
        lappend def ${:targetName} ${prefix}proc $m \
            $arglist \
            {*}[expr {$returns ne "" ? [list -returns $returns] : {}}] \
            [$o ::nsf::methods::${scope}::info::method body $m]
        foreach p {pre post} {
          set cond [$o ::nsf::methods::${scope}::info::method ${p}condition $m]
          if {$cond ne ""} {
            lappend def $cond
          }
        }
      }
      return $def[:extraMethodProperties $o $perObject $m]
    }

    ###############################
    # XOTcl object serialization
    ###############################

    :object method Object-serialize {o s} {
      set traces [:collect-var-traces $o $s]
      append cmd [list ::nsf::object::alloc [$o info class] ${:targetName} [join [:collectVars $o $s] "\n   "]]\n
      foreach i [$o ::nsf::methods::object::info::methods -type scripted -callprotection all] {
        append cmd [:method-serialize $o $i "" $s] "\n"
      }
      foreach i [$o ::nsf::methods::object::info::methods -type forward -callprotection all] {
        append cmd [concat [list ${:targetName}] forward $i [$o info forward -definition $i]] "\n"
      }
      foreach i [$o ::nsf::methods::object::info::methods -type setter -callprotection all] {
        append cmd [list ${:targetName} parametercmd $i] "\n"
      }
      append cmd \
          [:frameWorkCmd ::nsf::relation::get $o object-mixin] \
          [:frameWorkCmd ::nsf::method::assertion $o object-invar]

      $s addPostCmd [:frameWorkCmd ::nsf::relation::get $o object-filter]

      eval $traces
      return $cmd
    }

    ###############################
    # XOTcl class serialization
    ###############################

    :object method Class-serialize {o s} {
      set cmd [:Object-serialize $o $s]
      foreach i [$o info instprocs] {
        append cmd [:method-serialize $o $i inst $s] "\n"
      }
      foreach i [$o info instforward] {
        append cmd [concat [list ${:targetName}] instforward $i [$o info instforward -definition $i]] "\n"
      }
      foreach i [$o info instparametercmd] {
        append cmd [list ${:targetName} instparametercmd $i] "\n"
      }
      # provide limited support for exporting aliases for XOTcl objects
      foreach i [$o ::nsf::methods::class::info::methods -type alias -callprotection all] {
        set nxDef [$o ::nsf::methods::class::info::method definition $i]
        append cmd [list ::nsf::method::alias ${:targetName} {*}[lrange $nxDef 3 end]]\n
      }
      append cmd \
          [:frameWorkCmd ::nsf::relation::get $o superclass -unless ${:rootClass}] \
          [:frameWorkCmd ::nsf::relation::get $o class-mixin] \
          [:frameWorkCmd ::nsf::method::assertion $o class-invar]

      $s addPostCmd [:frameWorkCmd ::nsf::relation::get $o class-filter]
      return $cmd
    }

    # register serialize a global method for XOTcl
    ::xotcl::Object instproc serialize {-target} {
      set objmap [expr {[info exists target] ? [list [::nsf::current object] $target] : ""}]
      ::Serializer deepSerialize -objmap $objmap [::nsf::current object]
    }

    # include this method in the serialized code
    #Serializer exportMethods {
    #  ::xotcl::Object instproc contains
    #}
  }

  namespace export Serializer
  namespace eval :: "::namespace import -force [namespace current]::*"
}

#
# Local variables:
#    mode: tcl
#    tcl-indent-level: 2
#    indent-tabs-mode: nil
# End:
