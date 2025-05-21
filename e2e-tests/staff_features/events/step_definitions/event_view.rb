# frozen_string_literal: true

When 'the user filters by text with the Event record link title' do
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

Then 'the Event view page is displayed' do
  expect(current_url).to eq "#{STAFF_URL}/events/#{@event_id}"
end

Then 'the Event is in the search results' do
  expect(page).to have_css('tr', text: 'test_agent')
end

Given 'two Events have been created with a common keyword in their record link title' do
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

  visit "#{STAFF_URL}/events/new"
  fill_in 'Outcome Note', with: "A #{@shared_accession_uuid}"
  within '#event_date' do
    select 'Single', from: 'Type'
    fill_in 'Begin', with: '2020-01-01'
  end
  select 'Authorizer', from: 'event_linked_agents__0__role_'
  fill_in 'token-input-event_linked_agents__0__ref_', with: 'test_agent'
  dropdown_items = all('li.token-input-dropdown-item2')
  dropdown_items.first.click
  select 'Outcome', from: 'event_linked_records__0__role_'
  fill_in 'token-input-event_linked_records__0__ref_', with: "Accession A #{@accession_a_uuid} #{@shared_accession_uuid}"
  dropdown_items = all('li.token-input-dropdown-item2')
  dropdown_items.first.click
  find('button', text: 'Save Event', match: :first).click
  expect(find('.alert.alert-success').text).to eq 'Event Created'
  url_parts = current_url.split('events').pop.split('/')
  url_parts.pop
  @event_first_id = url_parts.pop

  visit "#{STAFF_URL}/events/new"
  fill_in 'Outcome Note', with: "B #{@shared_accession_uuid}"
  within '#event_date' do
    select 'Single', from: 'Type'
    fill_in 'Begin', with: '2020-01-01'
  end
  select 'Authorizer', from: 'event_linked_agents__0__role_'
  fill_in 'token-input-event_linked_agents__0__ref_', with: 'test_agent'
  dropdown_items = all('li.token-input-dropdown-item2')
  dropdown_items.first.click
  select 'Outcome', from: 'event_linked_records__0__role_'
  fill_in 'token-input-event_linked_records__0__ref_', with: "Accession B #{@accession_b_uuid} #{@shared_accession_uuid}"
  dropdown_items = all('li.token-input-dropdown-item2')
  dropdown_items.first.click
  select 'Accumulation', from: 'event_event_type_'
  find('button', text: 'Save Event', match: :first).click
  expect(find('.alert.alert-success').text).to eq 'Event Created'
  url_parts = current_url.split('events').pop.split('/')
  url_parts.pop
  @event_first_id = url_parts.pop
end

Then 'the two Events are displayed sorted by descending type' do
  search_result_rows = all('#tabledSearchResults tbody tr')

  expect(search_result_rows.length).to eq 2
  expect(search_result_rows[1]).to have_text @accession_a_uuid
  expect(search_result_rows[0]).to have_text @accession_b_uuid
end

Then 'the two Events are displayed sorted by ascending outcome' do
  search_result_rows = all('#tabledSearchResults tbody tr')

  expect(search_result_rows.length).to eq 2
  expect(search_result_rows[0]).to have_text @accession_a_uuid
  expect(search_result_rows[1]).to have_text @accession_b_uuid
end

Then 'the two Events are displayed sorted by ascending created date' do
  search_result_rows = all('#tabledSearchResults tbody tr')

  expect(search_result_rows.length).to eq 2
  expect(search_result_rows[0]).to have_text @accession_a_uuid
  expect(search_result_rows[1]).to have_text @accession_b_uuid
end

Then 'the two Events are displayed sorted by ascending modified date' do
  search_result_rows = all('#tabledSearchResults tbody tr')

  expect(search_result_rows.length).to eq 2
  expect(search_result_rows[0]).to have_text @accession_a_uuid
  expect(search_result_rows[1]).to have_text @accession_b_uuid
end

Given 'the two Events are displayed sorted by ascending type' do
  visit "#{STAFF_URL}/events"

  fill_in 'filter-text', with: @shared_accession_uuid

  within '.search-filter' do
    find('button').click
  end

  search_result_rows = all('#tabledSearchResults tbody tr')

  expect(search_result_rows.length).to eq 2
  expect(search_result_rows[0]).to have_text @accession_a_uuid
  expect(search_result_rows[1]).to have_text @accession_b_uuid
end
