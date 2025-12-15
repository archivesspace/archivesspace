# frozen_string_literal: true

Given 'the user is on the Component Record Default page' do
  visit "#{STAFF_URL}/archival_objects/defaults"
end

Then 'the Component Record Defaults page is displayed' do
  expect(current_url).to include '/archival_objects/defaults'
end

Then 'the new Resource Component form has the following default values' do |form_values_table|
  visit "#{STAFF_URL}/resources/#{@resource_id}/edit"
  wait_for_ajax
  click_on 'Add Child'
  wait_for_ajax

  form_values = form_values_table.hashes

  form_values.each do |row|
    section_title = find('h3', text: row['form_section'])
    section = section_title.ancestor('section')
    expect(section[:id]).to_not eq nil

    within section do
      field_name = row['form_field']
      expected_value = row['form_value']

      field = find_field(field_name, visible: true)

      if field.tag_name == 'select'
        expect(field.value).to eq expected_value.downcase
      else
        expect(page).to have_field(field_name, with: /#{Regexp.quote(expected_value)}/i, wait: 5)
      end
    end
  end
end
