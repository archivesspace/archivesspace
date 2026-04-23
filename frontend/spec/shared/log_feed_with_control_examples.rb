# frozen_string_literal: true

require 'timeout'

# Shared examples for verifying a log feed with auto-scroll control behavior.
#
# Prerequisites:
# - The `#logSpool` log container element is present

RSpec.shared_examples 'log feed with auto-scroll control' do
  def log_div_count
    page.evaluate_script('document.getElementById("logSpool").children.length')
  end

  def scroll_metrics
    {
      scroll_height: page.evaluate_script('document.getElementById("logSpool").scrollHeight'),
      client_height: page.evaluate_script('document.getElementById("logSpool").clientHeight'),
      scroll_top: page.evaluate_script('document.getElementById("logSpool").scrollTop'),
    }
  end

  def wait_for_scroll_to_bottom(tolerance: 50)
    Timeout.timeout(Capybara.default_max_wait_time) do
      loop do
        metrics = scroll_metrics
        target = metrics[:scroll_height] - metrics[:client_height]
        break if (metrics[:scroll_top] - target).abs <= tolerance
        sleep 0.1
      end
    end
  end

  def wait_for_scroll_to_top(tolerance: 5)
    Timeout.timeout(Capybara.default_max_wait_time) do
      loop do
        scroll_top = page.evaluate_script('document.getElementById("logSpool").scrollTop')
        break if scroll_top <= tolerance
        sleep 0.1
      end
    end
  end

  def is_scrolled_to_bottom?(tolerance: 50)
    metrics = scroll_metrics
    target = metrics[:scroll_height] - metrics[:client_height]
    (metrics[:scroll_top] - target).abs <= tolerance
  end

  def is_scrolled_to_top?(tolerance: 5)
    scroll_top = page.evaluate_script('document.getElementById("logSpool").scrollTop')
    scroll_top <= tolerance
  end

  def wait_for_scroll_to_stabilize(checks: 3, interval: 0.2)
    previous_scroll = nil
    checks.times do
      current_scroll = page.evaluate_script('document.getElementById("logSpool").scrollTop')
      break if previous_scroll == current_scroll
      previous_scroll = current_scroll
      sleep interval
    end
  end

  def is_scrollable?
    metrics = scroll_metrics
    metrics[:scroll_height] > metrics[:client_height]
  end

  describe 'auto-scroll control' do
    it 'toggles between "Following Log" and "Follow Log" text' do
      follow_log_button = find('.btn-follow-log')

      expect(follow_log_button).to have_content('Following Log')
      expect(follow_log_button[:class]).to include('active')

      follow_log_button.click
      expect(follow_log_button).to have_content('Follow Log')
      expect(follow_log_button[:class]).not_to include('active')

      follow_log_button.click
      expect(follow_log_button).to have_content('Following Log')
      expect(follow_log_button[:class]).to include('active')
    end
  end

  describe 'log feed' do
    context 'when actively following' do
      it 'auto-scrolls to the latest update' do
        expect(page).to have_css('#logSpool > div', minimum: 1, visible: :all)

        initial_div_count = log_div_count
        expect(page).to have_css('#logSpool > div', minimum: initial_div_count + 1, visible: :all)

        new_div_count = log_div_count
        expect(new_div_count).to be > initial_div_count

        if is_scrollable?
          wait_for_scroll_to_bottom
          expect(is_scrolled_to_bottom?).to be true
        end
      end
    end

    context 'when not following' do
      it 'continues appending updates without auto-scrolling' do
        expect(page).to have_css('#logSpool > div', minimum: 1, visible: :all)

        follow_log_button = find('.btn-follow-log')
        follow_log_button.click
        expect(follow_log_button[:class]).not_to include('active')

        page.execute_script('document.getElementById("logSpool").scrollTop = 0')
        wait_for_scroll_to_top

        initial_div_count = log_div_count
        expect(page).to have_css('#logSpool > div', minimum: initial_div_count + 1, visible: :all)

        new_div_count = log_div_count
        expect(new_div_count).to be > initial_div_count

        if is_scrollable?
          initial_scroll_top = page.evaluate_script('document.getElementById("logSpool").scrollTop')
          wait_for_scroll_to_stabilize
          final_scroll_top = page.evaluate_script('document.getElementById("logSpool").scrollTop')

          expect((final_scroll_top - initial_scroll_top).abs).to be <= 5
        end
      end
    end
  end
end
