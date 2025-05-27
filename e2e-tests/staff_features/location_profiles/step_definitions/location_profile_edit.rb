# frozen_string_literal: true

Given 'the Location Profile appears in the search results list' do
  visit "#{STAFF_URL}/location_profiles"

  fill_in 'filter-text', with: @uuid

  within '.search-filter' do
    find('button').click
  end

  search_result_rows = all('#tabledSearchResults tbody tr')
  expect(search_result_rows.length).to eq 1
end

Then 'the Location Profile is opened in the edit mode' do
  uri = current_url.split('/')

  action = uri.pop
  location_profile_id = uri.pop

  expect(action).to eq 'edit'
  expect(location_profile_id).to eq @location_profile_id
end

Given 'the Location Profile is opened in view mode' do
  visit "#{STAFF_URL}/location_profiles/#{@location_profile_id}"
end

Given 'the Location Profile is opened in edit mode' do
  visit "#{STAFF_URL}/location_profiles/#{@location_profile_id}/edit"
end

Then 'the Location Profile Name field has the original value' do
  visit "#{STAFF_URL}/location_profiles/#{@location_profile_id}/edit"

  expect(page).to have_field('Name', with: "Test Location Profile #{@uuid}")
end

Then 'the Top Container form has the following values' do |form_values_table|
  form_values = form_values_table.hashes

  form_values.each do |row|
    section_title = find('h3', text: row['form_section'])
    section = section_title.ancestor('section')
    expect(section[:id]).to_not eq nil

    within section do
      field = find_field(row['form_field'])

      expect(field.value.downcase).to eq row['form_value'].downcase
    end
  end
end
