require 'spec_helper'
require_relative 'factories'

describe 'Location Profile model' do

  it "can be created from a JSON module" do
    cp = LocationProfile.create_from_json(build(:json_location_profile, :name => "Large shelf"))

    LocationProfile[cp[:id]].name.should eq("Large shelf")
  end


  it "enforces name uniqueness" do
      create(:json_location_profile, :name => "1234")

      expect {
        create(:json_location_profile, :name => "1234")
      }.to raise_error(JSONModel::ValidationException)
  end


  it "can link a Location Profile to a Location" do
    location_profile = create(:json_location_profile)
    location = create(:json_location,
                      :location_profile => {'ref' => location_profile.uri})

    Location.to_jsonmodel(location.id)['location_profile']['ref'].should eq(location_profile.uri)
  end


  it "can delete a Location Profile that has been linked to records" do
    location_profile = create(:json_location_profile)
    location = create(:json_location,
                 :location_profile => {'ref' => location_profile.uri})

    LocationProfile[location_profile.id].delete

    Location.to_jsonmodel(location.id)['location_profile'].should be_nil
  end


  it "requires depth to be a number with no more than 2 decimal places" do
    expect {
      create(:json_location_profile, :depth => "123abc", :width => "10", :height => "10")
    }.to raise_error(JSONModel::ValidationException)
  end


  it "requires width to be a number with no more than 2 decimal places" do
    expect {
      create(:json_location_profile, :depth => "10", :width => "123.001", :height => "10")
    }.to raise_error(JSONModel::ValidationException)
  end


  it "requires height to be a number with no more than 2 decimal places" do
    expect {
      create(:json_location_profile, :depth => "10", :width => "10", :height => "-10")
    }.to raise_error(JSONModel::ValidationException)
  end


  it "has a very informative display string" do
    jlp = create(:json_location_profile, :name => "Large shelf",
                :depth => "8",
                :height => "13",
                :width => "5.5",
                :dimension_units => "inches")

    lp = LocationProfile[jlp.id]

    lp.display_string.should eq("Large shelf [8d, 13h, 5.5w Inches]")
  end

end
