require 'spec_helper'

describe 'Hidden record timestamps' do

  def hidden_at(record)
    record.class[record.id][:hidden_at]
  end

  def an_archival_object_under(resource)
    ArchivalObject.create_from_json(build(:json_archival_object,
                                          'resource' => {'ref' => resource.uri}))
  end

  it "doesn't stamp a record that is published and unsuppressed" do
    expect(hidden_at(create_resource(:publish => true))).to be_nil
  end

  it "stamps a record created unpublished" do
    expect(hidden_at(create_resource(:publish => false))).not_to be_nil
  end

  it "stamps a record when it is suppressed and clears the stamp when it is unsuppressed" do
    resource = create_resource(:publish => true)

    resource.set_suppressed(true)
    expect(hidden_at(resource)).not_to be_nil

    resource.set_suppressed(false)
    expect(hidden_at(resource)).to be_nil
  end

  it "stamps a record when it is unpublished and clears the stamp when it is republished" do
    resource = create_resource(:publish => true)

    resource.unpublish!
    expect(hidden_at(resource)).not_to be_nil

    resource.publish!
    expect(hidden_at(resource)).to be_nil
  end

  it "stamps a record unpublished through a regular update" do
    resource = create_resource(:publish => true)

    json = Resource.to_jsonmodel(resource.id)
    json.publish = false
    resource.update_from_json(json)

    expect(hidden_at(resource)).not_to be_nil
  end

  it "stamps the children of a suppressed record" do
    resource = create_resource(:publish => true)
    ao = an_archival_object_under(resource)

    resource.set_suppressed(true)

    expect(hidden_at(ao)).not_to be_nil
  end

  it "leaves the stamp alone while a record stays hidden" do
    resource = create_resource(:publish => false)

    an_hour_ago = Time.now.utc - 3600
    Resource.dataset.filter(:id => resource.id).update(:hidden_at => an_hour_ago)

    resource.unpublish!
    resource.set_suppressed(true)

    expect(hidden_at(resource).to_i).to eq(an_hour_ago.to_i)
  end

  it "leaves the stamp alone when a hidden record's mtime is bumped" do
    resource = create_resource(:publish => false)

    an_hour_ago = Time.now.utc - 3600
    Resource.dataset.filter(:id => resource.id).update(:hidden_at => an_hour_ago)

    # As happens when the repository is published or unpublished, or when
    # the TouchRecords mixin is called for a related record.
    Resource.update_mtime_for_repo_id($repo_id)

    expect(hidden_at(resource).to_i).to eq(an_hour_ago.to_i)
    expect(Resource[resource.id][:system_mtime].to_i).to be > an_hour_ago.to_i
  end
end
