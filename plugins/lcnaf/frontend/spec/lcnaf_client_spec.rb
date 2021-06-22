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


    it "can take a set of agent IDs and prepare them for the auth importer" do
      lccns = %w(no92032176 nr91032543)
      marcxml_file = loc_searcher.results_to_marcxml_file(lccns)
      expect(marcxml_file[:agents][:count]).to eq(2)
      expect(marcxml_file[:subjects][:count]).to eq(0)
    end


    it "can take a set of subject IDs and prepare them for the bib importer" do
      lccns = %w(n79053099 n81038610)
      marcxml_file = loc_searcher.results_to_marcxml_file(lccns)
      expect(marcxml_file[:agents][:count]).to eq(0)
      expect(marcxml_file[:subjects][:count]).to eq(2)
    end


    it "can take a mixed set of agent and subject IDs and prepare them for the both importers" do
      lccns = %w(no92032176 n81038610)
      marcxml_file = loc_searcher.results_to_marcxml_file(lccns)
      expect(marcxml_file[:agents][:count]).to eq(1)
      expect(marcxml_file[:subjects][:count]).to eq(1)
    end


    it "can take a set of IDs and make a marcxml collection of the records" do
      lccns = %w(no92032176 nr91032543)
      marcxml_file = loc_searcher.results_to_marcxml_file(lccns)
      expect(IO.read(marcxml_file[:agents][:file])).to include("<record>")
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
