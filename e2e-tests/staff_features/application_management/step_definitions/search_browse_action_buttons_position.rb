# frozen_string_literal: true

ACCESSION_ACTIONS_POSITION_SELECT = 'preference_defaults__accession_actions_column_position_'

# Restore the preference changed by the "changes the Accession Action Buttons
# (View/Edit) Position" step so other features see the default
After('@action_buttons_position_preference') do
  next unless @action_buttons_position_preferences_url

  visit @action_buttons_position_preferences_url
  find("##{ACCESSION_ACTIONS_POSITION_SELECT} option[value='']").select_option
  find('button[type="submit"]', text: 'Save', match: :first).click
end

When 'the user performs a search' do
  find('#global-search-button').click
  expect(page).to have_css('#tabledSearchResults tbody tr')
end

When 'the user changes the Accession Action Buttons \(View\/Edit\) Position to Right' do
  @action_buttons_position_preferences_url = current_url
  select 'Right', from: ACCESSION_ACTIONS_POSITION_SELECT
end

def expect_action_buttons_column(selector)
  expect(page).to have_css("#tabledSearchResults thead tr > #{selector.gsub('CELL', 'th')}")
  expect(page).to have_css("#tabledSearchResults tbody tr:first-child > #{selector.gsub('CELL', 'td')}")
end

Then 'the View\/Edit buttons column is the first column of the results table' do
  expect_action_buttons_column('CELL.table-record-actions:first-child')
end

Then 'the View\/Edit buttons column is just to the right of the checkboxes in the results table' do
  expect_action_buttons_column('CELL.multiselect-column:first-child + CELL.table-record-actions')
end

Then 'the View\/Edit buttons column is the last column of the results table' do
  expect_action_buttons_column('CELL.table-record-actions:last-child')
end
