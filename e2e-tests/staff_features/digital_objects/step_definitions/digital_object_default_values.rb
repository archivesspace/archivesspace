# frozen_string_literal: true

Then 'the new Digital Object form has the following default values' do |form_values_table|
  visit "#{STAFF_URL}/digital_objects/new"

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

Then 'the new Digital Object Component form has the following default values' do |form_values_table|
  visit "#{STAFF_URL}/digital_objects/#{@digital_object_id}/edit"
  wait_for_ajax
  expect(page).to have_selector('h2', visible: true, text: 'Digital Object')

  click_on 'Add Child'

  wait_for_ajax
  expect(page).to have_selector('h2', visible: true, text: 'Digital Object Component')

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
