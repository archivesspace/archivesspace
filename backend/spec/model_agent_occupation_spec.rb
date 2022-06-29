require_relative 'spec_helper'

describe 'AgentOccupation model' do
  it "allows agent_occupation records to be created" do
    occupation = AgentOccupation.create_from_json(build(:json_agent_occupation))
    expect(AgentOccupation[occupation[:id]]).to_not eq(nil)
  end

  it "validates that agent_occupation records have a valid subject defined" do
    occupation = AgentOccupation.create_from_json(build(:json_agent_occupation))

    expect {
      occupation = AgentOccupation.create_from_json(build(:json_agent_occupation, :subjects => []))
    }.to raise_error(JSONModel::ValidationException)
  end
end
