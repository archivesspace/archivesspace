function setupCite() {
  new Clipboard('.clip-btn');

  $('#cite_sub').on('submit', function (e) {
    e.preventDefault();

    bootstrap.Modal.getOrCreateInstance(
      document.getElementById('cite_modal')
    ).show();

    return false;
  });
}
