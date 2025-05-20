# frozen_string_literal: true

Then 'the Accession is in the search results' do
  expect(page).to have_css('tr', text: @uuid)
end

Then 'the Accession view page is displayed' do
  expect(find('h2').text).to eq "Accession Title #{@uuid} Accession"
end

Given 'two Accessions have been created with a common keyword in their title' do
  @shared_accession_uuid = SecureRandom.uuid
  @accession_a_uuid = SecureRandom.uuid
  @accession_b_uuid = SecureRandom.uuid

  visit "#{STAFF_URL}/accessions/new"
  fill_in 'accession_title_', with: "Accession A #{@accession_a_uuid} #{@shared_accession_uuid}"
  fill_in 'accession_id_0_', with: "Accession A #{@accession_a_uuid}"
  click_on 'Save'

  visit "#{STAFF_URL}/accessions/new"
  fill_in 'accession_title_', with: "Accession B #{@accession_b_uuid} #{@shared_accession_uuid}"
  fill_in 'accession_id_0_', with: "Accession B #{@accession_b_uuid}"
  click_on 'Save'
end

Given 'the two Accessions are displayed sorted by ascending title' do
  visit "#{STAFF_URL}/accessions"

  fill_in 'filter-text', with: @shared_accession_uuid

  within '.search-filter' do
    find('button').click
  end

  search_result_rows = all('#tabledSearchResults tbody tr')

  expect(search_result_rows.length).to eq 2
  expect(search_result_rows[0]).to have_text @accession_a_uuid
  expect(search_result_rows[1]).to have_text @accession_b_uuid
end

Then 'the two Accessions are displayed sorted by descending title' do
  search_result_rows = all('#tabledSearchResults tbody tr')

  expect(search_result_rows.length).to eq 2
  expect(search_result_rows[1]).to have_text @accession_a_uuid
  expect(search_result_rows[0]).to have_text @accession_b_uuid
end
