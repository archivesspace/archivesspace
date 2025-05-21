# frozen_string_literal: true

Then 'the Location Profile is created' do
  @location_profile_id = current_url.split('/').pop

  visit "#{STAFF_URL}/location_profiles/#{@location_profile_id}/edit"

  expect(find('#location_profile_name_').value).to eq @uuid
  expect(find('#location_profile_depth_').value).to eq '10'
  expect(find('#location_profile_height_').value).to eq '20'
  expect(find('#location_profile_width_').value).to eq '30'
end
