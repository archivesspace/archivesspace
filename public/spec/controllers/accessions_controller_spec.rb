require 'spec_helper'

describe AccessionsController, type: :controller do

  let(:as_client) { as_client = instance_double("ArchivesSpaceClient") }
  let(:accessions) { (0...8).map { |i| { "title" => "Accession #{i}",
                                         "primary_type" => "accession",
                                         "json" => build(:json_accession, title: "Accession #{i}").to_hash,
                                         "uri"=> "/accessions/#{i}" } } }

  context 'index' do

    before(:each) do
      allow(controller).to receive(:archivesspace).and_return(as_client)
      allow(as_client).to receive(:advanced_search) { |base_search, page, criteria|
        @criteria = criteria
        mock_solr_results(
          (0...8).map { |i|
            {
              'primary_type' => 'accession',
              'json' => {'title' => 'TITLE'},
              'uri' => "/accessions/#{i}"
            }})
      }

    end

    it "returns a list of accessions" do
      expect(get :index).to have_http_status(200)
      filter = JSON.parse(@criteria["filter"])
      # see controllers/concerns/searchable.rb:162 where 'filter' is set
      expect(filter['query']['subqueries'][0]['subqueries'][0]['subqueries'][0]['field']).to eq "types"
      expect(filter['query']['subqueries'][0]['subqueries'][0]['subqueries'][0]['value']).to eq "accession"
      results = assigns(:results)
      expect( results['total_hits'] ).to eq(8)
      expect( results.records.first["title"] ).to eq(accessions.first['title'])
      ## TODO - move this assertion to features or indexer
      #expect( results.records.select { |record| record["title"] == "Unpublished Accession" } ).to be_empty
    end

    describe 'deaccessions in accession results' do
      it 'shows deaccession data if it is present in the Solr document' do
        accessions.first['json'] = build(:json_accession, deaccessions: [build(:json_deaccession)]).to_hash
        expect(get :index).to have_http_status(200)
        results = assigns(:results)
        rec_with_deaccession = results.records.first
        expect( rec_with_deaccession.deaccessions ).not_to be_empty
      end
    end
  end

  describe 'show' do
    render_views

    before(:all) do
      @fv_uri = 'https://www.archivesspace.org/demos/Congreave%20E-4/ms292_008.jpg'
      @fv_caption = 'digi_obj_with_rep_file_ver caption'
    end

    it 'displays a representative file version image' do
      allow(controller).to receive(:archivesspace).and_return(as_client)
      allow(as_client).to receive(:get_record) { |uri, criteria|
        record = Accession.new({
                                 'primary_type' => 'accession',
                                 'json' => build(:json_accession).to_hash.merge(
                                   {
                                     'representative_file_version' => build(:json_file_version, {
                                                                              caption: @fv_caption,
                                                                              file_uri: @fv_uri
                                                                            }).to_hash
                                   }),
                                 'uri' => "/accessions/0"
                               }
        )
        allow(record).to receive(:resolved_repository).and_return({'name' => 'Repository', 'uri' => "/repositories/0"})
        record
      }

      get(:show, params: {rid: 0, id: 0})

      expect(response).to render_template("shared/_representative_file_version_record")
      page = Capybara.string(response.body)
      expect(page).to have_css("figure[data-rep-file-version-wrapper] img[src='#{@fv_uri}']")
      page.find(:css, 'figure[data-rep-file-version-wrapper] figcaption') do |fc|
        expect(fc.text).to have_content(@fv_caption)
      end
    end
  end
end
