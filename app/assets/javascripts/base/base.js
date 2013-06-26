(function ($, window) {
    window.tmpst = {
        /**
         * Format string
         * @param  {string} source
         * @param  {Object} opts
         * @return {string} formated string
         */
        format: function (source, opts) {
            source = String(source);
            var data = Array.prototype.slice.call(arguments, 1),
                toString = Object.prototype.toString;
            if (data.length) {
                data = data.length == 1 ? /* ie 下 Object.prototype.toString.call(null) == '[object Object]' */
                    (opts !== null && (/\[object Array\]|\[object Object\]/.test(toString.call(opts))) ? opts : data) : data;
                return source.replace(/>\s*</g, '><').replace(/(#|!|@)\{(.+?)(?:\s*[,:]\s*(\d+?))*?\}/g, function (match, type, key, length) {
                    var replacer = data[key];
                    // chrome 下 typeof /a/ == 'function'
                    if ('[object Function]' == toString.call(replacer)) {
                        replacer = replacer(key);
                    }
                    if (length) {
                        replacer = h.truncate(replacer, length);
                    }
                    /*
                //html encode
                if (type == "#") {
                    replacer = h.escape(replacer);
                } else if (type === '@') {
                    replacer = h.encodeAttr(replacer);
                }*/

                    return ('undefined' == typeof replacer ? '' : replacer);
                });
            }
            return source;
        },
        /**
         * Generate namespace
         *
         * @public
         * @param {string} ns_string namespace string that is joined with dot
         *
         * @return {Object} the top-end object of the namespace
         */
        namespace: function (ns_string) {
            if (!ns_string || !ns_string.length) {
                return null;
            }

            var _package = window;

            for (var a = ns_string.split('.'), l = a.length, i = (a[0] == 'window') ? 1 : 0; i < l; _package = _package[a[i]] = _package[a[i]] || {}, i++);

            return _package;
        },
        /**
         * Truncate string
         *
         * @public
         * @param {string} str the source string text
         * @param {number} length determine how many characters to truncate to
         * @param {string} truncateStr this is a text string that replaces the truncated text, tts length is not included in the truncation length setting
         * @param {[type]} middle this determines whether the truncation happens at the end of the string with false, or in the middle of the string with true
         *
         * @return {string} string text that is truncated to
         */
        truncate: function (str, length, truncateStr, middle) {
            if (str == null) return '';
            str = String(str);

            if (typeof middle !== 'undefined') {
                middle = truncateStr;
                truncateStr = '...';
            } else {
                truncateStr = truncateStr || '...';
            }

            length = ~~length;
            if (!middle) {
                return str.length > length ? str.slice(0, length) + truncateStr : str;
            } else {
                return str.length > length ? str.slice(0, length / 2) + truncateStr + str.slice(-length / 2) : str;
            }
        },
        isFunction: function (obj) {
            return $.isFunction(obj);
        },
        extend: $.extend,
        noop: $.noop
    };
}(jQuery, window));