# frozen_string_literal: true

Given 'two Subjects A & B have been created' do
  visit "#{STAFF_URL}/subjects/new"

  fill_in 'subject_terms__0__term_', with: "subject_term_A_#{@uuid}"
  select 'Art & Architecture Thesaurus', from: 'subject_source_'
  select 'Cultural context', from: 'subject_terms__0__term_type_'

  click_on 'Save'
  expect(find('.alert.alert-success.with-hide-alert').text).to eq 'Subject Created'

  uri_parts = current_url.split('/')
  uri_parts.pop
  @subject_first_id = uri_parts.pop

  visit "#{STAFF_URL}/subjects/new"

  fill_in 'subject_terms__0__term_', with: "subject_term_B_#{@uuid}"
  select 'Art & Architecture Thesaurus', from: 'subject_source_'
  select 'Cultural context', from: 'subject_terms__0__term_type_'

  click_on 'Save'
  expect(find('.alert.alert-success.with-hide-alert').text).to eq 'Subject Created'

  uri_parts = current_url.split('/')
  uri_parts.pop
  @subject_second_id = uri_parts.pop
end

Given 'the Subject A is opened in edit mode' do
  visit "#{STAFF_URL}/subjects/#{@subject_first_id}/edit"
end

When 'the user selects the Subject B from the search results in the modal' do
  within '.modal-content' do
    within '#tabledSearchResults' do
      rows = all('tr', text: "subject_term_B_#{@uuid}")
      expect(rows.length).to eq 1

      rows.first.click
    end
  end
end

When 'the user filters by text with the Subject B title in the modal' do
  within '.modal-content' do
    fill_in 'Filter by text', with: "subject_term_B_#{@uuid}"
    find('.search-filter button').click

    rows = []
    checks = 0

    while checks < 5
      checks += 1

      begin
        rows = all('tr', text: "subject_term_B_#{@uuid}")
      rescue Selenium::WebDriver::Error::JavascriptError
        sleep 1
      end

      break if rows.length == 1
    end
  end
end

When 'the user fills in and selects the Subject B in the merge dropdown form' do
  fill_in 'token-input-merge_ref_', with: "subject_term_B_#{@uuid}"
  dropdown_items = all('li.token-input-dropdown-item2')
  dropdown_items.first.click
end

Then 'the Subject B is deleted' do
  visit "#{STAFF_URL}/subjects/#{@subject_second_id}"

  expect(page).to have_text 'Record Not Found'
end

Then 'the following linked records from the Subject B are appended to the Subject A' do |forms|
  visit "#{STAFF_URL}/subjects/#{@subject_first_id}/edit"

  forms.raw.each do |form_title|
    form_title = form_title[0]

    section_title = find('h3', text: form_title)
    section = section_title.ancestor('section')
    expect(section[:id]).to_not eq nil

    case form_title
    when 'Agent Links'
      expect(find('#subject_linked_agents__0__role_').value).to eq 'creator'
      expect(find('#subject_linked_agents__0__title_').value).to eq "Subject #{@uuid} Agent Title"
      expect(find('#subject_linked_agents__0__relator_').value).to eq 'Annotator'
      expect(find('#subject_linked_agents__0__ref__combobox .token-input-token').text).to include 'test_agent'
    when 'Related Accessions'
      expect(find('#subject_related_accessions__0__ref__combobox').text).to include 'test_accession'
    when 'Subjects'
      expect(find('#subject_subjects__0_ .token-input-token').text).to include 'test_subject_term'
    when 'Classifications'
      expect(find('#subject_classifications__0__ref__combobox').text).to include 'test_classification'
    else
      raise "Invalid form provided: #{form_title}"
    end
  end
end
