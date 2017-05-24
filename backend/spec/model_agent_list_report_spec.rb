require 'spec_helper'

require_relative '../app/model/reports/abstract_report.rb'
require_relative '../app/model/reports/agents/agent_list_report/agent_list_report.rb'

describe AgentListReport do
  let(:repo)  { Repository.create_from_json(JSONModel(:repository).from_hash(:repo_code => "TESTREPO",
                                                                      :name => "My new test repository")) }
  let(:datab) { Sequel.connect(AppConfig[:db_url]) }
  let(:acc_job) { Job.create_from_json(build(:json_agent_job),
                       :repo_id => repo.id,
                       :user => create_nobody_user) }
  let(:report) { AgentListReport.new({:repo_id => repo.id},
                                acc_job,
                                datab) }
  it 'returns the correct fields for the agent report' do
    expect(report.query.first.keys.length).to eq(4)
    expect(report.query.first).to have_key(:agentId)
    expect(report.query.first).to have_key(:sortName)
    expect(report.query.first).to have_key(:nameType)
    expect(report.query.first).to have_key(:nameSource)
  end
  it 'has the correct template name' do
    expect(report.template).to eq('generic_listing.erb')
  end
  xit 'returns the correct number of values' do
  end
end
