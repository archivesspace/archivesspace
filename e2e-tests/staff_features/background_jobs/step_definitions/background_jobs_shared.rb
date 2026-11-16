# frozen_string_literal: true

Given 'the user is on the {string} background job page' do |string|
  click_on 'Create'
  click_on 'Background Job'
  click_on string
end

Given 'the user fills in and selects the Resource from the search field' do
  fill_in 'token-input-job_source_', with: @uuid
  dropdown_item = find('div.token-input-dropdown li', text: @uuid, wait: 5)
  dropdown_item.click
end

Then 'a {word} file is downloaded for the job' do |extension|
  job_id = current_url[%r{/jobs/(\d+)}, 1]
  expect(job_id).to_not eq nil

  downloads = File.join(Dir.tmpdir, "job_#{job_id}_file_*")
  downloaded_file = Dir.glob("#{downloads}.#{extension.downcase}").first

  expect(downloaded_file).to_not(eq(nil), "expected a .#{extension.downcase} download, found: #{Dir.glob(downloads)}")
ensure
  Dir.glob(downloads).each { |file| FileUtils.rm_f(file) } if downloads
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
