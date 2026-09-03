# frozen_string_literal: true

When 'the user checks the checkbox of the Agent' do
  find('#multiselect-item').check
end

Then 'the Agent is deleted' do
  expect(@agent_id).to_not eq nil

  visit "#{STAFF_URL}/agents/agent_person/#{@agent_id}/edit"

  expect(find('h2').text).to eq 'Record Not Found'

  expected_text = "The record you've tried to access may no longer exist or you may not have permission to view it."
  expect(page).to have_text expected_text
end

Given 'the user is on the Agent view page' do
  visit "#{STAFF_URL}/agents/agent_person/#{@agent_id}"
end

Then 'the Agents page is displayed' do
  expect(find('h2').text).to have_text 'Agents'
end

Then 'the user is still on the Agent view page' do
  expect(current_url).to include "agents/agent_person/#{@agent_id}"
end

Given 'an Accession with a Linked Agent has been created' do
  visit "#{STAFF_URL}/accessions/new"

  fill_in 'accession_id_0_', with: "Accession #{@uuid}"
  fill_in 'Title', with: "Accession Title #{@uuid}"
  fill_in 'Accession Date', with: ORIGINAL_ACCESSION_DATE
  check 'Publish?'

  click_on 'Add Agent Link'
  select 'Source', from: 'accession_linked_agents__0__role_'
  fill_in 'token-input-accession_linked_agents__0__ref_', with: "Agent #{@uuid}"
  wait_for_ajax
  dropdown_items = all('li.token-input-dropdown-item2')
  dropdown_items.first.click

  click_on 'Save'
  expect(page).to have_text "Accession Accession Title #{@uuid} created"
end
