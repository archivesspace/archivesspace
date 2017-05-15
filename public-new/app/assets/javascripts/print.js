function setupPrint(modalId) {
    $(".noscript").hide();

    $('#print_button').on('click', function (e) {
        e.preventDefault();

        print_form();

        return false;
    });
}

function print_form() {
    var modal = $("#print_modal");
    var submit = modal.find('.action-btn');

    submit.text(modal.find('input[name=submit_text]').val());

    submit.on('click', function () {
        $('#print_modal').find('form').submit();
    });

    modal.modal('show');
}
