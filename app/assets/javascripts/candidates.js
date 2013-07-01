(function ($, tmpst) {
    'use strict';

    function create_opening(id) {
        var opening_selection_container = $("#opening_selection_container");

        opening_selection_container.parent().get(0).setAttribute('action', '/candidates/' + id + '/create_opening');
        opening_selection_container.parent().dialog({
            modal: true,
            title: "Select Opening",
            width: '450'
        });
    }

    var page = {
        /**
         * Initialize page
         *
         * @constructs
         * @public
         */
        initialize: function () {
            this._initAccordion();
            this._initFileUpload();

            if ($('.candidates_index_new_opening').length > 0 ||
                $('.candidate_new_opening').length > 0 ||
                $('#new_candidate').length > 0) {
                $('#department_id').attr('name', null);
                $('#openingid_select_wrapper').attr('id', 'candidate_openingid_select_wrapper');
                $('select#opening_id').attr('name', 'candidate[opening_id]');

                $('#department_id').change(function () {
                    tmpst.reloadOpening($(this), $('#candidate_openingid_select_wrapper'), 'candidate[opening_id]');
                });
            }

            this.bindEvents();

            if ($('.dropdown-toggle').length > 0) {
                $('.dropdown-toggle').dropdown();
            }

            $('#candidate_resume').change(function (event) {
                var maxsize = 10 * 1024 * 1024;

                if ($.browser.msie) {
                    // microsoft ie
                    //
                    // It's not easy to achieve this functionality in IE, most likly,
                    // IE configuration does forbidden ActiveXObject. Anyway, we have
                    // done the server side file size limit mechanism.
                } else {
                    // firefox, chrome
                    if (this.files[0].size > maxsize) {
                        alert('File size cannot be larger than 10M.');
                        $(this).attr('value', '');
                    }
                }
            });

            $("ul.interviewline").each(function (index, elem) {
                elem.childNodes[0].innerHTML = new Date(elem.childNodes[0].innerHTML).toLocaleString();
            });
        },
        /**
         * Initializing accordion component
         *
         * @private
         */
        _initAccordion: function () {
            $(".accordion").accordion({
                collapsible: true,
                heightStyle: 'content'
            });
        },
        /**
         * Initialzing file upload component
         *
         * @private
         */
        _initFileUpload: function () {
            $('.fileupload').fileupload({
                name: "candidate[resume]"
            });
        },
        /**
         * Bind events
         *
         * @public
         */
        bindEvents: function () {
            // open dialog for "Assign Job Opening"
            $('.candidates_index_new_opening').click(function (event) {
                create_opening($(this).closest('tr').data('id'));

                return false;
            });

            $('.candidate_new_opening').click(function (event) {
                create_opening($('#candidate_id').val());

                return false;
            });

            // to handle "blacklist-link" click event
            $('.table-candicates').on('click', '.candidate-blacklist-link', $.proxy(this, '_onCandidateBlacklistClick'));

            // assess candidates
            $('#candidate-assessment-btn').click(function () {
                $('div#candidate-assessment-dialog').dialog({
                    modal: true,
                    width: '700',
                    height: '620',
                    title: 'Assess Candidate'
                });
            });
        },
        /**
         * Click event handler for 'Move to Blacklist' button
         *
         * @private
         * @event
         * @param  {Object} event Event object
         *
         * @return {boolean} stop event
         */
        _onCandidateBlacklistClick: function (event) {
            var candidate_id = $(event.target).attr('data-candidate-id');
            var div_id = "candidate-blacklist-dialog-" + candidate_id;

            $("#" + div_id).dialog({
                height: 350,
                width: 450,
                modal: true,
                title: 'Deactive candidate',
                close: function (event, ui) {
                    $(this).dialog('destroy');
                }
            });

            return false;
        }
    };

    tmpst.candidatesPage = tmpst.Class(page);
}(jQuery, tmpst));