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
        if ($(event.target).parents("*[data-no-change-tracking='true']").length === 0) {
          $this.trigger("formchanged.aspace");
        }
      };
      $(":input", $this).live("change keyup", function(event) {
        if ($(this).data("original_value") && ($(this).data("original_value") !== $(this).val())) {
          onFormElementChange(event);
        } else if ($.inArray(event.keyCode, ignoredKeycodes) === -1) {
          onFormElementChange(event);
        }
      });
      $this.live("focusin", ":input", function(event) {
        $(event.target).parents(".subrecord-form").addClass("focus");
      });
      $this.live("focusout", ":input", function(event) {
        $(event.target).parents(".subrecord-form").removeClass("focus");
      });
      $(":radio, :checkbox", $this).live("click", onFormElementChange);


      $this.bind("formchanged.aspace", function(event) {
        $this.data("form_changed", true);
        $(".record-toolbar", $this).addClass("formchanged");
        $(".record-toolbar .btn-toolbar .btn", $this).addClass("disabled").attr("disabled","disabled");
      });

      $(".createPlusOneBtn", $this).on("click", function() {
        $this.data("createPlusOne", "true");
      });

      $this.bind("submit", function(event) {
        $this.data("form_changed", false);
        $(":input[type='submit']", $this).attr("disabled","disabled");
        if ($(this).data("createPlusOne")) {
          var $input = $("<input>").attr("type", "hidden").attr("name", "plus_one").val("true");
          $($this).append($input);
        }
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
      } else if ($this.closest(".modal").length === 0) {
        // if form isn't opened via a modal, then clear the timeouts
        // and they will be reinitialised for that form (e.g. tree forms)
        $(document).trigger("clearupdatemonitorintervals.aspace", [$this]);
      }

    });
  };

  $(document).ajaxComplete(function() {
    $.proxy(initFormChangeDetection, $("form.aspace-record-form"))();
  });

  $.proxy(initFormChangeDetection, $("form.aspace-record-form"))();
});
