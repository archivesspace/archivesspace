# frozen_string_literal: true

Then 'the New Event page is displayed with the Resource linked' do
  expect(find('h2').text).to eq 'New Event Event'
  expect(find('#event_linked_records__0__ref__combobox')).to have_text @uuid
end
