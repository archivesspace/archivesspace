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
                 :instances => [build(:json_instance_digital,
                                      :digital_object => {'ref' => digital_object.uri})])

    digital_object = JSONModel(:digital_object).find(digital_object.id)
    digital_object.linked_instances.count.should eq(1)
  end


  it "won't allow more than one file_version flagged 'is_representative'" do
    json = build(:json_digital_object, {
                   :publish => true,
                   :file_versions => [build(:json_file_version, {
                                              :publish => true,
                                              :is_representative => true,
                                              :file_uri => 'http://foo.com/bar1',
                                              :use_statement => 'image-service'
                                            }),
                                      build(:json_file_version, {
                                              :publish => true,
                                              :is_representative => true,
                                              :file_uri => 'http://foo.com/bar2',
                                              :use_statement => 'image-service'
                                            })

                                     ]})


    expect {
      DigitalObject.create_from_json(json)

    }.to raise_error(Sequel::ValidationFailed)


    json = build(:json_digital_object, {
                   :publish => true,
                   :file_versions => [build(:json_file_version, {
                                              :publish => true,
                                              :is_representative => true,
                                              :file_uri => 'http://foo.com/bar1',
                                              :use_statement => 'image-service'
                                            }),
                                      build(:json_file_version, {
                                              :publish => true,
                                              :file_uri => 'http://foo.com/bar2',
                                              :use_statement => 'image-service'
                                            }),
                                      build(:json_file_version, {
                                              :publish => true,
                                              :file_uri => 'http://foo.com/bar3',
                                              :use_statement => 'image-service'
                                            })

                                     ]})


    expect {
      DigitalObject.create_from_json(json)

    }.to_not raise_error

  end


  it "supports optional captions for file versions" do
    obj = create(:json_digital_object, {
                   :publish => true,
                   :file_versions => [build(:json_file_version, {
                                              :publish => true,
                                              :file_uri => 'http://foo.com/bar1',
                                              :caption => "bar one"
                                            })]
                 })

    obj = JSONModel(:digital_object).find(obj.id)


    obj.file_versions.first['caption'].should eq("bar one");
  end

  it "deletes all related instances when digital object is deleted" do

    # Create resource and link to digital instance
    resource = create(:json_resource,
                      :instances => [build(:json_instance_digital)])

    # Identify digital object
    do_id = ((resource.instances[0]['digital_object']['ref']).split('/'))[4].to_i
    linked_digital_object = DigitalObject.where(:id => do_id).first

    # Identify instance
    instance = linked_digital_object.related_records(:instance_do_link).map {|sub| sub }.first

    # Delete digital object
    linked_digital_object = JSONModel(:digital_object).find(linked_digital_object.id)
    linked_digital_object.delete

    # Digital object should be dead
    expect {
      JSONModel(:digital_object).find(linked_digital_object.id)
    }.to raise_error(RecordNotFound)

    # Instance should be dead
    expect(
      Instance.filter(:id => instance.id).all
    ).to be_empty

    # Confirm all is still well with the resource
    resource = JSONModel(:resource).find(resource.id)
    resource.should_not eq(nil)
    resource.instances.count.should be(0)

  end

end
