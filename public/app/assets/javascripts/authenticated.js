// I started here, but this isn't really used anymore as I started to think better of doing auth client-side... but leaving
// for now in case I want to return to it.

function check(val) {
  var authenticated = val;
  console.log(authenticated);
}

$(function () {
  if (typeof FRONTEND_URL === 'undefined') {
    return;
  }

  $.ajax(FRONTEND_URL + '/check_pui_session', {
    data: {},
    type: 'GET',
    dataType: 'json',
    xhrFields: {
      withCredentials: true,
    },
  })
    .done(function (data) {
      if (data.view_pui === true) {
        const authenticated = document.getElementById('authenticated');
        authenticated.value = data.view_pui;
      } else {
        check(false);
      }
    })
    .fail(function () {
      check(false);
    });
});
