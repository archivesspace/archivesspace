require 'spec_helper'

describe 'Software agent controller' do

  def create_software(opts = {})
    create(:json_agent_software, opts)
  end


  it "lets you create a software agent and get them back" do
    
    opts = {:names => [build(:json_name_software, :manufacturer => generate(:generic_name)).to_hash]}

    id = create_software(opts).id
    JSONModel(:agent_software).find(id).names.first['manufacturer'].should eq(opts[:names][0]['manufacturer'])
  end

  it "lets you update a software agent" do
    id = create_software(:agent_contacts => nil).id

    software = JSONModel(:agent_software).find(id)
    [0,1].each do |n|
      opts = {:name => generate(:generic_name)}

      software.agent_contacts << build(:json_agent_contact, opts).to_hash
      software.save

      JSONModel(:agent_software).find(id).agent_contacts[n]['name'].should eq(opts[:name])
    end

  end


end
