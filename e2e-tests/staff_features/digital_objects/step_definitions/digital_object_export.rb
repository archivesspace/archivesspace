# frozen_string_literal: true

Then 'a MODS XML file is downloaded' do
  files = Dir.glob(File.join(Dir.tmpdir, '*__mods.xml'))

  downloaded_file = nil
  files.each do |file|
    downloaded_file = file if file.include?("Digital_Object_Identifier_#{@uuid}".gsub('-', ''))
  end

  expect(downloaded_file).to_not eq nil

  file_string = File.read(downloaded_file)

  expect(file_string).to include '<mods version="3.4" xmlns="http://www.loc.gov/mods/v3">'
  expect(file_string).to include "<title>Digital Object Title #{@uuid}</title>"
end

Then 'a METS XML file is downloaded' do
  files = Dir.glob(File.join(Dir.tmpdir, '*__mets.xml'))

  downloaded_file = nil
  files.each do |file|
    downloaded_file = file if file.include?("Digital_Object_Identifier_#{@uuid}".gsub('-', ''))
  end

  expect(downloaded_file).to_not eq nil

  file_string = File.read(downloaded_file)

  expect(file_string).to include '<mets xmlns="http://www.loc.gov/METS/" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:mods="http://www.loc.gov/mods/v3" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.loc.gov/METS/ https://www.loc.gov/standards/mets/mets.xsd">'
  expect(file_string).to include "<mods:title xmlns:mods=\"http://www.loc.gov/mods/v3\">Digital Object Title #{@uuid}</mods:title>"
end

Then 'a DC XML file is downloaded' do
  files = Dir.glob(File.join(Dir.tmpdir, '*__dc.xml'))

  downloaded_file = nil
  files.each do |file|
    downloaded_file = file if file.include?("Digital_Object_Identifier_#{@uuid}".gsub('-', ''))
  end

  expect(downloaded_file).to_not eq nil

  file_string = File.read(downloaded_file)

  expect(file_string).to include '<dc xmlns="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://purl.org/dc/elements/1.1/ https://dublincore.org/schemas/xmls/qdc/2006/01/06/dc.xsd http://purl.org/dc/terms/ https://dublincore.org/schemas/xmls/qdc/2006/01/06/dcterms.xsd">' # rubocop:disable Layout/LineLength:
  expect(file_string).to include "<title>Digital Object Title #{@uuid}</title>"
end
