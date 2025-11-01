# frozen_string_literal: true

# Shared helpers and examples for verifying is_primary behavior on linked agents.

# Requires:
# - let(:record_type) - 'accession', etc.
RSpec.shared_context 'linked agents is_primary helpers' do
  let(:top_level_linked_agents_section) { "section##{record_type}_linked_agents_" }
  let(:top_level_linked_agents_first_li) { "#{top_level_linked_agents_section} .subrecord-form-list > li[data-index='0']" }
  let(:rights_statement_linked_agents_section) { "##{record_type}_rights_statements__0__linked_agents_" }
  let(:is_primary_hidden_selector) { "input[type='hidden'][name$='[is_primary]']" }
  let(:make_primary_btn_selector) { 'button.is-representative-toggle' }
  let(:primary_btn_selector) { 'button.is-representative-label' }
  let(:save_button_selector) { 'button[type="submit"]' }
end

# Requires:
# - let(:record_type) - 'accession', etc.
# - let(:edit_path) - the edit path for the record
RSpec.shared_examples 'supporting is_primary on top-level linked agents' do
  include_context 'linked agents is_primary helpers'

  it 'marks an agent primary and persists the state' do
    visit edit_path

    within top_level_linked_agents_first_li do
      expect(page).to have_css(make_primary_btn_selector, text: 'Make Primary', visible: true)
      expect(page).to have_css(primary_btn_selector, text: 'Primary', visible: false)
      expect(page).to have_css("#{is_primary_hidden_selector}[value='0']", visible: false)

      find(make_primary_btn_selector).click
      expect(page).to have_css(primary_btn_selector, text: 'Primary', visible: true)
      expect(page).to have_css(make_primary_btn_selector, text: 'Make Primary', visible: false)
      expect(page).to have_css("#{is_primary_hidden_selector}[value='1']", visible: false)
    end

    find('button', text: 'Save', match: :first).click
    expect(page).to have_css('.alert.alert-success.with-hide-alert')
    within top_level_linked_agents_first_li do
      expect(page).to have_css(primary_btn_selector, text: 'Primary', visible: true)
      expect(page).to have_css(make_primary_btn_selector, text: 'Make Primary', visible: false)
      expect(page).to have_css("#{is_primary_hidden_selector}[value='1']", visible: false)
    end
  end

  it 'unmarks an agent primary and persists the state' do
    visit edit_path

    within top_level_linked_agents_first_li do
      expect(page).to have_css(make_primary_btn_selector, text: 'Make Primary', visible: true)
      find(make_primary_btn_selector).click
    end

    find(save_button_selector, match: :first).click
    expect(page).to have_css('.alert.alert-success.with-hide-alert')
    within top_level_linked_agents_first_li do
      expect(page).to have_css(primary_btn_selector, text: 'Primary', visible: true)
      find(primary_btn_selector).click
    end

    find(save_button_selector, match: :first).click
    expect(page).to have_css('.alert.alert-success.with-hide-alert')
    within top_level_linked_agents_first_li do
      expect(page).to have_css(make_primary_btn_selector, text: 'Make Primary', visible: true)
      expect(page).to have_css(primary_btn_selector, text: 'Primary', visible: false)
      expect(page).to have_css("#{is_primary_hidden_selector}[value='0']", visible: false)
    end
  end
end

# Requires:
# - let(:record_type) - 'accession', etc.
# - let(:edit_path) - the edit path for the record
RSpec.shared_examples 'not supporting is_primary on top-level linked agents' do
  include_context 'linked agents is_primary helpers'

  it 'does not show is_primary UI for top-level linked agents' do
    visit edit_path
    within top_level_linked_agents_section do
      expect(page).to have_no_css(make_primary_btn_selector, visible: :all)
      expect(page).to have_no_css(primary_btn_selector, visible: :all)
      expect(page).to have_no_css(is_primary_hidden_selector, visible: :all)
    end
  end
end

# Requires:
# - let(:record_type) - 'accession', etc.
# - let(:edit_path) - the edit path for the record
RSpec.shared_examples 'not supporting is_primary on rights statement linked agents' do
  include_context 'linked agents is_primary helpers'

  it 'does not show is_primary UI for rights statement linked agents' do
    visit edit_path
    within rights_statement_linked_agents_section do
      expect(page).to have_no_css(make_primary_btn_selector, visible: :all)
      expect(page).to have_no_css(primary_btn_selector, visible: :all)
      expect(page).to have_no_css(is_primary_hidden_selector, visible: :all)
    end
  end
end
