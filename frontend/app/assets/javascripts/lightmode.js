// Handle toggle (hide / show fields & sections) for light mode
$(function () {
  $(document).bind('loadedrecordform.aspace', function (event, $container) {
    init();
  });

  var init = function () {
    var lightmodeToggle = $('#lightmode_toggle'); // This is our toggle checkbox
    if (lightmodeToggle && lightmodeToggle.data('type')) {
      var lmKey = getLightModeKey(lightmodeToggle);
      if (localStorage.getItem(lmKey) === null) {
        localStorage.setItem(lmKey, 'false'); // Default if not previously set
      }
      lightmodeToggle.prop('checked', JSON.parse(localStorage.getItem(lmKey)));
      $(document).trigger('lightmode_toggle.aspace', [lightmodeToggle, 0]);
    }
  };

  // For now at least local storage key is based on data type attr
  var getLightModeKey = function (lightmodeToggle) {
    return 'lightmode_toggle.' + lightmodeToggle.data('type');
  };

  $('#lightmode_toggle').on('change', function () {
    $(document).trigger('lightmode_toggle.aspace', [$(this), 500]);
  });

  $(document).bind(
    'lightmode_toggle.aspace',
    function (event, lightmodeToggle, duration) {
      var lmKey = getLightModeKey($(lightmodeToggle));
      if ($(lightmodeToggle).prop('checked') == true) {
        localStorage.setItem(lmKey, 'true');
        $('.lightmode_toggle').hide(duration);
      } else {
        localStorage.setItem(lmKey, 'false');
        $('.lightmode_toggle').show(duration);
      }
    }
  );
});
