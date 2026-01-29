# frozen_string_literal: true

Then 'the new Digital Object form has the following default values' do |form_values_table|
  visit "#{STAFF_URL}/digital_objects/new"

  expect(page).to have_selector('h2', visible: true, text: 'Digital Object')

  expect_form_values(form_values_table)
end

Then 'the new Digital Object Component form has the following default values' do |form_values_table|
  visit "#{STAFF_URL}/digital_objects/#{@digital_object_id}/edit"

  expect(page).to have_selector('h2', visible: true, text: 'Digital Object')

  click_on 'Add Child'

  expect(page).to have_selector('h2', visible: true, text: 'Digital Object Component')

  expect_form_values(form_values_table)
end
