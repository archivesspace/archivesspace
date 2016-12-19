function setupRequest(modalId) {
    $('#request_sub').submit(function(e) {
            request_form();
            return false;
        });
}


function request_form() {
    $("#request_modal").modal('show');
}
