/* Copyright 2011 Google Inc. All Rights Reserved. */
(function() {
	var b = null,
		c = 0,
		d = b,
		e = b,
		f = b,
		h = b,
		k = b,
		l = b,
		m = function(a) {
			a.target = "_blank";
			a.addEventListener("click", function() {
				window.close()
			}, !1)
		},
		q = function() {
			var a;
			if (a = e.value.replace(/^\s+|\s+$/g, "")) f.innerHTML = "Searching...", f.style.display = "block", h.style.display = "none", k.style.display = "none", l.style.display = "none", d.disabled = !0, c++, chrome.extension.sendMessage({
				type: "fetch_html",
				eventKey: c,
				query: a
			}, n)
		},
		n = function(a) {
			if (a.eventKey == c) {
				if (a.html) {
					l.innerHTML = a.html;
					var p = l.getElementsByTagName("span");
					a = 0;
					for (var g; g = p[a]; a++)("dct-lnk" == g.className || "dct-rlnk" == g.className) && g.addEventListener("click", function() {
						e.value = this.title ? this.title : this.innerHTML;
						q()
					}, !1);
					p = l.getElementsByTagName("a");
					for (a = 0; g = p[a]; a++) m(g);
					f.style.display = "none";
					l.style.display = "block"
				} else f.innerHTML = "No definition found.", f.style.display = "block", h.href = "http://www.google.com/search?q=" + a.sanitizedQuery, h.innerHTML = 'Search the web for "' + a.sanitizedQuery + '" »', h.style.display = "block";
				d.disabled = !1
			}
		},
		d = document.getElementById("button"),
		e = document.getElementById("query-field");
	e.focus();
	f = document.getElementById("lookup-status");
	h = document.getElementById("web-search-link");
	m(h);
	k = document.getElementById("usage-tip");
	l = document.getElementById("meaning");
	m(document.getElementById("options-link"));
	d.addEventListener("click", q, !1);
	e.addEventListener("keydown", function(a) {
		13 == a.keyCode && q()
	}, !1);
	k.innerHTML = "Tip: Select text on any webpage, then click the Google Dictionary button to view the definition of your selection.";
	k.style.display = "block";
	chrome.tabs.getSelected(b, function(a) {
		chrome.tabs.sendMessage(a.id, {
			type: "get_selection"
		}, function(a) {
			a.selection && (e.value = a.selection, q())
		})
	});
})();