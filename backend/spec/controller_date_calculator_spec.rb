require 'spec_helper'

describe 'Date Calculator controller' do

  def perform_calculate(uri, level = nil)
    url = URI("#{JSONModel::HTTP.backend_url}/date_calculator")
    request = Net::HTTP::Get.new(url.request_uri)
    request.set_form_data({"record_uri" => uri, "level" => level})

    response = JSONModel::HTTP.do_http_request(url, request)

    response
  end

  it "returns a report" do
    resource = create_resource

    response = perform_calculate(resource.uri)
    expect(response.code).to eq("200")

    report = ASUtils.json_parse(response.body)

    expect(report.keys).to include('object')
    expect(report.keys).to include('resource')
    expect(report.keys).to include('label')
    expect(report.keys).to include('min_begin')
    expect(report.keys).to include('min_begin_date')
    expect(report.keys).to include('max_end')
    expect(report.keys).to include('max_end_date')

    expect(report.fetch('object').fetch('uri')).to eq(resource.uri)
    expect(report.fetch('object').fetch('id')).to eq(resource.id)
    expect(report.fetch('object').fetch('jsonmodel_type')).to eq('resource')
  end

  it "throws an error when user cannot access the repository" do
    create(:user, {:username => 'noaccess'})
    resource = create_resource

    as_anonymous_user do
      expect(perform_calculate(resource.uri).code).to eq("403")
    end

    as_test_user('noaccess') do
      expect(perform_calculate(resource.uri).code).to eq("403")
    end
  end

end
