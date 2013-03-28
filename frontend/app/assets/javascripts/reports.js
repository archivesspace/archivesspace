$(function() {
  $("form.form-report").submit(function() {
    // hide any errors after a form submit
    $(".alert-error").remove();
    $(".error").removeClass("error");
  });
});