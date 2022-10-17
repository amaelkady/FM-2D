package require nx
package provide nx::pp 1.0

# @package nx::pp
# 
# A simple pretty printer for Tcl/XOTcl/NX
# that converts a script into HTML output.
#
# Usage: 
#     package require nx::pp
#     set html [nx::pp render { your script }]
#
# Designed to be usable from asciidoc like gnu source-highligt,
# ignores options.
#
# Gustaf Neumann,   Dez 2010

namespace eval ::nx::pp {
  #
  # The pretty printer is implemented via several States objects that
  # represent different context for input processing. Such states are
  # for example "comment" or "quoted strings". Every state contains
  # the parsed content, and a CSS class for HTML rendering.
  #
  nx::Class create State {
    :property {text ""}
    :property {cssClass:substdefault "[namespace tail [nx::self]]"}
    :property {prevState:substdefault "[default]"}
    
    :public method start {char} {
      # Start output in a state by initializing the text buffer.
      set :text $char
      return [nx::self]
    }

    :public method cssWrap {html} {
      if {${:cssClass} ne ""} {
	return "<span class='nx-${:cssClass}'>$html</span>"
      } else {
	return $html
      }
    }
    
    :public method flush {} {
      # Flush the current text in the buffer using the css class
      set html [string map [list & {&amp;} < {&lt;} > {&gt;}] ${:text}]
      ::nx::pp puts -nonewline [:cssWrap $html]
      set :text ""
    }
    
    :method new_state {new lastChar firstChar} {
      # Switch from one state to another state
      if {[$new eval {info exists :escape}]} {
	$new configure -prevState [nx::self]
	append :text $lastChar
	return [$new]
      } else {
	$new configure -prevState [default]
	append :text $lastChar
	:flush
	return [$new start $firstChar]
      }
    }
    
    :public method process {char} {
      # Process a single character in the current state
      append :text $char
      return [nx::self]
    }
  }
  
  #
  # Below, we define the state objects for processing the input
  #
  State create default -cssClass "" {
    #
    # The State "default" is processing bare Tcl words. In this state,
    # we perform substitutions of keywords and placeholders.
    #
    :public object method process {char} {
      switch $char {
	"\#" { return [:new_state comment "" $char]}
	"\"" { return [:new_state quoted "" $char]}
	"\$" { return [:new_state variable "" $char]}
	default {return [nx::next]}
      }
    }

    set keywords {
      after append apply array binary break catch cd chan clock close concat continue
      dict else encoding eof error eval exec exit expr fblocked fconfigure fcopy file 
      fileevent flush for foreach format gets glob global if incr info interp join
      lappend lassign lindex linsert list llength load lrange lrepeat lreplace lreverse
      lsearch lset lsort namespace open pid proc puts read regexp regsub rename return 
      scan seek set socket source split stdin stderr stdout string subst switch 
      tell trace unset uplevel update upvar variable vwait while
      package
      public protected private
      method alias property forward delete require
      my next new self current dispatch objectparameter defaultmethod
      create init new destroy alloc dealloc recreate unknown move cget configure
      class object superclass mixin filter guard metaclass
      methods lookup
      ::nx::Class nx::Class ::xotcl::Class xotcl::Class Class 
      ::nx::Object nx::Object ::xotcl::Object xotcl::Object Object 
      ::nx::VariableSlot nx::VariableSlot Attribute 
    }
    set :re(keyword1) (\[^:.-\])(\\m[join $keywords \\M|\\m]\\M)
    set :re(keyword2) (\[^:\])(\\m:[join $keywords \\M|:\\m]\\M)

    set :re(placeholder1) {([/][a-zA-Z0-9:]+?[/])}
    set :re(placeholder2) {([?][^ ][-a-zA-Z0-9: .]+?[?])}

    :public object method flush {} {
      set html [string map [list & {&amp;} < {&lt;} > {&gt;}] ${:text}]
      regsub -all [set :re(keyword1)] " $html" {\1<span class='nx-keyword'>\2</span>} html
      regsub -all [set :re(keyword2)] $html {\1<span class='nx-keyword'>\2</span>} html
      set html [string range $html 1 end]
      regsub -all [set :re(placeholder1)] $html {<span class='nx-placeholder'>\1</span>} html
      regsub -all [set :re(placeholder2)] $html {<span class='nx-placeholder'>\1</span>} html
      nx::pp puts -nonewline [:cssWrap $html]
      set :text ""
    }
  }
  
  State create quoted -cssClass "string" {
    #
    # The State "quoted" is for content between double quotes.
    #
    :public object method process {char} {
      switch $char {
	"\""    {return [:new_state ${:prevState} $char ""]}
	"\\"    {return [:new_state escape $char ""]}
	default {return [nx::next]}
      }
    }
  }
  
  State create comment {
    #
    # The State "comment" is for Tcl comments (currently, only up to
    # end of line)
    #
    :public object method process {char} {
      switch $char {
	"\n"    {return [:new_state default $char ""]}
	default {return [nx::next]}
      }
    }
  }

  State create variable {
    #
    # The State "variable" is for simple Tcl variables (without curley
    # braces)
    #
    :public object method process {char} {
      switch -glob -- $char {
	{\{}            {return [:new_state quoted_variable $char ""] }
	{[a-zA-Z0-9_:]} {return [nx::next]} 
	default         {return [:new_state default "" $char]}
      }

    }
  }
 
  State create quoted_variable -cssClass "variable" {
    #
    # The State "quoted_variable" is for Tcl variables, where the
    # names are quoted with curley braces.
    #
    :public object method process {char} {
      switch -glob -- $char {
	{\}}    {return [:new_state default $char ""] }
	default {return [nx::next]}
      }
    }
  }

  State create escape -cssClass "" {
    #
    # The State "escape" is for simple backslash handling.
    #
    # Set an instance variable to ease identification of the state
    set :escape 1

    #  When a character is processed in the escape state, it is suffed
    #  into the previous state and returns immediately to it.
    #
    :public object method process {char} {
      ${:prevState} eval [list append :text $char]
      return ${:prevState}
    }
  }
}

#
# Finally, we create a simple pretty-printer as an object. The
# method render receives a Tcl script as input and writes the HTML
# output to stdout
#
nx::Object create nx::pp {
  
  :public object method toHTML {block} {
    set state [self]::default
    set l [string length $block]
    for {set i 0} {$i < $l} {incr i} {
      set state [$state process [string index $block $i]]
    }
    $state flush
  }

  :public object method numbers {block} {
    set nrlines [regsub -all \n $block \n block]
    incr nrlines
    set HTML ""
    for {set i 1} {$i<=$nrlines} {incr i} {
      append HTML [format %3d $i]\n
    }
    return $HTML
  }

  :public object method render {{-linenumbers false} -noCSSClasses:switch block} {
    set :output ""
    :toHTML $block
    set HTML ${:output}
    set :output ""
    :puts "<style type='text/css'>"
    :puts ".nx             {color: #000000; font-weight: normal; font-style: normal; padding-left: 10px}"
    :puts "table.nx        {border-collapse: collapse; border-spacing: 3px;}"
    :puts ".nx-linenr      {border-right: 1px solid #DDDDDD;padding-right: 5px; color: #2B547D;font-style: italic;}"
    :puts ".nx-string      {color: #779977; font-weight: normal; font-style: italic;}"
    :puts ".nx-comment     {color: #717ab3; font-weight: normal; font-style: italic;}"
    :puts ".nx-keyword     {color: #7f0055; font-weight: normal; font-style: normal;}"
    :puts ".nx-placeholder {color: #AF663F; font-weight: normal; font-style: italic;}"
    :puts ".nx-variable    {color: #AF663F; font-weight: normal; font-style: normal;}"
    :puts "</style>"
    if {$linenumbers} {
      :puts -nonewline "<table class='nx'><tr><td class='nx-linenr'><pre>[:numbers $block]</pre></td>"
      :puts -nonewline "<td class='nx-body'><pre class='nx'>$HTML</pre></td></tr></table>"
    } else {
      :puts -nonewline "<pre class='nx'>$HTML</pre>"
    }
    return ${:output}
  }

  :public object method puts {{-nonewline:switch} string} {
    append :output $string
    if {!$nonewline} {append :output \n}
  }
}

# pp render {
#   set x "hello\ngoodbye"
#   # a comment line
#   set b $c($a).b
#   foo a ${:text} b "hello \"$x" world
# }
# exit
