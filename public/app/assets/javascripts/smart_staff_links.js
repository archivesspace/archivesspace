$(function() {

  if (typeof RECORD_URI === "undefined" || typeof FRONTEND_URL === 'undefined') {
    return;
  }

  $.ajax(FRONTEND_URL + "/check_session", {
    data: {
      uri: RECORD_URI
    },
    type: "GET",
    dataType: "json",
    xhrFields: {
      withCredentials: true
    }
  }).done(function( data ) {
    if (data === true) {
      var staff = $('#staff-link');
      link = FRONTEND_URL + "/resolve/edit?uri=" + RECORD_URI + "&autoselect_repo=true";
      staff.attr("href", link);
      staff.fadeIn("slow").removeClass("hide");
    }
  }).fail(function() {
    // do nothing
  });

});
