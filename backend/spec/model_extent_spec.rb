require 'spec_helper'

describe 'Extent model' do


  it "Allows an extent to be created" do

    extent = Extent.create_from_json(JSONModel(:extent).
                                 from_hash({
                                             "portion" => "whole",
                                             "number" => "5 or so",
                                             "extent_type" => "reels",
                                           }))

    Extent[extent[:id]].portion.should eq("whole")
    Extent[extent[:id]].number.should eq("5 or so")
    Extent[extent[:id]].extent_type.should eq("reels")
  end


end
