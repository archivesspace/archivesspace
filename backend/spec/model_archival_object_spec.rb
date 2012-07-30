require 'spec_helper'

describe 'ArchivalObject model' do

  it "Allows archival objects to be created" do
    repo = Repository.create(:repo_id => "TESTREPO",
                             :description => "My new test repository")

    ao = repo.create_archival_object(JSONModel(:archival_object).
                                     from_hash({ "id_0" => "abcd",
                                                 "title" => "A new archival object" }))

    ArchivalObject[ao].title.should eq("A new archival object")
  end

end
