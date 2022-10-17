package require nx
package provide nx::trait 0.4

# @package nx::trait
# 
# Minimal trait framework with checking in NX, based on
#
#    S. Ducasse, O. Nierstrasz, N. Schärli, R. Wuyts, A. Black:
#    Traits: A Mechanism for Fine-grained Reuse,
#    ACM transactions on Programming Language Systems, Vol 28, No 2, March 2006
#
# Gustaf Neumann (Aug 2011)
#
# Traits are a mechanism for the reuse of methods. In contrary to
# other forms of reuse (e.g. inheritance of methods in a class
# hierarchy or via mixin classes), the methods defined in traits are
# materialized in the target objects and classes. This gives more
# fine-grained control over the reuse of methods and overcomes the
# "total composition ordering" limitation of mixins.
#
# The current implementation does not handle overwrites (conflicting
# definition from several traits), be we handle renames (aliases) and
# we check required methods. "requiredVariables" (not part of the
# ducasse paper) are not checked yet.
#
# In essence, the package provides a class "nx::Trait" to define
# Traits and a method "useTrait" to reuse a trait in trait consumer
# (e.g. a class or another trait).
#
# Usage: 
#     package require nx::trait
#     nx::Trait create .... {
#        ...
#     }
#     nx::Class create .... {
#        ...
#        :useTrait ...
#     }
#

#
# Define a method to allow configuration for verbosity of the
# trait operations:
#
#    nx::configure trait-verbosity on|off
#
# This might be useful for debugging of complex trait compositions.
#

nx::configure public object method trait-verbosity {onoff:boolean,optional} {
  if {[info exists onoff]} {
    set :trait-verbosity $onoff
  } else {
    set :trait-verbosity
  }
}
nx::configure  trait-verbosity off


namespace eval ::nx::trait {

  #
  # nx::trait::provide and nx::trait::require implement a basic
  # auto-loading mechanism for traits
  #
  nsf::proc provide {traitName script} {
    set ::nsf::traitIndex($traitName) [list script $script]
  }

  nsf::proc require {traitName} {
    if {[::nsf::object::exists $traitName]} {return}
    set key ::nsf::traitIndex($traitName)
    if {[info exists $key]} {
      array set "" [set $key]
      if {$(script) ne ""} {
	eval $(script)
      }
    }
    if {[::nsf::object::exists $traitName]} {return}
    error "cannot require trait $traitName, trait unknown"
  }

  #
  # The function nx::trait::add adds the methods defined in the
  # specified trait to the obj/class provided as first argument.
  #
  nsf::proc add {obj -per-object:switch traitName {nameMap ""}} {
    array set map $nameMap
    if {${per-object} || ![::nsf::is class $obj]} {
      error "per-object traits are currently not supported"
    }
    foreach m [$traitName info methods -callprotection all -path] {
      if {[info exists map($m)]} {set newName $map($m)} else {set newName $m}
      # do not add entries with $newName empty
      if {$newName eq ""} continue
      set traitMethodHandle [$traitName info method definitionhandle $m]
      $obj public alias $newName $traitMethodHandle
      if {[nx::configure trait-verbosity]} {
	puts "...trait: $obj public alias $newName"
      }
    }
    foreach slot [$traitName info variables] {
      #puts "$obj - will define: [$traitName info variable definition $slot]"
      $obj {*}[lrange [$traitName info variable definition $slot] 1 end]
      if {[nx::configure trait-verbosity]} {
	puts "...trait: $obj [lrange [$traitName info variable definition $slot] 1 end]"
      }
    }
  }
  
  #
  # The function nx::trait::checkObject checks, whether the target
  # object has the method defined that the trait requires.
  #
  nsf::proc checkObject {obj traitName} {
    foreach m [$traitName cget -requiredMethods] {
      #puts "$m ok? [$obj info methods -closure $m]"
      if {[$obj info lookup method $m] eq ""} {
	error "trait $traitName requires $m, which is not defined for $obj"
      }
    }
  }
  
  #
  # The function nx::trait::checkClass checks, whether the target
  # class has the method defined that the trait requires.
  #
  nsf::proc checkClass {obj traitName} {
    foreach m [$traitName cget -requiredMethods] {
      #puts "$m ok? [$obj info methods -closure $m]"
      if {[$obj info methods -closure $m] eq ""} {
	error "trait $traitName requires $m, which is not defined for $obj"
      }
    }
  }
}

#
# The require methods for traits extend the predefined ensemble with
# trait-specific subcommands.
#
nx::Class public method "require trait" {traitName {nameMap ""}} {
  # adding a trait to a class
  if {[nx::configure trait-verbosity]} {
    puts "trait: [self] requires $traitName"
  }
  nx::trait::require $traitName
  nx::trait::checkClass [self] $traitName
  nx::trait::add [self] $traitName $nameMap  
}

#nx::Object public method "require object trait" {traitName {nameMap ""}} {
#  puts "[self] require object trait $traitName -- MAYBE OBSOLETE"
#  # adding a trait to an object
#  nx::trait::require $traitName
#  nx::trait::checkObject [self] $traitName
#  nx::trait::add [self] -per-object $traitName $nameMap
#}

#
# The class "nx::Trait" provides the basic properties and methods needed for
# the trait management.
#
nx::Class create nx::Trait -superclass nx::Class {
  :property {package}
  :property {requiredMethods:0..n ""}
  :property {requiredVariables:0..n ""}

  ::nsf::method::setter [self] requiredMethods:0..n
  ::nsf::method::setter [self] requiredVariables:0..n

  :public method "require trait" {traitName {nameMap ""}} {
    # adding a trait to a trait
    nx::trait::require $traitName
    nx::trait::add [self] $traitName $nameMap
    set finalReqMethods {}
    # remove the methods from the set of required methods, which became available
    foreach m [lsort -unique [concat ${:requiredMethods} [$traitName cget -requiredMethods]]] {
      if {[:info methods $m] eq ""} {lappend finalReqMethods $m}
    }
    #puts "final reqMethods of [self]: $finalReqMethods // defined=[:info methods]"
    set :requiredMethods $finalReqMethods
  }
}

#
# Local variables:
#    mode: tcl
#    tcl-indent-level: 2
#    indent-tabs-mode: nil
# End:
