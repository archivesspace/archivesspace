# frozen_string_literal: true

Then 'a new Date is added to the Resource with the following values' do |form_values_table|
  dates = all('#resource_dates_ .subrecord-form-list li')

  expect(dates.length).to eq @resource_number_of_dates + 1

  created_date = dates.last

  form_values_hash = form_values_table.rows_hash
  form_values_hash.each do |field, value|
    expect(created_date.find_field(field).value).to eq value.downcase.gsub(' ', '_')
  end
end
