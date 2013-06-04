require 'spec_helper'
require_relative '../app/model/ASModel'
require_relative '../app/model/mixins/external_ids'


describe 'External ID mixin' do

  before(:each) do
    $testdb.create_table :test_record do
      primary_key :id
      String :name
      Integer :lock_version, :default => 0
      DateTime :create_time
      DateTime :system_mtime
      DateTime :user_mtime
      String :created_by
      String :last_modified_by
    end


    $testdb.create_table :test_record_ext_id do
      primary_key :id
      Integer :test_record_id, :null => false
      String :external_id, :null => false
      String :source, :null => false
    end


    JSONModel.stub(:schema_src).with('test_record').and_return('{
      :schema => {
        "$schema" => "http://www.archivesspace.org/archivesspace.json",
        "type" => "object",
        "uri" => "/test_record",
        "properties" => {
          "uri" => {"type" => "string", "required" => false},
          "external_ids" => {
            "type" => "array",
            "items" => {
              "type" => "object",
              "properties" => {
                "external_id" => {"type" => "string"},
                "source" => {"type" => "string"},
              }
            }
          }
        },
      },
    }')


    class TestRecord < Sequel::Model(:test_record)
      include ASModel
      include ExternalIDs

      set_model_scope :global
      corresponds_to JSONModel(:test_record)
    end
  end


  after(:each) do
    $testdb.drop_table(:test_record)
    $testdb.drop_table(:test_record_ext_id)
  end


  it "stores external IDs and gives them back" do
    obj = JSONModel(:test_record).
      from_hash('external_ids' => [{
                                     'source' => 'MyILMS',
                                     'external_id' => '40440444'
                                   }])

    record = TestRecord.create_from_json(obj)

    TestRecord.to_jsonmodel(record).external_ids.first['external_id'].should eq('40440444')
  end


  it "deletes external IDs when the referenced object is deleted" do
    obj = JSONModel(:test_record).
      from_hash('external_ids' => [{
                                     'source' => 'MyILMS',
                                     'external_id' => '40440444'
                                   }])

    record = TestRecord.create_from_json(obj)

    record.external_id.count.should eq(1)
    external_id = record.external_id.first

    record.delete

    # Gone now, so raises an error on reload.
    expect { external_id.reload }.to raise_error

  end
end
