require 'spec_helper'
require 'agent_spec_helper'

describe 'Corporate entity agent controller' do

  def create_corporate_entity(opts = {})
    create(:json_agent_corporate_entity, opts)
  end


  it "lets you create a corporate entity and get it back" do
    opts = {:names => [build(:json_name_corporate_entity)],
            :agent_contacts => [build(:json_agent_contact)]}

    ce = create_corporate_entity(opts)
    expect(JSONModel(:agent_corporate_entity).find(ce.id).names.first['primary_name']).to eq(opts[:names][0]['primary_name'])
  end


  it "lets you update a corporate_entity by adding a contact" do
    id = create_corporate_entity(:agent_contacts => []).id

    corporate_entity = JSONModel(:agent_corporate_entity).find(id)

    opts = {:name => generate(:generic_name)}

    corporate_entity.agent_contacts << build(:json_agent_contact, opts)

    corporate_entity.save

    expect(JSONModel(:agent_corporate_entity).find(id).agent_contacts[0]['name']).to eq(opts[:name])
  end


  it "can add an external document to a corporate entity agent" do
    JSONModel.with_repository(nil) do

      # Nothing here should need a repository (since agents are global), so test without!
      RequestContext.put(:repo_id, nil)

      agent = create(:json_agent_corporate_entity,
                     :external_documents => [build(:json_external_document)])

      expect(agent.external_documents.length).to eq(1)
    end
  end


  it "can give a list of corporate entity agents" do
    AppConfig[:default_page_size] = 30
    count = JSONModel(:agent_corporate_entity).all(:page => 1)['results'].count

    create_corporate_entity
    create_corporate_entity
    create_corporate_entity

    # There's a corporate entity created in the test setup too.
    expect(JSONModel(:agent_corporate_entity).all(:page => 1)['results'].count).to eq(count + 3)
  end


  it "publishes the corporate entity agent and subrecords when /publish is POSTed" do
    ce = create(:json_agent_corporate_entity, {
                  :publish => false,
                  :names => [build(:json_name_corporate_entity)],
                  :external_documents => [build(:json_external_document, {:publish => false})],
                  :agent_places => [build(:json_agent_place)]
                })

    # Confirm various subrecords are unpublished
    ce = JSONModel(:agent_corporate_entity).find(ce.id)
    expect(ce.publish).to be_falsey
    expect(ce.external_documents[0]['publish']).to be_falsey
    expect(ce.agent_places[0]['publish']).to be_falsey
    expect(ce.agent_places[0]['notes'][0]['publish']).to be_falsey

    url = URI("#{JSONModel::HTTP.backend_url}#{ce.uri}/publish")

    request = Net::HTTP::Post.new(url.request_uri)
    response = JSONModel::HTTP.do_http_request(url, request)

    # Now they're published
    ce = JSONModel(:agent_corporate_entity).find(ce.id)
    expect(ce.publish).to be_truthy
    expect(ce.external_documents[0]['publish']).to be_truthy
    expect(ce.agent_places[0]['publish']).to be_truthy
    expect(ce.agent_places[0]['notes'][0]['publish']).to be_truthy
  end


  it "sets the sort name if one is provided" do
    opts = {:names => [build(:json_name_corporate_entity, :sort_name => "Custom Sort Name", :sort_name_auto_generate => false)]}

    id = create_corporate_entity(opts).id
    expect(JSONModel(:agent_corporate_entity).find(id).names.first['sort_name']).to eq(opts[:names][0]['sort_name'])
  end


  it "auto-generates the sort name if one is not provided" do
    id = create_corporate_entity({:names => [build(:json_name_corporate_entity,{:primary_name => "ArchivesSpace", :sort_name_auto_generate => true})]}).id

    agent = JSONModel(:agent_corporate_entity).find(id)

    expect(agent.names.first['sort_name']).to match(/\AArchivesSpace/)

    agent.names.first['qualifier'] = "Global"
    agent.save

    expect(JSONModel(:agent_corporate_entity).find(id).names.first['sort_name']).to match(/\AArchivesSpace.* \(Global\)/)
  end


  it "auto-generates the sort name for a parallel name" do
    id = create_corporate_entity(
      {
        :names => [build(:json_name_corporate_entity, {
          :primary_name => "ArchivesSpace",
          :sort_name_auto_generate => true,
          :parallel_names => [{:primary_name => 'ASpace'}]
        })]
      }).id

    agent = JSONModel(:agent_corporate_entity).find(id)

    expect(agent.names.first['sort_name']).to match(/^ArchivesSpace/)
    expect(agent.names.first['parallel_names'].first['sort_name']).to match(/^ASpace/)

    agent.names.first['parallel_names'].first['qualifier'] = "Global"
    agent.save

    expect(JSONModel(:agent_corporate_entity).find(id).names.first['parallel_names'].first['sort_name']).to match(/^ASpace.*\(Global\)$/)
  end


  it "allows corporations to have a bioghist notes" do

    n1 = build(:json_note_bioghist)

    id = create_corporate_entity({:notes => [n1]}).id

    agent = JSONModel(:agent_corporate_entity).find(id)

    expect(agent.notes.length).to eq(1)
    expect(agent.notes[0]["label"]).to eq(n1.label)
  end

  it "allows corporations to have a general_context notes" do

    n1 = build(:json_note_general_context)

    id = create_corporate_entity({:notes => [n1]}).id

    agent = JSONModel(:agent_corporate_entity).find(id)

    expect(agent.notes.length).to eq(1)
    expect(agent.notes[0]["label"]).to eq(n1.label)
  end

  it "allows corporations to have a mandate notes" do

    n1 = build(:json_note_mandate)

    id = create_corporate_entity({:notes => [n1]}).id

    agent = JSONModel(:agent_corporate_entity).find(id)

    expect(agent.notes.length).to eq(1)
    expect(agent.notes[0]["label"]).to eq(n1.label)
  end

  it "allows corporations to have a legal_status notes" do

    n1 = build(:json_note_legal_status)

    id = create_corporate_entity({:notes => [n1]}).id

    agent = JSONModel(:agent_corporate_entity).find(id)

    expect(agent.notes.length).to eq(1)
    expect(agent.notes[0]["label"]).to eq(n1.label)
  end

  it "allows corporations to have a structure_or_genealogy notes" do

    n1 = build(:json_note_legal_status)

    id = create_corporate_entity({:notes => [n1]}).id

    agent = JSONModel(:agent_corporate_entity).find(id)

    expect(agent.notes.length).to eq(1)
    expect(agent.notes[0]["label"]).to eq(n1.label)
  end

  describe "subrecord CRUD" do
    it "creates agent subrecords on POST if appropriate" do
      agent_id = create_agent_via_api(:corporate_entity, {:create_subrecords => true})
      expect(agent_id).to_not eq(-1)

      expect(AgentRecordControl.where(:agent_corporate_entity_id => agent_id).count).to eq(1)
      expect(AgentAlternateSet.where(:agent_corporate_entity_id => agent_id).count).to eq(1)
      expect(AgentConventionsDeclaration.where(:agent_corporate_entity_id => agent_id).count).to eq(1)
      expect(AgentSources.where(:agent_corporate_entity_id => agent_id).count).to eq(1)
      expect(AgentOtherAgencyCodes.where(:agent_corporate_entity_id => agent_id).count).to eq(1)
      expect(AgentMaintenanceHistory.where(:agent_corporate_entity_id => agent_id).count).to eq(1)
      expect(AgentRecordIdentifier.where(:agent_corporate_entity_id => agent_id).count).to eq(1)
      expect(StructuredDateLabel.where(:agent_corporate_entity_id => agent_id).count).to eq(1)
      expect(AgentPlace.where(:agent_corporate_entity_id => agent_id).count).to eq(1)
      expect(AgentOccupation.where(:agent_corporate_entity_id => agent_id).count).to eq(1)
      expect(AgentFunction.where(:agent_corporate_entity_id => agent_id).count).to eq(1)
      expect(AgentTopic.where(:agent_corporate_entity_id => agent_id).count).to eq(1)
      expect(AgentIdentifier.where(:agent_corporate_entity_id => agent_id).count).to eq(1)
      expect(UsedLanguage.where(:agent_corporate_entity_id => agent_id).count).to eq(1)
      expect(AgentResource.where(:agent_corporate_entity_id => agent_id).count).to eq(1)
    end

    it "deletes agent subrecords when parent agent is deleted" do
      agent_id = create_agent_via_api(:corporate_entity, {:create_subrecords => true})
      expect(agent_id).to_not eq(-1)


      url = URI("#{JSONModel::HTTP.backend_url}/agents/corporate_entities/#{agent_id}")
      response = JSONModel::HTTP.delete_request(url)

      expect(AgentRecordControl.where(:agent_corporate_entity_id => agent_id).count).to eq(0)
      expect(AgentAlternateSet.where(:agent_corporate_entity_id => agent_id).count).to eq(0)
      expect(AgentConventionsDeclaration.where(:agent_corporate_entity_id => agent_id).count).to eq(0)
      expect(AgentSources.where(:agent_corporate_entity_id => agent_id).count).to eq(0)
      expect(AgentOtherAgencyCodes.where(:agent_corporate_entity_id => agent_id).count).to eq(0)
      expect(AgentMaintenanceHistory.where(:agent_corporate_entity_id => agent_id).count).to eq(0)
      expect(AgentRecordIdentifier.where(:agent_corporate_entity_id => agent_id).count).to eq(0)
      expect(StructuredDateLabel.where(:agent_corporate_entity_id => agent_id).count).to eq(0)
      expect(AgentPlace.where(:agent_corporate_entity_id => agent_id).count).to eq(0)
      expect(AgentOccupation.where(:agent_corporate_entity_id => agent_id).count).to eq(0)
      expect(AgentFunction.where(:agent_corporate_entity_id => agent_id).count).to eq(0)
      expect(AgentTopic.where(:agent_corporate_entity_id => agent_id).count).to eq(0)
      expect(AgentIdentifier.where(:agent_corporate_entity_id => agent_id).count).to eq(0)
      expect(UsedLanguage.where(:agent_corporate_entity_id => agent_id).count).to eq(0)
      expect(AgentResource.where(:agent_corporate_entity_id => agent_id).count).to eq(0)
    end

    it "gets subrecords along with agent" do
      agent_id = create_agent_via_api(:corporate_entity, {:create_subrecords => true})
      expect(agent_id).to_not eq(-1)

      url = URI("#{JSONModel::HTTP.backend_url}/agents/corporate_entities/#{agent_id}")
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
