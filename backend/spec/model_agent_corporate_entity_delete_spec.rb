require 'spec_helper'

describe 'AgentCorporateEntity#delete' do

  it "blocks deletion when the agent represents a repository" do
    repo = create(:repo)
    agent = AgentCorporateEntity.create_from_json(build(:json_agent_corporate_entity))

    Repository[repo.id].update(:agent_representation_id => agent[:id])

    expect {
      AgentCorporateEntity[agent[:id]].delete
    }.to raise_error(ConflictException, /linked to a repository/)
  end

end
