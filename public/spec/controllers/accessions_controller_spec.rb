require 'spec_helper'


describe AccessionsController, type: :controller do
  
  before(:all) do
    @repo = create(:repo, :repo_code => "accession_test_#{Time.now.to_i}")
    set_repo @repo
    @coll_mgmt_accession = create(:accession)
    @other_accession = create(:accession, title: "Unpublished", publish: false )
    run_all_indexers
  end

  it "should show the published accessions" do 
    expect(get :index).to have_http_status(200)
    results = assigns(:results)
    expect( results['total_hits'] ).to eq(1)  
    expect( results.records.first["title"] ).to eq(@coll_mgmt_accession["title"])
  end

end
