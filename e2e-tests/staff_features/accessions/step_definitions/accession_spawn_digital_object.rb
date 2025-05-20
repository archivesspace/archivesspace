# frozen_string_literal: true

When 'the {string} setting is enabled in the Repository Preferences' do |repository_setting_checkbox_label|
  find('#user-menu-dropdown').click
  click_on 'Repository Preferences (admin)'

  check repository_setting_checkbox_label

  click_on 'Save'
end

Then 'the Create Digital Object modal is displayed' do
  expect(page).to have_css '#accession_instances__0__digital_object__ref__modal'
end

Then 'the Digital Object title is filled in with the Accession Title' do
  expect(find('#digital_object_title_').value).to eq "Accession Title #{@uuid}"
end

Then 'the following Digital Object forms have the same values as the Accession' do |linked_record_forms|
  linked_record_forms.raw.each do |form_title|
    form_title = form_title[0]

    section_title = find('h3', text: form_title)
    section = section_title.ancestor('section')
    expect(section[:id]).to_not eq nil

    case form_title
    when 'Languages'
      expect(find('#digital_object_lang_materials__0__language_and_script__language_').value).to eq 'English'
      expect(find('#digital_object_lang_materials__0__language_and_script__script_').value).to eq 'Adlam'
    when 'Dates'
      expect(find('#digital_object_dates__0__label_').value).to eq 'creation'
      expect(find('#digital_object_dates__0__date_type_').value).to eq 'single'
      expect(find('#digital_object_dates__0__begin_').value).to eq ORIGINAL_ACCESSION_DATE
    else
      raise "Invalid form provided: #{form_title}"
    end
  end
end
