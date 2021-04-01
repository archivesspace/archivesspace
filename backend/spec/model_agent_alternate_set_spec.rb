require_relative 'spec_helper'

describe 'AgentAlternateSet model' do

  it "validates the record making sure at least one of set component, file uri or description is set" do
    expect {
      AgentAlternateSet.create_from_json(build(:agent_alternate_set, :set_component => nil,
                                                          :file_uri => nil,
                                                          :descriptive_note => nil))
    }.to raise_error(JSONModel::ValidationException)


    expect {
      AgentAlternateSet.create_from_json(build(:agent_alternate_set, :set_component => "foo",
                                                          :file_uri => nil,
                                                          :descriptive_note => nil))
    }.to_not raise_error(JSONModel::ValidationException)

    expect {
      AgentAlternateSet.create_from_json(build(:agent_alternate_set, :set_component => nil,
                                                          :file_uri => "foo",
                                                          :descriptive_note => nil))
    }.to_not raise_error(JSONModel::ValidationException)


    expect {
      AgentAlternateSet.create_from_json(build(:agent_alternate_set, :set_component => nil,
                                                          :file_uri => nil,
                                                          :descriptive_note => "foo"))
    }.to_not raise_error(JSONModel::ValidationException)
  end
end
