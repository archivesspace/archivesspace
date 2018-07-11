require 'spec_helper'
require_relative '../app/lib/rest'

describe 'Rest Helpers' do

  before(:all) do
    RESTHelpers::Endpoint.get('/rest_helper_spec/get')
      .description("GET endpoint test")
      .permissions([])
      .returns([200, "(json)"]) \
    do
      json_response(:method => env["REQUEST_METHOD"])
    end

    RESTHelpers::Endpoint.post('/rest_helper_spec/post')
      .description("POST endpoint test")
      .permissions([])
      .returns([200, "(json)"]) \
    do
      json_response(:method => env["REQUEST_METHOD"])
    end

    RESTHelpers::Endpoint.get_or_post('/rest_helper_spec/get_or_post')
      .description("GET or POST endpoint test")
      .permissions([])
      .returns([200, "(json)"]) \
    do
      json_response(:method => env["REQUEST_METHOD"])
    end
  end

  it "can define a GET" do
    get '/rest_helper_spec/get'
    json = ASUtils.json_parse(last_response.body)
    json['method'].should eq('GET')
  end

  it "can define a POST" do
    post '/rest_helper_spec/post'
    json = ASUtils.json_parse(last_response.body)
    json['method'].should eq('POST')
  end

  it "can define both a GET and a POST" do
    get '/rest_helper_spec/get_or_post'
    json = ASUtils.json_parse(last_response.body)
    json['method'].should eq('GET')

    post '/rest_helper_spec/get_or_post'
    json = ASUtils.json_parse(last_response.body)
    json['method'].should eq('POST')
  end

end
