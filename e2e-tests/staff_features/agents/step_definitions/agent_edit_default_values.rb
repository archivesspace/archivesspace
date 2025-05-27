# frozen_string_literal: true

Given 'the user is on the Agents page' do
  visit "#{STAFF_URL}/agents"
end

Given 'an Agent Person has been created' do
  visit "#{STAFF_URL}/agents/agent_person/new"

  fill_in 'Primary Part of Name', with: "Agent #{@uuid}", match: :first
  click_on 'Save'

  expect(find('.alert.alert-success.with-hide-alert').text).to eq 'Agent Created'
  url_parts = current_url.split('agents/agent_person').pop.split('/')
  url_parts.pop
  @agent_id = url_parts.pop
end

Given 'an Agent Family has been created' do
  visit "#{STAFF_URL}/agents/agent_family/new"

  fill_in 'Family Name', with: "Agent #{@uuid}"

  click_on 'Save'

  expect(find('.alert.alert-success.with-hide-alert').text).to eq 'Agent Created'
  url_parts = current_url.split('agents/agent_person').pop.split('/')
  url_parts.pop
  @agent_id = url_parts.pop
end

Given 'an Agent Corporate Entity has been created' do
  visit "#{STAFF_URL}/agents/agent_corporate_entity/new"

  fill_in 'Primary Part of Name', with: "Agent #{@uuid}", match: :first
  click_on 'Save'

  expect(find('.alert.alert-success.with-hide-alert').text).to eq 'Agent Created'
  url_parts = current_url.split('agents/agent_person').pop.split('/')
  url_parts.pop
  @agent_id = url_parts.pop
end

Given 'an Agent Software has been created' do
  visit "#{STAFF_URL}/agents/agent_software/new"

  fill_in 'Software Name', with: "Agent #{@uuid}"
  click_on 'Save'

  expect(find('.alert.alert-success.with-hide-alert').text).to eq 'Agent Created'
  url_parts = current_url.split('agents/agent_person').pop.split('/')
  url_parts.pop
  @agent_id = url_parts.pop
end

Then 'the new Agent Person form has the following default values' do |form_values_table|
  visit "#{STAFF_URL}/agents/agent_person/new"

  expect_form_values(form_values_table)
end

Then 'the new Agent Family form has the following default values' do |form_values_table|
  visit "#{STAFF_URL}/agents/agent_family/new"

  expect_form_values(form_values_table)
end

Then 'the new Agent Corporate Entity form has the following default values' do |form_values_table|
  visit "#{STAFF_URL}/agents/agent_corporate_entity/new"

  expect_form_values(form_values_table)
end

Then 'the new Agent Software form has the following default values' do |form_values_table|
  visit "#{STAFF_URL}/agents/agent_software/new"

  expect_form_values(form_values_table)
end
