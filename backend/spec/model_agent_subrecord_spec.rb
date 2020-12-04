require 'spec_helper'

describe 'Agent model subrecords' do

  def check_subrecord_publish_status(agent:, status:)
    AgentManager::AGENT_SUBRECORDS_WITH_SUBJECTS.each do |subrecord_type|
      agent[subrecord_type].each { |subrecord| expect(subrecord['publish']).to be status }
    end
  end

  it 'sets subrecord publish status to match the agent publish status' do
    agent = build(:json_agent_person_full_subrec)
    agent.save

    expect(agent.publish).to be false
    check_subrecord_publish_status(agent: agent, status: false)

    agent.publish = true
    agent.save

    expect(agent.publish).to be true
    check_subrecord_publish_status(agent: agent, status: true)

    agent.publish = false
    agent.save

    expect(agent.publish).to be false
    check_subrecord_publish_status(agent: agent, status: false)
  end
end
