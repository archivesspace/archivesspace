function setupRequest() {
  $('#request_sub').on('submit', function () {
    request_form();
    return false;
  });

  $('#request_modal').find('div.modal-body').attr('id', 'requestThis');

  // Bootstrap 5 form validation: toggle .was-validated so :invalid styles apply
  $('#request_form')
    .off('submit.requestValidation')
    .on('submit.requestValidation', function (event) {
      if (!this.checkValidity()) {
        event.preventDefault();
        event.stopPropagation();
      }
      this.classList.add('was-validated');
    });
}

function request_form() {
  const modalEl = document.getElementById('request_modal');
  const form = document.getElementById('request_form');
  form.classList.remove('was-validated');
  bootstrap.Modal.getOrCreateInstance(modalEl).show();
}
