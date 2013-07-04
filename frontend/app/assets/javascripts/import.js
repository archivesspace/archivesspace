//= require status_streams

$(function() {
  $("form#import").submit(function() {
    $(".btn-primary", this).addClass("disabled").addClass("busy").attr("disabled", "disabled");
    $(":input, .btn-cancel", this).attr("disabled", "disabled");
  });
});