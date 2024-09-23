require 'spec_helper'
require_relative 'factories'

describe 'Location Profile model' do
  it 'creates a location profile with various decimal formats for width, height, depth' do
    uuid = SecureRandom.uuid

    location_profile = LocationProfile.create_from_json(
      build(:json_location_profile,
        :name => "Location Profile Name #{uuid}",
        :width => '.2',
        :height => '0.2',
        :depth => '.11'
      )
    )

    expect(location_profile[:name]).to eq "Location Profile Name #{uuid}"
    expect(location_profile[:width]).to eq '.2'
    expect(location_profile[:height]).to eq '0.2'
    expect(location_profile[:depth]).to eq '.11'
  end

  it "can be created from a JSON module" do
    cp = LocationProfile.create_from_json(build(:json_location_profile, :name => "Large shelf"))

    expect(LocationProfile[cp[:id]].name).to eq("Large shelf")
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

    expect(Location.to_jsonmodel(location.id)['location_profile']['ref']).to eq(location_profile.uri)
  end


  it "can delete a Location Profile that has been linked to records" do
    location_profile = create(:json_location_profile)
    location = create(:json_location,
                 :location_profile => {'ref' => location_profile.uri})

    LocationProfile[location_profile.id].delete

    expect(Location.to_jsonmodel(location.id)['location_profile']).to be_nil
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

    expect(lp.display_string).to eq("Large shelf [8d, 13h, 5.5w Inches]")
  end

end
