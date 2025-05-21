# frozen_string_literal: true

Then 'an EAD XML file is downloaded' do
  files = Dir.glob(File.join(Dir.tmpdir, '*__ead.xml'))

  downloaded_file = nil
  files.each do |file|
    downloaded_file = file if file.include?("Resource_#{@uuid}".gsub('-', ''))
  end

  file_read = File.read(downloaded_file)
  expect(file_read).to include @uuid
end

Then 'a MARC 21 XML file is downloaded' do
  files = Dir.glob(File.join(Dir.tmpdir, '*__marc21.xml'))

  downloaded_file = nil
  files.each do |file|
    downloaded_file = file if file.include?("Resource_#{@uuid}".gsub('-', ''))
  end

  file_read = File.read(downloaded_file)
  expect(file_read).to include @uuid
end

Then 'the Container Template CSV file is downloaded' do
  files = Dir.glob(File.join(Dir.tmpdir, '*.csv'))

  downloaded_file = nil
  files.each do |file|
    file_read = File.read(file)

    downloaded_file = file if file_read.include?('Archival Object Top Container Generation Template')
  end

  expect(downloaded_file).to_not eq nil
end

Then 'a Digital Object template CSV file is downloaded prefilled with resource URI' do
  files = Dir.glob(File.join(Dir.tmpdir, '*.csv'))

  downloaded_file = nil
  files.each do |file|
    downloaded_file = file if file.include?('digital_object_template')
  end

  file_read = File.read(downloaded_file)
  expect(file_read).to include "resources/#{@resource_id}"
end

Then 'the {string} job page is displayed' do |job_title|
  expect(page.windows.length).to eq 2

  switch_to_window page.windows[1]

  tries = 0
  while current_url == 'about:blank'
    sleep 3

    tries += 1

    break if tries == 5
  end

  expect(current_url).to include 'jobs'
  expect(page).to have_text job_title
end
