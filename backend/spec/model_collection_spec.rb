require 'spec_helper'

describe 'Collection model' do

   before(:each) do
     @repo = Repository.create(:repo_code => "TESTREPO",
                               :description => "My new test repository").id
   end

   def create_collection
      Collection.create_from_json(JSONModel(:collection).
                                                from_hash({
                                                            "title" => "A new collection",
                                                            "id_0" => "abc123"
                                                          }),
                                            :repo_id => @repo)
   end


  it "Allows collections to be created" do
    collection = create_collection

    Collection[collection[:id]].title.should eq("A new collection")
  end


  it "Prevents duplicate IDs " do
      create_collection

      expect { create_collection }.to raise_error
  end
end
