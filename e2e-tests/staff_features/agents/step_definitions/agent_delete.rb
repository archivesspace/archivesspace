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
