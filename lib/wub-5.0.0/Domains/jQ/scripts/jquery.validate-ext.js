$.validator.addMethod("ident", function(value, element) {
			return this.optional(element) || /^[a-zA-Z][a-zA-Z0-9_]*$/.test(value);
		      }, "Please enter an identifier.");
