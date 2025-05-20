# frozen_string_literal: true

Then 'the {string} option is not displayed in the dropdown menu' do |string|
  expect(page).to_not have_text string
end

Then 'the archivist user cannot manage repositories' do
  visit "#{STAFF_URL}/repositories"

  expect(find('h2').text).to eq 'Repositories'

  rows = all('#tabledSearchResults tbody tr')

  expect(rows.length.positive?).to eq true

  within rows[0] do
    click_on 'View'
  end

  respository_id = current_url.split('/').pop
  visit "#{STAFF_URL}/repositories/#{respository_id}/edit"
  expect(page).to have_text 'Unable to Access Page'

  visit "#{STAFF_URL}/repositories/new"
  expect(page).to have_text 'Unable to Access Page'
end
