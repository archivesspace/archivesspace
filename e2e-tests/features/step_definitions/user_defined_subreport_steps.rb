Then('I should see a notification that the template was saved') do
  expect(page).to have_content('+1')
end

When('I locate the {string} template') do |template_name|
  expect(page).to have_content(template_name)
end

When('I click the {string} button for that template') do |button_text|
  within(:xpath, "//div[contains(., 'User Defined Fields in Accessions')]/ancestor::div[contains(@class, 'row')]") do
    click_button(button_text)
  end
end

When('I wait for the job to complete') do
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

Then('I should see the following user defined values:') do |table|
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

  File.delete(@downloaded_report) if File.exist?(@downloaded_report)
end

When('I wait for the report to complete') do
  expect(page).to have_css('.report-content', wait: 30)
end
