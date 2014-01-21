// Fix focus issue when two modals are on the page
// see http://stackoverflow.com/questions/13649459/twitter-bootstrap-multiple-modal-error
$.fn.modal.Constructor.prototype.enforceFocus = function() {};