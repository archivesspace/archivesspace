require 'spec_helper'

describe "Container Management Conversion" do

  it "can run" do
     ContainerManagementConversion.new.run
  end

  it "will delete instances that have no containers or DOs" do
    digital_object =  create(:json_digital_object)
    archival_object = create(:json_archival_object,
                             :instances => [{"instance_type" => "digital_object",
                                              "digital_object" => {"ref" => digital_object.uri},
                                              "container" => nil
                                            },
                                            { "instance_type" => "mixed_materials",
                                               "container" => build(:json_container, {:container_extent => "1.0",
                                                  :container_extent_type => "cassettes"
                                                 })
                                             }
                                            ]) 
    
    json = ArchivalObject.to_jsonmodel(archival_object.id)
    json["instances"].length.should eq(2)
    
    json["instances"].last["container"] = nil # we fudge this a bit 
    json["instances"].last["sub_container"] = nil # we fudge this a bit 
    
    ContainerManagementConversion::MigrationMapper.new(json, false, {}).call
    ArchivalObject.to_jsonmodel(archival_object.id)["instances"].length.should eq(1)

  end


end
