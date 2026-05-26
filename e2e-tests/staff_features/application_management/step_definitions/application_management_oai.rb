# frozen_string_literal: true

Given 'the user visits the OAI-PMH endpoint using the verb Identify' do
  visit "#{OAI_URL}/oai?verb=Identify"
end

Given 'an XML response beginning with {string} is displayed' do |expected_string|
  expect(page.body).to include(expected_string)
end
