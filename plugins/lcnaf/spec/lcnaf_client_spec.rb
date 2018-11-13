require_relative 'spec_helper'
require_relative '../frontend/models/opensearcher.rb'
require_relative '../frontend/models/sruquery.rb'
require_relative '../frontend/models/srusearcher.rb'



describe "id.loc.gov clientware" do

  before(:all) do
    Net::HTTP.class_eval do

      class << self
        alias_method :get_response_orig, :get_response


        def xget_response(uri)
          response = OpenStruct.new
          response.code = '200'
          response.body = ''

          if uri.host == 'id.loc.gov' && uri.query && uri.query.match(/start=21/)
            puts "Mocking LOC response #{uri.query}"
            response.body = IO.read(File.join(File.dirname(__FILE__), 'mocks/loc_search_page2.json'))
          elsif uri.host == 'id.loc.gov' && uri.query
            puts "Mocking LOC response"
            response.body = IO.read(File.join(File.dirname(__FILE__), 'mocks/loc_search.json'))

          elsif uri.host == 'alcme.oclc.org'
            puts "Mocking OCLC Response"
            response.body = IO.read(File.join(File.dirname(__FILE__), 'mocks/oclc_search.xml'))
          end

          response
        end
      end

    end
  end

  after(:all) do
    Net::HTTP.class_eval do

      class << self
        alias_method :get_response, :get_response_orig
      end
    end
  end


  let(:loc_searcher) {
    OpenSearcher.new("http://id.loc.gov/search/")
  }

  let(:oclc_searcher) {
    SRUSearcher.new("http://alcme.oclc.org/srw/search/lcnaf")
  }


  describe "OpenSearch client tools" do

    it "can query id.loc.gov and return a result set object" do
      results = loc_searcher.search('franklin', 1, 20)

      expect(results.class.name).to eq('OpenSearchResultSet')

      expect(results.total_results.to_s).to match /^\d+$/
      expect(results.start_index).to eq(1)
      expect(results.items_per_page).to eq(20)

      expect(results.entries[0]['title']).to eq('Franklin')
      expect(results.entries[0]['uri']).to match(/http:\/\/id\.loc\.gov\/authorities\/names\/n\d+/)
    end


    it "can get the second page" do
      results = loc_searcher.search('franklin', 2, 20)
      expect(results.start_index).to eq(21)
      expect(results.entries[0]['title']).to eq('Edminster, C. Franklin (Clothier Franklin), -1932')
    end


    it "can take a set of IDs and make a marcxml collection of the records" do
      lccns = %w(no92032176 nr91032543)
      marcxml_file = loc_searcher.results_to_marcxml_file(lccns)
      puts IO.read(marcxml_file)
    end

  end

  describe "common result structure" do

    let(:loc_results) {
      ASUtils.json_parse(loc_searcher.search('franklin', 1, 20).to_json)
    }

    let (:oclc_results) {
      ASUtils.json_parse(oclc_searcher.search(SRUQuery.name_search('franklin', ''), 1, 20).to_json)
    }


    xit "has the pagination values required by the client" do
      [loc_results, oclc_results].each do |results|
        expect(results['first_record_index']).to eq(1)
        expect(results['last_record_index']).to eq(20)
      end

    end
  end

end
