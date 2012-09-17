require 'spec_helper'

describe 'ArchivalObject model' do

  before(:each) do
    @repo = Repository.create(:repo_code => "TESTREPO",
                              :description => "My new test repository").id
  end


  def create_archival_object
    ArchivalObject.create_from_json(JSONModel(:archival_object).
                                    from_hash({ "ref_id" => "abcd",
                                                "title" => "A new archival object"}),
                                    :repo_id => @repo)
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
                                    :repo_id => @repo)
    ArchivalObject[ao[:id]].extents.length.should eq(1)
    ArchivalObject[ao[:id]].extents[0].extent_type.should eq("reels")
  end

end
