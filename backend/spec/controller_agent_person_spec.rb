require 'spec_helper'
require 'agent_spec_helper'

describe 'Person agent controller' do

  def create_person(opts = {})
    create(:json_agent_person, opts)
  end


  it "lets you create a person and get them back" do
    opts = {:names => [build(:json_name_person)]}

    id = create_person(opts).id
    expect(JSONModel(:agent_person).find(id).names.first['primary_name']).to eq(opts[:names][0]['primary_name'])
  end


  it "lets you update someone by adding contacts" do
    id = create_person(:agent_contacts => nil).id

    person = JSONModel(:agent_person).find(id)
    [0, 1].each do |n|
      opts = {:name => generate(:generic_name)}

      person.agent_contacts << build(:json_agent_contact, opts)

      person.save

      expect(JSONModel(:agent_person).find(id).agent_contacts[n]['name']).to eq(opts[:name])
    end
  end


  it "can give a list of person agents" do
    page = AgentPerson.all.length / 10 + 1

    count = JSONModel(:agent_person).all(:page => page)['results'].count

    2.times { create_person }

    expect(JSONModel(:agent_person).all(:page => page)['results'].count).to eq(count + 2)
  end


  it "sets the sort name if one is provided" do
    opts = {:names => [build(:json_name_person, :sort_name => "Custom Sort Name", :sort_name_auto_generate => false)]}

    id = create_person(opts).id
    expect(JSONModel(:agent_person).find(id).names.first['sort_name']).to eq(opts[:names][0]['sort_name'])
  end


  it "auto-generates the sort name if one is not provided" do
    id = create_person({:names => [build(:json_name_person,{:primary_name => "Hendrix", :rest_of_name => "Jimi", :title => "Mr", :name_order => "direct", :sort_name_auto_generate => true})]}).id

    agent = JSONModel(:agent_person).find(id)

    expect(agent.names.first['sort_name']).to match(/\AJimi Hendrix,.* Mr/)

    agent.names.first['name_order'] = "direct"
    agent.save

    expect(JSONModel(:agent_person).find(id).names.first['sort_name']).to match(/\AJimi Hendrix,.* Mr/)
  end


  it "auto-generates the sort name for a parallel name" do
    id = create_person(
      {
        :names => [build(:json_name_person, {
          :primary_name => "Caesar",
          :rest_of_name => "Julius",
          :name_order => "direct",
          :sort_name_auto_generate => true,
          :parallel_names => [{:primary_name => 'Gaius Julius Caesar', :name_order => "direct"}]
        })]
      }).id

    agent = JSONModel(:agent_person).find(id)

    expect(agent.names.first['sort_name']).to match(/^Julius Caesar/)
    expect(agent.names.first['parallel_names'].first['sort_name']).to match(/^Gaius Julius Caesar/)

    agent.names.first['parallel_names'].first['title'] = "Dictator"
    agent.save

    expect(JSONModel(:agent_person).find(id).names.first['parallel_names'].first['sort_name']).to match(/^Gaius.*Dictator$/)
  end


  it "allows people to have a bioghist notes" do

    n1 = build(:json_note_bioghist)

    id = create_person({:notes => [n1]}).id

    agent = JSONModel(:agent_person).find(id)

    expect(agent.notes.length).to eq(1)
    expect(agent.notes[0]["label"]).to eq(n1.label)
  end

  it "allows people to have a general_context notes" do

    n1 = build(:json_note_general_context)

    id = create_person({:notes => [n1]}).id

    agent = JSONModel(:agent_person).find(id)

    expect(agent.notes.length).to eq(1)
    expect(agent.notes[0]["label"]).to eq(n1.label)
  end


  it "throws an error if created with an invalid note type" do

    n1 = build(:json_note_bibliography)

    expect { create_person({:notes => [n1.to_json]}) }.to raise_error(JSONModel::ValidationException)

  end


  it "offers a readonly 'title' of the first name's sort_name" do
    id = create_person({:names => [build(:json_name_person,{:primary_name => "Hendrix", :rest_of_name => "Jimi", :title => "Mr", :name_order => "direct", :sort_name_auto_generate => true})]}).id

    agent = JSONModel(:agent_person).find(id)

    expect(agent.title).to match(/Jimi Hendrix,.* Mr/)
  end

  it "allows agents to have dates of existence" do

    date = build(:json_structured_date_label, :date_label => "existence")

    id = create_person({:dates_of_existence => [date]}).id

    agent = JSONModel(:agent_person).find(id)

    expect(agent.dates_of_existence.length).to eq(1)
    expect(agent.dates_of_existence[0]["structured_date_single"]["date_expression"]).to eq(date["structured_date_single"]["date_expression"])
  end

  it "allows names to have use dates" do

    date = build(:json_structured_date_label, {:date_label => "usage"})

    name = build(:json_name_person, {:use_dates => [date]})

    id = create_person({:names => [name]}).id

    agent = JSONModel(:agent_person).find(id)

    expect(agent.names[0]['use_dates'].length).to eq(1)
  end

  describe "subrecord CRUD" do
    before :each do
      add_gender_values
    end

    it "creates agent subrecords on POST if appropriate" do
      agent_id = create_agent_via_api(:person, {:create_subrecords => true})
      expect(agent_id).to_not eq(-1)

      expect(AgentRecordControl.where(:agent_person_id => agent_id).count).to eq(1)
      expect(AgentAlternateSet.where(:agent_person_id => agent_id).count).to eq(1)
      expect(AgentConventionsDeclaration.where(:agent_person_id => agent_id).count).to eq(1)
      expect(AgentSources.where(:agent_person_id => agent_id).count).to eq(1)
      expect(AgentOtherAgencyCodes.where(:agent_person_id => agent_id).count).to eq(1)
      expect(AgentMaintenanceHistory.where(:agent_person_id => agent_id).count).to eq(1)
      expect(AgentRecordIdentifier.where(:agent_person_id => agent_id).count).to eq(1)
      expect(StructuredDateLabel.where(:agent_person_id => agent_id).count).to eq(1)
      expect(AgentPlace.where(:agent_person_id => agent_id).count).to eq(1)
      expect(AgentOccupation.where(:agent_person_id => agent_id).count).to eq(1)
      expect(AgentFunction.where(:agent_person_id => agent_id).count).to eq(1)
      expect(AgentTopic.where(:agent_person_id => agent_id).count).to eq(1)
      expect(AgentIdentifier.where(:agent_person_id => agent_id).count).to eq(1)
      expect(UsedLanguage.where(:agent_person_id => agent_id).count).to eq(1)
      expect(UsedLanguage.where(:agent_person_id => agent_id).count).to eq(1)
      expect(AgentResource.where(:agent_person_id => agent_id).count).to eq(1)
    end

    it "deletes agent subrecords when parent agent is deleted" do
      agent_id = create_agent_via_api(:person, {:create_subrecords => true})
      expect(agent_id).to_not eq(-1)


      url = URI("#{JSONModel::HTTP.backend_url}/agents/people/#{agent_id}")
      response = JSONModel::HTTP.delete_request(url)

      expect(AgentRecordControl.where(:agent_person_id => agent_id).count).to eq(0)
      expect(AgentAlternateSet.where(:agent_person_id => agent_id).count).to eq(0)
      expect(AgentConventionsDeclaration.where(:agent_person_id => agent_id).count).to eq(0)
      expect(AgentSources.where(:agent_person_id => agent_id).count).to eq(0)
      expect(AgentOtherAgencyCodes.where(:agent_person_id => agent_id).count).to eq(0)
      expect(AgentMaintenanceHistory.where(:agent_person_id => agent_id).count).to eq(0)
      expect(AgentRecordIdentifier.where(:agent_person_id => agent_id).count).to eq(0)
      expect(StructuredDateLabel.where(:agent_person_id => agent_id).count).to eq(0)
      expect(AgentPlace.where(:agent_person_id => agent_id).count).to eq(0)
      expect(AgentOccupation.where(:agent_person_id => agent_id).count).to eq(0)
      expect(AgentFunction.where(:agent_person_id => agent_id).count).to eq(0)
      expect(AgentTopic.where(:agent_person_id => agent_id).count).to eq(0)
      expect(AgentIdentifier.where(:agent_person_id => agent_id).count).to eq(0)
      expect(UsedLanguage.where(:agent_person_id => agent_id).count).to eq(0)
      expect(AgentResource.where(:agent_person_id => agent_id).count).to eq(0)
    end

    it "gets subrecords along with agent" do
      agent_id = create_agent_via_api(:person, {:create_subrecords => true})
      expect(agent_id).to_not eq(-1)

      url = URI("#{JSONModel::HTTP.backend_url}/agents/people/#{agent_id}")
      response = JSONModel::HTTP.get_response(url)
      json_response = ASUtils.json_parse(response.body)

      expect(json_response["agent_record_controls"].length).to eq(1)
      expect(json_response["agent_alternate_sets"].length).to eq(1)
      expect(json_response["agent_conventions_declarations"].length).to eq(1)
      expect(json_response["agent_other_agency_codes"].length).to eq(1)
      expect(json_response["agent_maintenance_histories"].length).to eq(1)
      expect(json_response["agent_record_identifiers"].length).to eq(1)
      expect(json_response["agent_sources"].length).to eq(1)
      expect(json_response["dates_of_existence"].length).to eq(1)
      expect(json_response["agent_places"].length).to eq(1)
      expect(json_response["agent_occupations"].length).to eq(1)
      expect(json_response["agent_functions"].length).to eq(1)
      expect(json_response["agent_topics"].length).to eq(1)
      expect(json_response["agent_identifiers"].length).to eq(1)
      expect(json_response["used_languages"].length).to eq(1)
      expect(json_response["agent_resources"].length).to eq(1)
    end
  end
end
