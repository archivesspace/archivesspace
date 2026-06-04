# frozen_string_literal: true

Given 'the user selects {string} in the List Name dropdown menu' do |string|
  select string, from: 'enum_selector' do
    wait_for_ajax
  end
end

Given 'the value {string} is added to the list' do |string|
  expect(page).to have_css('tbody tr td', text: string)
end
