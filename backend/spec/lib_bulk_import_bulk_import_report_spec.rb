require "spec_helper"
require_relative "../app/lib/bulk_import/bulk_import_report.rb"

describe BulkImportReport do
  def row_match(row, number)
    row == "Row #{number}"
  end

  it "creates an informational one-line report " do
    report = BulkImportReport.new
    report.new_row(1)
    report.add_info("This is a one line report")
    report.end_row
    expect(row_match(report.rows[0].row, 1)).to be(true)
    expect(report.row_count).to eq(1)
    expect(report.rows[0].info[0]).to eq("This is a one line report")
  end
  it "creates an one-line error report " do
    report = BulkImportReport.new
    report.new_row(1)
    report.add_errors("This is a one line error report")
    report.end_row
    expect(report.row_count).to eq(1)
    expect(row_match(report.rows[0].row, 1)).to be(true)
    expect(report.rows[0].errors[0]).to eq("This is a one line error report")
  end
  it "created 2 rows; the first with info AND errors, the second with 2 infos only" do
    report = BulkImportReport.new
    report.new_row(1)
    report.add_info("This is an info line")
    errors = ["I have 2 errors", "here's the second error"]
    report.add_errors(errors)
    report.add_errors("Yet Another Error")
    report.end_row
    report.new_row(2)
    report.add_info("first info line")
    report.add_info("second info line")
    report.end_row
    expect(report.row_count).to eq(2)
    [1, 2].each { |intg|
      expect(row_match(report.rows[intg - 1].row, intg)).to be(true)
    }
    row = report.rows[0]
    expect(row.info[0]).to eq("This is an info line")
    expect(row.errors.length).to eq(3)
    expect(row.errors.join(" ")).to eq("I have 2 errors here's the second error Yet Another Error")
    row = report.rows[1]
    expect(row.errors).to eq([])
    expect(row.info.length).to eq(2)
    expect(row.info[1]).to eq("second info line")
  end
  it "identifies an archival object" do
    resource = create(:json_resource)
    resource.save
    ao = create(:json_archival_object, { :title => "archival object: Hi There" })
    ao.resource = { :ref => resource.uri }
    ao.save
    report = BulkImportReport.new
    report.new_row(1)
    report.add_info("This is info for an archival object")
    report.add_archival_object(ao)
    report.end_row
    row = report.rows[0]
    expect(row.archival_object_display).to eq("archival object: Hi There")
    expect(row.archival_object_id).to eq(ao.uri)
    expect(row.info[0]).to eq("This is info for an archival object")
  end
end
