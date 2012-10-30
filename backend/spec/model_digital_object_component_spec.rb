require 'spec_helper'

describe 'DigitalObjectComponent model' do

  before(:each) do
    create(:repo)
  end


  def create_digital_object_component
    DigitalObjectComponent.create_from_json(JSONModel(:digital_object_component).
                                            from_hash("ref_id" => "abcd",
                                                      "component_id" => "abc321",
                                                      "title" => "A new digital object component"),
                                            :repo_id => $repo_id)
  end


  it "Allows digital object components to be created" do
    doc = create_digital_object_component

    DigitalObjectComponent[doc[:id]].title.should eq("A new digital object component")
  end


end
