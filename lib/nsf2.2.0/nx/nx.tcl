# -*- Tcl -*-
############################################################
# nx.tcl --
#
#      Implementation of the Next Scripting Language (NX) object
#      system, based on the Next Scripting Framework (NSF).
#
# Copyright (C) 2010-2016 Gustaf Neumann
# Copyright (C) 2010-2016 Stefan Sobernig
#
# Vienna University of Economics and Business
# Institute of Information Systems and New Media
# A-1020, Welthandelsplatz 1
# Vienna, Austria
#
# This work is licensed under the MIT License http://www.opensource.org/licenses/MIT
#
# Copyright:
#
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation files
# (the "Software"), to deal in the Software without restriction,
# including without limitation the rights to use, copy, modify, merge,
# publish, distribute, sublicense, and/or sell copies of the Software,
# and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
# BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
# ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#

package req nsf

package provide nx 2.2.0

namespace eval ::nx {

  namespace eval ::nsf {}            ;# make pkg-indexer happy
  namespace eval ::nsf::object {}    ;# make pkg-indexer happy
  namespace eval ::nsf::parameter {} ;# make pkg-indexer happy

  namespace eval ::nx::internal {}   ;# make pkg-indexer happy
  namespace eval ::nx::trait {}     ;# make pkg-indexer happy

  #
  # By setting the variable bootstrap, we can check later, whether we
  # are in bootstrapping mode
  #
  set ::nsf::bootstrap ::nx

  #
  # First create the ::nx object system. The internally called methods,
  # which are not defined by in this script, must have method handles
  # included. The methods "create", "configure", "destroy", "move" and
  # "__objectcoonfigureparameter" are defined in this script (either scripted, or
  # via alias).
  #
  ::nsf::objectsystem::create ::nx::Object ::nx::Class {
    -class.alloc {__alloc ::nsf::methods::class::alloc 1}
    -class.create create
    -class.dealloc {__dealloc ::nsf::methods::class::dealloc 1}
    -class.configureparameter __class_configureparameter
    -class.recreate {__recreate ::nsf::methods::class::recreate 1}
    -object.configure __configure
    -object.configureparameter __object_configureparameter
    -object.defaultmethod {defaultmethod ::nsf::methods::object::defaultmethod}
    -object.destroy destroy
    -object.init {init ::nsf::methods::object::init}
    -object.move move
    -object.unknown unknown
  }

  #
  # get frequently used primitiva from the next scripting framework
  #
  namespace export next current self configure
  namespace import ::nsf::next ::nsf::current ::nsf::self ::nsf::dispatch

  #
  # provide the standard command set for ::nx::Object
  #
  ::nsf::method::alias Object upvar     ::nsf::methods::object::upvar
  ::nsf::method::alias Object destroy   ::nsf::methods::object::destroy
  ::nsf::method::alias Object uplevel   ::nsf::methods::object::uplevel

  #
  # provide ::eval as method for ::nx::Object
  #
  ::nsf::method::alias Object eval -frame method ::eval

  ######################################################################
  # Default Methods (referenced via createobjectsystem)
  ######################################################################

  namespace eval ::nsf::methods {}         ;# make pkg-indexer happy
  namespace eval ::nsf::methods::object {} ;# make pkg-indexer happy

  # Actually, we do not need an unknown handler, but if someone
  # defines his own unknown handler we define it automatically
  proc ::nsf::methods::object::unknown {m args} {
    return -code error "[::nsf::self]: unable to dispatch method '$m'"
  }

  # The default constructor
  proc ::nsf::methods::object::init args {}

  # This method can be called on invocations of the object without a
  # specified method.
  proc ::nsf::methods::object::defaultmethod {} {::nsf::self}

  ######################################################################
  # Class methods
  ######################################################################

  # provide the standard command set for Class
  ::nsf::method::alias Class create ::nsf::methods::class::create
  ::nsf::method::alias Class new ::nsf::methods::class::new

  # set a few aliases as protected
  # "__next", if defined, should be added as well
  foreach cmd {uplevel upvar} {
    ::nsf::method::property Object $cmd call-protected 1
  }
  unset cmd

  # protect some methods against redefinition
  ::nsf::method::property Object destroy redefine-protected true
  ::nsf::method::property Class  create  redefine-protected true

  #
  # Use method::provide for base methods in case they are overloaded
  # with scripted counterparts
  ::nsf::method::provide __alloc     {::nsf::method::alias __alloc     ::nsf::methods::class::alloc}
  ::nsf::method::provide __dealloc   {::nsf::method::alias __dealloc   ::nsf::methods::class::dealloc}
  ::nsf::method::provide __recreate  {::nsf::method::alias __recreate  ::nsf::methods::class::recreate}
  ::nsf::method::provide __configure {::nsf::method::alias __configure ::nsf::methods::object::configure}
  ::nsf::method::provide unknown     {::nsf::method::alias unknown     ::nsf::methods::object::unknown}

  #
  # The method __resolve_method_path resolves a space separated path
  # of a method name and creates from the path the necessary ensemble
  # objects when needed.
  #
  ::nsf::method::create Object __resolve_method_path {
    -per-object:switch
    -verbose:switch
    path
  } {
    set object [::nsf::self]
    set methodName $path
    set regObject ""
    if {[string first " " $path] > -1} {
      set methodName [lindex $path end]
      set regObject $object

      foreach w [lrange $path 0 end-1] {
	set scope [expr {[::nsf::is class $object] && !${per-object} ? "class" : "object"}]
	if {[::nsf::is class $object] && !${per-object}} {
	  set scope class
	  set ensembleName [::nx::slotObj ${object} __$w]
          if {[: ::nsf::methods::class::info::method exists $w]
              && [: ::nsf::methods::class::info::method type $w] ne "alias"} {
            return -code error "refuse to overwrite method $w; delete/rename method first."
          }
	} else {
	  set scope object
          if {[: ::nsf::methods::object::info::method exists $w]
              && [: ::nsf::methods::object::info::method type $w] ne "object"} {
            return -code error "refuse to overwrite object method $w; delete/rename object method first."
          }
	  set ensembleName ${object}::$w
	}
	#puts stderr "NX check $scope $object info methods $path @ <$w> cmd=[info command $w] obj?[nsf::object::exists $ensembleName] "
	if {![nsf::object::exists $ensembleName]} {
 	  #
	  # Create dispatch/ensemble object and accessor method (if wanted)
	  #
	  set o [nx::EnsembleObject create $ensembleName]
	  if {$scope eq "class"} {
	    if {$verbose} {puts stderr "... create object $o"}
	    # We are on a class, and have to create an alias to be
	    # accessible for objects
	    ::nsf::method::alias $object $w $o
	    if {$verbose} {puts stderr "... create alias $object $w $o"}
	  } else {
	    if {$verbose} {puts stderr "... create object $o"}
	  }
	  set object $o
	} else {
	  #
	  # The accessor method exists already, check, if it is
	  # appropriate for extending.
	  #
	  set type [::nsf::directdispatch $object ::nsf::methods::${scope}::info::method type $w]
	  set definition [::nsf::directdispatch $object ::nsf::methods::${scope}::info::method definition $w]
	  if {$scope eq "class"} {
	    if {$type eq ""} {
	      # In case of a copy operation, the ensemble object might
	      # exist, but the alias might be missing.
	      ::nsf::method::alias $object $w $ensembleName
	      set object $ensembleName
	    } else {
	      if {$type ne "alias"} {error "can't append to $type"}
	      if {$definition eq ""} {error "definition must not be empty"}
	      set object [lindex $definition end]
	    }
	  } else {
	    if {$type ne "object"} {error "can't append to $type"}
	    if {[llength $definition] != 3} {error "unexpected definition '$definition'"}
	    append object ::$w
	  }
	}
      }
      #puts stderr "... final object $object method $methodName"
    }
    return [list object $object methodName $methodName regObject $regObject]
  }

  ::nsf::method::property Object __resolve_method_path call-protected true

  ######################################################################
  # Define default method and property protection
  ######################################################################
  ::nsf::method::create Object __default_method_call_protection args {return false}
  ::nsf::method::create Object __default_accessor args {return public}

  ::nsf::method::property Object __default_method_call_protection call-protected true
  ::nsf::method::property Object __default_accessor call-protected true

  ######################################################################
  # Define method "method" for Class
  ######################################################################

  ::nsf::method::create Class method {
    -debug:switch -deprecated:switch
    name arguments:parameter,0..* -checkalways:switch -returns body
  } {
    set p [:__resolve_method_path $name]
    set p [dict filter $p script {k v} {expr {$k in {object regObject methodName}}}]
    dict with p {
      #puts "class method $object.$methodName [list $arguments] {...}"
      set r [::nsf::method::create $object \
		 -checkalways=$checkalways \
		 {*}[expr {$regObject ne "" ? "-reg-object [list $regObject]" : ""}] \
		 $methodName $arguments $body]
      if {$r ne ""} {
	# the method was not deleted
	::nsf::method::property $object $r call-protected \
	    [::nsf::dispatch $object __default_method_call_protection]
	if {[info exists returns]} {::nsf::method::property $object $r returns $returns}
        if {$debug} {::nsf::method::property $object $r debug true}
        if {$deprecated} {::nsf::method::property $object $r deprecated true}
      }
      return $r
    }
  }

  ######################################################################
  # Define method "unknown"
  ######################################################################

  Class eval {

    # define unknown handler for class
    :method unknown {methodName args} {
      return -code error "method '$methodName' unknown for [::nsf::self];\
	in order to create an instance of class [::nsf::self], consider using\
	'[::nsf::self] create $methodName ?...?'"
    }
    # protected is not yet defined
    ::nsf::method::property [::nsf::self] unknown call-protected true
  }

  ######################################################################
  # Remember names of method defining methods
  ######################################################################

  # Well, class is not a method defining method either, but a modifier
  array set ::nsf::methodDefiningMethod {
    method 1 alias 1 forward 1 object 1
    ::nsf::classes::nx::Class::method  1 ::nsf::classes::nx::Object::method  1
    ::nsf::classes::nx::Class::alias   1 ::nsf::classes::nx::Object::alias   1
    ::nsf::classes::nx::Class::forward 1 ::nsf::classes::nx::Object::forward 1
  }

  ######################################################################
  # Provide method modifiers for ::nx::Object
  ######################################################################
  Object eval {

    # method modifier "public"
    :method public {args} {
      if {![info exists ::nsf::methodDefiningMethod([lindex $args 0])]} {
	return -code error "'[lindex $args 0]' is not a method defining method"
      } elseif {[lindex $args 0] eq "object" && ![info exists ::nsf::methodDefiningMethod([lindex $args 1])]} {
	return -code error "'[lindex $args 1]' is not a method defining method"
      }
      set r [: -system {*}$args]
      if {$r ne ""} {::nsf::method::property [self] $r call-protected false}
      return $r
    }

    # method modifier "protected"
    :method protected {args} {
      if {![info exists ::nsf::methodDefiningMethod([lindex $args 0])]} {
	return -code error "'[lindex $args 0]' is not a method defining method"
      } elseif {[lindex $args 0] eq "object" && ![info exists ::nsf::methodDefiningMethod([lindex $args 1])]} {
	return -code error "'[lindex $args 1]' is not a method defining method"
      }
      set r [: -system {*}$args]
      if {$r ne ""} {::nsf::method::property [self] $r call-protected true}
      return $r
    }

    # method modifier "private"
    :method private {args} {
      if {![info exists ::nsf::methodDefiningMethod([lindex $args 0])]} {
	return -code error "'[lindex $args 0]' is not a method defining method"
      } elseif {[lindex $args 0] eq "object" && ![info exists ::nsf::methodDefiningMethod([lindex $args 1])]} {
	return -code error "'[lindex $args 1]' is not a method defining method"
      }
      set r [: -system {*}$args]
      if {$r ne ""} {::nsf::method::property [self] $r call-private true}
      return $r
    }
  }

  # Provide a placeholder for objectparameter during the bootup
  # process. The real definition is based on slots, which are not
  # available at this point.

  Object protected method __object_configureparameter {} {;}

  ######################################################################
  # Define forward methods
  ######################################################################
  #
  # We could do this simply as
  #
  #   ::nsf::method::forward Object forward ::nsf::method::forward %self -per-object
  #   ::nsf::method::forward Class forward ::nsf::method::forward %self
  #
  # but then, we would loose the option to use compound names
  #

  Class public method forward {
      -debug:switch -deprecated:switch
      methodName
      -default -prefix -frame -onerror -returns -verbose:switch
      target:optional args
   } {
    set pathData  [:__resolve_method_path $methodName]
    set arguments [lrange [::nsf::current args] 1 end]
    set object [dict get $pathData object]

    if {[info exists target] && [string index $target 0] eq "-"} {
      error "target '$target' must not start with a dash"
    }
    if {[info exists frame] && $frame ni {object default}} {
      error "value of parameter -frame must be 'object' or 'default'"
    }
    if {[info exists returns]} {
      set nrPreArgs [expr {[llength $arguments]-[llength $args]}]
      # search for "-returns" in the arguments before $args and remove it
      set p [lsearch -exact [lrange $arguments 0 $nrPreArgs] -returns]
      if {$p > -1} {set arguments [lreplace $arguments $p $p+1]}
    }
    set r [::nsf::method::forward $object [dict get $pathData methodName] {*}$arguments]

    ::nsf::method::property $object $r call-protected \
	[::nsf::dispatch $object __default_method_call_protection]
    if {[info exists returns]} {::nsf::method::property $object $r returns $returns}
    if {$debug} {::nsf::method::property $object $r debug true}
    if {$deprecated} {::nsf::method::property $object $r deprecated true}
    return $r
  }

  ######################################################################
  # Provide method "alias"
  #
  # -frame object|method make only sense for c-defined cmds,
  ######################################################################

  Class public method alias {
    -debug:switch -deprecated:switch
    methodName -returns {-frame default} cmd
  } {
    set pathData  [:__resolve_method_path $methodName]
    set object [dict get $pathData object]

    #puts "class alias $object.[dict get $pathData methodName] $cmd"
    set r [::nsf::method::alias $object [dict get $pathData methodName] -frame $frame $cmd]
    ::nsf::method::property $object $r call-protected \
	[::nsf::dispatch $object __default_method_call_protection]
    if {[info exists returns]} {::nsf::method::property $object $r returns $returns}
    if {$debug} {::nsf::method::property $object $r debug true}
    if {$deprecated} {::nsf::method::property $object $r deprecated true}
    return $r
  }

  ######################################################################
  # Basic definitions for slots
  ######################################################################
  #
  # The function isSlotContainer tests, whether the provided object is
  # a slot container based on the method property slotcontainer, used
  # internally by the serializer.
  #
  proc ::nx::isSlotContainer {object} {
    return [::nsf::object::property $object slotcontainer]
  }

  #
  # The function nx::internal::setSlotContainerProperties set the method
  # properties for slot containers
  #
  proc ::nx::internal::setSlotContainerProperties {baseObject containerName} {
    set slotContainer ${baseObject}::$containerName
    $slotContainer ::nsf::methods::object::requirenamespace
    ::nsf::method::property $baseObject -per-object $containerName call-protected true
    ::nsf::method::property $baseObject -per-object $containerName redefine-protected true
    #puts stderr "::nsf::method::property $baseObject -per-object $containerName slotcontainer true"
    #::nsf::method::property $baseObject -per-object $containerName slotcontainer true
    ::nsf::object::property $slotContainer slotcontainer true
  }

  #
  # The function nx::slotObj ensures that the slot container for the
  # provided baseObject exists. It returns either the name of the
  # slotContainer (when no slot name was provided) or the fully
  # qualified name of the slot object.
  #
  ::nsf::proc ::nx::slotObj {{-container slot} baseObject name:optional} {
    # Create slot container object if needed
    set slotContainer ${baseObject}::$container
    if {![::nsf::object::exists $slotContainer]} {
      ::nx::Object ::nsf::methods::class::alloc $slotContainer
      ::nx::internal::setSlotContainerProperties $baseObject $container
      if {$container eq "per-object-slot"} {
	::nsf::object::property $baseObject hasperobjectslots true
      }
    }
    if {[info exists name]} {
      return ${slotContainer}::$name
    }
    return ${slotContainer}
  }

  ######################################################################
  # Allocate system slot containers
  ######################################################################
  ::nx::slotObj ::nx::Class
  ::nx::slotObj ::nx::Object


  ######################################################################
  # Define the EnsembleObject with its base methods
  ######################################################################

  Class create ::nx::EnsembleObject
  ::nx::EnsembleObject eval {
    #
    # The EnsembleObjects are called typically with a "self" bound to
    # the object, on which they are registered as methods. This way,
    # only method registered on the object are resolved (ensemble
    # methods). Only for the methods "unknown" and "defaultmethod",
    # self is actually the ensemble object. These methods are
    # maintenance methods. We have to be careful here ...
    #
    # a) not to interfere between "maintenance methods" and "ensemble
    #    methods" within the maintenance methods. This is achieved
    #    via explicit dispatch commands in the maintenance methods.
    #
    # b) not to overload "maintenance methods" with "ensemble
    #    methods".  This is achieved via the object-method-only policy
    #    (we cannot call "subcmd <subcmdName>" when "subcmdName" is a
    #    method on EnsembleObject) and via a skip object-methods flag
    #    in nsf when calling e.g. "unknown" (such that a subcmd
    #    "unknown" does not interfere with the method "unknown").
    #
    :protected method init {} {
      ::nsf::object::property [self] keepcallerself true
      ::nsf::object::property [self] perobjectdispatch true
    }
    :protected method unknown {callInfo args} {
      set path [lrange $callInfo 1 end-1]
      set m [lindex $callInfo end]
      set obj [lindex $callInfo 0]
      #::nsf::__db_show_stack
      #puts stderr "CI=<$callInfo> args <$args>"
      #puts stderr "### [list $obj ::nsf::methods::object::info::lookupmethods -path \"$path *\"]"
      if {[catch {set valid [$obj ::nsf::methods::object::info::lookupmethods -path "$path *"]} errorMsg]} {
	set valid ""
	puts stderr "+++ UNKNOWN raises error $errorMsg"
      }
      set ref "\"$m\" of $obj $path"
      return -code error "unable to dispatch sub-method $ref; valid are: [join [lsort $valid] {, }]"
    }

    :protected method defaultmethod {} {
      if {[catch {set obj [uplevel ::nsf::current]}]} {
	error "ensemble dispatch called outside of method context"
      }
      set path [uplevel {::nsf::current methodpath}]
      set l [string length $path]
      set submethods [$obj ::nsf::methods::object::info::lookupmethods -path "$path *"]
      foreach sm $submethods {set results([lindex [string range $sm $l+1 end] 0]) 1}
      return -code error "valid submethods of $obj $path: [lsort [array names results]]"
    }

    # end of EnsembleObject
  }
  ######################################################################
  # Now we are able to use ensemble methods in the definition of NX
  ######################################################################


  Object eval {
    #
    #  Define method defining methods for Object.
    #
    #  These are:
    #    - "method"
    #    - "alias"
    #    - "forward"

    :public method "object method" {
      -debug:switch -deprecated:switch
      methodName arguments:parameter,0..* -checkalways:switch -returns body
    } {
      set pathData  [:__resolve_method_path -per-object $methodName]
      set object    [dict get $pathData object]
      set regObject [dict get $pathData regObject]

      # puts "object method $object.[dict get $pathData methodName] [list $arguments] {...}"
      set r [::nsf::method::create $object \
		 -checkalways=$checkalways \
		 {*}[expr {$regObject ne "" ? "-reg-object [list $regObject]" : ""}] \
		 -per-object \
		 [dict get $pathData methodName] $arguments $body]
      if {$r ne ""} {
	# the method was not deleted
	::nsf::method::property $object $r call-protected \
	    [::nsf::dispatch $object __default_method_call_protection]
	if {[info exists returns]} {::nsf::method::property $object $r returns $returns}
        if {$debug} {::nsf::method::property $object $r debug true}
        if {$deprecated} {::nsf::method::property $object $r deprecated true}
      }
      return $r
    }

    :public method "object alias" {
      -debug:switch -deprecated:switch
      methodName -returns {-frame default} cmd
    } {
      set pathData  [:__resolve_method_path -per-object  $methodName]
      set object    [dict get $pathData object]

      #puts "object alias $object.[dict get $pathData methodName] $cmd"
      set r [::nsf::method::alias $object -per-object [dict get $pathData methodName] \
		 -frame $frame $cmd]
      ::nsf::method::property $object -per-object $r call-protected \
	  [::nsf::dispatch $object __default_method_call_protection]
      if {[info exists returns]} {::nsf::method::property $object $r returns $returns}
      if {$debug} {::nsf::method::property $object $r debug true}
      if {$deprecated} {::nsf::method::property $object $r deprecated true}
      return $r
    }

    :public method "object forward" {
      -debug:switch -deprecated:switch
      methodName
      -default -prefix -frame -onerror -returns -verbose:switch
      target:optional args
    } {
      set arguments [lrange [::nsf::current args] 1 end]
      set pathData  [:__resolve_method_path -per-object  $methodName]
      set object    [dict get $pathData object]

      if {[info exists target] && [string index $target 0] eq "-"} {
        error "target '$target' must not start with a dash"
      }
      if {[info exists frame] && $frame ni {object default}} {
        error "value of parameter '-frame' must be 'object' or 'default'"
      }
      if {[info exists returns]} {
        set nrPreArgs [expr {[llength $arguments]-[llength $args]}]
	# search for "-returns" in the arguments before $args ...
	set p [lsearch -exact [lrange $arguments 0 $nrPreArgs] -returns]
	# ... and remove it if found
	if {$p > -1} {set arguments [lreplace $arguments $p $p+1]}
      }
      set r [::nsf::method::forward $object -per-object \
                 [dict get $pathData methodName] {*}$arguments]
      ::nsf::method::property $object -per-object $r call-protected \
	  [::nsf::dispatch $object __default_method_call_protection]
      if {[info exists returns]} {::nsf::method::property $object $r returns $returns}
      if {$debug} {::nsf::method::property $object $r debug true}
      if {$deprecated} {::nsf::method::property $object $r deprecated true}
      return $r
    }
  }

  #
  # Method for deletion of properties, variables and plain methods
  #
  Object eval {

    :public method "delete object method" {name} {
      ::nsf::method::delete [self] -per-object $name
    }

    :public method "delete object property" {name} {
      # call explicitly the per-object variant of "info::slotobjects"
      set slot [: ::nsf::methods::object::info::slotobjects -type ::nx::Slot $name]
      if {$slot eq ""} {
	  return -code error \
	      "[self]: cannot delete object-specific property '$name'"
      }
      $slot destroy
      nsf::var::unset -nocomplain [self] $name
    }

    :public method "delete object variable" {name} {
      # First remove the instance variable and complain, if it does
      # not exist.
      if {[nsf::var::exists [self] $name]} {
	nsf::var::unset [self] $name
      } else {
	return -code error \
	    "[self]: object does not have an instance variable '$name'"
      }
      # call explicitly the per-object variant of "info::slotobjects"
      set slot [: ::nsf::methods::object::info::slotobjects -type ::nx::Slot $name]

      if {$slot ne ""} {
	# it is not a slot-less variable
	$slot destroy
      }
    }
  }

  Class eval {
    :public method "delete method" {name} {
      ::nsf::method::delete [self] $name
    }
    :public method "delete property" {name} {
      set slot [:info slots $name]
      if {$slot eq ""} {
	  return -code error "[self]: cannot delete property '$name'"
      }
      $slot destroy
    }
    :public method "delete variable" {name} {
      set slot [:info slots $name]
      if {$slot eq ""} {
	  return -code error "[self]: cannot delete variable '$name'"
      }
      $slot destroy
    }
  }

  ######################################################################
  # Provide method "require"
  ######################################################################
  Object eval {
    :method "require namespace" {} {
      ::nsf::directdispatch [::nsf::self] ::nsf::methods::object::requirenamespace
    }

    #
    # method require, base cases
    #
    :method "require object method" {methodName} {
      ::nsf::method::require [::nsf::self] $methodName 1
      return [:info lookup method $methodName]
    }
    #
    # method require, public explicitly
    #
    :method "require public object method" {methodName} {
      set result [:require object method $methodName]
      ::nsf::method::property [self] $result call-protected false
      return $result
    }
    #
    # method require, protected explicitly
    #
    :method "require protected object method" {methodName} {
      set result [:require object method $methodName]
      ::nsf::method::property [self] $result call-protected true
      return $result
    }

    #
    # method require, private explicitly
    #
    :method "require private object method" {methodName} {
      set result [:require object method $methodName]
      ::nsf::method::property [self] $result call-private true
      return $result
    }
  }

  nx::Class eval {
    :method "require method" {methodName} {
      return [::nsf::method::require [::nsf::self] $methodName 0]
    }
    :method "require public method" {methodName} {
      set result [:require method $methodName]
      ::nsf::method::property [self] $result call-protected false
      return $result
    }
    :method "require protected method" {methodName} {
      set result [:require method $methodName]
      ::nsf::method::property [self] $result call-protected true
      return $result
    }
    :method "require private method" {methodName} {
      set result [:require method $methodName]
      ::nsf::method::property [self] $result call-private true
      return $result
    }
  }

  ######################################################################
  # Info definition
  ######################################################################

  # we have to use "eval", since objectParameters are not defined yet

  Object eval {
    :alias "info lookup filter"  ::nsf::methods::object::info::lookupfilter
    :alias "info lookup filters" ::nsf::methods::object::info::lookupfilters
    :alias "info lookup method"  ::nsf::methods::object::info::lookupmethod
    :alias "info lookup methods" ::nsf::methods::object::info::lookupmethods
    :alias "info lookup mixins"  ::nsf::methods::object::info::lookupmixins
    :method "info lookup slots" {{-type:class ::nx::Slot} -source pattern:optional} {
      set cmd [list ::nsf::methods::object::info::lookupslots -type $type]
      if {[info exists source]} {lappend cmd -source $source}
      if {[info exists pattern]} {lappend cmd $pattern}
      return [: {*}$cmd]
    }
    :method "info lookup parameters" {methodName pattern:optional} {
      return [::nsf::cmd::info \
                  parameter \
                  -context [self] \
                  [:info lookup method $methodName] \
                  {*}[expr {[info exists pattern] ? $pattern : ""}] ]
    }
    :method "info lookup syntax" {methodName pattern:optional} {
      return [::nsf::cmd::info \
                  syntax \
                  -context [self] \
                  [:info lookup method $methodName] \
                  {*}[expr {[info exists pattern] ? $pattern : ""}] ]
    }
    :method "info lookup variables" {pattern:optional} {
      return [: info lookup slots -type ::nx::VariableSlot {*}[current args]]
    }
    :alias "info baseclass"        ::nsf::methods::object::info::baseclass
    :alias "info children"         ::nsf::methods::object::info::children
    :alias "info class"            ::nsf::methods::object::info::class
    :alias "info has mixin"        ::nsf::methods::object::info::hasmixin
    :alias "info has namespace"    ::nsf::methods::object::info::hasnamespace
    :alias "info has type"         ::nsf::methods::object::info::hastype
    :alias "info name"             ::nsf::methods::object::info::name
    :alias "info object filters"   ::nsf::methods::object::info::filters
    :alias "info object methods"   ::nsf::methods::object::info::methods
    :alias "info object mixins"    ::nsf::methods::object::info::mixins
    :method "info object slots" {{-type:class ::nx::Slot} pattern:optional} {
      set method [list ::nsf::methods::object::info::slotobjects -type $type]
      if {[info exists pattern]} {lappend method $pattern}
      return [: {*}$method]
    }
    :method "info object variables" {pattern:optional} {
      return [: info object slots -type ::nx::VariableSlot {*}[current args]]
    }
    #
    # Parameter extractors
    #
    # :method "info parameter default" {p:parameter varName:optional} {
    #   if {[info exists varName]} {
    #     uplevel [list ::nsf::parameter::info default $p $varName]
    #   } else {
    #     ::nsf::parameter::info default $p
    #   }
    # }
    # :method "info parameter name"    {p:parameter} {::nsf::parameter::info name   $p}
    # :method "info parameter syntax"  {p:parameter} {::nsf::parameter::info syntax $p}
    # :method "info parameter type"    {p:parameter} {::nsf::parameter::info type   $p}

    :alias "info parent"                ::nsf::methods::object::info::parent
    :alias "info precedence"            ::nsf::methods::object::info::precedence
    :alias "info vars"                  ::nsf::methods::object::info::vars
    :method "info variable definition" {handle:object,type=::nx::VariableSlot}  {
      return [$handle definition]
    }
    :method "info variable name" {handle:object,type=::nx::VariableSlot}  {
      return [$handle cget -name]
    }
    :method "info variable parameter" {handle:object,type=::nx::VariableSlot}  {
      return [$handle parameter]
    }
  }

  ######################################################################
  # Create the ensemble object for "info" here manually to prevent the
  # replicated definitions from Object.info in Class.info.
  # Potentially, some names are overwritten later by Class.info. Note,
  # that the automatically created name of the ensemble object has to
  # be the same as defined above.
  ######################################################################

  #
  # The following test is just for the redefinition case, after a
  # "package forget". We clear "info method" for ::nx::Object to avoid
  # confusions in the copy loop below, which uses method "method".
  #
  if {[::nsf::directdispatch ::nx::Object::slot::__info ::nsf::methods::object::info::methods "method"] ne ""} {
    Object method "info method" {} {}
  }

  #
  # There is not need to copy the "info object" ensemble to
  # ::nx::Class since this is reached via ensemble "next" in
  # nx::Object.
  #

  Class eval {
    # :alias "info lookup"         ::nx::Object::slot::__info::lookup
    :alias "info filters"        ::nsf::methods::class::info::filters
    # :alias "info has"            ::nx::Object::slot::__info::has
    :alias "info heritage"       ::nsf::methods::class::info::heritage
    :alias "info instances"      ::nsf::methods::class::info::instances
    :alias "info methods"        ::nsf::methods::class::info::methods
    :alias "info mixins"         ::nsf::methods::class::info::mixins
    :alias "info mixinof"        ::nsf::methods::class::info::mixinof

    :method "info slots" {{-type ::nx::Slot} -closure:switch -source:optional pattern:optional} {
      set cmd [list ::nsf::methods::class::info::slotobjects -type $type]
      if {[info exists source]} {lappend cmd -source $source}
      if {$closure} {lappend cmd -closure}
      if {[info exists pattern]} {lappend cmd $pattern}
      return [: {*}$cmd]
    }
    :alias "info subclasses"     ::nsf::methods::class::info::subclass
    :alias "info superclasses"   ::nsf::methods::class::info::superclass
    :method "info variables" {pattern:optional} {
      set cmd {info slots -type ::nx::VariableSlot}
      if {[info exists pattern]} {lappend cmd $pattern}
      return [: {*}$cmd]
    }
  }

  ######################################################################
  # Define "info info" and "info unknown"
  ######################################################################

  ::nsf::proc ::nx::internal::infoOptions {-asList:switch obj {methods ""}} {
    # puts stderr "INFO INFO $obj -> '[::nsf::directdispatch $obj ::nsf::methods::object::info::methods -type all]'"

    foreach name [::nsf::directdispatch $obj ::nsf::methods::object::info::methods] {
      if {$name in $methods || $name eq "unknown"} continue
      lappend methods $name
    }

    if {$asList} {
      return $methods
    } else {
      return "valid options are: [join [lsort $methods] {, }]"
    }
  }

  Object method "info info" {-asList:switch} {
    ::nx::internal::infoOptions -asList=$asList ::nx::Object::slot::__info
  }
  Class  method "info info" {-asList:switch} {
    ::nx::internal::infoOptions -asList=$asList ::nx::Class::slot::__info [next {info -asList}]
  }

  # finally register method for "info method" (otherwise, we cannot use "method" above)
  Class  eval {
    #:alias "info method" ::nsf::methods::class::info::method
    :method "info method args"         {name} {: ::nsf::methods::class::info::method args $name}
    :method "info method body"         {name} {: ::nsf::methods::class::info::method body $name}
    if {[::nsf::pkgconfig get development]} {
      :method "info method disassemble" {name} {: ::nsf::methods::class::info::method disassemble $name}
    }
    :method "info method definition"   {name} {: ::nsf::methods::class::info::method definition $name}
    :method "info method exists"       {name} {: ::nsf::methods::class::info::method exists $name}
    :method "info method handle"       {name} {: ::nsf::methods::class::info::method definitionhandle $name}
    :method "info method registrationhandle" {name} {: ::nsf::methods::class::info::method registrationhandle $name}
    :method "info method definitionhandle"   {name} {: ::nsf::methods::class::info::method definitionhandle $name}
    :method "info method origin"       {name} {: ::nsf::methods::class::info::method origin $name}
    :method "info method parameters"   {name pattern:optional} {
      set defs [: ::nsf::methods::class::info::method parameter $name]
      if {[info exists pattern]} {return [::nsf::parameter::filter $defs $pattern]}
      return $defs
    }
    :method "info method syntax"         {name} {
      return [string trimright "/cls/ [namespace tail $name] [: ::nsf::methods::class::info::method syntax $name]" { }]
    }
    :method "info method type"           {name} {: ::nsf::methods::class::info::method type $name}
    :method "info method submethods"     {name} {: ::nsf::methods::class::info::method submethods $name}
    :method "info method returns"        {name} {: ::nsf::methods::class::info::method returns $name}
    :method "info method callprotection" {name} {
      if {[::nsf::method::property [self] $name call-protected]} {
        return protected
      } elseif {[::nsf::method::property [self] $name call-private]} {
        return private
      } else {
        return public
      }
    }
    :method "info method deprecated"     {name} {::nsf::method::property [self] $name deprecated}
    :method "info method debug"          {name} {::nsf::method::property [self] $name debug}
  }

  Object  eval {
    #:alias "info object method" ::nsf::methods::object::info::method
    :method "info object method args"         {name} {: ::nsf::methods::object::info::method args $name}
    :method "info object method body"         {name} {: ::nsf::methods::object::info::method body $name}
    :method "info object method definition"   {name} {: ::nsf::methods::object::info::method definition $name}
    if {[::nsf::pkgconfig get development]} {
      :method "info object method disassemble" {name} {: ::nsf::methods::object::info::method disassemble $name}
    }
    :method "info object method exists"       {name} {: ::nsf::methods::object::info::method exists $name}
    :method "info object method handle"       {name} {: ::nsf::methods::object::info::method definitionhandle $name}
    :method "info object method registrationhandle" {name} {: ::nsf::methods::object::info::method registrationhandle $name}
    :method "info object method definitionhandle"   {name} {: ::nsf::methods::object::info::method definitionhandle $name}
    :method "info object method origin"       {name} {: ::nsf::methods::object::info::method origin $name}
    :method "info object method parameters"   {name pattern:optional} {
      set defs [: ::nsf::methods::object::info::method parameter $name]
      if {[info exists pattern]} {return [::nsf::parameter::filter $defs $pattern]}
      return $defs
    }
    :method "info object method syntax"         {name} {
      return [string trimright "/obj/ [namespace tail $name] [: ::nsf::methods::object::info::method syntax $name]" { }]
    }
    :method "info object method type"           {name} {: ::nsf::methods::object::info::method type $name}
    :method "info object method submethods"     {name} {: ::nsf::methods::object::info::method submethods $name}
    :method "info object method returns"        {name} {: ::nsf::methods::object::info::method returns $name}
    :method "info object method callprotection" {name} {
      if {[::nsf::method::property [self] -per-object $name call-protected]} {
        return protected
      } elseif {[::nsf::method::property [self] -per-object $name call-private]} {
        return private
      } else {
        return public
      }
    }
    :method "info object method deprecated" {name} {::nsf::method::property [self] -per-object $name deprecated}
    :method "info object method debug"      {name} {::nsf::method::property [self] -per-object $name debug}
  }

  ######################################################################
  # Provide Tk-style methods for configure and cget
  ######################################################################
  Object eval {
    :public alias cget ::nsf::methods::object::cget

    :public alias configure ::nsf::methods::object::configure
    #:public method "info configure" {} {: ::nsf::methods::object::info::objectparameter syntax}
  }
  #nsf::method::create ::nx::Class::slot::__info::configure defaultmethod {} {
   # uplevel {: ::nsf::methods::object::info::objectparameter syntax}
  #}


  ######################################################################
  # Definition of "abstract method foo ...."
  #
  # Deactivated for now. If we like to revive this method, it should
  # be integrated with the method modifiers and the method "class"
  #
  # Object method abstract {methtype -per-object:switch methName arglist} {
  #   if {$methtype ne "method"} {
  #     error "invalid method type '$methtype', must be 'method'"
  #   }
  #   set body "
  #     if {!\[::nsf::current isnextcall\]} {
  #       error \"abstract method $methName $arglist called\"
  #     } else {::nsf::next}
  #   "
  #   if {${per-object}} {
  #     :method -per-object $methName $arglist $body
  #   }  else {
  #     :method $methName $arglist $body
  #   }
  # }

  ######################################################################
  # MetaSlot definitions
  #
  # The MetaSlots are used later to create SlotClasses
  ######################################################################
  #
  # We are in bootstrap code; we cannot use slots/parameter to define
  # slots, so the code is a little low level. After the definition of
  # the slots, we can use slot-based code such as "-parameter" or
  # "objectparameter".
  #
  Class create ::nx::MetaSlot
  ::nsf::relation::set MetaSlot superclass Class

  MetaSlot object method requireClass {required:class old:class,0..1} {
    #
    # Combine two classes and return the more specialized one
    #
    if {$old eq "" || $old eq $required} {return $required}
    if {[$required info superclasses -closure $old] ne ""} {
      #puts stderr "required $required has $old as superclass => specializing"
      return $required
    } elseif {[$required info subclasses -closure $old] ne ""} {
      #puts stderr "required $required is more general than $old => keep $old"
      return $old
    } else {
      return -code error "required class $required not compatible with $old"
    }
  }

  #
  # Translate substdefault bitpattern to options passed to the Tcl
  # "subst" command
  #
  MetaSlot public object method substDefaultOptions {
    bitPattern
  } {
    # backslashes, variables, commands
    set options {}
    if {($bitPattern & 0b100) == 0} {
      lappend options -nobackslashes
    }
    if {($bitPattern & 0b010) == 0} {
      lappend options -novariables
    }
    if {($bitPattern & 0b001) == 0} {
      lappend options -nocommands
    }
    return $options
  }

  #
  # Given a dict of parameter options, translate this into a spec
  # which can be passed to nsf::is for value checking
  #
  MetaSlot public object method optionsToValueCheckingSpec {
    options
  } {
    set noptions ""
    if {[dict exists $options -type]} {
      set type [dict get $options -type]
      if {[string match "::*" $type]} {
        lappend noptions object type=$type
      } elseif {$type eq "switch"} {
        lappend noptions boolean
      } else {
        lappend noptions $type
      }
    }
    if {[dict exists $options -arg]} {
      lappend noptions arg=[dict get $options -arg]
    }
    if {[dict exists $options -multiplicity]} {
      lappend noptions [dict get $options -multiplicity]
    }
    return [join $noptions ,]
  }

  MetaSlot public object method parseParameterSpec {
    {-class ""}
    {-defaultopts ""}
    {-target ""}
    spec
    default:optional
  } {
    array set opt $defaultopts
    set opts ""
    set colonPos [string first : $spec]
    if {$colonPos == -1} {
      set name $spec
      set parameterOptions ""
    } else {
      set parameterOptions [string range $spec [expr {$colonPos+1}] end]
      set name [string range $spec 0 [expr {$colonPos -1}]]
      foreach property [split $parameterOptions ,] {
        if {$property in [list "required" "convert" "noarg" "nodashalnum"]} {
	  if {$property eq "convert" } {set class [:requireClass ::nx::VariableSlot $class]}
          lappend opts -$property 1
        } elseif {$property eq "noconfig"} {
	  set opt(-configurable) 0 ;# TODO
        } elseif {$property eq "incremental"} {
	  return -code error "parameter option incremental must not be used; use non-positional argument -incremental instead"
        } elseif {[string match "type=*" $property]} {
	  set class [:requireClass ::nx::VariableSlot $class]
          set type [string range $property 5 end]
          if {$type eq ""} {
            unset type
          } elseif {![string match "::*" $type]} {
            set type [namespace qualifier $target]::$type
          }
        } elseif {[string match "arg=*" $property]} {
          set argument [string range $property 4 end]
          lappend opts -arg $argument
        } elseif {[string match "substdefault*" $property]} {
          if {[string match "substdefault=*" $property]} {
            set argument [string range $property 13 end]
          } else {
            set argument 0b111
          }
          lappend opts -substdefault $argument
        } elseif {[string match "method=*" $property]} {
          lappend opts -methodname [string range $property 7 end]
        } elseif {$property eq "optional"} {
	  lappend opts -required 0
        } elseif {$property in [list "alias" "forward" "cmd" "initcmd"]} {
	  lappend opts -disposition $property
	  set class [:requireClass ::nx::ObjectParameterSlot $class]
        } elseif {[regexp {([01])[.][.]([1n*])} $property _ minOccurrence maxOccurrence]} {
	  lappend opts -multiplicity $property
        } else {
          set type $property
        }
      }
    }

    if {[info exists type]} {
      #if {$type eq "switch"} {error "switch is not allowed as type for object parameter $name"}
      lappend opts -type $type
    }
    lappend opts {*}[array get opt]
    #puts stderr "[self] *** parseParameterSpec [list $name $parameterOptions $class $opts]"
    return [list $name $parameterOptions $class $opts]
  }

  MetaSlot public object method createFromParameterSpec {
    target
    -per-object:switch
    {-class ""}
    {-initblock ""}
    {-private:switch}
    {-incremental:switch}
    {-defaultopts ""}
    spec
    default:optional
  } {

    lassign [:parseParameterSpec -class $class -defaultopts $defaultopts -target $target $spec] \
	name parameterOptions class opts

    lappend opts -incremental $incremental
    if {[info exists default]} {
      lappend opts -default $default
    }
    if {${per-object}} {
      lappend opts -per-object true
      set scope object
      set container per-object-slot
    } else {
      set scope class
      set container slot
    }

    if {$private} {
      regsub -all :  __$target _ prefix
      lappend opts -settername $name -name __private($target,$name)
      set slotname ${prefix}.$name
    } else {
      set slotname $name
    }

    if {$class eq ""} {
      set class ::nx::VariableSlot
    } else {
      #puts stderr "*** Class for '$target $name' is $class // [$class info heritage]"
    }

    set slotObj [::nx::slotObj -container $container $target $slotname]
    #puts stderr "[self] SLOTCREATE *** [list $class create $slotObj] {*}$opts <$initblock>"
    set r [$class create $slotObj {*}$opts $initblock]
    #puts stderr "[self] SLOTCREATE returned $r"
    return $r
  }
}


namespace eval ::nx {

  ######################################################################
  # Slot definitions
  ######################################################################

  MetaSlot create ::nx::Slot

  MetaSlot create ::nx::ObjectParameterSlot
  ::nsf::relation::set ObjectParameterSlot superclass Slot

  MetaSlot create ::nx::MethodParameterSlot
  ::nsf::relation::set MethodParameterSlot superclass Slot

  # Create a slot instance for dispatching method parameter specific
  # value checkers
  MethodParameterSlot create ::nx::methodParameterSlot

  # Define a temporary, low level interface for defining slot
  # values. Normally, this is done via slot objects, which are defined
  # later. The proc is removed later in this script.

  proc createBootstrapVariableSlots {class definitions} {
    foreach att $definitions {
      if {[llength $att]>1} {lassign $att att default}
      set slotObj [::nx::slotObj $class $att]
      #puts stderr "::nx::BootStrapVariableSlot create $slotObj"
      ::nx::BootStrapVariableSlot create $slotObj
      if {[info exists default]} {
        #puts stderr "::nsf::var::set $slotObj default $default"
        ::nsf::var::set $slotObj default $default
        unset default
      }
      #
      # register the standard setter
      #
      #::nsf::method::setter $class $att

      #
      # make setter protected
      #
      #regexp {^([^:]+):} $att . att
      #::nsf::method::property $class $att call-protected true

      #
      # set for every bootstrap property slot the position 0
      #
      ::nsf::var::set $slotObj position 0
      ::nsf::var::set $slotObj configurable 1
    }

    #puts stderr "Bootstrap-slot for $class calls parameter::cache::classinvalidate"
    ::nsf::parameter::cache::classinvalidate $class
  }

  ObjectParameterSlot protected method namedParameterSpec {-map-private:switch prefix name options} {
    #
    # Build a pos/nonpos parameter specification from name and option list
    #
    if {${map-private} && [info exists :accessor] && ${:accessor} eq "private"} {
      set pName ${:settername}
    } else {
      set pName $name
    }
    if {[llength $options]>0} {
      return $prefix${pName}:[join $options ,]
    } else {
      return $prefix${pName}
    }
  }

  ######################################################################
  # Define slots for slots
  ######################################################################
  #
  # We would like to have property slots during bootstrap to
  # configure the slots itself (e.g. a relation slot object). This is
  # however a chicken/egg problem, so we use a very simple class for
  # defining slots for slots, called BootStrapVariableSlot.
  #
  MetaSlot create ::nx::BootStrapVariableSlot
  ::nsf::relation::set BootStrapVariableSlot superclass ObjectParameterSlot

  BootStrapVariableSlot public method getParameterSpec {} {
    #
    # Bootstrap version of getParameter spec. Just bare essentials.
    #
    if {[info exists :parameterSpec]} {
      return ${:parameterSpec}
    }
    set name [namespace tail [self]]
    set prefix [expr {[info exists :positional] && ${:positional} ? "" : "-"}]
    set options [list]
    if {[info exists :default]} {
      if {[string match {*\[*\]*} ${:default}]} {
        lappend options substdefault
      }
      set :parameterSpec [list [list [:namedParameterSpec $prefix $name $options]] ${:default}]
    } else {
      set :parameterSpec [list [:namedParameterSpec $prefix $name $options]]
    }
    return ${:parameterSpec}
  }

  BootStrapVariableSlot protected method init {args} {
    #
    # Empty constructor; do nothing, intentionally without "next"
    #
  }

  ######################################################################
  # configure nx::Slot
  ######################################################################
  createBootstrapVariableSlots ::nx::Slot {
  }

  Slot protected method getParameterOptionSubstdefault {} {
    if {${:substdefault} eq "0b111"} {
      return substdefault
    } else {
      return substdefault=${:substdefault}
    }
  }


  ######################################################################
  # configure nx::ObjectParameterSlot
  ######################################################################

  createBootstrapVariableSlots ::nx::ObjectParameterSlot {
    {name "[namespace tail [::nsf::self]]"}
    {domain "[lindex [regexp -inline {^(.*)::(per-object-slot|slot)::[^:]+$} [::nsf::self]] 1]"}
    {manager "[::nsf::self]"}
    {per-object false}
    {methodname}
    {forwardername}
    {defaultmethods {}}
    {accessor public}
    {incremental:boolean false}
    {configurable true}
    {noarg}
    {nodashalnum}
    {disposition alias}
    {required false}
    {default}
    {initblock}
    {substdefault}
    {position 0}
    {positional}
    {elementtype}
    {multiplicity 1..1}
    {trace}
  }

  # TODO: check, if substdefault/default could work with e.g. alias; otherwise, move substdefault down
  #
  # Default unknown handler for all slots
  #
  ObjectParameterSlot protected method unknown {method args} {
    #
    # Report just application specific methods not starting with "__"
    #
    set methods [list]
    foreach m [::nsf::directdispatch [::nsf::self] \
		   ::nsf::methods::object::info::lookupmethods -source application] {
      if {[string match __* $m]} continue
      lappend methods $m
    }
    return -code error "method '$method' unknown for slot [::nsf::self]; valid are: {[lsort $methods]}"
  }

  ObjectParameterSlot protected method init {args} {
    #
    # Provide a default depending on :name for :methodname.  When slot
    # objects are created, invalidate the object parameters to reflect
    # the changes
    #
    if {${:incremental} && [:info class] eq [current class]} {
      return -code error "flag incremental must not be used for this slot type"
    }
    if {![info exists :methodname]} {
      set :methodname ${:name}
    }
    if {${:per-object}} {
      ::nsf::parameter::cache::objectinvalidate ${:domain}
    } else {
      ::nsf::parameter::cache::classinvalidate ${:domain}
    }
    nsf::object::property [self] initialized 1
    #
    # plain object parameter have currently no setter/forwarder
    #
  }

  ObjectParameterSlot public method destroy {} {
    if {[info exists :domain] && ${:domain} ne ""} {
      #
      # When slot objects are destroyed, flush the parameter cache and
      # delete the accessors
      #
      #puts stderr "*** slot destroy of [self], domain ${:domain} per-object ${:per-object}"

      if {${:per-object}} {
	::nsf::parameter::cache::objectinvalidate ${:domain}
	if {[${:domain} ::nsf::methods::object::info::method exists ${:name}]} {
	  ::nsf::method::delete ${:domain} -per-object ${:name}
	}
      } elseif {[::nsf::is class ${:domain}]} {
        ::nsf::parameter::cache::classinvalidate ${:domain}
        if {[${:domain} ::nsf::methods::class::info::method exists ${:name}]} {
          ::nsf::method::delete ${:domain} ${:name}
        }
      } else {
        nsf::log Warning "ignore improper domain ${:domain} during destroy (maybe per-object not set?)"
      }
    }
    ::nsf::next
  }

  #
  # Define a forwarder directing accessor calls to the slot
  #
  ObjectParameterSlot protected method createForwarder {name domain} {
    set dm [${:manager} cget -defaultmethods]
    ::nsf::method::forward $domain \
        -per-object=${:per-object} \
        $name \
        -prefix "value=" \
        -onerror [list ${:manager} onError] \
        ${:manager} \
        [expr {$dm ne "" ? [list %1 $dm] : "%1"}] %self \
        ${:forwardername}
  }

  ObjectParameterSlot public method onError {cmd msg} {
    if {[string match "%1 requires argument*" $msg]} {
      set template {wrong # args: use \"$cmd [join $methods |]\"}
    } elseif {[string match "*unknown for slot*" $msg]} {
      lassign $cmd slot calledMethod obj .
      regexp {=(.*)$} $calledMethod . calledMethod
      regexp {::([^:]+)$} $slot . slot
      set template {submethod $calledMethod undefined for $slot: use \"$obj $slot [join $methods |]\"}
    }
    if {[info exists template]} {
      set methods ""
      foreach m [lsort [:info lookup methods -callprotection public value=*]] {
        lappend methods [lindex [split $m =] end]
      }
      return -code error [subst $template]
    }
    return -code error $msg
  }

  ObjectParameterSlot protected method makeForwarder {} {
    #
    # Build forwarder from the source object class ($domain) to the slot
    # to delegate read and update operations
    #
    # intended to be called on RelationSlot or VariableSlot
    #
    if {![info exists :forwardername]} {
      set :forwardername ${:methodname}
    }
    #puts stderr "makeforwarder --> '${:forwardername}'"
    if {[info exists :settername]} {
      set d [nsf::directdispatch ${:domain} \
                 ::nsf::classes::nx::Object::__resolve_method_path \
                 {*}[expr {${:per-object} ? "-per-object" : ""}] ${:settername}]
      :createForwarder [dict get $d methodName] [dict get $d object]
    } else {
      :createForwarder ${:name} ${:domain}
    }
  }

  ObjectParameterSlot protected method getParameterOptions {
    {-withMultiplicity 0}
    {-forObjectParameter 0}
  } {
    #
    # Obtain a list of parameter options from slot object
    #
    set options [list]
    if {[info exists :elementtype] && ${:elementtype} ne {}} {
      lappend options ${:elementtype}
      #puts stderr "+++ [self] added elementtype ${:elementtype}"
    }
    if {${:disposition} eq "slotset"} {
      lappend options slot=[::nsf::self] ${:disposition}
      if {${:forwardername} ne ${:name}} {
        lappend options method=${:forwardername}
      }
    } else {
      lappend options ${:disposition}
    }
    if {${:name} ne ${:methodname}} {
      lappend options method=${:methodname}
    }
    if {${:required}} {
      lappend options required
    } elseif {[info exists :positional] && ${:positional}} {
      lappend options optional
    }
    if {$forObjectParameter} {
      #
      # Check, if get or set methods were overloaded
      #
      if {[:info lookup method value=set] ni {"" "::nsf::classes::nx::RelationSlot::value=set"}} {
	# In case the "set" method was provided on the slot, ask nsf to call it directly
	lappend options slot=[::nsf::self] slotset
      } elseif {[:info lookup method value=get] ni {"" "::nsf::classes::nx::RelationSlot::value=get"}} {
	# In case the "get" method was provided on the slot, ask nsf to call it directly
	lappend options slot=[::nsf::self]
      }
    }
    if {[info exists :noarg] && ${:noarg}} {lappend options noarg}
    if {[info exists :nodashalnum] && ${:nodashalnum}} {lappend options nodashalnum}
    if {$withMultiplicity && [info exists :multiplicity] && ${:multiplicity} ne "1..1"} {
      #puts stderr "### [self] added multiplicity ${:multiplicity}"
      lappend options ${:multiplicity}
    }
    if {[info exists :substdefault]} {
      lappend options [:getParameterOptionSubstdefault]
    }
    return $options
  }

  ObjectParameterSlot public method getParameterSpec {} {
    #
    # Get a full object parameter specification from slot object
    #
    if {![info exists :parameterSpec]} {
      set prefix [expr {[info exists :positional] && ${:positional} ? "" : "-"}]
      set options [:getParameterOptions -withMultiplicity true -forObjectParameter true]

      if {[info exists :initblock]} {
	if {[info exists :default]} {
	  if {[llength $options] > 0} {
            #
            # In case the parameter options contain a "slotset", this
            # options would not be allowed by nsf::is. Therefore, we
            # remove this option before testing (we are already in the
            # slot object).
            #
            set p [lsearch -exact $options "slotset" ]
            if {$p > -1} {
              set check_options [lreplace $options $p $p]
            } else {
              set check_options $options
            }
	    ::nsf::is -complain [join $check_options ,] ${:default}
	    #puts stderr "::nsf::is -complain [join $options ,] ${:default} ==> OK"
	  }
	  append initblock "\n::nsf::var::set \[::nsf::self\] ${:name} [list ${:default}]\n"
	  #puts stderr ================append-default-to-initblock-old=<${:initblock}>
	}
	lappend options initcmd
	append initblock ${:initblock}
	set :parameterSpec [list [:namedParameterSpec $prefix ${:name} $options] $initblock]

      } elseif {[info exists :default]} {
	set :parameterSpec [list [:namedParameterSpec $prefix ${:name} $options] ${:default}]
      } else {
	set :parameterSpec [list [:namedParameterSpec $prefix ${:name} $options]]
      }
    }

    #puts stderr [self]================${:parameterSpec}
    return ${:parameterSpec}
  }

  ObjectParameterSlot public method getPropertyDefinitionOptions {parameterSpec} {
    #puts "accessor <${:accessor}> configurable ${:configurable} per-object ${:per-object}"

    set mod [expr {${:per-object} ? "object" : ""}]
    set opts ""

    if {${:configurable}} {
      lappend opts -accessor ${:accessor}
      if {${:incremental}} {lappend opts -incremental}
      if {[info exists :default]} {
	return [list ${:domain} {*}$mod property {*}$opts [list $parameterSpec ${:default}]]
      }
      set methodName property
    } else {
      lappend opts -accessor ${:accessor}
      if {${:configurable}} {lappend opts -configurable true}
      if {[info exists :default]} {
	return [list ${:domain} {*}$mod variable {*}$opts $parameterSpec ${:default}]
      }
      set methodName variable
    }
    return [list ${:domain} {*}$mod $methodName {*}$opts $parameterSpec]
  }

  ObjectParameterSlot public method definition {} {
    set options [:getParameterOptions -withMultiplicity true]
    if {[info exists :positional]} {lappend options positional}
    #if {!${:configurable}} {lappend options noconfig}
    return [:getPropertyDefinitionOptions [:namedParameterSpec -map-private "" ${:name} $options]]
  }

  ######################################################################
  # We have no working objectparameter yet, since it requires a
  # minimal slot infrastructure to build object parameters from
  # slots. The above definitions should be sufficient as a basis for
  # object parameters. We provide the definition here before we refine
  # the slot definitions.
  #
  # Invalidate previously defined object parameter (built with the
  # empty objectparameter definition.
  #
  ::nsf::parameter::cache::classinvalidate MetaSlot

  ######################################################################
  # Define objectparameter method
  ######################################################################

  Object protected method __object_configureparameter {} {
    set slotObjects [nsf::directdispatch [self] ::nsf::methods::object::info::lookupslots -type ::nx::Slot]
    return [::nsf::parameter::specs $slotObjects]
  }
  Class protected method __class_configureparameter {} {
    set slotObjects [nsf::directdispatch [self] ::nsf::methods::class::info::slotobjects -closure -type ::nx::Slot]
    return [::nsf::parameter::specs $slotObjects]
  }
}

namespace eval ::nx {

  ######################################################################
  #  class nx::RelationSlot
  ######################################################################

  MetaSlot create ::nx::RelationSlot
  ::nsf::relation::set RelationSlot superclass ObjectParameterSlot

  createBootstrapVariableSlots ::nx::RelationSlot {
    {accessor public}
    {multiplicity 0..n}
    {settername}
  }

  RelationSlot protected method init {} {
    ::nsf::next
    if {${:accessor} ne ""} {
      :makeForwarder
    }
  }

  #
  # create methods for slot operations set/get/add/clear/delete
  #
  ::nsf::method::alias RelationSlot value=set ::nsf::relation::set
  ::nsf::method::alias RelationSlot value=get ::nsf::relation::get

  RelationSlot public method value=clear {obj prop} {
    set result [::nsf::relation::set $obj $prop]
    ::nsf::relation::set $obj $prop {}
    return $result
  }

  RelationSlot protected method delete_value {obj prop old value} {
    #
    # Helper method for the delete operation, deleting a value from a
    # relation slot list.
    #
    if {[string first * $value] > -1 || [string first \[ $value] > -1} {
      #
      # Value contains globbing meta characters.
      #
      if {[info exists :elementtype]
          && ${:elementtype} eq "mixinreg"
	  && ![string match ::* $value]} {
	#
        # Prefix glob pattern with ::, since all object names have
        # leading "::"
	#
        set value ::$value
      }
      return [lsearch -all -not -glob -inline $old $value]
    } elseif {[info exists :elementtype] && ${:elementtype} eq "mixinreg"} {
      #
      # Value contains no globbing meta characters, and elementtype could be
      # fully qualified
      #
      if {[string first :: $value] == -1} {
	#
	# Obtain a fully qualified name.
	#
        if {![::nsf::object::exists $value]} {
          return -code error "$value does not appear to be an object"
        }
        set value [::nsf::directdispatch $value -frame method ::nsf::self]
      }
    }
    set p [lsearch -exact $old $value]
    if {$p > -1} {
      return [lreplace $old $p $p]
    } else {
      #
      # In the resulting list might be guards. If so, do another round
      # of checking to test the first list element.
      #
      set new [list]
      set found 0
      foreach v $old {
	if {[llength $v]>1 && $value eq [lindex $v 0]} {
	  set found 1
	  continue
	}
	lappend new $v
      }
      if {!$found} {
	  return -code error "$value is not a $prop of $obj (valid are: $old)"
      }
      return $new
    }
  }

  RelationSlot public method value=add {obj prop value {pos 0}} {
    set oldSetting [::nsf::relation::get $obj $prop]
    #puts stderr [list ::nsf::relation::set $obj $prop [linsert $oldSetting $pos $value]]
    #
    # Use uplevel to avoid namespace surprises
    #
    uplevel [list ::nsf::relation::set $obj $prop [linsert $oldSetting $pos $value]]
  }

  RelationSlot public method value=delete {-nocomplain:switch obj prop value} {
    uplevel [list ::nsf::relation::set $obj $prop \
		 [:delete_value $obj $prop [::nsf::relation::get $obj $prop] $value]]
  }

  ######################################################################
  # Register system slots
  ######################################################################

  #
  # Create relation slots
  #
  # on nx::Object for
  #
  #     object-mixin
  #     object-filter
  #
  # and on nx::Class for
  #
  #     mixin
  #     filter

  ::nx::RelationSlot create ::nx::Object::slot::object-mixins \
      -multiplicity 0..n \
      -defaultmethods {} \
      -disposition slotset \
      -forwardername object-mixin \
      -settername "object mixins" \
      -elementtype mixinreg

  ::nx::RelationSlot create ::nx::Object::slot::object-filters \
      -multiplicity 0..n \
      -defaultmethods {} \
      -disposition slotset \
      -forwardername object-filter \
      -settername "object filters" \
      -elementtype filterreg

  ::nx::RelationSlot create ::nx::Class::slot::mixins \
      -multiplicity 0..n \
      -defaultmethods {} \
      -disposition slotset \
      -forwardername "class-mixin" \
      -elementtype mixinreg

    ::nx::RelationSlot create ::nx::Class::slot::filters \
      -multiplicity 0..n \
      -defaultmethods {} \
      -disposition slotset \
      -forwardername class-filter \
      -elementtype filterreg

  #
  # Define "class" as a ObjectParameterSlot defined as alias
  #
  ::nx::ObjectParameterSlot create ::nx::Object::slot::class \
      -methodname "::nsf::methods::object::class" -elementtype class

  #
  # Define "superclass" as a ObjectParameterSlot defined as alias
  #
  ::nx::ObjectParameterSlot create ::nx::Class::slot::superclasses \
      -methodname "::nsf::methods::class::superclass" \
      -elementtype class \
      -multiplicity 1..n \
      -default ::nx::Object

  #
  # Define the initblock as a positional ObjectParameterSlot
  #
  ::nx::ObjectParameterSlot create ::nx::Object::slot::__initblock \
      -disposition cmd \
      -nodashalnum true \
      -positional true \
      -position 2

  #
  # Make sure the invalidate all ObjectParameterSlots
  #
  ::nsf::parameter::cache::classinvalidate ::nx::ObjectParameterSlot

  #
  # Define method "guard" and "methods" for object filters
  #
  ::nx::Object::slot::object-filters object method value=guard {obj prop filter guard:optional} {
    if {[info exists guard]} {
      ::nsf::directdispatch $obj ::nsf::methods::object::filterguard $filter $guard
    } else {
      lindex [$obj info object filters -guards $filter] 0 2
    }
  }
  ::nx::Object::slot::object-filters object method value=methods {obj prop pattern:optional} {
    if {[info exists pattern]} {
      $obj info object filters $pattern
    } else {
      $obj info object filters
    }
  }

  #
  # Define method "guard" and "methods" for filters
  #
  ::nx::Class::slot::filters object method value=guard {obj prop filter guard:optional} {
    if {[info exists guard]} {
      ::nsf::directdispatch $obj ::nsf::methods::class::filterguard $filter $guard
    } else {
      lindex [$obj info filters -guards $filter] 0 2
    }
  }
  ::nx::Class::slot::filters object method value=methods {obj prop pattern:optional} {
    if {[info exists pattern]} {
      $obj info filters $pattern
    } else {
      $obj info filters
    }
  }

  #
  # object mixins
  #
  ::nx::Object::slot::object-mixins object method value=classes {obj prop pattern:optional} {
    if {[info exists pattern]} {
      $obj info object mixins $pattern
    } else {
      $obj info object mixins
    }
  }
  ::nx::Object::slot::object-mixins object method value=guard {obj prop mixin guard:optional} {
    if {[info exists guard]} {
      ::nsf::directdispatch $obj ::nsf::methods::object::mixinguard $mixin $guard
    } else {
      lindex [$obj info object mixins -guards $mixin] 0 2
    }
  }

  #
  # mixins
  #
  ::nx::Class::slot::mixins object method value=classes {obj prop pattern:optional} {
    if {[info exists pattern]} {
      $obj info mixins $pattern
    } else {
      $obj info mixins
    }
  }
  ::nx::Class::slot::mixins object method value=guard {obj prop filter guard:optional} {
    if {[info exists guard]} {
      ::nsf::directdispatch $obj ::nsf::methods::class::mixinguard $filter $guard
    } else {
      lindex [$obj info mixins -guards $mixin] 0 2
    }
  }
  #::nsf::method::alias ::nx::Class::slot::object-filters guard ::nx::Object::slot::object-filters::guard

  #
  # With a special purpose eval, we could avoid the need for
  # reconfigure for slot changes via eval (two cases in the regression
  # test). However, most of the eval uses are from various reading
  # purposes, so maybe this is an overkill.
  #
  #::nx::ObjectParameterSlot public method eval {cmd} {
  #  set r [next]
  #  #puts stderr "eval on slot [self] $cmd -> $r"
  #  :reconfigure
  #  return $r
  #}

  ######################################################################
  # Variable slots
  ######################################################################
  ::nsf::parameter::cache::classinvalidate MetaSlot

  MetaSlot create ::nx::VariableSlot -superclass ::nx::ObjectParameterSlot

  createBootstrapVariableSlots ::nx::VariableSlot {
    {arg}
    {convert false}
    {incremental:boolean false}
    {multiplicity 1..1}
    {accessor public}
    {type}
    {settername}
    {trace none}
  }

  ::nx::VariableSlot public method setCheckedInstVar {-nocomplain:switch -allowpreset:switch object value} {

    if {!$allowpreset && [::nsf::var::exists $object ${:name}] && !$nocomplain} {
      return -code error "object $object has already an instance variable named '${:name}'"
    }

    #
    # For checking the default, we do not want substdefault to be
    # passed to is, or is would have to do the subst....
    #
    set options [:getParameterOptions -withMultiplicity true -withSubstdefault false]

    if {[llength $options]} {
      ::nsf::is -configure -complain -name ${:name}: [join $options ,] $value
    }

    set restore [:removeTraces $object *]
    # was: ::nsf::var::set $object ${:name} ${:default}
    ::nsf::var::set $object ${:name} $value
    if {[info exists restore]} { {*}$restore }
  }

  ::nx::VariableSlot protected method setterRedefinedOptions {} {
    #
    # In the :trace = "set" case, the slot will be set via the trace
    # triggered from the direct assignment. Otherwise, when the
    # "value=set" method is provided, tell nsf ot call it (e.g. in
    # configure).
    #
    if {${:trace} ne "set" && [:info lookup method value=set] ne "::nsf::classes::nx::VariableSlot::value=set"} {
      return [list slot=[::nsf::self] slotset]
    }
    if {[:info lookup method value=get] ne "::nsf::classes::nx::VariableSlot::value=get"} {
      # In case the "get" method was provided on the slot, ask nsf to call it directly
      return [list slot=[::nsf::self]]
    }
  }

  ::nx::VariableSlot protected method getParameterOptions {
    {-withMultiplicity 0}
    {-withSubstdefault 1}
    {-forObjectParameter 0}
  } {
    set options ""
    set slotObject ""

    if {[info exists :type]} {
      set type ${:type}
      if {$type eq "switch" && !$forObjectParameter} {set type boolean}
      if {$type in {cmd initcmd}} {
	lappend options $type
      } elseif {[string match ::* $type]} {
	lappend options [expr {[::nsf::is metaclass $type] ? "class" : "object"}] type=$type
      } else {
	lappend options $type
	if {$type ni [list "" \
			     "boolean" "integer" "object" "class" \
			     "metaclass" "baseclass" "parameter" \
			     "alnum" "alpha" "ascii" "control" "digit" "double" \
			     "false" "graph" "lower" "print" "punct" "space" "true" \
			     "wideinteger" "wordchar" "xdigit" ]} {
	  lappend options slot=[::nsf::self]
	}
      }
    }
    if {$forObjectParameter} {
      foreach o [:setterRedefinedOptions] {
        if {$o ni $options} {lappend options $o}
      }
    }

    if {[:info lookup method initialize] ne "" && $forObjectParameter} {
      if {"slot=[::nsf::self]" ni $options} {lappend options slot=[::nsf::self]}
      lappend options slotinitialize
    }
    if {[info exists :arg]} {lappend options arg=${:arg}}
    if {$withSubstdefault && [info exists :substdefault]} {
      lappend options [:getParameterOptionSubstdefault]
    }
    if {${:required}} {
      lappend options required
    } elseif {[info exists :positional] && ${:positional}} {
      lappend options optional
    }
    if {${:convert}} {lappend options convert}
    if {$withMultiplicity && [info exists :multiplicity] && ${:multiplicity} ne "1..1"} {
      lappend options ${:multiplicity}
    }
    if {$forObjectParameter} {
      if {[info exists :configurable] && !${:configurable}} {
	lappend options noconfig
      }
    }
    #puts stderr "[self]*** getParameterOptions $withMultiplicity $withSubstdefault $forObjectParameter [self] returns '$options'"
    return $options
  }

  ::nx::VariableSlot protected method isMultivalued {} {
    return [string match {*..[n*]} ${:multiplicity}]
  }

  #
  # When there are accessors defined, we use always the forwarders in
  # NX. XOTcl2 has a detailed optimization.
  #
  ::nx::VariableSlot protected method needsForwarder {} {
    return 1
  }

  ::nx::VariableSlot protected method makeAccessor {} {

    if {${:accessor} eq "none"} {
      #puts stderr "*** Do not register forwarder ${:domain} ${:name}"
      return 0
    }

    if {[:needsForwarder]} {
      set handle [:makeForwarder]
      :makeIncrementalOperations
    } else {
      set handle [:makeSetter]
    }

    if {${:accessor} eq "protected"} {
      ::nsf::method::property ${:domain} {*}[expr {${:per-object} ? "-per-object" : ""}] \
	  $handle call-protected true
      set :configurable 0
    } elseif {${:accessor} eq "private"} {
      ::nsf::method::property ${:domain} {*}[expr {${:per-object} ? "-per-object" : ""}] \
	  $handle call-private true
      set :configurable 0
    } elseif {${:accessor} ne "public"} {
       set msg "accessor value '${:accessor}' invalid; might be one of public|protected|private or none"
       :destroy
       return -code error $msg
    }
    return 1
  }

  ::nx::VariableSlot public method reconfigure {} {
    #puts stderr "*** Should we reconfigure [self]???"
    unset -nocomplain :parameterSpec
    if {${:incremental}} {
      if {${:accessor} eq "none"} { set :accessor "public" }
      if {![:isMultivalued]} { set :multiplicity [string range ${:multiplicity} 0 0]..n }
    }
    :makeAccessor
    if {${:per-object} && [info exists :default]} {
      :setCheckedInstVar -nocomplain=[info exists :nocomplain] ${:domain} ${:default}
    }
    if {[::nsf::is class ${:domain}]} {
      ::nsf::parameter::cache::classinvalidate ${:domain}
    }
  }

  ::nx::VariableSlot public method parameter {} {
    # This is a shortened "lightweight" version of "getParameterSpec"
    # returning less (implicit) details. Used e.g. by "info variable parameter"
    set options [:getParameterOptions -withMultiplicity true]
    set spec [:namedParameterSpec -map-private "" ${:name} $options]
    if {[info exists :default]} {lappend spec ${:default}}
    return $spec
  }

  ::nx::VariableSlot protected method checkDefault {} {
    if {![info exists :default] || [string match {*\[*\]*} ${:default}]} {
      return
    }
    #
    # For checking the default, we do not want substdefault to be
    # passed to is, or is would have to do the subst....
    #
    set options [:getParameterOptions -withMultiplicity true -withSubstdefault false]

    if {[llength $options] > 0} {
      if {[catch {::nsf::is -complain -configure -name ${:name}: [join $options ,] ${:default}} errorMsg]} {
	#puts stderr "**** destroy [self] - $errorMsg"
	:destroy
	return -code error $errorMsg
      }
    }
  }

  ::nx::VariableSlot protected method init {} {
    if {${:incremental}} {
      if {${:accessor} eq "none"} { set :accessor "public" }
      if {![:isMultivalued]} {
        set :multiplicity [string range ${:multiplicity} 0 0]..n
      }
    }
    next
    :makeAccessor
    :checkDefault
    :handleTraces
  }

  ::nx::VariableSlot protected method makeSetter {} {
    set options [:getParameterOptions -withMultiplicity true -withSubstdefault false]
    set setterParam ${:name}
    if {[llength $options]>0} {append setterParam :[join $options ,]}
    ::nsf::method::setter ${:domain} {*}[expr {${:per-object} ? "-per-object" : ""}] $setterParam
  }

  ::nx::VariableSlot protected method defineIncrementalOperations {options_single options} {
    #
    # Just define these setter methods, when these are not defined
    # yet. We need the methods as well for e.g. private properties,
    # where the setting of the property is handled via slot.
    #
    if {[:info lookup method value=set] eq "::nsf::classes::nx::VariableSlot::value=set"} {
      set args [list obj var [:namedParameterSpec {} value $options]]
      :public object method value=set $args {::nsf::var::set $obj $var $value}
    }
    if {[:isMultivalued] && [:info lookup method value=add] eq "::nsf::classes::nx::VariableSlot::value=add"} {
      set slotObj "slot=[::nsf::self]"
      # lappend options_single slot=[::nsf::self]
      if {$slotObj ni $options_single} {lappend options_single $slotObj}
      set vspec [:namedParameterSpec {} value $options_single]
      set addArgs [list obj prop $vspec {pos 0}]
      :public object method value=add $addArgs {::nsf::next [list $obj $prop $value $pos]}
      set delArgs [list obj prop -nocomplain:switch $vspec]
      :public object method value=delete $delArgs {::nsf::next [list $obj $prop -nocomplain=$nocomplain $value]}
    } else {
      # TODO should we deactivate add/delete?
    }
  }

  ::nx::VariableSlot protected method makeIncrementalOperations {} {
    set options_single [:getParameterOptions -withSubstdefault false]
    #if {[llength $options_single] == 0} {}
    if {![info exists :type]} {
      # No need to make per-slot methods; the general rules on
      # nx::VariableSlot are sufficient
      return
    }
    #puts "makeIncrementalOperations -- single $options_single type ${:type}"
    #if {[info exists :type]} {puts ".... type ${:type}"}
    set options [:getParameterOptions -withMultiplicity true -withSubstdefault false]
    set slotObj "slot=[::nsf::self]"
    if {$slotObj ni $options} {lappend options $slotObj}

    :defineIncrementalOperations $options_single $options
  }

  ######################################################################
  # Handle variable traces
  ######################################################################
  ::nx::VariableSlot protected method removeTraces {object matchOps} {
    #puts stderr "====removeTraces ${:name} $matchOps"
    set restore ""
    set traces [::nsf::directdispatch $object -frame object ::trace info variable ${:name}]
    foreach trace $traces {
      lassign $trace ops cmdPrefix
      if {![string match $matchOps $ops]} continue
      #puts stderr "====remove trace variable ${:name} $ops $cmdPrefix"
      ::nsf::directdispatch $object -frame object ::trace remove variable ${:name} $ops $cmdPrefix
      append restore "[list ::nsf::directdispatch $object -frame object ::trace add variable ${:name} $ops $cmdPrefix]\n"
    }
    return $restore
  }

  ::nx::VariableSlot protected method handleTraces {} {
    #
    # This method assembles the __initblock, which might be used at
    # creation time of instances, or immediately for per-object slots.
    #
    set __initblock ""
    set traceCmd {::nsf::directdispatch [::nsf::self] -frame object ::trace}

    #puts stderr "instance variable trace has value <${:trace}>"
    if {"default" in ${:trace}} {
      if {"get" in ${:trace}} {
        return -code error \
            "'-trace default' and '-trace get' can't be used together"
      }
    }
    # There might be already default values registered on the
    # class. If so, the default trace is ignored.
    if {[info exists :default]} {
      if {"default" in ${:trace}} {
        return -code error \
            "'-trace default' can't be used together with default value"
      }
      #if {"get" in ${:trace}} {
      #  return -code error \
      #      "'trace get' can't be used together with default value"
      #}
    }
    if {"default" in ${:trace}} {
      #puts stderr "DEFAULTCMD [self] trace=${:trace}"
      append __initblock "::nsf::directdispatch [::nsf::self] -frame object :removeTraces \[::nsf::self\] read\n"
      append __initblock "$traceCmd add variable [list ${:name}] read \
	\[list [::nsf::self] __trace_default \[::nsf::self\]\]\n"
    }
    if {"get" in ${:trace}} {
      #puts stderr "VALUECMD [self] trace=${:trace}"
      append __initblock "::nsf::directdispatch [::nsf::self] -frame object :removeTraces \[::nsf::self\] read\n"
      append __initblock "$traceCmd add variable [list ${:name}] read \
	\[list [::nsf::self] __trace_get \[::nsf::self\]\]\n"
    }
    if {"set" in ${:trace}} {
      #puts stderr "VALUECHANGED [self] trace=${:trace}"
      append __initblock "::nsf::directdispatch [::nsf::self] -frame object :removeTraces \[::nsf::self\] write\n"
      append __initblock "$traceCmd add variable [list ${:name}] write \
	\[list [::nsf::self] __trace_set \[::nsf::self\]\]\n"
    }

    if {$__initblock ne ""} {
      if {${:per-object}} {
	${:domain} eval $__initblock
      }
      #puts stderr initblock=$__initblock
      set :initblock $__initblock
    }
  }

  #
  # Implementation of methods called by the traces
  #
  ::nx::VariableSlot method __default_from_cmd {obj cmd var sub op} {
    #puts "GETVAR [::nsf::current method] obj=$obj cmd=$cmd, var=$var, op=$op"
    ::nsf::directdispatch $obj -frame object \
	::trace remove variable $var $op [list [::nsf::self] [::nsf::current method] $obj $cmd]
    ::nsf::var::set $obj $var [$obj eval $cmd]
  }
  # TODO: remove me
  # ::nx::VariableSlot method __value_from_cmd {obj cmd var sub op} {
  #   #puts stderr "GETVAR [::nsf::current method] obj=$obj cmd=$cmd, var=$var, op=$op"
  #   ::nsf::var::set $obj [string trimleft $var :] [$obj eval $cmd]
  # }
  #::nx::VariableSlot method __value_changed_cmd {obj method var sub op} {
  #  #puts "valuechanged obj=$obj cmd=$cmd, var=$var, op=$op"
  #  eval $cmd
  #}
  ::nx::VariableSlot method __trace_default {obj var sub op} {
    #puts stderr "trace_default call obj=$obj var=$var, sub=<$sub> op=$op"
    ::nsf::directdispatch $obj -frame object \
	::trace remove variable $var $op [list [::nsf::self] [::nsf::current method] $obj]
    ::nsf::var::set $obj $var [:value=default $obj $var]
  }
  ::nx::VariableSlot method __trace_get {obj var sub op} {
    #puts stderr "trace_get call obj=$obj var=$var, sub=<$sub> op=$op"
    :value=get $obj [string trimleft $var :]
  }
  ::nx::VariableSlot method __trace_set {obj var sub op} {
    #puts stderr "trace_set call obj=$obj var=$var, sub=<$sub> op=$op"
    set var [string trimleft $var :]
    :value=set $obj $var [::nsf::var::get $obj $var]
  }

  ######################################################################
  # Implementation of (incremental) forwarder operations for
  # VariableSlots:
  #  - set
  #  - get
  #  - add
  #  - delete
  ######################################################################

  ::nsf::method::alias ::nx::VariableSlot value=get    ::nsf::var::get
  ::nsf::method::alias ::nx::VariableSlot value=set    ::nsf::var::set

  ::nx::VariableSlot public method value=unset {obj prop -nocomplain:switch} {
    ::nsf::var::unset -nocomplain=$nocomplain $obj $prop
  }

  ::nx::VariableSlot public method value=add {obj prop value {pos 0}} {
    if {![:isMultivalued]} {
      #puts stderr "... vars [[self] info vars] // [[self] eval {set :multiplicity}]"
      return -code error "property $prop of [set :domain] ist not multivalued"
    }
    if {[::nsf::var::exists $obj $prop]} {
      ::nsf::var::set $obj $prop [linsert [::nsf::var::set $obj $prop] $pos $value]
    } else {
      ::nsf::var::set $obj $prop [list $value]
    }
  }

  ::nx::VariableSlot public method value=delete {obj prop -nocomplain:switch value} {
    set old [::nsf::var::get $obj $prop]
    set p [lsearch -glob $old $value]
    if {$p > -1} {
      ::nsf::var::set $obj $prop [lreplace $old $p $p]
    } elseif {!$nocomplain} {
      return -code error "$obj: '$value' is not in variable '$prop' (values are: '$old')"
    } else {
      return $old
    }
  }


  ######################################################################
  # Define methods "property" and "variable"
  ######################################################################

  nx::Object method "object variable" {
     {-accessor "none"}
     {-class ""}
     {-configurable:boolean false}
     {-incremental:switch}
     {-initblock ""}
     {-nocomplain:switch}
     {-trace}
     spec:parameter
     defaultValue:optional
   } {
    #
    # This method creates sometimes a slot, sometimes not
    # (optimization).  We need a slot currently in the following
    # situations:
    #  - when accessors are needed
    #    (serializer uses slot object to create accessors)
    #  - when initblock is non empty
    #

    #puts stderr "Object variable $spec accessor $accessor nocomplain $nocomplain incremental $incremental"

    # get name and list of parameter options
    lassign [::nx::MetaSlot parseParameterSpec -class $class -target [self] $spec] \
	name parameterOptions class options

    #puts "[self] object variable $spec name <$name> parameterOptions <$parameterOptions> class <$class> options <$options>"


    if {[dict exists $options -configurable]} {
      set configurable [dict get $options -configurable]
    }

    if {![info exists trace] && [info exists :trace] && ${:trace} ne "none"} {
      set trace ${:trace}
    }

    #puts "[self] object variable $spec haveDefault? [info exists defaultValue] opts <$parameterOptions> options <$options>"

    if {[info exists defaultValue]
        && [dict exists $options -substdefault]
        && [string match {*\[*\]*} $defaultValue]
      } {
      if {![info complete $defaultValue]} {
        return -code error "substdefault: default '$defaultValue' is not a complete script"
      }
      set substDefaultOptions [::nx::MetaSlot substDefaultOptions [dict get $options -substdefault]]
      set defaultValue [subst {*}$substDefaultOptions $defaultValue]
    }

    #
    # Check for slot-less variables
    #
    if {$initblock eq ""
        && !$configurable
        && !$incremental
        && $accessor eq "none"
        && ![info exists trace]
      } {
      #
      # The variable is slot-less.
      #
      #puts "[self]... slotless variable $spec"

      # The following tasks have to be still performed:
      # - If there is an explicit default value, the value has to
      #   be checked.
      # - if the type is a switch, we have to set the implicit
      #   default value, when there is not explicit default
      #
      set isSwitch [expr {[dict exists $options -type] && [dict get $options -type] eq "switch"}]

      if {[info exists defaultValue]} {
	if {[info exists :$name] && !$nocomplain} {
	  return -code error \
	      "object [self] has already an instance variable named '$name'"
	}
	if {$parameterOptions ne ""} {
	  #puts stderr "*** ::nsf::is $parameterOptions $defaultValue // opts=$options"
	  #
          # Extract from the options a spec for value checking, and
          # let "nsf::is" perform the actual checking. In case, the
          # check fails, "nsf::is" will raise an error with and error
          # message communicating the failure.
          #
	  set nspec [::nx::MetaSlot optionsToValueCheckingSpec $options]
	  ::nsf::is -complain $nspec $defaultValue
	} else {
	  set name $spec
	}
	set :$name $defaultValue
      } elseif {$isSwitch} {
	set :$name 0
      } else {
	return -code error \
	    "variable definition for '$name' (without value and accessor) is useless"
      }
      return
    }

    #puts "[self]... slot variable $spec"
    #
    # create variable via a slot object
    #
    set defaultopts [list -accessor $accessor]
    if {[info exists trace]} {lappend defaultopts -trace $trace}

    set slot [::nx::MetaSlot createFromParameterSpec [self] \
		  -per-object \
		  -class $class \
		  -initblock $initblock \
		  -incremental=$incremental \
		  -private=[expr {$accessor eq "private"}] \
		  -defaultopts $defaultopts \
		  $spec \
		  {*}[expr {[info exists defaultValue] ? [list $defaultValue] : ""}]]

    if {$nocomplain} {$slot eval {set :nocomplain 1}}
    if {!$configurable} {$slot eval {set :configurable false}}
    if {[info exists defaultValue]} {
      #
      # We could consider calling "configure" instead, but that would
      # not work for true "variable" handlers.
      #
      # In case a get trace is activated, don't compain about
      # pre-existing variables, which might be set via traces.
      set allowpreset [expr {"get" in [$slot cget -trace] && [nsf::var::exists [self] $name]}]
      $slot setCheckedInstVar -allowpreset=$allowpreset -nocomplain=$nocomplain [self] $defaultValue
      #set :__initblock($name) 1
    }

    if {[$slot eval {info exists :settername}]} {
      set name [$slot cget -settername]
    } else {
      set name [$slot cget -name]
    }
    #puts "[self]... $slot cget DONE"
    return [::nsf::directdispatch [self] ::nsf::methods::object::info::method registrationhandle $name]
  }

  Object method "object property" {
    {-accessor ""}
    {-class ""}
    {-configurable:boolean true}
    {-incremental:switch}
    {-nocomplain:switch}
    {-trace}
     spec:parameter
    {initblock ""}
  } {

    if {$accessor eq ""} {
      set accessor [::nsf::dispatch [self] __default_accessor]
      #puts stderr "OBJECT [self] got default accessor ${accessor}"
    }
    set traceSpec [expr {[info exists trace] ? [list -trace $trace] : ""}]

    set r [[self] object variable \
	       -accessor $accessor \
	       -incremental=$incremental \
	       -class $class \
	       -initblock $initblock \
	       -configurable $configurable \
	       -nocomplain=$nocomplain \
               {*}$traceSpec \
	       {*}$spec]
    return $r
  }

  nx::Class method variable {
    {-accessor "none"}
    {-class ""}
    {-configurable:boolean false}
    {-incremental:switch}
    {-initblock ""}
    {-trace}
    spec:parameter
    defaultValue:optional
  } {
    set defaultopts [list -accessor $accessor -configurable $configurable]
    if {[info exists trace]} {
      foreach t $trace {
        if {$t ni {none get set default}} {
          return -code error "invalid value '$t' for trace: '$trace'"
        }
      }
      lappend defaultopts -trace $trace
    }

    lassign [::nx::MetaSlot parseParameterSpec -class $class -target [self] $spec] \
               pname parameterOptions _ options

    if {[info exists defaultValue]
        && [dict exists $options -substdefault]
        && [string match {*\[*\]*} $defaultValue]
        && ![info complete $defaultValue]
      } {
      return -code error "substdefault: default '$defaultValue' is not a complete script"
    }
    
    set slot [::nx::MetaSlot createFromParameterSpec [::nsf::self] \
		  -class $class \
		  -initblock $initblock \
		  -incremental=$incremental \
		  -private=[expr {$accessor eq "private"}] \
		  -defaultopts $defaultopts \
		  $spec \
		  {*}[expr {[info exists defaultValue] ? [list $defaultValue] : ""}]]
    if {[$slot eval {info exists :settername}]} {
      set name [$slot cget -settername]
    } else {
      set name [$slot cget -name]
    }
    #puts stderr handle=[::nsf::directdispatch [self] ::nsf::methods::class::info::method registrationhandle $name]
    return [::nsf::directdispatch [self] ::nsf::methods::class::info::method registrationhandle $name]
  }

  nx::Class method property {
    {-accessor ""}
    {-class ""}
    {-configurable:boolean true}
    {-incremental:switch}
    {-trace}
    spec:parameter
    {initblock ""}
  } {
    if {$accessor eq ""} {
      set accessor [::nsf::dispatch [self] __default_accessor]
    }
    set traceSpec [expr {[info exists trace] ? [list -trace $trace] : ""}]

    set r [[self] ::nsf::classes::nx::Class::variable \
	       -accessor $accessor \
	       -incremental=$incremental \
	       -class $class \
	       -configurable $configurable \
	       -initblock $initblock \
               {*}$traceSpec \
	       {*}$spec]
    return $r
  }


  ######################################################################
  # Define method "properties" for convenience to define multiple
  # properties based on a list of parameter specifications.
  ######################################################################
  #
  #proc ::nx::internal::addProperties {arglist} {
  #  foreach arg $arglist {:property $arg}
  #}
  #::nx::ObjectParameterSlot create ::nx::Object::slot::properties \
  #    -methodname "::nx::internal::addProperties"

  ######################################################################
  # Minimal definition of a value checker that permits every value
  # without warnings. The primary purpose of this value checker is to
  # provide a means to specify that the value can have every possible
  # content and not to produce a warning when it might look like a
  # non-positional parameter.
  ######################################################################
  ::nx::Slot method type=any {name value} { }
  ::nsf::method::property ::nx::Slot type=any call-protected true

  ######################################################################
  # Now the slots are defined; now we can defines the Objects or
  # classes with parameters more easily than above.
  ######################################################################

  # remove helper proc
  rename ::nx::createBootstrapVariableSlots ""

  ######################################################################
  # Define a scoped "new" method, which is similar to plain new, but
  # uses the current namespace by default as root of the object name.
  ######################################################################

  Class create ::nx::NsScopedNew {
    :public method new {-childof args} {
      if {![info exists childof]} {
	#
	# Obtain the namespace from plain uplevel to honor the
	# namespace provided by apply
	#
	set childof [uplevel {namespace current}]
      }
      #
      # Use the uplevel method to assure that e.g. "... new -volatile ..."
      # has the right scope
      #
      :uplevel [list [self] ::nsf::methods::class::new -childof $childof {*}$args]
    }
  }

  ######################################################################
  # The method 'contains' changes the namespace in which objects with
  # relative names are created.  Therefore, 'contains' provides a
  # friendly notation for creating nested object
  # structures. Optionally, creating new objects in the specified
  # scope can be turned off.
  ######################################################################

  Object public method contains {
    {-withnew:boolean true}
    -object
    {-class:class ::nx::Object}
    cmds
  } {
    if {![info exists object]} {set object [::nsf::self]}
    if {![::nsf::object::exists $object]} {$class create $object}
    # This method is reused in XOTcl which has e.g. no "require";
    # therefore use nsf primitiva.
    ::nsf::directdispatch $object ::nsf::methods::object::requirenamespace

    if {$withnew} {
      #
      # When $withnew is requested we replace the default new method
      # with a version using the current namespace as root. Earlier
      # implementations used a mixin on nx::Class and xotcl::Class,
      # but frequent mixin operations on the most general meta-class
      # are expensive when there are many classes defined
      # (e.g. several ten thousands), since the mixin operation
      # invalidates the mixins for all instances of the meta-class
      # (i.e. for all classes)
      #
      set infoMethod "::nsf::methods::class::info::method"
      set plainNew   "::nsf::methods::class::new"
      set mappedNew  [::nx::NsScopedNew $infoMethod definitionhandle new]

      set nxMapNew [expr {[::nx::Class $infoMethod origin new] eq $plainNew}]
      if {$nxMapNew} {::nsf::method::alias ::nx::Class new $mappedNew}

      if {[::nsf::is class ::xotcl::Class]} {
	set xotclMapNew [expr {[::xotcl::Class $infoMethod origin new] eq $plainNew}]
	if {$xotclMapNew} {::nsf::method::alias ::xotcl::Class new $mappedNew }
      }
      #
      # Evaluate the command under catch to ensure reverse mapping
      # of "new"
      #
      set errorOccurred [catch \
                            [list ::apply [list {} $cmds $object]] \
                            result errorOptions]

      #
      # Remove the mapped "new" method, if it was added above
      #
      if {$nxMapNew} {::nsf::method::alias ::nx::Class new $plainNew}
      if {[::nsf::is class ::xotcl::Class]} {
	if {$xotclMapNew} {::nsf::method::alias ::xotcl::Class new $plainNew}
      }
      #
      # Report the error with message and code when necessary
      #
      if {$errorOccurred} {
        dict incr errorOptions -level
        dict unset errorOptions -errorinfo
      }
      return -options $errorOptions $result

    } else {
      ::apply [list {} $cmds $object]
    }
  }

  ######################################################################
  # copy/move implementation
  ######################################################################

  Class create ::nx::CopyHandler {

    :property {targetList ""}
    :property {dest ""}
    :property objLength

    :method makeTargetList {t} {
      if {[::nsf::is object,type=::nx::EnsembleObject $t]} {
	#
	# we do not copy ensemble objects, since method
	# introspection/recreation will care about these
	#
	return
      }
      lappend :targetList $t
      #puts stderr "COPY makeTargetList $t targetList '${:targetList}'"
      # if it is an object without namespace, it is a leaf
      if {[::nsf::object::exists $t]} {
	if {[::nsf::directdispatch $t ::nsf::methods::object::info::hasnamespace]} {
	  # make target list from all children
	  set children [$t info children]
        } else {
	  # ok, no namespace -> no more children
	  return
        }
      }
      # now append all namespaces that are in the obj, but that
      # are not objects
      foreach c [namespace children $t] {
        if {![::nsf::object::exists $c]} {
          lappend children [namespace children $t]
        }
      }

      # a namespace or an obj with namespace may have children
      # itself
      foreach c $children {
        :makeTargetList $c
      }
    }

    # construct destination obj name from old qualified ns name
    :method getDest {origin} {
      if {${:dest} eq ""} {
	return ""
      } else {
	set tail [string range $origin [set :objLength] end]
	return ::[string trimleft [set :dest]$tail :]
      }
    }

    :method copyTargets {} {
      #puts stderr "COPY will copy targetList = [set :targetList]"
      set objs {}
      array set cmdMap {alias alias forward forward method create setter setter}

      foreach origin [set :targetList] {
        set dest [:getDest $origin]
        if {[::nsf::object::exists $origin]} {
	  if {$dest eq ""} {
	    #set obj [[$origin info class] new -noinit]
	    set obj [::nsf::object::alloc [$origin info class] ""]
	    #nsf::object::property $obj initialized 1
	    set dest [set :dest $obj]
	  } else {
	    #
	    # Slot container are handled separately, since
	    # ::nx::slotObj does already the right thing. We have just
	    # to copy the variables (XOTcl keeps the parameter
	    # definitions there).
	    #
	    if {[::nsf::object::property $origin slotcontainer]} {
	      ::nx::slotObj -container [namespace tail $origin] \
		  [namespace qualifiers $dest]
	      ::nsf::nscopyvars $origin $dest
	      continue
	    } else {
	      #
	      # create an object without calling init
	      #
	      #set obj [[$origin info class] create $dest -noinit]
	      set obj [::nsf::object::alloc [$origin info class] $dest]
	      #nsf::object::property $obj initialized 1
	      #puts stderr "COPY obj=<$obj>"
	    }
	  }

          # copy class information
          if {[::nsf::is class $origin]} {
	    # obj is a class, copy class specific information
            ::nsf::relation::set $obj superclass [$origin ::nsf::methods::class::info::superclass]
            ::nsf::method::assertion $obj class-invar [::nsf::method::assertion $origin class-invar]
	    ::nsf::relation::set $obj class-filter [::nsf::relation::get $origin class-filter]
	    ::nsf::relation::set $obj class-mixin [::nsf::relation::get $origin class-mixin]
	    ::nsf::nscopyvars ::nsf::classes$origin ::nsf::classes$dest

	    foreach m [$origin ::nsf::methods::class::info::methods -path -callprotection all] {
	      set rest [lassign [$origin ::nsf::methods::class::info::method definition $m] . protection what .]

	      # remove -returns from reported definitions
	      set p [lsearch -exact $rest -returns]
              if {$p > -1} {set rest [lreplace $rest $p $p+1]}

              set pathData  [$obj eval [list :__resolve_method_path $m]]
              set object    [dict get $pathData object]

              #
              # Create a copy of the instance method and set the method
              # properties with separate primitive commands.
              #
	      set r [::nsf::method::$cmdMap($what) $object [dict get $pathData methodName] {*}$rest]

	      ::nsf::method::property $object $r returns [$origin ::nsf::methods::class::info::method returns $m]
	      ::nsf::method::property $object $r call-protected [::nsf::method::property $origin $m call-protected]
	      ::nsf::method::property $object $r call-private [::nsf::method::property $origin $m call-private]
	    }
	  }

	  # copy object -> might be a class obj
	  ::nsf::object::property $obj keepcallerself [::nsf::object::property $origin keepcallerself]
	  ::nsf::object::property $obj perobjectdispatch [::nsf::object::property $origin perobjectdispatch]
	  ::nsf::object::property $obj hasperobjectslots [::nsf::object::property $origin hasperobjectslots]
	  ::nsf::method::assertion $obj check [::nsf::method::assertion $origin check]
	  ::nsf::method::assertion $obj object-invar [::nsf::method::assertion $origin object-invar]
	  ::nsf::relation::set $obj object-filter [::nsf::relation::get $origin object-filter]
	  ::nsf::relation::set $obj object-mixin [::nsf::relation::get $origin object-mixin]
	  # reused in XOTcl, no "require namespace" there, so use nsf primitiva
	  if {[::nsf::directdispatch $origin ::nsf::methods::object::info::hasnamespace]} {
	    ::nsf::directdispatch $obj ::nsf::methods::object::requirenamespace
	  }
	} else {
	  namespace eval $dest {}
	}
	lappend objs $obj
	::nsf::nscopyvars $origin $dest

	foreach m [$origin ::nsf::methods::object::info::methods -path -callprotection all] {
	  set rest [lassign [$origin ::nsf::methods::object::info::method definition $m] . protection . what .]

	  # remove -returns from reported definitions
	  set p [lsearch -exact $rest -returns];
          if {$p > -1} {set rest [lreplace $rest $p $p+1]}

          set pathData  [$obj eval [list :__resolve_method_path -per-object $m]]
          set object    [dict get $pathData object]

          #
          # Create a copy of the object method and set the method
          # properties with separate primitive commands.
          #
	  set r [::nsf::method::$cmdMap($what) $object -per-object \
                     [dict get $pathData methodName] {*}$rest]
	  ::nsf::method::property $object -per-object $r \
	      returns [$origin ::nsf::methods::object::info::method returns $m]
	  ::nsf::method::property $object -per-object $r \
	      call-protected [::nsf::method::property $origin -per-object $m call-protected]
	  ::nsf::method::property $object -per-object $r \
	      call-private [::nsf::method::property $origin -per-object $m call-private]
	}

	#
	# transfer the traces
	#
	foreach var [$origin info vars] {
	  set cmds [::nsf::directdispatch $origin -frame object ::trace info variable $var]
	  #puts stderr "COPY $var <$cmds>"
	  if {$cmds ne ""} {
	    foreach cmd $cmds {
	      lassign $cmd op def
	      #$origin trace remove variable $var $op $def
	      set domain [lindex $def 0]
	      if {$domain eq $origin} {
		set def [concat $dest [lrange $def 1 end]]
	      }
	      #puts stderr "COPY $var domain $domain [::nsf::object::exists $domain] && [$domain info has type ::nx::Slot]"
	      #if {[::nsf::object::exists $domain] && [$domain info has type ::nx::Slot]} {
		# slot traces are handled already by the slot mechanism
		#continue
	      #}
	      #
	      # handle the most common cases to replace $origin by $dest in trace command
	      #
	      if {[lindex $def 2] eq $origin} {
		set def [lreplace $def 2 2 $dest]
	      } elseif {[lindex $def 0] eq $origin} {
		set def [lreplace $def 0 0 $dest]
	      }
	      ::nsf::directdispatch $dest -frame object ::trace add variable $var $op $def
	    }
	  }
	}
      }

      #
      # alter 'domain' and 'manager' in slot objects
      #
      foreach origin [set :targetList] {
	set dest [:getDest $origin]
	set slots [list]
	#
	# get class specific slots
	#
	if {[::nsf::is class $origin]} {
	  set slots [$origin ::nsf::methods::class::info::slotobjects -type ::nx::Slot]
	}
	#
	# append object specific slots
	#
	foreach slot [$origin ::nsf::methods::object::info::slotobjects -type ::nx::Slot] {
	  lappend slots $slot
	}

	#puts stderr "replacing domain and manager from <$origin> to <$dest> in slots <$slots>"
	foreach oldslot $slots {
	  set container [expr {[$oldslot cget -per-object] ? "per-object-slot" : "slot"}]
	  set newslot [::nx::slotObj -container $container $dest [namespace tail $oldslot]]
	  if {[$oldslot cget -domain] eq $origin}   {$newslot configure -domain $dest}
	  if {[$oldslot cget -manager] eq $oldslot} {$newslot configure -manager $newslot}
	  $newslot eval :init
	}
      }
      return [lindex $objs 0]
    }

    #:public object method mapSlot {newslot origin dest} {
    #  if {[$oldslot cget -domain] eq $origin}   {$newslot configure -domain $dest}
    #  if {[$oldslot cget -manager] eq $oldslot} {$newslot configure -manager $newslot}
    #  $newslot eval :init
    #}

    :public method copy {obj {dest ""}} {
      #puts stderr "[::nsf::self] copy <$obj> <$dest>"
      set :objLength [string length $obj]
      set :dest $dest
      :makeTargetList $obj
      :copyTargets
    }

  }

  Object public method copy {{newName ""}} {
    if {[string trimleft $newName :] ne [string trimleft [::nsf::self] :]} {
      set h [CopyHandler new]
      set r [$h copy [::nsf::self] $newName]
      $h destroy
      return $r
    }
  }

  Object public method move {newName} {
    if {[string trimleft $newName :] ne [string trimleft [::nsf::self] :]} {
      if {$newName ne ""} {
        :copy $newName
      }
      ### let all subclasses get the copied class as superclass
      if {[::nsf::is class [::nsf::self]] && $newName ne ""} {
        foreach subclass [: ::nsf::methods::class::info::subclass] {
          set scl [$subclass ::nsf::methods::class::info::superclass]
          if {[set index [lsearch -exact $scl [::nsf::self]]] != -1} {
            set scl [lreplace $scl $index $index $newName]
	    ::nsf::relation::set $subclass superclass $scl
          }
        }	
      }
      :destroy
    }
  }


  ######################################################################
  # Methods of meta-classes are methods intended for classes. Make
  # sure, these methods are only applied on classes.
  ######################################################################

  foreach m [Class info methods] {
    ::nsf::method::property Class $m class-only true
  }
  if {[info exists m]} {unset m}

  ######################################################################
  # some utilities
  ######################################################################
  #
  # Provide mechanisms to configure nx
  #
  ::nx::Object create ::nx::configure {
    #
    # Set the default method protection for nx methods. This
    # protection level is used per default for all method definitions
    # of scripted methods, aliases and forwarders without explicit
    # protection specified.
    #
    :object method defaultMethodCallProtection {value:boolean,optional} {
      if {[info exists value]} {
	::nsf::method::create Object __default_method_call_protection args [list return $value]
	::nsf::method::property Object  __default_method_call_protection call-protected true
      }
      return [::nsf::dispatch [::nx::self] __default_method_call_protection]
    }

    #
    # Set the default method accessor handling nx properties. The configured
    # value is used for creating accessors for properties in nx.
    #
    :object method defaultAccessor {value:optional} {
      if {[info exists value]} {
	if {$value ni {"public" "protected" "private" "none"}} {
	  return -code error {defaultAccessor must be "public", "protected", "private" or "none"}
	}
	::nsf::method::create Object __default_accessor args [list return $value]
	::nsf::method::property Object __default_accessor call-protected true
      }
      return [::nsf::dispatch [::nx::self] __default_accessor]
    }
  }
  #
  # Make the default protected methods
  #
  ::nx::configure defaultMethodCallProtection true
  ::nx::configure defaultAccessor none

  #
  # Provide an ensemble-like interface to the ::nsf primitiva to
  # access variables. Note that aliasing in the next scripting
  # framework is faster than namespace-ensembles.
  #
  Object create ::nx::var {
    :public object alias exists ::nsf::var::exists
    :public object alias get ::nsf::var::get
    :public object alias import ::nsf::var::import
    :public object alias set ::nsf::var::set
  }

  #interp alias {} ::nx::self {} ::nsf::self

  set value "add /class/|classes ?/pattern/?|clear|delete /class/|get|guard /class/ /?expr?/|set /class .../"
  set "::nsf::parameter::syntax(::nx::Object::slot::__object::object mixins)"  $value
  set "::nsf::parameter::syntax(::nsf::classes::nx::Class::mixins)"            $value
  # set "::nsf::parameter::syntax(::nsf::classes::nx::Class::superclasses)"      $value
  set "::nsf::parameter::syntax(::nsf::classes::nx::Object::class)"           "?/className/?"
  set value "add /filter/|clear|delete /filter/|get|guard /filter/ ?/expr/?|methods ?/pattern/?|set /filter .../"
  set "::nsf::parameter::syntax(::nx::Object::slot::__object::object filters)" $value
  set "::nsf::parameter::syntax(::nsf::classes::nx::Class::filters)"           $value
  set "::nsf::parameter::syntax(::nsf::classes::nx::Object::eval)"            "/arg/ ?/arg/ ...?"
  unset value

  ::nsf::configure debug 1
}


namespace eval ::nx {

  ######################################################################
  # Define exported Tcl commands
  ######################################################################

  # export the main commands of ::nx
  namespace export Object Class next self current

  set ::nx::confdir ~/.nx
  set ::nx::logdir $::nx::confdir/log

  unset ::nsf::bootstrap
}

if {[info command ::lmap] eq ""} {
  # provide a simple forward compatible version of Tcl 8.6's lmap
  proc lmap {_var list body} {
    upvar 1 $_var var
    set res {}
    foreach var $list {lappend res [uplevel 1 $body]}
    return $res
  }
}

#
# When debug is not deactivated, tell the developer, what happened
#
if {[::nsf::configure debug] > 1} {
  foreach ns {::nsf ::nx} {
    puts "vars of $ns: [info vars ${ns}::*]"
    puts stderr "$ns exports: [namespace eval $ns {lsort [namespace export]}]"
  }
  puts stderr "======= nx loaded"
}

#
# Local variables:
#    mode: tcl
#    tcl-indent-level: 2
#    indent-tabs-mode: nil
# End:
