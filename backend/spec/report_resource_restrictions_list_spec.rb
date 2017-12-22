require 'spec_helper'

describe ResourceRestrictionsListReport do
  let(:repo)  { Repository.create_from_json(JSONModel(:repository).from_hash(:repo_code => "TESTREPO",
                                                                      :name => "My new test repository")) }
  let(:datab) { Sequel.connect(AppConfig[:db_url]) }
  let(:res_res_job) { Job.create_from_json(build(:json_resource_restrict_job),
                       :repo_id => repo.id,
                       :user => create_nobody_user) }
  let(:report) { ResourceRestrictionsListReport.new({:repo_id => repo.id},
                                res_res_job,
                                datab) }
  it 'returns the correct fields for the resource restrictions list report' do
    puts "LANEY #{report.query.first.keys}"
    # expect(report.query.first.keys.length).to eq(8)
    # expect(report.query.first).to have_key(:resourceId)
    # expect(report.query.first).to have_key(:repo_id)
    # expect(report.query.first).to have_key(:title)
    # expect(report.query.first).to have_key(:resourceIdentifier)
    # expect(report.query.first).to have_key(:restrictionsApply)
    # expect(report.query.first).to have_key(:level)
    # expect(report.query.first).to have_key(:dateExpression)
    # expect(report.query.first).to have_key(:extentNumber)
  end
  it 'has the correct template name' do
    expect(report.template).to eq('resource_restrictions_list_report.erb')
  end
  it 'renders the expected report' do
    # rend = ReportErbRenderer.new(report,{})
    # puts rend.render(report.template)
    # expect(rend.render(report.template)).to include('Resources and Locations List')
    # expect(rend.render(report.template)).to include('resource_locations_subreport.erb')
  end
end
