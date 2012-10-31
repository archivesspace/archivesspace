require 'spec_helper'

describe 'Events controller' do

  before(:each) do
    @test_agent = create(:json_agent_person)

    @test_accession = create(:json_accession)

    @event_opts = {
      :linked_agents => [{
                           'ref' => @test_agent.uri,
                           'role' => generate(:agent_role)
                         }],
      :linked_records => [{
                           'ref' => @test_accession.uri,
                           'role' => generate(:record_role)
                         }]
    }
  end


  it "can save an event and get it back" do

    e = create(:json_event, @event_opts)

    event = JSONModel(:event).find(e.id, "resolve[]" => "ref")

    event.linked_agents[0]['resolved']['ref']['names'][0]['primary_name'].should eq(@test_agent.names[0]['primary_name'])
    event.linked_records[0]['resolved']['ref']['title'].should eq(@test_accession.title)
  end


  it "can update an event" do
    e = create(:json_event, @event_opts)
    
    new_type = generate(:event_type)
    new_begin_date = generate(:yyyy_mm_dd)

    event = JSONModel(:event).find(e.id)
    event['event_type'] = new_type
    event['date']['begin'] = new_begin_date
    event.save

    event = JSONModel(:event).find(e.id)
    event['event_type'].should eq(new_type)
    event['date']['begin'].should eq(new_begin_date)
  end


  it "can get a list of all events" do
    5.times do
      create(:json_event)
    end

    JSONModel(:event).all.length.should eq(5)
  end


  it "can get a list of records that are candidates for linking" do
    result = JSONModel::HTTP.get_json(JSONModel(:event).uri_for('linkable-records/list'),
                                      :q => @test_accession.title)
    result[0]["title"].should eq(@test_accession.title)
  end

end
