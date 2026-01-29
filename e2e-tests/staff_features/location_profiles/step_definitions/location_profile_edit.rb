# frozen_string_literal: true

Given 'the Location Profile appears in the search results list' do
  visit "#{STAFF_URL}/location_profiles"

  fill_in 'filter-text', with: @uuid

  within '.search-filter' do
    find('button').click
  end

  search_result_rows = all('#tabledSearchResults tbody tr')
  expect(search_result_rows.length).to eq 1
end

Then 'the Location Profile is opened in the edit mode' do
  uri = current_url.split('/')

  action = uri.pop
  location_profile_id = uri.pop

  expect(action).to eq 'edit'
  expect(location_profile_id).to eq @location_profile_id
end

Given 'the Location Profile is opened in view mode' do
  visit "#{STAFF_URL}/location_profiles/#{@location_profile_id}"
end

Given 'the Location Profile is opened in edit mode' do
  visit "#{STAFF_URL}/location_profiles/#{@location_profile_id}/edit"
end

Then 'the Location Profile Name field has the original value' do
  visit "#{STAFF_URL}/location_profiles/#{@location_profile_id}/edit"

  expect(page).to have_field('Name', with: "Test Location Profile #{@uuid}")
end
