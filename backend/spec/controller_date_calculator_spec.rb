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
    response.code.should eq("200")

    report = ASUtils.json_parse(response.body)

    report.keys.should include('object')
    report.keys.should include('resource')
    report.keys.should include('label')
    report.keys.should include('min_begin')
    report.keys.should include('min_begin_date')
    report.keys.should include('max_end')
    report.keys.should include('max_end_date')

    report.fetch('object').fetch('uri').should eq(resource.uri)
    report.fetch('object').fetch('id').should eq(resource.id)
    report.fetch('object').fetch('jsonmodel_type').should eq('resource')
  end

  it "throws an error when user cannot access the repository" do
    create(:user, {:username => 'noaccess'})
    resource = create_resource

    as_anonymous_user do
      perform_calculate(resource.uri).code.should eq("403")
    end

    as_test_user('noaccess') do 
      perform_calculate(resource.uri).code.should eq("403")
    end
  end

end
