$(function() {
  var LOG_POLL_INTERVAL = 2000;
  var STATUS_POLL_INTERVAL = 2000;

  var LOG_POLL, STATUS_POLL;

  var $statusSection = $("#job_status");

  var CURRENT_STATUS = $statusSection.data("current-status");

  var initLoggingSpool = function() {
    var $logSection = $("#logs");
    var $logSpool = $("#logSpool", $logSection);
    var $followLogBtn = $(".btn-follow-log", $logSection);

    if ($logSection.length === 0) {
      return;
    }

    $followLogBtn.on("click", function() {
      $(this).toggleClass("active");
    });

    var offset = 0;

    var pollLog = function() {
      $.ajax({
        url: $logSection.data("poll-url"),
        data: {
          offset: offset
        },
        type: "GET",
        success: function(data) {
          var dataLength = data.length;
          $logSpool.append(data);
          offset +=dataLength;

          if (dataLength === 0) {
            // Hmm... we may have finished... or failed,,
            // so let's poll the status to double check.
            pollStatus();
          }

          if (CURRENT_STATUS === "running") {
            LOG_POLL = setTimeout(pollLog, LOG_POLL_INTERVAL);
            if ($followLogBtn.hasClass("active")) {
              $logSpool.animate({
                scrollTop: $logSpool[0].scrollHeight
              });
            }
          } else {
            // The log is only loaded once..
            // So show the bottom of the log.. as that's where
            // the errors and finish summary will be.
            $logSpool[0].scrollTop = $logSpool[0].scrollHeight;
          }
        }
      });
    };
    pollLog();
  };

  var pollStatus = function() {
    $.ajax({
      url: $statusSection.data("poll-url"),
      type: "GET",
      dataType: "json",
      success: function(json) {
        if (CURRENT_STATUS != json.status) {
          CURRENT_STATUS = json.status;
          var templateName = "template_job_"+json.status + "_notice";
          var $li = $("<li>");
          $li.append(AS.renderTemplate(templateName));
          $("#archivesSpaceSidebar .nav-list").append($li);
        } else if ($.inArray(CURRENT_STATUS, ["queued"]) >= 0) {
          STATUS_POLL = setTimeout(pollStatus, STATUS_POLL_INTERVAL);
        }
      }
    });
  };

  $("#archivesSpaceSidebar").on("click", ".btn-refresh", function() {
    location.reload();
  });

  if ($.inArray(CURRENT_STATUS, ["queued"]) >= 0) pollStatus();
  initLoggingSpool();
});