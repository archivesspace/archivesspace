# frozen_string_literal: true

# Shared helpers and examples for verifying is_primary behavior on linked agents.
# NOTE: These examples DO NOT create records. The spec file must define:
# - let(:record_type) { 'accession' | 'resource' | 'digital_object' | 'archival_object' | 'digital_object_component' | 'event' }
# - let(:record) { create(:...) } with any linked_agents/rights_statements as needed
# - let(:edit_path) { "/.../#{record.id}/edit" or the appropriate tree anchor }

RSpec.shared_context 'linked agents is_primary helpers' do
  def top_level_linked_agents_section(record_type)
    "section##{record_type}_linked_agents_"
  end

  def top_level_linked_agents_first_li(record_type)
    "#{top_level_linked_agents_section(record_type)} .subrecord-form-list > li[data-index='0']"
  end

  def rights_statement_linked_agents_section(record_type, index = 0)
    "##{record_type}_rights_statements__#{index}__linked_agents_"
  end

  def is_primary_hidden_selector
    "input[type='hidden'][name$='[is_primary]']"
  end

  def make_primary_btn_selector
    'button.is-representative-toggle'
  end

  def primary_btn_selector
    'button.is-representative-label'
  end
end

RSpec.shared_examples 'supports is_primary on top-level linked agents' do
  include_context 'linked agents is_primary helpers'

  it 'marks primary and persists the state' do
    visit edit_path

    within top_level_linked_agents_first_li(record_type) do
      expect(page).to have_css(make_primary_btn_selector, text: 'Make Primary')
      expect(find(is_primary_hidden_selector, visible: false).value).to eq('0')

      find(make_primary_btn_selector, match: :first).click
      expect(find(is_primary_hidden_selector, visible: false).value).to eq('1')
    end

    find('button', text: 'Save', match: :first).click
    expect(page).to have_css('.alert.alert-success.with-hide-alert')
    within top_level_linked_agents_first_li(record_type) do
      expect(page).to have_button('Primary')
      expect(find(is_primary_hidden_selector, visible: false).value).to eq('1')
    end
  end
end

RSpec.shared_examples 'disallows is_primary on rights statement linked agents' do
  include_context 'linked agents is_primary helpers'

  it 'does not show primary UI in rights statement linked agents' do
    visit edit_path
    within rights_statement_linked_agents_section(record_type) do
      expect(page).to have_no_css(make_primary_btn_selector, visible: :all)
      expect(page).to have_no_css(primary_btn_selector, visible: :all)
      expect(page).to have_no_css(is_primary_hidden_selector, visible: :all)
    end
  end
end

RSpec.shared_examples 'disallows is_primary on top-level linked agents' do
  include_context 'linked agents is_primary helpers'

  it 'does not show primary UI for top-level linked agents' do
    visit edit_path
    # If a pre-created linked agent exists, the selector will match. Otherwise, this will no-op.
    if page.has_css?(top_level_linked_agents_first_li(record_type))
      within top_level_linked_agents_first_li(record_type) do
        expect(page).to have_no_css(make_primary_btn_selector, visible: :all)
        expect(page).to have_no_css(primary_btn_selector, visible: :all)
        expect(page).to have_no_css(is_primary_hidden_selector, visible: :all)
      end
    else
      # Fallback: ensure the section itself has no primary UI
      within top_level_linked_agents_section(record_type) do
        expect(page).to have_no_css(make_primary_btn_selector, visible: :all)
        expect(page).to have_no_css(primary_btn_selector, visible: :all)
        expect(page).to have_no_css(is_primary_hidden_selector, visible: :all)
      end
    end
  end
end
