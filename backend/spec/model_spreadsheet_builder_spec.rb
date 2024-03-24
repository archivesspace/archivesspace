require 'spec_helper'

describe 'Spreadsheet Builder Model' do
  let(:resource) do
    create(:json_resource, ead_id: "foobar")
  end

  let(:archival_object) do
    create(:json_archival_object, :resource => {:ref => resource.uri}, :publish => true, :title => "Series 1")
  end

  it "creates a spreadsheet" do
    spreadsheet = SpreadsheetBuilder.new(resource.uri, [archival_object.uri], 0, 0, 0, [])
    expect(spreadsheet.build_filename).to eq("bulk_update.resource_#{resource.id}.#{Date.today.iso8601}.xlsx")
    expect(spreadsheet.instance_variable_get(:@resource_id)).to eq(resource.id)
    expect(spreadsheet.machine_readable_headers).to eq(SpreadsheetBuilder::ALWAYS_FIELDS)
  end
end
