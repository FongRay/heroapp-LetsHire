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
            this._initSelectOpeningDialog();
            this._initInterviewSelectionDialog();
            this._initDatetimepicker();

            this.bindEvents();
        },
        /**
         * Initialize Select Opening dialog component
         *
         * @private
         */
        _initSelectOpeningDialog: function () {
            $('#department_id').attr('name', null);
            $('#openingid_select_wrapper').attr('id', 'interview_openingid_select_wrapper');
            $('#opening_id').attr('name', 'opening_id');

            $('#department_id').change(function (event) {
                tmpst.reloadOpening($(this), $('#interview_openingid_select_wrapper'), 'opening_id');
            });

            $('.flexible_schedule_interviews').on('click', $.proxy(this, '_onscheduleInterviewClick'));
        },
        /**
         * Initizlize interviews selection dialog component
         *
         * @private
         */
        _initInterviewSelectionDialog: function () {
            tmpst.prepareObjectSelectionContainer($('#interviewers_selection'), loadInterviewersStatus, function (checkbox) {
                var interviewersSelectionContainer = $("#interviewers_selection_container");
                var userIds = interviewersSelectionContainer.data('user_ids');
                var users = interviewersSelectionContainer.data('users');
                var currentVal = parseInt($(checkbox).val());
                var index = userIds.indexOf(currentVal);

                if (index >= 0) {
                    userIds.splice(index, 1);
                    users.splice(index, 1);
                } else {
                    userIds.push(currentVal);
                    users.push(checkbox.data('str'));
                }
            });
        },
        /**
         * Initialize datetimepicker component
         *
         * @private
         */
        _initDatetimepicker: function () {
            setupDatetimePicker($(".datetimepicker"));

            $(".iso-time").each(function (index, elem) {
                elem.innerHTML = new Date(elem.innerHTML).toLocaleString();
            });
        },
        /**
         * Click event handler for schedule interview
         *
         * @private
         * @event
         * @param  {Object} event Event object
         *
         * @return {boolean} stop event
         */
        _onscheduleInterviewClick: function (event) {
            var openingSelectionContainer = $("#opening_selection_container");
            var openingCandidateId = $('#opening_candidate_id').val();

            if (openingCandidateId) {
                window.location = '/interviews/edit_multiple?opening_candidate_id=' + openingCandidateId;
            } else {
                openingSelectionContainer.parent().dialog({
                    modal: true,
                    title: "Select Opening",
                    width: '450'
                });
            }
        },
        /**
         * Click event handler for adding interview
         *
         * @private
         * @event
         *
         * @return {boolean} stop event
         */
        _onAddInterviewClick: function () {
            var $table = $('.table-schedule-interviews');
            var $tbody = $table.find('tbody');

            if ($tbody.find('tr').length >= 30) {
                //TODO: just check new added lines, not including existing ones
                alert('Too many interviews scheduled.');

                return;
            }

            var openingId = $('#opening_id').val();
            var candidateId = $('#candidate_id').val();
            var url = tmpst.format('/interviews/schedule_add?opening_id=#{0}&candidate_id=#{1}', openingId, candidateId);

            $.get(url, function (data, status) {
                var newElem = $(data).appendTo($tbody);

                setupDatetimePicker(newElem.find("td .datetimepicker"));
            });

            return false;
        },
        /**
         * Change event handler for datetimepicker
         *
         * @private
         * @event
         * @param  {Object} event Event object
         */
        _onDatetimePickerChange: function (event) {
            var $target = $(event.target);
            var targetId = event.target.id;
            var isoVal = new Date($target.val()).toISOString();

            $target.data('iso', isoVal);

            var newId = targetId.replace("scheduled_at", "scheduled_at_iso");

            if (newId != targetId) {
                var isoItem = $("#" + newId);

                if (isoItem) {
                    isoItem.val(isoVal);
                }
            }
        },
        /**
         * Click evnet handler for edit interviewers button
         *
         * @private
         * @event
         * @param  {Object} event Event object
         *
         * @return {boolean} stop event
         */
        _onEditInterviewersClick: function (event) {
            var interviewerTd = $(event.target).closest('td');
            var interviewersSelectionContainer = $("#interviewers_selection_container");

            interviewersSelectionContainer.data('user_ids', interviewerTd.data('user_ids').slice(0));
            interviewersSelectionContainer.data('users', interviewerTd.data('users').slice(0));

            var new_val = $('#opening_id').data('department');

            $('#interviewers_selection').empty().append('Loading users...');
            $('#participants_department_id').val(new_val);

            tmpst.usersPage.reloadDepartmentUsers($('#interviewers_selection'), $('#participants_department_id').val(), loadInterviewersStatus);

            interviewersSelectionContainer.show().dialog({
                width: 400,
                height: 500,
                title: "Assign Interviewers",
                modal: true,
                buttons: {
                    "OK": function () {
                        interviewersSelectionContainer.hide().dialog("close");
                        calculateInterviewersChange(interviewerTd);
                    },
                    Cancel: function () {
                        $interviewersSelectionContainer.hide().dialog("close");
                    }
                }
            });

            return false;
        },
        /**
         * Click event handler for remove interviews button
         *
         * @private
         * @event
         * @param  {Object} event Event object
         *
         * @return {boolean} stop event
         */
        _onRemoveInterviewClick: function (event) {
            var $table = $('.table-schedule-interviews');
            var $tbody = $table.find('tbody');
            var $currentRow = $(event.target).closest('tr');

            if ($currentRow.data('interview_id')) {
                var delIds = tbody.data('del_ids');

                if (!delIds) {
                    delIds = [$currentRow.data('interview_id')];
                } else {
                    delIds.push($currentRow.data('interview_id'));
                }

                tbody.data('del_ids', delIds);
            }

            $currentRow.remove();

            return false;
        },
        /**
         * Click event handler for submitting interviews
         *
         * @private
         * @event
         *
         * @return {boolean} stop event
         */
        _onSubmitInterviewsClick: function () {
            var $table = $('.table-schedule-interviews');
            var $tbody = $table.find('tbody');

            $('#error_messages')
                .closest('div')
                .hide();

            if (!this._validationCheck($tbody)) {
                return false;
            }

            var interviews = GetAllInterviews($tbody);

            if (!interviews) {
                return false;
            }

            var me = this;

            $.post('/interviews/update_multiple', {
                interviews: {
                    opening_id: $('#opening_id').val(),
                    candidate_id: $('#candidate_id').val(),
                    interviews_attributes: interviews
                }
            }).done(function (response) {
                if (!response.success) {
                    me._displaySubmitErrors(response.messages);
                } else {
                    var url = $('#previous_url').data('value');
                    if (!url) {
                        url = "/interviews"
                    }
                    window.location = url;
                }
            }).fail(function (jqXHR, textStatus, errorThrown) {
                me._displaySubmitErrors(['Server error']);
            });

            return false;
        },
        /**
         * Click event handler for interview feedback button
         *
         * @private
         * @event
         * @param  {Object} event Event object
         *
         * @return {boolean} stop event
         */
        _onInterviewFeedbackClick: function (event) {
            var interviewId = $(this).attr('data-interview-id');
            var divId = "interview-feedback-dialog-" + interviewId;

            $("#" + divId).dialog({
                height: 400,
                width: 600,
                modal: true,
                title: 'Add Feedback',
                close: function (event, ui) {
                    $(this).dialog('destroy');
                }
            });

            return false;
        },
        /**
         * Bind events
         *
         * @public
         */
        bindEvents: function () {
            $('.add_new_interview').on('click', $.proxy(this, '_onAddInterviewClick'));
            $('.table-schedule-interviews').on('change', '.datetimepicker', $.proxy(this, '_onDatetimePickerChange'));

            $('#candidate_id').change(updateScheduleInterviewTable);
            updateScheduleInterviewTable();


            $('#participants_department_id').change(function () {
                tmpst.usersPage.reloadDepartmentUsers($('#interviewers_selection'), $('#participants_department_id').val(), loadInterviewersStatus);
            });

            $('.table-schedule-interviews').on('click', '.edit_interviewers', $.proxy(this, '_onEditInterviewersClick'));
            $('.table-schedule-interviews').on('click', '.button-remove', $.proxy(this, '_onRemoveInterviewClick'));
            $('.submit_interviews').on('click', $.proxy(this, '_onSubmitInterviewsClick'));

            $('#main').on('click', '.interview-feedback-btn', $.proxy(this, '_onInterviewFeedbackClick'));
        },
        /**
         * Validate submit of interviews
         *
         * @param  {Object} tbody The body of table we should to check
         *
         * @return {boolean} Whether it's valid
         */
        _validationCheck: function (tbody) {
            var errors = [];

            tbody.find('tr').each(function (index, row) {
                var interviewerTd = $(row).find('td:eq(4)');
                interviewerTd.find('div').removeClass('field_with_errors');
                if ($(row).find('.button-remove').length > 0) {
                    var userIds = interviewerTd.data('user_ids');

                    if (userIds == null || userIds.length == 0) {
                        interviewerTd.find('div').addClass('field_with_errors');
                        errors.push('No interviewers configured for row ' + (index + 1));
                    }
                }
            });

            this._displaySubmitErrors(errors);

            return (errors.length == 0);
        },
        /**
         * Display error messages of submitting interviews
         *
         * @private
         * @param  {Array} errors Array of error string messages
         *
         */
        _displaySubmitErrors: function (errors) {
            if (errors.length > 0) {
                var errorContent = '<ul>';

                for (var i = 0; i < errors.length; i++) {
                    errorContent += '<li>' + errors[i] + '</li>';
                }

                errorContent += '</ul>';

                $('#error_messages').html(errorContent);
                $('#error_messages').closest('div').show();
            } else {
                $('#error_messages').closest('div').hide();
            }

        }
    };

    function setupDatetimePicker(elements) {
        $(elements).datetimepicker().each(function (index, elem) {
            var isoTime = new Date($(elem).data('iso'));
            var newId = elem.id.replace("scheduled_at", "scheduled_at_iso");
            if (newId != elem.id) {
                var iso_elem = $("#" + newId);
                if (iso_elem) {
                    iso_elem.val($(elem).data('iso'));
                }
            }
            $(elem).datetimepicker("setDate", isoTime);
        });
    }

    // Read all rows and return an array of objects

    function GetAllInterviews(tbody) {
        var interviews = [];

        tbody.find('tr').each(function (index, value) {
            var row = GetRow(index, value);
            if (row) {
                interviews.push(row);
            }
        });

        if (interviews.length < $('table.schedule_interviews tbody tr').length) {
            return false;
        } else {
            var delIds = tbody.data('del_ids');

            if (delIds) {
                $.each(delIds, function (index, value) {
                    var interview = {};
                    interview.id = value;
                    interview._destroy = true;
                    interviews.push(interview);
                });
            }

            return interviews;
        }

    }

    // Read the row into an object

    function GetRow(rowNum, rowElem) {
        var row = $(rowElem);
        var interview = {};

        interview.id = row.data('interview_id');
        interview.status = row.find('#status').val();

        if (row.find('.button-remove').length > 0) {
            interview.scheduled_at_iso = row.find('td:eq(0) input').data('iso');
            interview.duration = row.find('td:eq(1) input').val();
            interview.modality = row.find('td:eq(2) select').val();
            if (interview.modality == 'onsite interview') {
                interview.location = row.find('td:eq(3) input').val();
            } else {
                interview.phone = row.find('td:eq(3) input').val();
            }

            var interviewerTd = row.find('td:eq(4)');
            var userIds = interviewerTd.data('user_ids');

            if (userIds == null || userIds.length == 0) {
                alert('No interviewers configured for row ' + (rowNum + 1));
                return false;
            }

            var originUserIds = interviewerTd.data('origin_user_ids');

            if (originUserIds) {
                //We have change
                interview.user_ids = userIds;
            }
        }

        return interview;
    }

    function updateScheduleInterviewTable() {
        var table = $('table.schedule_interviews');
        var openingId = $('#opening_id').val();
        var candidateId = $('#candidate_id').val();
        var active = openingId && candidateId;

        table.empty();
        $('.submit_interviews').hide();
        $('.add_new_interview').hide();
        $('#opening_candidate_status_label').hide();
        $('#opening_candidate_status_field').hide();

        if (active) {
            $('#participants_department_id').attr('name', null);
            var url = '/interviews/schedule_reload?opening_id=' + openingId + '&candidate_id=' + candidateId;

            table.load(url, function (data, status) {
                if (status == 'success') {
                    var status = table.find('tbody').data('status');

                    $('#opening_candidate_status_field').text(status);
 
                    if (status == undefined || status == 'Interview Loop') {
                        $('.add_new_interview').show();
                    }
 
                    $('#opening_candidate_status_label').show();
                    $('#opening_candidate_status_field').show();
                    $('.submit_interviews').show();
                    $(this).find('td .datetimepicker').each(function (index, elem) {
                        setupDatetimePicker(elem);
                    });
                    $(".iso-time").each(function (index, elem) {
                        elem.innerHTML = new Date(elem.innerHTML).toLocaleString();
                    });
                }
            });
        }
    }

    function loadInterviewersStatus() {
        var interviewersSelectionContainer = $("#interviewers_selection_container");
        var currentSelectedUserIds = interviewersSelectionContainer.data('user_ids');
        var participants = $('#opening_id').data('participants');

        if (!participants) {
            participants = [];
        }

        $(interviewersSelectionContainer).find('input:checkbox').each(function (index, elem) {
            if (currentSelectedUserIds.indexOf(parseInt($(elem).val())) >= 0) {
                $(elem).prop('checked', true);
            }

            if (participants.indexOf(parseInt($(elem).val())) >= 0) {
                var tr = $(elem).closest('tr');

                tr.addClass('starred');
                tr.next().addClass('starred'); // The same style for the hidden tr
            }
        });
    }

    /**
     * We assume a1 and a2 don't have duplicated elements.
     */

    function isArrayDuplicated(a1, a2) {
        if (a1.length != a2.length) {
            return false;
        }

        for (var i = 0; i < a1.length; i++) {
            if (a2.indexOf(a1[i]) == -1) {
                return false;
            }
        }

        for (var i = 0; i < a2.length; i++) {
            if (a1.indexOf(a2[i]) == -1) {
                return false;
            }
        }

        return true;
    }

    function calculateInterviewersChange(interviewerTd) {
        var interviewersSelectionContainer = $("#interviewers_selection_container");
        var newUserIds = interviewersSelectionContainer.data('user_ids');
        var oldUserIds = $(interviewerTd).data('user_ids');

        if (isArrayDuplicated(newUserIds, oldUserIds)) {
            //No change comparing to data before dialog open.
            return true;
        }

        if (newUserIds.length > 0) {
            $(interviewerTd).children(":first-child").removeClass('field_with_errors');
        }

        $(interviewerTd).data('users', interviewersSelectionContainer.data('users').slice(0));

        var interviewerNames = []

        for (var k in interviewersSelectionContainer.data('users')) {
            var interviewer = interviewersSelectionContainer.data('users')[k];

            if (interviewer.length > 30) {
                interviewer = interviewer.substring(0, 26) + '...';
            }
            interviewerNames.push(interviewer);
        }
        $(interviewerTd).find('#interviewers_literal').html('<p>' + interviewerNames.join(';<br/>') + '</p>');

        var originalUserIds = $(interviewerTd).data('origin_user_ids');

        if (!originalUserIds) {
            // Definitely a change comparing to content loading
            $(interviewerTd).data('origin_user_ids', oldUserIds.slice(0));
        } else {
            // Check whether we rollback to the original version
            if (isArrayDuplicated(newUserIds, originalUserIds)) {
                $(interviewerTd).removeData('origin_user_ids');
            }
        }
        $(interviewerTd).data('user_ids', newUserIds.slice(0));

        return true;
    }

    tmpst.interviewsPage = tmpst.Class(page);
}(jQuery, tmpst));