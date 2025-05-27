# frozen_string_literal: true

Then 'a new Extent is added to the Resource with the following values' do |form_values_table|
  extents = all('#resource_extents_ .subrecord-form-list li')

  expect(extents.length).to eq @resource_number_of_extents + 1

  created_extent = extents.last

  form_values_hash = form_values_table.rows_hash
  form_values_hash.each do |field, value|
    expect(created_extent.find_field(field).value).to eq value.downcase.gsub(' ', '_')
  end
end
