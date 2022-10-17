/***********************************************
 * Dynamic Ajax Content- © Dynamic Drive DHTML code library (www.dynamicdrive.com)
 * This notice MUST stay intact for legal use
 * Visit Dynamic Drive at http://www.dynamicdrive.com/ for full source code
 * Functions taken from Dynamic Ajax Content:
 *    ajaxpage
 *    loadpage
 ***********************************************/
    
function ajaxpage(url, containerid){
    var page_request = false
    if (window.XMLHttpRequest) // if Mozilla, Safari etc
        page_request = new XMLHttpRequest()
    else if (window.ActiveXObject){ // if IE
	try {
	    page_request = new ActiveXObject("Msxml2.XMLHTTP")
	} 	
	catch (e){
	    try{
		page_request = new ActiveXObject("Microsoft.XMLHTTP")
	    }
	    catch (e){}
	}
    }
    else
        return false
    page_request.onreadystatechange=function(){
	loadpage(page_request, containerid)
    }
    page_request.open('GET', url, true)
    page_request.send(null)
}

function loadpage(page_request, containerid){

    if (page_request.readyState == 4 && (page_request.status==200 || window.location.href.indexOf("http")==-1))
        document.getElementById(containerid).innerHTML=page_request.responseText;
}

/***********************************************/
    
function ajaxtocpage(url, containerid){
    var page_request = false
    if (window.XMLHttpRequest) // if Mozilla, Safari etc
        page_request = new XMLHttpRequest()
    else if (window.ActiveXObject){ // if IE
	try {
	    page_request = new ActiveXObject("Msxml2.XMLHTTP")
	} 	
	catch (e){
	    try{
		page_request = new ActiveXObject("Microsoft.XMLHTTP")
	    }
	    catch (e){}
	}
    }
    else
        return false
    page_request.onreadystatechange=function(){
	loadtocpage(page_request, containerid)
    }
    page_request.open('GET', url, true)
    page_request.send(null)
}

function loadtocpage(page_request, containerid){
    if (page_request.readyState == 4 && (page_request.status==200 || window.location.href.indexOf("http")==-1)) {
	if (page_request.responseText.length) {
	    eval(page_request.responseText);
	}
    }
}

function ajaxtocpages(N){
    ajaxtocpage('/_toc/' + N, 'wiki_toc');
    document.getElementById('wrapper').style.marginLeft = '-200px';
    document.getElementById('content').style.marginLeft = '200px';
}

function ajaxnotocpages(){
    document.getElementById('wrapper').style.marginLeft = '0';
    document.getElementById('content').style.marginLeft = '0';
}

function getCookie(c_name)
{
    if (document.cookie.length>0) {
	c_start=document.cookie.indexOf(c_name + "=");
	if (c_start!=-1) { 
	    c_start=c_start + c_name.length+1;
	    c_end=document.cookie.indexOf(";",c_start);
	    if (c_end==-1) c_end=document.cookie.length;
	    return unescape(document.cookie.substring(c_start,c_end));
	} 
    }
    return ""
}

function checkTOC(N)
{
    needs_toc=getCookie('witoc')
    if (needs_toc!=null && needs_toc=="1") {
	ajaxtocpages(N);
    } else {
	ajaxnotocpages();
    }
}

function toggleTOC(N)
{
    needs_toc=getCookie('witoc')
    if (needs_toc!=null && needs_toc=="1") {
	ajaxnotocpages();
    } else {
	ajaxtocpages(N);
    }
}
