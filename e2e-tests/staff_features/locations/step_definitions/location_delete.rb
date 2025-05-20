# frozen_string_literal: true

When 'the user checks the checkbox of the Location' do
  find('#multiselect-item').check
end

Then 'the Location is deleted' do
  visit "#{STAFF_URL}/locations/#{@location_id}/edit"

  expect(find('h2').text).to eq 'Record Not Found'

  expected_text = "The record you've tried to access may no longer exist or you may not have permission to view it."
  expect(page).to have_text expected_text
end

Then 'the user is still on the Location view page' do
  expect(current_url).to eq "#{STAFF_URL}/locations/#{@location_id}"
end

Then 'the user is on the Locations page' do
  expect(current_url).to include "#{STAFF_URL}/locations"
end
