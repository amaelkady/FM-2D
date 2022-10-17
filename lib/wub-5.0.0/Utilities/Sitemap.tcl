# Sitemap.tcl - generate a google sitemap from a dict (like a file)

package require Html
package require Http
package provide Sitemap 1.0

set ::API(Utilities/Sitemap) {
    {
	Sitemap - generates a site map for google et al.
    }
}

namespace eval ::Sitemap {
    # wrap characters which offend HTML
    proc esc {string} {
  	return [string map {& &amp; ' &apos; \" &quot; > &gt; < &lt;} $string]
    }

    # location - generate loc record for sitemap
    proc location {prefix n args} {
	if {[llength $args] == 1} {
	    set args [lindex $args 0]
	}
	return [subst {<url>
	    [<loc> [esc ${prefix}$n]]
	    [<lastmod> [clock format [dict get $args mtime] -format {%Y-%m-%dT%H:%M:%SZ}]]
	    [If {[dict exists $args changefreq]} {
		[<changefreq> [dict get $args changefreq]]
	    }]
	    [If {[dict exists $args priority]} {
		[<priority> [dict get $args priority]]
	    }]
	    </url>}]
    }

    # sitemap - wrap generated map in sitemap XML
    proc sitemap {string} {
	return "<?xml version='1.0' encoding='UTF-8'?>
	    [<urlset> xmlns http://www.sitemaps.org/schemas/sitemap/0.9 $string]"
    }

    # dict2map - turn a dict into a sitemap
    proc dict2map {prefix args} {
	if {[llength $args] == 1} {
	    set args [lindex $args 0]
	}
	return [sitemap [subst {
	    [Foreach {n v} $args {
		[location $prefix $n $v]
	    }]
	}]]
    }

    # dir2map - turn a directory into a sitemap
    proc dir2map {prefix dir {glob *}} {
	set dir [file normalize $dir]
	set dict {}
	foreach file [::fileutil::findByPattern $dir -glob $glob] {
	    catch {unset attr}
	    file lstat $file attr
	    set name [::fileutil::stripPath $dir $file]
	    dict set dict $name [list name $name {*}[array get attr]]
	}
	return [dict2map $prefix $dict]
    }

    # siteindex - wrap generated map in siteindex
    proc siteindex {string} {
	return "<?xml version='1.0' encoding='UTF-8'?>
	    [<sitemapindex> xmlns http://www.sitemaps.org/schemas/sitemap/0.9 $string]"
    }

    # dict2index - turn a dict into a siteindex
    proc dict2index {prefix args} {
	if {[llength $args] == 1} {
	    set args [lindex $args 0]
	}
	return [Foreach {n v} $args {
	    [<sitemap> [subst {
		[<loc> ${prefix}$n]
		[<lastmod> [Http Date [args get $v mtime]]]
	    }]]
	}]
    }

    # dir2index - turn a directory into a siteindex
    proc dir2index {prefix dir {glob *}} {
	set dir [file normalize $dir]
	set dict {}
	foreach file [::fileutil::findByPattern $dir -glob $glob] {
	    catch {unset attr}
	    file lstat $file attr
	    set name [::fileutil::stripPath $dir $file]
	    dict set dict $name [list name $name {*}[array get attr]]
	}
	return [dict2index $prefix $dict]
    }

    namespace export -clear *
    namespace ensemble create -subcommands {}
}
