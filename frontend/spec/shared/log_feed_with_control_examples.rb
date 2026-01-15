# frozen_string_literal: true

require 'timeout'

# Shared examples for verifying a log feed with auto-scroll control behavior.
#
# Prerequisites:
# - The `#logSpool` log container element is present

RSpec.shared_examples 'log feed with auto-scroll control' do
  let(:poll_interval) { 3 }
  let(:require_log_growth) { true }
  let(:stop_log_spool_animations) { false }
  let(:wait_for_scroll_after_update) { false }

  def log_div_count
    page.evaluate_script('document.getElementById("logSpool").children.length')
  end

  def wait_for_log_divs(min_count)
    Capybara.using_wait_time(Capybara.default_max_wait_time) do
      expect(page).to have_css('#logSpool > div', minimum: min_count, visible: :all)
    end
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

    context 'when set to active' do
    end
  end

  describe 'log feed' do
    context 'when actively following' do
      it 'auto-scrolls to the latest update' do
        wait_for_log_divs(1)
        wait_for_scroll_to_bottom

        initial_div_count = log_div_count

        wait_for_log_divs(initial_div_count + 1) if require_log_growth
        wait_for_scroll_to_bottom if wait_for_scroll_after_update
        new_div_count = log_div_count

        expect(new_div_count).to be > initial_div_count if require_log_growth
      end
    end

    context 'when not following' do
      it 'continues appending updates without scrolling' do
        wait_for_log_divs(1)

        follow_log_button = find('.btn-follow-log')
        follow_log_button.click
        expect(follow_log_button[:class]).not_to include('active')

        if stop_log_spool_animations
          page.execute_script('$("#logSpool").stop(true, true)')
        end
        page.execute_script('document.getElementById("logSpool").scrollTop = 0')
        wait_for_scroll_to_top

        initial_div_count = log_div_count
        wait_for_log_divs(initial_div_count + 1) if require_log_growth
        new_div_count = log_div_count

        expect(new_div_count).to be > initial_div_count if require_log_growth
        wait_for_scroll_to_top if wait_for_scroll_after_update
      end
    end
  end
end
