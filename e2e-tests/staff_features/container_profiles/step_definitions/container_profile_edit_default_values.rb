# frozen_string_literal: true

Given 'the user is on the Container Profiles page' do
  visit "#{STAFF_URL}/container_profiles"
end

Given 'a Container Profile Default has been set with Width as Extent Dimension' do
  visit "#{STAFF_URL}/container_profiles"
  click_link('Edit Default Values')
  wait_for_ajax

  fill_in 'Name', with: 'DEFAULT BOX'
  select 'Width', from: 'Extent Dimension'
  fill_in 'Depth', with: '12'
  fill_in 'Height', with: '15'
  fill_in 'Width', with: '10'
  select 'Inches', from: 'Dimension Units'

  click_on('Save Container Profile')
  expect(page).to have_content('Defaults Updated')
end

Then 'the new Container Profile form has the following default values' do |form_values_table|
  visit "#{STAFF_URL}/container_profiles/new"

  form_values = form_values_table.hashes

  form_values.each do |row|
    section_title = find('h3', text: row['form_section'])
    section = section_title.ancestor('section')
    expect(section[:id]).to_not eq nil

    within section do
      field = find_field(row['form_field'])

      case row['form_field']
      when 'Extent Dimension', 'Dimension Units'
        expect(field.value).to eq row['form_value'].downcase
      else
        expect(field.value).to eq row['form_value']
      end
    end
  end
end
