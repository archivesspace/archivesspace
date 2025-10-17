# frozen_string_literal: true

Given 'the user is on the New Resource page' do
  visit "#{STAFF_URL}/resources/new"
end

Then 'the Resource form has the following values' do |form_values_table|
  form_values = form_values_table.hashes

  form_values.each do |row|
    section_title = find('h3', text: row['form_section'])
    section = section_title.ancestor('section')
    expect(section[:id]).to_not eq nil

    within section do
      expect(page).to have_field(row['form_field'], with: /#{Regexp.quote(row['form_value'])}/i)
    end
  end
end
