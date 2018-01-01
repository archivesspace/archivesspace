require 'spec_helper'

describe AccessionRightsTransferredReport do
  let(:datab) { Sequel.connect(AppConfig[:db_url]) }
  let(:report) { AccessionReport.new({:repo_id => 2},
                                {},
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
  it 'renders the expected report' do
    rend = ReportErbRenderer.new(report,{})
    expect(rend.render(report.template)).to include('Accessions with rights transferred')
  end
end
