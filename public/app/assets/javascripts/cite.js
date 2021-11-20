function setupCite() {
  $('#cite_sub').submit(function () {
    new Clipboard('.clip-btn');
    $('#cite_modal').modal('show');
    return false;
  });
}
