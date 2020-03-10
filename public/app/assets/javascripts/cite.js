function setupCite(modalId, text){
    setupClip(modalId, text, '[data-js="citation"].active', 'cite');
    $('#cite_sub').submit(function(e) {
	    cite();
	    return false;
	});
}

function setupClip(modalId, btnText,target, type ) {
    var $modal = $('#' + modalId);
    $modal.find('div.modal-body').attr('id', target);
    var x = $modal.find('.action-btn');
    var btn;
    if (x.length == 1) {
      btn = x[0];
        }
        else {
      btn = x;
    }
    $(btn).attr('id', type+ "_btn");
    $(btn).addClass('clip-btn');
    $(btn).attr('data-clipboard-target', target);
    $(btn).html(btnText);
    new Clipboard('.clip-btn');
}

function cite() {
    $("#cite_modal").modal('show');
}
