require_relative 'spec_helper'
require_relative '../models/opensearcher.rb'
require_relative '../models/http_request.rb'



describe "id.loc.gov clientware" do

  let(:loc_searcher) {
    OpenSearcher.new('https://id.loc.gov/search/', 'http://id.loc.gov/authorities/names')
  }


  describe "OpenSearch client tools" do

    it "can query id.loc.gov and return a result set object" do
      results = loc_searcher.search('franklin', 1, 20)

      expect(results.class.name).to eq('OpenSearchResultSet')

      expect(results.total_results.to_s).to match (/^\d+$/)
      expect(results.start_index).to eq(1)
      expect(results.items_per_page).to eq(20)

      expect(results.entries[0]['title']).to eq('Franklin')
      expect(results.entries[0]['uri']).to match(/http:\/\/id\.loc\.gov\/authorities\/names\/n\S+/)
    end


    it "can get the second page" do
      results = loc_searcher.search('franklin', 2, 20)

      expect(results.class.name).to eq('OpenSearchResultSet')

      expect(results.total_results.to_s).to match (/^\d+$/)
      expect(results.start_index).to eq(21)
      expect(results.items_per_page).to eq(20)

      expect(results.entries[0]['uri']).to match(/http:\/\/id\.loc\.gov\/authorities\/names\/n\S+/)
    end


    it "can take a set of IDs and make an individual marcxml file for each record sorted by type" do
      lccns = %w(no92032176 nr91032543 n80010207)
      marcxml_files = loc_searcher.results_to_marcxml_file(lccns)

      expect(marcxml_files[:subjects].length).to eq(1)
      expect(marcxml_files[:agents].length).to eq(2)
    end

  end

  describe "common result structure" do

    let(:loc_results) {
      ASUtils.json_parse(loc_searcher.search('franklin', 1, 20).to_json)
    }

    it "has the pagination values required by the client" do
      expect(loc_results['first_record_index']).to eq(1)
      expect(loc_results['last_record_index']).to eq(20)
    end
  end

end
