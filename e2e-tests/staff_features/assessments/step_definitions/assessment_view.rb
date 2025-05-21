# frozen_string_literal: true

Given 'an Assessment has been created' do
  visit "#{STAFF_URL}/accessions/new"
  fill_in 'accession_id_0_', with: "Accession #{@uuid}"
  click_on 'Save'
  expect(page).to have_text "Accession #{@uuid}"

  visit "#{STAFF_URL}/assessments/new"
  fill_in 'token-input-assessment_records_', with: "Accession #{@uuid}"
  dropdown_items = all('li.token-input-dropdown-item2')
  dropdown_items.first.click

  fill_in 'token-input-assessment_surveyed_by_', with: 'test'
  dropdown_items = all('li.token-input-dropdown-item2')
  dropdown_items.first.click

  click_on 'Save'
  expect(find('.alert.alert-success.with-hide-alert').text).to eq 'Assessment Created'
  url_parts = current_url.split('assessments').pop.split('/')
  url_parts.pop
  @assessment_id = url_parts.pop
end

When 'the user filters by text with the Assessment record' do
  fill_in 'Filter by text', with: "Accession #{@uuid}"

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

Given 'two Assessments have been created with a common keyword in their record' do
  @shared_accession_uuid = SecureRandom.uuid
  @accession_a_uuid = SecureRandom.uuid
  @accession_b_uuid = SecureRandom.uuid

  visit "#{STAFF_URL}/accessions/new"
  fill_in 'accession_id_0_', with: 'Accession A'
  fill_in 'accession_id_1_', with: @accession_a_uuid
  fill_in 'accession_id_2_', with: @shared_accession_uuid
  click_on 'Save'
  expect(find('.alert.alert-success.with-hide-alert').text).to eq 'Accession created'

  visit "#{STAFF_URL}/accessions/new"
  fill_in 'accession_id_0_', with: 'Accession B'
  fill_in 'accession_id_1_', with: @accession_b_uuid
  fill_in 'accession_id_2_', with: @shared_accession_uuid
  click_on 'Save'
  expect(find('.alert.alert-success.with-hide-alert').text).to eq 'Accession created'

  visit "#{STAFF_URL}/assessments/new"
  fill_in 'token-input-assessment_records_', with: "Accession A-#{@accession_a_uuid}-#{@shared_accession_uuid}"
  dropdown_items = all('li.token-input-dropdown-item2')
  dropdown_items.first.click

  fill_in 'token-input-assessment_surveyed_by_', with: 'test'
  dropdown_items = all('li.token-input-dropdown-item2')
  dropdown_items.first.click

  click_on 'Save'
  expect(find('.alert.alert-success.with-hide-alert').text).to eq 'Assessment Created'
  url_parts = current_url.split('assessments').pop.split('/')
  url_parts.pop
  @assessment_a_id = url_parts.pop

  visit "#{STAFF_URL}/assessments/new"
  fill_in 'token-input-assessment_records_', with: "Accession A-#{@accession_a_uuid}-#{@shared_accession_uuid}"
  dropdown_items = all('li.token-input-dropdown-item2')
  dropdown_items.first.click

  fill_in 'token-input-assessment_surveyed_by_', with: 'test'
  dropdown_items = all('li.token-input-dropdown-item2')
  dropdown_items.first.click

  click_on 'Save'
  expect(find('.alert.alert-success.with-hide-alert').text).to eq 'Assessment Created'
  url_parts = current_url.split('assessments').pop.split('/')
  url_parts.pop
  @assessment_b_id = url_parts.pop
end

Then 'the Assessment is in the search results' do
  expect(page).to have_css('tr', text: @assessment_id)
end

Then 'the Assessment view page is displayed' do
  expect(find('h2').text).to eq "Assessment #{@assessment_id} Assessment"
  expect(current_url).to eq "#{STAFF_URL}/assessments/#{@assessment_id}"
end

Given 'the two Assessments are displayed sorted by ascending record in the search results' do
  visit "#{STAFF_URL}/assessments"

  fill_in 'filter-text', with: @shared_accession_uuid

  within '.search-filter' do
    find('button').click
  end

  search_result_rows = all('#tabledSearchResults tbody tr')

  expect(search_result_rows.length).to eq 2
  expect(search_result_rows[0]).to have_text @assessment_a_uuid
  expect(search_result_rows[1]).to have_text @assessment_b_uuid
end

Then('the two Assessments are displayed sorted by ascending ID') do
  search_result_rows = all('#tabledSearchResults tbody tr')

  expect(search_result_rows.length).to eq 2
  expect(search_result_rows[0]).to have_text @assessment_a_uuid
  expect(search_result_rows[1]).to have_text @assessment_b_uuid
end
