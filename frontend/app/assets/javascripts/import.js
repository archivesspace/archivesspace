//= require status_streams

$(function() {
  var $import_form = $("form#import");

  // disable the import button by default
  $(".btn-primary", $import_form).addClass("disabled").attr("disabled", "disabled");

  // and only enable when a file has been selected to upload
  $("#upload_import_file").change(function() {
    $(".btn-primary", $import_form).removeClass("disabled").removeAttr("disabled");
  });

  $import_form.submit(function() {
    $(".btn-primary", $import_form).addClass("disabled").addClass("busy").attr("disabled", "disabled");
    $(":input", $import_form).attr("disabled", "disabled");
    $(".btn-cancel", $import_form).attr("href", "javascript:void(0)").attr("disabled", "disabled");
  });
});