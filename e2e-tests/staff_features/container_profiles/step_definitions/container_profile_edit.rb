# frozen_string_literal: true

Given 'a Container Profile has been created' do
  visit "#{STAFF_URL}/container_profiles/new"

  fill_in 'container_profile_name_', with: "Container Profile #{@uuid}"
  fill_in 'container_profile_depth_', with: '1.1'
  fill_in 'container_profile_height_', with: '2.2'
  fill_in 'container_profile_width_', with: '3.3'

  click_on 'Save'
  expect(find('.alert.alert-success.with-hide-alert').text).to eq 'Container Profile Created'

  @container_profile_id = current_url.split('/').pop
end

Given 'the Container Profile appears in the search results list' do
  visit "#{STAFF_URL}/container_profiles"

  fill_in 'filter-text', with: @uuid

  within '.search-filter' do
    find('button').click
  end

  search_result_rows = all('#tabledSearchResults tbody tr')
  expect(search_result_rows.length).to eq 1
end

Then 'the Container Profile is opened in the edit mode' do
  url_parts = current_url.split('/')
  action = url_parts.pop
  container_profile_id = url_parts.pop

  expect(action).to eq 'edit'
  expect(container_profile_id).to eq @container_profile_id
end

Given 'the Container Profile is opened in the view mode' do
  visit "#{STAFF_URL}/container_profiles/#{@container_profile_id}"
end

Given 'the Container Profile is opened in edit mode' do
  visit "#{STAFF_URL}/container_profiles/#{@container_profile_id}/edit"
end

Then 'the Container Profile Name field has the original value' do
  visit "#{STAFF_URL}/container_profiles/#{@container_profile_id}/edit"

  expect(page).to have_field('Name', with: "Container Profile #{@uuid}")
end
