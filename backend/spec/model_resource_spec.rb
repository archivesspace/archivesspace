require 'spec_helper'

describe 'Resource model' do

  before(:each) do
    make_test_repo
  end


  def create_resource
    Resource.create_from_json(JSONModel(:resource).
                              from_hash({
                                          "title" => "A new resource",
                                          "id_0" => "abc123",
                                          "extents" => [
                                            {
                                              "portion" => "whole",
                                              "number" => "5 or so",
                                              "extent_type" => "reels",
                                            }
                                          ]
                                        }),
                              :repo_id => @repo_id)
  end


  it "Allows resources to be created" do
    resource = create_resource

    Resource[resource[:id]].title.should eq("A new resource")
  end


  it "Prevents duplicate IDs " do
    create_resource

    expect { create_resource }.to raise_error
  end


  it "Allows resources to be created with a date" do
    resource = Resource.create_from_json(JSONModel(:resource).
                                           from_hash({
                                                       "title" => "A new resource",
                                                       "id_0" => "abc123",
                                                       "extents" => [
                                                         {
                                                           "portion" => "whole",
                                                           "number" => "5 or so",
                                                           "extent_type" => "reels",
                                                         }
                                                       ],
                                                       "dates" => [
                                                         {
                                                           "date_type" => "single",
                                                           "label" => "creation",
                                                           "begin" => "2012-05-14",
                                                           "end" => "2012-05-14",
                                                         }
                                                       ]
                                                     }),
                                         :repo_id => @repo_id)

    Resource[resource[:id]].date.length.should eq(1)
    Resource[resource[:id]].date[0].begin.should eq("2012-05-14")
  end


  it "Throws an exception if extents is nil" do
    expect {
      resource = Resource.create_from_json(JSONModel(:resource).
                                             from_hash({
                                                         "title" => "A new resource",
                                                         "id_0" => "abc123",
                                                       }),
                                           :repo_id => @repo_id)
    }.to raise_error
  end


  it "Throws an exception if extents is empty" do
    expect {
      resource = Resource.create_from_json(JSONModel(:resource).
                                             from_hash({
                                                         "title" => "A new resource",
                                                         "id_0" => "abc123",
                                                         "extents" => []
                                                       }),
                                           :repo_id => @repo_id)
    }.to raise_error
  end


  it "blows up if you don't specify which repository you're querying" do
    resource = create_resource

    expect {
      Resource.to_jsonmodel(resource[:id], :resource, nil)
    }.to raise_error

    expect {
      Resource.to_jsonmodel(resource[:id], :resource, :none)
    }.to raise_error
  end


  it "can be created with an instance" do
    resource = Resource.create_from_json(JSONModel(:resource).
                                           from_hash({
                                                       "title" => "A new resource",
                                                       "id_0" => "abc123",
                                                       "extents" => [
                                                         {
                                                           "portion" => "whole",
                                                           "number" => "5 or so",
                                                           "extent_type" => "reels",
                                                         }
                                                       ],
                                                       "instances" => [
                                                         {
                                                           "instance_type" => "text",
                                                           "container" => {
                                                             "type_1" => "A Container",
                                                             "indicator_1" => "555-1-2",
                                                             "barcode_1" => "00011010010011",
                                                           }
                                                         }
                                                       ]
                                                     }),
                                         :repo_id => @repo_id)

    Resource[resource[:id]].instance.length.should eq(1)
    Resource[resource[:id]].instance[0].instance_type.should eq("text")
    Resource[resource[:id]].instance[0].container.first.type_1.should eq("A Container")
  end

end
