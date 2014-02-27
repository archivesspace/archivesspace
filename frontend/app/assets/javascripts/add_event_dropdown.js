$(function () {

  var init = function () {
    $('.add-event-form .btn-close').on('click', function (event) {
      event.stopImmediatePropagation();
      event.preventDefault();
      $('.add-event-action').trigger("click");
    });

    // Override the default bootstrap dropdown behaviour here to
    // ensure that this modal stays open even when another modal is
    // opened within it.
    $(".add-event-action").on("click", function(event) {
      event.preventDefault();
      event.stopImmediatePropagation();

      if ($(this).attr('disabled')) {
        return;
      }

      if ($(".add-event-form")[0].style.display === "block") {
        // Hide it
        $(".add-event-form").css("display", "");
      } else {
        // Show it
        $(".add-event-form").css("display", "block");
      }
    });

    // Stop the modal from being hidden by clicks within the form
    $(".add-event-form").on("click", function(event) {
      event.stopPropagation();
    });


    $(".add-event-form .add-event-button").on("click", function(event) {
      event.stopPropagation();
      event.preventDefault();

      var url = AS.quickTemplate(decodeURIComponent($("#add-event-dropdown").data("add-event-url")), {event_type: $("#add_event_event_type").val()});
      location.href = url;
    });
  };


  if ($('.add-event-form').length > 0) {
    init();
  } else {
    $(document).bind("loadedrecordform.aspace", init);
  }

});
