$(function () {
  $('#pui-logout').on('click', function () {
    $.ajax(FRONTEND_URL + '/logout_pui_session', {
      type: 'GET',
      xhrFields: {
        withCredentials: true,
      },
      success: function (response) {
        window.location.href = '/';
      },
      error: function (xhr, status, error) {
        // Handle errors
        console.error(error);
      },
    });
  });
});
