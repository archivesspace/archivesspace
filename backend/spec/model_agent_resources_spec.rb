require_relative 'spec_helper'

describe 'AgentResource model' do
  it "allows agent_resource records to be created" do
    resource = AgentResource.create_from_json(build(:json_agent_resource))
    expect(AgentResource[resource[:id]]).to_not eq(nil)
  end
end
