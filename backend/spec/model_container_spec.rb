require 'spec_helper'

describe 'Container model' do


  it "Allows a container to be created" do

    container = Container.create_from_json(JSONModel(:container).
                                             from_hash({
                                                         "type_1" => "A Container",
                                                         "indicator_1" => "555-1-2",
                                                         "barcode_1" => "00011010010011",
                                                       }))

    Container[container[:id]].type_1.should eq("A Container")
    Container[container[:id]].indicator_1.should eq("555-1-2")
    Container[container[:id]].barcode_1.should eq("00011010010011")
  end


end