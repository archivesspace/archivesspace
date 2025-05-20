# frozen_string_literal: true

Then 'the New Accession page is displayed' do
  expect(find('h2').text).to eq 'New Accession Accession'
end

Given 'the user is on the New Accession page spawned from the original Accession' do
  visit "#{STAFF_URL}/accessions/new?accession_id=#{@accession_id}"
end

Then 'the Accession has been spawned from Accession info message is displayed' do
  message = "This Accession has been spawned from Accession Accession Title #{@uuid}. This record is unsaved. You must click Save for the record to be created in the system"

  expect(page).to have_text message
end

Then 'the new Accession is not linked to the original Accession' do
  expect(page).not_to have_selector('#accession_related_accessions__0_')
end

When 'the user links to the original Accession in the {string} form' do |form_title|
  section_title = find('h3', text: form_title)
  section = section_title.ancestor('section')
  expect(section[:id]).to_not eq nil

  within section do
    click_on 'Add Related Accession'
    find('.related-accession-type').select '"Part of" Relationship'
    fill_in 'token-input-accession_related_accessions__0__ref_', with: @uuid
    dropdown_items = all('li.token-input-dropdown-item2')
    dropdown_items.first.click
  end
end

Then 'the new Accession is linked to the original Accession' do
  section = find('#accession_related_accessions_')
  expect(section).to have_text @uuid
end
