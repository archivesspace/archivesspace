# frozen_string_literal: true

Given 'two Agents A & B have been created' do
  visit "#{STAFF_URL}/agents/agent_person/new"

  fill_in 'Primary Part of Name', with: "Agent A #{@uuid}"
  fill_in 'Rest of Name', with: 'Rest of Name A'
  find('button', text: 'Save Person', match: :first).click
  expect(page).to have_text 'Agent Created'

  uri_parts = current_url.split('/')
  uri_parts.pop
  @agent_first_id = uri_parts.pop

  visit "#{STAFF_URL}/agents/agent_person/new"

  fill_in 'Primary Part of Name', with: "Agent B #{@uuid}"
  fill_in 'Rest of Name', with: 'Rest of Name B'
  find('button', text: 'Save Person', match: :first).click
  expect(page).to have_text 'Agent Created'

  uri_parts = current_url.split('/')
  uri_parts.pop
  @agent_second_id = uri_parts.pop
end

Given 'the Agent A is opened in edit mode' do
  visit "#{STAFF_URL}/agents/agent_person/#{@agent_first_id}/edit"
end

When 'the user selects the Agent B from the search results in the modal' do
  within '.modal-content' do
    within '#tabledSearchResults' do
      rows = all('tr', text: "Agent B #{@uuid}")
      expect(rows.length).to eq 1

      rows[0].click
    end
  end
end

When 'the user filters by text with the Agent B name in the modal' do
  within '.modal-content' do
    fill_in 'Filter by text', with: "Agent B #{@uuid}"
    find('.search-filter button').click

    rows = []
    checks = 0

    while checks < 5
      checks += 1

      begin
        rows = all('tr', text: "Agent B #{@uuid}")
      rescue Selenium::WebDriver::Error::JavascriptError
        sleep 1
      end

      break if rows.length == 1
    end
  end
end

When 'the user fills in and selects the Agent B in the merge dropdown form' do
  fill_in 'token-input-merge_ref_', with: "Agent B #{@uuid}"
  dropdown_items = all('li.token-input-dropdown-item2')
  dropdown_items.first.click
end

Then 'the Agent B is deleted' do
  visit "#{STAFF_URL}/resources/#{@agent_second_id}"

  expect(page).to have_text 'Record Not Found'
end

When 'the user clicks on {string} in the Compare Agents form' do |text|
  tries = 0

  loop do
    buttons = all('button', text: text, match: :first)

    buttons.each do |button|
      if button.text == text
        button.click
        break
      end
    end

    break
  rescue Capybara::ElementNotFound => e
    tries += 1
    sleep 1

    raise e if tries == 5
  end
end
