// THIS IS ZELIP.js!

$(document).ready(function () {
  $('[data-scrollspy-target]').scrollspy({
    target: '#archivesSpaceSidebar',
    offset: 20,
  });

  $('[data-scrollspy-target]').each(function () {
    var $spy = $(this).scrollspy('refresh');
    console.log('this:', this);
  });

  console.log('scrollspy ZELIP!', $('[data-scrollspy-target]'));

  $('[data-scrollspy-target]').on('activate.bs.scrollspy', function (e) {
    console.log('scrollspy activated, e:', e);
  });
});
