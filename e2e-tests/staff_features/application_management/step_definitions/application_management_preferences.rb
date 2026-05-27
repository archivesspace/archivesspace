# frozen_string_literal: true

Given 'the user clicks on {string} in the User Menu Dropdown' do |string|
  find('#user-menu-dropdown').click
  within '.dropdown-menu'
  click_on string
end

Given 'the user updates the Accession Browse Column 6 to Acquisition Type' do
  select 'Acquisition Type', from: 'preference_defaults__accession_browse_column_6_'
  click_on 'Save'
end

Given 'Acquisition Type is included as a column on the Accessions Browse page' do
  visit "#{STAFF_URL}/accessions"
  expect(page).to have_css('thead tr th', text: 'Acquisition Type')
end
