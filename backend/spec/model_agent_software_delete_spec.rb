require 'spec_helper'

describe 'AgentSoftware#delete' do

  it "blocks deletion of the system's own software agent" do
    expect {
      AgentSoftware.archivesspace_record.delete
    }.to raise_error(AccessDeniedException)
  end


  it "allows deletion of an ordinary software agent" do
    agent = AgentSoftware.create_from_json(build(:json_agent_software))

    expect {
      AgentSoftware[agent[:id]].delete
    }.not_to raise_error
  end

end
