require 'spec_helper'

describe 'Digital Object Component controller' do

  before(:each) do
    make_test_repo
  end


  def create_digital_object_component(opts = {})

    doc = JSONModel(:digital_object_component).from_hash("component_id" => "abc123",
                                                         "extents" => [{"portion" => "whole",
                                                                         "number" => "5 or so",
                                                                         "extent_type" => "reels"}],
                                                         "title" => "The digital object component title")
    doc.update(opts)
    doc.save
  end



  it "lets you create an digital object component and get it back" do
    created = create_digital_object_component
    JSONModel(:digital_object_component).find(created).title.should eq("The digital object component title")
  end

  it "lets you list all digital object components" do
    id = create_digital_object_component
    JSONModel(:digital_object_component).all.count.should eq(1)
  end


  it "lets you create an digital object component with a parent" do
    digital_object = JSONModel(:digital_object).from_hash("title" => "a resource",
                                                          "digital_object_id" => "abc123",
                                                          "extents" => [{"portion" => "whole",
                                                                          "number" => "5 or so",
                                                                          "extent_type" => "reels"}])
    digital_object.save

    created = create_digital_object_component("digital_object" => digital_object.uri,
                                              "component_id" => "parent123",
                                              "extents" => [{"portion" => "whole",
                                                              "number" => "5 or so",
                                                              "extent_type" => "reels"}])

    create_digital_object_component("component_id" => "child123",
                                    "digital_object" => digital_object.uri,
                                    "title" => "child digital object component",
                                    "parent" => "#{@repo}/digital_object_components/#{created}")

    get "#{@repo}/digital_object_components/#{created}/children"

    children = JSON(last_response.body)
    children[0]["title"].should eq("child digital object component")
  end


  it "handles updates for an existing digital object component" do
    created = create_digital_object_component

    doc = JSONModel(:digital_object_component).find(created)
    doc.title = "A brand new title"
    doc.save

    JSONModel(:digital_object_component).find(created).title.should eq("A brand new title")
  end

end
