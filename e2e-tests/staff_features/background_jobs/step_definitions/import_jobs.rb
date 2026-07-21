# frozen_string_literal: true

Given('the user is on the Import Job page') do
  click_on 'Create'
  click_on 'Background Job'
  click_on 'Import Data'
end

When 'the user adds {string} as a file' do |file_path|
  attach_file('files[]', file_path, make_visible: true)
end

Then 'the New & Modified Records section contains {int} links' do |number|
  links = all('#jobRecordsSpool > div.subrecord-form-fields > div > a')
  expect(links.count).to eq(number)
end

Then 'the record links do not display {string}' do |string|
  expect(all('span.badge.badge-warning').map(&:text)).not_to include(string)
end
