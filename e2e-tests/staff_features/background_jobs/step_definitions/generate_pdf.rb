# frozen_string_literal: true

require 'pdf-reader'

Then 'a PDF file is downloaded for the resource' do
  downloaded_file = Dir.glob(File.join(Dir.tmpdir, '*.pdf'))
                       .select { |file| File.basename(file).include?('job') }
                       .max_by { |file| File.mtime(file) }

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
