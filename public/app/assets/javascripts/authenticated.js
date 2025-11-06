(function () {
  if (!PUI_REQUIRE_AUTH) return;
  if (window.location.pathname === '/login') {
    return;
  }

  document.addEventListener('DOMContentLoaded', function () {
    function showApp() {
      var authCheck = document.getElementById('auth-check');
      var appContainer = document.getElementById('pui-container');
      if (authCheck) authCheck.style.display = 'none';
      if (appContainer) appContainer.style.display = '';
    }

    // Already logged into PUI
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

    // Not logged into PUI, check for existing staff session
    if (typeof FRONTEND_URL === 'undefined') {
      window.location.href = '/login';
      return;
    }

    console.log('Checking for staff session...');
    $.ajax(FRONTEND_URL + '/check_pui_session', {
      type: 'GET',
      dataType: 'json',
      xhrFields: {
        withCredentials: true,
      },
    })
      .done(function (response) {
        if (response.view_pui === true) {
          console.log(
            'Found staff session, logging in as: ' + response.username
          );
          // Exchange staff session for PUI session
          $.ajax('/login/staff_handoff', {
            type: 'POST',
            dataType: 'json',
            data: {
              session: response.session,
              username: response.username,
            },
          })
            .done(function () {
              window.location.reload();
            })
            .fail(function () {
              window.location.href = '/login';
            });
        } else {
          window.location.href = '/login';
        }
      })
      .fail(function () {
        window.location.href = '/login';
      });
  });
})();
