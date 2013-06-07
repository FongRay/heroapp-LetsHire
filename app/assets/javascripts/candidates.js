// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
// You can also rename this file to openings.js.coffee, and only keep the coffee script

$(function() {
    if ($('#candidate-profile-panel').length > 0 && $('#candidate-applying-panel').length > 0) {
        $('#candidate-applying-panel').height($('#candidate-profile-panel').height());
        if ($('#candidate-no-assignment-msg').length > 0) {
            height = $('#candidate-profile-panel').height();
            fontsize = parseInt($('#candidate-no-assignment-msg').children()[0].style.fontSize);
            $('#candidate-no-assignment-msg').css("line-height", height / fontsize);
        }
    }

    $('.fileupload').fileupload({
        name: "candidate[resume]"
    });

    if ($('.candidates_index_new_opening').length > 0 ||
        $('.candidate_new_opening').length > 0 ||
        $('#new_candidate').length > 0)
    {
        $('#department_id').attr('name', null);
        $('#openingid_select_wrapper').attr('id', 'candidate_openingid_select_wrapper');
        $('select#opening_id').attr('name', 'candidate[opening_ids]');

        $('body').delegate('select#department_id', 'change', function() {
            Common.reloadOpening($(this), $('#candidate_openingid_select_wrapper'), 'candidate[opening_ids]');
        });

        var opening_selection_container = $("#opening_selection_container");
        function create_opening(id) {
            opening_selection_container.parent().get(0).setAttribute('action', '/candidates/' + id + '/create_opening');
            opening_selection_container.parent().dialog({
                modal: true,
                title: "Select Opening",
                width : '450px'});

        }

        $('.candidates_index_new_opening').click(function(event) {
            create_opening($(this).closest('tr').data('id'));
            return false;
        });

        $('.candidate_new_opening').click(function(event) {
            create_opening($('#candidate_id').val());
            return false;
        });
    }

    $(document).on('click', '.candidate-blacklist-link', function(event){
        event.stopPropagation();
        var candidate_id = $(this).attr('data-candidate-id');
        var div_id = "candidate-blacklist-dialog-" + candidate_id;

        $("div#" + div_id).dialog({
            height: 350,
            width: 450,
            modal: true,
            title: 'Deactive candidate',
            close: function(event, ui){
                $(this).dialog('destroy');
            }
        });
    });

    if ($('.dropdown-toggle').length > 0) {
        $('.dropdown-toggle').dropdown();
    }

    $('#candidate_resume').change(function(event) {
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

    if ($('#candidate-assessment-btn').length > 0 ){
        $('#candidate-assessment-btn').click(function(e){
            $('div#candidate-assessment-dialog').dialog({
                modal: true,
                width: '700',
                height: '620',
                title: 'Assess Candidate'
            });
        });
    }

    $("ul.interviewline").each(function (index, elem) {
        elem.childNodes[0].innerHTML = new Date(elem.childNodes[0].innerHTML).toLocaleString();
    });
});
