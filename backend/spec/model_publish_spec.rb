require 'spec_helper'

describe 'Record Publishing' do

  it "an archival object's publish status is overridden by a unpublished resource" do
    resource = create_resource(:publish => false)

    obj = ArchivalObject.create_from_json(build(:json_archival_object,
                                                'resource' => {'ref' => resource.uri},
                                                'publish' => true))

    ArchivalObject.to_jsonmodel(obj).publish.should be_true
    ArchivalObject.to_jsonmodel(obj).has_unpublished_ancestor.should be_true
  end


  it "an archival object's publish status is overridden by a unpublished parent archival object" do
    resource = create_resource(:publish => true)

    parent = ArchivalObject.create_from_json(build(:json_archival_object,
                                                   'resource' => {'ref' => resource.uri},
                                                   'publish' => false))

    child = ArchivalObject.create_from_json(build(:json_archival_object,
                                                  'resource' => {'ref' => resource.uri},
                                                  'parent' => {'ref' => parent.uri},
                                                  'publish' => true))

    ArchivalObject.to_jsonmodel(parent).publish.should be_false
    ArchivalObject.to_jsonmodel(parent).has_unpublished_ancestor.should be_false
    ArchivalObject.to_jsonmodel(child).publish.should be_true
    ArchivalObject.to_jsonmodel(child).has_unpublished_ancestor.should be_true
  end


  it "a digital object component's publish status is overridden by a unpublished digital object" do
    digital_object = create_digital_object(:publish => false)

    obj = DigitalObjectComponent.create_from_json(build(:json_digital_object_component,
                                                'digital_object' => {'ref' => digital_object.uri},
                                                'publish' => true))

    DigitalObjectComponent.to_jsonmodel(obj).publish.should be_true
    DigitalObjectComponent.to_jsonmodel(obj).has_unpublished_ancestor.should be_true
  end


  it "a digital object component's publish status is overridden by a unpublished parent component" do
    digital_object = create_digital_object(:publish => true)

    parent = DigitalObjectComponent.create_from_json(build(:json_digital_object_component,
                                                   'digital_object' => {'ref' => digital_object.uri},
                                                   'publish' => false))

    child = DigitalObjectComponent.create_from_json(build(:json_digital_object_component,
                                                  'digital_object' => {'ref' => digital_object.uri},
                                                  'parent' => {'ref' => parent.uri},
                                                  'publish' => true))

    DigitalObjectComponent.to_jsonmodel(parent).publish.should be_false
    DigitalObjectComponent.to_jsonmodel(parent).has_unpublished_ancestor.should be_false
    DigitalObjectComponent.to_jsonmodel(child).publish.should be_true
    DigitalObjectComponent.to_jsonmodel(child).has_unpublished_ancestor.should be_true
  end

end