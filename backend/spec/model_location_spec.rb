require 'spec_helper'

describe 'Location model' do

  before(:each) do
    make_test_repo
  end

  it "can be created" do
    location = Location.create_from_json(JSONModel(:location).
                                  from_hash({
                                              "building" => "129 West 81st Street",
                                              "floor" => "5",
                                              "room" => "5A",
                                              "barcode" => "010101100011",
                                            }),
                                :repo_id => @repo_id)

    Location[location[:id]].building.should eq("129 West 81st Street")
    Location[location[:id]].barcode.should eq("010101100011")
  end

  it "can be created with coordinate data" do
    location = Location.create_from_json(JSONModel(:location).
                                           from_hash({
                                                       "building" => "129 West 81st Street",
                                                       "floor" => "5",
                                                       "room" => "5A",
                                                       "coordinate_1_label" => "Position XYZ",
                                                       "coordinate_1_indicator" => "A1BB99",
                                                       "coordinate_2_label" => "Position ABC",
                                                       "coordinate_2_indicator" => "Z55",
                                                     }),
                                         :repo_id => @repo_id)

    Location[location[:id]].building.should eq("129 West 81st Street")
    Location[location[:id]].coordinate_1_label.should eq("Position XYZ")
    Location[location[:id]].coordinate_2_indicator.should eq("Z55")
  end

  it "can be created with a classification" do
    location = Location.create_from_json(JSONModel(:location).
                                           from_hash({
                                                       "building" => "129 West 81st Street",
                                                       "floor" => "5",
                                                       "room" => "5A",
                                                       "classification" => "Foo Foo Foo Foo",
                                                     }),
                                         :repo_id => @repo_id)

    Location[location[:id]].building.should eq("129 West 81st Street")
    Location[location[:id]].classification.should eq("Foo Foo Foo Foo")
  end
end
