require 'spec_helper'

describe 'Corporate entity agent controller' do

  def create_corporate_entity(opts = {})

    create(:json_agent_corporate_entity, opts)
  end


  it "lets you create a corporate entity and get it back" do

    opts = {:names => [build(:json_name_corporate_entity).to_hash],
            :agent_contacts => [build(:json_agent_contact).to_hash]
            }

    ce = create_corporate_entity(opts)
    JSONModel(:agent_corporate_entity).find(ce.id).names.first['primary_name'].should eq(opts[:names][0]['primary_name'])
  end

  it "lets you update a corporate_entity by adding a contact" do

    id = create_corporate_entity.id

    corporate_entity = JSONModel(:agent_corporate_entity).find(id)

    opts = {:name => generate(:generic_name)}

    corporate_entity.agent_contacts << build(:json_agent_contact, opts).to_hash

    corporate_entity.save

    JSONModel(:agent_corporate_entity).find(id).agent_contacts[0]['name'].should eq(opts[:name])
  end

  it "can add an external document to a corporate entity agent" do
    JSONModel.with_repository(nil) do

      # Nothing here should need a repository (since agents are global), so test without!
      RequestContext.put(:repo_id, nil)

      agent = create(:json_agent_corporate_entity,
                     :external_documents => [build(:json_external_document).to_hash])

      agent.external_documents.length.should eq(1)
    end
  end



end
