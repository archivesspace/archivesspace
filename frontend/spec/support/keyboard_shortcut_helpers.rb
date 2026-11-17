# frozen_string_literal: true

module KeyboardShortcutHelpers
  def press_save_shortcut
    press_ctrl_shift('s')
  end

  def press_close_shortcut
    press_ctrl_shift('x')
  end

  # Presses Shift+Ctrl+X where it should do nothing, then verifies the page
  # neither navigated nor reloaded. This records two signals in the page:
  # - navigation-started: set when a navigation begins. The Navigation API's
  #   navigate event fires synchronously when the shortcut assigns
  #   window.location.href; beforeunload is the fallback for browsers
  #   without it.
  # - close-shortcut-handled: set by a keydown listener when the shortcut's
  #   keydown reaches the page. Waiting for it confirms the keypress was
  #   delivered; by the time the next check runs, the whole keydown dispatch,
  #   including the app's handler, has finished.
  def press_close_shortcut_and_expect_nothing
    url = page.current_url
    page.execute_script(<<~JS)
      const markNavigationStarted = function () {
        document.body.classList.add('navigation-started');
      };
      if (window.navigation) {
        window.navigation.addEventListener('navigate', markNavigationStarted);
      } else {
        window.addEventListener('beforeunload', markNavigationStarted);
      }

      window.addEventListener('keydown', function (event) {
        if (event.ctrlKey && event.shiftKey && event.key.toLowerCase() === 'x') {
          document.body.classList.add('close-shortcut-handled');
        }
      });
    JS

    press_close_shortcut

    expect(page).to have_css('body.close-shortcut-handled')
    aggregate_failures do
      expect(page).to have_no_css('body.navigation-started')
      expect(page).to have_current_path(url, url: true)
    end
  end

  def press_ctrl_shift(key)
    page.driver.browser.action
      .key_down(:control).key_down(:shift).send_keys(key)
      .key_up(:shift).key_up(:control).perform
  end

  def start_counting_form_submissions
    page.execute_script(<<~JS)
      window.formSubmissionCount = 0;
      document.addEventListener('submit', function () { window.formSubmissionCount += 1; }, true);
    JS
  end

  def form_submission_count
    page.evaluate_script('window.formSubmissionCount')
  end
end
