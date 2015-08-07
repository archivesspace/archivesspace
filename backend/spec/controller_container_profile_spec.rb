require 'spec_helper'

describe 'Container Profile controller' do

  it "can create a container profile" do
    cp = create(:json_container_profile)
    cp.name = "cp-01"
    cp.save

    JSONModel(:container_profile).find(cp.id).name.should eq("cp-01")

  end


  it "can update a container profile" do
    cp = create(:json_container_profile)
    cp.name = "cp-01"
    cp.save

    cp_retrieved = JSONModel(:container_profile).find(cp.id)
    cp_retrieved.name = "cp-02"
    cp_retrieved.save

    JSONModel(:container_profile).find(cp_retrieved.id).name.should eq("cp-02")
  end


it "allows container profiles to be deleted" do
    cp = create(:json_container_profile)
    cp.name = "cp-01"
    cp.save
    JSONModel(:container_profile).find(cp.id).name.should eq("cp-01")
    cp.delete

    expect {
      JSONModel(:container_profile).find(cp.id)
    }.to raise_error(RecordNotFound)
  end


  it "fails when you try to update a container_profile that doesn't exist" do
    cp = build(:json_container_profile)
    cp.uri = "/container_profiles/9999"

    expect { cp.save }.to raise_error(RecordNotFound)
  end


  it "can give a list of container profiles" do
    5.times do 
      create(:json_container_profile)
    end  
    JSONModel(:container_profile).all(:page => 1)['results'].count.should eq(5)
  end

end
