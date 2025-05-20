# frozen_string_literal: true

Given 'two Digital Objects A & B have been created' do
  visit "#{STAFF_URL}/digital_objects/new"

  fill_in 'digital_object_digital_object_id_', with: "Digital Object A #{@uuid}"
  fill_in 'digital_object_title_', with: "Digital Object A #{@uuid}"

  click_on 'Save'
  wait_for_ajax

  expect(find('.alert.alert-success.with-hide-alert').text).to have_text "Digital Object Digital Object A #{@uuid} Created"
  @digital_object_first_id = current_url.split('::digital_object_').pop

  visit "#{STAFF_URL}/digital_objects/new"

  fill_in 'digital_object_digital_object_id_', with: "Digital Object B #{@uuid}"
  fill_in 'digital_object_title_', with: "Digital Object B #{@uuid}"

  click_on 'Add Agent Link'
  select 'Creator', from: 'digital_object_linked_agents__0__role_'
  fill_in 'digital_object_linked_agents__0__title_', with: "Resource #{@uuid} Agent Title"
  fill_in 'digital_object_linked_agents__0__relator_', with: 'annotator'
  dropdown_items = all('.typeahead.typeahead-long.dropdown-menu')
  dropdown_items.first.click
  fill_in 'token-input-digital_object_linked_agents__0__ref_', with: 'test_agent'
  dropdown_items = all('li.token-input-dropdown-item2')
  dropdown_items.first.click

  click_on 'Add Subject'
  fill_in 'token-input-digital_object_subjects__0__ref_', with: 'test_subject'
  dropdown_items = all('li.token-input-dropdown-item2')
  dropdown_items.first.click

  click_on 'Add Classification'
  fill_in 'token-input-digital_object_classifications__0__ref_', with: 'test_classification'
  dropdown_items = all('li.token-input-dropdown-item2')
  dropdown_items.first.click

  click_on 'Save'
  wait_for_ajax

  expect(find('.alert.alert-success.with-hide-alert').text).to have_text "Digital Object Digital Object B #{@uuid} Created"
  @digital_object_second_id = current_url.split('::digital_object_').pop
end

Given 'the Digital Object A is opened in edit mode' do
  visit "#{STAFF_URL}/digital_objects/#{@digital_object_first_id}/edit"
end

When 'the user selects the Digital Object B from the search results in the modal' do
  within '.modal-content' do
    within '#tabledSearchResults' do
      rows = all('tr', text: "Digital Object B #{@uuid}")
      expect(rows.length).to eq 1

      find('input[type="radio"]').click
    end
  end
end

When 'the user filters by text with the Digital Object B title in the modal' do
  within '.modal-content' do
    fill_in 'Filter by text', with: "Digital Object B #{@uuid}"
    find('.search-filter button').click

    rows = []
    checks = 0

    while checks < 5
      checks += 1

      begin
        rows = all('tr', text: "Digital Object B #{@uuid}")
      rescue Selenium::WebDriver::Error::JavascriptError
        sleep 1
      end

      break if rows.length == 1
    end
  end
end

When 'the user fills in and selects the Digital Object B in the merge dropdown form' do
  fill_in 'token-input-merge_ref_', with: "Digital Object B #{@uuid}"
  dropdown_items = all('li.token-input-dropdown-item2')
  dropdown_items.first.click
end

Then 'the Digital Object B is deleted' do
  visit "#{STAFF_URL}/digital_objects/#{@digital_object_second_id}"

  expect(page).to have_text 'Record Not Found'
end

Then 'the following linked records from the Digital Object B are appended to the Digital Object A' do |forms|
  visit "#{STAFF_URL}/digital_objects/#{@digital_object_first_id}/edit"

  forms.raw.each do |form_title|
    form_title = form_title[0]

    section_title = find('h3', text: form_title)
    section = section_title.ancestor('section')
    expect(section[:id]).to_not eq nil

    case form_title
    when 'Agent Links'
      expect(find('#digital_object_linked_agents__0__role_').value).to eq 'creator'
      expect(find('#digital_object_linked_agents__0__title_').value).to eq "Resource #{@uuid} Agent Title"
      expect(find('#digital_object_linked_agents__0__relator_').value).to eq 'Annotator'
      expect(find('#digital_object_linked_agents__0__ref__combobox .token-input-token').text).to include 'test_agent'
    when 'Related Accessions'
      expect(find('#digital_object_related_accessions__0__ref__combobox').text).to include 'test_accession'
    when 'Subjects'
      expect(find('#digital_object_subjects__0_ .token-input-token').text).to include 'test_subject_term'
    when 'Classifications'
      expect(find('#digital_object_classifications__0__ref__combobox').text).to include 'test_classification'
    else
      raise "Invalid form provided: #{form_title}"
    end
  end
end
