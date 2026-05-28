# frozen_string_literal: true

Given 'the user selects {string} in the List Name dropdown menu' do |string|
  select string, from: 'enum_selector'
  wait_for_ajax
end

Given 'the user fills in {string} with {string} in the Create Value modal' do |_label, value|
  within '.modal-content' do
    fill_in 'enumeration[value]', with: value
  end
end

Given 'the value {string} is added to the list' do |string|
  expect(page).to have_css('tbody tr td', text: string)
end
