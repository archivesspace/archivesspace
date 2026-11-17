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

MANY_EXTENT_TYPES = Array.new(50) { |i| format('e2e extent type %02d', i + 1) }.freeze

After('@many_extent_types') do
  remove_enumeration_values('extent_extent_type', MANY_EXTENT_TYPES)
end

Given 'the Extent Type list is long enough that the Type field is a combobox' do
  add_enumeration_values('extent_extent_type', MANY_EXTENT_TYPES)

  expect(enumeration_named('extent_extent_type')['values'].length).to be >= 50

  page.refresh
  wait_for_ajax

  expect(page).to have_css("input#resource_extents__0__extent_type_[role='combobox']")
end

Then 'the new Extent has the {string} Type selected' do |label|
  created_extent = all('#resource_extents_ .subrecord-form-list li').last

  expect(created_extent.find_field('Type').value).to eq label

  submitted = created_extent.find("input[type='hidden'][name$='[extent_type]']", visible: :all)

  expect(submitted.value).to eq label.downcase.gsub(' ', '_')
end
