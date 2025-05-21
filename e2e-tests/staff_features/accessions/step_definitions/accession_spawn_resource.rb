# frozen_string_literal: true

Then 'the New Resource page is displayed' do
  uri = current_url.split('/')

  last_part = uri.pop
  last_part_split = last_part.split('?')
  action = last_part_split.pop if last_part_split.length > 1
  action = last_part_split[0] if last_part_split.length == 1

  entity = uri.pop

  expect(entity).to eq 'resources'
  expect(action).to eq 'new'
end

Then 'the Resource is linked to the Accession in the Related Accessions form' do
  section_title = find('h3', text: 'Related Accession')
  section = section_title.ancestor('section')
  expect(section[:id]).to_not eq nil

  related_accessions_elements = section.all('.subrecord-form-fields')
  expect(related_accessions_elements.length).to eq 1
  related_accession = related_accessions_elements[0].find('.accession')

  expect(related_accession[:'data-content']).to include "accessions/#{@accession_id}"
end

Then 'the Resource has been spawned from Accession info message is displayed' do
  message = "A new Resource has been spawned from Accession Accession Title #{@uuid}. This record is unsaved. You must click Save for the record to be created in the system."

  expect(page).to have_text message
end

Then 'the Accession page is displayed' do
  expect(current_url).to include "accessions/#{@accession_id}"
end

Then 'the Resource title is filled in with the Accession Title' do
  expect(find('#resource_title_').value).to eq "Accession Title #{@uuid}"
end

Then 'the Resource publish is set from the Accession publish' do
  expect(find('#resource_publish_').checked?).to eq true
end

Then 'the Resource notes are set from the Accession Content Description and Condition Description' do
  notes = all('#resource_notes_ .subrecord-form-wrapper')
  expect(notes.length).to eq 2

  notes[0].click
  expect(find('#resource_notes__0__label_').value).to eq 'Content Description'
  expect(find('#resource_notes__0__type_').value).to eq 'scopecontent'
  expect(find('#resource_notes__0__subnotes__0_ textarea', match: :first, visible: false).value).to eq "Content Description #{@uuid}"

  notes[1].click
  expect(find('#resource_notes__1__label_').value).to eq 'Condition Description'
  expect(find('#resource_notes__1__type_').value).to eq 'physdesc'
  expect(find('#resource_notes__1__content__0_ textarea', match: :first, visible: false).value).to eq "Condition Description #{@uuid}"
end

Then 'the following Resource forms have the same values as the Accession' do |linked_record_forms|
  linked_record_forms.raw.each do |form_title|
    form_title = form_title[0]

    section_title = find('h3', text: form_title)
    section = section_title.ancestor('section')
    expect(section[:id]).to_not eq nil

    case form_title
    when 'Agent Links'
      expect(find('#resource_linked_agents__0__role_').value).to eq 'creator'
      expect(find('#resource_linked_agents__0__title_').value).to eq "Accession #{@uuid} Agent Title"
      expect(find('#resource_linked_agents__0__relator_').value).to eq 'Annotator'
      expect(find('#resource_linked_agents__0__ref__combobox .token-input-token').text).to include 'test_agent'
    when 'Related Accessions'
      expect(find('#resource_related_accessions__0_ .token-input-token').text).to include "Accession #{@uuid}: Accession Title #{@uuid}"
    when 'Subjects'
      expect(find('#resource_subjects__0_ .token-input-token').text).to include 'test_subject_term'
    when 'Languages'
      expect(find('#resource_lang_materials__0__language_and_script__language_').value).to eq 'English'
      expect(find('#resource_lang_materials__0__language_and_script__script_').value).to eq 'Adlam'
    when 'Dates'
      expect(find('#resource_dates__0__label_').value).to eq 'creation'
      expect(find('#resource_dates__0__date_type_').value).to eq 'single'
      expect(find('#resource_dates__0__begin_').value).to eq ORIGINAL_ACCESSION_DATE
    when 'Extents'
      expect(find('#resource_extents__0__portion_').value).to eq 'whole'
      expect(find('#resource_extents__0__number_').value).to eq @uuid
      expect(find('#resource_extents__0__extent_type_').value).to eq 'cassettes'
    when 'Rights Statements'
      expect(find('#resource_rights_statements__0__rights_type_').value).to eq 'copyright'
      expect(find('#resource_rights_statements__0__status_').value).to eq 'copyrighted'
      expect(find('#resource_rights_statements__0__jurisdiction_').value).to eq 'Andorra'
      expect(find('#resource_rights_statements__0__start_date_').value).to eq ORIGINAL_ACCESSION_DATE
    when 'Metadata Rights Declarations'
      expect(find('#resource_metadata_rights_declarations__0__license_').value).to eq 'public_domain'
      expect(find('#resource_metadata_rights_declarations__0__descriptive_note_').value).to eq "Descriptive Note #{@uuid}"
      expect(find('#resource_metadata_rights_declarations__0__descriptive_note_').value).to eq "Descriptive Note #{@uuid}"
      expect(find('#resource_metadata_rights_declarations__0__file_uri_').value).to eq "file-uri-#{@uuid}"
      expect(find('#resource_metadata_rights_declarations__0__file_version_xlink_actuate_attribute_').value).to eq 'onLoad'
      expect(find('#resource_metadata_rights_declarations__0__file_version_xlink_show_attribute_').value).to eq 'embed'
      expect(find('#resource_metadata_rights_declarations__0__xlink_role_attribute_').value).to eq "Xlink Role Attribute #{@uuid}"
      expect(find('#resource_metadata_rights_declarations__0__xlink_arcrole_attribute_').value).to eq "Xlink Arcrole Attribute #{@uuid}"
      expect(find('#resource_metadata_rights_declarations__0__last_verified_date_').value).to eq '2000-01-01 00:00:00 UTC'
    when 'Classifications'
      expect(find('#resource_classifications__0__ref__combobox .token-input-token').text).to include 'test_classification'
    else
      raise "Invalid form provided: #{form_title}"
    end
  end
end
