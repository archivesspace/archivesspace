# frozen_string_literal: true

Given 'the Resource is not suppressed' do
  expect(page).to have_css('button', text: 'Suppress')
end

Given 'the Resource is suppressed' do
  expect(page).to have_css('button', text: 'Suppress')

  click_on 'Suppress'
  within '.modal-content' do
    click_on 'Suppress'
  end

  wait_for_ajax

  expect(current_url).to include "resources/#{@resource_id}"
  expect(page).to have_text "Resource Resource #{@uuid} suppressed"
  expect(page).to have_text 'Resource is suppressed and cannot be edited'
end

Then 'the Resource now is suppressed' do
  wait_for_ajax

  expect(current_url).to include "resources/#{@resource_id}"
  expect(page).to have_text "Resource Resource #{@uuid} suppressed"
  expect(page).to have_text 'Resource is suppressed and cannot be edited'
end

Then 'the Resource now is not suppressed' do
  visit "#{STAFF_URL}/resources/#{@resource_id}/edit"
  expect(current_url).to include "/resources/#{@resource_id}/edit"

  expect(page).to have_css('button', text: 'Suppress')
end

Then 'the Resource cannot be accessed by archivists' do
  visit "#{STAFF_URL}/logout"

  login_archivist

  visit "#{STAFF_URL}/resources/#{@resource_id}"

  expect(page).to have_text 'Record Not Found'
  expect(page).to have_text "The record you've tried to access may no longer exist or you may not have permission to view it."
end

Then 'the Resource can be accessed by archivists' do
  visit "#{STAFF_URL}/logout"

  login_archivist

  visit "#{STAFF_URL}/resources/#{@resource_id}/edit"
  expect(current_url).to include "/resources/#{@resource_id}/edit"
end
