# frozen_string_literal: true

Given 'two Resources have been created with a common keyword in their title' do
  @shared_resource_uuid = SecureRandom.uuid
  @resource_a_uuid = SecureRandom.uuid
  @resource_b_uuid = SecureRandom.uuid

  visit "#{STAFF_URL}/resources/new"
  fill_in 'resource_title_', with: "Resource A #{@resource_a_uuid} #{@shared_resource_uuid}"
  fill_in 'resource_id_0_', with: "Resource A #{@resource_a_uuid}"
  select 'Class', from: 'Level of Description'
  fill_in 'Language', with: 'English'
  dropdown_items = all('.typeahead.typeahead-long.dropdown-menu')
  dropdown_items.first.click
  fill_in 'Script', with: 'adlam'
  dropdown_items = all('.typeahead.typeahead-long.dropdown-menu')
  dropdown_items.first.click
  select 'Single', from: 'resource_dates__0__date_type_'
  fill_in 'resource_dates__0__begin_', with: '2000-01-01'
  fill_in 'Number', with: @uuid
  select 'Cassettes', from: 'resource_extents__0__extent_type_'
  fill_in 'resource_finding_aid_language_', with: 'English'
  dropdown_items = all('.typeahead.typeahead-long.dropdown-menu')
  dropdown_items.first.click
  fill_in 'resource_finding_aid_script_', with: 'adlam'
  dropdown_items = all('.typeahead.typeahead-long.dropdown-menu')
  dropdown_items.first.click
  click_on 'Save'
  expect(page).to have_text "Resource Resource A #{@resource_a_uuid} #{@shared_resource_uuid} created"

  visit "#{STAFF_URL}/resources/new"
  fill_in 'resource_title_', with: "Resource B #{@resource_b_uuid} #{@shared_resource_uuid}"
  fill_in 'resource_id_0_', with: "Resource B #{@resource_b_uuid}"
  select 'Collection', from: 'Level of Description'
  fill_in 'Language', with: 'English'
  dropdown_items = all('.typeahead.typeahead-long.dropdown-menu')
  dropdown_items.first.click
  fill_in 'Script', with: 'adlam'
  dropdown_items = all('.typeahead.typeahead-long.dropdown-menu')
  dropdown_items.first.click
  select 'Single', from: 'resource_dates__0__date_type_'
  fill_in 'resource_dates__0__begin_', with: '2000-01-01'
  fill_in 'Number', with: @uuid
  select 'Cassettes', from: 'resource_extents__0__extent_type_'
  fill_in 'resource_finding_aid_language_', with: 'English'
  dropdown_items = all('.typeahead.typeahead-long.dropdown-menu')
  dropdown_items.first.click
  fill_in 'resource_finding_aid_script_', with: 'adlam'
  dropdown_items = all('.typeahead.typeahead-long.dropdown-menu')
  dropdown_items.first.click
  click_on 'Save'
  expect(page).to have_text "Resource Resource B #{@resource_b_uuid} #{@shared_resource_uuid} created"
end

Given 'the two Resources are displayed sorted by ascending title' do
  visit "#{STAFF_URL}/resources"

  fill_in 'filter-text', with: @shared_resource_uuid

  within '.search-filter' do
    find('button').click
  end

  search_result_rows = all('#tabledSearchResults tbody tr')

  expect(search_result_rows.length).to eq 2
  expect(search_result_rows[0]).to have_text @resource_a_uuid
  expect(search_result_rows[1]).to have_text @resource_b_uuid
end

Then 'the two Resources are displayed sorted by descending title' do
  search_result_rows = all('#tabledSearchResults tbody tr')

  expect(search_result_rows.length).to eq 2
  expect(search_result_rows[1]).to have_text @resource_a_uuid
  expect(search_result_rows[0]).to have_text @resource_b_uuid
end

Then 'the two Resources are displayed sorted by ascending identifier' do
  search_result_rows = all('#tabledSearchResults tbody tr')

  expect(search_result_rows.length).to eq 2
  expect(search_result_rows[1]).to have_text @accession_a_uuid
  expect(search_result_rows[0]).to have_text @accession_b_uuid
end

Then 'the two Resources are displayed sorted by ascending level' do
  search_result_rows = all('#tabledSearchResults tbody tr')

  expect(search_result_rows.length).to eq 2
  expect(search_result_rows[1]).to have_text @accession_a_uuid
  expect(search_result_rows[0]).to have_text @accession_b_uuid
end
