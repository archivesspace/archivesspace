require 'spec_helper'
require_relative 'factories'


describe 'Space Calculator model' do

  def create_location_profile(name, depth, height, width, dim_units)
    create(:json_location_profile, :name => name,
           :depth => depth,
           :height => height,
           :width => width,
           :dimension_units => dim_units)
  end


  def create_locations(location_profile, num = 1)
    locations = []
    num.times do |n|
      locations << create(:json_location, 'location_profile' => {'ref' => location_profile.uri})
    end
    locations
  end


  def create_container_profile(name, depth, height, width, dim_units, ext_dim, stacking_limit = nil)
    create(:json_container_profile, :name => name,
           :depth => depth,
           :height => height,
           :width => width,
           :dimension_units => dim_units,
           :extent_dimension => ext_dim,
           :stacking_limit => stacking_limit)
  end


  def create_containers(container_profile, location, num = 1)
    containers = []
    num.times do |n|
      containers << create(:json_top_container,
                           'container_profile' => {'ref' => container_profile.uri},
                           'container_locations' => [{'ref' => location.uri,
                                                      'status' => 'current',
                                                      'start_date' => generate(:yyyy_mm_dd),
                                                      'end_date' => generate(:yyyy_mm_dd)}])
    end
    containers
  end

  def add_container_to_location(container, location)
    container_location = JSONModel(:container_location).from_hash(
      'status' => 'current',
      'start_date' => '2000-01-01',
      'note' => 'test container location',
      'ref' => location.uri
    )
    container.container_locations = container.container_locations + [container_location]
    container.save
  end


  let (:bigbox_profile) { create_container_profile("big box", "18", "12", "15", "inches", "width") }
  let (:a_bigbox) { create(:json_top_container, 'container_profile' => {'ref' => bigbox_profile.uri}) }

  let (:tinybox_profile) { create_container_profile("tiny box", "18", "12", "15", "millimeters", "width") }
  let (:a_tinybox) { create(:json_top_container, 'container_profile' => {'ref' => tinybox_profile.uri}) }

  let (:unstackablebox_profile) { create_container_profile("unstackable box", "18", "12", "15", "inches", "width", "1") }
  let (:an_unstackablebox) { create(:json_top_container, 'container_profile' => {'ref' => tinybox_profile.uri}) }

  let (:a_box_without_a_profile) { create(:json_top_container, 'container_profile' => nil) }

  let (:bigshelf_profile) { create_location_profile("big shelf", "24", "36", "108", "inches") }
  let (:a_bigshelf) { Location.create_from_json(create(:json_location, 'location_profile' => {'ref' => bigshelf_profile.uri})) }
  let (:another_bigshelf) { Location.create_from_json(create(:json_location, 'location_profile' => {'ref' => bigshelf_profile.uri})) }

  let (:smallshelf_profile) { create_location_profile("small shelf", "30", "30", "120", "centimeters") }
  let (:a_smallshelf) { Location.create_from_json(create(:json_location, 'location_profile' => {'ref' => smallshelf_profile.uri})) }

  let (:a_profilelessshelf) { Location.create_from_json(create(:json_location, 'location_profile' => nil)) }

  let (:uncertainshelf_profile) { create_location_profile("uncertain shelf", "30", "30", nil, "yards") }
  let (:an_uncertainshelf) { Location.create_from_json(create(:json_location, 'location_profile' => {'ref' => uncertainshelf_profile.uri})) }

  let (:nounitshelf_profile) { create_location_profile("no unit shelf", "18", "12", "15", nil) }
  let (:a_nounitshelf) { Location.create_from_json(create(:json_location, 'location_profile' => {'ref' => nounitshelf_profile.uri})) }


  it "tells you how many boxes will fit on a shelf" do
    space_calculator = SpaceCalculator.new(bigbox_profile, [a_bigshelf])
    result = space_calculator.to_hash

    result['locations_with_space'][0]['count'].should eq(21)
  end


  it "tells you the total number of boxes that will fit on the locations checked" do
    space_calculator = SpaceCalculator.new(bigbox_profile, [a_bigshelf, another_bigshelf])
    result = space_calculator.to_hash

    result['total_spaces_available'].should eq(42)
  end


  it "tells you the total number of containers with our profile at the locations checked" do
    add_container_to_location(a_bigbox, a_bigshelf)
    add_container_to_location(a_bigbox, a_bigshelf)
    add_container_to_location(a_bigbox, a_bigshelf)
    add_container_to_location(a_bigbox, another_bigshelf)
    add_container_to_location(a_tinybox, another_bigshelf)

    space_calculator = SpaceCalculator.new(bigbox_profile, [a_bigshelf, another_bigshelf])
    result = space_calculator.to_hash

    result['total_containers_of_type'].should eq(4)
  end


  it "complains if you give it an unsupported unit" do
    # all this jiggery pokery to get a new value in the dimension_units enum
    du_enum = Enumeration.find(:name => 'dimension_units')
    du_enum.update(:editable => 1)
    Enumeration.apply_values(du_enum, {'values' => BackendEnumSource.values_for('dimension_units') + ['cubits']})
    BackendEnumSource.cache_entry_for('dimension_units', true)

    # create a container profile using the new value
    roman_box_cp = create_container_profile("roman box", "2", "2", "2", "cubits", "width")

    # the space calculator doesn't know how to convert cubits, so it should error
    expect {
      space_calculator = SpaceCalculator.new(roman_box_cp, [a_bigshelf])
    }.to raise_error(SpaceCalculator::UnsupportedUnitException)
  end


  it "tells you if a box is too big for a shelf" do
    space_calculator = SpaceCalculator.new(bigbox_profile, [a_smallshelf])
    result = space_calculator.to_hash

    result['locations_without_space'].length.should eq(1)
  end


  it "cannot calculate space for a location that lacks a profile" do
    space_calculator = SpaceCalculator.new(bigbox_profile, [a_profilelessshelf])
    result = space_calculator.to_hash

    result['uncalculatable_locations'].length.should eq(1)
  end


  it "cannot calculate space for a location whose profile lacks a dimension" do
    space_calculator = SpaceCalculator.new(bigbox_profile, [an_uncertainshelf])
    result = space_calculator.to_hash

    result['uncalculatable_locations'].length.should eq(1)
  end


  it "cannot calculate space for a location that currently contains a container without a profile" do
    add_container_to_location(a_box_without_a_profile, a_bigshelf)

    space_calculator = SpaceCalculator.new(bigbox_profile, [a_bigshelf])
    result = space_calculator.to_hash

    result['uncalculatable_locations'].length.should eq(1)
  end


  it "cannot calculate space for a location that is already over capacity" do
    add_container_to_location(a_bigbox, a_smallshelf)

    space_calculator = SpaceCalculator.new(tinybox_profile, [a_smallshelf])
    result = space_calculator.to_hash

    result['uncalculatable_locations'].length.should eq(1)
  end


  it "can handle nil units and will assume inches" do
    space_calculator = SpaceCalculator.new(bigbox_profile, [a_nounitshelf])
    result = space_calculator.to_hash

    result['locations_with_space'][0]['count'].should eq(1)
  end


  it "respects stacking limits" do
    space_calculator = SpaceCalculator.new(unstackablebox_profile, [a_bigshelf])
    result = space_calculator.to_hash

    result['locations_with_space'][0]['count'].should eq(7)

  end

end
