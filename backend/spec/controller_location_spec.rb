require 'spec_helper'

describe 'Location controller' do

  it "can update a location" do
    loc = create(:json_location)
    loc.room = "2-26"
    loc.save

    JSONModel(:location).find(loc.id).room.should eq("2-26")

  end


  it "can give a list of locations" do
    create(:json_location)
    JSONModel(:location).all(:page => 1)['results'].count.should eq(1)
  end


  it "can perform a dry run batch creation of locations" do
    batch = JSONModel(:location_batch).from_hash({
                                                   "source_location" => build(:json_location),
                                                   "coordinate_1" => {
                                                     "label" => "Range",
                                                     "start" => "1",
                                                     "end" => "10"
                                                   },
                                                   "coordinate_2" => {
                                                     "label" => "Section",
                                                     "start" => "A",
                                                     "end" => "M"
                                                   },
                                                   "coordinate_3" => {
                                                     "label" => "Shelf",
                                                     "start" => "1",
                                                     "end" => "7"
                                                   }
                                                 })


    response = JSONModel::HTTP.post_json(URI("#{JSONModel::HTTP.backend_url}/repositories/#{$repo_id}/locations/batch?dry_run=true"),
                              batch.to_json)

    batch_response = ASUtils.json_parse(response.body)

    batch_response["result_locations"].length.should eq(910)
    batch_response["result_locations"][0]["uri"].should eq(nil)
  end


  it "can perform a batch creation of locations" do
    batch = JSONModel(:location_batch).from_hash({
                                                   "source_location" => build(:json_location),
                                                   "coordinate_1" => {
                                                     "label" => "Range",
                                                     "start" => "1",
                                                     "end" => "10"
                                                   },
                                                   "coordinate_2" => {
                                                     "label" => "Section",
                                                     "start" => "A",
                                                     "end" => "M"
                                                   },
                                                   "coordinate_3" => {
                                                     "label" => "Shelf",
                                                     "start" => "1",
                                                     "end" => "7"
                                                   }
                                                 })


    response = JSONModel::HTTP.post_json(URI("#{JSONModel::HTTP.backend_url}/repositories/#{$repo_id}/locations/batch"),
                                         batch.to_json)

    batch_response = ASUtils.json_parse(response.body)

    batch_response["result_locations"].length.should eq(910)
    JSONModel.parse_reference(batch_response["result_locations"][0])[:type].should eq("location")
  end
end
