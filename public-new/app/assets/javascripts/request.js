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
	    /*	    alert("you clicked me!");
		    console.log($("#request_form")) */
    $("#request_form").submit();
	});
}


function request_form() {
    $("#request_modal").modal('show');
}
