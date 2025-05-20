# frozen_string_literal: true

Given 'an Agent has been created' do
  visit "#{STAFF_URL}/agents/agent_person/new"

  fill_in 'Primary Part of Name', with: "Agent #{@uuid}"
  select 'Local sources', from: 'Source'
  fill_in 'Rest of Name', with: "Agent Rest of Name #{@uuid}"
  check 'Publish'
  click_on 'Save'
  expect(find('.alert.alert-success.with-hide-alert').text).to eq 'Agent Created'
  url_parts = current_url.split('agents/agent_person').pop.split('/')
  url_parts.pop
  @agent_id = url_parts.pop
end

Given 'the Agent appears in the search results list' do
  visit "#{STAFF_URL}/agents"

  fill_in 'filter-text', with: "Agent #{@uuid}"

  within '.search-filter' do
    find('button').click
  end

  search_result_rows = all('#tabledSearchResults tbody tr')
  expect(search_result_rows.length).to eq 1
end

Then 'the Agent is opened in the edit mode' do
  uri = current_url.split('/')

  action = uri.pop
  agent_id = uri.pop

  expect(action).to eq 'edit'
  expect(agent_id).to eq @agent_id
end

Given 'the Agent is opened in edit mode' do
  visit "#{STAFF_URL}/agents/agent_person/#{@agent_id}/edit"
end

Given 'the Agent is opened in the view mode' do
  visit "#{STAFF_URL}/agents/agent_person/#{@agent_id}"
end

Then 'the Primary Part of Name has the original value' do
  visit "#{STAFF_URL}/agents/agent_person/#{@agent_id}/edit"

  expect(page).to have_field('Primary Part of Name', with: "Agent #{@uuid}")
end
