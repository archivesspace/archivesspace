require 'spec_helper'

describe 'Digital object model' do

  before(:each) do
    make_test_repo
  end


  def create_digital_object
    DigitalObject.create_from_json(JSONModel(:digital_object).
                                   from_hash({
                                               "title" => "A new digital object",
                                               "digital_object_id" => "abc123",
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


  it "Allows digital objects to be created" do
    digital_object = create_digital_object

    DigitalObject[digital_object[:id]].title.should eq("A new digital object")
  end


  it "Prevents duplicate IDs " do
    create_digital_object

    expect { create_digital_object }.to raise_error
  end



end
