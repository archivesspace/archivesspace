require 'spec_helper'

describe "Batch Import Controller" do

  before(:each) do
    create(:repo)
  end

  it "can import a batch of JSON objects" do
    
    batch_array = []

    types = [:json_resource, :json_archival_object]
    10.times do
      obj = build(types.sample)
      obj.uri = obj.class.uri_for(rand(100000), {:repo_id => $repo_id})
      batch_array << obj.to_hash(true)
    end
    
    batch = JSONModel(:batch_import).new
    batch.set_data({:batch => batch_array})
        
    uri = "/repositories/#{$repo_id}/batch_imports"
    url = URI("#{JSONModel::HTTP.backend_url}#{uri}")

    response = JSONModel::HTTP.post_json(url, batch.to_json)
    
    response.code.should eq('200')
    
    body = JSON.parse(response.body, :max_nesting => false)
    body['saved'].length.should eq(10)
    
  end
end
