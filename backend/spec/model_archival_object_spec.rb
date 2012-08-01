require 'spec_helper'

describe 'ArchivalObject model' do

  it "Allows archival objects to be created" do
    repo = Repository.create(:repo_id => "TESTREPO",
                             :description => "My new test repository")

    ao = ArchivalObject.create_from_json(JSONModel(:archival_object).
                                         from_hash({ "id_0" => "abcd",
                                                     "title" => "A new archival object",
                                                     "repository" => "/repositories/#{repo[:id]}"}))

    ArchivalObject[ao[:id]].title.should eq("A new archival object")
  end

end
