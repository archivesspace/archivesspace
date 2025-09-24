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
      within '#resource_linked_agents_' do
        expect(page).to have_select('resource_linked_agents__0__role_', selected: 'Creator')
        expect(page).to have_field('resource_linked_agents__0__title_', with: "Accession #{@uuid} Agent Title")
        expect(page).to have_field('resource_linked_agents__0__relator_', with: 'Annotator')
        expect(page).to have_css('#resource_linked_agents__0__ref__combobox .token-input-token', text: 'test_agent')
      end
    when 'Related Accessions'
      within '#resource_related_accessions_' do
        expect(page).to have_css('#resource_related_accessions__0_ .token-input-token', text: "Accession #{@uuid}: Accession Title #{@uuid}")
      end
    when 'Subjects'
      within '#resource_subjects_' do
        expect(page).to have_css('#resource_subjects__0_ .token-input-token', text: 'test_subject_term')
      end
    when 'Languages'
      within '#resource_lang_materials_' do
        expect(page).to have_field('resource_lang_materials__0__language_and_script__language_', with: 'English')
        expect(page).to have_select('resource_lang_materials__0__language_and_script__script__list', selected: 'Adlam', visible: false)
      end
    when 'Dates'
      within '#resource_dates_' do
        expect(page).to have_select('resource_dates__0__label_', selected: 'Creation')
        expect(page).to have_select('resource_dates__0__date_type_', selected: 'Single')
        expect(page).to have_field('resource_dates__0__begin_', with: ORIGINAL_ACCESSION_DATE)
      end
    when 'Extents'
      within '#resource_extents_' do
        expect(page).to have_select('resource_extents__0__portion_', selected: 'Whole')
        expect(page).to have_field('resource_extents__0__number_', with: @uuid)
        expect(page).to have_select('resource_extents__0__extent_type_', selected: 'Cassettes')
      end
    when 'Rights Statements'
      within '#resource_rights_statements_' do
        expect(page).to have_select('resource_rights_statements__0__rights_type_', selected: 'Copyright')
        expect(page).to have_select('resource_rights_statements__0__status_', selected: 'Copyrighted')
        expect(page).to have_field('resource_rights_statements__0__jurisdiction_', with: 'Andorra')
        expect(page).to have_field('resource_rights_statements__0__start_date_', with: ORIGINAL_ACCESSION_DATE)
      end
    when 'Metadata Rights Declarations'
      within '#resource_metadata_rights_declarations_' do
        expect(page).to have_css("#resource_metadata_rights_declarations__0__license_ option[selected][value='public_domain']")
        expect(page).to have_field('resource_metadata_rights_declarations__0__descriptive_note_', with: "Descriptive Note #{@uuid}")

        expect(page).to have_field('resource_metadata_rights_declarations__0__file_uri_', with: "file-uri-#{@uuid}")
        expect(page).to have_select('resource_metadata_rights_declarations__0__file_version_xlink_actuate_attribute_', selected: 'onLoad')
        expect(page).to have_select('resource_metadata_rights_declarations__0__file_version_xlink_show_attribute_', selected: 'embed')
        expect(page).to have_field('resource_metadata_rights_declarations__0__xlink_role_attribute_', with: "Xlink Role Attribute #{@uuid}")
        expect(page).to have_field('resource_metadata_rights_declarations__0__xlink_arcrole_attribute_', with: "Xlink Arcrole Attribute #{@uuid}")
        expect(page).to have_field('resource_metadata_rights_declarations__0__last_verified_date_', with: '2000-01-01 00:00:00 UTC')
      end
    when 'Classifications'
      within '#resource_classifications_' do
        expect(page).to have_css('#resource_classifications__0__ref__combobox .token-input-token', text: 'test_classification')
      end
    else
      raise "Invalid form provided: #{form_title}"
    end
  end
end
