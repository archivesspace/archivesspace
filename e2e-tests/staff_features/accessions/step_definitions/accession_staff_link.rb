# frozen_string_literal: true

Given 'the Accession ID is recorded' do
  uri = find('#accession_form')[:'data-update-monitor-record-uri']
  @accession_id = uri.split('/').pop
end

Given 'the user is logged out' do
  visit "#{STAFF_URL}/logout"
end

Given 'a viewer user is logged in' do
  login_viewer
end

When 'the user visits the Accession on the Public Interface' do
  visit "#{PUBLIC_URL}/repositories/#{@repository_id}/accessions/#{@accession_id}"
end

Then 'the Staff Only button is displayed' do
  expect(page).to have_css('#staff-link', visible: true)
end

Then 'the Staff Only button is not displayed' do
  expect(page).not_to have_css('#staff-link')
end

Then 'the Staff Only button opens the edit page' do
  staff_link = find('#staff-link')
  expect(staff_link[:href]).to include('/resolve/edit')
end

Then 'the Staff Only button opens the readonly page' do
  staff_link = find('#staff-link')
  expect(staff_link[:href]).to include('/resolve/readonly')
end
