# frozen_string_literal: true

Given('the user is on the New Digital Object page') do
  visit "#{STAFF_URL}/digital_objects/new"
end

When('the user fills in Title with a unique id') do
  fill_in 'Title', with: "Digital Object Title #{@uuid}"
end
