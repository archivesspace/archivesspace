require 'spec_helper'

describe 'Digital object model' do

  it "allows digital objects to be created" do
    json = build(:json_digital_object)
    
    digital_object = DigitalObject.create_from_json(json, :repo_id => $repo_id)

    DigitalObject[digital_object[:id]].title.should eq(json.title)
  end


  it "prevents duplicate IDs " do
    json1 = build(:json_digital_object, :digital_object_id => '123')
    
    json2 = build(:json_digital_object, :digital_object_id => '123')

    expect { DigitalObject.create_from_json(json1, :repo_id => $repo_id) }.to_not raise_error
    expect { DigitalObject.create_from_json(json2, :repo_id => $repo_id) }.to raise_error(Sequel::ValidationFailed)
  end


  it "can link a digital object to an accession" do
    digital_object = create(:json_digital_object)
    acc = create(:json_accession,
                 :instances => [build(:json_instance,
                                      :instance_type => 'digital_object',
                                      :digital_object => {'ref' => digital_object.uri})])

    digital_object = JSONModel(:digital_object).find(digital_object.id)
    digital_object.linked_instances.count.should eq(1)
  end

end
