# frozen_string_literal: true

Then 'the Assessment is linked to the Resource in the {string} form' do |form_title|
  section_title = find('h3', text: form_title)
  section = section_title.ancestor('section')
  expect(section[:id]).to_not eq nil

  related_resources_elements = section.all('li.token-input-token')

  expect(related_resources_elements.length).to eq 1
  related_resource = related_resources_elements[0].find('.resource')

  expect(related_resource[:'data-content']).to include "resources/#{@resource_id}"
end
