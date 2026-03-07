# frozen_string_literal: true

Given 'the user is on the Generate Bulk Archival Object Spreadsheet page' do
  click_on 'More'
  click_on 'Generate Bulk Archival Object Spreadsheet'
end

Then 'the Generate Bulk Archival Object Spreadsheet page is displayed' do
  expect(current_url).to include 'bulk_archival_object_updater/download?resource='
  expect(current_url).to include @resource_id
end

Then 'the user selects all Archival Objects on the Generate Bulk Archival Object Spreadsheet page' do
  input_fields = all('#bulk_archival_object_updater_table input')

  expect(input_fields.length).to eq 2
  input_fields[0].click
end

When 'AppConfig[:bulk_archival_object_updater_max_rows] is overridden by localStorage' do
  execute_script("window.localStorage.setItem('APPCONFIG_MAX_ROWS', '0');")

  override = page.evaluate_script("window.localStorage.getItem('APPCONFIG_MAX_ROWS');")
  expect(override).to eq('0')
end

Then 'the too many rows warning is displayed' do
  expect(page).to have_text "The number of rows that will be generated in this spreadsheet exceeds the number of rows that can be updated via the Bulk Archival Object Updater background job."
end

Then 'APPCONFIG_MAX_ROWS is removed from localStorage' do
  execute_script("window.localStorage.removeItem('APPCONFIG_MAX_ROWS');")

  override = page.evaluate_script("window.localStorage.getItem('APPCONFIG_MAX_ROWS');")
  expect(override).to be_nil
end

Then 'the Bulk Update Resource spreadsheet is downloaded' do
  files = Dir.glob(File.join(Dir.tmpdir, '*.xlsx'))

  downloaded_file = nil
  files.each do |file|
    downloaded_file = file if file.include?("bulk_update.resource_#{@resource_id}")
  end

  expect(downloaded_file).to_not eq nil
end
