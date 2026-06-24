/* handle the accordions */
/* we need to pass in the text that is obtained via the config/locales/*yml file */
var expand_text = '';
var collapse_text = '';
/* we don't provide a button if there's only one panel; neither do we collapse that one panel */

/**
 * @param {string} what accordion panels selector
 * @param {string} ex_text 'expand text' i18n
 * @param {string} col_text 'collapse text' i18n
 * @param {boolean} expand_all
 */
function initialize_accordion(what, ex_text, col_text, expand_all) {
  expand_text = ex_text;
  collapse_text = col_text;
  if ($(what).length > 1 && $(what).parents('.acc_holder').length === 1) {
    if ($(what).parents('.acc_holder').children('.acc_button').length === 0) {
      $(what)
        .parents('.acc_holder')
        .prepend(
          "<a class='btn btn-primary acc_button mb-2' role='button' ></a>"
        );
    }
    expandAllByDefault(what, expand_all);
  }
}

/**
 * @param {string} what accordion panels selector
 * @param {boolean} expand to expand or not
 */
function expandAllByDefault(what, expand) {
  $(what).each(function () {
    toggleCollapsePanel(this, expand);
  });
  set_button(what, !expand);
}

/**
 * @param {HTMLElement} panel collapse panel element
 * @param {boolean} expand to expand or not
 */
function toggleCollapsePanel(panel, expand) {
  // Bootstrap 5 API
  if (window.bootstrap && window.bootstrap.Collapse) {
    const instance = window.bootstrap.Collapse.getOrCreateInstance(panel, {
      toggle: false,
    });

    if (expand) {
      instance.show();
    } else {
      instance.hide();
    }

    return;
  }

  // Bootstrap 4/jQuery plugin compatibility
  if (typeof $(panel).collapse === 'function') {
    $(panel).collapse(expand ? 'show' : 'hide');
  }
}

/**
 * @param {string} what accordion panels selector
 * @param {boolean} expand to expand or not
 */
function set_button(what, expand) {
  const $holder = $(what).parents('.acc_holder');
  const $btn = $holder.children('.acc_button');
  if ($btn.length === 1) {
    $btn.text(expand ? expand_text : collapse_text);
    $btn.attr(
      'href',
      "javascript:expandAllByDefault('" + what + "'," + expand + ')'
    );
  }
}
