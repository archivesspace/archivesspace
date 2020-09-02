require_relative 'spec_helper'

describe 'AgentIdentifier model' do
  it "allows agent_identifier records to be created" do
    identifier = AgentIdentifier.create_from_json(build(:json_agent_identifier, :agent_person_id => rand(10000)))
    expect(AgentIdentifier[identifier[:id]]).to_not eq(nil)
  end
end
