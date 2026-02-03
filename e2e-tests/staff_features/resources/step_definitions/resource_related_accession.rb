# frozen_string_literal: true

Then('the accession {string} appears in the related accessions linker') do |title|
  within '#resource_related_accessions__0__ref__combobox' do
    expect(page).to have_text(title)
  end
end

Then('the accession {string} is linked to the resource') do |title|
  within '#resource_related_accessions_' do
    expect(page).to have_text(title)
  end
end
