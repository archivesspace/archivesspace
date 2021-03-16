require 'spec_helper'
require 'agent_spec_helper'

describe 'Software agent controller' do

  def create_software(opts = {})
    create(:json_agent_software, opts)
  end


  it "lets you create a software agent and get them back" do
    opts = {:names => [build(:json_name_software, :manufacturer => generate(:generic_name))]}

    id = create_software(opts).id
    expect(JSONModel(:agent_software).find(id).names.first['manufacturer']).to eq(opts[:names][0]['manufacturer'])
  end


  it "lets you update a software agent" do
    id = create_software(:agent_contacts => nil).id

    software = JSONModel(:agent_software).find(id)
    [0,1].each do |n|
      opts = {:name => generate(:generic_name)}

      software.agent_contacts << build(:json_agent_contact, opts)
      software.save

      expect(JSONModel(:agent_software).find(id).agent_contacts[n]['name']).to eq(opts[:name])
    end
  end


  it "can give a list of software agents" do
    start = JSONModel(:agent_software).all(:page => 1)['results'].count

    2.times { create_software }

    expect(JSONModel(:agent_software).all(:page => 1)['results'].count).to eq(start+2)
  end


  it "publishes the software agent and subrecords when /publish is POSTed" do
    software = create(:json_agent_software, {
                  :publish => false,
                  :names => [build(:json_name_software)],
                  :external_documents => [build(:json_external_document, {:publish => false})],
                  :agent_places => [build(:json_agent_place)]
                })

    # Confirm various subrecords are unpublished
    software = JSONModel(:agent_software).find(software.id)
    expect(software.publish).to be_falsey
    expect(software.external_documents[0]['publish']).to be_falsey
    expect(software.agent_places[0]['publish']).to be_falsey
    expect(software.agent_places[0]['notes'][0]['publish']).to be_falsey

    url = URI("#{JSONModel::HTTP.backend_url}#{software.uri}/publish")

    request = Net::HTTP::Post.new(url.request_uri)
    response = JSONModel::HTTP.do_http_request(url, request)

    # Now they're published
    software = JSONModel(:agent_software).find(software.id)
    expect(software.publish).to be_truthy
    expect(software.external_documents[0]['publish']).to be_truthy
    expect(software.agent_places[0]['publish']).to be_truthy
    expect(software.agent_places[0]['notes'][0]['publish']).to be_truthy
  end


  it "sets the sort name if one is provided" do
    opts = {:names => [build(:json_name_software, :sort_name => "Custom Sort Name", :sort_name_auto_generate => false)]}

    id = create_software(opts).id
    expect(JSONModel(:agent_software).find(id).names.first['sort_name']).to eq(opts[:names][0]['sort_name'])
  end


  it "auto-generates the sort name if one is not provided" do
    id = create_software({:names => [build(:json_name_software,
                                           {:software_name => "ArchivesSpace", :sort_name_auto_generate => true})]}).id

    agent = JSONModel(:agent_software).find(id)

    expect(agent.names.first['sort_name']).to match(/\AArchivesSpace/)

    agent.names.first['version'] = "1.0"
    agent.save

    expect(JSONModel(:agent_software).find(id).names.first['sort_name']).to match(/\AArchivesSpace.*1\.0/)
  end

  it "auto-generates the sort name for a parallel name" do
    id = create_software(
      {
        :names => [build(:json_name_software, {
          :software_name => "ArchivesSpace",
          :sort_name_auto_generate => true,
          :parallel_names => [{:software_name => 'Your friendly archives management tool'}]
        })]
      }).id

    agent = JSONModel(:agent_software).find(id)

    expect(agent.names.first['sort_name']).to match(/\AArchivesSpace/)
    expect(agent.names.first['parallel_names'].first['sort_name']).to match(/^Your.*tool$/)

    agent.names.first['parallel_names'].first['version'] = "1.0"
    agent.save

    expect(JSONModel(:agent_software).find(id).names.first['parallel_names'].first['sort_name']).to match(/^Your.*tool.*1\.0$/)
  end

  it "allows software to have a bioghist notes" do

    n1 = build(:json_note_bioghist)

    id = create_software({:notes => [n1]}).id

    agent = JSONModel(:agent_software).find(id)

    expect(agent.notes.length).to eq(1)
    expect(agent.notes[0]["label"]).to eq(n1.label)
  end

  it "allows software to have a general_context notes" do

    n1 = build(:json_note_general_context)

    id = create_software({:notes => [n1]}).id

    agent = JSONModel(:agent_software).find(id)

    expect(agent.notes.length).to eq(1)
    expect(agent.notes[0]["label"]).to eq(n1.label)
  end


  describe "subrecord CRUD" do
    it "creates agent subrecords on POST if appropriate" do
      agent_id = create_agent_via_api(:software, {:create_subrecords => true})
      expect(agent_id).to_not eq(-1)

      expect(AgentRecordControl.where(:agent_software_id => agent_id).count).to eq(1)
      expect(AgentAlternateSet.where(:agent_software_id => agent_id).count).to eq(1)
      expect(AgentConventionsDeclaration.where(:agent_software_id => agent_id).count).to eq(1)
      expect(AgentSources.where(:agent_software_id => agent_id).count).to eq(1)
      expect(AgentOtherAgencyCodes.where(:agent_software_id => agent_id).count).to eq(1)
      expect(AgentMaintenanceHistory.where(:agent_software_id => agent_id).count).to eq(1)
      expect(AgentRecordIdentifier.where(:agent_software_id => agent_id).count).to eq(1)
      expect(StructuredDateLabel.where(:agent_software_id => agent_id).count).to eq(1)
      expect(AgentPlace.where(:agent_software_id => agent_id).count).to eq(1)
      expect(AgentOccupation.where(:agent_software_id => agent_id).count).to eq(1)
      expect(AgentFunction.where(:agent_software_id => agent_id).count).to eq(1)
      expect(AgentTopic.where(:agent_software_id => agent_id).count).to eq(1)
      expect(AgentIdentifier.where(:agent_software_id => agent_id).count).to eq(1)
      expect(UsedLanguage.where(:agent_software_id => agent_id).count).to eq(1)
      expect(AgentResource.where(:agent_software_id => agent_id).count).to eq(1)
    end

    it "deletes agent subrecords when parent agent is deleted" do
      agent_id = create_agent_via_api(:software, {:create_subrecords => true})
      expect(agent_id).to_not eq(-1)


      url = URI("#{JSONModel::HTTP.backend_url}/agents/software/#{agent_id}")
      response = JSONModel::HTTP.delete_request(url)

      expect(AgentRecordControl.where(:agent_software_id => agent_id).count).to eq(0)
      expect(AgentAlternateSet.where(:agent_software_id => agent_id).count).to eq(0)
      expect(AgentConventionsDeclaration.where(:agent_software_id => agent_id).count).to eq(0)
      expect(AgentSources.where(:agent_software_id => agent_id).count).to eq(0)
      expect(AgentOtherAgencyCodes.where(:agent_software_id => agent_id).count).to eq(0)
      expect(AgentMaintenanceHistory.where(:agent_software_id => agent_id).count).to eq(0)
      expect(AgentRecordIdentifier.where(:agent_software_id => agent_id).count).to eq(0)
      expect(StructuredDateLabel.where(:agent_software_id => agent_id).count).to eq(0)
      expect(AgentPlace.where(:agent_software_id => agent_id).count).to eq(0)
      expect(AgentOccupation.where(:agent_software_id => agent_id).count).to eq(0)
      expect(AgentFunction.where(:agent_software_id => agent_id).count).to eq(0)
      expect(AgentTopic.where(:agent_software_id => agent_id).count).to eq(0)
      expect(AgentIdentifier.where(:agent_software_id => agent_id).count).to eq(0)
      expect(UsedLanguage.where(:agent_software_id => agent_id).count).to eq(0)
      expect(AgentResource.where(:agent_software_id => agent_id).count).to eq(0)
    end

    it "gets subrecords along with agent" do
      agent_id = create_agent_via_api(:software, {:create_subrecords => true})
      expect(agent_id).to_not eq(-1)

      url = URI("#{JSONModel::HTTP.backend_url}/agents/software/#{agent_id}")
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
