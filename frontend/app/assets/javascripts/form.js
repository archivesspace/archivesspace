//= require update_monitor
//= require login

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
      $this.on("change keyup", ":input", function(event) {
        if ($(this).data("original_value") && ($(this).data("original_value") !== $(this).val())) {
          onFormElementChange(event);
        } else if ($.inArray(event.keyCode, ignoredKeycodes) === -1) {
          onFormElementChange(event);
        }
      });
      $this.on("focusin", ":input", function(event) {
        $(event.target).parents(".subrecord-form").addClass("focus");
      });
      $this.on("focusout", ":input", function(event) {
        $(event.target).parents(".subrecord-form").removeClass("focus");
      });
      $this.on("click", ":radio, :checkbox", onFormElementChange);


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
        $(":input[type='submit'], :input.btn-primary", $this).attr("disabled","disabled");
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

  $(document).bind("loadedrecordform.aspace", function(event, $container) {
    $.proxy(initFormChangeDetection, $("form.aspace-record-form", $container))();
  });

  $.proxy(initFormChangeDetection, $("form.aspace-record-form"))();
});

// Add session active check upon form submission
$(function() {
  var initSessionCheck = function() {
    // don't bother checking for the session when running the
    // the selenium tests.
    if (typeof TEST_MODE != "undefined" && TEST_MODE === true) {
      return;
    }


    $(this).each(function() {
      var $form = $(this);

      $form.on("submit", function(event) {
        if ($form.data("sessionValidated")) {
          // continue to submit!
          return true;
        }

        event.preventDefault();
        event.stopPropagation();

        $.ajax({
          url: APP_PATH + "has_session",
          data_type: "json",
          success: function(json) {
            if (json.has_session) {
              $form.data("sessionValidated", true);
              $form.submit();
            } else {
              $(":input[type='submit'], :input.btn-primary", $form).removeAttr("disabled");
              var $modal = AS.openAjaxModal(APP_PATH + "login");
              var $loginForm = $("form", $modal);
              AS.LoginHelper.init($loginForm);
              $loginForm.on("loginsuccess.aspace", function(event, data) {
                $(":input[name=authenticity_token]", $form).val(data.csrf_token);
                $form.data("sessionValidated", true);
                $form.submit();
              });
            }
          },
          error: function() {
            $(":input[type='submit'], :input.btn-primary", $form).removeAttr("disabled");
          }
        });

      });
    });
  };

  $(document).bind("loadedrecordform.aspace", function(event, $container) {
    $.proxy(initSessionCheck, $("form.aspace-record-form", $container))();
  });

  $.proxy(initSessionCheck, $("form.aspace-record-form"))();
});
