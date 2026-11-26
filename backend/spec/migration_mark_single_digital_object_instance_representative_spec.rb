require 'spec_helper'

describe 'Migration 185: mark a single shown digital object instance representative' do
  let(:migration) {
    migration_file = File.join(File.dirname(__FILE__), '../../common/db/migrations/185_mark_single_digital_object_instance_representative.rb')
    eval(File.read(migration_file), TOPLEVEL_BINDING, migration_file)
  }

  let(:long_ago) { Time.utc(2000, 1, 1) }
  let(:resource) { create(:json_resource) }

  def file_version(file_uri = 'https://example.com/image.jpg', xlink_show_attribute: 'embed', publish: true)
    build(:json_file_version, file_uri: file_uri, xlink_show_attribute: xlink_show_attribute, publish: publish)
  end

  def digital_object(*file_versions, publish: true)
    create(:json_digital_object, publish: publish, file_versions: file_versions)
  end

  def instances(*digital_objects, representative: nil)
    digital_objects.map { |digital_object|
      build(:json_instance_digital, digital_object: { ref: digital_object.uri }, is_representative: digital_object == representative)
    }
  end

  def archival_object(*digital_objects, representative: nil)
    create(:json_archival_object, resource: { ref: resource.uri }, instances: instances(*digital_objects, representative: representative))
  end

  def model(record)
    { 'accession' => Accession, 'resource' => Resource, 'archival_object' => ArchivalObject }.fetch(record.jsonmodel_type)
  end

  def migrate(*records)
    DB.open do |db|
      (records + [resource]).each { |record| model(record).filter(:id => record.id).update(:system_mtime => long_ago) }
      migration.apply(db, :up)
    end
  end

  def representative_flags(record)
    model(record).to_jsonmodel(record.id)['instances'].map { |instance| instance['is_representative'] }
  end

  def touched?(record)
    model(record)[record.id].system_mtime > long_ago
  end

  it 'marks the only instance of an archival object shown as an image, and reindexes it and its resource' do
    image = archival_object(digital_object(file_version))

    migrate(image)

    expect(representative_flags(image)).to eq([true])
    expect(touched?(image)).to be true
    expect(touched?(resource)).to be true
  end

  it 'marks the only instance shown as a generic icon, whatever its XLink Show Attribute' do
    new_window = archival_object(digital_object(file_version(xlink_show_attribute: 'new')))
    no_attribute = archival_object(digital_object(file_version(xlink_show_attribute: nil)))

    migrate(new_window, no_attribute)

    expect(representative_flags(new_window)).to eq([true])
    expect(representative_flags(no_attribute)).to eq([true])
  end

  it 'marks the only shown instance when its digital object has several shown file versions' do
    image_and_link = archival_object(digital_object(file_version, file_version('https://example.com/page', xlink_show_attribute: 'new')))

    migrate(image_and_link)

    expect(representative_flags(image_and_link)).to eq([true])
  end

  it 'counts http, https and data: URIs, whatever their case or surrounding whitespace' do
    http = archival_object(digital_object(file_version('http://example.com/image.jpg')))
    upper_case = archival_object(digital_object(file_version('HTTPS://example.com/image.jpg')))
    data_uri = archival_object(digital_object(file_version('data:image/png;base64,iVBORw0KGgo=')))
    padded = digital_object(file_version)
    padded_uri = archival_object(padded)
    DB.open { |db| db[:file_version].filter(:digital_object_id => padded.id).update(:file_uri => " https://example.com/image.jpg\n") }

    migrate(http, upper_case, data_uri, padded_uri)

    expect([http, upper_case, data_uri, padded_uri].map { |record| representative_flags(record) }).to eq([[true]] * 4)
  end

  it 'marks the only shown instance of a resource' do
    own = create(:json_resource, instances: instances(digital_object(file_version(xlink_show_attribute: 'new'))))

    migrate(own)

    expect(representative_flags(own)).to eq([true])
    expect(touched?(own)).to be true
  end

  it 'ignores instances that showed nothing' do
    suppressed = digital_object(file_version)
    with_component_file_version = digital_object
    create(:json_digital_object_component, digital_object: { ref: with_component_file_version.uri }, file_versions: [file_version])
    with_others = archival_object(digital_object(file_version),
                                  digital_object(file_version, publish: false),
                                  suppressed,
                                  digital_object(file_version(publish: false)),
                                  digital_object(file_version('image.jpg')),
                                  digital_object(file_version('ftp://example.com/image.jpg')),
                                  digital_object(file_version('httpx://example.com/image.jpg')),
                                  digital_object,
                                  with_component_file_version)
    DigitalObject[suppressed.id].set_suppressed(true)

    migrate(with_others)

    expect(representative_flags(with_others)).to eq([true] + [false] * 8)
  end

  it 'leaves records with several shown instances alone' do
    several = archival_object(digital_object(file_version), digital_object(file_version(xlink_show_attribute: 'new')))

    migrate(several)

    expect(representative_flags(several)).to eq([false, false])
    expect(touched?(several)).to be false
    expect(touched?(resource)).to be false
  end

  it 'counts each instance of the same digital object' do
    shown = digital_object(file_version)
    linked_twice = archival_object(shown, shown)

    migrate(linked_twice)

    expect(representative_flags(linked_twice)).to eq([false, false])
  end

  it 'leaves records with a representative instance alone' do
    representative = digital_object
    with_representative = archival_object(representative, digital_object(file_version), representative: representative)

    migrate(with_representative)

    expect(representative_flags(with_representative)).to eq([true, false])
    expect(touched?(with_representative)).to be false
  end

  it 'leaves accessions alone' do
    accession = create(:json_accession, instances: instances(digital_object(file_version)))

    migrate(accession)

    expect(representative_flags(accession)).to eq([false])
    expect(touched?(accession)).to be false
  end
end
