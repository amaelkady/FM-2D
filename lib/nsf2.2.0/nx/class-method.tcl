package provide nx::class-method 1.0

#
# Provide a convenience layer to class methods/variables by using
# "class method" rather than "object method". This reflects the naming
# conventions of NX 2.0b4 and earlier. By using this package, one can
# use instead of
#
#     nx::Class create C {
#        :public object method foo args {....}
#        :object property p:integer
#        :object mixins add M
#        #...
#        puts [:info object methods]
#     }
#
# a terminology closer to text book vocabulary
#
#     package require nx::class-method
#
#     nx::Object create o {
#        :public class method foo args {....}
#        :class property p:integer
#        :class mixins add M
#        #...
#        puts [:class info methods]
#     }
#
# Note that for object specific methods of object, have still to be
# defined via "object method" etc. (see also package
# nx::plain-object-method).
#

#
# make "class" an accepted method defining method
#
namespace eval ::nsf {
  array set ::nsf::methodDefiningMethod {
    class 1
  }
}

namespace eval ::nx {
  #
  # Define a method to allow configuration for tracing of the
  # convenience methods. Use 
  #
  #    nx::configure class-method-warning on|off
  #
  # for activation/deactivation of tracing. This might be 
  # useful for porting legacy NX programs or for testing
  # default-configuration compliance.
  #
  nx::configure public object method class-method-warning {onoff:boolean,optional} {
    if {[info exists onoff]} {
      set :class-method-warning $onoff
    } else {
      if {[info exists :class-method-warning]} {
	if {${:class-method-warning}} {
	  uplevel {::nsf::log warn "class method: [self] [current method] [current args]"}
	}
      }
    }
  }


  nx::Class eval {

    #
    # Definitions redirected to "object"
    #
    foreach m {
      alias 
      filters 
      forward 
      method 
      mixins 
      property 
      variable
    } {
      :public method "class $m" {args} {
	nx::configure class-method-warning
	:object [current method] {*}[current args]
      }
    }    

    #
    # info subcommands 
    #
    foreach m {
      method methods slots variables
      filters mixins
    } {
      :public method "class info $m" {args} [subst -nocommands {
	nx::configure class-method-warning
	:info object $m {*}[current args]
      }]
    }
  }

  #
  # Deletions
  #
  foreach m {
    property
    variable
    method
  } {
    nx::Class public method "class delete $m" {args} {
      nx::configure class-method-warning
      :delete object [current method] {*}[current args]
    }
  }

  ######################################################################
  # Provide method "require"
  ######################################################################
  Object eval {
    #
    # method require, base cases
    #
    :method "require class method" {methodName} {
      nx::configure class-method-warning
      ::nsf::method::require [::nsf::self] $methodName 1
      return [:info lookup method $methodName]
    }
    #
    # method require, public explicitly
    #
    :method "require public class method" {methodName} {
      nx::configure class-method-warning
      set result [:require class method $methodName]
      ::nsf::method::property [self] $result call-protected false
      return $result
    }
    #
    # method require, protected explicitly
    #
    :method "require protected class method" {methodName} {
      nx::configure class-method-warning
      set result [:require class method $methodName]
      ::nsf::method::property [self] $result call-protected true
      return $result
    }
    #
    # method require, private explicitly
    #
    :method "require private class method" {methodName} {
      nx::configure class-method-warning
      set result [:require class method $methodName]
      ::nsf::method::property [self] $result call-private true
      return $result
    }
  }
}
