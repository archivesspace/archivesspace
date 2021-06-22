require 'spec_helper'

class ArkQueryResponseMock
  @type         = nil
  @id           = nil
  @repo_id      = nil
  @external_url = nil

  def initialize(type, id = nil, repo_id = nil, external_url = nil)
    @type         = type
    @id           = id
    @repo_id      = repo_id
    @external_url = external_url
  end

  def body
    return {:id => @id, :type => @type, :repo_id => @repo_id, :external_url => @external_url}.to_json
  end
end

describe ArkNameController, type: :controller do
  it "should redirect to the correct URL for a resource" do
    HTTP.stub(:get_response) { ArkQueryResponseMock.new("Resource", "4", "5") }

    response = get :show, params: {:id => "1", :naan => "f00001", :ark_tag => "ark:"}

    expect(response.location).to match(/\/repositories\/5\/resources\/4/)
  end

  it "should redirect to the correct URL for an archival object" do
    HTTP.stub(:get_response) { ArkQueryResponseMock.new("ArchivalObject", "4", "5") }

    response = get :show, params: {:id => "1", :naan => "f00001", :ark_tag => "ark:"}

    expect(response.location).to match(/\/repositories\/5\/archival_objects\/4/)
  end

  it "should redirect external ark URL" do
    HTTP.stub(:get_response) { ArkQueryResponseMock.new("external", "4", "5", "http://google.com") }

    response = get :show, params: {:id => "1", :naan => "f00001", :ark_tag => "ark:"}

    expect(response.location).to eq("http://google.com")
  end

  it "should render to not found when not found" do
    HTTP.stub(:get_response) { ArkQueryResponseMock.new("not_found") }

    response = get :show, params: {:id => "1", :naan => "f00001", :ark_tag => "ark:"}

    expect(response).to render_template('shared/not_found')
  end
end
