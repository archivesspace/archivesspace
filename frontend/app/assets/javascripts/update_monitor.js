$(function() {

  var INTERVAL_PERIOD = 10000; // check every 10 seconds
  var STATUS_STALE = "stale";
  var STATUS_OTHER_EDITORS = "opened_for_editing";

  var setupUpdateMonitor = function($form) {

    if ($form.data("update-monitor") === "enabled") {
      return;
    }

    $form.data("update-monitor", "enabled");

    var poll_url = $form.data("update-monitor-url");
    var lock_version = $form.data("update-monitor-lock_version");
    var uri = $form.data("update-monitor-record-uri");

    var handleStaleRecord = function(status_data) {
      console.log("STALE RECORD");
      console.log(status_data);
      insertErrorAndHighlightSidebar(status_data);
    };

    var handleOpenedForEditing = function(status_data) {
      console.log("RECORD OPENED FOR EDITING");
      console.log(status_data);
      insertErrorAndHighlightSidebar(status_data);
    };

    var insertErrorAndHighlightSidebar = function(status_data) {
      // insert the error
      $("#form_messages .update-monitor-error", $form).remove(); // remove any existing errors
      if (status_data.status === STATUS_STALE) {
        $("#form_messages", $form).prepend(AS.renderTemplate("update_monitor_stale_record_message_template"));
        $(".btn-primary, .btn-toolbar .btn", $form).attr("disabled", "disabled").addClass("disabled");
      } else if (status_data.status === STATUS_OTHER_EDITORS) {
        var user_ids = [];
        $.each(status_data.edited_by, function(user_id, timestamp) {
          user_ids.push(user_id);
        });
        $("#form_messages", $form).prepend(AS.renderTemplate("update_monitor_other_editors_message_template", {user_ids: user_ids.join(", ")}));
      }

      // highlight in the sidebar
      if ($(".as-nav-list li.alert-error").length === 0) {
        $(".as-nav-list").prepend("<li class='alert-error update-monitor-error'><a href='#form_messages'>Errors and Warnings</a></li>");
      }
      var $errorNavListItem = $(".as-nav-list li.alert-error");

      if (!$errorNavListItem.hasClass("acknowledged")) {
        var highlight_interval = setInterval(function() {
          $errorNavListItem.toggleClass("active");
        }, 3000)
        $errorNavListItem.hover(function() {
          clearInterval(highlight_interval);
          $errorNavListItem.removeClass("active").addClass("acknowledged");
        }, function() {});
      }
    };

    var clearAnyMonitorErrors = function() {
      $("li.update-monitor-error", $form).remove();
    };

    var poll = function() {
      $.post(
        poll_url,
        {
          lock_version: lock_version,
          uri: uri
        },
        function(json, textStatus, jqXHR) {
          if (json.status === STATUS_STALE) {
            handleStaleRecord(json);
          } else if (json.status === STATUS_OTHER_EDITORS) {
            handleOpenedForEditing(json);
          } else {
            // nobody else editing and lock_version still current
            clearAnyMonitorErrors()
          }
        },
        "json")
    };

    poll();
    var polling_interval = setInterval(poll, INTERVAL_PERIOD);
  };


  $(document).bind("setupupdatemonitor.aspace", function(event, $form) {
    setupUpdateMonitor($form);
  });
});
