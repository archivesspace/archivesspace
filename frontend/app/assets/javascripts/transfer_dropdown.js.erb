$(function () {

  var init = function () {
    $('.transfer-form .btn-cancel').on('click', function () {
      $('.transfer-action').trigger("click");
    });

    // Override the default bootstrap dropdown behaviour here to
    // ensure that this modal stays open even when another modal is
    // opened within it.
    $(".transfer-action").on("click", function(event) {
      event.preventDefault();
      event.stopImmediatePropagation();

      if ($(this).attr('disabled')) {
        return;
      }

      if ($(".transfer-form")[0].style.display === "block") {
        // Hide it
        $(".transfer-form").css("display", "");
      } else {
        // Show it
        $(".transfer-form").css("display", "block");
      }
    });

    // Stop the modal from being hidden by clicks within the form
    $(".transfer-form").on("click", function(event) {
      event.stopPropagation();
    });


    $(".transfer-form .linker-wrapper .dropdown-toggle").on("click", function(event) {
      event.stopPropagation();
      $(this).parent().toggleClass("open");
    });


    $(".transfer-form .transfer-button").on("click", function(event) {
      var formvals = $(".transfer-form").serializeObject();
      if (!formvals["transfer[ref]"]) {
        $(".missing-ref-message", ".transfer-form").show();
        event.preventDefault();
        event.stopImmediatePropagation();
        return false;
      } else {
        $(".missing-ref-message", ".transfer-form").hide();
        $(this).data("form-data", {"ref": formvals["transfer[ref]"]});
      }
    });
  };


  if ($('.transfer-form').length > 0) {
    init();
  } else {
    $(document).bind("loadedrecordform.aspace", init);
  }

});
