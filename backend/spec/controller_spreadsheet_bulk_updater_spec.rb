require 'spec_helper'

describe 'Spreadsheet Bulk Updater controller' do
  let!(:resource) {
    create(:json_resource, :publish => true)
  }

  let(:archival_object) do
    create(:json_archival_object, :resource => {:ref => resource.uri}, :publish => true, :title => "Series 1")
  end

  let!(:series_1) {
    create(:json_archival_object, :resource => {:ref => resource.uri}, :publish => true, :title => "Series 1")
  }

  let!(:series_2) {
    create(:json_archival_object, :resource => {:ref => resource.uri}, :publish => true, :title => "Series 2")

  }

  let!(:series_1_child_1) {
    create(:json_archival_object,
           :resource => {:ref => resource.uri},
           :parent => {:ref => series_1.uri},
           :publish => true,
           :title => "Series 1 Child 1")
  }

  let!(:series_1_child_2) {
    create(:json_archival_object,
           :resource => {:ref => resource.uri},
           :parent => {:ref => series_1.uri},
           :publish => true,
           :title => "Series 1 Child 2")
  }

  let!(:series_2_child_1) {
    create(:json_archival_object,
           :resource => {:ref => resource.uri},
           :parent => {:ref => series_2.uri},
           :publish => true,
           :title => "Series 2 Child 1")
  }

  let!(:series_2_child_2) {
    create(:json_archival_object,
           :resource => {:ref => resource.uri},
           :parent => {:ref => series_2.uri},
           :publish => true,
           :title => "Series 2 Child 2")
  }

  it "Returns an XLSX" do
    url = URI("#{JSONModel::HTTP.backend_url}/spreadsheet_bulk_updater/#{resource.repository['ref']}/generate_spreadsheet")
    response = JSONModel::HTTP.post_json(url, {"uri": ["#{archival_object.uri}"], "resource_uri": "#{resource.uri}"})

    expect(response.headers["Content-Type"]).to eq("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
    expect(response.headers["Content-Disposition"]).to eq("attachment; filename=\"bulk_update.resource_#{resource.id}.#{Date.today.iso8601}.xlsx\"")
  end

  it "Generates the small tree for a resource" do
    url = URI("#{JSONModel::HTTP.backend_url}/spreadsheet_bulk_updater#{resource.uri}/small_tree")
    request = Net::HTTP::Get.new(url.request_uri)
    response = JSONModel::HTTP.do_http_request(url, request)

    json_response = ASUtils.json_parse(response.body)
    expect(json_response["children"].map {|c| c["has_children"]}.count).to eq(Resource[resource.id].children.count)
  end
end
