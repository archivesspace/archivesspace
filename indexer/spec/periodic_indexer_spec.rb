require_relative 'spec_helper'
require_relative '../app/lib/periodic_indexer'

describe "indexer" do

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
               'has_unpublished_ancestor' => true)

    indexer.prepare_docs([ao])

    doc = indexer.records[0]
    expect(doc.fetch('publish')).to eq(false)
  end

end
