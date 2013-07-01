(function ($, tmpst) {
    'use strict';

    function reloadRoleFunc(department_id, role) {
        if (department_id.length <= 0) {
            department_id = '0';
        }

        var role_id = $('#opening_' + role + '_id');

        $('select', role_id).attr('disabled', true);

        var old_value = role_id.val();
        var url = "/departments/" + department_id + "/user_select?role=" + role;

        return role_id.load(url, function () {
            var role_id = $('#opening_' + role + '_id');

            role_id.attr('id', 'opening_' + role + '_id')
                .attr('name', 'opening[' + role + '_id]');
            role_id.val(old_value);
        });
    };

    var page = {
        /**
         * Initialize page
         *
         * @constructs
         * @public
         */
        initialize: function () {
            this.initCountrySelect();
            this.initRecruiterSelect();
            this.initDepartmentSelect();
            this.bindEvents();
        },
        /**
         * Initialize country select component
         *
         * @public
         */
        initCountrySelect: function () {
            $("#opening_country").change(function (event) {
                var country_code = $(this).val();
                var state_select_wrapper = $("#opening_state_wrapper");
                var url = '/addresses/subregion_options?country_code=' + country_code;

                $("select", state_select_wrapper).attr("disabled", true);

                return state_select_wrapper.load(url);
            });
        },
        /**
         * Initialize recruiter select component
         *
         * @public
         */
        initRecruiterSelect: function () {
            $('#opening_recruiter_id').change(function (event) {
                var current_user_id = $('#opening_recruiting_warn').attr('data-recruiter-id');

                if (current_user_id != $(this).val()) {
                    $('#opening_recruiting_warn').show();
                } else {
                    $('#opening_recruiting_warn').hide();
                }
            });
        },
        /**
         * Initialize department select component
         *
         * @public
         */
        initDepartmentSelect: function () {
            $('#opening_department_id').change(function (event) {
                var department_id = $(this).val();

                return reloadRoleFunc(department_id, 'hiring_manager');
            });

            if ($('#opening_department_id').length > 0) {
                reloadRoleFunc($('#opening_department_id').val(), 'hiring_manager');
            }
        },
        /**
         * Bind events
         *
         * @public
         */
        bindEvents: function () {
            $('.table-openings').on('click', '.assign_candidates', $.proxy(this, '_onAssignCandidatesClick'));
            tmpst.prepareObjectSelectionContainer($('#candidates_selection'), null, function (checkbox) {
                var candidates_selection_container = $('#candidates_selection_container');
                var ids = candidates_selection_container.data('ids');
                var current_val = parseInt($(checkbox).val());
                var index = ids.indexOf(current_val);

                if (index >= 0) {
                    ids.splice(index, 1);
                } else {
                    ids.push(current_val);
                }
            });
        },
        /**
         * Click event handler for assigning candidate
         *
         * @param  {Object} event Event object
         *
         * @return {boolean} stop event
         */
        _onAssignCandidatesClick: function (event) {
            var opening_id = $(event.target).closest('tr').data('id');

            if (opening_id == undefined) {
                return false;
            }

            $('#candidates_selection').load('/candidates/index_for_selection?exclude_opening_id=' + opening_id, function () {
                var candidates_selection_container = $('#candidates_selection_container');

                candidates_selection_container.data('ids', []);
                candidates_selection_container
                    .show()
                    .dialog({
                    width: 400,
                    height: 500,
                    title: "Select Candidates",
                    modal: true,
                    buttons: {
                        "OK": function () {
                            var id = opening_id;
                            var candidate_ids = candidates_selection_container.data('ids');

                            $.post('/openings/' + id + '/assign_candidates', {
                                candidates: candidate_ids
                            }).done(function (response) {
                                if (!response.success) {
                                    $('#error_messages').html('<p class="errors">' + response.messages + '</p>').parent().show();
                                } else {
                                    $("#candidates_selection_container").hide().dialog("close");
                                    location.reload();
                                }
                            }).fail(function (jqXHR, textStatus, errorThrown) {
                                alert('fail');
                            });
                        },
                        Cancel: function () {
                            $("#candidates_selection_container").hide().dialog("close");
                        }
                    }
                });
            });

            return false;
        }
    };

    tmpst.openingsPage = tmpst.Class(page);
}(jQuery, tmpst));