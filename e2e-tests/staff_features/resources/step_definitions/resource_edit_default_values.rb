# frozen_string_literal: true

Given 'the user is on the Resources page' do
  visit "#{STAFF_URL}/resources"
end

Then 'the Resource Record Defaults page is displayed' do
  expect(current_url).to include 'resources/defaults'
end

Given 'the user is on the Resource Record Default page' do
  visit "#{STAFF_URL}/resources/defaults"
  wait_for_ajax
end

Then 'the new Resource form has the following default values' do |form_values_table|
  visit "#{STAFF_URL}/resources/new"
  expect(page).to have_selector('h2', visible: true, text: 'Resource')

  expect_form_values(form_values_table)
end
