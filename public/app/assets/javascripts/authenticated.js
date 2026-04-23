$(function () {
  if (typeof FRONTEND_URL === 'undefined') {
    return;
  }

  if (typeof PUI_USER === 'string' && PUI_USER.trim() !== '') {
    console.log('Logged in via PUI');
    const userDropdown = document.getElementById('user-menu-dropdown');
    userDropdown.innerHTML += PUI_USER;
    userDropdown.style.display = 'block';
    return;
  } else {
    console.log('Not logged in via PUI');
    $.ajax(FRONTEND_URL + '/check_pui_session', {
      data: {},
      type: 'GET',
      dataType: 'json',
      xhrFields: {
        withCredentials: true,
      },
    })
      .done(function (response) {
        if (response.view_pui === true) {
          console.log('Authenticated as: ' + response.username);
          const userDropdown = document.getElementById('user-menu-dropdown');
          userDropdown.innerHTML += response.username;
          userDropdown.style.display = 'block';
          const authenticated = document.getElementById('staff_authenticated');
          authenticated.value = response.view_pui;
        } else {
          check(false);
          console.log('Not authenticated.');
          if (window.location.pathname !== '/login') {
            window.location.href = '/login';
          }
        }
      })
      .fail(function () {
        check(false);
      });
  }
});
