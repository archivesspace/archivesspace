require 'spec_helper'

describe SearchController, type: :controller do
  let(:as_client) { instance_double("ArchivesSpaceClient") }
  let(:repos) { class_double("Repository").as_stubbed_const }
  let(:solr_results) {
    mock_solr_results(
      (0...10).map { |i|
        {
          'primary_type' => 'accession',
          'json' => {'title' => 'TITLE'},
          'uri' => "/accessions/#{i}"
        } })
  }

  before(:each) do
    allow(controller).to receive(:archivesspace).and_return(as_client)
    allow(repos).to receive(:get_repos) {
      {
        "/repositories/3" => { "name" => "Alpha" },
        "/repositories/2" => { "name" => "Beta" },
        "/repositories/1" => { "name" => "Delta" }
      }
    }
  end

  it 'should return all records' do
    allow(as_client).to receive(:advanced_search) { |base_search, page, criteria|
        solr_results
    }
    response = get(:search, params: {
      :rid => 2,
      :q => ['*'],
      :op => ['OR'],
      :field => ['']
    })
    result_data = controller.instance_variable_get(:@results)

    expect(response).to have_http_status(200)
    expect(response).to render_template('search/search_results')
    expect(result_data['total_hits']).to eq 10
  end

  it 'accepts a :limit param and adds a filter subquery to the backend request' do
    expect(as_client).to receive(:advanced_search) { |base_search, page, criteria|
      advanced_query = JSON.parse(criteria['aq'])
      filter_query = JSON.parse(criteria['filter'])

      advanced_query_string = advanced_query['query']['subqueries'][1]['subqueries'][0]['subqueries'][0]['value']
      expect(advanced_query_string).to eq("*")

      filter_query_string = filter_query['query']['subqueries'][0]['subqueries'][0]['subqueries'][0]['value']
      expect(filter_query_string).to eq('digital_object')

      solr_results
    }

    response = get(:search, params: {
      :rid => 2,
      :q => ['*'],
      :op => ['OR'],
      :limit => 'digital_object',
      :field => ['']
    })

    expect(response).to have_http_status(200)
  end

  it 'supports an identifier search' do
    expect(as_client).to receive(:advanced_search) { |base_search, page, criteria|
      advanced_query = JSON.parse(criteria['aq'])
      filter_query = JSON.parse(criteria['filter'])

      advanced_query_string = advanced_query['query']['subqueries'][1]['subqueries'][0]['subqueries'][0]['value']
      expect(advanced_query_string).to eq("12345")
      advanced_query_field = advanced_query['query']['subqueries'][1]['subqueries'][0]['subqueries'][0]['field']
      expect(advanced_query_field).to eq("identifier")

      solr_results
    }

    response = get(:search, params: {
     :rid => 2,
     :q => ['12345'],
     :op => ['OR'],
     :field => ['identifier']
    })
    expect(response).to have_http_status(200)
  end

  it 'should return a linked resource with subject search' do
    expect(as_client).to receive(:advanced_search) { |base_search, page, criteria|
      advanced_query = JSON.parse(criteria['aq'])
      filter_query = JSON.parse(criteria['filter'])
      advanced_query_string = advanced_query['query']['subqueries'][1]['subqueries'][0]['subqueries'][0]['value']
      expect(advanced_query_string).to eq("Term 1")
      advanced_query_field = advanced_query['query']['subqueries'][1]['subqueries'][0]['subqueries'][0]['field']
      expect(advanced_query_field).to eq("subjects_text")

      solr_results
    }

    response = get(:search, params: {
     :rid => 2,
     :q => ['Term 1'],
     :op => ['OR'],
     :field => ['subjects_text']
    })
    expect(response).to have_http_status(200)
  end

  describe 'facet sorting' do
    it 'leaves facets in the order received (hit count) unless config says to sort by label' do
      allow(as_client).to receive(:advanced_search) { |base_search, page, criteria|
        mock_solr_results(
          (0...10).map {|i| {
                          'primary_type' => 'accession',
                          'json' => {'title' => 'TITLE'},
                          'uri' => "/accessions/#{i}"
                        } },
            {'facets' => {
               'facet_fields' => {
                 'repository' => [
                   '/repositories/2', 6, '/repositories/1', 3, '/repositories/3', 2
                 ]
               }}}
        )
      }

      response = get(:search, params: {
                       :rid => 2,
                       :q => ['foo'],
                       :op => ['OR'],
                       :field => ['']
                     })
      facets = assigns(:facets)
      expect(facets["repository"].map { |f| f.key }).to eq(["/repositories/2", "/repositories/1", "/repositories/3"])
      allow(AppConfig).to receive(:[]).with(:pui_display_facets_alpha) { true }

      response = get(:search, params: {
                       :rid => 2,
                       :q => ['foo'],
                       :op => ['OR'],
                       :field => ['']
                     })
      facets = assigns(:facets)
      expect(facets["repository"].map { |f| f.key }).to eq(["/repositories/3", "/repositories/2", "/repositories/1"])
    end
  end

  describe "search requests to api" do
    it "does not convert & into the entity &amp; when preparing a search query" do
      allow(controller).to receive(:archivesspace).and_call_original
      expect(ArchivesSpaceClient.instance).to receive(:do_http_request) do |request, http_opts|
        query_to_backend = Rack::Utils.parse_query request.uri.query
        advanced_query = JSON.parse(query_to_backend['aq'])
        # that such a simple query gets nested so deeply seems strange
        # perhaps the query building logic in this controller can be simplified
        # without changing the result sets?
        users_query_string = advanced_query['query']['subqueries'][1]['subqueries'][0]['subqueries'][0]['value']
        expect(users_query_string).to eq("foo & bar")

        Struct.new(:code, :body).new(200, "search results")
      end

      get(:search, params: {
            :rid => 2,
            :q => ['foo & bar'],
            :op => ['OR'],
            :field => ['']
          })
    end
  end

  describe 'search action' do
    render_views

    let(:solr_results) {
      solr_results = mock_solr_results([
        {
          'primary_type' => 'digital_object',
          'uri' => '/repositories/0/digital_objects/0',
          'json' => { 'title' => 'Digital Object' },
        }
                                       ])
      linked_instances = [
        {
          'primary_type' => 'resource',
          'uri' => '/repositories/0/resources/0',
          'json' => { 'title' => 'Resource'},
        },
        {
          'primary_type' => 'archival_object',
          'uri' => '/repositories/0/archival_objects/0',
          'json' => { 'title' => 'Archival Object', 'resource' => {'ref' => '/repositories/0/resources/0'} },
        },
        {
          'primary_type' => 'accession',
          'uri' => '/repositories/0/accessions/0',
          'json' => { 'title' => 'Accession' }
        }
      ].map { |raw| record_for_type(raw) }.map { |i| {i['uri'] => i}}.inject({}) { |result, item| result.merge(item) }

      allow(solr_results.records.first).to receive(:linked_instances).and_return(linked_instances)
      allow(solr_results.records.first).to receive(:resolved_repository).and_return({'name' => 'Repository', 'uri' => "/repositories/0"})
      solr_results
    }

    it 'should show breadcrumbs for archival records linked to a digital object' do
      allow(ArchivesSpaceClient).to receive(:instance).and_return(as_client)
      allow(as_client).to receive(:advanced_search) { |base_search, page, criteria|
        solr_results
      }
      allow(as_client).to receive(:get_raw_record) { |uri, search_opts = {}|
        expect(uri).to eq "/repositories/0/resources/0/tree/node_from_root_0"
        JSON.parse("{\"0\":[{\"node\":null,\"root_record_uri\":\"/repositories/0/resources/0\",\"offset\":0,\"jsonmodel_type\":\"resource\",\"title\":\"Resource\",\"parsed_title\":\"Resource\"}]}")
      }
      digital_object = solr_results.records.first

      get(:search, params: {
        :q => ['*'],
        :limit => 'digital_object',
        :op => ['']
      })

      expect(response).to render_template("digital_objects/_search_result_breadcrumbs")

      page = Capybara.string(response.body)

      page.find(:css, ".recordrow[data-uri='#{digital_object.uri}']") do |result|
        result.find(:css, 'ol.result_linked_instances_tree li:first-of-type') do |crumb1|
          expect(crumb1).to have_css ".resource_name a[href='#{digital_object.linked_instances.values[0].uri}']"
        end

        result.find(:css, 'ol.result_linked_instances_tree li:nth-of-type(2)') do |crumb2|
          expect(crumb2).to have_css ".resource_name + .archival_object_name a[href='#{digital_object.linked_instances.values[1].uri}']"
        end

        result.find(:css, 'ol.result_linked_instances_tree li:last-of-type') do |crumb3|
          expect(crumb3).to have_css ".accession_name a[href='#{digital_object.linked_instances.values[2].uri}']"
        end

        expect(result).to have_css('ol.result_linked_instances_tree li', count: 3)
      end
    end
  end
end
