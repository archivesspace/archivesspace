require 'spec_helper'

describe 'Collection model' do

  it "Allows collections to be created" do
    repo = Repository.create(:repo_id => "TESTREPO",
                             :description => "My new test repository")

    collection = Collection.create_from_json(JSONModel(:collection).
                                             from_hash({
                                                         "title" => "A new collection",
                                                         "repository" => "/repositories/#{repo[:id]}"
                                                       }))

    Collection[collection[:id]].title.should eq("A new collection")
  end

end
