# frozen_string_literal: true

# Shared examples for verifying a log feed with auto-scroll control behavior.
#
# Prerequisites:
# - The `#logSpool` log container element is present

RSpec.shared_examples 'log feed with auto-scroll control' do
  let(:poll_interval) { 3 }

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
        sleep poll_interval

        initial_div_count = page.evaluate_script('document.getElementById("logSpool").children.length')
        scroll_height = page.evaluate_script('document.getElementById("logSpool").scrollHeight')
        client_height = page.evaluate_script('document.getElementById("logSpool").clientHeight')
        scroll_top = page.evaluate_script('document.getElementById("logSpool").scrollTop')

        expect(scroll_top).to be_within(50).of(scroll_height - client_height)

        sleep poll_interval

        new_div_count = page.evaluate_script('document.getElementById("logSpool").children.length')
        new_scroll_height = page.evaluate_script('document.getElementById("logSpool").scrollHeight')
        new_client_height = page.evaluate_script('document.getElementById("logSpool").clientHeight')
        new_scroll_top = page.evaluate_script('document.getElementById("logSpool").scrollTop')

        expect(new_div_count).to be > initial_div_count
        expect(new_scroll_top).to be_within(50).of(new_scroll_height - new_client_height)
      end
    end

    context 'when not following' do
      it 'continues appending updates without scrolling' do
        sleep poll_interval

        follow_log_button = find('.btn-follow-log')
        follow_log_button.click
        expect(follow_log_button[:class]).not_to include('active')

        page.execute_script('document.getElementById("logSpool").scrollTop = 0')
        expect(page.evaluate_script('document.getElementById("logSpool").scrollTop')).to eq(0)

        initial_div_count = page.evaluate_script('document.getElementById("logSpool").children.length')

        sleep poll_interval

        new_div_count = page.evaluate_script('document.getElementById("logSpool").children.length')
        scroll_top = page.evaluate_script('document.getElementById("logSpool").scrollTop')

        expect(new_div_count).to be > initial_div_count
        expect(scroll_top).to eq(0)
      end
    end
  end
end
