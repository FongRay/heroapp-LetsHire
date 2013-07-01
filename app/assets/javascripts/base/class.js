(function ($, tmpst) {
    'use strict';

    /**
     * Constructor: tmpst.Class
     * Base class used to construct all other classes. Includes support for
     *     multiple inheritance.
     *
     * To create a new class, use the following syntax:
     * (code)
     *     var MyClass = tmpst.Class(prototype);
     * (end)
     *
     * To create a new class with multiple inheritance, use the
     *     following syntax:
     * (code)
     *     var MyClass = tmpst.Class(Class1, Class2, prototype);
     * (end)
     *
     * Note that instanceof reflection will only reveal Class1 as superclass.
     *
     */
    tmpst.Class = function () {
        var len = arguments.length;
        //superclass
        var P = arguments[0];
        //prototype
        var F = arguments[len - 1];

        //constructor
        var C = typeof F.initialize == "function" ? F.initialize : function () {
                P.prototype.initialize.apply(this, arguments);
            };

        if (len > 1) { //inheritance
            var newArgs = [C, P].concat(
                Array.prototype.slice.call(arguments).slice(1, len - 1), F);
            tmpst.inherit.apply(null, newArgs);
        } else {
            C.prototype = F;
        }

        //extend
        C.extend = function (components) {
            if (!'[object Array]' == Object.prototype.toString.call(components)) {
                components = Array.prototype.concat.call(components);
            }
            var i = components.length;
            while (i--) {
                components[i].call(C.prototype);
            }
            return C;
        };

        return C;
    };

     /**
      * Function: tmpst.inherit
      * 
      * In addition to the mandatory C and P parameters, an arbitrary number of
      * objects can be passed, which will extend C.
      *
      * @param  {Object} the class that inherits
      * @param  {Object} the superclass to inherit from
      *
      */
    tmpst.inherit = function (C, P) {
        var F = function () {};
        F.prototype = P.prototype;
        C.prototype = new F;
        var i, l, o;
        for (i = 2, l = arguments.length; i < l; i++) {
            o = arguments[i];
            if (typeof o === "function") {
                o = o.prototype;
            }
            tmpst.util.extend(C.prototype, o);
        }
    };

}(jQuery, tmpst));