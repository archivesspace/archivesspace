# frozen_string_literal: true

Given 'a Resource with an Archival Object has been created' do
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

  find('button', text: 'Save Resource', match: :first).click

  wait_for_ajax
  expect(page).to have_text "Resource Resource #{@uuid} created"

  url_parts = current_url.split('/')
  url_parts.pop
  @resource_id = url_parts.pop

  click_on 'Add Child'
  wait_for_ajax
  fill_in 'Title', with: "Archival Object 1 #{@uuid}"
  select 'Class', from: 'Level of Description'
  fill_in 'Component Unique Identifier', with: "Archival Object 1 #{@uuid}"
  check 'Publish?'
  check 'Restrictions Apply?'
  fill_in 'Repository Processing Note', with: "Repository Processing Note #{@uuid}"

  click_on 'Add Language'
  fill_in 'Language', with: 'English'
  dropdown_items = all('.typeahead.typeahead-long.dropdown-menu')
  dropdown_items.first.click
  fill_in 'Script', with: 'adlam'
  dropdown_items = all('.typeahead.typeahead-long.dropdown-menu')
  dropdown_items.first.click

  click_on 'Add Date'
  select 'Single', from: 'archival_object_dates__0__date_type_'
  fill_in 'archival_object_dates__0__begin_', with: '2000-01-01'

  click_on 'Add Extent'
  fill_in 'Number', with: @uuid
  select 'Cassettes', from: 'archival_object_extents__0__extent_type_'

  click_on 'Add Agent Link'
  select 'Creator', from: 'archival_object_linked_agents__0__role_'
  fill_in 'archival_object_linked_agents__0__title_', with: "Accession #{@uuid} Agent Title"
  fill_in 'archival_object_linked_agents__0__relator_', with: 'annotator'
  dropdown_items = all('.typeahead.typeahead-long.dropdown-menu')
  dropdown_items.first.click
  fill_in 'token-input-archival_object_linked_agents__0__ref_', with: 'test_agent'
  dropdown_items = all('li.token-input-dropdown-item2')
  dropdown_items.first.click

  click_on 'Add Accession Link'
  fill_in 'token-input-archival_object_accession_links__0__ref_', with: 'test_accession'
  dropdown_items = all('li.token-input-dropdown-item2')
  dropdown_items.first.click

  click_on 'Add Subject'
  fill_in 'token-input-archival_object_subjects__0__ref_', with: 'test_subject'
  dropdown_items = all('li.token-input-dropdown-item2')
  dropdown_items.first.click

  click_on 'Add Note'
  note_type = find('#notes select')
  note_type.select 'Abstract'
  fill_in 'archival_object_notes__0__persistent_id_', with: "Persistent ID #{@uuid}"
  fill_in 'archival_object_notes__0__label_', with: "Label #{@uuid}"
  check 'archival_object_notes__0__publish_'
  page.execute_script("$('#archival_object_notes__0__content__0_').data('CodeMirror').setValue('Content #{@uuid}')")

  click_on 'Add External Document'
  fill_in 'archival_object_external_documents__0__title_', with: "External Document Title #{@uuid}"
  fill_in 'archival_object_external_documents__0__location_', with: "External Document Location #{@uuid}"
  check 'archival_object_external_documents__0__publish_'

  click_on 'Add Rights Statement'
  select 'Copyright', from: 'archival_object_rights_statements__0__rights_type_'
  fill_in 'archival_object_rights_statements__0__jurisdiction_', with: 'andorra'
  dropdown_items = all('.typeahead.typeahead-long.dropdown-menu')
  dropdown_items.first.click
  fill_in 'archival_object_rights_statements__0__start_date_', with: ORIGINAL_ACCESSION_RIGHTS_STATEMENT_START_DATE

  click_on 'Save'
  expect(page).to have_text "Archival Object Archival Object 1 #{@uuid} on Resource Resource #{@uuid} created"
  wait_for_ajax
end

When 'the user selects the Archival Object' do
  click_on "Archival Object 1 #{@uuid}"
end

Then 'the Archival Object with Title {string} is saved as a child of the Resource' do |title|
  archival_objects = all('#tree-container .table-row', text: title)

  expect(archival_objects.length).to eq 1
  expect(archival_objects[0][:class]).to include 'indent-level-1 current'
  expect(page).to have_css "#tree-container #resource_#{@resource_id} + .table-row-group #archival_object_#{@created_record_id}"
end

Then 'the Archival Object with Title {string} is saved as a sibling of the selected Archival Object' do |title|
  archival_objects = all('#tree-container .table-row', text: title)

  expect(archival_objects.length).to eq 1
  expect(archival_objects[0][:class]).to include 'indent-level-1 current'
  expect(page).to have_css "#tree-container #resource_#{@resource_id} + .table-row-group #archival_object_#{@created_record_id}"
end

Then 'the New Archival Object page is displayed' do
  if current_url.include? 'resources'
    expect(current_url).to include "resources/#{@resource_id}/edit#new"
  else
    expect(current_url).to include 'archival_objects/new'
  end
end

Then 'the following Archival Object forms have the same values as the Archival Object' do |forms|
  forms.raw.each do |form_title|
    form_title = form_title[0]

    section_title = find('h3', text: form_title)
    section = section_title.ancestor('section')
    expect(section[:id]).to_not eq nil

    case form_title
    when 'Basic Information'
      expect(find('#archival_object_title_').value).to eq "Archival Object 1 #{@uuid}"
      expect(find('#archival_object_component_id_').value).to eq "Archival Object 1 #{@uuid}"
      expect(find('#archival_object_level_').value).to eq 'class'
      expect(find('#archival_object_publish_').value).to eq '1'
      expect(find('#archival_object_restrictions_apply_').value).to eq '1'
      expect(find('#archival_object_repository_processing_note_').value).to eq "Repository Processing Note #{@uuid}"
    when 'Languages'
      expect(find('#archival_object_lang_materials__0__language_and_script__language_').value).to eq 'English'
      expect(find('#archival_object_lang_materials__0__language_and_script__script_').value).to eq 'Adlam'
    when 'Dates'
      expect(find('#archival_object_dates__0__label_').value).to eq 'creation'
      expect(find('#archival_object_dates__0__date_type_').value).to eq 'single'
      expect(find('#archival_object_dates__0__begin_').value).to eq '2000-01-01'
    when 'Extents'
      expect(find('#archival_object_extents__0__portion_').value).to eq 'whole'
      expect(find('#archival_object_extents__0__number_').value).to eq @uuid
      expect(find('#archival_object_extents__0__extent_type_').value).to eq 'cassettes'
    when 'Agent Links'
      expect(find('#archival_object_linked_agents__0__role_').value).to eq 'creator'
      expect(find('#archival_object_linked_agents__0__title_').value).to eq "Accession #{@uuid} Agent Title"
      expect(find('#archival_object_linked_agents__0__relator_').value).to eq 'Annotator'
      expect(find('#archival_object_linked_agents__0__ref__combobox .token-input-token').text).to include 'test_agent'
    when 'Accession Links'
      expect(find('#archival_object_accession_links__0_ .token-input-token').text).to include 'test_accession'
    when 'Subjects'
      expect(find('#archival_object_subjects__0_ .token-input-token').text).to include 'test_subject_term'
    when 'Notes'
      find('#archival_object_notes__0_').click
      expect(find('#archival_object_notes__0__persistent_id_').value).to eq "Persistent ID #{@uuid}"
      expect(find('#archival_object_notes__0__label_').value).to eq "Label #{@uuid}"
      expect(find('#archival_object_notes__0__publish_').value).to eq '1'
      expect(page).to have_css '#archival_object_notes__0__content__0_'
      expect(find('#archival_object_notes__0__content__0_').text).to include "Content #{@uuid}"
    when 'External Documents'
      expect(find('#archival_object_external_documents__0__title_').value).to eq "External Document Title #{@uuid}"
      expect(find('#archival_object_external_documents__0__location_').value).to eq "External Document Location #{@uuid}"
      expect(find('#archival_object_external_documents__0__publish_').value).to eq '1'
    when 'Rights Statements'
      expect(find('#archival_object_rights_statements__0__rights_type_').value).to eq 'copyright'
      expect(find('#archival_object_rights_statements__0__status_').value).to eq 'copyrighted'
      expect(find('#archival_object_rights_statements__0__jurisdiction_').value).to eq 'Andorra'
      expect(find('#archival_object_rights_statements__0__start_date_').value).to eq '2000-01-01'
    else
      raise "Invalid form provided: #{form_title}"
    end
  end
end
