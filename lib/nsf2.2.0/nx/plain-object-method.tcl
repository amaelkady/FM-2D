package provide nx::plain-object-method 1.0

#
# Provide a convenience layer to define/introspect object specific
# methods without having to use the "object" modifier. By using this
# package, one can use instead of
#
#     nx::Object create o {
#        :public object method foo args {....}
#        :object property p:integer
#        :object mixins add M
#        #...
#        puts [:info object methods]
#     }
#
# simply
#
#     package require nx::plain-object-method
#
#     nx::Object create o {
#        :public method foo args {....}
#        :property p:integer
#        :mixins add M
#        #...
#        puts [:info methods]
#     }
#
# Note that for object specific methods of classes, one has still to
# use "object method" etc. (see also package nx::plass-method).
#

namespace eval ::nx {

  #
  # Define a method to allow configuration for tracing of the
  # convenience methods. Use 
  #
  #    nx::configure plain-object-method-warning on|off
  #
  # for activation/deactivation of tracing. This might be 
  # useful for porting legacy NX programs or for testing
  # default-configuration compliance.
  #
  nx::configure public object method plain-object-method-warning {onoff:boolean,optional} {
    if {[info exists onoff]} {
      set :plain-object-method-warning $onoff
    } else {
      if {[info exists :plain-object-method-warning]} {
	if {${:plain-object-method-warning}} {
	  uplevel {::nsf::log warn "plain object method: [self] [current method] [current args]"}
	}
      }
    }
  }


  nx::Object eval {
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
      :public method $m {args} {
	nx::configure plain-object-method-warning
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
      :public method "info $m" {args} [subst -nocommands {
	nx::configure plain-object-method-warning
	:info object $m {*}[current args]
      }]
    }

    #
    # deletions for object
    #
    foreach m {
      "property"
      "variable"
      "method"
    } {
      nx::Object public method "delete $m" {args} {
	nx::configure plain-object-method-warning
	:delete object [current method] {*}[current args]
      }
    } 

  }


  Object eval {
    #
    # method require, base cases
    #
    :method "require method" {methodName} {
      nx::configure plain-object-method-warning
      ::nsf::method::require [::nsf::self] $methodName 1
      return [:info lookup method $methodName]
    }
    #
    # method require, public explicitly
    #
    :method "require public method" {methodName} {
      nx::configure plain-object-method-warning
      set result [:require object method $methodName]
      ::nsf::method::property [self] $result call-protected false
      return $result
    }
    #
    # method require, protected explicitly
    #
    :method "require protected method" {methodName} {
      nx::configure plain-object-method-warning
      set result [:require object method $methodName]
      ::nsf::method::property [self] $result call-protected true
      return $result
    }

    #
    # method require, private explicitly
    #
    :method "require private method" {methodName} {
      set result [:require object method $methodName]
      ::nsf::method::property [self] $result call-private true
      return $result
    }
  }

}
