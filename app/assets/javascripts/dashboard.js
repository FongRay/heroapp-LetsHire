(function ($, tmpst) {
    'use strict';

    var page = {
        /**
         * Initialize page
         *
         * @constructs
         * @public
         */
        initialize: function () {
            this.initCarousel();
        },
        /**
         * Initialize the carousel component
         *
         * @public
         */
        initCarousel: function () {
            $('.carousel').jcarousel();
            $('.jcarousel-control').jcarouselControl();

            // 1. if the total size of items is less than 4, the prev and next controls should be hided;
            // 2. if the total size is more than 4, the prev control should also not be displayed
            if ($('.carousel').jcarousel('items').length <= 4) {
                $('.carousel-control-next').hide();
                $('.carousel-control-prev').hide();
            } else {
                $('.carousel-control-prev').hide();
            }

            $('.carousel-control-prev').on('click', $.proxy(this, '_onPrevCarouselClick'));
            $('.carousel-control-next').on('click', $.proxy(this, '_onNextCarouselClick'));
        },
        /**
         * Click event handler for previous carousel button
         *
         * @private
         * @event
         */
        _onPrevCarouselClick: function () {
            var items = $('.carousel').jcarousel('items');
            var current_target = $('.carousel').jcarousel('target')[0];

            if (items.length > 4) {
                if (current_target === items[0]) {
                    $('.carousel-control-prev').hide();
                }

                $('.carousel-control-next').show();
            }
        },
        /**
         * Click event handler for next carousel button
         *
         * @private
         * @event
         */
        _onNextCarouselClick: function () {
            var items = $('.carousel').jcarousel('items');
            var current_target = $('.carousel').jcarousel('target')[0];

            if (items.length > 4) {
                if (current_target == items[items.length - 4]) {
                    $('.carousel-control-next').hide();
                }

                $('.carousel-control-prev').show();
            }
        }
    };

    tmpst.dashboardPage = tmpst.Class(page);
}(jQuery, tmpst));