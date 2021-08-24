require_relative 'spec_helper'

describe 'AgentTopic model' do
  it "allows agent_topic records to be created" do
    topic = AgentTopic.create_from_json(build(:json_agent_topic))
    expect(AgentTopic[topic[:id]]).to_not eq(nil)
  end

  it "validates that agent_topic records have a valid subject defined" do
    topic = AgentTopic.create_from_json(build(:json_agent_topic))

    expect {
      topic = AgentTopic.create_from_json(build(:json_agent_topic, :subjects => []))
    }.to raise_error(JSONModel::ValidationException)
  end

  it "won't let you delete a subject that has a role in a topic" do
    subject = create(:json_subject)
    subject_place = create(:json_subject)
    agent_topic = AgentTopic.create_from_json(build(:json_agent_topic, subjects: [{'ref' => subject.uri}], places: [{'ref' => subject_place.uri}]))

    expect {
      Subject[subject.id].delete
    }.to raise_error ConflictException

    expect {
      Subject[subject_place.id].delete
    }.to raise_error ConflictException
  end
end
