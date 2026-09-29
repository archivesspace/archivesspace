require 'spec_helper'
require 'rails_helper'

describe SearchController, type: :controller do
  render_views

  before :each do
    allow(controller).to receive(:unauthorised_access).and_return(true)
    allow(controller).to receive(:load_repository_list).and_return([])
  end

  describe 'Search: context filter term params' do
    let(:raw_search_data) {
      {
        "page_size"=>10,
        "first_page"=>1,
        "last_page"=>90,
        "this_page"=>1,
        "offset_first"=>1,
        "offset_last"=>10,
        "total_hits"=>10,
        "results"=> (1..10).map { |i| {
                                    "id" => i.to_s,
                                    "title" => "Example #{i}",
                                    "types" => ["archival_object"],
                                    "json" => {}.to_json,
                                    "resource" => "/repositories/999/resources#{i}",
                                  }
        },
        "facets" => {
          "facet_fields" => []
        }
      }
    }

    let(:preferences_with_browse_columns_populated) {
      {
        "defaults" => {
          "archival_object_browse_column_1" => "title",
          "archival_object_browse_column_2" => "context",
          "archival_object_browse_column_3" => "identifier",
          "archival_object_browse_column_4" => "dates",
          "archival_object_browse_column_5" => "extents"
        }
      }
    }

    it 'does not render a context column in results if the search uses a context filter term' do
      session = User.login('admin', 'admin')
      User.establish_session(controller, session, 'admin')
      controller.session[:repo_id] = 999
      allow(JSONModel::HTTP).to receive(:get_json) do |endpoint, criteria|
        expect(criteria["filter_term[]"]).to include({"level" => "item"}.to_json)
        expect(criteria["filter_term[]"]).to include({"resource" => "/repositories/999/resources/999"}.to_json)
        raw_search_data
      end
      allow(JSONModel::HTTP).to receive(:get_json)
                                  .with("/repositories/999/current_preferences")
                                  .and_return(preferences_with_browse_columns_populated)
      allow(JSONModel::HTTP).to receive(:get_json)
                                  .with("/current_global_preferences")
                                  .and_return(preferences_with_browse_columns_populated)
      get :do_search, format: :js, params: {
            "filter_term[]" => {"level" => "item"}.to_json,
            "context_filter_term[]" => {"resource" => "/repositories/999/resources/999"}.to_json,
            "type[]" => "archival_object"
          }, xhr: true
      body = Nokogiri::HTML.parse(response.body)
      expect(body.xpath("//th[starts-with(@class, 'col title')]").size).to eq 1
      expect(body.xpath("//th[starts-with(@class, 'col context')]").size).to eq 0
    end

    it 'works even if there is no user-selected filter term' do
      session = User.login('admin', 'admin')
      User.establish_session(controller, session, 'admin')
      controller.session[:repo_id] = 999
      allow(JSONModel::HTTP).to receive(:get_json) do |endpoint, criteria|
        expect(criteria["filter_term[]"]).to include({"resource" => "/repositories/999/resources/999"}.to_json)
        raw_search_data
      end
      allow(JSONModel::HTTP).to receive(:get_json)
                                  .with("/repositories/999/current_preferences")
                                  .and_return(preferences_with_browse_columns_populated)
      allow(JSONModel::HTTP).to receive(:get_json)
                                  .with("/current_global_preferences")
                                  .and_return(preferences_with_browse_columns_populated)

      get :do_search, format: :js, params: {
            "context_filter_term[]" => {"resource" => "/repositories/999/resources/999"}.to_json,
            "type[]" => "archival_object"
          }, xhr: true
      body = Nokogiri::HTML.parse(response.body)
      expect(body.xpath("//th[starts-with(@class, 'col title')]").size).to eq 1
      expect(body.xpath("//th[starts-with(@class, 'col context')]").size).to eq 0
    end
  end

  describe 'Advanced Search' do
    it 'supports chaining an :aq query field in the request params' do
      search = class_double("Search").
                 as_stubbed_const

      allow(search).to receive(:all) { |_, params|
        expect(params.keys).to include "aq"
        aq = JSON.parse(params["aq"])
        expect(aq["query"]["subqueries"].map { |sq| sq["field"] }).to eq ["foo", "unfoo"]
      }

      get :advanced_search, params: { aq: JSON({ query: { field: 'foo', value: 'bar', jsonmodel_type: 'field_query' } }),
                                      advanced: true,
                                      f1: "unfoo",
                                      v1: "unbar",
                                      op1: "AND",
                                    }, format: :json
    end
  end

  context 'thumbnail column in search results' do

    RECORD_TYPES = %w(digital_object digital_object_component resource accession archival_object)

    def stub_search_results
      allow(JSONModel::HTTP).to receive(:get_json) do |endpoint, criteria|
        record_types = criteria.has_key?("type[]") ? criteria["type[]"] : RECORD_TYPES
        {
          "page_size"=>10,
          "first_page"=>1,
          "last_page"=>90,
          "this_page"=>1,
          "offset_first"=>1,
          "offset_last"=>10,
          "total_hits"=>10,
          "results"=> record_types.map { |type| {
                                           "id" => "abc",
                                           "title" => "Example",
                                           "types" => [type],
                                           "json" => {
                                             "uri" => "/repositories/999/#{type}s/1",
                                             "thumbnail" => {
                                               "image_url" => "http://foo.com/bar.jpg",
                                               "caption" => "A caption",
                                             }
                                           }.to_json,
                                           "resource" => "/repositories/999/resources/999",
                                         }
          },
          "facets" => {
            "facet_fields" => []
          }
        }
      end
    end

    def stub_browse_column_preference(value)
      preference_prefixes = RECORD_TYPES + ['multi']
      allow(JSONModel::HTTP).to receive(:get_json)
                                  .with("/repositories/999/current_preferences")
                                  .and_return({
                                                "defaults" => Hash[preference_prefixes.map { |record_type|
                                                                     ["#{record_type}_browse_column_1", value]
                                                                   }]})
    end

    before(:each) do
      session = User.login('admin', 'admin')
      User.establish_session(controller, session, 'admin')
      controller.session[:repo_id] = 999

      stub_search_results
    end

    context 'when chosen in the browse column preferences' do
      before(:each) do
        stub_browse_column_preference('thumbnail')
      end

      RECORD_TYPES.each do |record_type|
        it "shows the thumbnail when searching for #{record_type}" do
          get :do_search, format: :js, params: {
                "type[]" => record_type
              }, xhr: true

          body = Nokogiri::HTML.parse(response.body)
          expect(body.xpath("//th[contains(@class, 'thumbnail-column')]").size).to eq 1
          expect(body.css("td.thumbnail-column img[src='http://foo.com/bar.jpg'][alt='A caption']").size).to eq 1
        end
      end

      it "shows the thumbnail when searching across types" do
        get :do_search, format: :js, params: {}, xhr: true

        body = Nokogiri::HTML.parse(response.body)
        expect(body.xpath("//th[contains(@class, 'thumbnail-column')]").size).to eq 1
        expect(body.css("td.thumbnail-column img[src='http://foo.com/bar.jpg']").size).to eq RECORD_TYPES.length
      end
    end

    it "is not shown when not chosen in the browse column preferences" do
      stub_browse_column_preference('title')

      get :do_search, format: :js, params: {}, xhr: true

      body = Nokogiri::HTML.parse(response.body)
      expect(body.xpath("//th[contains(@class, 'thumbnail-column')]").size).to eq 0
    end

    (RECORD_TYPES + ['multi']).each do |record_type|
      it "is a browse column option but not a sort column option for #{record_type}" do
        properties = JSONModel(:defaults).schema['properties']

        expect(properties["#{record_type}_browse_column_1"]['enum']).to include('thumbnail')
        expect(properties["#{record_type}_sort_column"]['enum']).not_to include('thumbnail')
      end
    end
  end
end
