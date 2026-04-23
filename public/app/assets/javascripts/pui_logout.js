$(function () {
  $('#pui-logout').on('click', function () {
    $.ajax(FRONTEND_URL + '/logout_pui_session', {
      data: {},
      type: 'GET',
      xhrFields: {
        withCredentials: true,
      },
      success: function (response) {
        console.log(response);
      },
      error: function (xhr, status, error) {
        // Handle errors
        console.error(error);
      },
    });
  });
});
