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

end
