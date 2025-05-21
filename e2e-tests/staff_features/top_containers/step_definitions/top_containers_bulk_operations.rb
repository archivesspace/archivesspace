# frozen_string_literal: true

Given 'a Resource with two Top Containers has been created' do
  visit "#{STAFF_URL}/resources/new"

  fill_in 'resource_title_', with: "Resource #{@uuid}"
  fill_in 'resource_id_0_', with: "Resource #{@uuid}"
  select 'Class', from: 'resource_level_'
  element = find('#resource_lang_materials__0__language_and_script__language_')
  element.send_keys('AU')
  element.send_keys(:tab)

  select 'Single', from: 'resource_dates__0__date_type_'
  fill_in 'resource_dates__0__begin_', with: '2024'

  fill_in 'resource_extents__0__number_', with: '10'
  select 'Cassettes', from: 'resource_extents__0__extent_type_'

  element = find('#resource_finding_aid_language_')
  element.send_keys('ENG')
  element.send_keys(:tab)

  element = find('#resource_finding_aid_script_')
  element.send_keys('Latin')
  element.send_keys(:tab)

  click_on 'Add Container Instance'
  select 'Accession', from: 'resource_instances__0__instance_type_'
  find('#resource_instances__0__sub_container__top_container__ref__combobox .btn.btn-default.dropdown-toggle').click
  within '#resource_instances__0__sub_container__top_container__ref__combobox' do
    click_on 'Create'
  end
  fill_in 'Indicator', with: "Indicator A #{@uuid}"

  click_on 'Add Location'
  fill_in 'token-input-top_container_container_locations__0__ref_', with: 'test_location'
  dropdown_items = all('li.token-input-dropdown-item2')
  dropdown_items.first.click

  click_on 'Create and Link'

  sleep 3

  click_on 'Add Container Instance'
  select 'Accession', from: 'resource_instances__1__instance_type_'
  find('#resource_instances__1__sub_container__top_container__ref__combobox .btn.btn-default.dropdown-toggle').click
  within '#resource_instances__1__sub_container__top_container__ref__combobox' do
    click_on 'Create'
  end

  fill_in 'Indicator', with: "Indicator B #{@uuid}"
  click_on 'Add Location'
  fill_in 'token-input-top_container_container_locations__0__ref_', with: 'test_location'
  dropdown_items = all('li.token-input-dropdown-item2')
  dropdown_items.first.click
  click_on 'Create and Link'

  find('button', text: 'Save Resource', match: :first).click

  wait_for_ajax
  expect(page).to have_text "Resource Resource #{@uuid} created"

  url_parts = current_url.split('/')
  url_parts.pop
  @resource_id = url_parts.pop

  top_containers = all('.top_container')
  data_content = top_containers[0][:'data-content']
  split = data_content.split('/')
  split.pop
  text_containing_id = split.pop
  @top_container_first_id = text_containing_id.scan(/\d+/).first

  data_content = top_containers[1][:'data-content']
  split = data_content.split('/')
  split.pop
  text_containing_id = split.pop
  @top_container_second_id = text_containing_id.scan(/\d+/).first
end

When 'the user fills in {string} with the Resource title' do |label|
  fill_in label, with: @uuid
end

When 'the user checks the checkbox in the header row' do
  within '#bulk_operation_results' do
    find('#select_all').click
  end
end

Then 'all the Top Containers are selected' do
  checkboxes = all('#bulk_operation_results tbody tr input')

  checkboxes.each do |checkbox|
    expect(checkbox.checked?).to eq true
  end
end

Given 'all Top Containers are selected' do
  find('#select_all').click
end

Then 'all the Top Containers are not selected' do
  checkboxes = all('#bulk_operation_results tbody tr input')

  checkboxes.each do |checkbox|
    expect(checkbox.checked?).to eq false
  end
end

Given 'the Top Container A is selected' do
  checkboxes = all('#bulk_operation_results tbody tr input')

  checkboxes[0].check
end

Given 'the the two Top Containers are displayed in the search results' do
  fill_in 'Keyword', with: @uuid

  click_on 'Search'
end

When 'the user fills in and selects Container Profile in the modal' do
  fill_in 'token-input-container_profile', with: 'test_container_profile'
end

When 'the user selects Location in the modal' do
  rows = all('#tabledSearchResults tbody tr')

  rows.first.click
end

When 'the user clicks on the dropdown in the Bulk Update form' do
  find('#bulk_update_form .btn.btn-default.dropdown-toggle').click
end

When 'the user selects Container Profile in the modal' do
  fill_in 'filter-text', with: 'test_container_profile'
  find('.search-filter button').click

  rows = all('#tabledSearchResults input')
  rows[0].click
end

When 'the user clicks on {string} in the Browse Container Profiles modal' do |string|
  wait_for_ajax

  within '#container_profile_modal' do
    click_on_string string
  end
end

Then 'the Top Container A profile is linked to the Container Profile' do
  visit "#{STAFF_URL}/top_containers/#{@top_container_first_id}/edit"

  element = find('.container_profile')
  expect(element.text).to include 'test_container_profile'
end

When 'the user fills in {string} with {string} in the Create Container Profiles modal' do |label, value|
  within '#container_profile_modal' do
    fill_in label, with: value, match: :first
  end
end

When 'the user fills in {string} in the Create Container Profiles modal' do |label|
  within '#container_profile_modal' do
    fill_in label, with: @uuid, match: :first
  end
end

Then 'the Top Container A profile is linked to the created Container Profile' do
  visit "#{STAFF_URL}/top_containers/#{@top_container_first_id}/edit"

  element = find('.container_profile')
  expect(element.text).to include @uuid
end

When 'the user clicks on {string} in the Browse Locations modal' do |string|
  wait_for_ajax

  within '#location_modal' do
    click_on_string string
  end
end

Then 'the Top Container profile is linked to the Location' do
  visit "#{STAFF_URL}/top_containers/#{@top_container_first_id}/edit"

  element = find('.location')
  expect(element.text).to include 'test_location'
end

When 'the user fills in {string} with {string} in the Create Location modal' do |label, value|
  within '#location_modal' do
    fill_in label, with: value, match: :first
  end
end

When 'the user clicks on {string} in the Create Location modal' do |string|
  wait_for_ajax

  within '#location_modal' do
    click_on_string string
  end
end

Then 'the Top Container profile is linked to the created Location' do
  visit "#{STAFF_URL}/top_containers/#{@top_container_first_id}/edit"

  element = find('.location')
  expect(element.text).to include 'Test Building'
end

Given 'the two Top Containers are selected' do
  rows = all('#bulk_operation_results tbody tr')

  rows.each do |row|
    row.all('td')[1].click
  end

  tries = 0

  loop do
    buttons = all('button', text: 'Bulk Operations')
    expect(buttons[0].disabled?).to eq false
    expect(buttons[1].disabled?).to eq false

    break
  rescue RSpec::Expectations::ExpectationNotMetError => e
    sleep 1
    tries += 1

    raise e if tries == 3
  end
end

Then 'the Locations are removed from the Top Containers' do
  visit "#{STAFF_URL}/top_containers/#{@top_container_first_id}/edit"
  expect(page).to_not have_css '.location'

  visit "#{STAFF_URL}/top_containers/#{@top_container_second_id}/edit"
  expect(page).to_not have_css '.location'
end

When 'the user fills in New Barcode for Top Container A' do
  row = find('#bulkActionBarcodeRapidEntryModal tr', text: "Indicator A #{@uuid}")

  @top_container_first_barcode = SecureRandom.uuid
  row.find('input').fill_in with: @top_container_first_barcode
end

When 'the user fills in New Barcode for Top Container B' do
  row = find('#bulkActionBarcodeRapidEntryModal tr', text: "Indicator B #{@uuid}")

  @top_container_second_barcode = SecureRandom.uuid
  row.find('input').fill_in with: @top_container_second_barcode
end

Then 'the Top Containers have new Barcodes' do
  visit "#{STAFF_URL}/top_containers/#{@top_container_first_id}/edit"
  expect(find_field('Barcode').value).to eq @top_container_first_barcode

  visit "#{STAFF_URL}/top_containers/#{@top_container_second_id}/edit"
  expect(find_field('Barcode').value).to eq @top_container_second_barcode
end

When 'the user fills in New Barcode for Top Container A with {string}' do |value|
  row = find('#bulkActionBarcodeRapidEntryModal tr', text: "Indicator A #{@uuid}")

  row.find('input').fill_in with: value
end

When 'the user fills in New Barcode for Top Container B with {string}' do |value|
  row = find('#bulkActionBarcodeRapidEntryModal tr', text: "Indicator B #{@uuid}")

  row.find('input').fill_in with: value
end

When 'the user selects the Top Container B in the Merge Top Containers modal' do
  find('#chkPref', text: "Indicator B #{@uuid}").find('input').click
end

When 'the user clicks on {string} in the Confirm Merge Top Containers modal' do |string|
  within '#bulkMergeConfirmModal' do
    click_on_string string
  end
end

Then 'the Top Container A is deleted' do
  visit "#{STAFF_URL}/top_containers/#{@top_container_first_id}/edit"

  expect(page).to have_text 'Record Not Found'
  expect(page).to have_text "The record you've tried to access may no longer exist or you may not have permission to view it."
end

Then 'the two Top Containers are deleted' do
  visit "#{STAFF_URL}/top_containers/#{@top_container_first_id}/edit"
  expect(page).to have_text 'Record Not Found'
  expect(page).to have_text "The record you've tried to access may no longer exist or you may not have permission to view it."

  visit "#{STAFF_URL}/top_containers/#{@top_container_second_id}/edit"
  expect(page).to have_text 'Record Not Found'
  expect(page).to have_text "The record you've tried to access may no longer exist or you may not have permission to view it."
end
