# frozen_string_literal: true

Then 'the Agent is in the light mode' do
  section_titles = [
    'Record Info',
    'Other Agency Codes',
    'Convention Declarations',
    'Metadata Rights Declarations',
    'Maintenance History',
    'Sources',
    'Alternate Sets',
    'Genders',
    'Places',
    'Occupations',
    'Functions',
    'Topics',
    'Languages Used',
    'Related External Resources'
  ]

  section_titles.each do |section_title|
    expect(page).to_not have_text section_title
  end
end

Given 'the light mode is checked' do
  check 'Light Mode'
end

Then 'the Agent is in the full mode' do
  section_titles = [
    'Record Info',
    'Other Agency Codes',
    'Convention Declarations',
    'Metadata Rights Declarations',
    'Maintenance History',
    'Sources',
    'Alternate Sets',
    'Genders',
    'Places',
    'Occupations',
    'Functions',
    'Topics',
    'Languages Used',
    'Related External Resources'
  ]

  section_titles.each do |section_title|
    expect(page).to have_text section_title
  end
end
