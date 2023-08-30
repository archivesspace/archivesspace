// Scrollend event polyfill for safari, ios, and opera
// via https://github.com/argyleink/scrollyfills/blob/1ca96b0669743fcfbeebc4a8175724fe237a4b09/dist/scrollyfills.umd.js
// This UMD version was built from source

!(function (e, t) {
  'object' == typeof exports && 'undefined' != typeof module
    ? t(exports)
    : 'function' == typeof define && define.amd
    ? define(['exports'], t)
    : t(((e || self).scrollyfills = {}));
})(this, function (e) {
  function t(e, t) {
    (null == t || t > e.length) && (t = e.length);
    for (var n = 0, r = new Array(t); n < t; n++) r[n] = e[n];
    return r;
  }
  function n(e, n) {
    var r =
      ('undefined' != typeof Symbol && e[Symbol.iterator]) || e['@@iterator'];
    if (r) return (r = r.call(e)).next.bind(r);
    if (
      Array.isArray(e) ||
      (r = (function (e, n) {
        if (e) {
          if ('string' == typeof e) return t(e, n);
          var r = Object.prototype.toString.call(e).slice(8, -1);
          return (
            'Object' === r && e.constructor && (r = e.constructor.name),
            'Map' === r || 'Set' === r
              ? Array.from(e)
              : 'Arguments' === r ||
                /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(r)
              ? t(e, n)
              : void 0
          );
        }
      })(e)) ||
      (n && e && 'number' == typeof e.length)
    ) {
      r && (e = r);
      var o = 0;
      return function () {
        return o >= e.length ? { done: !0 } : { done: !1, value: e[o++] };
      };
    }
    throw new TypeError(
      'Invalid attempt to iterate non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method.'
    );
  }
  if (!('onscrollend' in window)) {
    var r = function (e, t, n) {
        var r = e[t];
        e[t] = function () {
          var e = Array.prototype.slice.apply(arguments, [0]);
          r.apply(this, e), e.unshift(r), n.apply(this, e);
        };
      },
      o = function (e, t, n, r) {
        if ('scroll' == t || 'scrollend' == t) {
          var o = this,
            i = a.get(o);
          if (void 0 === i) {
            var d = 0;
            (i = {
              scrollListener: function (e) {
                clearTimeout(d),
                  (d = setTimeout(function () {
                    s.size
                      ? setTimeout(i.scrollListener, 100)
                      : (o.dispatchEvent(l), (d = 0));
                  }, 100));
              },
              listeners: 0,
            }),
              e.apply(o, ['scroll', i.scrollListener]),
              a.set(o, i);
          }
          i.listeners++;
        }
      },
      i = function (e, t, n) {
        if ('scroll' == t || 'scrollend' == t) {
          var r = this,
            o = a.get(r);
          void 0 !== o &&
            (o[t]--,
            --o.listeners > 0 ||
              (e.apply(r, ['scroll', o.scrollListener]), a.delete(r)));
        }
      },
      l = new Event('scrollend'),
      s = new Set();
    document.addEventListener(
      'touchstart',
      function (e) {
        for (var t, r = n(e.changedTouches); !(t = r()).done; )
          s.add(t.value.identifier);
      },
      { passive: !0 }
    ),
      document.addEventListener(
        'touchend',
        function (e) {
          for (var t, r = n(e.changedTouches); !(t = r()).done; )
            s.delete(t.value.identifier);
        },
        { passive: !0 }
      );
    var a = new WeakMap();
    r(Element.prototype, 'addEventListener', o),
      r(window, 'addEventListener', o),
      r(document, 'addEventListener', o),
      r(Element.prototype, 'removeEventListener', i),
      r(window, 'removeEventListener', i),
      r(document, 'removeEventListener', i);
  }
  e.scrollend = { __proto__: null };
});
