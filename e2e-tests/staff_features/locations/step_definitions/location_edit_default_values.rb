# frozen_string_literal: true

Given 'the Locations page is displayed' do
  visit "#{STAFF_URL}/locations"
end

Then 'the new Location form has the following default values' do |form_values_table|
  visit "#{STAFF_URL}/locations/new"

  wait_for_ajax

  form_values_table.hashes.each do |row|
    expect(page).to have_field(row['form_field'], with: /#{Regexp.quote(row['form_value'])}/i)
  end
end
