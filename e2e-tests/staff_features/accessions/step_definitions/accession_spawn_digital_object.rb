# frozen_string_literal: true

When "the 'Spawn description for Digital Object instances from linked record' setting is enabled in the Repository Preferences" do
  find('#user-menu-dropdown').click
  click_on 'Repository Preferences (admin)'

  # unchecking and checking two times to ensure that the REFRESH_PREFERENCES notification reaches SUI
  uncheck 'Spawn description for Digital Object instances from linked record'
  click_on 'Save'
  sleep 3
  check 'Spawn description for Digital Object instances from linked record'
  click_on 'Save'
  sleep 3
  uncheck 'Publish?'
  click_on 'Save'
  sleep 3
  check 'Publish?'
  click_on 'Save'
  expect(page).to have_css('.alert.alert-success.with-hide-alert', text: 'Preferences updated')
end

Then 'the Create Digital Object modal is displayed' do
  expect(page).to have_css '#accession_instances__0__digital_object__ref__modal'
  wait_for_ajax
end

Then 'the Digital Object title is filled in with the Accession Title' do
  wait_for_ajax

  within '#form_digital_object section#basic_information' do
    expect(page).to have_field('digital_object_title_', with: "Accession Title #{@uuid}")
  end
end

Then 'the following Digital Object forms have the same values as the Accession' do |linked_record_forms|
  linked_record_forms.raw.each do |form_title|
    form_title = form_title[0]

    section_title = find('h3', text: form_title)
    section = section_title.ancestor('section')
    expect(section[:id]).to_not eq nil

    case form_title
    when 'Languages'
      within '#digital_object_lang_materials__0_' do
        expect(page).to have_field('digital_object_lang_materials__0__language_and_script__language_', with: 'English')
        expect(page).to have_select('digital_object_lang_materials__0__language_and_script__script__list', selected: 'Adlam', visible: false)
      end
    when 'Dates'
      expect(page).to have_select('digital_object_dates__0__label_', selected: 'Creation')
      expect(page).to have_select('digital_object_dates__0__date_type_', selected: 'Single')
      expect(page).to have_field('digital_object_dates__0__begin_', with: ORIGINAL_ACCESSION_DATE)
    else
      raise "Invalid form provided: #{form_title}"
    end
  end
end
