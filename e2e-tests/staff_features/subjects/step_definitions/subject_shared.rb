# frozen_string_literal: true

Given 'the user is on the New Subject page' do
  visit "#{STAFF_URL}/subjects/new"

  wait_for_ajax
end

Given 'the user is on the Subjects page' do
  visit "#{STAFF_URL}/subjects"
end

Then 'the new Subject form has the following default values' do |form_values_table|
  visit "#{STAFF_URL}/subjects/new"
  expect(page).to have_selector('h2', visible: true, text: 'Subject')

  expect_form_values(form_values_table)
end
