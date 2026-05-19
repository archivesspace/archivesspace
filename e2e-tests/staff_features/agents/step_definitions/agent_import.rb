# frozen_string_literal: true

When 'the user selects the first Name from the search results' do
  wait_for_ajax

  find('#results div.lcnaf-result button', match: :first).click
end

When 'the Agent Name is listed in the New & Modified Records form' do
  visit current_url

  element = find('#generated_uris .subrecord-form-fields')
  expect(element.text).to include 'Hutson, Jean Blackwell'
end

When 'a Related Subject is listed in the New & Modified Records form' do
    visit current_url

  element = find('#generated_uris .subrecord-form-fields')
  expect(element.text).to include 'Library science'
end
