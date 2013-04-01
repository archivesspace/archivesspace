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

    event = JSONModel(:event).find(e.id, "resolve[]" => ["linked_agents", "linked_records"])

    event['linked_agents'][0]['_resolved']['names'][0]['primary_name'].should eq(@test_agent.names[0]['primary_name'])
    event['linked_records'][0]['_resolved']['title'].should eq(@test_accession.title)
  end


  it "can replace the list of linked records" do
    e = create(:json_event, @event_opts)

    new_accession = create(:json_accession)

    event = JSONModel(:event).find(e.id)
    event['linked_records'] = [{
                                 'ref' => new_accession.uri,
                                 'role' => generate(:record_role)
                               }]
    event.save

    JSONModel(:event).find(event.id)['linked_records'].count.should eq(1)
    JSONModel(:event).find(event.id)['linked_records'][0]['ref'].should eq(new_accession.uri)
  end


  it "can update an event" do
    e = create(:json_event, @event_opts)

    new_type = generate(:event_type)
    new_begin_date = generate(:yyyy_mm_dd)

    event = JSONModel(:event).find(e.id)

    event['event_type'] = new_type
    event['date']['begin'] = new_begin_date
    event['date']['end'] = new_begin_date

    event.save

    event = JSONModel(:event).find(e.id)
    event['event_type'].should eq(new_type)
    event['date']['begin'].should eq(new_begin_date)
  end


  it "can get a list of all events" do
    5.times do
      create(:json_event)
    end

    JSONModel(:event).all(:page => 1)['results'].length.should eq(5)
  end


  it "can unsuppress an event" do
    event = create(:json_event)

    event.suppress
    JSONModel(:event).find(event.id).suppressed.should eq(true)

    event.unsuppress
    JSONModel(:event).find(event.id).suppressed.should eq(false)
  end

end
