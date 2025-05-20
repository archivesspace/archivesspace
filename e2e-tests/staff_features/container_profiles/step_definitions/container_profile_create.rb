# frozen_string_literal: true

Then 'the New Container Profile page is displayed' do
  expect(current_url).to eq "#{STAFF_URL}/container_profiles/new"
  expect(find('h2').text).to eq 'New Container Profile Container Profile'
end

Then 'the Container Profile is created' do
  @container_profile_id = current_url.split('/').pop

  visit "#{STAFF_URL}/container_profiles/#{@container_profile_id}/edit"

  expect(find('#container_profile_name_').value).to eq @uuid
end
