require 'spec_helper'

describe 'Events controller' do

  before(:all) do
    @test_date = build(:json_date).to_hash
  end

  before(:each) do
    create(:repo)

    @test_agent = create(:json_agent_person)

    @test_accession = create(:json_accession)
  end


  def make_test_event
    e = create(:json_event, {:date => @test_date,
                             :event_type => "accession",
                             :linked_agents => [{
                                                 "ref" => @test_agent.uri,
                                                 "role" => "authorizer"
                                               }],
                             :linked_records => [{
                                                 "ref" => @test_accession.uri,
                                                  "role" => "transfer"
                                               }]
                            })
    e.id
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
