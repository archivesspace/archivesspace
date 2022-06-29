// toggle slug field when auto-gen is on
var activate_slug_checkbox = function () {
  var textfield = $('div.js-slug_textfield > div > input');
  var checkbox = $('div.js-slug_auto_checkbox > div > input');

  checkbox.click(function () {
    textfield.val('');
    textfield.attr('readonly', function (_, attr) {
      return !attr;
    });
  });
};
