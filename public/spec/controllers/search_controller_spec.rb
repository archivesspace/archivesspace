require 'spec_helper'
require 'uri'

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
            :from_year => [Addressable::URI.encode('<script>alert("boo");</script>')]
          })

      expect(response.status).to eq(302)
      expect(controller.params["from_year"]).to eq ["%3Cscript%3Ealert(%22boo%22);%3C/script%3E"]
      expect(URI.parse(response.redirect_url).query).to be_nil
      expect(request.flash[:error]).to eq ("Invalid search parameter '&lt;script&gt;alert(&quot;boo&quot;);&lt;/script&gt;' for field 'From year'")
    end
  end

  describe 'highlighting' do
    context 'when searching for a resource title' do
      let(:now) { Time.now.to_i }
      let(:search_term) { "Resource Title #{now}" }
      let(:repository) do
        create(
          :repo,
          :repo_code => "resource_search_test_#{now}",
          :name => "Repository Title #{now}",
          publish: true
        )
      end

      it 'successfully retrieves the resource with highlighting and replaces the display string with the highlighted title' do
        set_repo repository
        resource = create(
          :resource,
          title: search_term,
          publish: true
        )
        run_indexers

        response = get(:search, params: {
          :q => [search_term],
          :op => ['OR'],
          :field => ['']
        })

        results = controller.instance_variable_get(:@results)

        expected_highlights_hash = {
          "primary_type"=>["<span class=\"searchterm\">resource</span>"],
          "title" => ["<span class=\"searchterm\">Resource</span> <span class=\"searchterm\">Title</span> <span class=\"searchterm\">#{now}</span>"],
          "title_ws" => ["<span class=\"searchterm\">Resource</span> <span class=\"searchterm\">Title</span> <span class=\"searchterm\">#{now}</span>"],
          "types"=>["<span class=\"searchterm\">resource</span>"]
        }

        expect(results['total_hits']).to eq 1
        expect(results['highlighting']).to eq(
          {
            "/repositories/#{repository.id}/resources/#{resource.id}" => expected_highlights_hash
          }
        )

        expect(results.records.length).to eq 1
        record = results.records[0]
        expect(record.highlights).to eq(expected_highlights_hash)
        expect(record.display_string).to eq "<span class=\"searchterm\">Resource</span> <span class=\"searchterm\">Title</span> <span class=\"searchterm\">#{now}</span>"
      end
    end

    context 'when searching for a term contained in multiple records' do
      let(:now) { Time.now.to_i }
      let(:search_term) { now }
      let(:repository) do
        create(
          :repo,
          :repo_code => "resource_search_test_#{now}",
          :name => "Repository Title #{now}",
          publish: true
        )
      end

      it 'successfully retrieves the resource with highlighting' do
        set_repo repository

        accession = create(:accession, title: "Accession Title #{now}")
        digital_object = create(:digital_object, title: "Digital Object Title #{now}")

        person_1 = JSONModel(:name_person).new(primary_name: "Linked Agent 1 #{now}", name_order: 'direct')
        linked_agent_1 = create(:agent_person, names: [person_1], publish: true, dates_of_existence: [])

        person_2 = JSONModel(:name_person).new(:primary_name => "Linked Agent 2 #{now}", name_order: 'direct')
        linked_agent_2 = create(:agent_person, names: [person_2], publish: true, dates_of_existence: [])

        resource = create(:resource,
          :title => "Resource Title #{now}",
          :publish => true,
          :finding_aid_language_note => "Finding aid language note #{now}",
          :id_0 => "id_0 #{now}",
          :id_1 => "with spaces #{now}",
          :repository_processing_note => "Processing note #{now}",
          :linked_agents => [
            { 'role' => 'creator', 'ref' => linked_agent_1.uri },
            { 'role' => 'source', 'ref' => linked_agent_2.uri }
          ],
          :notes => [
            build(:json_note_multipart,
              subnotes: [
                build(:json_note_text, publish: true, content: "Note text #{now}"),
                build(:json_note_text, publish: false, content: "Unpublished note text #{now}")
              ])
          ]
        )

        run_indexers

        response = get(:search, params: {
          :q => [search_term],
          :op => ['OR'],
          :field => ['']
        })

        results = controller.instance_variable_get(:@results)

        expected_accession_highlights_hash = {
          "title"=>["Accession Title <span class=\"searchterm\">#{now}</span>"],
          "title_ws"=>["Accession Title <span class=\"searchterm\">#{now}</span>"]
        }

        aggregate_failures do
          expect(results['total_hits']).to eq 5
          expect(results['highlighting']).to eq(
                                               {
                                                 "/repositories/#{repository.id}/accessions/#{accession.id}" => expected_accession_highlights_hash,
                                                 "/repositories/#{repository.id}/resources/#{resource.id}" => {
                                                   "title"=>["Resource Title <span class=\"searchterm\">#{now}</span>"],
                                                   "title_ws"=>["Resource Title <span class=\"searchterm\">#{now}</span>"],
                                                   "identifier_ws" => ["id_0 #{now}-with spaces <span class=\"searchterm\">#{now}</span>"],
                                                   "four_part_id" => ["id_0 <span class=\"searchterm\">#{now}</span> with spaces <span class=\"searchterm\">#{now}</span>"],
                                                   "creators_text" => ["Linked Agent 1 <span class=\"searchterm\">#{now}</span>"],
                                                   "agents_text" => ["Linked Agent 1 <span class=\"searchterm\">#{now}</span>"],
                                                   "notes_published"=>["Note text <span class=\"searchterm\">#{now}</span>"],
                                                   "notes"=>["Note text <span class=\"searchterm\">#{now}</span>"],
                                                   "summary"=>["Note text <span class=\"searchterm\">#{now}</span>\nUnpublished note text <span class=\"searchterm\">#{now}</span>"]
                                                 },
                                                 "/agents/people/#{linked_agent_1.id}" => {
                                                   "title" => ["Linked Agent 1 <span class=\"searchterm\">#{now}</span>"],
                                                   "title_ws" => ["Linked Agent 1 <span class=\"searchterm\">#{now}</span>"]
                                                 },
                                                 "/agents/people/#{linked_agent_2.id}" => {
                                                   "title" => ["Linked Agent 2 <span class=\"searchterm\">#{now}</span>"],
                                                   "title_ws" => ["Linked Agent 2 <span class=\"searchterm\">#{now}</span>"]
                                                 },
                                                 "/repositories/#{repository.id}/digital_objects/#{digital_object.id}" => {
                                                   "title"=>["Digital Object Title <span class=\"searchterm\">#{now}</span>"],
                                                   "title_ws"=>["Digital Object Title <span class=\"searchterm\">#{now}</span>"]
                                                 }
                                               }
                                             )

          expect(results.records.length).to eq 5

          accession_record = results.records[0]
          expect(accession_record.display_string).to eq "Accession Title <span class=\"searchterm\">#{now}</span>"
          expect(accession_record.highlights).to eq(expected_accession_highlights_hash)

          resource_record = results.records[1]
          expect(resource_record.display_string).to eq "Resource Title <span class=\"searchterm\">#{now}</span>"
          expect(resource_record.highlights).to eq(
                                                  {
                                                    "agents_text" => ["Linked Agent 1 <span class=\"searchterm\">#{now}</span>"],
                                                    "creators_text"=>["Linked Agent 1 <span class=\"searchterm\">#{now}</span>"],
                                                    "identifier_ws" => ["id_0 #{now}-with spaces <span class=\"searchterm\">#{now}</span>"],
                                                    "notes" => ["Note text <span class=\"searchterm\">#{now}</span>"],
                                                    "notes_published"=>["Note text <span class=\"searchterm\">#{now}</span>"],
                                                    "summary" => ["Note text <span class=\"searchterm\">#{now}</span>\nUnpublished note text <span class=\"searchterm\">#{now}</span>"],
                                                    "title" => ["Resource Title <span class=\"searchterm\">#{now}</span>"],
                                                    "title_ws" => ["Resource Title <span class=\"searchterm\">#{now}</span>"],
                                                    "four_part_id"=>["id_0 <span class=\"searchterm\">#{now}</span> with spaces <span class=\"searchterm\">#{now}</span>"]
                                                  }
                                                )

          agent_1_record = results.records[2]
          expect(agent_1_record.display_string).to eq "Linked Agent 1 <span class=\"searchterm\">#{now}</span>"
          expect(agent_1_record.highlights).to eq({"title"=>["Linked Agent 1 <span class=\"searchterm\">#{now}</span>"], "title_ws"=>["Linked Agent 1 <span class=\"searchterm\">#{now}</span>"]})

          agent_2_record = results.records[3]
          expect(agent_2_record.display_string).to eq "Linked Agent 2 <span class=\"searchterm\">#{now}</span>"
          expect(agent_2_record.highlights).to eq({"title"=>["Linked Agent 2 <span class=\"searchterm\">#{now}</span>"], "title_ws"=>["Linked Agent 2 <span class=\"searchterm\">#{now}</span>"]} )

          digital_object_record = results.records[4]
          expect(digital_object_record.display_string).to eq "Digital Object Title <span class=\"searchterm\">#{now}</span>"
          expect(digital_object_record.highlights).to eq({"title"=>["Digital Object Title <span class=\"searchterm\">#{now}</span>"], "title_ws"=>["Digital Object Title <span class=\"searchterm\">#{now}</span>"]} )
        end
      end
    end

    context 'when searching for a resource repository_processing_note' do
      let(:now) { Time.now.to_i }
      let(:search_term) { SecureRandom.uuid }
      let(:repository) do
        create(
          :repo,
          :repo_code => "resource_search_test_#{now}",
          :name => "Repository Title #{now}",
          publish: true
        )
      end

      it 'successfully retrieves the resource but without highlighting' do
        set_repo repository
        resource = create(
          :resource,
          title: "Resource Title #{now}",
          publish: true,
          repository_processing_note: search_term
        )
        run_indexers

        response = get(:search, params: {
          :q => [search_term],
          :op => ['OR'],
          :field => ['']
        })

        results = controller.instance_variable_get(:@results)

        expect(results['total_hits']).to eq 1
        expect(results['highlighting']).to eq(
          {
            "/repositories/#{repository.id}/resources/#{resource.id}" => {}
          }
        )

        expect(results.records.length).to eq 1
        record = results.records[0]
        expect(record.display_string).to eq "Resource Title #{now}"
        expect(record.highlights).to eq({})
      end
    end
  end

  describe 'default search scope configuration' do
    before(:each) do
      # Store original config to restore it after tests
      @original_default_scope = AppConfig[:search_default_scope]
    end

    after(:each) do
      # Restore original config
      AppConfig[:search_default_scope] = @original_default_scope
    end

    it 'should use all_record_types by default when config is set to all_record_types' do
      AppConfig[:search_default_scope] = 'all_record_types'

      response = get(:search, params: {
        :q => ['*'],
        :op => ['OR'],
        :field => ['']
      })

      expect(response).to have_http_status(200)
      expect(controller.params[:limit]).to be_blank
    end

    it 'should use collections_only by default when config is set to collections_only' do
      AppConfig[:search_default_scope] = 'collections_only'

      response = get(:search, params: {
        :q => ['*'],
        :op => ['OR'],
        :field => ['']
      })

      expect(response).to have_http_status(200)
      expect(controller.params[:limit]).to eq('resource')
    end

    it 'should respect user selection when explicitly choosing all_record_types' do
      AppConfig[:search_default_scope] = 'collections_only'

      # Send an empty string for limit to simulate selecting "All Records"
      response = get(:search, params: {
        :q => ['*'],
        :op => ['OR'],
        :field => [''],
        :limit => ''
      })

      expect(response).to have_http_status(200)
      expect(controller.params[:limit]).to eq('')
    end

    it 'should respect user selection when explicitly choosing collections_only' do
      AppConfig[:search_default_scope] = 'all_record_types'

      response = get(:search, params: {
        :q => ['*'],
        :op => ['OR'],
        :field => [''],
        :limit => 'resource'
      })

      expect(response).to have_http_status(200)
      expect(controller.params[:limit]).to eq('resource')
    end
  end
end
