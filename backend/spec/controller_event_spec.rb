require 'spec_helper'

describe 'Events controller' do

  before(:all) do
    @test_date = JSONModel(:date).from_hash("date_type" => "single",
                                            "label" => "creation",
                                            "begin" => "2012-05-14",
                                            "end" => "2012-05-14").to_hash
  end

  before(:each) do
    make_test_repo
  end


  it "can save an event and get it back" do

    agent = JSONModel(:agent_person).
      from_hash("agent_type" => "agent_person",
                "names" => [{
                              "rules" => "local",
                              "primary_name" => "Magus Magoo",
                              "sort_name" => "Magoo, Mr M",
                              "direct_order" => "standard"
                            }]).save


    accession = JSONModel(:accession).from_hash("id_0" => "1234",
                                                "title" => "The accession title",
                                                "content_description" => "The accession description",
                                                "condition_description" => "The condition description",
                                                "accession_date" => "2012-05-03").save


    id = JSONModel(:event).from_hash(:date => @test_date,
                                        :event_type => "accession",
                                        :linked_agents => [{
                                                             "ref" => JSONModel(:agent_person).uri_for(agent),
                                                             "role" => "authorizer"
                                                           }],
                                        :linked_records => [{
                                                              "ref" => JSONModel(:accession).uri_for(accession),
                                                              "role" => "transfer"
                                                            }]).save

    puts "ID: #{id.inspect}"
    event = JSONModel(:event).find(id)

    puts event.inspect
  end




end
