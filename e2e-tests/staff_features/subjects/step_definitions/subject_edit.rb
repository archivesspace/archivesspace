# frozen_string_literal: true

Given 'the Subject appears in the search results list' do
  visit "#{STAFF_URL}/subjects"

  fill_in 'filter-text', with: "subject_term_#{@uuid}"

  within '.search-filter' do
    find('button').click
  end

  search_result_rows = all('#tabledSearchResults tbody tr')
  expect(search_result_rows.length).to eq 1

  within search_result_rows[0] do
    element = find('a', text: 'Edit')

    @subject_id = URI.decode_www_form_component(element[:href]).split('/').pop
  end
end

Then 'the Subject is opened in the edit mode' do
  uri = current_url.split('/')

  action = uri.pop
  subject_id = uri.pop

  expect(action).to eq 'edit'
  expect(subject_id).to eq @subject_id
end

Given 'the Subject is opened in the view mode' do
  visit "#{STAFF_URL}/subjects/#{@subject_id}"
end

Given 'the Subject is opened in edit mode' do
  visit "#{STAFF_URL}/subjects/#{@subject_id}/edit"
end

Given 'the Subject has one Metadata Rights Declarations' do
  click_on 'Add Metadata Rights Declaration'

  select 'This record is made available under an Universal 1.0 Public Domain Dedication Creative Commons license.', from: 'License'

  click_on 'Save'

  expect(find('.alert.alert-success.with-hide-alert').text).to eq 'Subject Saved'
end

Then 'the Subject does not have Metadata Rights Declarations' do
  elements = all('#subject_metadata_rights_declarations_ li')

  expect(elements.length).to eq 0
end

Then 'a new External Document is added to the Subject with the following values' do |form_values_table|
  records = all('#subject_external_documents_ .subrecord-form-list li')

  expect(records.length).to eq @subject_number_of_external_documents + 1

  created_record = records.last

  form_values_hash = form_values_table.rows_hash
  form_values_hash.each do |field, value|
    expect(created_record.find_field(field).value.downcase.gsub(' ', '_')).to eq value.downcase.gsub(' ', '_')
  end
end
