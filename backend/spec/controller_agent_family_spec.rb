require 'spec_helper'
require 'agent_spec_helper'

describe 'Family agent controller' do

  def create_family(opts = {})
    create(:json_agent_family, opts)
  end


  it "lets you create a family and get them back" do
    opts = {:names => [build(:json_name_family)],
            :agent_contacts => [build(:json_agent_contact)]
            }

    id = create_family(opts).id
    expect(JSONModel(:agent_family).find(id).names.first['family_name']).to eq(opts[:names][0]['family_name'])
  end


  it "lets you update a family" do
    id = create_family(:agent_contacts => nil).id

    family = JSONModel(:agent_family).find(id)
    [0,1].each do |n|

      opts = {:name => generate(:generic_name)}
      family.agent_contacts << build(:json_agent_contact, opts)

      family.save

      expect(JSONModel(:agent_family).find(id).agent_contacts[n]['name']).to eq(opts[:name])
    end
  end

  it "sets the sort name if one is provided" do
    opts = {:names => [build(:json_name_family, :sort_name => "Custom Sort Name", :sort_name_auto_generate => false)]}

    id = create_family(opts).id
    expect(JSONModel(:agent_family).find(id).names.first['sort_name']).to eq(opts[:names][0]['sort_name'])
  end


  it "auto-generates the sort name if one is not provided" do
    id = create_family({:names => [build(:json_name_family,
                                         {:family_name => "Hendrix", :sort_name_auto_generate => true})]}).id

    agent = JSONModel(:agent_family).find(id)

    expect(agent.names.first['sort_name']).to match(/\AHendrix/)

    agent.names.first['qualifier'] = "FACT123"
    agent.save

    expect(JSONModel(:agent_family).find(id).names.first['sort_name']).to match(/\AHendrix.*\(FACT123\)/)
  end


  it "can give a list of family agents" do
    uris = (1...4).map {|_| create_family.uri}
    results = JSONModel(:agent_family).all(:page => 1)['results'].map {|rec| rec['uri']}

    expect((uris - results).length).to eq(0)
  end

  it "allows families to have a bioghist notes" do

    n1 = build(:json_note_bioghist)

    id = create_family({:notes => [n1]}).id

    agent = JSONModel(:agent_family).find(id)

    expect(agent.notes.length).to eq(1)
    expect(agent.notes[0]["label"]).to eq(n1.label)
  end

  it "allows families to have a general_context notes" do

    n1 = build(:json_note_general_context)

    id = create_family({:notes => [n1]}).id

    agent = JSONModel(:agent_family).find(id)

    expect(agent.notes.length).to eq(1)
    expect(agent.notes[0]["label"]).to eq(n1.label)
  end

  it "allows families to have a structure_or_genealogy notes" do

    n1 = build(:json_note_legal_status)

    id = create_family({:notes => [n1]}).id

    agent = JSONModel(:agent_family).find(id)

    expect(agent.notes.length).to eq(1)
    expect(agent.notes[0]["label"]).to eq(n1.label)
  end

  describe "subrecord CRUD" do
    it "creates agent subrecords on POST if appropriate" do
      agent_id = create_agent_via_api(:family, {:create_subrecords => true})
      expect(agent_id).to_not eq(-1)

      expect(AgentRecordControl.where(:agent_family_id => agent_id).count).to eq(1)
      expect(AgentAlternateSet.where(:agent_family_id => agent_id).count).to eq(1)
      expect(AgentConventionsDeclaration.where(:agent_family_id => agent_id).count).to eq(1)
      expect(AgentSources.where(:agent_family_id => agent_id).count).to eq(1)
      expect(AgentOtherAgencyCodes.where(:agent_family_id => agent_id).count).to eq(1)
      expect(AgentMaintenanceHistory.where(:agent_family_id => agent_id).count).to eq(1)
      expect(AgentRecordIdentifier.where(:agent_family_id => agent_id).count).to eq(1)
      expect(StructuredDateLabel.where(:agent_family_id => agent_id).count).to eq(1)
      expect(AgentPlace.where(:agent_family_id => agent_id).count).to eq(1)
      expect(AgentOccupation.where(:agent_family_id => agent_id).count).to eq(1)
      expect(AgentFunction.where(:agent_family_id => agent_id).count).to eq(1)
      expect(AgentTopic.where(:agent_family_id => agent_id).count).to eq(1)
      expect(AgentIdentifier.where(:agent_family_id => agent_id).count).to eq(1)
      expect(UsedLanguage.where(:agent_family_id => agent_id).count).to eq(1)
      expect(AgentResource.where(:agent_family_id => agent_id).count).to eq(1)
    end

    it "deletes agent subrecords when parent agent is deleted" do
      agent_id = create_agent_via_api(:family, {:create_subrecords => true})
      expect(agent_id).to_not eq(-1)


      url = URI("#{JSONModel::HTTP.backend_url}/agents/families/#{agent_id}")
      response = JSONModel::HTTP.delete_request(url)

      expect(AgentRecordControl.where(:agent_family_id => agent_id).count).to eq(0)
      expect(AgentAlternateSet.where(:agent_family_id => agent_id).count).to eq(0)
      expect(AgentConventionsDeclaration.where(:agent_family_id => agent_id).count).to eq(0)
      expect(AgentSources.where(:agent_family_id => agent_id).count).to eq(0)
      expect(AgentOtherAgencyCodes.where(:agent_family_id => agent_id).count).to eq(0)
      expect(AgentMaintenanceHistory.where(:agent_family_id => agent_id).count).to eq(0)
      expect(AgentRecordIdentifier.where(:agent_family_id => agent_id).count).to eq(0)
      expect(StructuredDateLabel.where(:agent_family_id => agent_id).count).to eq(0)
      expect(AgentPlace.where(:agent_family_id => agent_id).count).to eq(0)
      expect(AgentOccupation.where(:agent_family_id => agent_id).count).to eq(0)
      expect(AgentFunction.where(:agent_family_id => agent_id).count).to eq(0)
      expect(AgentTopic.where(:agent_family_id => agent_id).count).to eq(0)
      expect(AgentIdentifier.where(:agent_family_id => agent_id).count).to eq(0)
      expect(UsedLanguage.where(:agent_family_id => agent_id).count).to eq(0)
      expect(AgentResource.where(:agent_family_id => agent_id).count).to eq(0)
    end

    it "gets subrecords along with agent" do
      agent_id = create_agent_via_api(:family, {:create_subrecords => true})
      expect(agent_id).to_not eq(-1)

      url = URI("#{JSONModel::HTTP.backend_url}/agents/families/#{agent_id}")
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
