require 'spec_helper'

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
end
