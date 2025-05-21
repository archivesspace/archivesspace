# frozen_string_literal: true

Given 'an Event has been created' do
  visit "#{STAFF_URL}/events/new"

  fill_in 'Outcome', with: @uuid

  within '#event_date' do
    select 'Single', from: 'Type'
    fill_in 'Begin', with: '2020-01-01'
  end

  select 'Authorizer', from: 'event_linked_agents__0__role_'

  fill_in 'token-input-event_linked_agents__0__ref_', with: 'test_agent'
  dropdown_items = all('li.token-input-dropdown-item2')
  dropdown_items.first.click

  select 'Outcome', from: 'event_linked_records__0__role_'
  fill_in 'token-input-event_linked_records__0__ref_', with: 'test_accession'
  dropdown_items = all('li.token-input-dropdown-item2')
  dropdown_items.first.click

  find('button', text: 'Save Event', match: :first).click
  expect(find('.alert.alert-success').text).to eq 'Event Created'

  url_parts = current_url.split('events').pop.split('/')
  url_parts.pop
  @event_id = url_parts.pop
end

Given 'the Event appears in the search results list' do
  visit "#{STAFF_URL}/events"

  fill_in 'filter-text', with: @uuid

  within '.search-filter' do
    find('button').click
  end

  search_result_rows = all('#tabledSearchResults tbody tr')
  expect(search_result_rows.length).to eq 1
end

Given 'the Event is opened in edit mode' do
  visit "#{STAFF_URL}/events/#{@event_id}/edit"
end

Then 'the Event is opened in the edit mode' do
  expect(current_url).to eq "#{STAFF_URL}/events/#{@event_id}/edit"
end

Given 'the Event is opened in the view mode' do
  visit "#{STAFF_URL}/events/#{@event_id}"
end

When 'the user clears the {string} field at {string} form' do |_string, _string2|
  pending # Write code here that turns the phrase above into concrete actions
end

Then 'the Event Type field has the original value' do
  visit "#{STAFF_URL}/events/#{@event_id}/edit"

  field = find_field('Type', match: :first)

  expect(field.value).to eq 'accession'
end

Given 'the user is on the Events page' do
  visit "#{STAFF_URL}/events"
end

Then 'the new Event form has the following default values' do |form_values_table|
  visit "#{STAFF_URL}/events/new"

  expect_form_values(form_values_table)
end
