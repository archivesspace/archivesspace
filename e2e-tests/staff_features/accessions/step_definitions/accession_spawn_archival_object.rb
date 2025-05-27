# frozen_string_literal: true

When 'the user selects Resource in the modal' do
  within '#linkResourceModal' do
    fill_in 'filter-text', with: @uuid
    within '.search-listing-filter' do
      find('button').click
    end

    rows = all('#tabledSearchResults tbody tr')
    expect(rows.length).to eq 1
    rows[0].click

    click_on 'Select Resource'
  end
end

When 'the user clicks on an Archival Object in the Component Position modal' do
  within '#linkResourceModal' do
    click_on "Archival Object #{@uuid}"
  end
end

Then 'the Archival Object has been spawned from Accession info message is displayed' do
  message = "This Archival Object has been spawned from Accession Accession Title #{@uuid}. This record is unsaved. You must click Save for the record to be created in the system."

  expect(page).to have_text message
end

Then 'the Archival Object title is filled in with the Accession Title' do
  expect(find('#archival_object_title_').value).to eq "Accession Title #{@uuid}"
end

Then 'the Archival Object publish is set from the Accession publish' do
  expect(find('#archival_object_publish_').checked?).to eq true
end

Then 'the following Archival Object forms have the same values as the Accession' do |linked_record_forms|
  linked_record_forms.raw.each do |form_title|
    form_title = form_title[0]

    section_title = find('h3', text: form_title)
    section = section_title.ancestor('section')
    expect(section[:id]).to_not eq nil

    case form_title
    when 'Agent Links'
      expect(find('#archival_object_linked_agents__0__role_').value).to eq 'creator'
      expect(find('#archival_object_linked_agents__0__title_').value).to eq "Accession #{@uuid} Agent Title"
      expect(find('#archival_object_linked_agents__0__relator_').value).to eq 'Annotator'
      expect(find('#archival_object_linked_agents__0__ref__combobox .token-input-token').text).to include 'test_agent'
    when 'Accession Links'
      expect(find('#archival_object_accession_links__0_ .token-input-token').text).to include "Accession #{@uuid}: Accession Title #{@uuid}"
    when 'Subjects'
      expect(find('#archival_object_subjects__0_ .token-input-token').text).to include 'test_subject_term'
    when 'Languages'
      expect(find('#archival_object_lang_materials__0__language_and_script__language_').value).to eq 'English'
      expect(find('#archival_object_lang_materials__0__language_and_script__script_').value).to eq 'Adlam'
    when 'Dates'
      expect(find('#archival_object_dates__0__label_').value).to eq 'creation'
      expect(find('#archival_object_dates__0__date_type_').value).to eq 'single'
      expect(find('#archival_object_dates__0__begin_').value).to eq ORIGINAL_ACCESSION_DATE
    when 'Extents'
      expect(find('#archival_object_extents__0__portion_').value).to eq 'whole'
      expect(find('#archival_object_extents__0__number_').value).to eq @uuid
      expect(find('#archival_object_extents__0__extent_type_').value).to eq 'cassettes'
    when 'Rights Statements'
      expect(find('#archival_object_rights_statements__0__rights_type_').value).to eq 'copyright'
      expect(find('#archival_object_rights_statements__0__status_').value).to eq 'copyrighted'
      expect(find('#archival_object_rights_statements__0__jurisdiction_').value).to eq 'Andorra'
      expect(find('#archival_object_rights_statements__0__start_date_').value).to eq ORIGINAL_ACCESSION_DATE
    else
      raise "Invalid form provided: #{form_title}"
    end
  end
end

Then 'the Archival Object notes are set from the Accession Content Description and Condition Description' do
  notes = all('#notes .subrecord-form-wrapper')
  expect(notes.length).to eq 2

  notes[0].click
  expect(find('#archival_object_notes__0__label_').value).to eq 'Content Description'
  expect(find('#archival_object_notes__0__type_').value).to eq 'scopecontent'
  expect(find('#archival_object_notes__0__subnotes__0_ textarea', match: :first, visible: false).value).to eq "Content Description #{@uuid}"

  notes[1].click
  expect(find('#archival_object_notes__1__label_').value).to eq 'Condition Description'
  expect(find('#archival_object_notes__1__type_').value).to eq 'physdesc'
  expect(find('#archival_object_notes__1__content__0_ textarea', match: :first, visible: false).value).to eq "Condition Description #{@uuid}"
end
