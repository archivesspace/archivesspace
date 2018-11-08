require 'spec_helper'

describe 'Location model' do

  it "can be created from a JSON module" do
    location = Location.create_from_json(build(:json_location, :building => "129 West 81st Street"),
                                         :repo_id => $repo_id)

    expect(Location[location[:id]].building).to eq("129 West 81st Street")
    expect(Location[location[:id]].barcode).to match(/[0,1]?/)
  end


  it "can be created with coordinate data" do
    opts = {:coordinate_1_label => "Position XYZ",
            :coordinate_1_indicator => "A1BB99",
            :coordinate_2_label => "Position ABC",
            :coordinate_2_indicator => "Z55"}

    location = Location.create_from_json(build(:json_location, opts), :repo_id => $repo_id)

    expect(Location[location[:id]].coordinate_1_label).to eq("Position XYZ")
    expect(Location[location[:id]].coordinate_2_indicator).to eq("Z55")
  end


  it "can be created with a classification" do
    opts = {:classification => "Foo Foo Foo Foo"}

    location = Location.create_from_json(build(:json_location, opts), :repo_id => $repo_id)

    expect(Location[location[:id]].classification).to eq("Foo Foo Foo Foo")
  end


  it "generates a title" do

    building = "1 Testing Street"
    barcode = "011011001"
    area = "Area"

    location = Location.create_from_json(build(:json_location, {:building => building, :barcode => barcode, :floor => nil, :room => nil, :area => area}), :repo_id => $repo_id)

    expect(Location[location[:id]].title).to eq("#{building}, #{area} [#{barcode}]")
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

    expect(ids[0]).to eq("Oogabooga-A")
    expect(ids[1]).to eq("Oogabooga-B")
    expect(ids[2]).to eq("Oogabooga-C")
    expect(ids[3]).to eq("Oogabooga-D")
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

    expect(ids[0]).to eq("3-woozle")
    expect(ids[1]).to eq("4-woozle")
    expect(ids[2]).to eq("5-woozle")
    expect(ids[3]).to eq("6-woozle")
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

    expect(locations.length).to eq(910)

    expect(locations[0].coordinate_1_label).to eq("Range")
    expect(locations[0].coordinate_1_indicator).to eq("1")
    expect(locations[0].coordinate_2_label).to eq("Section")
    expect(locations[0].coordinate_2_indicator).to eq("A")
    expect(locations[0].coordinate_3_label).to eq("Shelf")
    expect(locations[0].coordinate_3_indicator).to eq("1")

    expect(locations[1].coordinate_1_label).to eq("Range")
    expect(locations[1].coordinate_1_indicator).to eq("1")
    expect(locations[1].coordinate_2_label).to eq("Section")
    expect(locations[1].coordinate_2_indicator).to eq("A")
    expect(locations[1].coordinate_3_label).to eq("Shelf")
    expect(locations[1].coordinate_3_indicator).to eq("2")

    expect(locations[909].coordinate_1_label).to eq("Range")
    expect(locations[909].coordinate_1_indicator).to eq("10")
    expect(locations[909].coordinate_2_label).to eq("Section")
    expect(locations[909].coordinate_2_indicator).to eq("M")
    expect(locations[909].coordinate_3_label).to eq("Shelf")
    expect(locations[909].coordinate_3_indicator).to eq("7")
  end


  it "can have an owner repository" do
    owner_repo = create(:unselected_repo, {:repo_code => "OWNER_REPO"})

    owner_repo_uri = JSONModel(:repository).uri_for(owner_repo.id)

    location = create(:json_location, {:owner_repo => {'ref' => owner_repo_uri}})

    json = Location.to_jsonmodel(location.id)
    expect(json['owner_repo']['ref']).to eq(owner_repo_uri)
  end

  it "allows you you delete a location that has a location profile attached" do
    location_profile = create(:json_location_profile)
    location = create(:json_location,
                      :location_profile => {'ref' => location_profile.uri})

    expect { Location[location.id].delete }.not_to raise_error

    expect(Location[location.id]).to be_nil
  end

  it "allows you you delete a location that has an owner" do
    owner_repo = create(:unselected_repo, {:repo_code => "OWNER_REPO"})
    owner_repo_uri = JSONModel(:repository).uri_for(owner_repo.id)

    location = create(:json_location, {:owner_repo => {'ref' => owner_repo_uri}})

    expect { Location[location.id].delete }.not_to raise_error

    expect(Location[location.id]).to be_nil
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
      expect(json['functions'].length).to eq(2)
    end


    it "only remembers unique functions" do
      opts = {:functions => [arrival_function, arrival_function, shared_function]}
      location = Location.create_from_json(build(:json_location, opts), :repo_id => $repo_id)

      json = Location.to_jsonmodel(location.id)

      expect(json['functions'].length).to eq(2)
    end

  end

end
