(function () {
  if (typeof FRONTEND_URL === 'undefined') {
    return;
  }

  // Don't run authentication check on login page
  if (window.location.pathname === '/login') {
    return;
  }

  document.addEventListener('DOMContentLoaded', function () {
    function showApp() {
      var authCheck = document.getElementById('auth-check');
      var appContainer = document.getElementById('pui-container');
      if (authCheck) {
        authCheck.style.display = 'none';
      }
      if (appContainer) {
        appContainer.style.display = '';
      }
    }

    function redirectToLogin() {
      window.location.href = '/login';
    }

    if (typeof PUI_USER === 'string' && PUI_USER.trim() !== '') {
      console.log('Logged in via PUI');
      var userDropdown = document.getElementById('user-menu-dropdown');
      if (userDropdown) {
        userDropdown.innerHTML += PUI_USER;
        userDropdown.style.display = 'block';
      }
      showApp();
      return;
    }

    console.log('Not logged in via PUI');
    $.ajax(FRONTEND_URL + '/check_pui_session', {
      type: 'GET',
      dataType: 'json',
      xhrFields: {
        withCredentials: true,
      },
    })
      .done(function (response) {
        if (response.view_pui === true) {
          console.log('Authenticated as: ' + response.username);
          var userDropdown = document.getElementById('user-menu-dropdown');
          if (userDropdown) {
            userDropdown.innerHTML += response.username;
            userDropdown.style.display = 'block';
          }
          var authenticated = document.getElementById('staff_authenticated');
          if (authenticated) {
            authenticated.value = response.view_pui;
          }
          showApp();
        } else {
          console.log('Not authenticated.');
          redirectToLogin();
        }
      })
      .fail(function () {
        redirectToLogin();
      });
  });
})();
