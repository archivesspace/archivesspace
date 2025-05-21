# frozen_string_literal: true

Given 'the user is on the Resource view page' do
  visit "#{STAFF_URL}/resources/#{@resource_id}"

  wait_for_ajax

  expect(current_url).to_not include 'edit'

  url_parts = current_url.split('/')

  last_parts_after_hash = url_parts.last.split('#')
  last_parts_after_hash.pop
  expect(last_parts_after_hash.length).to eq 1
  resource_id = last_parts_after_hash.pop

  url_parts.pop
  entity = url_parts.pop

  expect(entity).to eq 'resources'
  expect(resource_id).to eq @resource_id
end

When 'the user checks the checkbox of the Resource' do
  page.refresh

  find('#multiselect-item').check
  row = find('tr.selected')
  input = row.find('input')
  expect(input.value).to include 'repositories'
  expect(input.value).to include 'resource'

  @resource_id = input.value.split('/').pop
end

Then 'the Resource is deleted' do
  expect(@resource_id).to_not eq nil

  visit "#{STAFF_URL}/resources/#{@resource_id}/edit"

  expect(find('h2').text).to eq 'Record Not Found'

  expected_text = "The record you've tried to access may no longer exist or you may not have permission to view it."
  expect(page).to have_text expected_text
end

Then 'the Resources page is displayed' do
  expect(find('h2').text).to have_text 'Resources'
end

Then 'the user is still on the Resource view page' do
  expect(current_url).to include "resources/#{@resource_id}"
end
