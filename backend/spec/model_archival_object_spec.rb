require 'spec_helper'

describe 'ArchivalObject model' do

  before(:each) do
    @repo = Repository.create(:repo_code => "TESTREPO",
                              :description => "My new test repository").id
  end


  def create_archival_object
    ArchivalObject.create_from_json(JSONModel(:archival_object).
                                    from_hash({ "id_0" => "abcd",
                                                "title" => "A new archival object"}),
                                    :repo_id => @repo)
  end


  it "Allows archival objects to be created" do
    ao = create_archival_object

    ArchivalObject[ao[:id]].title.should eq("A new archival object")
  end


  it "Prevents duplicate IDs " do
    ao = create_archival_object

    expect { create_archival_object }.to raise_error
  end


end
