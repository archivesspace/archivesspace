require 'spec_helper'

describe 'Location model' do

  it "can be created from a JSON module" do
    location = Location.create_from_json(build(:json_location, :building => "129 West 81st Street"),
                                         :repo_id => $repo_id)

    Location[location[:id]].building.should eq("129 West 81st Street")
    Location[location[:id]].barcode.should match(/[0,1]?/)
  end


  it "can be created with coordinate data" do
    opts = {:coordinate_1_label => "Position XYZ",
            :coordinate_1_indicator => "A1BB99",
            :coordinate_2_label => "Position ABC",
            :coordinate_2_indicator => "Z55"}
    
    location = Location.create_from_json(build(:json_location, opts), :repo_id => $repo_id)

    Location[location[:id]].coordinate_1_label.should eq("Position XYZ")
    Location[location[:id]].coordinate_2_indicator.should eq("Z55")
  end


  it "can be created with a classification" do
    opts = {:classification => "Foo Foo Foo Foo"}
    
    location = Location.create_from_json(build(:json_location, opts), :repo_id => $repo_id)

    Location[location[:id]].classification.should eq("Foo Foo Foo Foo")
  end


  it "generates a title" do

    building = "1 Testing Street"
    barcode = "011011001"
    area = "Area"

    location = Location.create_from_json(build(:json_location, {:building => building, :barcode => barcode, :floor => nil, :room => nil, :area => area}), :repo_id => $repo_id)

    Location[location[:id]].title.should eq("#{building}, #{area} [#{barcode}]")
  end


  it "enforces at least one of barcode, classification or coordinate" do
    expect {
      create(:json_location, {:barcode => nil, :classification => nil, :coordinate_1_indicator => nil})
    }.to raise_error(JSONModel::ValidationException)
  end


  it "generates identifiers for a batch location coordinate definition (letters)" do
    batch = JSONModel(:location_batch).from_hash(build(:json_location).to_hash.merge({
      "coordinate_1_range" => {
        "label" => "Testing",
        "start" => "A",
        "end" => "D",
        "prefix" => "Oogabooga-"
      }
    }))

    ids = Location.generate_indicators(batch["coordinate_1_range"])

    ids[0].should eq("Oogabooga-A")
    ids[1].should eq("Oogabooga-B")
    ids[2].should eq("Oogabooga-C")
    ids[3].should eq("Oogabooga-D")
  end

  it "generates identifiers for a batch location coordinate definition (integers)" do
    batch = JSONModel(:location_batch).from_hash(build(:json_location).to_hash.merge({
                                                   "coordinate_1_range" => {
                                                     "label" => "Testing",
                                                     "start" => "3",
                                                     "end" => "6",
                                                     "suffix" => "-woozle"
                                                   }
                                                 }))

    ids = Location.generate_indicators(batch["coordinate_1_range"])

    ids[0].should eq("3-woozle")
    ids[1].should eq("4-woozle")
    ids[2].should eq("5-woozle")
    ids[3].should eq("6-woozle")
  end


  it "creates locations from a batch process" do
    batch = JSONModel(:location_batch).from_hash(build(:json_location).to_hash.merge({
                                                   "coordinate_1_range" => {
                                                     "label" => "Range",
                                                     "start" => "1",
                                                     "end" => "10"
                                                   },
                                                   "coordinate_2_range" => {
                                                     "label" => "Section",
                                                     "start" => "A",
                                                     "end" => "M"
                                                   },
                                                   "coordinate_3_range" => {
                                                     "label" => "Shelf",
                                                     "start" => "1",
                                                     "end" => "7"
                                                   }
                                                 }))

    locations = Location.create_for_batch(batch)

    locations.length.should eq(910)

    locations[0].coordinate_1_label.should eq("Range")
    locations[0].coordinate_1_indicator.should eq("1")
    locations[0].coordinate_2_label.should eq("Section")
    locations[0].coordinate_2_indicator.should eq("A")
    locations[0].coordinate_3_label.should eq("Shelf")
    locations[0].coordinate_3_indicator.should eq("1")

    locations[1].coordinate_1_label.should eq("Range")
    locations[1].coordinate_1_indicator.should eq("1")
    locations[1].coordinate_2_label.should eq("Section")
    locations[1].coordinate_2_indicator.should eq("A")
    locations[1].coordinate_3_label.should eq("Shelf")
    locations[1].coordinate_3_indicator.should eq("2")

    locations[909].coordinate_1_label.should eq("Range")
    locations[909].coordinate_1_indicator.should eq("10")
    locations[909].coordinate_2_label.should eq("Section")
    locations[909].coordinate_2_indicator.should eq("M")
    locations[909].coordinate_3_label.should eq("Shelf")
    locations[909].coordinate_3_indicator.should eq("7")
  end


  it "can have an owner repository" do
    owner_repo = create(:unselected_repo, {:repo_code => "OWNER_REPO"})

    owner_repo_uri = JSONModel(:repository).uri_for(owner_repo.id)

    location = create(:json_location, {:owner_repo => {'ref' => owner_repo_uri}})

    json = Location.to_jsonmodel(location.id)
    json['owner_repo']['ref'].should eq(owner_repo_uri)
  end

  it "allows you you delete a location that has a location profile attached" do
    location_profile = create(:json_location_profile)
    location = create(:json_location,
                      :location_profile => {'ref' => location_profile.uri})

    expect { Location[location.id].delete }.to_not raise_error

    Location[location.id].should be(nil)
  end

  it "allows you you delete a location that has an owner" do
    owner_repo = create(:unselected_repo, {:repo_code => "OWNER_REPO"})
    owner_repo_uri = JSONModel(:repository).uri_for(owner_repo.id)

    location = create(:json_location, {:owner_repo => {'ref' => owner_repo_uri}})

    expect { Location[location.id].delete }.to_not raise_error

    Location[location.id].should be(nil)
  end


  describe "functions" do

    let (:arrival_function) { build(:json_location_function,
                                    :location_function_type => 'arrivals') }

    let (:shared_function) { build(:json_location_function,
                                   :location_function_type => 'shared') }

    it "can have a bunch of functions" do
      opts = {:functions => [arrival_function, shared_function]}
      location = Location.create_from_json(build(:json_location, opts), :repo_id => $repo_id)

      json = Location.to_jsonmodel(location.id)
      json['functions'].length.should eq(2)
    end


    it "only remembers unique functions" do
      opts = {:functions => [arrival_function, arrival_function, shared_function]}
      location = Location.create_from_json(build(:json_location, opts), :repo_id => $repo_id)

      json = Location.to_jsonmodel(location.id)

      json['functions'].length.should eq(2)
    end

  end

end
