# frozen_string_literal: true

Given 'the New Event page is open for an Accession' do
  click_on 'Add Event'

  within '#form_add_event' do
    click_on 'Add Event'
  end
end

When 'the user links an Agent' do
  select 'Authorizer', from: 'event_linked_agents__0__role_'
  fill_in 'token-input-event_linked_agents__0__ref_', with: 'test_agent'
  dropdown_items = all('li.token-input-dropdown-item2')
  dropdown_items.first.click
end

Then 'the New Event page is displayed with the Accession linked' do
  expect(find('h2').text).to eq 'New Event Event'
  expect(find('#event_linked_records__0__ref__combobox')).to have_text @uuid
end
