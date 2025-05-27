# frozen_string_literal: true

Given 'the Repository appears in the search results list' do
  visit "#{STAFF_URL}/repositories"

  fill_in 'filter-text', with: @uuid

  within '.search-filter' do
    find('button').click
  end

  search_result_rows = all('#tabledSearchResults tbody tr')
  expect(search_result_rows.length).to eq 1
end

Then 'the Repository is opened in the edit mode' do
  uri = current_url.split('/')

  action = uri.pop
  repository_id = uri.pop

  expect(action).to eq 'edit'
  expect(repository_id).to eq @repository_id
end

Given 'the Repository is opened in the view mode' do
  visit "#{STAFF_URL}/repositories/#{@repository_id}"
end

Given 'the Repository is opened in edit mode' do
  visit "#{STAFF_URL}/repositories/#{@repository_id}/edit"
end

Then 'the Repository Short Name field has the original value' do
  visit "#{STAFF_URL}/repositories/#{@repository_id}/edit"

  expect(page).to have_field('Repository Short Name', with: "repository_test_#{@uuid}")
end

Then 'the Repository form has the following values' do |form_values_table|
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
