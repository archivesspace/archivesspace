require 'spec_helper'

describe "Resource Component Transfer Service" do

  before(:each) do
    
  end
  
  def transfer(resource, object)
    uri = "/repositories/#{$repo_id}/component_transfers"
    url = URI("#{JSONModel::HTTP.backend_url}#{uri}")  
    
    request = Net::HTTP::Post.new(url.request_uri)
    request.set_form_data({"target_resource" => resource.uri, "component" => object.uri})
     
    response = JSONModel::HTTP.do_http_request(url, request)
    
    puts "RESPONSE BODY #{response.body}"
    
    response
  end
    
  
  it "can move an archival object from one resource tree to another" do
    
    resource_alpha = create(:json_resource)
    resource_beta = create(:json_resource)

    object = create(:json_archival_object, :resource => {:ref => resource_alpha.uri})

    puts object.inspect
    
    object.resource['ref'].should eq(resource_alpha.uri)

    response = transfer(resource_beta, object)
    
    puts response.body.inspect
    
    response.code.should eq('200')
    
    refreshed_object = JSONModel(:archival_object).find(object.id)
    
    refreshed_object.resource['ref'].should eq(resource_beta.uri)

  end

  it "returns a 404 response code when asked to transfer a non-existent object" do
    
    fake_uri = JSONModel(:archival_object).uri_for(99*99)

    resource = create(:json_resource)
    
    response = transfer(resource, build(:json_archival_object, :uri => fake_uri))
    
    response.code.should eq('404')
    response.body.should match(/not found/)
  end
  
  it "returns a 409 response code when asked to transfer an object to a resource containing a conflicting object" do
    
    conflicting_ref_id = generate(:alphanumstr)
    
    resource_alpha = create(:json_resource)
    resource_beta = create(:json_resource)
    
    object_alpha = create(:json_archival_object, :resource => {:ref => resource_alpha.uri}, :ref_id => conflicting_ref_id)
    object_beta = create(:json_archival_object, :resource => {:ref => resource_beta.uri}, :ref_id => conflicting_ref_id)
    
    response = transfer(resource_beta, object_alpha)
    
    response.code.should eq('400')
    response.body.should match (/unique to its resource/)
  end

end