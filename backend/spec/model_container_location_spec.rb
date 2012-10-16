require 'spec_helper'

describe 'Container Location' do

  before(:each) do
    make_test_repo
  end

  def create_container
    Container.create_from_json(JSONModel(:container).
                                 from_hash({
                                             "type_1" => "A Container",
                                             "indicator_1" => "555-1-2",
                                             "barcode_1" => "00011010010011",
                                           }))
  end

  def create_location
    Location.create_from_json(JSONModel(:location).
                                 from_hash({
                                             "building" => "129 West 81st Street",
                                             "floor" => "5",
                                             "room" => "5A",
                                             "barcode" => "010101100011",
                                           }),
                                          :repo_id => @repo_id)
  end

  it "can be created" do
    container_location = ContainerLocation.create_from_json(JSONModel(:container_location).
                                             from_hash({
                                                         "status" => "current",
                                                         "start_date" => "2012-01-02",
                                                       }))

    ContainerLocation[container_location[:id]].status.should eq("current")
    ContainerLocation[container_location[:id]].start_date.should eq("2012-01-02")
  end

  it "can be created with a location" do
    location = create_location
@@moo = true
    container_location = ContainerLocation.create_from_json(JSONModel(:container_location).
                                                              from_hash({
                                                                          "status" => "current",
                                                                          "start_date" => "2012-01-02",
                                                                          "location" => JSONModel(:location).uri_for(location[:id])
                                                                        }))
@@moo = false
    ContainerLocation[container_location[:id]].status.should eq("current")
    ContainerLocation[container_location[:id]].start_date.should eq("2012-01-02")
  end

end