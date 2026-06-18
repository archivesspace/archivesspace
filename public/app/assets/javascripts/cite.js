function setupCite() {
  $('#cite_sub').on('submit', function (e) {
    e.preventDefault();

    new Clipboard('.clip-btn');

    new bootstrap.Modal(document.querySelector('#cite_modal')).show();

    return false;
  });
}
