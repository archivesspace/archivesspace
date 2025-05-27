# frozen_string_literal: true

Given 'the user is on the Resources page' do
  visit "#{STAFF_URL}/resources"
end

Then 'the Resource Record Defaults page is displayed' do
  expect(current_url).to include 'resources/defaults'
end

Given 'the user is on the Resource Record Default page' do
  visit "#{STAFF_URL}/resources/defaults"
end

Then 'the new Resource form has the following default values' do |form_values_table|
  visit "#{STAFF_URL}/resources/new"

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
