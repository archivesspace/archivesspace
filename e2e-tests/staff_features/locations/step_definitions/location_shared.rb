# frozen_string_literal: true

Given 'a Location has been created' do
  visit "#{STAFF_URL}/locations/new"

  fill_in 'location_building_', with: "Location Building #{@uuid}"
  fill_in 'location_barcode_', with: @uuid

  find('button', text: 'Save Location', match: :first).click

  uri_parts = current_url.split('/')
  uri_parts.pop
  @location_id = uri_parts.pop
end

When 'the user filters by text with the Location building' do
  fill_in 'Filter by text', with: "Location Building #{@uuid}"

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

Given 'the Location view page is displayed' do
  visit "#{STAFF_URL}/locations/#{@location_id}"
end

Given 'two Locations have been created with a common keyword in their building' do
  @shared_location_uuid = SecureRandom.uuid
  @location_a_uuid = SecureRandom.uuid
  @location_b_uuid = SecureRandom.uuid

  visit "#{STAFF_URL}/locations/new"

  fill_in 'location_building_', with: "Location Building A #{@location_a_uuid} #{@shared_location_uuid}"
  fill_in 'location_barcode_', with: @location_a_uuid
  fill_in 'location_floor_', with: '1'
  fill_in 'location_room_', with: '11'
  fill_in 'location_area_', with: '111'

  find('button', text: 'Save Location', match: :first).click

  uri_parts = current_url.split('/')
  uri_parts.pop
  @location_first_id = uri_parts.pop

  visit "#{STAFF_URL}/locations/new"

  fill_in 'location_building_', with: "Location Building B #{@location_b_uuid} #{@shared_location_uuid}"
  fill_in 'location_barcode_', with: @location_b_uuid
  fill_in 'location_floor_', with: '2'
  fill_in 'location_room_', with: '22'
  fill_in 'location_area_', with: '222'

  find('button', text: 'Save Location', match: :first).click

  uri_parts = current_url.split('/')
  uri_parts.pop
  @location_second_id = uri_parts.pop
end

Given 'the two Locations are displayed sorted by ascending building' do
  visit "#{STAFF_URL}/locations"

  fill_in 'filter-text', with: @shared_location_uuid

  within '.search-filter' do
    find('button').click
  end

  search_result_rows = all('#tabledSearchResults tbody tr')

  expect(search_result_rows.length).to eq 2
  expect(search_result_rows[0]).to have_text @location_a_uuid
  expect(search_result_rows[1]).to have_text @location_b_uuid
end

Then 'the Location is in the search results' do
  expect(page).to have_css('tr', text: @uuid)
end

Then 'the two Locations are displayed sorted by descending building' do
  search_result_rows = all('#tabledSearchResults tbody tr')

  expect(search_result_rows.length).to eq 2
  expect(search_result_rows[1]).to have_text @location_a_uuid
  expect(search_result_rows[0]).to have_text @location_b_uuid
end

Then 'the two Locations are displayed sorted by ascending floor' do
  search_result_rows = all('#tabledSearchResults tbody tr')

  expect(search_result_rows.length).to eq 2
  expect(search_result_rows[0]).to have_text @location_a_uuid
  expect(search_result_rows[1]).to have_text @location_b_uuid
end

Then 'the two Locations are displayed sorted by ascending area' do
  search_result_rows = all('#tabledSearchResults tbody tr')

  expect(search_result_rows.length).to eq 2
  expect(search_result_rows[0]).to have_text @location_a_uuid
  expect(search_result_rows[1]).to have_text @location_b_uuid
end

Then 'the two Locations are displayed sorted by ascending room' do
  search_result_rows = all('#tabledSearchResults tbody tr')

  expect(search_result_rows.length).to eq 2
  expect(search_result_rows[0]).to have_text @location_a_uuid
  expect(search_result_rows[1]).to have_text @location_b_uuid
end
