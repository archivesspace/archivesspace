# frozen_string_literal: true

Given 'a Digital Object has been created' do
  visit "#{STAFF_URL}/digital_objects/new"

  fill_in 'digital_object_digital_object_id_', with: "Digital Object Identifier #{@uuid}"
  fill_in 'digital_object_title_', with: "Digital Object Title #{@uuid}"

  click_on 'Add Date'
  select 'Single', from: 'digital_object_dates__0__date_type_'
  fill_in 'digital_object_dates__0__begin_', with: '2000-01-01'
  check 'Publish'

  @digital_object_number_of_agents = 0
  @digital_object_number_of_file_versions = 0

  click_on 'Save'

  wait_for_ajax
  expect(find('.alert.alert-success.with-hide-alert').text).to have_text "Digital Object Digital Object Title #{@uuid} Created"
  @digital_object_id = current_url.split('::digital_object_').pop
end

Given 'a Digital Object with a Linked Agent has been created' do
  visit "#{STAFF_URL}/digital_objects/new"

  fill_in 'digital_object_digital_object_id_', with: "Digital Object Identifier #{@uuid}"
  fill_in 'digital_object_title_', with: "Digital Object Title #{@uuid}"

  click_on 'Add Date'
  select 'Single', from: 'digital_object_dates__0__date_type_'
  fill_in 'digital_object_dates__0__begin_', with: '2000-01-01'
  check 'Publish'

  click_on 'Add Agent Link'
  select 'Creator', from: 'digital_object_linked_agents__0__role_'
  fill_in 'token-input-digital_object_linked_agents__0__ref_', with: 'test_agent'
  dropdown_items = all('li.token-input-dropdown-item2')
  dropdown_items.first.click

  @digital_object_number_of_agents = 1
  @digital_object_number_of_file_versions = 0

  click_on 'Save'

  wait_for_ajax
  expect(find('.alert.alert-success.with-hide-alert').text).to have_text "Digital Object Digital Object Title #{@uuid} Created"
  @digital_object_id = current_url.split('::digital_object_').pop
end

Given 'the user is on the Digital Objects page' do
  visit "#{STAFF_URL}/digital_objects"
end

When 'the user filters by text with the Digital Object title' do
  fill_in 'Filter by text', with: "Digital Object Identifier #{@uuid}"

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

Given 'the user is on the Digital Object view page' do
  visit "#{STAFF_URL}/digital_objects/#{@digital_object_id}"
end

Given 'the user is on the Digital Object edit page' do
  visit "#{STAFF_URL}/digital_objects/#{@digital_object_id}/edit"
end

Then 'the Digital Objects page is displayed' do
  expect(find('h2').text).to have_text 'Digital Objects'
  expect(current_url).to include "#{STAFF_URL}/digital_objects"
end

Then 'the user is still on the Digital Object view page' do
  expect(find('h2').text).to eq "Digital Object Title #{@uuid} Digital Object"
  expect(current_url).to include "#{STAFF_URL}/digital_objects/#{@digital_object_id}"
end

Given 'the Digital Object appears in the search results list' do
  visit "#{STAFF_URL}/digital_objects"

  fill_in 'filter-text', with: "Digital Object Identifier #{@uuid}"

  within '.search-filter' do
    find('button').click
  end

  search_result_rows = all('#tabledSearchResults tbody tr')
  expect(search_result_rows.length).to eq 1
end

Then 'the Digital Object is opened in the edit mode' do
  wait_for_ajax
  expect(current_url).to include 'edit'
  expect(@digital_object_id).to eq current_url.split('::digital_object_').pop
end

Given 'the Digital Object is opened in the view mode' do
  visit "#{STAFF_URL}/digital_objects/#{@digital_object_id}"
end

Given 'the Digital Object is opened in edit mode' do
  visit "#{STAFF_URL}/digital_objects/#{@digital_object_id}/edit"

  wait_for_ajax
end

Then 'the Digital Object Title field has the original value' do
  visit "#{STAFF_URL}/digital_objects/#{@digital_object_id}/edit"

  expect(page).to have_field('Title', with: "Digital Object Title #{@uuid}")
end

Then 'the Digital Object Identifier field has the original value' do
  visit "#{STAFF_URL}/digital_objects/#{@digital_object_id}/edit"

  expect(page).to have_field('Identifier', with: "Digital Object Identifier #{@uuid}")
end

Then 'a new File Version is added to the Digital Object with the following values' do |form_values_table|
  subrecords = all('#digital_object_file_versions_ .subrecord-form-list li')

  expect(subrecords.length).to eq @digital_object_number_of_file_versions + 1

  created_subrecord = subrecords.last

  form_values_hash = form_values_table.rows_hash
  form_values_hash.each do |field, value|
    expect(created_subrecord.find_field(field).value).to eq value.downcase.gsub(' ', '_')
  end
end

Given 'the user has added a File Version to the Digital Object with the following values' do |form_values_table|
  click_on 'Add File Version'

  form_values_hash = form_values_table.rows_hash
  form_values_hash.each do |field, value|
    fill_in field, with: value
  end

  click_on 'Save'
  wait_for_ajax

  @digital_object_number_of_file_versions += 1
end

Then 'the File Version is removed from the Digital Object' do
  subrecords = all('#digital_object_file_versions_ .subrecord-form-list li')

  expect(subrecords.length).to eq @digital_object_number_of_file_versions - 1
end

Given 'the Digital Object is published' do
  expect(find('#digital_object_publish_').checked?).to eq true
end

Then 'the Digital Object opens on a new tab in the public interface' do
  expect(page.windows.size).to eq 2
  switch_to_window(page.windows[1])

  tries = 0

  while current_url == 'about:blank'
    break if tries == 3

    tries += 1
    sleep 1
  end

  expect(current_url).to eq "#{PUBLIC_URL}/repositories/#{@repository_id}/digital_objects/#{@digital_object_id}"
  expect(page).to have_text "Digital Object Title #{@uuid}"
end

Then 'the Digital Object Component with Label {string} is saved as a child of the Digital Object' do |text|
  records = all('#tree-container .table-row', text:)

  expect(records.length).to eq 1
  expect(records[0][:class]).to include 'indent-level-1 current'

  expect(page).to have_css "#tree-container #digital_object_#{@digital_object_id} + .table-row-group #digital_object_component_#{@created_record_id}"
end

Then 'the Digital Object Component with Title {string} is saved as a sibling of the selected Digital Object Component' do |title|
  records = all('#tree-container .table-row', text: title)

  expect(records.length).to eq 1
  expect(records[0][:class]).to include 'indent-level-1 current'
  expect(page).to have_css "#tree-container #digital_object_#{@digital_object_id} + .table-row-group #digital_object_component_#{@created_record_id}"
end

Given 'a Digital Object with a Digital Object Component has been created' do
  visit "#{STAFF_URL}/digital_objects/new"

  fill_in 'digital_object_digital_object_id_', with: "Digital Object Identifier #{@uuid}"
  fill_in 'digital_object_title_', with: "Digital Object Title #{@uuid}"

  click_on 'Add Date'
  select 'Single', from: 'digital_object_dates__0__date_type_'
  fill_in 'digital_object_dates__0__begin_', with: '2000-01-01'

  click_on 'Save'

  wait_for_ajax
  expect(find('.alert.alert-success.with-hide-alert').text).to have_text "Digital Object Digital Object Title #{@uuid} Created"
  @digital_object_id = current_url.split('::digital_object_').pop

  click_on 'Add Child'
  wait_for_ajax

  fill_in 'Label', with: "Digital Object Component Label #{@uuid}"
  click_on 'Save'
  wait_for_ajax

  expect(find('.alert.alert-success.with-hide-alert').text).to eq "Digital Object Component created on Digital Object Digital Object Title #{@uuid}"
end

And 'the user selects the Digital Object Component' do
  click_on "Digital Object Component Label #{@uuid}"
end

Then 'the Assessment is linked to the Digital Object in the {string} form' do |form_title|
  section_title = find('h3', text: form_title)
  section = section_title.ancestor('section')
  expect(section[:id]).to_not eq nil

  related_accessions_elements = section.all('li.token-input-token')

  expect(related_accessions_elements.length).to eq 1
  related_accession = related_accessions_elements[0].find('.digital_object')

  expect(related_accession[:'data-content']).to include "digital_objects/#{@digital_object_id}"
end

When 'the user searches and selects an Agent' do
  fill_in 'token-input-digital_object_linked_agents__0__ref_', with: 'test_agent'
  dropdown_items = all('li.token-input-dropdown-item2')
  dropdown_items.first.click
end

Then 'a new Linked Agent is added to the Digital Object' do
  agent_links = all('#digital_object_linked_agents_ .subrecord-form-container li.sort-enabled.initialised.linked_agent_initialised')

  expect(agent_links.length).to eq @digital_object_number_of_agents + 1
end

Then 'the Linked Agent is removed from the Digital Object' do
  agent_links = all('#digital_object_linked_agents_ .subrecord-form-container li.sort-enabled.initialised.linked_agent_initialised')

  expect(agent_links.length).to eq @digital_object_number_of_agents - 1
end
