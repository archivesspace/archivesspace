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
      field = find_field(row['form_field'])

      expect(field.value.downcase).to eq row['form_value'].downcase
    end
  end
end
