# frozen_string_literal: true

When 'the user clicks on the plus icon in the Ratings form' do
  find('#table_assessment_ratings button span.glyphicon.glyphicon-plus', match: :first).click
end

When 'the user clicks on the remove icon in the Ratings form' do
  element = find("input[value=\"#{@uuid}\"]")

  element.ancestor('.input-group').find('span.glyphicon.glyphicon-remove', match: :first).click
end

When 'the user fills in the input field in the Repository Ratings section' do
  element = find('input#ratings__label[value=""]', match: :first)

  element.fill_in with: @uuid
end

Then 'the new attribute is added to the Repository Ratings' do
  expect(find("input[value=\"#{@uuid}\"]").value).to eq @uuid
end

Given 'a Rating Attribute has been added to the Repository Ratings' do
  visit "#{STAFF_URL}/assessment_attributes"

  find('#table_assessment_ratings button span.glyphicon.glyphicon-plus', match: :first).click

  element = find('#table_assessment_ratings input[value=""]')

  element.fill_in with: @uuid

  find('button', text: 'Save Assessment Attributes', match: :first).click

  expect(find('.alert.alert-success.with-hide-alert').text).to eq 'Assessment Attributes updated'
end

Then 'the Rating Attribute is removed from the Repository Ratings' do
  expect(page).to_not have_css("input[value=\"#{@uuid}\"]")
end

Given 'an Assessment with a rating has been created' do
  visit "#{STAFF_URL}/assessment_attributes"
  find('#table_assessment_ratings button span.glyphicon.glyphicon-plus', match: :first).click
  element = find('input#ratings__label[value=""]', match: :first)
  element.fill_in with: @uuid
  find('button', text: 'Save Assessment Attributes', match: :first).click
  expect(find('.alert.alert-success.with-hide-alert').text).to eq 'Assessment Attributes updated'

  visit "#{STAFF_URL}/accessions/new"
  fill_in 'accession_id_0_', with: "Accession #{@uuid}"
  click_on 'Save'
  expect(page).to have_text "Accession #{@uuid}"

  visit "#{STAFF_URL}/assessments/new"
  fill_in 'token-input-assessment_records_', with: "Accession #{@uuid}"
  dropdown_items = all('li.token-input-dropdown-item2')
  dropdown_items.first.click

  fill_in 'token-input-assessment_surveyed_by_', with: 'test'
  dropdown_items = all('li.token-input-dropdown-item2')
  dropdown_items.first.click

  element = find('label', text: @uuid)
  ratings = element.ancestor('tr').all('input')
  ratings[3].click

  click_on 'Save'
  expect(find('.alert.alert-success.with-hide-alert').text).to eq 'Assessment Created'
  url_parts = current_url.split('assessments').pop.split('/')
  url_parts.pop
  @assessment_id = url_parts.pop
end

When 'the user clicks on the magnifying glass icon of the rating' do
  element = find("input[value=\"#{@uuid}\"]")

  element.ancestor('.input-group').find('span.glyphicon.glyphicon-search', match: :first).click
end

Then 'the record associated with the assessment rating is in the search results' do
  expect(page).to have_css('tr', text: @uuid)
end
