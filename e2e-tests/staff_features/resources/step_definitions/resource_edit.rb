# frozen_string_literal: true

Given 'the Resource appears in the search results list' do
  visit "#{STAFF_URL}/resources"

  fill_in 'filter-text', with: @uuid

  within '.search-filter' do
    find('button').click
  end

  search_result_rows = all('#tabledSearchResults tbody tr')
  expect(search_result_rows.length).to eq 1

  within search_result_rows[0] do
    element = find('a', text: 'Edit')

    @resource_id = URI.decode_www_form_component(element[:href]).split('/').pop
  end
end

Given 'the Resource has one Language' do
  languages = all('#resource_lang_materials_ .subrecord-form-list .subrecord-form-wrapper')

  expect(languages.length).to eq 1
end

Given 'the Resource has one Note' do
  notes = all('#resource_notes_ .subrecord-form-list .subrecord-form-wrapper')

  expect(notes.length).to eq 1
end

Then 'the Resource is opened in the edit mode' do
  uri = current_url.split('/')

  action = uri.pop
  resource_id = uri.pop

  expect(action).to include 'edit'
  expect(resource_id).to eq @resource_id
end

Then 'the Resource Title field has the original value' do
  visit "#{STAFF_URL}/resources/#{@resource_id}/edit"
  wait_for_ajax

  expect(page).to have_field('Title', with: "Resource #{@uuid}", match: :first)
end

Then 'the Resource Begin field has the original value' do
  visit "#{STAFF_URL}/resources/#{@resource_id}/edit"
  wait_for_ajax

  expect(page).to have_field('Begin', with: ORIGINAL_RESOURCE_DATE, match: :first)
end

Then 'the Resource has one Language with the original values' do
  visit "#{STAFF_URL}/resources/#{@resource_id}/edit"
  wait_for_ajax

  languages = all('#resource_lang_materials_ .subrecord-form-wrapper')

  expect(languages.length).to eq 1
  expect(find('#resource_lang_materials__0__language_and_script__language_').value).to eq ORIGINAL_LANGUAGE
end

Then 'the Resource does not have Notes' do
  visit "#{STAFF_URL}/resources/#{@resource_id}/edit"
  wait_for_ajax

  notes = all('#resource_notes_ .subrecord-form-wrapper')
  expect(notes.length).to eq 0
end

Then 'a new Instance is added to the Resource with the following values' do |form_values_table|
  instances = all('#resource_instances_ .subrecord-form-list li.subrecord-form-wrapper')

  expect(instances.length).to eq @resource_number_of_instances + 1

  instance = instances.last

  form_values_hash = form_values_table.rows_hash
  form_values_hash.each do |field, value|
    if field == 'Top Container'
      expect(find('.top_container').text).to eq value
    else
      expect(instance.find_field(field, visible: true).value).to eq value.downcase.gsub(' ', '_')
    end
  end
end
