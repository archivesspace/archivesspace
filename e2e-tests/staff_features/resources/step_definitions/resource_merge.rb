# frozen_string_literal: true

Given 'two Resources A & B have been created' do
  visit "#{STAFF_URL}/resources/new"

  fill_in 'resource_title_', with: "Resource A #{@uuid}"
  fill_in 'resource_id_0_', with: "Resource A #{@uuid}"
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
  expect(page).to have_text "Resource Resource A #{@uuid} created"

  uri_parts = current_url.split('/')
  uri_parts.pop
  @resource_first_id = uri_parts.pop

  visit "#{STAFF_URL}/resources/new"

  fill_in 'resource_title_', with: "Resource B #{@uuid}"
  fill_in 'resource_id_0_', with: "Resource B #{@uuid}"
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

  click_on 'Add Agent Link'
  select 'Creator', from: 'resource_linked_agents__0__role_'
  fill_in 'resource_linked_agents__0__title_', with: "Resource #{@uuid} Agent Title"
  fill_in 'resource_linked_agents__0__relator_', with: 'annotator'
  dropdown_items = all('.typeahead.typeahead-long.dropdown-menu')
  dropdown_items.first.click
  fill_in 'token-input-resource_linked_agents__0__ref_', with: 'test_agent'
  dropdown_items = all('li.token-input-dropdown-item2')
  dropdown_items.first.click

  click_on 'Add Related Accession'
  fill_in 'token-input-resource_related_accessions__0__ref_', with: 'test_accession'
  dropdown_items = all('li.token-input-dropdown-item2')
  dropdown_items.first.click

  click_on 'Add Subject'
  fill_in 'token-input-resource_subjects__0__ref_', with: 'test_subject'
  dropdown_items = all('li.token-input-dropdown-item2')
  dropdown_items.first.click

  click_on 'Add Classification'
  fill_in 'token-input-resource_classifications__0__ref_', with: 'test_classification'
  dropdown_items = all('li.token-input-dropdown-item2')
  dropdown_items.first.click

  find('button', text: 'Save Resource', match: :first).click
  wait_for_ajax
  expect(page).to have_text "Resource Resource B #{@uuid} created"

  uri_parts = current_url.split('/')
  uri_parts.pop
  @resource_second_id = uri_parts.pop
end

Given 'the Resource A is opened in edit mode' do
  visit "#{STAFF_URL}/resources/#{@resource_first_id}/edit"
end

When 'the user selects the Resource B from the search results in the modal' do
  within '.modal-content' do
    within '#tabledSearchResults' do
      rows = all('tr', text: "Resource B #{@uuid}")
      expect(rows.length).to eq 1

      find('input[type="radio"]').click
    end
  end
end

When 'the user filters by text with the Resource B title in the modal' do
  within '.modal-content' do
    fill_in 'Filter by text', with: "Resource B #{@uuid}"
    find('.search-filter button').click

    rows = []
    checks = 0

    while checks < 5
      checks += 1

      begin
        rows = all('tr', text: "Resource B #{@uuid}")
      rescue Selenium::WebDriver::Error::JavascriptError
        sleep 1
      end

      break if rows.length == 1
    end
  end
end

When 'the user fills in and selects the Resource B in the merge dropdown form' do
  fill_in 'token-input-merge_ref_', with: "Resource B #{@uuid}"
  dropdown_items = all('li.token-input-dropdown-item2')
  dropdown_items.first.click
end

Then 'the Resource B is deleted' do
  visit "#{STAFF_URL}/resources/#{@resource_second_id}"

  expect(page).to have_text 'Record Not Found'
end

Then 'the following linked records from the Resource B are appended to the Resource A' do |forms|
  visit "#{STAFF_URL}/resources/#{@resource_first_id}/edit"

  forms.raw.each do |form_title|
    form_title = form_title[0]

    section_title = find('h3', text: form_title)
    section = section_title.ancestor('section')
    expect(section[:id]).to_not eq nil

    case form_title
    when 'Agent Links'
      expect(find('#resource_linked_agents__0__role_').value).to eq 'creator'
      expect(find('#resource_linked_agents__0__title_').value).to eq "Resource #{@uuid} Agent Title"
      expect(find('#resource_linked_agents__0__relator_').value).to eq 'Annotator'
      expect(find('#resource_linked_agents__0__ref__combobox .token-input-token').text).to include 'test_agent'
    when 'Related Accessions'
      expect(find('#resource_related_accessions__0__ref__combobox').text).to include 'test_accession'
    when 'Subjects'
      expect(find('#resource_subjects__0_ .token-input-token').text).to include 'test_subject_term'
    when 'Classifications'
      expect(find('#resource_classifications__0__ref__combobox').text).to include 'test_classification'
    else
      raise "Invalid form provided: #{form_title}"
    end
  end
end
