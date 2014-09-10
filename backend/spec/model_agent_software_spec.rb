require 'spec_helper'

describe 'Agent model' do

  it "allows software agent records to be created with multiple names" do
    
    n1 = build(:json_name_software)
    n2 = build(:json_name_software)

    agent = AgentSoftware.create_from_json(build(:json_agent_software, :names => [n1, n2]))

    AgentSoftware[agent[:id]].name_software.length.should eq(2)
  end
  
  it "doesn't allow a software agent record to be created without a name" do
    
    expect { 
      AgentSoftware.create_from_json(build(:json_agent_software, :names => []))
      }.to raise_error(JSONModel::ValidationException)
  end


  it "allows a software agent record to be created with linked contact details" do
    
    opts = {:name => 'Business hours contact'}
    
    c1 = build(:json_agent_contact, opts)

    agent = AgentSoftware.create_from_json(build(:json_agent_software, {:agent_contacts => [c1]}))

    AgentSoftware[agent[:id]].agent_contact.length.should eq(1)
    AgentSoftware[agent[:id]].agent_contact[0][:name].should eq(opts[:name])
  end


  it "requires a source to be set if an authority id is provided" do
    
    n1 = build(:json_name_software, :authority_id => 'wooo')
    
    expect { 
      n1.to_hash
     }.to raise_error(JSONModel::ValidationException)
  end

  it "returns the existing agent if an name authority id is already in place " do
    json =    build( :json_agent_software,
                     :names => [build(:json_name_software,
                     'authority_id' => 'thesame',
                      'source' => "naf"

                     )])
    json2 =    build( :json_agent_software,
                     :names => [build(:json_name_software,
                     'authority_id' => 'thesame',
                      'source' => "naf"
                     )])
   
    a1 =    AgentSoftware.create_from_json(json)
    a2 =    AgentSoftware.ensure_exists(json2, nil)
    
    a1.should eq(a2) # the names should still be the same as the first authority_id names 
  end

  it "maintains a record that represents the ArchivesSpace application itself" do
    as_json = AgentSoftware.to_jsonmodel(AgentSoftware.archivesspace_record)
    as_json['names'][0]['version'].should eq ASConstants.VERSION
  end

end
