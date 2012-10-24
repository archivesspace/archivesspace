require 'spec_helper'

describe 'Event model' do

  before(:all) do
    @test_date = JSONModel(:date).from_hash("date_type" => "single",
                                            "label" => "creation",
                                            "begin" => "2012-05-14",
                                            "end" => "2012-05-14").to_hash
  end

  before(:each) do
    make_test_repo
  end


  it "enforces at least one linked agent and one linked record via its schema" do

    expect {
      JSONModel(:event).from_hash(:date => @test_date,
                                  :event_type => "accession",
                                  :linked_agents => [],
                                  :linked_records => [])
    }.to raise_error(JSONModel::ValidationException)
  end


  it "permits a mixture of linked record types" do
    JSONModel(:event).from_hash(:date => @test_date,
                                :event_type => "accession",
                                :linked_agents => [{
                                                     "ref" => JSONModel(:agent_person).uri_for(100),
                                                     "role" => "authorizer"
                                                   }],
                                :linked_records => [{
                                                      "ref" => JSONModel(:accession).uri_for(2),
                                                      "role" => "transfer"
                                                    },
                                                    {
                                                      "ref" => JSONModel(:resource).uri_for(3),
                                                      "role" => "transfer"
                                                    },
                                                    {
                                                      "ref" => JSONModel(:archival_object).uri_for(4),
                                                      "role" => "transfer"
                                                    }])
  end


  it "but not any old record type!" do
    expect {
      JSONModel(:event).from_hash(:date => @test_date,
                                  :event_type => "accession",
                                  :linked_agents => [{
                                                       "ref" => JSONModel(:agent_person).uri_for(100),
                                                       "role" => "authorizer"
                                                     }],
                                  :linked_records => [{
                                                        "ref" => JSONModel(:repository).uri_for(2),
                                                        "role" => "transfer"
                                                      }])
    }.to raise_error(JSONModel::ValidationException)
  end

end
