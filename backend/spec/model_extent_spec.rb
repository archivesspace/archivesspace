require 'spec_helper'

describe 'Extent model' do


  it "Allows an extent to be created" do

    extent = Extent.create_from_json(JSONModel(:extent).
                                 from_hash({
                                             "portion" => "whole",
                                             "number" => "5 or so",
                                             "extent_type" => "reels",
                                           }))

    expect(Extent[extent[:id]].portion).to eq("whole")
    expect(Extent[extent[:id]].number).to eq("5 or so")
    expect(Extent[extent[:id]].extent_type).to eq("reels")
  end


end
