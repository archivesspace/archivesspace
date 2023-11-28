require 'spec_helper'
require_relative '../app/lib/periodic_indexer'

describe "periodic indexer" do

  let (:indexer) do
    indexer = PeriodicIndexer.new

    def indexer.index_batch(batch, timing)
      @index_batch = batch
    end

    def indexer.prepare_docs(records)
      prepared_records = records.map {|rec|
        rec_hash = rec.to_hash(:raw)
        rec_hash['display_string'] = rec_hash['title']

        {'record' => rec_hash, 'uri' => rec['uri']}}

      index_records(prepared_records)
    end

    def indexer.records
      result = []

      @index_batch.each do |rec|
        result << rec
      end

      result
    end

    indexer
  end

  describe "initialize" do
    it "initializes the indexer" do
      # def initialize(backend_url = nil, state = nil, indexer_name = nil)
    end
  end
  describe "start_worker_thread" do
    it "starts a worker thread" do
      # def start_worker_thread(queue, record_type)
    end
  end
  describe "run_index_round" do
    it "runs and index round" do
      # def run_index_round
    end
  end
  describe "index_round_complete" do
    it "determines if the index round is complete" do
    # def index_round_complete(repository)
    end
  end
  describe "handle_deletes" do
    it "handles deletes" do
      # def handle_deletes(opts = {})
    end
  end
  describe "run" do
    it "runs the indexer" do
      # def run
    end
  end
  describe "log" do
    it "logs stuff" do
    # def log(line)
    end
  end
  describe "get_indexer" do
    it "gets the indexer" do
      # def self.get_indexer(state = nil, name = "Staff Indexer")
    end
  end
  describe "fetch_records" do
    it "fetches records" do
      # def fetch_records(type, ids, resolve)
    end
  end
  describe "has_unpublished_ancestor" do
    it "indexes the 'has_unpublished_ancestor' property" do
      ao = build(:json_archival_object,
                 'uri' => '/repositories/2/archival_objects/123',
                 'title' => "AO with unpublished ancestor",
                 'repository' => {
                   'ref' => '/repositories/5',
                   '_resolved' => {
                     'repo_code' => 'woop',
                   },
                 },
                 'publish' => true,
                 'has_unpublished_ancestor' => true,
                 'instances' => [],
                 'resource' => "/repositories/5/resources/1")

      indexer.prepare_docs([ao])

      doc = indexer.records[0]
      expect(doc.fetch('publish')).to be_falsey
    end
  end

  describe "identifiers" do
    it "indexes concatenated four part ids as identifiers" do
      records = []

      ['accession', 'resource'].each do |t|
        records << build(:"json_#{t}",
                       'uri' => "/repositories/2/#{t}s/1",
                       'title' => "Test #{t}",
                       'repository' => {
                         'ref' => '/repositories/2',
                         '_resolved' => {
                           'repo_code' => 'test',
                         },
                       },
                       'id_0' => '0',
                       'id_1' => '1',
                       'id_2' => '2',
                       'id_3' => '3',
                       'instances' => [])
      end

      indexer.prepare_docs(records)

      doc = indexer.records
      doc.each do |d|
        expect(d.fetch('identifier')).to eq('0-1-2-3')
      end
    end

    it "indexes component unique ids as identifiers" do
      records = []

      ['archival_object', 'digital_object_component'].each do |t|
        parent_type = (t == 'archival_object') ? 'resource' : 'digital_object'
        records << build(:"json_#{t}",
                       'uri' => "/repositories/2/#{t}s/1",
                       'title' => "Test #{t}",
                       'repository' => {
                         'ref' => '/repositories/2',
                         '_resolved' => {
                           'repo_code' => 'test',
                         },
                       },
                       'component_id' => '0123',
                       "#{parent_type}" => "/repositories/2/#{parent_type}s/1")
      end

      indexer.prepare_docs(records)

      doc = indexer.records
      doc.each do |d|
        expect(d.fetch('identifier')).to eq('0123')
      end
    end

    it "indexes digital object id as identifier" do
      digital_object = build(:json_digital_object,
                     'uri' => "/repositories/2/digital_objects/1",
                     'title' => "Test Digital Object",
                     'repository' => {
                       'ref' => '/repositories/2',
                       '_resolved' => {
                         'repo_code' => 'test',
                       },
                     },
                     'digital_object_id' => '0123')

      indexer.prepare_docs([digital_object])

      doc = indexer.records[0]
      expect(doc.fetch('identifier')).to eq('0123')
    end
  end
end
