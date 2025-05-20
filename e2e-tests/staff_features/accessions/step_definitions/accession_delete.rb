# frozen_string_literal: true

Given 'the user is on the Accession view page' do
  visit "#{STAFF_URL}/accessions"

  fill_in 'filter-text', with: @uuid

  within '.search-filter' do
    find('button').click
  end

  table_row = find('tr', text: @uuid, match: :first)

  within table_row do
    click_on 'View'
  end

  input = find('input#uri')
  expect(input.value).to include 'repositories'
  expect(input.value).to include 'accession'

  @accession_id = input.value.split('/').pop
end

When 'the user filters by text with the Accession title' do
  fill_in 'Filter by text', with: @uuid

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

When 'the user checks the checkbox of the Accession' do
  find('#multiselect-item').check

  within '#tabledSearchResults' do
    row = find('tr.selected')

    input = row.find('input')
    expect(input.value).to include 'repositories'
    expect(input.value).to include 'accession'

    @accession_id = input.value.split('/').pop
  end
end

When 'the user confirms the delete action' do
  within '#confirmChangesModal' do
    click_on 'Delete'
  end
end

Then 'the user is still on the Accession view page' do
  expect(find('h2').text).to eq "Accession Title #{@uuid} Accession"
end

Then 'the Accessions page is displayed' do
  expect(find('h2').text).to have_text 'Accessions'
end

Then 'the Accession is deleted' do
  expect(@accession_id).to_not eq nil

  visit "#{STAFF_URL}/accessions/#{@accession_id}/edit"

  expect(find('h2').text).to eq 'Record Not Found'

  expected_text = "The record you've tried to access may no longer exist or you may not have permission to view it."
  expect(page).to have_text expected_text
end
