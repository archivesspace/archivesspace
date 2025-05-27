# frozen_string_literal: true

Given 'an Accession has been created' do
  visit "#{STAFF_URL}/accessions/new"

  fill_in 'accession_id_0_', with: "Accession #{@uuid}"
  fill_in 'Title', with: "Accession Title #{@uuid}"
  fill_in 'Accession Date', with: ORIGINAL_ACCESSION_DATE
  check 'Publish?'

  fill_in 'accession_content_description_', with: "Content Description #{@uuid}"
  fill_in 'accession_condition_description_', with: "Condition Description #{@uuid}"
  fill_in 'accession_disposition_', with: "Disposition #{@uuid}"
  fill_in 'accession_inventory_', with: "Inventory #{@uuid}"
  fill_in 'accession_provenance_', with: "Provenance #{@uuid}"
  fill_in 'accession_retention_rule_', with: "Retention Rule #{@uuid}"
  fill_in 'accession_general_note_', with: "General Note #{@uuid}"
  select 'Deposit', from: 'accession_acquisition_type_'
  select 'Collection', from: 'accession_resource_type_'

  fill_in 'accession_language_', with: 'english'
  dropdown_items = all('.typeahead.typeahead-long.dropdown-menu')
  dropdown_items.first.click
  fill_in 'accession_script_', with: 'adlam'
  dropdown_items = all('.typeahead.typeahead-long.dropdown-menu')
  dropdown_items.first.click
  find('#accession_restrictions_apply_').check
  find('#accession_access_restrictions_').check
  fill_in 'accession_access_restrictions_note_', with: "Access Restrictions Note #{@uuid}"
  find('#accession_use_restrictions_').check
  fill_in 'accession_use_restrictions_note_', with: "Use Restrictions Note #{@uuid}"

  click_on 'Add Language'
  fill_in 'Language', with: 'English'
  dropdown_items = all('.typeahead.typeahead-long.dropdown-menu li')
  dropdown_item = dropdown_items.select do |item|
    item.text == 'English'
  end
  expect(dropdown_item.length).to eq 1
  dropdown_item[0].click

  fill_in 'Script', with: 'adlam'
  dropdown_items = all('.typeahead.typeahead-long.dropdown-menu')
  dropdown_items.first.click

  click_on 'Add Date'
  select 'Single', from: 'accession_dates__0__date_type_'
  fill_in 'accession_dates__0__begin_', with: ORIGINAL_ACCESSION_DATE

  click_on 'Add Extent'
  fill_in 'Number', with: @uuid
  select 'Cassettes', from: 'accession_extents__0__extent_type_'
  @accession_number_of_extents = 1

  click_on 'Add Agent Link'
  select 'Creator', from: 'accession_linked_agents__0__role_'
  fill_in 'accession_linked_agents__0__title_', with: "Accession #{@uuid} Agent Title"
  fill_in 'accession_linked_agents__0__relator_', with: 'annotator'
  dropdown_items = all('.typeahead.typeahead-long.dropdown-menu')
  dropdown_items.first.click
  fill_in 'token-input-accession_linked_agents__0__ref_', with: 'test_agent'
  dropdown_items = all('li.token-input-dropdown-item2')
  dropdown_items.first.click

  click_on 'Add Subject'
  fill_in 'token-input-accession_subjects__0__ref_', with: 'test_subject'
  dropdown_items = all('li.token-input-dropdown-item2')
  dropdown_items.first.click

  click_on 'Add Rights Statement'
  select 'Copyright', from: 'accession_rights_statements__0__rights_type_'
  fill_in 'accession_rights_statements__0__jurisdiction_', with: 'andorra'
  dropdown_items = all('.typeahead.typeahead-long.dropdown-menu')
  dropdown_items.first.click
  fill_in 'accession_rights_statements__0__start_date_', with: ORIGINAL_ACCESSION_RIGHTS_STATEMENT_START_DATE

  click_on 'Add Metadata Rights Declaration'
  select 'This record is made available under an Universal 1.0 Public Domain Dedication Creative Commons license.',
         from: 'accession_metadata_rights_declarations__0__license_'
  fill_in 'accession_metadata_rights_declarations__0__descriptive_note_', with: "Descriptive Note #{@uuid}"
  fill_in 'accession_metadata_rights_declarations__0__file_uri_', with: "file-uri-#{@uuid}"
  select 'onLoad', from: 'accession_metadata_rights_declarations__0__file_version_xlink_actuate_attribute_'
  select 'embed', from: 'accession_metadata_rights_declarations__0__file_version_xlink_show_attribute_'
  fill_in 'accession_metadata_rights_declarations__0__xlink_title_attribute_', with: "Xlink Title Attribute #{@uuid}"
  fill_in 'accession_metadata_rights_declarations__0__xlink_role_attribute_', with: "Xlink Role Attribute #{@uuid}"
  fill_in 'accession_metadata_rights_declarations__0__xlink_arcrole_attribute_', with: "Xlink Arcrole Attribute #{@uuid}"
  fill_in 'accession_metadata_rights_declarations__0__last_verified_date_', with: '2000-01-01'

  click_on 'Add Classification'
  fill_in 'token-input-accession_classifications__0__ref_', with: 'test_classification'
  dropdown_items = all('li.token-input-dropdown-item2')
  dropdown_items.first.click

  @accession_number_of_instances = 0

  click_on 'Save'
  expect(page).to have_text "Accession Accession Title #{@uuid} created"
end

Given 'an Accession with a Top Container has been created' do
  visit "#{STAFF_URL}/accessions/new"

  fill_in 'accession_id_0_', with: "Accession #{@uuid}"
  fill_in 'Title', with: "Accession Title #{@uuid}"
  fill_in 'Accession Date', with: ORIGINAL_ACCESSION_DATE
  check 'Publish?'

  click_on 'Add Container Instance'
  select 'Accession', from: 'accession_instances__0__instance_type_'

  within '#accession_instances__0__sub_container__top_container__ref__combobox' do
    find('button').click

    click_on 'Create'
  end

  fill_in 'top_container_indicator_', with: @uuid
  click_on 'Create and Link'

  click_on 'Save'
  expect(page).to have_text "Accession Accession Title #{@uuid} created"
end

Given 'the Accession is opened in edit mode' do
  visit "#{STAFF_URL}/accessions"

  fill_in 'filter-text', with: @uuid

  within '.search-filter' do
    find('button').click
  end

  search_result_rows = all('#tabledSearchResults tbody tr')
  expect(search_result_rows.length).to eq 1

  within search_result_rows[0] do
    element = find('a', text: 'Edit')

    @accession_id = URI.decode_www_form_component(element[:href]).split('/').pop
  end

  click_on 'Edit'
end

Then 'a new Extent is added to the Accession with the following values' do |form_values_table|
  extents = all('#accession_extents_ .subrecord-form-list li')

  expect(extents.length).to eq @accession_number_of_extents + 1

  created_extent = extents.last

  form_values_hash = form_values_table.rows_hash
  form_values_hash.each do |field, value|
    expect(created_extent.find_field(field).value).to eq value.downcase.gsub(' ', '_')
  end
end

When 'the user selects the Top Container from the search results in the modal' do
  results = all('table.table-search-results tbody tr')

  expect(results.length > 0).to eq true

  results[0].click
end
