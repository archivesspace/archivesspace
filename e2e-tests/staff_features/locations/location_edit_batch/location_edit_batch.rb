# frozen_string_literal: true

Given 'two Locations A & B have been created' do
  @shared_location_uuid = SecureRandom.uuid
  @location_a_uuid = SecureRandom.uuid
  @location_b_uuid = SecureRandom.uuid

  visit "#{STAFF_URL}/locations/new"

  fill_in 'location_building_', with: "Location Building A #{@location_a_uuid} #{@shared_location_uuid}"
  fill_in 'location_barcode_', with: @location_a_uuid

  find('button', text: 'Save Location', match: :first).click

  uri_parts = current_url.split('/')
  uri_parts.pop
  @location_first_id = uri_parts.pop

  visit "#{STAFF_URL}/locations/new"

  fill_in 'location_building_', with: "Location Building B #{@location_b_uuid} #{@shared_location_uuid}"
  fill_in 'location_barcode_', with: @location_a_uuid

  find('button', text: 'Save Location', match: :first).click

  uri_parts = current_url.split('/')
  uri_parts.pop
  @location_second_id = uri_parts.pop
end

Given 'the two Locations are displayed in the search results' do
  visit "#{STAFF_URL}/locations"

  fill_in 'filter-text', with: @shared_location_uuid

  within '.search-filter' do
    find('button').click
  end

  search_result_rows = all('#tabledSearchResults tbody tr')

  expect(search_result_rows.length).to eq 2
end

When 'the user checks Location A and Location B' do
  find('#select_all').click
end

Then 'the two Locations have the following values' do |form_values_table|
  visit "#{STAFF_URL}/locations/#{@location_first_id}/edit"

  form_values = form_values_table.hashes

  form_values.each do |row|
    field = find_field(row['form_field'])

    expect(field.value.downcase).to eq row['form_value'].downcase
  end

  visit "#{STAFF_URL}/locations/#{@location_second_id}/edit"

  form_values = form_values_table.hashes

  form_values.each do |row|
    field = find_field(row['form_field'])

    expect(field.value.downcase).to eq row['form_value'].downcase
  end
end
