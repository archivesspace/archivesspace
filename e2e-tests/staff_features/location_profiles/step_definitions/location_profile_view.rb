# frozen_string_literal: true

Given 'a Location Profile has been created' do
  visit "#{STAFF_URL}/location_profiles/new"

  fill_in 'location_profile_name_', with: "Test Location Profile #{@uuid}"
  fill_in 'location_profile_depth_', with: '10'
  fill_in 'location_profile_height_', with: '20'
  fill_in 'location_profile_width_', with: '30'

  find('button', text: 'Save Location Profile', match: :first).click

  expect(find('.alert.alert-success.with-hide-alert').text).to eq 'Location Profile Created'
  url_parts = current_url.split('/')
  @location_profile_id = url_parts.pop
end

Given 'two Location Profiles have been created with a common keyword in their title' do
  @shared_location_profile_uuid = SecureRandom.uuid
  @location_profile_a_uuid = SecureRandom.uuid
  @location_profile_b_uuid = SecureRandom.uuid

  visit "#{STAFF_URL}/location_profiles/new"

  fill_in 'location_profile_name_', with: "Test Location Profile A #{@location_profile_a_uuid} #{@shared_location_profile_uuid}"
  fill_in 'location_profile_depth_', with: '10'
  fill_in 'location_profile_height_', with: '20'
  fill_in 'location_profile_width_', with: '30'

  find('button', text: 'Save Location Profile', match: :first).click

  expect(find('.alert.alert-success.with-hide-alert').text).to eq 'Location Profile Created'
  url_parts = current_url.split('/')
  @location_profile_first_id = url_parts.pop

  visit "#{STAFF_URL}/location_profiles/new"

  fill_in 'location_profile_name_', with: "Test Location Profile B #{@location_profile_b_uuid} #{@shared_location_profile_uuid}"
  fill_in 'location_profile_depth_', with: '10'
  fill_in 'location_profile_height_', with: '20'
  fill_in 'location_profile_width_', with: '30'

  find('button', text: 'Save Location Profile', match: :first).click

  expect(find('.alert.alert-success.with-hide-alert').text).to eq 'Location Profile Created'
  url_parts = current_url.split('/')
  @location_profile_first_id = url_parts.pop
end

When 'the user filters by text with the Location Profile name' do
  fill_in 'Filter by text', with: @uuid

  find('#filter-text').send_keys(:enter)

  rows = []
  checks = 0

  while checks < 5
    checks += 1

    begin
      rows = all('tr', text: @uuid)
    rescue Selenium::WebDriver::Error::JavascriptError
      sleep 1
    end

    break if rows.length == 1
  end
end

Then 'the Location Profile is in the search results' do
  expect(page).to have_css('tr', text: @uuid)
end

Then 'the Location Profile view page is displayed' do
  expect(current_url).to eq "#{STAFF_URL}/location_profiles/#{@location_profile_id}"
end

Given 'the two Location Profiles are displayed sorted by ascending title' do
  visit "#{STAFF_URL}/location_profiles"

  fill_in 'filter-text', with: @shared_location_profile_uuid

  within '.search-filter' do
    find('button').click
  end

  search_result_rows = all('#tabledSearchResults tbody tr')

  expect(search_result_rows.length).to eq 2
  expect(search_result_rows[0]).to have_text @location_profile_a_uuid
  expect(search_result_rows[1]).to have_text @location_profile_b_uuid
end

Then 'the two Location Profiles are displayed sorted by descending title' do
  search_result_rows = all('#tabledSearchResults tbody tr')

  expect(search_result_rows.length).to eq 2
  expect(search_result_rows[1]).to have_text @location_profile_a_uuid
  expect(search_result_rows[0]).to have_text @location_profile_b_uuid
end

Given 'the two Location Profiles are displayed in the search results' do
  visit "#{STAFF_URL}/location_profiles"

  fill_in 'filter-text', with: @shared_location_profile_uuid

  within '.search-filter' do
    find('button').click
  end

  search_result_rows = all('#tabledSearchResults tbody tr')

  expect(search_result_rows.length).to eq 2
  expect(search_result_rows[0]).to have_text @location_profile_a_uuid
  expect(search_result_rows[1]).to have_text @location_profile_b_uuid
end

Then 'a CSV file is downloaded with the the two Location Profiles' do
  files = Dir.glob(File.join(Dir.tmpdir, '*.csv'))

  downloaded_file = nil
  files.each do |file|
    downloaded_file = file if file.include?('location profiles')
  end

  expect(downloaded_file).to_not eq nil

  load_file = File.read(downloaded_file)
  expect(load_file).to include @location_profile_a_uuid
  expect(load_file).to include @location_profile_b_uuid
  expect(load_file).to include "Test Location Profile A #{@location_profile_a_uuid}"
  expect(load_file).to include "Test Location Profile B #{@location_profile_b_uuid}"
end
