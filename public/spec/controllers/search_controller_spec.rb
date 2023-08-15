require 'spec_helper'
require 'uri'

# TODO: the specs here (and elsehwere) formerly asserted against a hard-coded
# no. for 'total_hits' which was extremely annoying when adding new test data / fixtures.
# For now using a min. threshold for 'total_hits' instead because we rarely (if ever) go
# down. However, it may be better long term to think about what is really being tested
# and if there's a better approach.

describe SearchController, type: :controller do
  # Since test data is created in both `spec_helper` as well as in some of the individual
  # controller tests, predicting total numbers of results is tricky.  Just hardcoding
  # the repo id of these new tests to '2' (the `spec_helper` test data) for now.

  it 'should return all records' do
    response = get(:search, params: {
      :rid => 2,
      :q => ['*'],
      :op => ['OR'],
      :field => ['']
    })
    result_data = controller.instance_variable_get(:@results)

    expect(response).to have_http_status(200)
    expect(response).to render_template('search/search_results')
    expect(result_data['total_hits']).to be > 30
  end

  it 'should return all digital objects when filtered' do
    response = get(:search, params: {
      :rid => 2,
      :q => ['*'],
      :op => ['OR'],
      :limit => 'digital_object',
      :field => ['']
    })
    result_data = controller.instance_variable_get(:@results)

    expect(response).to have_http_status(200)
    expect(response).to render_template('search/search_results')
    expect(result_data['total_hits']).to be > 5
  end

  it 'should return digital object component with identifier search' do
    response = get(:search, params: {
     :rid => 2,
     :q => ['12345'],
     :op => ['OR'],
     :field => ['identifier']
    })
    result_data = controller.instance_variable_get(:@results)

    expect(response).to have_http_status(200)
    expect(response).to render_template('search/search_results')
    expect(result_data['total_hits']).to eq(1)
  end

  it 'should return a linked resource with subject search' do
    response = get(:search, params: {
     :rid => 2,
     :q => ['Term 1'],
     :op => ['OR'],
     :field => ['subjects_text']
    })
    result_data = controller.instance_variable_get(:@results)

    expect(response).to have_http_status(200)
    expect(response).to render_template('search/search_results')
    expect(result_data['total_hits']).to eq(2)
  end

  describe 'facet sorting' do
    it 'leaves facets in the order received (hit count) unless config says to sort by label' do
      repos = class_double("Repository").
                as_stubbed_const
      allow(repos).to receive(:get_repos) {
        {
          "/repositories/3" => { "name" => "Alpha" },
          "/repositories/2" => { "name" => "Beta" },
          "/repositories/1" => { "name" => "Delta" }
        }
      }

      as_client = instance_double("ArchivesSpaceClient")
      allow(as_client).to receive(:advanced_search) { |base_search, page, criteria|
        SolrResults.new({
                          'total_hits' => 10,
                          'results' => (0...10).map {|i| {
                                                       'primary_type' => 'accession',
                                                       'json' => {'title' => 'TITLE'},
                                                       'uri' => "/accessions/#{i}"
                                                     } },
                          'facets' => {
                            'facet_fields' => {
                              'repository' => [
                                '/repositories/2', 6, '/repositories/1', 3, '/repositories/3', 2
                              ]
                            }
                          }
                        })
      }
      allow(controller).to receive(:archivesspace).and_return(as_client)

      response = get(:search, params: {
                       :rid => 2,
                       :q => ['foo'],
                       :op => ['OR'],
                       :field => ['']
                     })
      facets = assigns(:facets)
      expect(facets["repository"].map { |f| f.key }).to eq(["/repositories/2", "/repositories/1", "/repositories/3"])

      allow(AppConfig).to receive(:[]).and_call_original
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
      expect(ArchivesSpaceClient.instance).to receive(:do_http_request) do |request, http_opts|
        query_to_backend = Rack::Utils.parse_query request.uri.query
        advanced_query = JSON.parse(query_to_backend['aq'])
        # that such a simple query gets nested so deeply seems strange
        # perhaps the query building logic in this controller can be simplified
        # without changing the result sets?
        users_query_string = advanced_query['query']['subqueries'][1]['subqueries'][0]['subqueries'][0]['value']
        expect(users_query_string).to eq("foo & bar")

        Struct.new(:code, :body).new(500, "doesn't matter for purpose of this test")
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

    before(:all) do
      @do_linked_to_multiple_records = create(:digital_object,
        title: 'Digital Object linked to multiple archival records',
        publish: true)
      @resource_with_common_linked_instance = create(:resource,
        title: "Resource with common linked instance",
        publish: true,
        instances: [build(:instance_digital,
          digital_object: {'ref' => @do_linked_to_multiple_records.uri})
        ])
      @ao_with_common_linked_instance = create(:archival_object,
        title: "Archival Object with common linked instance",
        resource: { 'ref' => @resource_with_common_linked_instance.uri },
        publish: true,
        instances: [build(:instance_digital,
          digital_object: {'ref' => @do_linked_to_multiple_records.uri})
        ])
      @accession_with_common_linked_instance = create(:accession,
        title: "Accession with common linked instance",
        publish: true,
        instances: [build(:instance_digital,
          digital_object: {'ref' => @do_linked_to_multiple_records.uri})
        ])
      @unpublished_accession_with_common_linked_instance = create(:accession,
        title: "Unpublished Accession with common linked instance",
        publish: false,
        instances: [build(:instance_digital,
          digital_object: {'ref' => @do_linked_to_multiple_records.uri})
        ])
      run_indexers
    end

    it 'should show breadcrumbs for all published archival records linked to a digital object' do
      get(:search, params: {
        :q => [@do_linked_to_multiple_records.title],
        :limit => 'digital_object',
        :op => ['']
      })

      expect(response).to render_template("digital_objects/_search_result_breadcrumbs")

      page = Capybara.string(response.body)
      page.find(:css, ".recordrow[data-uri='#{@do_linked_to_multiple_records.uri}']") do |result|
        result.find(:css, 'ol.result_linked_instances_tree li:first-of-type') do |crumb1|
          expect(crumb1).to have_css ".resource_name a[href='#{@resource_with_common_linked_instance.uri}']"
        end

        result.find(:css, 'ol.result_linked_instances_tree li:nth-of-type(2)') do |crumb2|
          expect(crumb2).to have_css ".resource_name + .archival_object_name a[href='#{@ao_with_common_linked_instance.uri}']"
        end

        result.find(:css, 'ol.result_linked_instances_tree li:last-of-type') do |crumb3|
          expect(crumb3).to have_css ".accession_name a[href='#{@accession_with_common_linked_instance.uri}']"
        end

        expect(result).to have_css('ol.result_linked_instances_tree li', count: 3)
      end
    end
  end

  describe "xss sanitizing" do
    render_views

    it "does not let javascript appear in search date params" do
      as_client = instance_double("ArchivesSpaceClient")
      allow(as_client).to receive(:advanced_search) { |base_search, page, criteria|
        SolrResults.new({
                          'total_hits' => 0,
                          'results' => [],
                          'facets' => {
                            'facet_fields' => {
                              'repository' => [
                                '/repositories/2', 6, '/repositories/1', 3, '/repositories/3', 2
                              ]
                            }
                          }
                        })
      }
      allow(controller).to receive(:archivesspace).and_return(as_client)

      get(:search, params: {
            :rid => 2,
            :q => ['foobar'],
            :op => ['OR'],
            :field => [''],
            :from_year => [URI.encode('<script>alert("boo");</script>')]
          })

      expect(response.status).to eq(302)
      expect(controller.params["from_year"]).to eq ["%3Cscript%3Ealert(%22boo%22);%3C/script%3E"]
      expect(URI.parse(response.redirect_url).query).to be_nil
      expect(request.flash[:error]).to eq ("Invalid search parameter '&lt;script&gt;alert(&quot;boo&quot;);&lt;/script&gt;' for field 'From year'")
    end
  end

end
