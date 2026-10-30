require "spec_helper"
require_relative "../app/lib/bulk_import/import_digital_objects.rb"
require_relative "lib_bulk_import_import_digital_objects_shared_context"
require_relative "thumbnail_spec_helper"

require 'rubyXL/convenience_methods/cell'

describe "Import Digital Objects digital_object_is_representative" do
  include_context "digital object importer harness"
  include ThumbnailSpecHelper

  def template_path(extension)
    File.join(ASUtils.find_base_directory, "frontend", "public", "bulk_import_templates", "bulk_import_DO_template.#{extension}")
  end

  # A published digital object with a display thumbnail, marked representative of @archival_object
  def representative_row(image_url, values = {})
    { 'res_uri' => @resource.uri,
      'ao_uri' => @archival_object.uri,
      'digital_object_publish' => 'TRUE',
      'digital_object_is_representative' => 'TRUE',
      'file_version_1_file_uri' => image_url,
      'file_version_1_is_display_thumbnail' => 'TRUE' }.merge(values)
  end

  def import_rows(*rows, validate_only: false)
    columns, explanations = CSV.read(template_path("csv"))
    blank = columns.to_h { |column| [column, nil] }
    import_digital_object_csv(columns, explanations, *rows.map { |row| blank.merge(row) }, validate_only: validate_only)
  end

  def import_xlsx_row(row)
    workbook = RubyXL::Parser.parse(template_path("xlsx"))
    sheet = workbook['Data']
    columns = sheet[3].cells.map(&:value)
    row.each { |column, value| sheet.add_cell(5, columns.index(column), value) }
    path = File.join(Dir.tmpdir, "bulk_import_DO_template_#{@now}_#{SecureRandom.uuid}.xlsx")
    workbook.save(path)
    opts = { :repo_id => @resource[:repo_id], :rid => @resource[:id], :type => "resource",
             :filename => File.basename(path), :filepath => path, :load_type => "digital_object" }

    ImportDigitalObjects.new(path, "xlsx", @current_user, opts).run
  end

  def archival_object(record = @archival_object)
    ArchivalObject.to_jsonmodel(record.id)
  end

  let(:not_representative) { I18n.t('bulk_import.error.dig_not_representative') }

  it 'makes the instance representative, so the archival object shows the thumbnail of its digital object' do
    report = import_rows(representative_row('http://example.com/first.jpg'))

    expect(report.rows[0].errors).to eq([])
    expect(archival_object['instances'].map { |instance| instance['is_representative'] }).to eq([true])
    expect(archival_object['thumbnail']['image_url']).to eq('http://example.com/first.jpg')
  end

  it 'makes the instance representative from the Excel template' do
    report = import_xlsx_row(representative_row('http://example.com/first.jpg'))

    expect(report.terminal_error).to be_nil
    expect(report.rows[0].errors).to eq([])
    expect(archival_object['instances'].map { |instance| instance['is_representative'] }).to eq([true])
  end

  it 'leaves the instance not representative when blank' do
    report = import_rows(representative_row('http://example.com/first.jpg', 'digital_object_is_representative' => nil))

    expect(report.rows[0].errors).to eq([])
    expect(archival_object['instances'].map { |instance| instance['is_representative'] }).to eq([false])
    expect(archival_object['thumbnail']).to be_nil
  end

  it 'reports a value that is not a boolean and creates no digital object' do
    expect {
      report = import_rows(representative_row('http://example.com/first.jpg', 'digital_object_is_representative' => 'maybe'))

      expect(report.rows[0].errors).to include(I18n.t('bulk_import.error.unrecognized_boolean', :column => 'digital_object_is_representative', :value => 'maybe'))
    }.not_to change { DigitalObject.count }
    expect(archival_object['instances']).to eq([])
  end

  it 'makes only the first of several rows marked for the same archival object representative' do
    report = import_rows(representative_row('http://example.com/first.jpg'),
                         representative_row('http://example.com/second.jpg'),
                         representative_row('http://example.com/third.jpg'))

    expect(report.rows.map(&:errors)).to eq([[], [not_representative], [not_representative]])
    expect(report.rows[1].info).to include(I18n.t('bulk_import.dig_assoc'))
    expect(archival_object['instances'].map { |instance| instance['is_representative'] }).to eq([true, false, false])
    expect(archival_object['thumbnail']['image_url']).to eq('http://example.com/first.jpg')
  end

  it 'makes the first row marked representative even when an earlier row for the archival object is not' do
    report = import_rows(representative_row('http://example.com/first.jpg', 'digital_object_is_representative' => nil),
                         representative_row('http://example.com/second.jpg'))

    expect(report.rows.map(&:errors)).to eq([[], []])
    expect(archival_object['instances'].map { |instance| instance['is_representative'] }).to eq([false, true])
  end

  it 'keeps the representative instance the archival object already has' do
    existing = digital_object_with([image_file_version(:file_uri => 'http://example.com/existing.jpg', :is_display_thumbnail => true)])
    record = create(:json_archival_object, :resource => { :ref => @resource.uri }, :instances => [representative_instance(existing)])

    report = import_rows(representative_row('http://example.com/first.jpg', 'ao_uri' => record.uri))

    expect(report.rows[0].errors).to eq([not_representative])
    expect(report.rows[0].info).to include(I18n.t('bulk_import.dig_assoc'))
    instances = archival_object(record)['instances']
    expect(instances.map { |instance| [instance['digital_object']['ref'] == existing.uri, instance['is_representative']] })
      .to eq([[true, true], [false, false]])
    expect(archival_object(record)['thumbnail']['image_url']).to eq('http://example.com/existing.jpg')
  end

  it 'reports the rows that would not be made representative when only validating' do
    expect {
      report = import_rows(representative_row('http://example.com/first.jpg'),
                           representative_row('http://example.com/second.jpg'),
                           validate_only: true)

      expect(report.rows.map(&:errors)).to eq([[], [not_representative]])
    }.not_to change { DigitalObject.count }
    expect(archival_object['instances']).to eq([])
  end
end
