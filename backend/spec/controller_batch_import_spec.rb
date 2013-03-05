require 'spec_helper'

describe "Batch Import Controller" do

  before(:each) do
    create(:repo)
    
    @batch_cls = Class.new(JSONModel::JSONModel(:batch_import)) do

      # Need to bypass some validation rules for 
      # JSON objects created by an import
      def self.validate(hash)
        begin
          super(hash)
        rescue JSONModel::ValidationException => e

          e.errors.reject! {|path, mssg| 
                            e.attribute_types.has_key?(path) && 
                            e.attribute_types[path] == 'ArchivesSpaceDynamicEnum'}

          raise e unless e.errors.empty?

        end
      end
    end

    
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
    
    body = ASUtils.json_parse(response.body)
    body['saved'].length.should eq(10)
    
  end
  
  
  it "can import a batch of JSON objects with unknown enum values" do
    
    # Set the enum source to the backend version     
    old_enum_source = JSONModel.init_args[:enum_source]
    JSONModel.init_args[:enum_source] = BackendEnumSource
    
            
    batch_array = []

    enum = JSONModel::JSONModel(:enumeration).all.find {|obj| obj.name == 'resource_resource_type' }

    enum.values.should_not include('spaghetti')

    obj = build(:json_resource, :resource_type => 'spaghetti')
    obj.uri = obj.class.uri_for(rand(100000), {:repo_id => $repo_id})

    batch_array << obj.to_hash(true)
    
    batch = @batch_cls.new
    batch.set_data({:batch => batch_array})
        
    uri = "/repositories/#{$repo_id}/batch_imports"
    url = URI("#{JSONModel::HTTP.backend_url}#{uri}")

    response = JSONModel::HTTP.post_json(url, batch.to_json)
    
    response.code.should eq('200')
    
    body = ASUtils.json_parse(response.body)
    body['saved'].length.should eq(1)
    
    enum = JSONModel::JSONModel(:enumeration).all.find {|obj| obj.name == 'resource_resource_type' }
    
    enum.values.should include('spaghetti')
    
    # set things back as they were enum source-wise
    JSONModel.init_args[:enum_source] = old_enum_source
    
  end
  
end
