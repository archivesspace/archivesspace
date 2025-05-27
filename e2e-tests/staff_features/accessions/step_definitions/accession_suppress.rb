# frozen_string_literal: true

Given 'the Accession is not suppressed' do
  expect(page).to have_css('button', text: 'Suppress')
end

Given 'the Accession is suppressed' do
  expect(page).to have_css('button', text: 'Suppress')

  click_on 'Suppress'
  within '.modal-content' do
    click_on 'Suppress'
  end

  expect(current_url).to include "accessions/#{@accession_id}"
  expect(page).to have_text "Accession Accession Title #{@uuid} suppressed"
  expect(page).to have_text 'Accession is suppressed and cannot be edited'
end

Then 'the Accession now is suppressed' do
  expect(current_url).to include "accessions/#{@accession_id}"
  expect(page).to have_text "Accession Accession Title #{@uuid} suppressed"
  expect(page).to have_text 'Accession is suppressed and cannot be edited'
end

Then 'the Accession now is not suppressed' do
  visit "#{STAFF_URL}/accessions/#{@accession_id}/edit"
  expect(current_url).to include "/accessions/#{@accession_id}/edit"

  expect(page).to have_css('button', text: 'Suppress')
end

Then 'the Accession cannot be accessed by archivists' do
  visit "#{STAFF_URL}/logout"

  login_archivist

  visit "#{STAFF_URL}/accessions/#{@accession_id}"

  expect(page).to have_text 'Record Not Found'
  expect(page).to have_text "The record you've tried to access may no longer exist or you may not have permission to view it."
end

Then 'the Accession can be accessed by archivists' do
  visit "#{STAFF_URL}/logout"

  login_archivist

  visit "#{STAFF_URL}/accessions/#{@accession_id}/edit"
  expect(current_url).to include "/accessions/#{@accession_id}/edit"
end
