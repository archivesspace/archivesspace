require 'spec_helper'
require_relative 'factories'

describe 'Managed Container Profile model' do

  it "can be created from a JSON module" do
    cp = ContainerProfile.create_from_json(build(:json_container_profile, :name => "Big black bag"))

    ContainerProfile[cp[:id]].name.should eq("Big black bag")
  end


  it "enforces name uniqueness" do
      create(:json_container_profile, :name => "1234")

      expect {
        create(:json_container_profile, :name => "1234")
      }.to raise_error(JSONModel::ValidationException)
  end


  it "can delete a container profile that has been linked to records" do
    container_profile = create(:json_container_profile)
    box = create(:json_top_container,
                 :container_profile => {'ref' => container_profile.uri})

    ContainerProfile[container_profile.id].delete

    TopContainer.to_jsonmodel(box.id)['container_profile'].should be_nil
  end


  it "requires depth to be a number with no more than 2 decimal places" do
    expect {
      create(:json_container_profile, :depth => "123abc", :width => "10", :height => "10")
    }.to raise_error(JSONModel::ValidationException)
  end


  it "requires width to be a number with no more than 2 decimal places" do
    expect {
      create(:json_container_profile, :depth => "10", :width => "123.001", :height => "10")
    }.to raise_error(JSONModel::ValidationException)
  end


  it "requires height to be a number with no more than 2 decimal places" do
    expect {
      create(:json_container_profile, :depth => "10", :width => "10", :height => "-10")
    }.to raise_error(JSONModel::ValidationException)
  end


  it "has a very informative display string" do
    jcp = create(:json_container_profile, :name => "Manuscript",
                :depth => "8",
                :height => "13",
                :width => "5.5",
                :dimension_units => "inches",
                :extent_dimension => "width")

    cp = ContainerProfile[jcp.id]

    cp.display_string.should eq("Manuscript [8d, 13h, 5.5w inches] extent measured by width")
  end

end
