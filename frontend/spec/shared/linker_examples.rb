# frozen_string_literal: true

# These variables should be defined in the calling spec:
# - let(:linked_record) - the linked record object
#
# Optional:
# - let(:linker_token_selector) - the selector for the linked record token in the
#   linker. Default is "#{linker_container_selector} .token-input-token" (falling
#   back to "#{linker_wrapper_selector} .token-input-token" if no
#   linker_container_selector is defined). Override for linkers that need a more
#   specific selector.
# - let(:linked_record_label) - The default is linked_record['title'], which most
#   record types populate on their resolved/rendered JSON. Override for  types that
#   render a different field instead (e.g. container profiles use 'name' and top
#   containers use 'display_string')
# - let(:readonly_linked_record_path) - Default is "#{linked_record['jsonmodel_type']}s/#{linked_record.id}",
#   which is used for most record types. Override for special-cases (e.g. agents
#   resolve to "agents/#{agent_type}/#{id}" rather than "#{agent_type}s/#{id}")
RSpec.shared_examples 'a token that opens its linked record in a new tab' do
  it 'opens the readonly view of the linked record in a new browser tab' do
    token_selector = if respond_to?(:linker_token_selector)
                       linker_token_selector
                     elsif respond_to?(:linker_container_selector)
                       "#{linker_container_selector} .token-input-token"
                     else
                       "#{linker_wrapper_selector} .token-input-token"
                     end
    path = if respond_to?(:readonly_linked_record_path)
             readonly_linked_record_path
           else
             "#{linked_record['jsonmodel_type']}s/#{linked_record.id}"
           end
    label = respond_to?(:linked_record_label) ? linked_record_label : linked_record['title']

    aggregate_failures 'starting out not on the linked record page' do
      expect(current_path).not_to match(path)
    end

    aggregate_failures 'clicking the linked record token opens its readonly view in a new browser tab' do
      expect(page).to have_css(token_selector, text: label)
      find(token_selector).click

      expect(page.windows.size).to eq 2
      switch_to_window(page.windows[1])

      expect(page).to have_css('.record-pane h2', text: label)
      expect(current_path).to match(path)
    end

    aggregate_failures 'resetting the browser' do
      page.current_window.close
      switch_to_window(page.windows[0])
      expect(page.windows.size).to eq 1
      expect(current_path).not_to match(path)
    end
  end
end
