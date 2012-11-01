require 'spec_helper'

describe 'Family agent controller' do

  def create_family(opts = {})
    create(:json_agent_family, opts)
  end


  it "lets you create a family and get them back" do
    opts = {:names => [build(:json_name_family).to_hash],
            :agent_contacts => [build(:json_agent_contact).to_hash]
            }

    id = create_family(opts).id
    JSONModel(:agent_family).find(id).names.first['family_name'].should eq(opts[:names][0]['family_name'])
  end

  it "lets you update a family" do
    id = create_family(:agent_contacts => nil).id

    family = JSONModel(:agent_family).find(id)
    [0,1].each do |n|

      opts = {:name => generate(:generic_name)}
      family.agent_contacts << build(:json_agent_contact, opts).to_hash

      family.save

      JSONModel(:agent_family).find(id).agent_contacts[n]['name'].should eq(opts[:name])
    end

  end


end
