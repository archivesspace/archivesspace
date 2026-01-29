# frozen_string_literal: true

Given 'the user is on the Component Record Default page' do
  visit "#{STAFF_URL}/archival_objects/defaults"
end

Then 'the Component Record Defaults page is displayed' do
  expect(current_url).to include '/archival_objects/defaults'
end

Then 'the new Resource Component form has the following default values' do |form_values_table|
  visit "#{STAFF_URL}/resources/#{@resource_id}/edit"
  expect(page).to have_selector('h2', visible: true, text: 'Resource')
  wait_for_ajax

  click_on 'Add Child'

  expect(page).to have_selector('h2', visible: true, text: 'Archival Object')

  expect_form_values(form_values_table)
end
