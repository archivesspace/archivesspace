require 'spec_helper'
require_relative '../app/lib/indexer_common'

describe "indexer common" do
  let (:indexer) { IndexerCommon.new(AppConfig[:backend_url]) }

  let (:resource) {
    resource = create(:json_resource,
                      publish: true,
                      instances: [],
                      notes: [
                        build(:json_note_multipart,
                              subnotes: [
                                build(:json_note_text, publish: true, content: "had 5 wives"),
                                build(:json_note_text, publish: false, content: "..and 12 mistresses")
                              ])
                      ])
    resolved = IndexerCommonConfig.resolved_attributes
    resource = JSONModel(:resource).find(resource.id, 'resolve[]' => resolved)
    resource
  }

  let(:container_profile) {
    create(:json_container_profile, notes: "Unlike other record types, my notes property is a String")
  }

  describe "Mapping JSONModel(:type) records to documents for Solr" do

    it "creates published-only versions of 'fullrecord' and 'notes' index fields" do
      allow(IndexBatch).to receive(:new) { [] }

      allow(indexer).to receive(:index_batch) do |batch, timing = IndexerTiming.new, opts = {}|
        fullrecord = batch.first['fullrecord'].join(' ')
        expect(fullrecord).not_to include("5 wives")
        expect(fullrecord).to include("12 mistresses")

        fullrecord_published = batch.first['fullrecord_published'].join(' ')
        expect(fullrecord_published).to include("5 wives")
        expect(fullrecord_published).not_to include("12 mistresses")

        notes = batch.first['notes'].join(' ')
        expect(notes).not_to include("5 wives")
        expect(notes).to include("12 mistresses")

        notes_published = batch.first['notes_published'].join(' ')
        expect(notes_published).to include("5 wives")
        expect(notes_published).not_to include("12 mistresses")
      end

      records = [
        {
          'uri' => resource.uri,
          'record' => resource.to_hash(:trusted)
        }
      ]

      indexer.index_records(records)
    end

  end

  it "can deal with schema that have a 'notes' property that takes strings" do
    allow(IndexBatch).to receive(:new) { [] }

    allow(indexer).to receive(:index_batch) do |batch, timing = IndexerTiming.new, opts = {}|
      fullrecord = (batch.first['fullrecord_published'] + batch.first['fullrecord']).join(' ')
      expect(fullrecord).to include(container_profile.notes)
    end

    records = [
      {
        'uri' => container_profile.uri,
        'record' => container_profile.to_hash(:trusted)
      }
    ]

    indexer.index_records(records)
  end

end
