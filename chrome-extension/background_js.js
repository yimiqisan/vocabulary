/* Copyright 2011 Google Inc. All Rights Reserved. */
(function() {
	var h = !0,
		k = null,
		m = !1,
		n = RegExp("<[^>]*>", "g"),
		q = RegExp("[<>]", "g"),
		s = "\" ' ( ) , - . / 1 2 2012 : ? a about and are as be but com for from have i in is it like may more my next not of on search that the this to was when with you your".split(" "),
		t = {},
		w = 0,
		x = -1,
		y = -1,
		z = function(a) {
			a = a.replace(n, "");
			a = a.replace(q, "");
			return a = a.substring(0, 100).toLowerCase()
		},
		A = function(a, c) {
			for (var b = 0, d = a.length; b < d; b++) if (c == a[b]) return h;
			return m
		},
		B = function() {
			t = JSON.parse(window.localStorage.options)
		},
		C = function(a, c, b) {
			"initialize" == a.type && (a = {
				instanceId: w++
			}, b(a))
		},
		D = function(a, c, b) {
			"options" == a.type && b({
				options: t
			})
		},
		G = function(a, c, b) {
			if (!("fetch_raw" != a.type && "fetch_html" != a.type)) {
				_gaq && _gaq.push(["_trackEvent", "lookup", a.type]); - 1 != x && y != a.instanceId && chrome.tabs.sendMessage(x, {
					type: "hide",
					instanceId: y
				});
				"fetch_raw" == a.type ? (x = c.tab.id, y = a.instanceId) : y = x = -1;
				c = z(a.query);
				var d = {
					request: a,
					sanitizedQuery: c,
					dictResponse: k,
					translateResponse: k,
					numResponses: 0,
					callback: b
				};
				b = "pr,de";
				"fetch_html" == a.type && (b = "pr,de,sy");
				google.language.define(c, t.language, t.language, function(a) {
					E(a, "dict", d)
				}, {
					restricts: b
				});
				"en" != t.language && google.language.define(c, "en", "en", function(a) {
					E(a, "enDict", d)
				}, {
					restricts: b
				});
				F(c, function(a) {
					E(a, "translate", d)
				});
				chrome.tabs.getSelected(k, function(a) {
					var b = window.setTimeout(function() {
						E({
							lang: "unknown"
						}, "tabLang", d)
					}, 800);
					chrome.tabs.detectLanguage(a.id, function(a) {
						window.clearTimeout(b);
						E({
							lang: a
						}, "tabLang", d)
					})
				});
				return h
			}
		},
		F = function(a, c) {
			var b = new XMLHttpRequest;
			b.open("GET", "https://clients5.google.com/translate_a/t?client=dict-chrome-ex&sl=auto&tl=" + t.language + "&q=" + encodeURIComponent(a), h);
			b.onreadystatechange = function() {
				if (4 == b.readyState) try {
					c(JSON.parse(b.responseText))
				} catch (a) {
					c(k)
				}
			};
			b.send()
		},
		E = function(a, c, b) {
			if ("dict" == c) b.dictResponse = a;
			else if ("enDict" == c) b.enDictResponse = a;
			else if ("translate" == c) b.translateResponse = a;
			else {
				if (b.tabLang) return;
				b.tabLang = "he" == a.lang ? "iw" : a.lang
			}
			a = 3;
			"en" != t.language && (a = 4);
			b.numResponses++;
			if (b.numResponses == a) {
				var d = c = H(b.dictResponse);
				"en" != t.language && (d = H(b.enDictResponse));
				var e = I(b.translateResponse, h);
				a = k;
				if (b.translateResponse && b.translateResponse.ld_result && (a = b.translateResponse.ld_result.srclangs)) for (var f = 0, l = a.length; f < l; f++) a[f] = a[f].toLowerCase();
				l = m;
				if (!c || "licensedDef" != c.type) {
					var f = t.language.toLowerCase(),
						g = e && e.srcLang.toLowerCase() != f;
					if (g && a && !A(a, f) || !c && g) l = h
				}
				a = l ? "translation" : "definition";
				!c && !e && (a = "none");
				_gaq && _gaq.push(["_trackEvent", "lookup", "type_" + a]);
				a = "http://translate.google.com/translate_t?source=dict-chrome-ex&sl=auto&tl=" + t.language + "&q=" + encodeURIComponent(b.sanitizedQuery);
                aa = "http://www.shanbay.com/api/learning/add/" + encodeURIComponent(b.sanitizedQuery);
				f = "http://www.google.com/search?source=dict-chrome-ex&defl=" + t.language + "&hl=" + t.language + "&q=" + encodeURIComponent(b.sanitizedQuery) + "&tbo=1&tbs=dfn:1";
				if ("fetch_html" == b.request.type) {
					if (l) if (c = b.translateResponse, d = I(c, m)) {
						d = '<div class="translate-main">' + d.meaningText + '</div><div class="translate-attrib">(' + d.attribution + ")</div>";
						e = "";
						if (c.dict && 0 < c.dict.length) {
							e = '<h3 class="dct-tl">Translated definitions</h3>';
							f = 0;
							for (l = c.dict.length; f < l; f++) {
								for (var g = c.dict[f], e = e + ("<b>" + g.pos + "</b><ol>"), p = 0, r = g.terms.length; p < r; p++) {
									var u = g.terms[p];
									0 < u.length && (e += "<li>" + u + "</li>")
								}
								e += "</ol>"
							}
						}
						a = d + e + ('<br><div class="translate-powered">Powered by <a href="' + a + '" class="translate-link">Google Translate</a></div><br>')
					} else a = "";
					else if (a = b.dictResponse, !a || a.error) a = "";
					else {
						c = google.language.dictionary.createResultHtml(a);
						a = document.createElement("div");
						a.innerHTML = c;
						c = a.getElementsByTagName("a");
						for (d = c.length - 1; 0 <= d; d--) e = c[d], "Google Dictionary" == e.innerText && 0 == e.href.lastIndexOf("http://www.google.com/dictionary", 0) && (e.href = f);
						a = a.innerHTML
					}
					a = {
						eventKey: b.request.eventKey,
						sanitizedQuery: b.sanitizedQuery,
						html: a
					}
				} else {
					g = k;
					l && e ? (g = e, g.moreUrl = a, g.addUrl = aa, d && (d.audio && "en" == e.srcLang.toLowerCase()) && (g.audio = d.audio)) : c && (g = c, g.moreUrl = f);
					g && !g.prettyQuery && (g.prettyQuery = b.sanitizedQuery);
					a = m;
					if (("true" == t.popupDblclick && "none" == t.popupDblclickKey || "true" == t.popupSelect && "none" == t.popupSelectKey) && A(s, b.sanitizedQuery)) a = h;
					a = {
						eventKey: b.request.eventKey,
						sanitizedQuery: b.sanitizedQuery,
						meaningObj: g,
						showOptionsTip: a
					}
				}
				b.callback(a)
			}
		},
		I = function(a, c) {
			if (!a || a.sentences[0].orig.toLowerCase() == a.sentences[0].trans.toLowerCase()) return k;
			var b = a.sentences[0].orig.toLowerCase(),
				d = a.sentences[0].trans.toLowerCase(),
				e = d;
			if (c && a.dict && 0 < a.dict.length) for (var f = 0, l = a.dict.length; f < l; f++) for (var g = a.dict[f], p = 0, r = 0, u = g.terms.length; r < u && 2 > p; r++) {
				var v = g.terms[r].toLowerCase();
				0 < v.length && (v != b && v != d) && (e += ", " + v, p++)
			}(b = window["gdx.LANG_MAP"][a.src.toLowerCase()]) || (b = a.src);
			return {
				type: "translation",
				meaningText: e,
				attribution: "Translated from " + b,
				srcLang: a.src
			}
		},
		J = function(a, c) {
			for (var b = 0, d; d = a[b]; b++) if (d.type && d.type == c && d.text) return d.text;
			return ""
		},
		K = function(a) {
			if (!a || 0 == a.length) return k;
			for (var c = 0, b; b = a[c]; c++) for (var d = 0, e; e = b.entries[d]; d++) if ("meaning" == e.type && e.terms && 0 < e.terms.length) {
				var f = J(e.terms, "text");
				if (f) return a = J(b.terms, "sound").replace("http://", "https://"), {
					prettyQuery: J(b.terms, "text"),
					meaningText: f,
					audio: a,
					attribution: J(e.terms, "url")
				}
			}
			return k
		},
		H = function(a) {
			if (!a || a.error) return k;
			var c = K(a.primaries);
			c ? (c.attribution = "", c.type = "licensedDef") : (c = K(a.webDefinitions)) && (c.type = "webDef");
			return c
		},
		M = function() {
			var a = L,
				c = {};
			c.language = a.language || "en";
			var b = function(a, b) {
					return "true" == a || "false" == a ? a : a == h ? "true" : a == m ? "false" : b
				};
			c.popupDblclick = b(a.popupDblclick, "true");
			c.popupSelect = b(a.popupSelect, "false");
			c.enableHttps = b(a.enableHttps, "true");
			c.popupDblclickKey = a.popupDblclickKey || "none";
			c.popupSelectKey = a.popupSelectKey || "ctrl";
			a.popupMode && ("popup_disabled" == a.popupMode ? c.popupDblclick = "false" : "popup_key_ctrl" == a.popupMode && (c.popupDblclickKey = "ctrl", c.popupSelect = "true", c.popupSelectKey = "ctrl"));
			return c
		},
		N = N || m;
	if ("undefined" == typeof N || !N) {
		dict_api.load("https://clients5.google.com?client=dict-chrome-ex", "1", "en");
		var O = window.localStorage.options,
			L = {};
		O && (L = JSON.parse(O));
		t = M();
		window.localStorage.options = JSON.stringify(t);
		chrome.extension.onMessage.addListener(C);
		chrome.extension.onMessage.addListener(D);
		chrome.extension.onMessage.addListener(G);
		window["gdx.updateOptions"] = B
	};
})();