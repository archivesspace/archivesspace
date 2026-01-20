# frozen_string_literal: true

When('the user clicks the dropdown toggle for related accessions') do
  within '#resource_related_accessions__0__ref__combobox' do
    find('button').click
  end
  wait_for_ajax
end

When('the user saves an accession without required fields') do
  within '.modal-content' do
    fill_in 'accession_title_', with: 'Incomplete Accession'
    click_on 'Create and Link'
  end
  wait_for_ajax
end

When('the user creates and links a related accession with title {string}') do |title|
  @accession_count ||= 0
  index = @accession_count

  click_on 'Add Related Accession'
  wait_for_ajax

  within "#resource_related_accessions__#{index}__ref__combobox" do
    find('button').click
    click_on 'Create'
  end

  wait_for_ajax

  within "#resource_related_accessions__#{index}__ref__modal" do
    fill_in 'accession_id_0_', with: "ACC_#{Time.now.to_i}_#{index}"
    fill_in 'accession_title_', with: title
    fill_in 'accession_accession_date_', with: '2026-01-05'
    click_on 'Create and Link'
  end

  wait_for_ajax
  @accession_count += 1
end

Then('the resource should have {int} related accessions') do |count|
  related_accessions = all('#resource_related_accessions_ .subrecord-form-list > li')
  expect(related_accessions.length).to eq count
end

Then('the related accessions should be named {string} and {string}') do |first_title, second_title|
  within '#resource_related_accessions__0__ref__combobox' do
    expect(page).to have_text(first_title)
  end

  within '#resource_related_accessions__1__ref__combobox' do
    expect(page).to have_text(second_title)
  end
end

When('the user navigates to edit the resource') do
  visit "#{STAFF_URL}/resources/#{@resource_id}/edit"
  expect(page).to have_content("Resource #{@uuid}")
end

Then('the related accession {string} is linked') do |title|
  within '#resource_related_accessions__0__ref__combobox' do
    expect(page).to have_text(title)
    expect(page).to have_css('.token-input-token .accession')
  end
end
