# frozen_string_literal: true

Given 'the user is on the New Accession page' do
  visit "#{STAFF_URL}/accessions/new"
end

Then 'the Accession is created' do
  uri = find('#accession_form')[:'data-update-monitor-record-uri']

  @accession_id = uri.split('/').pop

  visit "#{STAFF_URL}/accessions/#{@accession_id}/edit"

  expect(find('#accession_id_0_').value).to eq @uuid
end
