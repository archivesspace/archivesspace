# frozen_string_literal: true

Given 'the user is on Agents page' do
  visit "#{STAFF_URL}/agents"
end

When 'the user checks Rest of Name in the Name Forms form' do
  check 'required_fields__rest_of_name_'
end
