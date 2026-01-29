# frozen_string_literal: true

Given 'a Subject has been created' do
  visit "#{STAFF_URL}/subjects/new"

  wait_for_ajax

  fill_in 'subject_terms__0__term_', with: "subject_term_#{@uuid}"
  select 'Art & Architecture Thesaurus', from: 'subject_source_'
  select 'Cultural context', from: 'subject_terms__0__term_type_'

  @subject_number_of_external_documents = 0

  click_on 'Save Subject', match: :first
  wait_for_ajax
  expect(page).to have_selector('h2', visible: true, text: "subject_term_#{@uuid}")
  within '#form_messages' do
    expect(page).to have_css('.alert.alert-success.with-hide-alert', text: 'Subject Created')
  end

  uri_parts = current_url.split('/')
  uri_parts.pop
  @subject_id = uri_parts.pop
end

Then 'the two Subjects are displayed sorted by ascending identifier' do
  expect(page).to have_css('#tabledSearchResults tbody tr:first-child', text: @accession_b_uuid)
  expect(page).to have_css('#tabledSearchResults tbody tr:last-child', text: @accession_a_uuid)
end

Then 'the two Subjects are displayed sorted by ascending level' do
  expect(page).to have_css('#tabledSearchResults tbody tr:first-child', text: @accession_b_uuid)
  expect(page).to have_css('#tabledSearchResults tbody tr:last-child', text: @accession_a_uuid)
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
  wait_for_ajax
  fill_in 'subject_terms__0__term_', with: "Subject A #{@subject_a_uuid} #{@shared_subject_uuid}"
  select 'Art & Architecture Thesaurus', from: 'subject_source_'
  select 'Cultural context', from: 'subject_terms__0__term_type_'
  click_on 'Save Subject', match: :first
  wait_for_ajax
  expect(page).to have_selector('h2', visible: true, text: "Subject A #{@subject_a_uuid} #{@shared_subject_uuid}")

  within '#form_messages' do
    expect(page).to have_css('.alert.alert-success.with-hide-alert', text: 'Subject Created')
  end
  uri_parts = current_url.split('/')
  uri_parts.pop
  @subject_a_id = uri_parts.pop

  visit "#{STAFF_URL}/subjects/new"
  wait_for_ajax
  fill_in 'subject_terms__0__term_', with: "Subject B #{@subject_b_uuid} #{@shared_subject_uuid}"
  select 'Art & Architecture Thesaurus', from: 'subject_source_'
  select 'Cultural context', from: 'subject_terms__0__term_type_'
  click_on 'Save Subject', match: :first
  wait_for_ajax
  expect(page).to have_selector('h2', visible: true, text: "Subject B #{@subject_b_uuid} #{@shared_subject_uuid}")
  within '#form_messages' do
    expect(page).to have_css('.alert.alert-success.with-hide-alert', text: 'Subject Created')
  end
  uri_parts = current_url.split('/')
  uri_parts.pop
  @subject_b_id = uri_parts.pop
end

Then 'the Subject is in the search results' do
  expect(page).to have_css('tr', text: @uuid)
end

Then 'the two Subjects are displayed sorted by descending title' do
  expect(page).to have_css('#tabledSearchResults tbody tr:first-child', text: @subject_b_uuid)
  expect(page).to have_css('#tabledSearchResults tbody tr:last-child', text: @subject_a_uuid)
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

  expect(page).to have_css('#tabledSearchResults tbody tr:first-child', text: @subject_a_uuid)
  expect(page).to have_css('#tabledSearchResults tbody tr:last-child', text: @subject_b_uuid)
end

Then 'the two Subjects are displayed sorted by descending term' do
  expect(page).to have_css('#tabledSearchResults tbody tr:first-child', text: @subject_b_uuid)
  expect(page).to have_css('#tabledSearchResults tbody tr:last-child', text: @subject_a_uuid)
end

Then 'the two Subjects are displayed sorted by ascending created date' do
  expect(page).to have_css('#tabledSearchResults tbody tr:first-child', text: @subject_a_uuid)
  expect(page).to have_css('#tabledSearchResults tbody tr:last-child', text: @subject_b_uuid)
end

Then 'the two Subjects are displayed sorted by ascending modified date' do
  expect(page).to have_css('#tabledSearchResults tbody tr:first-child', text: @subject_a_uuid)
  expect(page).to have_css('#tabledSearchResults tbody tr:last-child', text: @subject_b_uuid)
end
