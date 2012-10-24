require 'spec_helper'

describe 'Deaccessions model' do


  it "Supports creating a new rights statement" do
    deaccession = Deaccession.create_from_json(JSONModel(:deaccession).
                                  from_hash({
                                              "whole_part" => false,
                                              "description" => "A description of this deaccession",
                                              "dates" => [{
                                                  "date_type" => "single",
                                                  "label" => "creation",
                                                  "begin" => "2012-05-14",
                                              }],
                                            }))

    Deaccession[deaccession[:id]].description.should eq("A description of this deaccession")
    Deaccession[deaccession[:id]].whole_part.should eq(0)
    Deaccession[deaccession[:id]].notification.should eq(0)
    Deaccession[deaccession[:id]].date.length.should eq(1)
    Deaccession[deaccession[:id]].date[0].begin.should eq("2012-05-14")
  end

end
