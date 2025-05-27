# frozen_string_literal: true

When 'the user checks the checkbox of the Assessment' do
  find('#multiselect-item').check
end

Then 'the Assessment is deleted' do
  expect(@assessment_id).to_not eq nil

  visit "#{STAFF_URL}/assessments/#{@assessment_id}/edit"

  expect(find('h2').text).to eq 'Record Not Found'

  expected_text = "The record you've tried to access may no longer exist or you may not have permission to view it."
  expect(page).to have_text expected_text
end

Given 'the user is on the Assessment view page' do
  visit "#{STAFF_URL}/assessments/#{@assessment_id}"
end

Then 'the Assessments page is displayed' do
  expect(current_url).to include "#{STAFF_URL}/assessments"
end

Then 'the user is still on the Assessment view page' do
  expect(current_url).to eq "#{STAFF_URL}/assessments/#{@assessment_id}"
end
