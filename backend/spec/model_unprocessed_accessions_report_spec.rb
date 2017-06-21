require 'spec_helper'

describe UnprocessedAccessionsReport do
  let(:repo)  { Repository.create_from_json(JSONModel(:repository).from_hash(:repo_code => "TESTREPO",
                                                                      :name => "My new test repository")) }
  let(:datab) { Sequel.connect(AppConfig[:db_url]) }
  let(:unp_acc_job) { Job.create_from_json(build(:json_unproc_accession_job),
                       :repo_id => repo.id,
                       :user => create_nobody_user) }
  let(:report) { UnprocessedAccessionsReport.new({:repo_id => repo.id},
                                unp_acc_job,
                                datab) }
  it 'returns the correct fields for the accession report' do
    puts report.query.inspect
  end
  it 'has the correct template name' do
    expect(report.template).to eq('generic_listing.erb')
  end
  it 'renders the expected report' do
    rend = ReportErbRenderer.new(report,{})
    expect(rend.render(report.template)).to include('Unprocessed Accessions List')
  end
end
