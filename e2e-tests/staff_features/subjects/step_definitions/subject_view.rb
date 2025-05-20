# frozen_string_literal: true

Given 'a Subject has been created' do
  visit "#{STAFF_URL}/subjects/new"

  fill_in 'subject_terms__0__term_', with: "subject_term_#{@uuid}"
  select 'Art & Architecture Thesaurus', from: 'subject_source_'
  select 'Cultural context', from: 'subject_terms__0__term_type_'

  @subject_number_of_external_documents = 0

  click_on 'Save'
  expect(find('.alert.alert-success.with-hide-alert').text).to eq 'Subject Created'

  uri_parts = current_url.split('/')
  uri_parts.pop
  @subject_id = uri_parts.pop
end

Then 'the two Subjects are displayed sorted by ascending identifier' do
  search_result_rows = all('#tabledSearchResults tbody tr')

  expect(search_result_rows.length).to eq 2
  expect(search_result_rows[1]).to have_text @accession_a_uuid
  expect(search_result_rows[0]).to have_text @accession_b_uuid
end

Then 'the two Subjects are displayed sorted by ascending level' do
  search_result_rows = all('#tabledSearchResults tbody tr')

  expect(search_result_rows.length).to eq 2
  expect(search_result_rows[1]).to have_text @accession_a_uuid
  expect(search_result_rows[0]).to have_text @accession_b_uuid
end

When 'the user filters by text with the Subject term' do
  fill_in 'Filter by text', with: "subject_term_#{@uuid}"

  find('#filter-text').send_keys(:enter)

  rows = []
  checks = 0

  while checks < 5
    checks += 1

    begin
      rows = all('tr', text: @uuid)
    rescue Selenium::WebDriver::Error::JavascriptError
      sleep 1
    end

    break if rows.length == 1
  end
end

Given 'two Subjects have been created with a common keyword in their term' do
  @shared_subject_uuid = SecureRandom.uuid
  @subject_a_uuid = SecureRandom.uuid
  @subject_b_uuid = SecureRandom.uuid

  visit "#{STAFF_URL}/subjects/new"
  fill_in 'subject_terms__0__term_', with: "Subject A #{@subject_a_uuid} #{@shared_subject_uuid}"
  select 'Art & Architecture Thesaurus', from: 'subject_source_'
  select 'Cultural context', from: 'subject_terms__0__term_type_'
  click_on 'Save'
  expect(find('.alert.alert-success.with-hide-alert').text).to eq 'Subject Created'
  uri_parts = current_url.split('/')
  uri_parts.pop
  @subject_a_id = uri_parts.pop

  visit "#{STAFF_URL}/subjects/new"
  fill_in 'subject_terms__0__term_', with: "Subject B #{@subject_b_uuid} #{@shared_subject_uuid}"
  select 'Art & Architecture Thesaurus', from: 'subject_source_'
  select 'Cultural context', from: 'subject_terms__0__term_type_'
  click_on 'Save'
  expect(find('.alert.alert-success.with-hide-alert').text).to eq 'Subject Created'
  uri_parts = current_url.split('/')
  uri_parts.pop
  @subject_b_id = uri_parts.pop
end

Then 'the Subject is in the search results' do
  expect(page).to have_css('tr', text: @uuid)
end

Then 'the two Subjects are displayed sorted by descending title' do
  search_result_rows = all('#tabledSearchResults tbody tr')

  expect(search_result_rows.length).to eq 2
  expect(search_result_rows[1]).to have_text @subject_a_uuid
  expect(search_result_rows[0]).to have_text @subject_b_uuid
end

Then 'the Subject view page is displayed' do
  expect(find('h2').text).to eq "subject_term_#{@uuid} Subject"
  expect(current_url).to eq "#{STAFF_URL}/subjects/#{@subject_id}"
end

Given 'the two Subjects are displayed sorted by ascending term' do
  visit "#{STAFF_URL}/subjects"

  fill_in 'filter-text', with: @shared_subject_uuid

  within '.search-filter' do
    find('button').click
  end

  search_result_rows = all('#tabledSearchResults tbody tr')

  expect(search_result_rows.length).to eq 2
  expect(search_result_rows[0]).to have_text @subject_a_uuid
  expect(search_result_rows[1]).to have_text @subject_b_uuid
end

Then 'the two Subjects are displayed sorted by descending term' do
  search_result_rows = all('#tabledSearchResults tbody tr')

  expect(search_result_rows.length).to eq 2
  expect(search_result_rows[1]).to have_text @subject_a_uuid
  expect(search_result_rows[0]).to have_text @subject_b_uuid
end

Then 'the two Subjects are displayed sorted by ascending created date' do
  search_result_rows = all('#tabledSearchResults tbody tr')

  expect(search_result_rows.length).to eq 2
  expect(search_result_rows[0]).to have_text @subject_a_uuid
  expect(search_result_rows[1]).to have_text @subject_b_uuid
end

Then 'the two Subjects are displayed sorted by ascending modified date' do
  search_result_rows = all('#tabledSearchResults tbody tr')

  expect(search_result_rows.length).to eq 2
  expect(search_result_rows[0]).to have_text @subject_a_uuid
  expect(search_result_rows[1]).to have_text @subject_b_uuid
end
