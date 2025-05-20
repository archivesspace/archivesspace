# frozen_string_literal: true

When 'the user checks the checkbox of the Digital Object' do
  find('#multiselect-item').check
end

Then 'the Digital Object is deleted' do
  expect(@digital_object_id).to_not eq nil

  visit "#{STAFF_URL}/digital_objects/#{@digital_object_id}/edit"

  expect(find('h2').text).to eq 'Record Not Found'

  expected_text = "The record you've tried to access may no longer exist or you may not have permission to view it."
  expect(page).to have_text expected_text
end
