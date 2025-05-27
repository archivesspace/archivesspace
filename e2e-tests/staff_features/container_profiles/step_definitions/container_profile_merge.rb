# frozen_string_literal: true

Given 'two Container Profiles A & B have been created' do
  @shared_container_profile_uuid = SecureRandom.uuid
  @container_profile_a_uuid = SecureRandom.uuid
  @container_profile_b_uuid = SecureRandom.uuid

  visit "#{STAFF_URL}/container_profiles/new"
  fill_in 'container_profile_name_', with: "Container Profile A #{@shared_container_profile_uuid} #{@container_profile_a_uuid}"
  fill_in 'container_profile_depth_', with: '1.1'
  fill_in 'container_profile_height_', with: '2.2'
  fill_in 'container_profile_width_', with: '3.3'
  click_on 'Save'
  expect(find('.alert.alert-success.with-hide-alert').text).to eq 'Container Profile Created'
  url_parts = current_url.split('container_profiles/container_profile_person').pop.split('/')
  @container_profile_a_id = url_parts.pop

  visit "#{STAFF_URL}/container_profiles/new"
  fill_in 'container_profile_name_', with: "Container Profile B #{@shared_container_profile_uuid} #{@container_profile_b_uuid}"
  fill_in 'container_profile_depth_', with: '1.1'
  fill_in 'container_profile_height_', with: '2.2'
  fill_in 'container_profile_width_', with: '3.3'
  click_on 'Save'
  expect(find('.alert.alert-success.with-hide-alert').text).to eq 'Container Profile Created'
  url_parts = current_url.split('container_profiles/container_profile_person').pop.split('/')
  @container_profile_b_id = url_parts.pop
end

Given 'the two Container Profiles are displayed in the search results' do
  visit "#{STAFF_URL}/container_profiles"

  fill_in 'filter-text', with: @shared_container_profile_uuid

  within '.search-filter' do
    find('button').click
  end

  search_result_rows = all('#tabledSearchResults tbody tr')

  expect(search_result_rows.length).to eq 2
  expect(search_result_rows[0]).to have_text @container_profile_a_uuid
  expect(search_result_rows[1]).to have_text @container_profile_b_uuid
end

When 'the two Container Profiles A & B are selected' do
  find('#select_all').click
end

When 'the user selects the Container Profile B in the Merge Container Profiles modal' do
  find(:css, "[id=\"/container_profiles/#{@container_profile_b_id}\"]").click
end

When 'the user clicks on {string} in the Confirm Merge Container Profiles modal' do |string|
  within '#bulkMergeConfirmModal' do
    click_on string
  end
end

Then 'the Container Profile B view page is displayed' do
  expect(current_url).to eq "#{STAFF_URL}/container_profiles/#{@container_profile_b_id}"
end

Then 'the Container Profile A is deleted' do
  visit "#{STAFF_URL}/container_profiles/#{@container_profile_a_id}"

  expect(find('h2').text).to eq 'Record Not Found'

  expected_text = "The record you've tried to access may no longer exist or you may not have permission to view it."
  expect(page).to have_text expected_text
end
