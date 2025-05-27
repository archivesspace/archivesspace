# frozen_string_literal: true

Then 'an EAC-CPF XML file is downloaded' do
  files = Dir.glob(File.join(Dir.tmpdir, '*.xml'))

  first_part_of_uuid = @uuid.split('-').pop

  downloaded_file = nil
  files.each do |file|
    downloaded_file = file if file.include?('__eac.xml') &&
                              file.include?(first_part_of_uuid)
  end

  expect(downloaded_file).to_not eq nil

  load_file = File.read(downloaded_file)
  expect(load_file).to include '<eac-cpf'
  expect(load_file).to include '<entityType>person</entityType>'
  expect(load_file).to include "<part localType=\"surname\">Agent #{@uuid}</part>"
end

Then 'a MARC XML file is downloaded' do
  files = Dir.glob(File.join(Dir.tmpdir, '*.xml'))

  first_part_of_uuid = @uuid.split('-').pop

  downloaded_file = nil
  files.each do |file|
    downloaded_file = file if file.include?('__marc.xml') &&
                              file.include?(first_part_of_uuid)
  end

  expect(downloaded_file).to_not eq nil

  load_file = File.read(downloaded_file)
  expect(load_file).to include '<collection'
  expect(load_file).to include "<subfield code=\"a\">Agent #{@uuid}, Agent Rest of Name #{@uuid}</subfield>"
end
