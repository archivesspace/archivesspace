# frozen_string_literal: true

require 'pdf-reader'

Given 'a PDF file is downloaded for the resource' do
  files = Dir.glob(File.join(Dir.tmpdir, '*.pdf'))

  downloaded_file = nil
  files.each do |file|
    downloaded_file = file if file.include?('job')
  end

  expect(downloaded_file).to_not eq nil

  pdf_text = String.new
  begin
    reader = PDF::Reader.new(downloaded_file)
    reader.pages.each do |page|
      pdf_text << page.text
    end
  ensure
    FileUtils.rm_f(downloaded_file)
  end
  expect(pdf_text).to include("Resource #{@uuid}")
end
