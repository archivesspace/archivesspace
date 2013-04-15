require 'spec_helper'

describe 'Instance model' do


  it "allows an instance to be created" do

    opts = {:instance_type => generate(:instance_type), 
            :container => build(:json_container)
            }

    instance = Instance.create_from_json(build(:json_instance, opts))

    Instance[instance[:id]].instance_type.should eq(opts[:instance_type])
    Instance[instance[:id]].container.first.type_1.should eq(opts[:container]['type_1'])
  end


  it "allows an instance to be created with a digital object link" do
    digital_object =  create(:json_digital_object)

    opts = {"instance_type" => "digital_object",
            "digital_object" => {"ref" => digital_object.uri},
            "container" => nil
    }

    instance = Instance.create_from_json(build(:json_instance, opts))

    Instance[instance[:id]].instance_type.should eq(opts["instance_type"])
    Instance[instance[:id]].linked_records(:instance_do_link).id.should eq(digital_object.id)
  end


  it "throws an error if no container is provided" do
    opts = {"instance_type" => "audio",
            "container" => nil
    }

    expect {
      Instance.create_from_json(build(:json_instance, opts))
    }.to raise_error(ValidationException)

  end


  it "throws an error if no digital object is provided" do
    opts = {"instance_type" => "digital_object",
            "digital_object" => nil
    }

    expect {
      Instance.create_from_json(build(:json_instance, opts))
    }.to raise_error(ValidationException)

  end

end
