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
            this._initAccordion();
            this._initFileUpload();
            this._initPhotoPreviewTooltip();
            this._initDatetime();

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
        },
        /**
         * Initialize accordion component
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
         * Initialize file upload component
         *
         * @private
         */
        _initFileUpload: function () {
            $('.fileupload').fileupload({
                name: "candidate[resume]"
            });
        },
        /**
         * Initialize the tooltip of photo preivew
         *
         * @private
         */
        _initPhotoPreviewTooltip: function () {
            $(document).on('mouseover', '.photo-preview-tooltip', function () {
                $(this).tooltip({
                    items: '[class~="photo-preview-tooltip"]',
                    tooltipClass: 'photo-preview-dialog',
                    content: function () {
                        var photoId = $(this).data('photo-id');

                        return tmpst.format('<img src="/api/v1/photo/download?photo_id=#{0}" />', photoId);
                    }
                }).tooltip('open');
            });
        },
        /**
         * Initialize the format of date time
         *
         * @private
         */
        _initDatetime: function () {
            $(".iso-time").each(function (index, elem) {
                elem.innerHTML = new Date(elem.innerHTML).toLocaleString();
            });
        },
        /**
         * Bind events
         *
         * @public
         */
        bindEvents: function () {
            var me = this;

            // open dialog for "Assign Job Opening"
            $('.candidates_index_new_opening').on('click', function (event) {
                me._assignJobOpening($(this).closest('tr').data('id'));

                return false;
            });
            $('.candidate_new_opening').on('click', function (event) {
                me._assignJobOpening($('#candidate_id').val());

                return false;
            });

            $('.table-candicates').on('click', '.candidate-blacklist-link', $.proxy(this, '_onCandidateBlacklistBtnClick'));
            $('#candidate-assessment-btn').on('click', $.proxy(this, '_onCandidateAssessmentBtnClick'));
            $('#candidate_resume').change($.proxy(this, '_onCandiateResumeSelectChange'));
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
        _onCandidateBlacklistBtnClick: function (event) {
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
        },
        /**
         * Click event handler for assess candidate
         *
         * @private
         * @event
         */
        _onCandidateAssessmentBtnClick: function () {
            $('#candidate-assessment-dialog').dialog({
                modal: true,
                width: '700',
                height: '620',
                title: 'Assess Candidate'
            });
        },
        /**
         * Change event handler for resume select
         *
         * @private
         * @event
         * @param  {Object} event Event object
         *
         */
        _onCandiateResumeSelectChange: function (event) {
            var maxsize = 10 * 1024 * 1024;
            var target = event.target;

            if ($.browser.msie) {
                // microsoft ie
                //
                // It's not easy to achieve this functionality in IE, most likly,
                // IE configuration does forbidden ActiveXObject. Anyway, we have
                // done the server side file size limit mechanism.
            } else {
                // firefox, chrome
                if (target.files[0].size > maxsize) {
                    alert('File size cannot be larger than 10M.');
                    $(target).attr('value', '');
                }
            }
        },
        /**
         * Assign job opening
         *
         * @private
         * @param  {string | number} id Candidate id
         *
         */
        _assignJobOpening: function (id) {
            var openingSelectionContainer = $("#opening_selection_container");

            openingSelectionContainer.parent().get(0).setAttribute('action', '/candidates/' + id + '/create_opening');
            openingSelectionContainer.parent().dialog({
                modal: true,
                title: "Select Opening",
                width: '450'
            });
        }
    };

    tmpst.candidatesPage = tmpst.Class(page);
}(jQuery, tmpst));