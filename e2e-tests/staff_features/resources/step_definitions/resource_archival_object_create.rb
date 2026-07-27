# frozen_string_literal: true

Given 'a Resource with an Archival Object has been created' do
  create_resource(@uuid)
  create_resource_archival_object(@uuid)
end

When 'the user selects the Archival Object' do
  click_on "Archival Object #{@uuid}"
end

Then 'the Archival Object with Title {string} is saved as a child of the Resource' do |title|
  expect(page).to have_css '#tree-container .table-row.indent-level-1.current', text: title
  expect(page).to have_css "#tree-container #resource_#{@resource_id} + .table-row-group #archival_object_#{@created_record_id}"
end

Then 'the Archival Object with Title {string} is saved as a sibling of the selected Archival Object' do |title|
  expect(page).to have_css('#tree-container .table-row.largetree-node.indent-level-1.current', text: title)
  expect(page).to have_css "#tree-container #resource_#{@resource_id} + .table-row-group #archival_object_#{@created_record_id}"
end

Then 'the New Archival Object page is displayed' do
  wait_for_ajax
  if current_url.include? 'resources'
    expect(current_url).to include "resources/#{@resource_id}/edit#new"
  else
    expect(current_url).to include 'archival_objects/new'
  end
end

Then 'the following Archival Object forms have the same values as the Archival Object' do |forms|
  aggregate_failures do
    forms.raw.each do |form_title|
      form_title = form_title[0]

      section_title = find('h3', text: form_title)
      section = section_title.ancestor('section')
      expect(section[:id]).to_not eq nil

      case form_title
      when 'Basic Information'
        expect(find('#archival_object_title_').value).to eq "Archival Object #{@uuid}"
        expect(find('#archival_object_component_id_').value).to eq @uuid
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
        expect(find('#archival_object_dates__0__begin_').value).to eq '2020-01-01'
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
        expect(page).to have_field('archival_object_notes__0__label_', with: "Label #{@uuid}")
        expect(page).to have_checked_field('archival_object_notes__0__publish_')
        expect(page).to have_field('archival_object_notes__0__content__0_', visible: false, with: "Content #{@uuid}")
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
end
