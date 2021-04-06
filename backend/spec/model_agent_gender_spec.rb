require_relative 'spec_helper'
require_relative 'agent_spec_helper'

describe 'AgentGender model' do
  it "allows agent_gender records to be created" do
    add_gender_values

    gender = AgentGender.create_from_json(build(:json_agent_gender))
    expect(AgentGender[gender[:id]]).to_not eq(nil)
  end
end
