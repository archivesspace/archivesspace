require 'spec_helper'

require_relative '../app/model/reports/abstract_report.rb'
require_relative '../app/model/reports/accessions/accession_rights_transferred_report/accession_rights_transferred_report.rb'

describe AccessionRightsTransferredReport do
  let(:repo)  { Repository.create_from_json(JSONModel(:repository).from_hash(:repo_code => "TESTREPO",
                                                                      :name => "My new test repository")) }
  let(:datab) { Sequel.connect(AppConfig[:db_url]) }
  let(:acc_job) { Job.create_from_json(build(:json_accession_job),
                       :repo_id => repo.id,
                       :user => create_nobody_user) }
  let(:report) { AccessionRightsTransferredReport.new({:repo_id => repo.id},
                                acc_job,
                                datab) }
  it 'returns the correct fields for the accession report' do
    expect(report.query.first.keys.length).to eq(18)
    expect(report.query.first).to have_key(:accessionId)
    expect(report.query.first).to have_key(:repo_id)
    expect(report.query.first).to have_key(:accessionNumber)
    expect(report.query.first).to have_key(:title)
    expect(report.query.first).to have_key(:accessionDate)
    expect(report.query.first).to have_key(:extentNumber)
    expect(report.query.first).to have_key(:extentType)
    expect(report.query.first).to have_key(:containerSummary)
    expect(report.query.first).to have_key(:accessionProcessed)
    expect(report.query.first).to have_key(:accessionProcessedDate)
    expect(report.query.first).to have_key(:cataloged)
    expect(report.query.first).to have_key(:restrictionsApply)
    expect(report.query.first).to have_key(:accessRestrictions)
    expect(report.query.first).to have_key(:accessRestrictionsNote)
    expect(report.query.first).to have_key(:useRestrictions)
    expect(report.query.first).to have_key(:useRestrictionsNote)
    expect(report.query.first).to have_key(:rightsTransferred)
    expect(report.query.first).to have_key(:rightsTransferredNote)
  end
  it 'has the correct template name' do
    expect(report.template).to eq('accession_rights_transferred_report.erb')
  end
  xit 'returns the correct number of values' do
  end
end
