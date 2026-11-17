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
    submit_listing_filter(@uuid)
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
    submit_listing_filter('test')
  end
end

When('the user selects the Agent from the search results in the modal') do
  expect(page).to have_css('#tabledSearchResults tbody tr input', count: 1)
  find('#tabledSearchResults tbody tr input').click
end

When 'the user selects the Resource from the search results in the modal' do
  find('tr', text: "Resource #{@uuid}", match: :first).click
end

When('the user filters by text with the Resource title in the modal') do
  within '.modal-content' do
    submit_listing_filter("Resource #{@uuid}")
  end
end

When('the user filters by text with the Archival Object title in the modal') do
  within '.modal-content' do
    submit_listing_filter("Archival Object #{@uuid}")
  end
end

When 'the user selects the Archival Object from the search results in the modal' do
  find('tr', text: "Archival Object #{@uuid}", match: :first).click
end
