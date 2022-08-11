$(document).ready(function () {
  $('#language_select_dropdown').on('change', function () {
    $('#language_select_form').trigger('submit');
  });
});
