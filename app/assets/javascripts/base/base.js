/**
 * @fileOverview Base functionalities for LetsHire
 * @author khalil zhang(khalilz@vmware.com)
 */

(function ($, window) {
    'use strict';

    var htmlDecodeDict = {
        "quot": '"',
        "lt": "<",
        "gt": ">",
        "amp": "&",
        "nbsp": " "
    };

    var htmlEncodeDict = {
        '"': "quot",
        "'": "#39",
        "<": "lt",
        ">": "gt",
        "&": "amp",
        " ": "nbsp"
    };

    window.tmpst = {
        /**
         * Encode html
         *
         * @public
         * @param {String} html
         */
        encodeHTML: function (html) {
            return String(html).replace(/["<>& ]/g, function (all) {
                return "&" + htmlEncodeDict[all] + ";";
            });
        },
        /**
         * Encode html attriute
         *
         * @public
         * @param {String} html attribute
         */
        encodeAttr: function (html) {
            return String(html).replace(/["']/g, function (all) {
                return "&" + htmlEncodeDict[all] + ";";
            });
        },
        /**
         * Format string
         *
         * @public
         * @param  {string} source
         * @param  {Object} opts
         *
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

                    //html encode
                    if (type == "#") {
                        replacer = tmpst.encodeHTML(replacer);
                    } else if (type === '@') {
                        replacer = tmpst.encodeAttr(replacer);
                    }


                    return ('undefined' == typeof replacer ? '' : replacer);
                });
            }
            return source;
        },
        /**
         * Generat namespace
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
        /**
         * Determine if the argument passed is a Javascript function object
         *
         * @public
         * @see $.isFunction
         *
         * @param  {*} Object to test whether or not it is a function
         *
         * @return {boolean} Test result
         */
        isFunction: function (obj) {
            return $.isFunction(obj);
        },
        prepareObjectSelectionContainer: function (object, paginate_callback, change_event_callback) {
            var parent_object = object.parent();

            parent_object.delegate('.pagination a', 'click', function () {
                $('.pagination').html('Page is loading...');
                object.load(this.href, function () {
                    if (paginate_callback) {
                        paginate_callback($(this));
                    }
                });

                return false;
            });

            parent_object.delegate('i.icon-arrow-down', 'click', function () {
                $(this).parent().parent().next().show();
                $(this).removeClass('icon-arrow-down').addClass('icon-arrow-up');

                return false;
            });

            parent_object.delegate('i.icon-arrow-up', 'click', function () {
                $(this).parent().parent().next().hide();
                $(this).removeClass('icon-arrow-up').addClass('icon-arrow-down');

                return false;
            });

            parent_object.delegate('input:checkbox', 'change', function () {
                if (change_event_callback) {
                    change_event_callback($(this));
                }
            });
        },
        reloadOpening: function (department_control, opening_control, opening_control_name) {
            $(department_control).attr('disabled', true);
            var url = '/openings/opening_options?selected_department_id=' + $(department_control).val();

            return $(opening_control).load(url, function () {
                $(department_control).attr('disabled', false);
                $(opening_control).find('select#opening_id').attr('name', opening_control_name);
            });
        },
        updateQueryStringParameter: function (uri, key, value) {
            var re = new RegExp("([?|&])" + key + "=.*?(&|$)", "i");

            separator = uri.indexOf('?') !== -1 ? "&" : "?";
            if (uri.match(re)) {
                return uri.replace(re, '$1' + key + "=" + value + '$2');
            } else {
                return uri + separator + key + "=" + value;
            }
        }
    };
}(jQuery, window));