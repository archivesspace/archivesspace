$(function() {

  var loc = $(location).attr('href').replace(/#.*$/, '');

  var getPath = function() {
    var path = loc;
    var agents_pattern = /(.*agents)\/(\d+)\?agent_type=agent_([a-z_]+)/

    var pm = loc.match(agents_pattern);
    if ( pm ) {
      path = pm[1] + "/" + pm[3].replace('person', 'people').replace('entity', 'entities').replace('family', 'families') + "/" + pm[2];
    }
    
    return path.replace(PUBLIC_URL, '');
  }

  var staffAuthEndpoint = function() {
    if (typeof FRONTEND_URL == 'undefined') {
      return;
    } else if (typeof record_type == 'undefined') {
      console.log("can't determine record type");
      return;
    } else {
      var repo_param = "";
      var lm = loc.match(/(\/repositories\/\d+)\//);
      if ( lm ) {
        repo_param = "&repository=" + lm[1];
      }
      return FRONTEND_URL + "/check_session?record_type=" +  record_type + repo_param;
    }
  }();

  if (typeof staffAuthEndpoint == 'undefined') {
    return;
  }

  $.ajax(staffAuthEndpoint , {
    dataType: "json",
    xhrFields: {
      withCredentials: true
    }
  }).done(function( data ) {
    if (data === true) {
      var staff = $('#staff-link');
      link = FRONTEND_URL + "/resolve/edit?uri=" + getPath() + "&autoselect_repo=true";
      staff.attr("href", link);
      staff.fadeIn("slow").removeClass("hide");
    }
  }).fail(function() {
    // do nothing
  });

});
