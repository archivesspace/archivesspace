# frozen_string_literal: true

Given 'the Location appears in the search results list' do
  visit "#{STAFF_URL}/locations"

  fill_in 'filter-text', with: @uuid

  within '.search-filter' do
    find('button').click
  end

  search_result_rows = all('#tabledSearchResults tbody tr')
  expect(search_result_rows.length).to eq 1
end

Then 'the Location is opened in the edit mode' do
  uri = current_url.split('/')

  action = uri.pop
  location_id = uri.pop

  expect(action).to eq 'edit'
  expect(location_id).to eq @location_id
end

Given 'the Location is opened in view mode' do
  visit "#{STAFF_URL}/locations/#{@location_id}"
end

Then 'the Location Building field has the original value' do
  visit "#{STAFF_URL}/locations/#{@location_id}/edit"

  expect(page).to have_field('Building', with: "Location Building #{@uuid}")
end

Given 'the Location is opened in edit mode' do
  visit "#{STAFF_URL}/locations/#{@location_id}/edit"
end
