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

    @test_agent = JSONModel(:agent_person).
      from_hash("agent_type" => "agent_person",
                "names" => [{
                              "rules" => "local",
                              "primary_name" => "Magus Magoo",
                              "sort_name" => "Magoo, Mr M",
                              "direct_order" => "standard"
                            }])

    @test_accession = JSONModel(:accession).from_hash("id_0" => "1234",
                                                      "title" => "The accession title",
                                                      "content_description" => "The accession description",
                                                      "condition_description" => "The condition description",
                                                      "accession_date" => "2012-05-03")

    @test_agent.save
    @test_accession.save
  end


  def make_test_event
    JSONModel(:event).from_hash(:date => @test_date,
                                :event_type => "accession",
                                :linked_agents => [{
                                                     "ref" => @test_agent.uri,
                                                     "role" => "authorizer"
                                                   }],
                                :linked_records => [{
                                                      "ref" => @test_accession.uri,
                                                      "role" => "transfer"
                                                    }]).save
  end


  it "can save an event and get it back" do
    id = make_test_event
    event = JSONModel(:event).find(id, "resolve[]" => "ref")

    event.linked_agents[0]['resolved']['ref']['names'][0]['primary_name'].should eq("Magus Magoo")
    event.linked_records[0]['resolved']['ref']['title'].should eq("The accession title")
  end


  it "can update an event" do
    id = make_test_event

    event = JSONModel(:event).find(id)
    event['event_type'] = 'virus check'
    event['date']['begin'] = '1900-01-01'
    event.save

    event = JSONModel(:event).find(id)
    event['event_type'].should eq('virus check')
    event['date']['begin'].should eq('1900-01-01')
  end


  it "can get a list of all events" do
    5.times do
      make_test_event
    end

    JSONModel(:event).all.length.should eq(5)
  end

end
