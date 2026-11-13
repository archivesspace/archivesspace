# frozen_string_literal: true

module KeyboardShortcutHelpers
  def press_save_shortcut
    press_ctrl_shift('s')
  end

  def press_close_shortcut
    press_ctrl_shift('x')
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
