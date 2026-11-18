# frozen_string_literal: true

Then 'a new instance with a link to the Digital Object is added to the Resource' do
  instances = all('#resource_instances_ .subrecord-form-list li.subrecord-form-wrapper')

  expect(instances.length).to eq @resource_number_of_instances + 1

  instance = instances.last

  expect(instance.text).to include @uuid
end

When 'the user searches and selects the Digital Object in the modal' do
  within '.modal-content' do
    submit_listing_filter(@uuid)
  end

  find('#tabledSearchResults tbody tr', text: @uuid).find('input[type="radio"]').click
end
