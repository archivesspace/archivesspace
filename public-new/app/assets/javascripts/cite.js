function setupCite(modalId, text){
    setupClip(modalId, text, 'citeThis', 'cite');
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
    $(btn).attr('data-clipboard-target', '#'+target);
    $(btn).html(btnText);
    new Clipboard('.clip-btn');
}

function cite() {
    $("#cite_modal").modal('show');
}

function bookmark_page() {
    if (window.sidebar && window.sidebar.addPanel) { // Mozilla Firefox Bookmark \\
        window.sidebar.addPanel(document.title, window.location.href, '');
    } else if (window.external && ("AddFavorite" in window.external)) {
        window.external.AddFavorite(location.href, document.title);
    } else if (window.opera && window.print) {
        this.title = document.title;
        return true;
    } else { // webkit - safari/chrome
        alert('Press ' + (navigator.userAgent.toLowerCase().indexOf('mac') != -1 ? 'Command/Cmd' : 'CTRL') + ' + D to bookmark this page.');
    }
}

function print_page() {
    window.print();
}