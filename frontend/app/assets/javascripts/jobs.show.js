$(function() {
  var POLL_INTERVAL = 2000;

  var $logSpool = $("#logSpool");
  var $logSection = $("#logs");

  var offset = 0;

  var pollLog = function() {
    $.ajax({
      url: $logSection.data("url"),
      data: {
        offset: offset
      },
      type: "GET",
      success: function(data, status, xhr) {
        $logSpool.append(data);
        offset += data.length;
      }
    });
  };

  var LOG_POLL = setInterval(pollLog, POLL_INTERVAL);
});