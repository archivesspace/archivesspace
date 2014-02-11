require 'spec_helper'

describe 'Corporate entity agent controller' do

  def create_corporate_entity(opts = {})
    create(:json_agent_corporate_entity, opts)
  end


  it "lets you create a corporate entity and get it back" do
    opts = {:names => [build(:json_name_corporate_entity)],
            :agent_contacts => [build(:json_agent_contact)]}

    ce = create_corporate_entity(opts)
    JSONModel(:agent_corporate_entity).find(ce.id).names.first['primary_name'].should eq(opts[:names][0]['primary_name'])
  end


  it "lets you update a corporate_entity by adding a contact" do
    id = create_corporate_entity(:agent_contacts => []).id

    corporate_entity = JSONModel(:agent_corporate_entity).find(id)

    opts = {:name => generate(:generic_name)}

    corporate_entity.agent_contacts << build(:json_agent_contact, opts)

    corporate_entity.save

    JSONModel(:agent_corporate_entity).find(id).agent_contacts[0]['name'].should eq(opts[:name])
  end


  it "can add an external document to a corporate entity agent" do
    JSONModel.with_repository(nil) do

      # Nothing here should need a repository (since agents are global), so test without!
      RequestContext.put(:repo_id, nil)

      agent = create(:json_agent_corporate_entity,
                     :external_documents => [build(:json_external_document)])

      agent.external_documents.length.should eq(1)
    end
  end


  it "can give a list of corporate entity agents" do
    count = JSONModel(:agent_corporate_entity).all(:page => 1)['results'].count

    create_corporate_entity
    create_corporate_entity
    create_corporate_entity

    # There's a corporate entity created in the test setup too.
    JSONModel(:agent_corporate_entity).all(:page => 1)['results'].count.should eq(count + 3)
  end


  it "sets the sort name if one is provided" do
    opts = {:names => [build(:json_name_corporate_entity, :sort_name => "Custom Sort Name", :sort_name_auto_generate => false)]}

    id = create_corporate_entity(opts).id
    JSONModel(:agent_corporate_entity).find(id).names.first['sort_name'].should eq(opts[:names][0]['sort_name'])
  end


  it "auto-generates the sort name if one is not provided" do
    id = create_corporate_entity({:names => [build(:json_name_corporate_entity,{:primary_name => "ArchivesSpace", :sort_name_auto_generate => true})]}).id

    agent = JSONModel(:agent_corporate_entity).find(id)

    agent.names.first['sort_name'].should match(/\AArchivesSpace/)

    agent.names.first['qualifier'] = "Global"
    agent.save

    JSONModel(:agent_corporate_entity).find(id).names.first['sort_name'].should match(/\AArchivesSpace.* \(Global\)/)
  end


end
