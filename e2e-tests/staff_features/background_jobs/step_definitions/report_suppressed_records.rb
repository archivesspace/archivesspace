# frozen_string_literal: true

def latest_downloaded_report
  Dir.glob(File.join(Dir.tmpdir, '*.csv'))
     .select { |file| File.basename(file).include?('job') }
     .max_by { |file| File.mtime(file) }
end

Given 'the user selects the {string} report' do |report_title|
  title_button = find('.report-listing button.report-title', exact_text: report_title)
  listing = title_button.ancestor('.report-listing')

  within listing do
    find('button.select-report').click
  end

  wait_for_ajax
  expect(page).to have_css('#report-fields .form-group')
end

Then 'the downloaded report contains the Accession' do
  downloaded_file = latest_downloaded_report
  expect(downloaded_file).to_not eq nil

  report_text = File.read(downloaded_file)
  FileUtils.rm_f(downloaded_file)

  expect(report_text).to include("Accession Title #{@uuid}")
end

Then 'the downloaded report does not contain the Accession' do
  downloaded_file = latest_downloaded_report
  expect(downloaded_file).to_not eq nil

  report_text = File.read(downloaded_file)
  FileUtils.rm_f(downloaded_file)

  expect(report_text).to_not include("Accession Title #{@uuid}")
end
