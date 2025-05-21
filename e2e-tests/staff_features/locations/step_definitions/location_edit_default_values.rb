# frozen_string_literal: true

Given 'the Locations page is displayed' do
  visit "#{STAFF_URL}/locations"
end

Then 'the new Location form has the following default values' do |form_values_table|
  visit "#{STAFF_URL}/locations/new"

  form_values = form_values_table.hashes

  form_values.each do |row|
    field = find_field(row['form_field'])

    expect(field.value.downcase).to eq row['form_value'].downcase
  end
end
