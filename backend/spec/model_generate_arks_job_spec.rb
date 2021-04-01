require 'spec_helper'

def generate_arks_job
  build( :json_job,
         :job => build(:json_generate_arks_job)
       )
end

describe "Generate ARKs job" do

  let(:user) { create_nobody_user }

  it "results in an ark being generated for all supported types" do
    resource  = Resource.create_from_json(build(:json_resource_nohtml))
    archival_object = ArchivalObject.create_from_json(build(:json_archival_object_nohtml))

    expect(ArkName.first(:resource_id => resource.id)).to be_nil
    expect(ArkName.first(:archival_object_id => archival_object.id)).to be_nil

    json = generate_arks_job
    job = Job.create_from_json(json, :user => user )
    jr = JobRunner.for(job)
    jr.run

    expect(ArkName.first(:resource_id => resource.id)).to_not be_nil
    expect(ArkName.first(:archival_object_id => archival_object.id)).to_not be_nil
  end

  it "does not add a second ark for objects that already exist in the ark_name table" do
     resource = Resource.create_from_json(build(:json_resource_nohtml))
     archival_object = ArchivalObject.create_from_json(build(:json_archival_object_nohtml))

     ArkName.create_from_resource(resource)
     ArkName.create_from_archival_object(archival_object)

     expect(ArkName.where(:resource_id => resource.id).count).to eq(1)
     expect(ArkName.where(:archival_object_id => archival_object.id).count).to eq(1)

     json = generate_arks_job
     job = Job.create_from_json(json, :user => user )
     jr = JobRunner.for(job)
     jr.run

     expect(ArkName.where(:resource_id => resource.id).count).to eq(1)
     expect(ArkName.where(:archival_object_id => archival_object.id).count).to eq(1)
   end
end
