# frozen_string_literal: true

Then 'the New Assessment page is displayed' do
  expect(current_url).to include 'new'
  expect(current_url).to include 'assessments'
end

Then 'the Assessment is linked to the Accession in the {string} form' do |form_title|
  section_title = find('h3', text: form_title)
  section = section_title.ancestor('section')
  expect(section[:id]).to_not eq nil

  related_accessions_elements = section.all('li.token-input-token')

  expect(related_accessions_elements.length).to eq 1
  related_accession = related_accessions_elements[0].find('.accession')

  expect(related_accession[:'data-content']).to include "accessions/#{@accession_id}"
end
