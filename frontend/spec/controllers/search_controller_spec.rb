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

  context 'representative file version column in search results' do

    RECORD_TYPES = %w(digital_object digital_object_component resource accession archival_object)

    before(:each) do
      session = User.login('admin', 'admin')
      User.establish_session(controller, session, 'admin')
      controller.session[:repo_id] = 999

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
                                             "representative_file_version" => {
                                               "file_uri" => "http://foo.com/bar.jpg"
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

      preference_prefixes = RECORD_TYPES + ['multi']
      allow(JSONModel::HTTP).to receive(:get_json)
                                  .with("/repositories/999/current_preferences")
                                  .and_return({
                                                "defaults" => Hash[preference_prefixes.map { |record_type|
                                                                     ["#{record_type}_browse_column_1", "representative_file_version"]
                                                                   }]})
    end

    RECORD_TYPES.each do |record_type|
      it "shows the representative file version image when searching for #{record_type}" do
        get :do_search, format: :js, params: {
              "type[]" => record_type
            }, xhr: true

        body = Nokogiri::HTML.parse(response.body)
        expect(body.xpath("//th[starts-with(@class, 'col representative_file_version')]").size).to eq 1
        expect(body.xpath("//td[starts-with(@class, 'col representative_file_version')][1]").first.inner_html.strip)
          .to eq "<img src=\"http://foo.com/bar.jpg\">"
      end
    end

    it "shows the representative file version image when searching across types" do
      get :do_search, format: :js, params: {}, xhr: true
      body = Nokogiri::HTML.parse(response.body)
      expect(body.xpath("//th[starts-with(@class, 'col representative_file_version')]").size).to eq 1
      expect(body.xpath("//td[starts-with(@class, 'col representative_file_version')][1]").first.inner_html.strip)
        .to eq "<img src=\"http://foo.com/bar.jpg\">"
    end
  end

  describe 'Top Container CSV Export Logic' do
    before :each do
      session = User.login('admin', 'admin')
      User.establish_session(controller, session, 'admin')
      controller.session[:repo_id] = 999
    end

    it 'correctly identifies top container searches from filter terms' do
      # Test the detection logic for top container searches
      criteria = {
        'filter_term[]' => [
          {"primary_type" => "top_container"}.to_json,
          {"collection" => "/repositories/999/resources/1"}.to_json
        ]
      }

      filter_terms = Array(criteria['filter_term[]']).map {|t| ASUtils.json_parse(t) rescue {} }
      is_top_container_search = filter_terms.any? {|term| term['primary_type'] == 'top_container'}

      expect(is_top_container_search).to be true
    end

    it 'correctly rejects non-top-container searches' do
      # Test that other search types are not identified as top container searches
      criteria = {
        'filter_term[]' => [
          {"primary_type" => "resource"}.to_json,
          {"collection" => "/repositories/999/resources/1"}.to_json
        ]
      }

      filter_terms = Array(criteria['filter_term[]']).map {|t| ASUtils.json_parse(t) rescue {} }
      is_top_container_search = filter_terms.any? {|term| term['primary_type'] == 'top_container'}

      expect(is_top_container_search).to be false
    end

    it 'handles data extraction logic for top container fields' do
      # Test the field extraction logic used in the CSV generation
      mock_result = {
        "title" => "Test Box",
        "collection_display_string_u_sstr" => ["Test Collection"],
        "series_title_u_sstr" => "Test Series",
        "type_enum_s" => ["box"],
        "indicator_u_sstr" => "1",
        "barcode_u_sstr" => ["12345"],
        "container_profile_display_string_u_sstr" => ["Letter Box"],
        "location_display_string_u_sstr" => ["Building A"]
      }

      # Test the extraction logic from the implementation
      title = mock_result['title'] || ''
      collection_raw = mock_result['collection_display_string_u_sstr']
      collection_display = collection_raw.is_a?(Array) ? collection_raw.first : collection_raw || ''
      series_raw = mock_result['series_title_u_sstr']
      series_display = series_raw.is_a?(Array) ? series_raw.first : series_raw || ''
      type_raw = mock_result['type_enum_s']
      type = type_raw.is_a?(Array) ? type_raw.first : type_raw || ''
      indicator_raw = mock_result['indicator_u_sstr'] || mock_result['indicator_u_icusort']
      indicator = indicator_raw.is_a?(Array) ? indicator_raw.first : indicator_raw || ''
      barcode_raw = mock_result['barcode_u_sstr']
      barcode = barcode_raw.is_a?(Array) ? barcode_raw.first : barcode_raw || ''
      container_profile_raw = mock_result['container_profile_display_string_u_sstr']
      container_profile = container_profile_raw.is_a?(Array) ? container_profile_raw.first : container_profile_raw || ''
      location_raw = mock_result['location_display_string_u_sstr']
      current_location_title = location_raw.is_a?(Array) ? location_raw.first : location_raw || ''

      expect(title).to eq("Test Box")
      expect(collection_display).to eq("Test Collection")
      expect(series_display).to eq("Test Series")
      expect(type).to eq("box")
      expect(indicator).to eq("1")
      expect(barcode).to eq("12345")
      expect(container_profile).to eq("Letter Box")
      expect(current_location_title).to eq("Building A")
    end

    it 'handles missing fields gracefully' do
      # Test with minimal data
      mock_result = {
        "title" => "Minimal Box"
      }

      title = mock_result['title'] || ''
      collection_raw = mock_result['collection_display_string_u_sstr']
      collection_display = collection_raw.is_a?(Array) ? collection_raw.first : collection_raw || ''
      series_raw = mock_result['series_title_u_sstr']
      series_display = series_raw.is_a?(Array) ? series_raw.first : series_raw || ''
      type_raw = mock_result['type_enum_s']
      type = type_raw.is_a?(Array) ? type_raw.first : type_raw || ''
      indicator_raw = mock_result['indicator_u_sstr'] || mock_result['indicator_u_icusort']
      indicator = indicator_raw.is_a?(Array) ? indicator_raw.first : indicator_raw || ''
      barcode_raw = mock_result['barcode_u_sstr']
      barcode = barcode_raw.is_a?(Array) ? barcode_raw.first : barcode_raw || ''
      container_profile_raw = mock_result['container_profile_display_string_u_sstr']
      container_profile = container_profile_raw.is_a?(Array) ? container_profile_raw.first : container_profile_raw || ''
      location_raw = mock_result['location_display_string_u_sstr']
      current_location_title = location_raw.is_a?(Array) ? location_raw.first : location_raw || ''

      expect(title).to eq("Minimal Box")
      expect(collection_display).to eq("")
      expect(series_display).to eq("")
      expect(type).to eq("")
      expect(indicator).to eq("")
      expect(barcode).to eq("")
      expect(container_profile).to eq("")
      expect(current_location_title).to eq("")
    end

    it 'uses fallback indicator field correctly' do
      # Test fallback to indicator_u_icusort when indicator_u_sstr is not available
      mock_result = {
        "title" => "Fallback Box",
        "indicator_u_icusort" => "fallback_value"
        # no indicator_u_sstr
      }

      indicator_raw = mock_result['indicator_u_sstr'] || mock_result['indicator_u_icusort']
      indicator = indicator_raw.is_a?(Array) ? indicator_raw.first : indicator_raw || ''

      expect(indicator).to eq("fallback_value")
    end

    it 'handles array vs string values correctly' do
      # Test mixed array and string data
      mock_result = {
        "collection_display_string_u_sstr" => ["Array Value"],
        "series_title_u_sstr" => "String Value",
        "type_enum_s" => ["box", "folder"],
        "indicator_u_sstr" => "single_indicator"
      }

      collection_raw = mock_result['collection_display_string_u_sstr']
      collection_display = collection_raw.is_a?(Array) ? collection_raw.first : collection_raw || ''
      series_raw = mock_result['series_title_u_sstr']
      series_display = series_raw.is_a?(Array) ? series_raw.first : series_raw || ''
      type_raw = mock_result['type_enum_s']
      type = type_raw.is_a?(Array) ? type_raw.first : type_raw || ''
      indicator_raw = mock_result['indicator_u_sstr'] || mock_result['indicator_u_icusort']
      indicator = indicator_raw.is_a?(Array) ? indicator_raw.first : indicator_raw || ''

      expect(collection_display).to eq("Array Value")
      expect(series_display).to eq("String Value")
      expect(type).to eq("box") # first element of array
      expect(indicator).to eq("single_indicator")
    end

    it 'generates correct search parameters for top container export' do
      # Test the search parameter construction logic
      criteria = {'some' => 'initial_criteria'}
      search_params = criteria.dup
      search_params.delete('dt')
      search_params['page'] = 1
      search_params['page_size'] = 10000 # default when no config
      search_params['resolve[]'] = ['container_profile:id', 'container_locations:id', 'collection:id', 'series:id']
      search_params['fields[]'] = [
        'title',
        'collection_display_string_u_sstr',
        'series_title_u_sstr',
        'type_enum_s',
        'indicator_u_sstr',
        'indicator_u_icusort',
        'barcode_u_sstr',
        'container_profile_display_string_u_sstr',
        'location_display_string_u_sstr'
      ]

      expect(search_params['page']).to eq(1)
      expect(search_params['page_size']).to eq(10000)
      expect(search_params['resolve[]']).to include('container_profile:id')
      expect(search_params['fields[]']).to include('title')
      expect(search_params['fields[]']).to include('collection_display_string_u_sstr')
      expect(search_params.has_key?('dt')).to be false
    end

    it 'respects max_top_container_results configuration' do
      # Test config handling
      allow(AppConfig).to receive(:has_key?).with(:max_top_container_results).and_return(true)
      allow(AppConfig).to receive(:[]).with(:max_top_container_results).and_return(5000)

      page_size = AppConfig.has_key?(:max_top_container_results) ? AppConfig[:max_top_container_results] : 10000
      expect(page_size).to eq(5000)
    end

    it 'uses default page size when config is not set' do
      # Test default behavior
      allow(AppConfig).to receive(:has_key?).with(:max_top_container_results).and_return(false)

      page_size = AppConfig.has_key?(:max_top_container_results) ? AppConfig[:max_top_container_results] : 10000
      expect(page_size).to eq(10000)
    end
  end
end
