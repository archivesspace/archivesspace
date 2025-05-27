# frozen_string_literal: true

Given 'the user is on the New Assessment page' do
  visit "#{STAFF_URL}/assessments/new"
end

When 'the user clicks on the Records dropdown' do
  sleep 3

  find_field('Records').find(:xpath, './ancestor::div[1]').find('button', match: :first).click
end

When('the user filters by text with the Digital Object title in the modal') do
  within '.modal-content' do
    find('.text-filter-field.form-control.rounded-left').fill_in with: @uuid

    find('.search-filter button').click
  end
end

When 'the user selects the Digital Object from the search results in the modal' do
  find('tr', text: @uuid, match: :first).click
end

When 'the user clicks on the Surveyed By dropdown' do
  find_field('Surveyed By').find(:xpath, './ancestor::div[1]').find('button', match: :first).click
end

When 'the user filters by text with the Agent name in the modal' do
  within '.modal-content' do
    find('.text-filter-field.form-control.rounded-left').fill_in with: 'test'

    find('.search-filter button').click
  end
end

When('the user selects the Agent from the search results in the modal') do
  rows = all('#tabledSearchResults tbody tr input')
  expect(rows.length).to eq 1
  rows[0].click
end
