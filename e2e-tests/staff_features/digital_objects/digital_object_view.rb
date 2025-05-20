# frozen_string_literal: true

Given 'two Digital Objects have been created with a common keyword in their title' do
  @shared_digital_object_uuid = SecureRandom.uuid
  @digital_object_a_uuid = SecureRandom.uuid
  @digital_object_b_uuid = SecureRandom.uuid

  visit "#{STAFF_URL}/digital_objects/new"
  fill_in 'digital_object_title_', with: "Digital Object A #{@digital_object_a_uuid} #{@shared_digital_object_uuid}"
  fill_in 'digital_object_digital_object_id_', with: "Digital Object A #{@digital_object_a_uuid}"
  click_on 'Save'

  visit "#{STAFF_URL}/digital_objects/new"
  fill_in 'digital_object_title_', with: "Digital Object B #{@digital_object_b_uuid} #{@shared_digital_object_uuid}"
  fill_in 'digital_object_digital_object_id_', with: "Digital Object B #{@digital_object_b_uuid}"
  click_on 'Save'
end

Given 'the two Digital Objects are displayed sorted by ascending title' do
  visit "#{STAFF_URL}/digital_objects"

  fill_in 'filter-text', with: @shared_digital_object_uuid

  within '.search-filter' do
    find('button').click
  end

  search_result_rows = all('#tabledSearchResults tbody tr')

  expect(search_result_rows.length).to eq 2
  expect(search_result_rows[0]).to have_text @digital_object_a_uuid
  expect(search_result_rows[1]).to have_text @digital_object_b_uuid
end

Then 'the two Digital Objects are displayed sorted by descending title' do
  search_result_rows = all('#tabledSearchResults tbody tr')

  expect(search_result_rows.length).to eq 2
  expect(search_result_rows[1]).to have_text @digital_object_a_uuid
  expect(search_result_rows[0]).to have_text @digital_object_b_uuid
end

Then 'the Digital Object is in the search results' do
  expect(page).to have_css('tr', text: @uuid)
end

Then 'the Digital Object view page is displayed' do
  expect(find('h2').text).to eq "Digital Object Title #{@uuid} Digital Object"
end

Then 'the two Digital Objects are displayed sorted by ascending Digital Object ID' do
  search_result_rows = all('#tabledSearchResults tbody tr')

  expect(search_result_rows.length).to eq 2
  expect(search_result_rows[0]).to have_text @digital_object_a_uuid
  expect(search_result_rows[1]).to have_text @digital_object_b_uuid
end

Given 'the two Digital Objects are displayed in the search results' do
  visit "#{STAFF_URL}/digital_objects"

  fill_in 'filter-text', with: @shared_digital_object_uuid

  within '.search-filter' do
    find('button').click
  end

  search_result_rows = all('#tabledSearchResults tbody tr')

  expect(search_result_rows.length).to eq 2
  expect(search_result_rows[0]).to have_text @digital_object_a_uuid
  expect(search_result_rows[1]).to have_text @digital_object_b_uuid
end

Then 'a CSV file is downloaded with the the two Digital Objects' do
  files = Dir.glob(File.join(Dir.tmpdir, '*.csv'))

  downloaded_file = nil
  files.each do |file|
    downloaded_file = file if file.include?('digital objects')
  end

  expect(downloaded_file).to_not eq nil

  load_file = File.read(downloaded_file)
  expect(load_file).to include @digital_object_a_uuid
  expect(load_file).to include @digital_object_b_uuid
  expect(load_file).to include "Digital Object A #{@digital_object_a_uuid}"
  expect(load_file).to include "Digital Object B #{@digital_object_b_uuid}"
end
