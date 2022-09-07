// Fix focus issue when two modals are on the page
// see http://stackoverflow.com/questions/13649459/twitter-bootstrap-multiple-modal-error

// commenting this out for now since it doesn't work with BS5 & causes a console error
// $.fn.modal.Constructor.prototype.enforceFocus = function () {};

// console.log("BS OVERRIDE");

// $.fn.modal.Constructor.prototype.setBackdropHeight = function() {
//   console.log(this.$backdrop);
// };

// Modal.prototype.setBackdropHeight = function () {
//   this.$backdrop
//     .css('height', 0)
//     .css('height', this.$element[0].scrollHeight)
// }
