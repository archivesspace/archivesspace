function setupRequest(modalId, text) {
    $(".noscript").hide();
    $('#request_sub').submit(function(e) {
        request_form();
        return false;
    });
    var $modal = $('#' + modalId);
    $modal.find('div.modal-body').attr('id', 'requestThis');
    var x = $modal.find('.action-btn');
    var btn;
    if (x.length == 1) {
        btn = x[0];
    }
    else {
        btn = x;
    }
    $(btn).attr('id', "request_btn");
    $(btn).html(text);
    $(btn).click(function(e) {
        $("#request_form").submit();
    });
}


function request_form() {
    $("#request_modal").modal('show');

    $('#user_name',this).closest('.form-group').removeClass('has-error');
    $('#user_email',this).closest('.form-group').removeClass('has-error');

    $('#request_form', '#request_modal').on('submit', function() {
        var proceed = true;

        if ($('#user_name',this).val().trim() == '') {
            $('#user_name',this).closest('.form-group').addClass('has-error');
            proceed = false;
        } else {
            $('#user_name',this).closest('.form-group').removeClass('has-error');
        }
        if ($('#user_email',this).val().trim() == '') {
            $('#user_email',this).closest('.form-group').addClass('has-error');
            proceed = false;
        } else {
            $('#user_email',this).closest('.form-group').removeClass('has-error');
        }

        return proceed;
    });
}
