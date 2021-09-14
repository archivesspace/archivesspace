require 'spec_helper'

def generate_arks_job
  build( :json_job,
         :job => build(:json_generate_arks_job)
       )
end

describe "Generate ARKs job" do

  around(:all) do |all|
    arks_enabled = AppConfig[:arks_enabled]
    AppConfig[:arks_enabled] = true
    all.run
    AppConfig[:arks_enabled] = arks_enabled
  end

  let(:user) { create_nobody_user }

  it "results in an ark being generated for all supported types" do
    resource  = Resource.create_from_json(build(:json_resource_nohtml))
    archival_object = ArchivalObject.create_from_json(build(:json_archival_object_nohtml))

    # Delete ARKs to pretend these had not been generated yet
    ArkName.filter(:resource_id => resource.id).delete
    ArkName.filter(:archival_object_id => archival_object.id).delete

    expect(ArkName.first(:resource_id => resource.id)).to be_nil
    expect(ArkName.first(:archival_object_id => archival_object.id)).to be_nil

    json = generate_arks_job
    job = Job.create_from_json(json, :user => user )
    jr = JobRunner.for(job)
    jr.run

    expect(ArkName.first(:resource_id => resource.id)).to_not be_nil
    expect(ArkName.first(:archival_object_id => archival_object.id)).to_not be_nil
  end

  it "does not mess with current valid ARKs" do
    resource  = Resource.create_from_json(build(:json_resource_nohtml))
    archival_object = ArchivalObject.create_from_json(build(:json_archival_object_nohtml))

    res_ark_before = ArkName.first(:resource_id => resource.id)
    ao_ark_before = ArkName.first(:archival_object_id => archival_object.id)

    json = generate_arks_job
    job = Job.create_from_json(json, :user => user )
    jr = JobRunner.for(job)
    jr.run

    expect(ArkName.where(:resource_id => resource.id).count).to eq(1)
    expect(ArkName.where(:archival_object_id => archival_object.id).count).to eq(1)

    expect(ArkName.first(:resource_id => resource.id).id).to eq(res_ark_before.id)
    expect(ArkName.first(:archival_object_id => archival_object.id).id).to eq(ao_ark_before.id)

    expect(ArkName[res_ark_before.id].generated_value).to eq(res_ark_before.generated_value)
    expect(ArkName[ao_ark_before.id].generated_value).to eq(ao_ark_before.generated_value)
  end

  it "generates a new ARK, and remembers the old one, when the current ARK is no longer valid" do
    resource  = Resource.create_from_json(build(:json_resource_nohtml))
    archival_object = ArchivalObject.create_from_json(build(:json_archival_object_nohtml))

    res_ark_id = ArkName.first(:resource_id => resource.id).id
    ao_ark_id = ArkName.first(:archival_object_id => archival_object.id).id

    ArkName[res_ark_id].update(:version_key => 'DEFINITELY NOT A VALID VERSION KEY')
    ArkName[ao_ark_id].update(:version_key => 'DEFINITELY NOT A VALID VERSION KEY')

    json = generate_arks_job
    job = Job.create_from_json(json, :user => user )
    jr = JobRunner.for(job)
    jr.run

    old_res_ark = ArkName[res_ark_id]
    old_ao_ark = ArkName[ao_ark_id]

    expect(old_res_ark.is_current).to eq(0)
    expect(old_ao_ark.is_current).to eq(0)

    expect(ArkName.where(:resource_id => resource.id, :is_current => 1).count).to eq(1)
    expect(ArkName.where(:archival_object_id => archival_object.id, :is_current => 1).count).to eq(1)
  end
end
