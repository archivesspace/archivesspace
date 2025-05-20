# frozen_string_literal: true

Given 'the New Location page is displayed' do
  visit "#{STAFF_URL}/locations/new"
end

Given 'the New Batch Location page is displayed' do
  visit "#{STAFF_URL}/locations/batch"
end

When 'the user fills in Coordinate Range 1 Label with {string}' do |value|
  fill_in 'location_batch_coordinate_1_range__label_', with: value
end

When 'the user fills in Coordinate Range 1 Range Start with {string}' do |value|
  fill_in 'location_batch_coordinate_1_range__start_', with: value
end

When 'the user fills in Coordinate Range 1 Range End with {string}' do |value|
  fill_in 'location_batch_coordinate_1_range__end_', with: value
end

Then 'the Preview Locations modal with the number of Locations is displayed' do
  expect(page).to have_css '#batchPreviewModal'
end
