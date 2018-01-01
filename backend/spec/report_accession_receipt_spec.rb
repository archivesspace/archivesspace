require 'spec_helper'

describe AccessionReceiptReport do
  let(:datab) { Sequel.connect(AppConfig[:db_url]) }
  let(:report) { AccessionReceiptReport.new({:repo_id => 2},
                                {},
                                datab) }

  it 'returns the correct fields for the accession receipt report' do
    expect(report.query.first.keys.length).to eq(9)
    expect(report.query.first).to have_key(:accessionId)
    expect(report.query.first).to have_key(:repo_id)
    expect(report.query.first).to have_key(:accessionNumber)
    expect(report.query.first).to have_key(:title)
    expect(report.query.first).to have_key(:accessionDate)
    expect(report.query.first).to have_key(:extentNumber)
    expect(report.query.first).to have_key(:extentType)
    expect(report.query.first).to have_key(:containerSummary)
    expect(report.query.first).to have_key(:repositoryName)
  end
  it 'has the correct template name' do
    expect(report.template).to eq('accession_receipt_report.erb')
  end
  it 'renders the expected report' do
    rend = ReportErbRenderer.new(report,{})
    expect(rend.render(report.template)).to include('Accession Receipt Report')
  end
end
