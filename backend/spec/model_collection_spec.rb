require 'spec_helper'

describe 'Collection model' do

  it "Allows collections to be created" do
    repo = Repository.create(:repo_id => "TESTREPO",
                             :description => "My new test repository")

    collection = repo.create_collection(JSONModel(:collection).
                                        from_hash({ "title" => "A new collection" }))

    Collection[collection].title.should eq("A new collection")
  end

end
