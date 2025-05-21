# frozen_string_literal: true

Given('the user is on the Import Job page') do
  click_on 'Create'
  click_on 'Background Job'
  click_on 'Import Data'
end

When 'the user adds {string} as a file' do |file_path|
  attach_file('files[]', file_path, make_visible: true)
end

Then 'the Import Job page is displayed' do
  tries = 0

  loop do
    expect(find('h2').text).to start_with 'Import Job'

    break
  rescue RSpec::Expectations::ExpectationNotMetError => e
    tries += 1
    sleep 3

    raise e if tries == 5
  end
end

Then 'the job completes' do
  tries = 0

  loop do
    expect(page).to_not have_text 'This job is next in the queue.'
    expect(page).to have_text 'The job has completed.'

    break
  rescue RSpec::Expectations::ExpectationNotMetError => e
    tries += 1
    sleep 3

    raise e if tries == 5
  end
end

Then 'the New & Modified Records section contains {int} links' do |number|
  links = all('#jobRecordsSpool > div.subrecord-form-fields > div > a')
  expect(links.count).to eq(number)
end

Then 'the record links do not display {string}' do |string|
  expect(all('span.badge.badge-warning').map(&:text)).not_to include(string)
end

Then 'the Subject is listed in the New & Modified Records form' do
  visit current_url

  element = find('#generated_uris .subrecord-form-fields')
  expect(element.text).to eq 'Subject headings'
end
