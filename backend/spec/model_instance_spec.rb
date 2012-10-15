require 'spec_helper'

describe 'Instance model' do


  it "Allows an instance to be created" do

    instance = Instance.create_from_json(JSONModel(:instance).
                                                       from_hash({
                                                                   "instance_type" => "text",
                                                                   "container" => {
                                                                     "type_1" => "A Container",
                                                                     "indicator_1" => "555-1-2",
                                                                     "barcode_1" => "00011010010011",
                                                                   }
                                                                 }))

    Instance[instance[:id]].instance_type.should eq("text")
    Instance[instance[:id]].container.first.type_1.should eq("A Container")
  end


end
