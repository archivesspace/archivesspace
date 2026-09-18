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
end
