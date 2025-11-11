# frozen_string_literal: true

# These variables should be defined in the calling spec:
# - let(:linked_record) - the linked record object
# - let(:linker_token_selector) - the selector for the linked record token in the linker
RSpec.shared_examples 'having a popover to view the linked record' do
  it 'opens the readonly view of the linked record in a new browser tab' do
    readonly_linked_record_path = "#{linked_record['jsonmodel_type']}s/#{linked_record['id']}"

    aggregate_failures 'starting out not on the linked record page' do
      expect(current_path).not_to match(readonly_linked_record_path)
    end

    aggregate_failures 'popover is shown by clicking the linked record token' do
      expect(page).to have_css(linker_token_selector, text: linked_record['title'])
      expect(page).not_to have_css('body > .popover:last-child', visible: :all)
      find(linker_token_selector).click
      expect(page).to have_css('body > .popover:last-child', text: 'View', visible: true)
    end

    aggregate_failures 'clicking the popover link opens the linked record in a new browser tab' do
      within 'body > .popover:last-child' do
        click_on 'View'
      end

      expect(page.windows.size).to eq 2
      switch_to_window(page.windows[1])

      expect(page).to have_css('.record-pane h2', text: linked_record['title'])
      expect(current_path).to match(readonly_linked_record_path)
    end

    aggregate_failures 'resetting the browser' do
      page.current_window.close
      switch_to_window(page.windows[0])
      expect(page.windows.size).to eq 1
      expect(current_path).not_to match(readonly_linked_record_path)
    end
  end
end
