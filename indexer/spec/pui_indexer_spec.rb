require 'spec_helper'
require_relative '../app/lib/pui_indexer'

describe "PUI indexer" do
  let (:indexer) do
    indexer = PUIIndexer.new(AppConfig[:backend_url], nil, 'PUIIndexer')

    def indexer.prepare_docs(records)
      records.map {|rec|
        rec_hash = rec.to_hash(:raw)
        rec_hash['display_string'] = rec_hash['title']

        {'record' => rec_hash, 'uri' => rec['uri']}
      }
    end

    # We run the first portion of the index here so that we can separate out the 
    # initial doc rules and the final doc rules.
    # This is ugly because we are copy/pasting from IndexerCommon index_records
    # with no way to know if that method changes.
    def indexer.start_index(record)

      # c/p start
      values = record['record']
      uri = record['uri']

      reference = JSONModel.parse_reference(uri)
      record_type = reference && reference[:type]

      doc = {}

      doc['id'] = uri
      doc['uri'] = uri
      doc['title'] = values['title']
      doc['primary_type'] = record_type
      doc['types'] = [record_type]
      doc['json'] = ASUtils.to_json(sanitize_json(values))
      doc['suppressed'] = values.has_key?('suppressed') && values['suppressed']
      if doc['suppressed']
        doc['publish'] = false
      elsif is_repository_unpublished?(uri, values)
        doc['publish'] = false
      elsif values['has_unpublished_ancestor']
        doc['publish'] = false
      else
        doc['publish'] = values.has_key?('publish') && values['publish']
      end
      doc['system_generated'] = values.has_key?('system_generated') ? values['system_generated'].to_s : 'false'
      doc['repository'] = get_record_scope(uri)
      # c/p end

      doc
    end

    def indexer.run_all_but_final_doc_rules(doc, rec)
      @document_prepare_hooks.each_with_index do |hook, idx|
        unless idx == @document_prepare_hooks.count - 1
          hook.call(doc, rec)
        end
      end
    end

    def indexer.run_final_doc_rules(doc, rec)
      @document_prepare_hooks.last.call(doc, rec)
    end

    indexer
  end
  describe "initialize" do
    it "initializes appropriately" do
    #    def initialize(backend = nil, state = nil, name)
    end
  end
  describe "fetch_records" do
    it "fetches records" do
    #    def fetch_records(type, ids, resolve)
    end
  end
  describe "get_indexer" do
    it "gets an indexer" do
    #    def self.get_indexer(state = nil, name = "PUI Indexer")
    end
  end
  describe "resolved_attributes" do
    it "returns resolved attributes" do
    #   def resolved_attributes
    end
  end
  describe "record_types" do
    it "returns record types" do
    #    def record_types
    end
  end
  describe "configure_doc_rules" do
    it "configures document rules" do
    #    def configure_doc_rules
    end
  end
  describe "add_infscroll_docs" do
    it "adds infscroll docs" do
    #    def add_infscroll_docs(resource_uris, batch)
    end
  end
  describe "skip_index_record?" do
    it "determines if it should skip index record" do
    # def skip_index_record?(record)
    end
  end
  describe "skip_index_doc?" do
    it "determines if it should skip index doc" do
      # def skip_index_doc?(doc)
    end
  end
  describe "index_round_complete" do
    it "determines when the index round is complete" do
      # def index_round_complete(repository)
    end
  end
  describe "stage_unpublished_for_deletion" do
    it "stages unpublished records for deletion" do
      # def stage_unpublished_for_deletion(doc_id)
    end
  end

  describe "final_doc_rules" do
    it "runs final PUI doc rules and removes ancestor data after all other hooks have run" do
      res = build(:json_resource,
                 'uri' => '/repositories/2/resources/1',
                 'title' => "Resource",
                 'repository' => {
                   'ref' => '/repositories/2',
                   '_resolved' => {
                     'repo_code' => 'woop',
                   },
                 },
                 'publish' => true,
                 'instances' => [])

      ao = build(:json_archival_object,
                 'uri' => '/repositories/2/archival_objects/123',
                 'title' => "AO with ancestor",
                 'repository' => {
                   'ref' => '/repositories/2',
                   '_resolved' => {
                     'repo_code' => 'woop',
                   },
                 },
                 'publish' => true,
                 'has_unpublished_ancestor' => false,
                 'instances' => [],
                 'ancestors' => [{
                    "ref" => "/repositories/2/resources/1",
                    "_resolved" => res
                  }],
                 'resource' => "/repositories/2/resources/1")

      rec = indexer.prepare_docs([ao]).first
      doc = indexer.start_index(rec)

      indexer.run_all_but_final_doc_rules(doc, rec)
      expect(rec['record']['ancestors'].count).to be(1)

      indexer.run_final_doc_rules(doc, rec)
      expect(rec['record']['ancestors']).to be_nil

    end
  end
end
