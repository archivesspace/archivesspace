# frozen_string_literal: true

require 'fileutils'

When('the user locates the {string} template') do |template_name|
  expect(page).to have_content(template_name)
end

When('the user clicks on {string} button for that template') do |button_text|
  within(:xpath, "//div[contains(., 'User Defined Fields in Accessions')]/ancestor::div[contains(@class, 'row')]") do
    click_button(button_text)
  end
end

When('the user waits for the job to complete') do
  Dir.glob(File.join(Dir.tmpdir, '*.json')).each do |file|
    File.delete(file)
  end

  timeout = 60
  start_time = Time.now

  while Time.now - start_time < timeout
    files = Dir.glob(File.join(Dir.tmpdir, '*.json'))
    if files.length == 1
      @downloaded_report = files.first
      break
    end
    sleep 1
  end

  expect(@downloaded_report).not_to be_nil
end

Then('the user should see the following user defined values:') do |table|
  require 'json'
  json_content = File.read(@downloaded_report)
  report_data = JSON.parse(json_content)

  expect(report_data).not_to be_empty
  record = report_data.first
  user_defined = record.fetch('user_defined')
  expect(user_defined).not_to be_nil

  table.rows.each do |field, expected_value|
    actual_value = user_defined.fetch(field)
    case expected_value
    when 'true'
      expect(actual_value).to be true
    when /^\d+$/
      expect(actual_value).to eq expected_value.to_i
    when /^\d*\.\d+$/
      expect(actual_value).to eq expected_value.to_f
    else
      expect(actual_value).to eq expected_value
    end
  end

  FileUtils.rm_f(@downloaded_report)
end

When('the user fills in {string} with {string} in the {string} box') do |label, value, box_position|
  box_index_map = {
    '1st' => 0,
    '2nd' => 1,
    '3rd' => 2,
    '4th' => 3,
    '5th' => 4
  }
  
  index = box_index_map[box_position] || (box_position.to_i - 1)
  field_name = "accession_id_#{index}_"
  fill_in field_name, with: value, match: :first
end
