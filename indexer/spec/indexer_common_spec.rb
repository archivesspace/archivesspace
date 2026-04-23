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

  describe "mlc_fields indexing" do
    # Builds a full resource record hash (via the +resource+ fixture) with
    # +mlc_fields+ injected so the document_prepare_hook can turn it into
    # +<field>_<lang>_mlc+ dynamic Solr fields.
    def resource_record_with_mlc(mlc)
      hash = resource.to_hash(:trusted)
      hash['mlc_fields'] = mlc
      {'uri' => resource.uri, 'record' => hash}
    end

    def capture_indexed_doc
      captured = nil
      allow(indexer).to receive(:index_batch) do |batch, *_|
        captured = batch.first
      end
      yield
      captured
    end

    it "emits a per-language dynamic field for every (lang, field) pair" do
      allow(IndexBatch).to receive(:new) { [] }

      doc = capture_indexed_doc do
        indexer.index_records([
          resource_record_with_mlc({
            "eng_Latn" => {"title" => "English title",    "finding_aid_title" => "English FA"},
            "fre_Latn" => {"title" => "Titre français"}
          })
        ])
      end

      expect(doc['title_eng_mlc']).to eq("English title")
      expect(doc['title_fre_mlc']).to eq("Titre français")
      expect(doc['finding_aid_title_eng_mlc']).to eq("English FA")
    end

    it "never emits fields listed in fullrecord_excludes" do
      allow(IndexBatch).to receive(:new) { [] }

      doc = capture_indexed_doc do
        indexer.index_records([
          resource_record_with_mlc({
            "eng_Latn" => {"finding_aid_filing_title" => "Filed under F"}
          })
        ])
      end

      expect(doc).not_to have_key('finding_aid_filing_title_eng_mlc')
    end

    it "skips nil and empty string values" do
      allow(IndexBatch).to receive(:new) { [] }

      doc = capture_indexed_doc do
        indexer.index_records([
          resource_record_with_mlc({
            "eng_Latn" => {"title" => "Real value", "label" => nil, "display_string" => ""}
          })
        ])
      end

      expect(doc['title_eng_mlc']).to eq("Real value")
      expect(doc).not_to have_key('label_eng_mlc')
      expect(doc).not_to have_key('display_string_eng_mlc')
    end

    it "routes every mlc variant into fullrecord_published via extract_string_values" do
      allow(IndexBatch).to receive(:new) { [] }

      doc = capture_indexed_doc do
        indexer.index_records([
          resource_record_with_mlc({
            "eng_Latn" => {"title" => "EnglishMLCTitle"},
            "fre_Latn" => {"title" => "TitreFrançaisMLC"}
          })
        ])
      end

      fullrecord_published = (doc['fullrecord_published'] || []).join(' ')
      expect(fullrecord_published).to include("EnglishMLCTitle")
      expect(fullrecord_published).to include("TitreFrançaisMLC")
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
