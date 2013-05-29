$(function() {

  var INTERVAL_PERIOD = 10000; // check every 10 seconds

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
    };

    var handleOpenedForEditing = function(status_data) {
      console.log("RECORD OPENED FOR EDITING");
      console.log(status_data);
    };

    var poll = function() {
      $.post(
        poll_url,
        {
          lock_version: lock_version,
          uri: uri
        },
        function(json, textStatus, jqXHR) {
          if (json.status === "stale") {
            handleStaleRecord(json);
          } else if (json.status === "opened_for_editing") {
            handleOpenedForEditing(json);
          } else {
            // nobody else editing and lock_version still current
          }
        },
        "json")
    };

    var polling_interval = setInterval(poll, INTERVAL_PERIOD);
  };


  $(document).bind("setupupdatemonitor.aspace", function(event, $form) {
    setupUpdateMonitor($form);
  });
});