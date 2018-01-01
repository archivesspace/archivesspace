require 'spec_helper'
require 'erb'
require_relative '../app/lib/reports/report_response'

describe AccessionReport do
  let(:datab) { Sequel.connect(AppConfig[:db_url]) }
  let(:report) { AccessionReport.new({:repo_id => 2},
                                {},
                                datab) }

  it 'returns the correct fields for the accession report' do
    expect(report.query.first.keys.length).to eq(28)
    expect(report.query.first).to have_key(:accessionId)
#    expect(report.query.first).to have_key(repo.id.to_s.to_sym)
    expect(report.query.first).to have_key(:accessionNumber)
    expect(report.query.first).to have_key(:title)
    expect(report.query.first).to have_key(:accessionDate)
    expect(report.query.first).to have_key(:extentNumber)
    expect(report.query.first).to have_key(:extentType)
    expect(report.query.first).to have_key(:generalNote)
    expect(report.query.first).to have_key(:containerSummary)
    expect(report.query.first).to have_key(:dateExpression)
    expect(report.query.first).to have_key(:dateBegin)
    expect(report.query.first).to have_key(:dateEnd)
    expect(report.query.first).to have_key(:bulkDateBegin)
    expect(report.query.first).to have_key(:bulkDateEnd)
    expect(report.query.first).to have_key(:acquisitionType)
    expect(report.query.first).to have_key(:retentionRule)
    expect(report.query.first).to have_key(:descriptionNote)
    expect(report.query.first).to have_key(:conditionNote)
    expect(report.query.first).to have_key(:inventory)
    expect(report.query.first).to have_key(:dispositionNote)
    expect(report.query.first).to have_key(:restrictionsApply)
    expect(report.query.first).to have_key(:accessRestrictions)
    expect(report.query.first).to have_key(:accessRestrictionsNote)
    expect(report.query.first).to have_key(:useRestrictions)
    expect(report.query.first).to have_key(:useRestrictionsNote)
    expect(report.query.first).to have_key(:rightsTransferred)
    expect(report.query.first).to have_key(:rightsTransferredNote)
    expect(report.query.first).to have_key(:acknowledgementSent)
  end
  it 'has the correct template name' do
    expect(report.template).to eq('accession_report.erb')
  end
  it 'renders the expected report' do
    rend = ReportErbRenderer.new(report,{})
    expect(rend.render(report.template)).to include('Accession Report')
    expect(rend.render(report.template)).to include('accession_deaccessions_subreport.erb')
    expect(rend.render(report.template)).to include('accession_locations_subreport.erb')
    expect(rend.render(report.template)).to include('accession_names_subreport.erb')
    expect(rend.render(report.template)).to include('accession_subjects_subreport.erb')
  end
end
