var citeModal;

function setupCite() {
  $('#cite_sub').on('submit', function (e) {
    e.preventDefault();
    new Clipboard('.clip-btn');
    citeModal = new bootstrap.Modal(document.getElementById('cite_modal'));
    citeModal.show();
    return false;
  });

  document.getElementById('cite_modal').addEventListener('hidden.bs.modal', function() {
    document.body.classList.remove('modal-open');
    var backdrops = document.querySelectorAll('.modal-backdrop');
    backdrops.forEach(function(backdrop) {
      backdrop.remove();
    });
  });
}

$(document).ready(function() {
  setupCite();
});
