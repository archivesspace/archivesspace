(function () {
  document.addEventListener('DOMContentLoaded', function () {
    var authCheck = document.getElementById('auth-check');

    if (!authCheck) return;

    function showForm() {
      authCheck.style.display = 'none';
      var formWrapper = document.getElementById('login-form-wrapper');
      if (formWrapper) formWrapper.style.display = '';
    }

    function csrfToken() {
      var meta = document.querySelector('meta[name="csrf-token"]');
      return meta ? meta.content : '';
    }

    if (PUI_SKIP_AUTOCHECK) {
      showForm();
      return;
    }

    if (typeof FRONTEND_URL === 'undefined') {
      showForm();
      return;
    }

    fetch(FRONTEND_URL + '/check_pui_session', {
      method: 'GET',
      credentials: 'include',
    })
      .then(function (response) {
        if (!response.ok) throw new Error('check_pui_session request failed');
        return response.json();
      })
      .then(function (data) {
        if (data.view_pui !== true) {
          showForm();
          return;
        }

        var body = new URLSearchParams();
        body.set('session', data.session);
        body.set('username', data.username);

        fetch(AS.app_prefix('/login/staff_handoff'), {
          method: 'POST',
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'X-CSRF-Token': csrfToken(),
          },
          body: body.toString(),
        })
          .then(function (response) {
            if (!response.ok) throw new Error('staff_handoff request failed');
            window.location.reload();
          })
          .catch(showForm);
      })
      .catch(showForm);
  });
})();
