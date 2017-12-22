require 'spec_helper'
require 'erb'
require_relative '../app/lib/reports/report_response'

describe AccessionDeaccessionsListReport do
  let(:repo)  { Repository.create_from_json(JSONModel(:repository).from_hash(:repo_code => "TESTREPO",
                                                                      :name => "My new test repository")) }
  let(:datab) { Sequel.connect(AppConfig[:db_url]) }
  let(:deacc_job) { Job.create_from_json(build(:json_deaccession_job),
                       :repo_id => repo.id,
                       :user => create_nobody_user) }
  let(:report) { AccessionDeaccessionsListReport.new({:repo_id => repo.id, :format => 'csv'},
                                deacc_job,
                                datab) }
  it 'returns the correct fields for the Accessions Acquired and Linked Deaccession Records report' do
    puts "Laney #{report.inspect}"
    expect(report.query.first.keys.length).to eq(8)
    expect(report.query.first).to have_key(:accessionId)
    expect(report.query.first).to have_key(:repo_id)
    expect(report.query.first).to have_key(:accessionNumber)
    expect(report.query.first).to have_key(:title)
    expect(report.query.first).to have_key(:accessionDate)
    expect(report.query.first).to have_key(:extentNumber)
    expect(report.query.first).to have_key(:extentType)
    expect(report.query.first).to have_key(:containerSummary)
    # expect(report.query.first).to have_key(:deaccessionId)
    # expect(report.query.first).to have_key(:description)
    # expect(report.query.first).to have_key(:notification)
    # expect(report.query.first).to have_key(:deaccessionDate)
    # expect(report.query.first).to have_key(:extentNumber)
    # expect(report.query.first).to have_key(:extentType)
  end
  it 'has the correct template name' do
    expect(report.template).to eq('accession_deaccessions_list_report.erb')
  end
  it 'renders the expected report' do
    rend = ReportErbRenderer.new(report, {})
    expect(rend.render(report.template)).to include('Accessions Acquired and Linked Deaccession Records')
    expect(rend.render(report.template)).to include('accession_deaccessions_subreport.erb')
  end
end
