#
# This is a basic VCL configuration file for varnish.  See the vcl(7)
# man page for details on VCL syntax and semantics.
#
# $Id: default.vcl 1424 2007-05-15 19:38:56Z des $
#

# Default backend definition.  Set this to point to your content
# server.

backend default {
    set backend.host = "127.0.0.1";
    set backend.port = "8080";
}

acl purge {
    "localhost";
}

#acl noref {
#}

sub vcl_recv {
    # try to prevent references from poorly behaved sites.
    # this doesn't work yet, but can be useful if someone is stealing
    # bandwidth, deep-linking, etc.
#    set req.x-refer = regsub(req.referer, "^http://([^/]+).*$", "$1");
#    if (req.x-refer ~ noref) {
#	error 405 "Roy Keene"
#    }

    # Add a unique header containing the client address
    remove req.http.X-Varnish-For;
    set req.http.X-Varnish-For = client.ip;

    if (req.request != "GET" && req.request != "HEAD") {
	# PURGE request if zope asks nicely
	if (req.request == "PURGE") {
	    if (!client.ip ~ purge) {
		error 405 "Not allowed.";
	    }
	    lookup;
	}
	pipe;
    }
    if (req.http.Expect) {
	pipe;
    }
    if (req.http.Authenticate || req.http.Authorization) {
	pass;
    }
    # We only care about the cookies used for authentication in Editing
    if (req.http.Cookie && req.url ~ "^/_") {
	pass;
    }
    lookup;
}
## Called when a client request is received
#
#sub vcl_recv {
#	if (req.request != "GET" && req.request != "HEAD") {
#		pipe;
#	}
#	if (req.http.Expect) {
#		pipe;
#	}
#	if (req.http.Authenticate || req.http.Cookie) {
#		pass;
#	}
#	lookup;
#}

# Do the PURGE thing
sub vcl_hit {
    if (req.request == "PURGE") {
	set obj.ttl = 0s;
	error 200 "Purged";
    }
}

## Called when the requested object was found in the cache
#
#sub vcl_hit {
#	if (!obj.cacheable) {
#		pass;
#	}
#	deliver;
#}

sub vcl_miss {
    if (req.request == "PURGE") {
	error 404 "Not in cache";
    }
}

## Called when the requested object was not found in the cache
#
#sub vcl_miss {
#	fetch;
#}


# Enforce a minimum TTL,
# since we PURGE changed objects actively
sub vcl_fetch {
    if (obj.ttl < 3600s) {
	set obj.ttl = 3600s;
    }
    if (obj.http.Pragma ~ "no-cache" || obj.http.Cache-Control ~ "no-cache" || obj.http.Cache-Control ~ "private") {
      pass;
    }
}


## Called when the requested object has been retrieved from the
## backend, or the request to the backend has failed
#
#sub vcl_fetch {
#	if (!obj.valid) {
#		error;
#	}
#	if (!obj.cacheable) {
#		pass;
#	}
#	if (resp.http.Set-Cookie) {
#		pass;
#	}
#	insert;
#}


# Below is a commented-out copy of the default VCL logic.  If you
# redefine any of these subroutines, the built-in logic will be
# appended to your code.

## Called when entering pipe mode
#
#sub vcl_pipe {
#	pipe;
#}

## Called when entering pass mode
#
#sub vcl_pass {
#	pass;
#}

sub vcl_hash {
        if (req.http.Accept-Encoding ~ "gzip") {
                set req.hash += "gzip";
        }
        else if (req.http.Accept-Encoding ~ "deflate") {
                set req.hash += "deflate";
        }
}

## Called when entering an object into the cache
#
#sub vcl_hash {
#	hash;
#}

## Called when an object nears its expiry time
#
#sub vcl_timeout {
#	discard;
#}
