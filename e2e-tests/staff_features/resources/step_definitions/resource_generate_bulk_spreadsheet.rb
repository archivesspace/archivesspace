# frozen_string_literal: true

Given 'the user is on the Generate Bulk Archival Object Spreadsheet page' do
  click_on 'More'
  click_on 'Generate Bulk Archival Object Spreadsheet'
end

Then 'the Generate Bulk Archival Object Spreadsheet page is displayed' do
  expect(current_url).to include 'bulk_archival_object_updater/download?resource='
  expect(current_url).to include @resource_id
end

Then 'the user selects the Archival Object on the Generate Bulk Archival Object Spreadsheet page' do
  input_fields = all('#bulk_archival_object_updater_table input')

  expect(input_fields.length).to eq 2
  input_fields[1].click
end

Then 'the Bulk Update Resource spreadsheet is downloaded' do
  files = Dir.glob(File.join(Dir.tmpdir, '*.xlsx'))

  downloaded_file = nil
  files.each do |file|
    downloaded_file = file if file.include?("bulk_update.resource_#{@resource_id}")
  end

  expect(downloaded_file).to_not eq nil
end
