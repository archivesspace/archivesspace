# frozen_string_literal: true

Given 'two Agents have been created with a common keyword in their name' do
  @shared_agent_uuid = SecureRandom.uuid
  @agent_a_uuid = SecureRandom.uuid
  @agent_b_uuid = SecureRandom.uuid

  visit "#{STAFF_URL}/agents/agent_person/new"
  fill_in 'Primary Part of Name', with: "A #{@agent_a_uuid} #{@shared_agent_uuid}"
  fill_in 'Authority ID', with: "A #{@agent_a_uuid} #{@shared_agent_uuid}"
  select 'Local sources', from: 'Source'
  select 'Anglo-American Cataloging Rules', from: 'Rules'
  fill_in 'Rest of Name', with: 'Rest of name A'
  click_on 'Save'
  expect(find('.alert.alert-success.with-hide-alert').text).to eq 'Agent Created'
  url_parts = current_url.split('agents/agent_person').pop.split('/')
  url_parts.pop
  @agent_a_id = url_parts.pop

  visit "#{STAFF_URL}/agents/agent_person/new"
  fill_in 'Primary Part of Name', with: "B #{@agent_b_uuid} #{@shared_agent_uuid}"
  fill_in 'Authority ID', with: "B #{@agent_b_uuid} #{@shared_agent_uuid}"
  select 'NAD / ARK II Name Authority Database', from: 'Source'
  select 'Describing Archives: A Content Standard', from: 'Rules'
  fill_in 'Rest of Name', with: 'Rest of name B'
  click_on 'Save'
  expect(find('.alert.alert-success.with-hide-alert').text).to eq 'Agent Created'
  url_parts = current_url.split('agents/agent_person').pop.split('/')
  url_parts.pop
  @agent_b_id = url_parts.pop
end

Given 'the two Agents are displayed sorted by ascending name' do
  visit "#{STAFF_URL}/agents"

  fill_in 'filter-text', with: @shared_agent_uuid

  within '.search-filter' do
    find('button').click
  end

  search_result_rows = all('#tabledSearchResults tbody tr')

  expect(search_result_rows.length).to eq 2
  expect(search_result_rows[0]).to have_text @agent_a_uuid
  expect(search_result_rows[1]).to have_text @agent_b_uuid
end

Then 'the two Agents are displayed sorted by descending name' do
  search_result_rows = all('#tabledSearchResults tbody tr')

  expect(search_result_rows.length).to eq 2
  expect(search_result_rows[1]).to have_text @agent_a_uuid
  expect(search_result_rows[0]).to have_text @agent_b_uuid
end

Then 'the two Agents are displayed sorted by ascending type' do
  search_result_rows = all('#tabledSearchResults tbody tr')

  expect(search_result_rows.length).to eq 2
  expect(search_result_rows[0]).to have_text "A #{@agent_a_uuid} #{@shared_agent_uuid}, Rest of name A"
  expect(search_result_rows[1]).to have_text "B #{@agent_b_uuid} #{@shared_agent_uuid}, Rest of name B"
end

Then 'the two Agents are displayed sorted by ascending level' do
  search_result_rows = all('#tabledSearchResults tbody tr')

  expect(search_result_rows.length).to eq 2
  expect(search_result_rows[1]).to have_text @agent_a_uuid
  expect(search_result_rows[0]).to have_text @agent_b_uuid
end

Then 'the two Agents are displayed sorted by ascending Authority ID' do
  search_result_rows = all('#tabledSearchResults tbody tr')

  expect(search_result_rows.length).to eq 2
  expect(search_result_rows[0]).to have_text @agent_a_uuid
  expect(search_result_rows[1]).to have_text @agent_b_uuid
end

Then 'the two Agents are displayed sorted by ascending source' do
  search_result_rows = all('#tabledSearchResults tbody tr')

  expect(search_result_rows.length).to eq 2
  expect(search_result_rows[0]).to have_text @agent_a_uuid
  expect(search_result_rows[1]).to have_text @agent_b_uuid
end

Then 'the two Agents are displayed sorted by ascending rule' do
  search_result_rows = all('#tabledSearchResults tbody tr')

  expect(search_result_rows.length).to eq 2
  expect(search_result_rows[0]).to have_text @agent_a_uuid
  expect(search_result_rows[1]).to have_text @agent_b_uuid
end

Then 'the two Agents are displayed sorted by ascending created date' do
  search_result_rows = all('#tabledSearchResults tbody tr')

  expect(search_result_rows.length).to eq 2
  expect(search_result_rows[0]).to have_text @agent_a_uuid
  expect(search_result_rows[1]).to have_text @agent_b_uuid
end

Then 'Sort Agents by modified date' do
  search_result_rows = all('#tabledSearchResults tbody tr')

  expect(search_result_rows.length).to eq 2
  expect(search_result_rows[0]).to have_text @agent_a_uuid
  expect(search_result_rows[1]).to have_text @agent_b_uuid
end

Then 'the two Agents are displayed sorted by ascending modified date' do
  search_result_rows = all('#tabledSearchResults tbody tr')

  expect(search_result_rows.length).to eq 2
  expect(search_result_rows[0]).to have_text @agent_a_uuid
  expect(search_result_rows[1]).to have_text @agent_b_uuid
end

When 'the user filters by text with the Agent name' do
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

Then 'the Agent is in the search results' do
  expect(page).to have_css('tr', text: @uuid)
end

Then 'the Agent view page is displayed' do
  expect(current_url).to eq "#{STAFF_URL}/agents/agent_person/#{@agent_id}"
end
