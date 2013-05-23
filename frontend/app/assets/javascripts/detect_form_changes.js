// add form change detection
$(function() {
  var ignoredKeycodes = [37,39,9];

  var initFormChangeDetection = function() {
    $(this).each(function() {
      var $this = $(this);

      if ($this.data("changedDetectionEnabled")) {
        return;
      }

      $this.data("form_changed", $this.data("form_changed") || false);
      $this.data("changedDetectionEnabled", true);


      var $objectContainer = $($this.closest("#object_container")[0]);

      var onFormElementChange = function(event) {
        $this.triggerHandler("formchanged.aspace");
      };
      $(":input", $this).live("change keyup", function(event) {
        if ($(this).data("original_value") && ($(this).data("original_value") !== $(this).val())) {
          onFormElementChange();
        } else if ($.inArray(event.keyCode, ignoredKeycodes) === -1) {
          onFormElementChange();
        }
      });
      $objectContainer.live("focusin", ":input", function(event) {
        $(event.target).parents(".subrecord-form").addClass("focus");
      });
      $objectContainer.live("focusout", ":input", function(event) {
        $(event.target).parents(".subrecord-form").removeClass("focus");
      });
      $(":radio, :checkbox", $this).live("click", onFormElementChange);


      $this.bind("formchanged.aspace", function() {
        $this.data("form_changed", true);
        $("#object_container .record-toolbar").addClass("formchanged");
        $("#object_container .record-toolbar .btn-toolbar .btn").addClass("disabled").attr("disabled","disabled");
      });

      $this.bind("submit", function() {
        $this.data("form_changed", false);
        $(":input[type='submit']", $this).attr("disabled","disabled");
      });

      $("#object_container .record-toolbar .revert-changes .btn").click(function() {
        $this.data("form_changed", false);
        return true;
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