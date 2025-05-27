# frozen_string_literal: true

Then 'a new template with name {string} with the following data is added to the Resource Rapid Data Entry templates' do |template, form_values_table|
  visit "#{STAFF_URL}/resources/#{@resource_id}/edit"
  click_on 'Rapid Data Entry'
  wait_for_ajax

  click_on 'Apply an RDE Template'
  find('a span', text: template, match: :first).click

  table_header_cells = all('.fieldset-labels .kiketable-th-text')
  table_field_rows = all('#rdeTable tbody tr')

  expect(table_field_rows.length).to eq 1

  form_values_hash = form_values_table.rows_hash
  form_values_hash.each do |field, value|
    field_position = 0
    table_header_cells.each_with_index do |header, index|
      field_position = index if header.text == field
    end
    field_position += 1
    expect(field_position).to_not eq 0

    table_field_cells = table_field_rows[0].all('td')
    field_cell = table_field_cells[field_position]

    expect(field_cell.find('input, select, textarea').value.downcase.gsub(' ', '_')).to eq value.downcase.gsub(' ', '_')
  end
end

Given 'a Resource Rapid Data Entry template has been created' do
  visit "#{STAFF_URL}/resources/#{@resource_id}/edit"
  click_on 'Rapid Data Entry'
  wait_for_ajax

  click_on 'Save as Template'
  fill_in 'templateName', with: "RDE Template #{@uuid}"
  click_on 'Save Template'

  visit "#{STAFF_URL}/resources/#{@resource_id}/edit"
  wait_for_ajax
end

Then 'the template is removed from the Resource Rapid Data Entry templates' do
  visit "#{STAFF_URL}/resources/#{@resource_id}/edit"
  click_on 'Rapid Data Entry'
  wait_for_ajax
  click_on 'Apply an RDE Template'

  expect(find('.dropdown-menu')).to_not have_text "RDE Template #{@uuid}"
end
