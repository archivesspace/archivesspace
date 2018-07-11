require 'spec_helper'

describe 'Collection Management model' do

  it "knows the parent" do
    accession = Accession.create_from_json(build(:json_accession,
                                                 :collection_management =>
                                                   {
                                                     "processing_status" => "completed"
                                                   }
                                           ),
                                           :repo_id => $repo_id)

    cm = CollectionManagement.to_jsonmodel(accession.collection_management.id)
    cm['parent']['ref'].should eq(accession.uri)
  end

end
