$(function () {
  $('#print_button').on('click', function (e) {
    var self = $(this);

    var form = self.closest('form');
    var base_token = form.find("input[name='base_token']").attr('value');

    var token = base_token + new Date().getTime();
    form.find("input[name='token']").attr('value', token);

    function resetPrintBtn() {
      self.find('.generating-label').hide();
      self.find('.print-label').show();
      self.attr('disabled', null);
    }

    self.find('.print-label').hide();
    self.find('.generating-label').show();
    self.attr('disabled', 'disabled');

    setTimeout(function () {
      form.submit();
    }, 0);

    setTimeout(function () {
      resetPrintBtn();
    }, 1000);

    return false;
  });
});

// Browser printing ANW-950
window.addEventListener('beforeprint', addPageLocationMsg);
window.addEventListener('afterprint', removePageLocationMsg);

function addPageLocationMsg() {
  const contentEl = document.querySelector('#content');
  const locationEl = document.createElement('p');
  locationEl.classList.add('page-location-for-printing');
  locationEl.innerHTML = `<i>Printed from</i> ${location}`;

  contentEl.insertAdjacentElement('beforebegin', locationEl);
}

function removePageLocationMsg() {
  const locationEl = document.querySelector(
    'body p.page-location-for-printing'
  );

  if (locationEl) locationEl.remove();
}
