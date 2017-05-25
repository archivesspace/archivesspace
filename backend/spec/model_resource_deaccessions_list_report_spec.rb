require 'spec_helper'

describe ResourceDeaccessionsListReport do
  let(:repo)  { Repository.create_from_json(JSONModel(:repository).from_hash(:repo_code => "TESTREPO",
                                                                      :name => "My new test repository")) }
  let(:datab) { Sequel.connect(AppConfig[:db_url]) }
  let(:res_deacc_job) { Job.create_from_json(build(:json_resource_deacc_job),
                       :repo_id => repo.id,
                       :user => create_nobody_user) }
  let(:report) { ResourceDeaccessionsListReport.new({:repo_id => repo.id},
                                res_deacc_job,
                                datab) }
  it 'returns the correct fields for the resource deaccessions list report' do
    expect(report.query.first.keys.length).to eq(8)
    expect(report.query.first).to have_key(:resourceId)
    expect(report.query.first).to have_key(:repo_id)
    expect(report.query.first).to have_key(:title)
    expect(report.query.first).to have_key(:resourceIdentifier)
    expect(report.query.first).to have_key(:level)
    expect(report.query.first).to have_key(:dateExpression)
    expect(report.query.first).to have_key(:extentNumber)
    expect(report.query.first).to have_key(:deaccessionExtentNumber)
  end
  it 'has the correct template name' do
    expect(report.template).to eq('resource_deaccessions_list_report.erb')
  end
  xit 'returns the correct number of values' do
  end
end
