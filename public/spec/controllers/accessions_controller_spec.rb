require 'spec_helper'


describe AccessionsController, type: :controller do

  before(:all) do
    @repo = create(:repo, :repo_code => "accession_test_#{Time.now.to_i}")
    set_repo @repo
    @coll_mgmt_accession = create(:accession)
    @other_accession = create(:accession, title: "Unpublished", publish: false )
    @acc_with_deaccession = create(:accession_with_deaccession)
    run_all_indexers
  end

  it "should show the published accessions" do
    expect(get :index).to have_http_status(200)
    results = assigns(:results)
    expect( results['total_hits'] ).to eq(2)
    expect( results.records.first["title"] ).to eq(@coll_mgmt_accession["title"])
  end

  describe 'deaccessions in accession results' do
    it 'shows deaccessions when AppConfig[:pui_display_deaccessions] is true' do
      AppConfig[:pui_display_deaccessions] = true
      expect(get :index).to have_http_status(200)
      results = assigns(:results)
      rec_with_deaccession = results.records.find {|x| x["title"] == @acc_with_deaccession["title"]}
      expect( rec_with_deaccession.deaccessions ).not_to be_empty
    end
    it 'does not show deaccessions when AppConfig[:pui_display_deaccessions] is false' do
      AppConfig[:pui_display_deaccessions] = false
      expect(get :index).to have_http_status(200)
      results = assigns(:results)
      results.records.each do | rec |
        expect(rec.deaccessions).to be_empty
      end
    end
  end
end
