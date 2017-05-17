require 'spec_helper'

describe 'Record Publishing' do

  it "an archival object's publish status is overridden by a unpublished resource" do
    resource = create_resource(:publish => false)

    obj = ArchivalObject.create_from_json(build(:json_archival_object,
                                                'resource' => {'ref' => resource.uri},
                                                'publish' => true))

    ArchivalObject.to_jsonmodel(obj).publish.should be_truthy
    ArchivalObject.to_jsonmodel(obj).has_unpublished_ancestor.should be_truthy
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

    ArchivalObject.to_jsonmodel(parent).publish.should be_falsey
    ArchivalObject.to_jsonmodel(parent).has_unpublished_ancestor.should be_falsey
    ArchivalObject.to_jsonmodel(child).publish.should be_truthy
    ArchivalObject.to_jsonmodel(child).has_unpublished_ancestor.should be_truthy
  end


  it "a digital object component's publish status is overridden by a unpublished digital object" do
    digital_object = create_digital_object(:publish => false)

    obj = DigitalObjectComponent.create_from_json(build(:json_digital_object_component,
                                                'digital_object' => {'ref' => digital_object.uri},
                                                'publish' => true))

    DigitalObjectComponent.to_jsonmodel(obj).publish.should be_truthy
    DigitalObjectComponent.to_jsonmodel(obj).has_unpublished_ancestor.should be_truthy
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

    DigitalObjectComponent.to_jsonmodel(parent).publish.should be_falsey
    DigitalObjectComponent.to_jsonmodel(parent).has_unpublished_ancestor.should be_falsey
    DigitalObjectComponent.to_jsonmodel(child).publish.should be_truthy
    DigitalObjectComponent.to_jsonmodel(child).has_unpublished_ancestor.should be_truthy
  end


  it "an archival object's publish status is overridden by a suppressed resource" do
    resource = create_resource(:publish => true)

    parent = ArchivalObject.create_from_json(build(:json_archival_object,
                                                   'resource' => {'ref' => resource.uri},
                                                   'publish' => true))

    child = ArchivalObject.create_from_json(build(:json_archival_object,
                                                  'resource' => {'ref' => resource.uri},
                                                  'parent' => {'ref' => parent.uri},
                                                  'publish' => true))

    resource.set_suppressed(true)

    ArchivalObject.to_jsonmodel(parent).publish.should be_truthy
    ArchivalObject.to_jsonmodel(parent).has_unpublished_ancestor.should be_truthy
    ArchivalObject.to_jsonmodel(child).publish.should be_truthy
    ArchivalObject.to_jsonmodel(child).has_unpublished_ancestor.should be_truthy
  end


  it "an archival object's publish status is overridden by a suppressed parent archival object" do
    resource = create_resource(:publish => true)

    parent = ArchivalObject.create_from_json(build(:json_archival_object,
                                                   'resource' => {'ref' => resource.uri},
                                                   'publish' => true))

    child = ArchivalObject.create_from_json(build(:json_archival_object,
                                                  'resource' => {'ref' => resource.uri},
                                                  'parent' => {'ref' => parent.uri},
                                                  'publish' => true))

    parent.set_suppressed(true)

    ArchivalObject.to_jsonmodel(parent).publish.should be_truthy
    ArchivalObject.to_jsonmodel(parent).has_unpublished_ancestor.should be_falsey
    ArchivalObject.to_jsonmodel(child).publish.should be_truthy
    ArchivalObject.to_jsonmodel(child).has_unpublished_ancestor.should be_truthy
  end

end
