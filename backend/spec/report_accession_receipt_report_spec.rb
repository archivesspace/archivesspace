require 'spec_helper'

describe 'AccessionReceiptReport' do

  it "generate an HTML report that looks about right" do
    accession = create(:json_accession)
    params = {
      repo_id: $repo_id,
      format: "html",
      scope_by_date: true,
      from: Date.today - 1,
      to: Date.today
    }

    report = DB.open do |db|
      AccessionReceiptReport.new(params, nil, db)
    end
    file = ASUtils.tempfile('report_job_')
    generator = ReportGenerator.new(report)
    result = generator.generate(file)
    file.rewind
    doc = Nokogiri::HTML(file.read)
    expect(doc.xpath("/html")).not_to be_empty
    expect(doc.xpath("//div[@class='title']").text).to eq "Accession Receipt Report"
    expect(doc.xpath("//dl/dt[2]").text).to eq "Title"
    expect(doc.xpath("//dl/dd[2]").text).to eq accession.title
  end
end
