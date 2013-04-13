/*
defne(function(){
	var trans = function(w){
		var encode = /"|&|'|<|>|[\x00-\x20]|[\x7F-\xFF]|[\u0100-\u2700]/g;
		w.replace(encode,function(a){
			var c = a.charCodeAt(0), r = ["&#"];
            c = (c == 0x20) ? 0xA0 : c;
            r.push(c); r.push(";");
            return r.join("");	
		});
		return w;
	};
	return {htmltrans:trans};
});
*/
define(function (){
	var trans = function (w){
		var s = "";  
		if (w.length == 0) return "&nbsp;";  
		s = w.replace(/&/g, "&gt;");  
		s = s.replace(/</g, "&lt;");  
		s = s.replace(/>/g, "&gt;");  
		s = s.replace(/ /g, "&nbsp;");  
		s = s.replace(/\'/g, "&#39;");  
		s = s.replace(/\"/g, "&quot;");  
		s = s.replace(/\n/g, "<br>");  
		return s;
	};
	return {
		trans: trans
	};
});