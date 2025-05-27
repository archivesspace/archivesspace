# frozen_string_literal: true

When 'the user fills in {string} with the Accession title' do |label|
  fill_in label, with: @uuid
end

Then 'the Top Container associated with the Resource is in the search results' do
  results = all('#bulk_operation_results tbody tr')
  expect(results.length).to eq 1
  expect(results[0].text).to include @uuid
end

Then 'the Top Container associated with the Accession is in the search results' do
  results = all('#bulk_operation_results tbody tr')
  expect(results.length).to eq 1
  expect(results[0].text).to include @uuid
end

Given 'the user is on the Top Containers page' do
  visit "#{STAFF_URL}/top_containers"
end

Then 'the Top Container view page is displayed' do
  expect(find('h2').text).to eq "#{@uuid} Top Container"
  expect(current_url).to eq "#{STAFF_URL}/top_containers/#{@top_container_id}"
end

Then 'the Top Container is opened in the edit mode' do
  uri = current_url.split('/')

  action = uri.pop
  top_container_id = uri.pop

  expect(action).to eq 'edit'
  expect(top_container_id).to eq @top_container_id
end

Given 'the user is on the Top Container view page' do
  visit "#{STAFF_URL}/top_containers/#{@top_container_id}"
end

Given 'the Top Container is opened in edit mode' do
  visit "#{STAFF_URL}/top_containers/#{@top_container_id}/edit"
end

Then 'the Indicator field has the original value' do
  visit "#{STAFF_URL}/top_containers/#{@top_container_id}/edit"

  expect(page).to have_field('Indicator', with: @uuid)
end

When 'the user selects the Test Location in the modal' do
  find('td', text: 'test_location', match: :first).click
end

Then 'the location is added to the Top Container' do
  expect(page).to have_text('test_location')
end

Then 'the Top Containers page is displayed' do
  expect(current_url).to include "#{STAFF_URL}/top_containers"
end

Then 'the Top Container is deleted' do
  expect(@top_container_id).to_not eq nil

  visit "#{STAFF_URL}/top_containers/#{@top_container_id}/edit"

  expect(find('h2').text).to eq 'Record Not Found'

  expected_text = "The record you've tried to access may no longer exist or you may not have permission to view it."
  expect(page).to have_text expected_text
end

Then 'the user is still on the Top Container view page' do
  expect(current_url).to include "top_containers/#{@top_container_id}"
end

Then 'the user is still on the Top Container edit page' do
  expect(current_url).to eq "#{STAFF_URL}/top_containers/#{@top_container_id}/edit"
end
