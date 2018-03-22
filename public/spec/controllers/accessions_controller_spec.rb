require 'spec_helper'


describe AccessionsController, type: :controller do
  
  before(:all) do
    @repo = create(:repo, :repo_code => "accession_test_#{Time.now.to_i}")
    set_repo @repo
    @coll_mgmt_accession = create(:accession)
    @other_accession = create(:accession, :title => "Link to me")
    run_all_indexers
    $pui.run_index_round
  end

  it "should welcome all visitors" do 
    expect(get :index).to have_http_status(200)
    expect( assigns(:results)['total_hits'] ).to eq(2)  
  end

end

