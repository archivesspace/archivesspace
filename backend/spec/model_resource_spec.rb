require 'spec_helper'

describe 'Resource model' do

  before(:each) do
    make_test_repo
  end


  def create_resource
    Resource.create_from_json(JSONModel(:resource).
                              from_hash({
                                          "title" => "A new resource",
                                          "id_0" => "abc123"
                                        }),
                              :repo_id => @repo_id)
  end


  it "Allows resources to be created" do
    resource = create_resource

    Resource[resource[:id]].title.should eq("A new resource")
  end


  it "Prevents duplicate IDs " do
    create_resource

    expect { create_resource }.to raise_error
  end
end
