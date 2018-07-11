require 'spec_helper'

describe 'Instance model' do


  it "allows an instance to be created" do
    json = build(:json_instance)

    instance = Instance.create_from_json(json)

    Instance[instance[:id]].instance_type.should eq(json[:instance_type])
    Instance[instance[:id]].sub_container.first.type_2.should eq(json[:sub_container][:type_2])
  end


  it "allows an instance to be created with a digital object link" do
    digital_object =  create(:json_digital_object)

    json = build(:json_instance_digital, :digital_object => {:ref => digital_object.uri})

    instance = Instance.create_from_json(json)

    Instance[instance[:id]].instance_type.should eq(json["instance_type"])
    Instance[instance[:id]].related_records(:instance_do_link).id.should eq(digital_object.id)
  end


  it "throws an error if no container is provided" do
    opts = {"instance_type" => "audio",
            "sub_container" => nil
    }

    expect {
      Instance.create_from_json(build(:json_instance, opts))
    }.to raise_error(JSONModel::ValidationException)

  end


  it "throws an error if no digital object is provided" do
    opts = {"instance_type" => "digital_object",
            "digital_object" => nil
    }

    expect {
      Instance.create_from_json(build(:json_instance_digital, opts))
    }.to raise_error(JSONModel::ValidationException)

  end


  it "doesn't show instances where the digital object link has been suppressed" do
    digital_object =  create(:json_digital_object)

    archival_object = create(:json_archival_object,
                             :instances => [{"instance_type" => "digital_object",
                                              "digital_object" => {"ref" => digital_object.uri},
                                              "container" => nil
                                            }])

    digital_object.set_suppressed(true)

    create_nobody_user
    as_test_user("nobody") do
      ArchivalObject.to_jsonmodel(archival_object.id)['instances'].should eq([])
    end
  end


  it "allows an archival object with a digital object instance to be saved" do
    digital_object =  create(:json_digital_object)

    archival_object = create(:json_archival_object,
                             :instances => [{"instance_type" => "digital_object",
                                              "digital_object" => {"ref" => digital_object.uri},
                                              "container" => nil
                                            }])

    archival_object.title = "something else"

    obj = ArchivalObject.find(:id => archival_object.id)

    expect { obj.update_from_json(archival_object) }.to_not raise_error
  end


  it "throws an error if you supply a digital object URI for a non-digital object type" do
    expect {
    JSONModel(:instance)
      .from_hash(:digital_object => {:ref => '/repositories/#{$repo_id}/digital_objects/123'},
                 :instance_type => 'text')
      .validate
    }.to raise_error(JSONModel::ValidationException)
  end

end
