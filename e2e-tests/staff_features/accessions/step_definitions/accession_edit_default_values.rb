# frozen_string_literal: true

Given 'the user is on the Accessions page' do
  visit "#{STAFF_URL}/accessions"
end

Then 'the Accession Record Defaults page is displayed' do
  expect(current_url).to include 'accessions/defaults'
end

Given 'the user is on the Accession Record Default page' do
  visit "#{STAFF_URL}/accessions/defaults"
  wait_for_ajax
end

Then 'the new Accession form has the following default values' do |form_values_table|
  visit "#{STAFF_URL}/accessions/new"
  expect(page).to have_selector('h2', visible: true, text: 'Accession')

  expect_form_values(form_values_table)
end

