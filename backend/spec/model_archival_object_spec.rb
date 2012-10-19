require 'spec_helper'

describe 'ArchivalObject model' do

  before(:each) do
    make_test_repo
  end


  def create_archival_object
    ArchivalObject.create_from_json(JSONModel(:archival_object).
                                    from_hash({ "ref_id" => "abcd",
                                                "title" => "A new archival object"}),
                                    :repo_id => @repo_id)
  end


  it "Allows archival objects to be created" do
    ao = create_archival_object

    ArchivalObject[ao[:id]].title.should eq("A new archival object")
  end


  it "Allows archival objects to be created with an extent" do
    ao = ArchivalObject.create_from_json(JSONModel(:archival_object).
                                    from_hash({ 
                                                "ref_id" => "abcd",
                                                "title" => "A new archival object",
                                                "extents" => [{
                                                  "portion" => "whole",
                                                  "number" => "5 or so",
                                                  "extent_type" => "reels",
                                                }]
                                              }),
                                    :repo_id => @repo_id)
    ArchivalObject[ao[:id]].extents.length.should eq(1)
    ArchivalObject[ao[:id]].extents[0].extent_type.should eq("reels")
  end


  it "Allows archival objects to be created with a date" do
    ao = ArchivalObject.create_from_json(JSONModel(:archival_object).
                              from_hash({
                                          "ref_id" => "abcd",
                                          "title" => "A new archival object",
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

    ArchivalObject[ao[:id]].dates.length.should eq(1)
    ArchivalObject[ao[:id]].dates[0].begin.should eq("2012-05-14")
  end


  it "can be created with an instance" do
    ao = ArchivalObject.create_from_json(JSONModel(:archival_object).
                                           from_hash({
                                                       "ref_id" => "abcd",
                                                       "title" => "A new archival object",
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

    ArchivalObject[ao[:id]].instances.length.should eq(1)
    ArchivalObject[ao[:id]].instances[0].instance_type.should eq("text")
    ArchivalObject[ao[:id]].instances[0].container.first.type_1.should eq("A Container")
  end

end
