require 'spec_helper'

# Covers migration 182, which bumps the system_mtime of the records whose thumbnail the new display
# rules may change, so that the indexer picks them up.
describe 'Migration 182: reindex published records with digital objects' do
  let(:migration) {
    migration_file = File.join(File.dirname(__FILE__), '../../common/db/migrations/182_reindex_published_records_with_digital.rb')
    eval(File.read(migration_file), TOPLEVEL_BINDING, migration_file)
  }

  let(:long_ago) { Time.utc(2000, 1, 1) }
  let(:published_digital_object) { create(:json_digital_object, publish: true, file_versions: []) }
  let(:unpublished_digital_object) { create(:json_digital_object, publish: false, file_versions: []) }

  def digital_instance(digital_object, is_representative: true)
    build(:json_instance_digital, digital_object: { ref: digital_object.uri }, is_representative: is_representative)
  end

  def resource(publish: true, instances: [])
    create(:json_resource, publish: publish, instances: instances)
  end

  def archival_object(resource, publish: true, instances: [])
    create(:json_archival_object, resource: { ref: resource.uri }, publish: publish, instances: instances)
  end

  # Applies the migration to records whose system_mtime is long ago, and returns whether each was touched
  def touched(records)
    DB.open do |db|
      records.each { |record| record_model(record).filter(:id => record.id).update(:system_mtime => long_ago) }
      migration.apply(db, :up)
      records.map { |record| record_model(record)[record.id].system_mtime > long_ago }
    end
  end

  def record_model(record)
    {
      'accession' => Accession,
      'resource' => Resource,
      'archival_object' => ArchivalObject,
      'digital_object' => DigitalObject,
      'digital_object_component' => DigitalObjectComponent,
    }.fetch(record.jsonmodel_type)
  end

  describe 'records with their own instance' do
    it 'touches published accessions, resources and archival objects linked to a published digital object' do
      accession = create(:json_accession, publish: true, instances: [digital_instance(published_digital_object)])
      linked_resource = resource(instances: [digital_instance(published_digital_object)])
      linked_archival_object = archival_object(resource(publish: false), instances: [digital_instance(published_digital_object)])

      expect(touched([accession, linked_resource, linked_archival_object])).to eq([true, true, true])
    end

    it 'does not touch unpublished records' do
      unpublished_resource = resource(publish: false, instances: [digital_instance(published_digital_object)])

      expect(touched([unpublished_resource])).to eq([false])
    end

    it 'does not touch records linked only to an unpublished digital object' do
      linked_resource = resource(instances: [digital_instance(unpublished_digital_object)])

      expect(touched([linked_resource])).to eq([false])
    end
  end

  describe 'resources whose thumbnail may come from their tree' do
    it 'touches a published resource with a published archival object whose representative instance links to a published digital object' do
      tree_resource = resource
      archival_object(tree_resource, instances: [digital_instance(published_digital_object)])

      expect(touched([tree_resource])).to eq([true])
    end

    it 'does not touch the resource when the archival object is unpublished' do
      tree_resource = resource
      archival_object(tree_resource, publish: false, instances: [digital_instance(published_digital_object)])

      expect(touched([tree_resource])).to eq([false])
    end

    it 'does not touch the resource when the archival object is suppressed' do
      tree_resource = resource
      suppressed = archival_object(tree_resource, instances: [digital_instance(published_digital_object)])
      ArchivalObject[suppressed.id].set_suppressed(true)

      expect(touched([tree_resource])).to eq([false])
    end

    it 'does not touch the resource when the archival object instance is not representative' do
      tree_resource = resource
      archival_object(tree_resource, instances: [digital_instance(published_digital_object, is_representative: false)])

      expect(touched([tree_resource])).to eq([false])
    end

    it 'does not touch the resource when the digital object is unpublished' do
      tree_resource = resource
      archival_object(tree_resource, instances: [digital_instance(unpublished_digital_object)])

      expect(touched([tree_resource])).to eq([false])
    end

    it 'does not touch an unpublished resource' do
      tree_resource = resource(publish: false)
      archival_object(tree_resource, instances: [digital_instance(published_digital_object)])

      expect(touched([tree_resource])).to eq([false])
    end
  end

  describe 'digital records' do
    it 'touches published digital objects and digital object components, and no unpublished ones' do
      published_component = create(:json_digital_object_component, publish: true, file_versions: [],
                                                                    digital_object: { ref: published_digital_object.uri })
      unpublished_component = create(:json_digital_object_component, publish: false, file_versions: [],
                                                                      digital_object: { ref: published_digital_object.uri })

      expect(touched([published_digital_object, published_component, unpublished_digital_object, unpublished_component]))
        .to eq([true, true, false, false])
    end
  end
end
