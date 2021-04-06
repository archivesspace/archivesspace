require_relative 'spec_helper'

describe 'AgentSources model' do

  it "validates the record making sure at least one of set component, file uri or description is set" do
    expect {
      AgentSources.create_from_json(build(:agent_sources, :source_entry => nil,
                                                          :file_uri => nil,
                                                          :descriptive_note => nil))
    }.to raise_error(JSONModel::ValidationException)


    expect {
      AgentSources.create_from_json(build(:agent_sources, :source_entry => "foo",
                                                          :file_uri => nil,
                                                          :descriptive_note => nil))
    }.to_not raise_error(JSONModel::ValidationException)

    expect {
      AgentSources.create_from_json(build(:agent_sources, :source_entry => nil,
                                                          :file_uri => "foo",
                                                          :descriptive_note => nil))
    }.to_not raise_error(JSONModel::ValidationException)


    expect {
      AgentSources.create_from_json(build(:agent_sources, :source_entry => nil,
                                                          :file_uri => nil,
                                                          :descriptive_note => "foo"))
    }.to_not raise_error(JSONModel::ValidationException)
  end
end
