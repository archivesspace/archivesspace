# frozen_string_literal: true

When 'the user selects the first Name from the search results' do
  wait_for_ajax

  find('#results div.lcnaf-result button', match: :first).click
end

When 'the {string} Agent Name is listed in the New & Modified Records form' do |agent_name|
  visit current_url

  element = find('#generated_uris .subrecord-form-fields')
  expect(element.text).to include agent_name
end

When 'a {string} Related Subject is listed in the New & Modified Records form' do |related_subject|
  visit current_url

  element = find('#generated_uris .subrecord-form-fields')
  expect(element.text).to include related_subject
end
