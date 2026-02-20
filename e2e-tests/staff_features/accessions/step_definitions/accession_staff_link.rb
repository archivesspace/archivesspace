# frozen_string_literal: true

Given 'the user is logged out' do
  visit "#{STAFF_URL}/logout"
end

Given 'a viewer user is logged in' do
  login_viewer
end

When 'the user visits the Accession on the Public Interface' do
  visit "#{PUBLIC_URL}/repositories/#{@repository_id}/accessions/#{@accession_id}"

  wait_for_ajax
end
