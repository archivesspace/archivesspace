require 'spec_helper'

describe 'Record Publishing' do

  it "an archival object's publish status is overridden by a unpublished resource" do
    resource = create_resource(:publish => false)

    obj = ArchivalObject.create_from_json(build(:json_archival_object,
                                                'resource' => {'ref' => resource.uri},
                                                'publish' => true))

    expect(ArchivalObject.to_jsonmodel(obj).publish).to be_truthy
    expect(ArchivalObject.to_jsonmodel(obj).has_unpublished_ancestor).to be_truthy
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

    expect(ArchivalObject.to_jsonmodel(parent).publish).to be_falsey
    expect(ArchivalObject.to_jsonmodel(parent).has_unpublished_ancestor).to be_falsey
    expect(ArchivalObject.to_jsonmodel(child).publish).to be_truthy
    expect(ArchivalObject.to_jsonmodel(child).has_unpublished_ancestor).to be_truthy
  end


  it "a digital object component's publish status is overridden by a unpublished digital object" do
    digital_object = create_digital_object(:publish => false)

    obj = DigitalObjectComponent.create_from_json(build(:json_digital_object_component,
                                                'digital_object' => {'ref' => digital_object.uri},
                                                'publish' => true))

    expect(DigitalObjectComponent.to_jsonmodel(obj).publish).to be_truthy
    expect(DigitalObjectComponent.to_jsonmodel(obj).has_unpublished_ancestor).to be_truthy
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

    expect(DigitalObjectComponent.to_jsonmodel(parent).publish).to be_falsey
    expect(DigitalObjectComponent.to_jsonmodel(parent).has_unpublished_ancestor).to be_falsey
    expect(DigitalObjectComponent.to_jsonmodel(child).publish).to be_truthy
    expect(DigitalObjectComponent.to_jsonmodel(child).has_unpublished_ancestor).to be_truthy
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

    expect(ArchivalObject.to_jsonmodel(parent).publish).to be_truthy
    expect(ArchivalObject.to_jsonmodel(parent).has_unpublished_ancestor).to be_truthy
    expect(ArchivalObject.to_jsonmodel(child).publish).to be_truthy
    expect(ArchivalObject.to_jsonmodel(child).has_unpublished_ancestor).to be_truthy
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

    expect(ArchivalObject.to_jsonmodel(parent).publish).to be_truthy
    expect(ArchivalObject.to_jsonmodel(parent).has_unpublished_ancestor).to be_falsey
    expect(ArchivalObject.to_jsonmodel(child).publish).to be_truthy
    expect(ArchivalObject.to_jsonmodel(child).has_unpublished_ancestor).to be_truthy
  end

end
