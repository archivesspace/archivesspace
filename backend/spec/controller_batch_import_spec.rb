require 'spec_helper'

describe "Batch Import Controller" do

  before(:all) do
    @batch_cls = Class.new(JSONModel::JSONModel(:batch_import)) do

      # Need to bypass some validation rules for 
      # JSON objects created by an import
      def self.validate(hash, raise_errors = true)
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


  before(:each) do
    create(:repo)
  end
  
  it "can import a batch of JSON objects" do
    
    batch_array = []
  
    types = [:json_resource, :json_archival_object]
    10.times do
      obj = build(types.sample)
      obj.uri = obj.class.uri_for(rand(100000), {:repo_id => $repo_id})
      batch_array << obj.to_hash(:raw)
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
  
    batch_array << obj.to_hash(:raw)
    
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
  it "can import a batch containing a record with a reference to already existing records" do
    
    subject = create(:json_subject)
    accession = create(:json_accession)
    
    resource = build(:json_resource, 
            :subjects => [{'ref' => subject.uri}],
            :related_accessions => [{'ref' => accession.uri}])
            
            
            
    resource.uri = resource.class.uri_for(rand(100000), {:repo_id => $repo_id})
    
    batch_array = [resource.to_hash(:raw)]
  
    batch = JSONModel(:batch_import).new
    batch.set_data({:batch => batch_array})
        
    uri = "/repositories/#{$repo_id}/batch_imports"
    url = URI("#{JSONModel::HTTP.backend_url}#{uri}")
  
    response = JSONModel::HTTP.post_json(url, batch.to_json)
    response.code.should eq('200')
    
    body = ASUtils.json_parse(response.body)
    body['saved'].length.should eq(1)
    
    real_id = body['saved'][resource.uri][-1]
    resource_reloaded = JSONModel(:resource).find(real_id, "resolve[]" => ['subjects', 'related_accessions'])
  
    resource_reloaded.subjects[0]['ref'].should eq(subject.uri)
    resource_reloaded.related_accessions[0]['ref'].should eq(accession.uri)
    
  end
  
  it "can import a batch containing a record with an inline (non-schematized) external id object" do
    
    resource = build(:json_resource, :external_ids => [{:external_id => '1', 
                                                        :source => 'jdbc:mysql://tracerdb.cyo37z0ucix8.us-east-1.rds.amazonaws.com/at2::RESOURCE'}])
  
    resource.uri = resource.class.uri_for(rand(100000), {:repo_id => $repo_id})
  
    batch_array = [resource.to_hash(:raw)]
  
    batch = JSONModel(:batch_import).new
    batch.set_data({:batch => batch_array})
        
    uri = "/repositories/#{$repo_id}/batch_imports"
    url = URI("#{JSONModel::HTTP.backend_url}#{uri}")
  
    response = JSONModel::HTTP.post_json(url, batch.to_json)
    response.code.should eq('200')
    
    body = ASUtils.json_parse(response.body)
    body['saved'].length.should eq(1)
  end
  

  
end
