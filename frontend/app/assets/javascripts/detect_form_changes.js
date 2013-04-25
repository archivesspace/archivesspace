// add form change detection
$(function() {
  var ignoredKeycodes = [37,39,9];
  var onFormElementChange = function(event) {
    $("#object_container form").triggerHandler("form-changed");
  };
  $("#object_container form :input").live("change keyup", function(event) {
    if ($(this).data("original_value") && ($(this).data("original_value") !== $(this).val())) {
      onFormElementChange();
    } else if ($.inArray(event.keyCode, ignoredKeycodes) === -1) {
      onFormElementChange();
    }
  });
  $("#object_container").live("focusin", ":input", function(event) {
    $(event.target).parents(".subrecord-form").addClass("focus");
  });
  $("#object_container").live("focusout", ":input", function(event) {
    $(event.target).parents(".subrecord-form").removeClass("focus");
  });
  $("#object_container form :radio, .object-container form :checkbox").live("click", onFormElementChange);

  var initFormChangeDetection = function() {
    $(this).each(function() {
      var $this = $(this);

      if ($this.data("changedDetectionEnabled")) {
        return
      }

      $this.data("form_changed", $this.data("form_changed") || false);

      $this.data("changedDetectionEnabled", true);

      $this.bind("form-changed", function() {
        $this.data("form_changed", true);
      });

      $this.bind("submit", function() {
        $this.data("form_changed", false);
      });

      $(window).bind("beforeunload", function(event) {
        if ($this.data("form_changed")) {
          return 'Please note you have some unsaved changes.';
        }
      });

    });
  };

  $(document).ajaxComplete(function() {
    $.proxy(initFormChangeDetection, $("#object_container form"))();
  });

  $.proxy(initFormChangeDetection, $("#object_container form"))();
});