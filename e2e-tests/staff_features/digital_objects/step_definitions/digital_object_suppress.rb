# frozen_string_literal: true

Given 'the Digital Object is not suppressed' do
  expect(page).to have_css('button', text: 'Suppress')
end

Given 'the Digital Object is suppressed' do
  expect(page).to have_css('button', text: 'Suppress')

  click_on 'Suppress'
  within '.modal-content' do
    click_on 'Suppress'
  end

  expect(current_url).to include "digital_objects/#{@digital_object_id}"
  expect(page).to have_text "Digital Object Digital Object Title #{@uuid} suppressed"
  expect(page).to have_text 'Digital Object is suppressed and cannot be edited'
end

Then 'the Digital Object now is suppressed' do
  expect(current_url).to include "digital_objects/#{@digital_object_id}"
  expect(page).to have_text "Digital Object Digital Object Title #{@uuid} suppressed"
  expect(page).to have_text 'Digital Object is suppressed and cannot be edited'
end

Then 'the Digital Object now is not suppressed' do
  visit "#{STAFF_URL}/digital_objects/#{@digital_object_id}/edit"

  wait_for_ajax

  expect(current_url).to include "/digital_objects/#{@digital_object_id}/edit"

  expect(page).to have_css('button', text: 'Suppress')
end

Then 'the Digital Object cannot be accessed by archivists' do
  visit "#{STAFF_URL}/logout"

  login_archivist

  visit "#{STAFF_URL}/digital_objects/#{@digital_object_id}"

  expect(page).to have_text 'Record Not Found'
  expect(page).to have_text "The record you've tried to access may no longer exist or you may not have permission to view it."
end

Then 'the Digital Object can be accessed by archivists' do
  visit "#{STAFF_URL}/logout"

  login_archivist

  visit "#{STAFF_URL}/digital_objects/#{@digital_object_id}/edit"
  expect(current_url).to include "/digital_objects/#{@digital_object_id}/edit"
end
