(function ($, tmpst) {
    'use strict';

    function setupDatetimePicker(elements) {
        $(elements).datetimepicker().each(function (index, elem) {
            var isoTime = new Date($(elem).data('iso'));
            var new_id = elem.id.replace("scheduled_at", "scheduled_at_iso");
            if (new_id != elem.id) {
                var iso_elem = $("#" + new_id);
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
            var del_ids = tbody.data('del_ids');
            if (del_ids) {
                $.each(del_ids, function (index, value) {
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
            var interviewer_td = row.find('td:eq(4)');
            var user_ids = interviewer_td.data('user_ids');
            if (user_ids == null || user_ids.length == 0) {
                alert('No interviewers configured for row ' + (rowNum + 1));
                return false;
            }
            var origin_user_ids = interviewer_td.data('origin_user_ids');
            if (origin_user_ids) {
                //We have change
                interview.user_ids = user_ids;
            }
        }

        return interview;
    }

    function update_schedule_interviews_table() {
        var table = $('table.schedule_interviews');
        var opening_id = $('#opening_id').val();
        var candidate_id = $('#candidate_id').val();
        var active = opening_id && candidate_id;
        table.empty();
        $('.submit_interviews').hide();
        $('.add_new_interview').hide();
        $('#opening_candidate_status_label').hide();
        $('#opening_candidate_status_field').hide();
        if (active) {
            $('#participants_department_id').attr('name', null);
            var url = '/interviews/schedule_reload?opening_id=' + opening_id + '&candidate_id=' + candidate_id;
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
        var interviewers_selection_container = $("#interviewers_selection_container");
        var current_selected_user_ids = interviewers_selection_container.data('user_ids');
        var participants = $('#opening_id').data('participants');
        if (!participants) {
            participants = [];
        }
        $(interviewers_selection_container).find('input:checkbox').each(function (index, elem) {
            if (current_selected_user_ids.indexOf(parseInt($(elem).val())) >= 0) {
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
    function uniq_array_equal(a1, a2) {
        if (a1.length != a2.length) {
            return false;
        }
        for (var a1_i = 0; a1_i < a1.length; a1_i++) {
            if (a2.indexOf(a1[a1_i]) == -1) {
                return false;
            }
        }
        for (var a2_i = 0; a2_i < a2.length; a2_i++) {
            if (a1.indexOf(a2[a2_i]) == -1) {
                return false;
            }
        }

        return true;
    }


    function calculateInterviewersChange(interviewer_td) {
        var interviewers_selection_container = $("#interviewers_selection_container");
        var new_user_ids = interviewers_selection_container.data('user_ids');
        var old_user_ids = $(interviewer_td).data('user_ids');

        if (uniq_array_equal(new_user_ids, old_user_ids)) {
            //No change comparing to data before dialog open.
            return true;
        }

        if (new_user_ids.length > 0) {
            $(interviewer_td).children(":first-child").removeClass('field_with_errors');
        }

        $(interviewer_td).data('users', interviewers_selection_container.data('users').slice(0));

        var interviewer_names = []

        for (var k in interviewers_selection_container.data('users')) {
            var interviewer = interviewers_selection_container.data('users')[k];

            if (interviewer.length > 30) {
                interviewer = interviewer.substring(0, 26) + '...';
            }
            interviewer_names.push(interviewer);
        }
        $(interviewer_td).find('#interviewers_literal').html('<p>' + interviewer_names.join(';<br/>') + '</p>');

        var original_user_ids = $(interviewer_td).data('origin_user_ids');

        if (!original_user_ids) {
            // Definitely a change comparing to content loading
            $(interviewer_td).data('origin_user_ids', old_user_ids.slice(0));
        } else {
            // Check whether we rollback to the original version
            if (uniq_array_equal(new_user_ids, original_user_ids)) {
                $(interviewer_td).removeData('origin_user_ids');
            }
        }
        $(interviewer_td).data('user_ids', new_user_ids.slice(0));

        return true;
    }

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
        _initSelectOpeningDialog: function () {
            $('#department_id').attr('name', null);
            $('#openingid_select_wrapper').attr('id', 'interview_openingid_select_wrapper');
            $('#opening_id').attr('name', 'opening_id');

            $('#department_id').change(function (event) {
                tmpst.reloadOpening($(this), $('#interview_openingid_select_wrapper'), 'opening_id');
            });

            $('.flexible_schedule_interviews').on('click', $.proxy(this, '_onscheduleInterviewClick'));
        },
        _initInterviewSelectionDialog: function () {
            tmpst.prepareObjectSelectionContainer($('#interviewers_selection'), loadInterviewersStatus, function (checkbox) {
                var interviewers_selection_container = $("#interviewers_selection_container");
                var user_ids = interviewers_selection_container.data('user_ids');
                var users = interviewers_selection_container.data('users');
                var current_val = parseInt($(checkbox).val());
                var index = user_ids.indexOf(current_val);

                if (index >= 0) {
                    user_ids.splice(index, 1);
                    users.splice(index, 1);
                } else {
                    user_ids.push(current_val);
                    users.push(checkbox.data('str'));
                }
            });
        },
        _initDatetimepicker: function () {
            setupDatetimePicker($(".datetimepicker"));

            $(".iso-time").each(function (index, elem) {
                elem.innerHTML = new Date(elem.innerHTML).toLocaleString();
            });
        },
        _onscheduleInterviewClick: function (event) {
            var opening_selection_container = $("#opening_selection_container");
            var opening_candidate_id = $('#opening_candidate_id').val();

            if (opening_candidate_id) {
                window.location = '/interviews/edit_multiple?opening_candidate_id=' + opening_candidate_id;
            } else {
                opening_selection_container.parent().dialog({
                    modal: true,
                    title: "Select Opening",
                    width: '450'
                });
            }
        },
        _onAddInterviewClick: function () {
            var $table = $('.table-schedule-interviews');
            var $tbody = $table.find('tbody');

            if ($tbody.find('tr').length >= 30) {
                //TODO: just check new added lines, not including existing ones
                alert('Too many interviews scheduled.');

                return;
            }

            var opening_id = $('#opening_id').val();
            var candidate_id = $('#candidate_id').val();
            var url = tmpst.format('/interviews/schedule_add?opening_id=#{0}&candidate_id=#{1}', opening_id, candidate_id);

            $.get(url, function (data, status) {
                var newElem = $(data).appendTo($tbody);

                setupDatetimePicker(newElem.find("td .datetimepicker"));
            });

            return false;
        },
        _onDatetimePickerChange: function (event) {
            var $target = $(event.target);
            var targetId = event.target.id;
            var isoVal = new Date($target.val()).toISOString();

            $target.data('iso', isoVal);

            var new_id = targetId.replace("scheduled_at", "scheduled_at_iso");

            if (new_id != targetId) {
                var iso_elem = $("#" + new_id);

                if (iso_elem) {
                    iso_elem.val(isoVal);
                }
            }
        },
        _onEditInterviewClick: function (event) {
            var interviewer_td = $(event.target).closest('td');
            var interviewers_selection_container = $("#interviewers_selection_container");

            interviewers_selection_container.data('user_ids', interviewer_td.data('user_ids').slice(0));
            interviewers_selection_container.data('users', interviewer_td.data('users').slice(0));

            var new_val = $('#opening_id').data('department');

            $('#interviewers_selection').empty().append('Loading users...');
            $('#participants_department_id').val(new_val);

            tmpst.usersPage.reloadDepartmentUsers($('#interviewers_selection'), $('#participants_department_id').val(), loadInterviewersStatus);

            interviewers_selection_container.show().dialog({
                width: 400,
                height: 500,
                title: "Assign Interviewers",
                modal: true,
                buttons: {
                    "OK": function () {
                        interviewers_selection_container.hide().dialog("close");
                        calculateInterviewersChange(interviewer_td);
                    },
                    Cancel: function () {
                        $interviewers_selection_container.hide().dialog("close");
                    }
                }
            });
        },
        _onRemoveInterviewClick: function (event) {
            var $table = $('.table-schedule-interviews');
            var $tbody = $table.find('tbody');
            var $currentRow = $(event.target).closest('tr');

            if ($currentRow.data('interview_id')) {
                var del_ids = tbody.data('del_ids');

                if (!del_ids) {
                    del_ids = [$currentRow.data('interview_id')];
                } else {
                    del_ids.push($currentRow.data('interview_id'));
                }

                tbody.data('del_ids', del_ids);
            }

            $currentRow.remove();

            return false;
        },
        _onSubmitInterviews: function () {
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
        _onInterviewFeedbackClick: function (event) {
            var interview_id = $(this).attr('data-interview-id');
            var div_id = "interview-feedback-dialog-" + interview_id;

            $("#" + div_id).dialog({
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
        bindEvents: function () {
            $('.add_new_interview').on('click', $.proxy(this, '_onAddInterviewClick'));
            $('.table-schedule-interviews').on('change', '.datetimepicker', $.proxy(this, '_onDatetimePickerChange'));

            $('#candidate_id').change(update_schedule_interviews_table);
            update_schedule_interviews_table();


            $('#participants_department_id').change(function () {
                tmpst.usersPage.reloadDepartmentUsers($('#interviewers_selection'), $('#participants_department_id').val(), loadInterviewersStatus);
            });

            $('.table-schedule-interviews').on('click', '.edit_interviewers', $.proxy(this, '_onEditInterviewClick'));
            $('.table-schedule-interviews').on('click', '.button-remove', $.proxy(this, '_onRemoveInterviewClick'));
            $('.submit_interviews').on('click', $.proxy(this, '_onSubmitInterviews'));

            $('#main').on('click', '.interview-feedback-btn', $.proxy(this, '_onInterviewFeedbackClick'));
        },
        _validationCheck: function (tbody) {
            var errors = [];

            tbody.find('tr').each(function (index, row) {
                var interviewer_td = $(row).find('td:eq(4)');
                interviewer_td.find('div').removeClass('field_with_errors');
                if ($(row).find('.button-remove').length > 0) {
                    var user_ids = interviewer_td.data('user_ids');

                    if (user_ids == null || user_ids.length == 0) {
                        interviewer_td.find('div').addClass('field_with_errors');
                        errors.push('No interviewers configured for row ' + (index + 1));
                    }
                }
            });

            this._displaySubmitErrors(errors);

            return (errors.length == 0);
        },
        _displaySubmitErrors: function (errors) {
            if (errors.length > 0) {
                var error_content = '<ul>';

                for (var i = 0; i < errors.length; i++) {
                    error_content += '<li>' + errors[i] + '</li>';
                }

                error_content += '</ul>';

                $('#error_messages').html(error_content);
                $('#error_messages').closest('div').show();
            } else {
                $('#error_messages').closest('div').hide();
            }

        }
    };

    tmpst.interviewsPage = tmpst.Class(page);
}(jQuery, tmpst));