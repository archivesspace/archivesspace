require 'spec_helper'
require_relative 'spec_slugs_helper'

describe 'Digital object model' do

  it "allows digital objects to be created" do
    json = build(:json_digital_object)

    digital_object = DigitalObject.create_from_json(json, :repo_id => $repo_id)

    expect(DigitalObject[digital_object[:id]].title).to eq(json.title)
  end


  it "prevents duplicate IDs " do
    json1 = build(:json_digital_object, :digital_object_id => '123')

    json2 = build(:json_digital_object, :digital_object_id => '123')

    expect { DigitalObject.create_from_json(json1, :repo_id => $repo_id) }.not_to raise_error
    expect { DigitalObject.create_from_json(json2, :repo_id => $repo_id) }.to raise_error(Sequel::ValidationFailed)
  end


  it "can link a digital object to an accession" do
    digital_object = create(:json_digital_object)
    create(:json_accession,
                 :instances => [build(:json_instance_digital,
                                      :digital_object => {'ref' => digital_object.uri})])

    digital_object = JSONModel(:digital_object).find(digital_object.id)
    expect(digital_object.collection.count).to eq(1)
    expect(digital_object.linked_instances.count).to eq(1)
  end

  it "can link a digital object to a classification" do
    digital_object = create(:json_digital_object)
    create(:json_classification,
                            :linked_records => [{'ref' => digital_object.uri}]
    )

    digital_object = JSONModel(:digital_object).find(digital_object.id)
    expect(digital_object.classifications.count).to eq(1)
  end

  it "can link a digital object to a resource" do
    digital_object = create(:json_digital_object)
    create(:json_resource,
                 :instances => [build(:json_instance_digital,
                                      :digital_object => {'ref' => digital_object.uri})])

    digital_object = JSONModel(:digital_object).find(digital_object.id)
    expect(digital_object.collection.count).to eq(1)
    expect(digital_object.linked_instances.count).to eq(1)
  end

  it "can link a digital object to multiple records types as collections and instances" do
    digital_object = create(:json_digital_object)
    resource = create(:json_resource,
                 :instances => [build(:json_instance_digital,
                                      :digital_object => {'ref' => digital_object.uri})])
    create(:json_accession,
                 :instances => [build(:json_instance_digital,
                                      :digital_object => {'ref' => digital_object.uri})])
    create(:json_archival_object,
                 :instances => [build(:json_instance_digital,
                                      :digital_object => {'ref' => digital_object.uri})],
                 :resource => {:ref => resource.uri})

    digital_object = JSONModel(:digital_object).find(digital_object.id)
    expect(digital_object.collection.count).to eq(2)
    expect(digital_object.linked_instances.count).to eq(3)
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
  end

  it "doesn't allow an unpublished file_version to be representative" do
    json = build(:json_digital_object, {
                   :publish => true,
                   :file_versions => [build(:json_file_version, {
                                              :publish => false,
                                              :is_representative => true,
                                              :file_uri => 'http://foo.com/bar1',
                                              :use_statement => 'image-service'
                                            }),
                                      build(:json_file_version, {
                                              :publish => true,
                                              :file_uri => 'http://foo.com/bar2',
                                              :use_statement => 'image-service'
                                            })
                                     ]})

    expect {
      DigitalObject.create_from_json(json)
    }.to raise_error(Sequel::ValidationFailed)
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

    expect(obj.file_versions.first['caption']).to eq("bar one");
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
    expect(resource).not_to be_nil
    expect(resource.instances.count).to be(0)

  end

  describe "slug tests" do
    before(:all) do
      AppConfig[:use_human_readable_urls] = true
    end

    describe "slug autogen enabled" do
      describe "by name" do
        before(:all) do
          AppConfig[:auto_generate_slugs_with_id] = false
        end
        it "autogenerates a slug via title" do
          digital_object = DigitalObject.create_from_json(build(:json_digital_object, :is_slug_auto => true, :title => rand(100000).to_s))
          expected_slug = clean_slug(digital_object[:title])
          expect(digital_object[:slug]).to eq(expected_slug)
        end
        it "cleans slug" do
          digital_object = DigitalObject.create_from_json(build(:json_digital_object, :is_slug_auto => true, :title => "Foo Bar Baz&&&&"))
          expect(digital_object[:slug]).to eq("foo_bar_baz")
        end

        it "dedupes slug" do
          digital_object1 = DigitalObject.create_from_json(build(:json_digital_object, :is_slug_auto => true, :title => "foo"))
          digital_object2 = DigitalObject.create_from_json(build(:json_digital_object, :is_slug_auto => true, :title => "foo"))
          expect(digital_object1[:slug]).to eq("foo")
          expect(digital_object2[:slug]).to eq("foo_1")
        end
        it "turns off autogen if slug is blank" do
          digital_object = DigitalObject.create_from_json(build(:json_digital_object, :is_slug_auto => true))
          digital_object.update(:slug => "")
          expect(digital_object[:is_slug_auto]).to eq(0)
        end
      end
      describe "by id" do
        before(:all) do
          AppConfig[:auto_generate_slugs_with_id] = true
        end
        it "autogenerates a slug via identifier" do
          digital_object = DigitalObject.create_from_json(build(:json_digital_object, :is_slug_auto => true))
          expected_slug = clean_slug(digital_object[:digital_object_id])
          expect(digital_object[:slug]).to eq(expected_slug)
        end
        it "cleans slug" do
          digital_object = DigitalObject.create_from_json(build(:json_digital_object, :is_slug_auto => true, :digital_object_id => "Foo Bar Baz&&&&"))
          expect(digital_object[:slug]).to eq("foo_bar_baz")
        end

        it "dedupes slug" do
          digital_object1 = DigitalObject.create_from_json(build(:json_digital_object, :is_slug_auto => true, :digital_object_id => "foo"))
          digital_object2 = DigitalObject.create_from_json(build(:json_digital_object, :is_slug_auto => true, :digital_object_id => "foo#"))
          expect(digital_object1[:slug]).to eq("foo")
          expect(digital_object2[:slug]).to eq("foo_1")
        end
      end
    end

    describe "slug autogen disabled" do
      before(:all) do
        AppConfig[:auto_generate_slugs_with_id] = false
      end
      it "slug does not change when config set to autogen by title and title updated" do
        digital_object = DigitalObject.create_from_json(build(:json_digital_object, :is_slug_auto => false, :slug => "foo"))
        digital_object.update(:title => rand(100000000))
        expect(digital_object[:slug]).to eq("foo")
      end

      it "slug does not change when config set to autogen by id and id updated" do
        digital_object = DigitalObject.create_from_json(build(:json_digital_object, :is_slug_auto => false, :slug => "foo"))
        digital_object.update(:digital_object_id => rand(100000000))
        expect(digital_object[:slug]).to eq("foo")
      end
    end

    describe "manual slugs" do
      it "cleans manual slugs" do
        digital_object = DigitalObject.create_from_json(build(:json_digital_object, :is_slug_auto => false))
        digital_object.update(:slug => "Foo Bar Baz ###")
        expect(digital_object[:slug]).to eq("foo_bar_baz")
      end

      it "dedupes manual slugs" do
        digital_object1 = DigitalObject.create_from_json(build(:json_digital_object, :is_slug_auto => false, :slug => "foo"))
        digital_object2 = DigitalObject.create_from_json(build(:json_digital_object, :is_slug_auto => false))

        digital_object2.update(:slug => "foo")

        expect(digital_object1[:slug]).to eq("foo")
        expect(digital_object2[:slug]).to eq("foo_1")
      end
    end
  end
end
