/* Plugin: safe_mail
 * Author: Michael D. Risser <MDRISSER AT the domain called GMAIL which is a dot COM>
 * Date: October 2007
 *
 * Description:
 *		With the proliferation of spammers out there, scrapping email addresses off of web sites,
 *		this plugin for jQuery makes it easy to hide email address from spam bots.
 *		
 *		The plugin is far from perfect, but it works, although I plan to expand on it as time permits.
 *		Usage is pretty straight forward, as shown below. The only caveat is that you need an element to
 *		append the mailto link to. You can simply place an empty div or span where you want the email link to
 *		appear, and access it using the id you have provided. For example:
 *			<p>Here is a bunch of text in a paragraph, where I want an <span id='email_link'></span> to
 *			appear. Since the plugin appends to an element, I've included an empty span tag where I want
 *			the email address to appear.</p>
 * Usage:
 *		To use the email address as the link text:
 *			$('#email_link').safe_mail("john.doe", "domain", "com");
 *			Ouput: <a href="mailto:john.doe@domain.com">john.doe@domain.com</a>
 *
 *		To use some other text as the link text:
 *			$('#email_link').safe_mail("john.doe", "domain", "com", "This is my email link text");
 *			Ouput: <a href="mailto:john.doe@domain.com">This is my email link text</a>
 */

jQuery.fn.safe_mail = function(username, domain_name, domain_ext, link_text) {
	if(link_text) {
		link_txt = link_text;
	} else {
		link_txt = "link"	
	}
	
	// If no link text(link_txt) is specified, or if the user explicitally sets link_txt to "link"
	if(link_txt == "link") {
		// Use the link its self as the link text
		mail_link = "<a " + "href" + "=" + "'mail" + "to" + ":" + username + "@" + domain_name + "." + domain_ext +"'>" + username + "@" + domain_name + "." + domain_ext +"</a>";
	} else {
		// Otherwise use the user provided link text
		mail_link = "<a " + "href" + "=" + "'mail" + "to" + ":" + username + "@" + domain_name + "." + domain_ext +"'>" + link_txt +"</a>";
	}
	
	$(this).append(mail_link);
};