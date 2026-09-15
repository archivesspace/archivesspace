# frozen_string_literal: true

Given 'the user visits the OAI-PMH endpoint using the verb Identify' do
  visit "#{OAI_URL}/oai?verb=Identify"
end

Given 'an XML response beginning with {string} is displayed' do |expected_string|
  expect(page.body).to include(expected_string)
end

OAI_SET_ENTRIES = '.subrecord-form-container > .subrecord-form-list > li'

def oai_set_section(section_id)
  find("##{section_id}")
end

def oai_set_entry(section_id, set_name)
  find("##{section_id} input[type='text'][value='#{set_name}']").ancestor('li', match: :first)
end

def add_oai_set_entry(section_id, add_button_label)
  section = oai_set_section(section_id)
  entry_count = section.all(OAI_SET_ENTRIES).length

  section.find('.subrecord-form-heading').click_on add_button_label

  expect(section).to have_css(OAI_SET_ENTRIES, count: entry_count + 1)

  section.all(OAI_SET_ENTRIES).last
end

def remove_oai_set_entry(section_id, entry)
  section = oai_set_section(section_id)
  entry_count = section.all(OAI_SET_ENTRIES).length

  within entry do
    find('.subrecord-form-remove').click
    find('.confirm-removal').click
  end

  expect(section).to have_css(OAI_SET_ENTRIES, count: entry_count - 1)
end

When 'the user removes every OAI set' do
  %w[repository_set sponsor_set].each do |section_id|
    while (entry = oai_set_section(section_id).all(OAI_SET_ENTRIES).first)
      remove_oai_set_entry section_id, entry
    end
  end
end

When 'the user removes the OAI repository set {string}' do |set_name|
  remove_oai_set_entry 'repository_set', oai_set_entry('repository_set', set_name)
end

When 'the user adds an OAI repository set named {string} for the repository {string}' do |set_name, repo_code|
  within add_oai_set_entry('repository_set', 'Add Repository Set') do
    fill_in 'Repository Set Name', with: set_name
    fill_in 'Repository Set Description', with: "#{set_name} description"
    check repo_code
  end
end

When 'the user adds an OAI sponsor set named {string} for the sponsors {string}' do |set_name, sponsors|
  within add_oai_set_entry('sponsor_set', 'Add Sponsor Set') do
    fill_in 'Sponsor Set Name', with: set_name
    fill_in 'Sponsor Set Description', with: "#{set_name} description"

    # Tag widget: one tag per return
    tag_field = find('.bootstrap-tagsinput input[type="text"]')

    sponsors.split(',').each { |sponsor| tag_field.send_keys(sponsor.strip, :enter) }
  end
end

Then 'the OAI repository set {string} includes the repository {string}' do |set_name, repo_code|
  within oai_set_entry('repository_set', set_name) do
    expect(page).to have_field(repo_code, checked: true)
  end
end

Then 'the OAI sponsor set {string} includes the sponsors {string}' do |set_name, sponsors|
  tags = oai_set_entry('sponsor_set', set_name).all('.bootstrap-tagsinput .tag').map(&:text)

  expect(tags).to match_array(sponsors.split(',').map(&:strip))
end

Then 'the OAI-PMH endpoint offers the sets {string}' do |set_names|
  visit "#{OAI_URL}/oai?verb=ListSets"

  set_names.split(',').each do |set_name|
    expect(page.body).to include("<setSpec>#{set_name.strip}</setSpec>")
  end
end

Then 'the OAI-PMH endpoint does not offer the set {string}' do |set_name|
  visit "#{OAI_URL}/oai?verb=ListSets"

  expect(page.body).to_not include("<setSpec>#{set_name}</setSpec>")
end
