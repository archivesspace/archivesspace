# frozen_string_literal: true

Given 'the user is on the New Resource page' do
  visit "#{STAFF_URL}/resources/new"
end

Then 'the Resource form has the following values' do |form_values_table|
  expect_form_values(form_values_table)
end
