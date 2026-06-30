(function () {
  function initLanguageSelector(container) {
    var root = container || document;
    var dropdown = root.querySelector('#language-of-description-dropdown');
    if (!dropdown) return;

    var currentLang = new URLSearchParams(window.location.search).get(
      'language_of_description'
    );
    if (currentLang) {
      var match = dropdown.querySelector(
        'input[type="radio"][value="' + currentLang + '"]'
      );
      if (match) {
        dropdown
          .querySelectorAll('input[type="radio"]')
          .forEach(function (radio) {
            radio.checked = false;
          });
        match.checked = true;
      }
    }

    dropdown.querySelectorAll('input[type="radio"]').forEach(function (radio) {
      radio.addEventListener('change', function () {
        var url = new URL(window.location.href);
        url.searchParams.set('language_of_description', this.value);
        window.location.href = url.toString();
      });
    });
  }

  function ready(fn) {
    if (document.readyState !== 'loading') {
      fn();
    } else {
      document.addEventListener('DOMContentLoaded', fn);
    }
  }

  ready(function () {
    $(document).bind('loadedrecordform.aspace', function (event, $container) {
      initLanguageSelector($container && $container[0]);
    });

    initLanguageSelector();
  });
})();
