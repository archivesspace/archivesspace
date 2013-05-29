//= require update_monitor

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
      $this.live("focusin", ":input", function(event) {
        $(event.target).parents(".subrecord-form").addClass("focus");
      });
      $this.live("focusout", ":input", function(event) {
        $(event.target).parents(".subrecord-form").removeClass("focus");
      });
      $(":radio, :checkbox", $this).live("click", onFormElementChange);


      $this.bind("formchanged.aspace", function() {
        $this.data("form_changed", true);
        $(".record-toolbar", $this).addClass("formchanged");
        $(".record-toolbar .btn-toolbar .btn", $this).addClass("disabled").attr("disabled","disabled");
      });

      $this.bind("submit", function() {
        $this.data("form_changed", false);
        $(":input[type='submit']", $this).attr("disabled","disabled");
      });

      $(".record-toolbar .revert-changes .btn", $this).click(function() {
        $this.data("form_changed", false);
        return true;
      });

      $(window).bind("beforeunload", function(event) {
        if ($this.data("form_changed") === true) {
          return 'Please note you have some unsaved changes.';
        }
      });

      if ($this.data("update-monitor")) {
        $(document).trigger("setupupdatemonitor.aspace", [$this]);
      }

    });
  };

  $(document).ajaxComplete(function() {
    $.proxy(initFormChangeDetection, $("form.aspace-record-form"))();
  });

  $.proxy(initFormChangeDetection, $("form.aspace-record-form"))();
});