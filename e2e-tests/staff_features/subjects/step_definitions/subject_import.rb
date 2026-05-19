# frozen_string_literal: true

When 'the user selects the first Subject from the search results' do
  wait_for_ajax

  find('#results div.lcnaf-result button', match: :first).click
end

Then 'the Subject is listed in the New & Modified Records form' do
  visit current_url

  element = find('#generated_uris .subrecord-form-fields')
  expect(element.text).to eq 'Subject headings'
end
