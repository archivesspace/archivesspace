# frozen_string_literal: true

When 'the user selects Resource in the modal' do
  within '#linkResourceModal' do
    fill_in 'filter-text', with: @uuid
    within '.search-listing-filter' do
      find('button').click
    end

    wait_for_ajax
    within '#tabledSearchResults' do
      find('tbody tr', match: :first).click
    end

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
  wait_for_ajax
  linked_record_forms.raw.each do |form_title|
    form_title = form_title[0]

    section_title = find('h3', text: form_title)
    section = section_title.ancestor('section')
    expect(section[:id]).to_not eq nil

    case form_title
    when 'Agent Links'
      within '#archival_object_linked_agents__0_' do
        expect(page).to have_select('archival_object_linked_agents__0__role_', selected: 'Creator')
        expect(page).to have_field('archival_object_linked_agents__0__title_', with: "Accession #{@uuid} Agent Title")
        expect(page).to have_field('archival_object_linked_agents__0__relator_', with: 'Annotator')
        expect(page).to have_css('#archival_object_linked_agents__0__ref__combobox .token-input-token', text: 'test_agent')
      end
    when 'Accession Links'
      expect(page).to have_css('#archival_object_accession_links__0_ .token-input-token', text: "Accession #{@uuid}: Accession Title #{@uuid}")
    when 'Subjects'
      expect(page).to have_css('#archival_object_subjects__0_ .token-input-token', text: 'test_subject_term')
    when 'Languages'
      within '#archival_object_lang_materials__0_' do
        expect(page).to have_field('archival_object_lang_materials__0__language_and_script__language_', with: 'English')
        expect(page).to have_select('archival_object_lang_materials__0__language_and_script__script__list', selected: 'Adlam', visible: false)
      end
    when 'Dates'
      expect(page).to have_select('archival_object_dates__0__label_', selected: 'Creation')
      expect(page).to have_select('archival_object_dates__0__date_type_', selected: 'Single')
      expect(page).to have_field('archival_object_dates__0__begin_', with: ORIGINAL_ACCESSION_DATE)
    when 'Extents'
      expect(page).to have_select('archival_object_extents__0__portion_', selected: 'Whole')
      expect(page).to have_field('archival_object_extents__0__number_', with: @uuid)
      expect(page).to have_select('archival_object_extents__0__extent_type_', selected: 'Cassettes')
    when 'Rights Statements'
      expect(page).to have_select('archival_object_rights_statements__0__rights_type_', selected: 'Copyright')
      expect(page).to have_select('archival_object_rights_statements__0__status_', selected: 'Copyrighted')
      expect(page).to have_field('archival_object_rights_statements__0__jurisdiction_', with: 'Andorra')
      expect(page).to have_field('archival_object_rights_statements__0__start_date_', with: ORIGINAL_ACCESSION_DATE)
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
