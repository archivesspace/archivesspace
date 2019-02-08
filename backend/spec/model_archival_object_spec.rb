require 'spec_helper'

describe 'ArchivalObject model' do

  it "allows archival objects to be created" do
    ao = ArchivalObject.create_from_json(
                                          build(
                                                :json_archival_object,
                                                :title => 'A new archival object'
                                                ),
                                          :repo_id => $repo_id)

    expect(ArchivalObject[ao[:id]].title).to eq('A new archival object')
  end


  it "allows multiple archival objects to be created without conflicts" do
    create_list(:json_archival_object, 5)
  end


  it "allow archival objects to be created with an extent" do

    opts = {:extents => [{
      "portion" => "whole",
      "number" => "5 or so",
      "extent_type" => generate(:extent_type),
    }]}

    ao = ArchivalObject.create_from_json(
                                          build(:json_archival_object, opts),
                                          :repo_id => $repo_id)
    expect(ArchivalObject[ao[:id]].extent.length).to eq(1)
    expect(ArchivalObject[ao[:id]].extent[0].extent_type).to eq(opts[:extents][0]['extent_type'])
  end


  it "allows archival objects to be created with a date" do

    opts = {:dates => [{
         "date_type" => "single",
         "label" => "creation",
         "begin" => generate(:yyyy_mm_dd),
      }]}

    ao = ArchivalObject.create_from_json(
                                          build(:json_archival_object, opts),
                                          :repo_id => $repo_id)

    expect(ArchivalObject[ao[:id]].date.length).to eq(1)
    expect(ArchivalObject[ao[:id]].date[0].begin).to eq(opts[:dates][0]['begin'])
  end


  it "allows archival objects to be created with an instance" do
    instance = build(:json_instance)
    opts = {:instances => [instance]}

    ao = ArchivalObject.create_from_json(
                                         build(:json_archival_object, opts),
                                         :repo_id => $repo_id)

    expect(ArchivalObject[ao[:id]].instance.length).to eq(1)
    expect(ArchivalObject[ao[:id]].instance[0].instance_type).to eq(instance['instance_type'])
    expect(ArchivalObject.to_jsonmodel(ao[:id])['instances'][0]["sub_container"]["type_2"]).to eq(instance['sub_container']["type_2"])
  end


  it "will generate a ref_id if non is provided" do
    ao = ArchivalObject.create_from_json(build(:json_archival_object),
                                         :repo_id => $repo_id)

    expect(ArchivalObject[ao[:id]].ref_id).not_to be_nil
  end


  it "will generate a label if requested" do
    opts = {
      :title => "",
      :dates => [{
                   "date_type" => "single",
                   "label" => "creation",
                   "begin" => generate(:yyyy_mm_dd),
                 }]
    }

    ao = ArchivalObject.create_from_json(build(:json_archival_object, opts),
                                         :repo_id => $repo_id)

    expect(ArchivalObject[ao[:id]].display_string).not_to be_nil
  end


  it "throws an error if 'level' is 'otherlevel' and 'other level' isn't provided, but only in strict mode" do

    opts = {:level => "otherlevel", :other_level => nil}

    expect { ArchivalObject.create_from_json(
                                build(:json_archival_object, opts),
                                :repo_id => $repo_id)
    }.to raise_error(JSONModel::ValidationException)

    JSONModel::strict_mode(false)

    expect { ArchivalObject.create_from_json(
                                build(:json_archival_object, opts),
                                :repo_id => $repo_id)
    }.not_to raise_error

    JSONModel::strict_mode(true)

  end

  it "throws an error if you attempt to add a value to the archival_record_level" do

    opts = {:level => "HAMBURGER!"}

    expect { ArchivalObject.create_from_json(
                                build(:json_archival_object, opts),
                                :repo_id => $repo_id)
    }.to raise_error(JSONModel::ValidationException)

  end

  it "enforces ref_id uniqueness only within a resource" do
    res1 = create(:json_resource)

    create(:json_archival_object, {:ref_id => "the_same", :resource => {:ref => res1.uri}})

    expect {
      create(:json_archival_object, {:ref_id => "the_same", :resource => {:ref => res1.uri}})
    }.to raise_error(JSONModel::ValidationException)
  end


  it "can create an AO with a position set" do
    res1 = create(:json_resource)

    expect {
      create(:json_archival_object,
             {
               :ref_id => "the_same",
               :resource => {:ref => res1.uri},
               :position => 0
             })
    }.not_to raise_error
  end

  it "auto generates a 'label' based on the title (when no date)" do
    title = "Just a title"

    ao = ArchivalObject.create_from_json(
          build(:json_archival_object, {
            :title => title
          }),
          :repo_id => $repo_id)

    expect(ArchivalObject[ao[:id]].display_string).to eq(title)
  end

  it "auto generates a 'label' based on the date (when no title)" do
    # if an expression that will display
    date = build(:json_date)
    ao = ArchivalObject.create_from_json(
      build(:json_archival_object, {
        :title => nil,
        :dates => [date]
      }),
      :repo_id => $repo_id)

    expect(ArchivalObject[ao[:id]].display_string).to eq(date['expression'])

    # try with begin and end
    date = build(:json_date, :expression => nil)
    ao = ArchivalObject.create_from_json(
      build(:json_archival_object, {
        :title => nil,
        :dates => [date]
      }),
      :repo_id => $repo_id)

    expect(ArchivalObject[ao[:id]].display_string).to eq("#{date['begin']} - #{date['end']}")
  end

  it "auto generates a 'label' based on the date and title when both are present" do
    title = "Just a title"
    date = build(:json_date)

    ao = ArchivalObject.create_from_json(
      build(:json_archival_object, {
        :title => title,
        :dates => [date]
      }),
      :repo_id => $repo_id)

    expect(ArchivalObject[ao[:id]].display_string).to eq("#{title}, #{date['expression']}")
  end


  it "persistent_ids are stored within the context of the tree root where applicable" do
    note = build(:json_note_bibliography,
                 :content => ["a little note"],
                 :persistent_id => "something")

    resource = create_resource

    obj = ArchivalObject.create_from_json(build(:json_archival_object,
                                                'resource' => {'ref' => resource.uri},
                                                'notes' => [note]))


    expect(NotePersistentId.filter(:persistent_id => "something",
                            :parent_id => resource.id,
                            :parent_type => 'resource').count).to eq(1)
  end


  it "persistent_ids are stored within the context of the tree root where applicable" do
    note = build(:json_note_bibliography,
                 :content => ["a little note"],
                 :persistent_id => "something")

    resource = create_resource

    obj = ArchivalObject.create_from_json(build(:json_archival_object,
                                                'resource' => {'ref' => resource.uri},
                                                'notes' => [note]))


    ao_with_index = ArchivalObject.create_from_json(build(:json_archival_object,
                                                          'resource' => {'ref' => resource.uri},
                                                          'parent' => {'ref' => obj.uri},
                                                          'notes' => [build(:json_note_index,
                                                                            :items => [build(:json_note_index_item,
                                                                                             :reference => "something")])
                                                                     ]))

    expect(ArchivalObject.to_jsonmodel(ao_with_index).notes[0]['items'][0]['reference_ref']['ref']).to eq(obj.uri)
  end


  it "can re-save a record with long notes" do
    long_note = build(:json_note_text, :content => "a really long note" * 3000)
    id = ArchivalObject.create_from_json(build(:json_archival_object,
                                               'notes' => [build(:json_note_multipart,
                                                                 'type' => 'accruals',
                                                                 :subnotes => [long_note])])).id

    expect {
      ArchivalObject[id].save
    }.not_to raise_error
  end


  it "doesn't blow up when converting records with multiple notes" do
    recs = 5.times.map {
      ArchivalObject.create_from_json(build(:json_archival_object,
                                            'notes' => 10.times.map {
                                                          build(:json_note_multipart,
                                                              'type' => 'accruals',
                                                              :subnotes => [build(:json_note_text)])
                                                        }))
    }

    expect {
      ArchivalObject.sequel_to_jsonmodel(recs)
    }.not_to raise_error
  end

  it "you can add children" do
    resource = create(:json_resource)
    ao = ArchivalObject.create_from_json( build(:json_archival_object, :resource => {:ref => resource.uri}))

    archival_object_1 = build(:json_archival_object)
    archival_object_2 = build(:json_archival_object)

    children = JSONModel(:archival_record_children).from_hash({
      "children" => [archival_object_1, archival_object_2]
    })


    expect {
      ao.add_children(children)
    }.not_to raise_error

    ao = ArchivalObject.get_or_die(ao.id)
    expect(ao.children.all.length).to eq(2)
    # now add more!
    archival_object_3 = build(:json_archival_object)
    archival_object_4 = build(:json_archival_object)

    children = JSONModel(:archival_record_children).from_hash({
      "children" => [archival_object_3, archival_object_4]
    })

    expect {
      ao.add_children(children)
    }.not_to raise_error

  end

  it "won't let you set your parent to a resource that you're not in" do
    resource_a = create(:json_resource)
    resource_b = create(:json_resource)
    parent_in_resource_a = create(:json_archival_object, :resource => {:ref => resource_a.uri})

    expect {
    create(:json_archival_object,
           :parent => {:ref => parent_in_resource_a.uri},
           # absurd!
           :resource => {:ref => resource_b.uri})
    }.to raise_error(RuntimeError, /Consistency check failed/)
  end

  describe "slug tests" do
    it "autogenerates a slug via title when configured to generate by name" do
      AppConfig[:auto_generate_slugs_with_id] = false

      digital_object = ArchivalObject.create_from_json(build(:json_archival_object))


      digital_object_rec = ArchivalObject.where(:id => digital_object[:id]).first.update(:is_slug_auto => 1)

      expected_slug = digital_object_rec[:title].gsub(" ", "_")
                                           .gsub(/[&;?$<>#%{}|\\^~\[\]`\/@=:+,!]/, "")

      expect(digital_object_rec[:slug]).to eq(expected_slug)
    end

    it "autogenerates a slug via digital_object_id when configured to generate by id" do
      AppConfig[:auto_generate_slugs_with_id] = true

      digital_object = ArchivalObject.create_from_json(build(:json_archival_object))


      digital_object_rec = ArchivalObject.where(:id => digital_object[:id]).first.update(:is_slug_auto => 1)

      expected_slug = digital_object_rec[:ref_id].gsub(" ", "_")
                                                .gsub(/[&;?$<>#%{}|\\^~\[\]`\/@=:+,!]/, "")
                                                .gsub('"', '')
                                                .gsub('null', '')

      # numeric slugs will be prepended by an underscore
      if expected_slug =~ /^\d+$/
        expected_slug = "_#{expected_slug}"
      end

      expect(digital_object_rec[:slug]).to eq(expected_slug)
    end

    it "generates a slug for largetree if use_human_readable_URLs is set to true" do
      AppConfig[:use_human_readable_URLs] = true

      expect(SlugHelpers.get_slugged_url_for_largetree("ArchivalObject", $repo_id, "ao_slug")).to eq( AppConfig[:public_proxy_url] + "/archival_objects/ao_slug")
    end

    it "does not generate a slug for largetree if use_human_readable_URLs is set to false" do
      AppConfig[:use_human_readable_URLs] = false

      expect(SlugHelpers.get_slugged_url_for_largetree("ArchivalObject", $repo_id, "ao_slug").empty?).to eq( true )
    end

    describe "slug code does not run" do
      it "does not execute slug code when auto-gen on id and title is changed" do
        AppConfig[:auto_generate_slugs_with_id] = true

        archival_object = ArchivalObject.create_from_json(build(:json_archival_object, {:is_slug_auto => true}))

        expect(archival_object).to_not receive(:auto_gen_slug!)
        expect(SlugHelpers).to_not receive(:clean_slug)

        archival_object.update(:title => "foobar")
      end

      it "does not execute slug code when auto-gen on title and id is changed" do
        AppConfig[:auto_generate_slugs_with_id] = false

        archival_object = ArchivalObject.create_from_json(build(:json_archival_object, {:is_slug_auto => true}))

        expect(archival_object).to_not receive(:auto_gen_slug!)
        expect(SlugHelpers).to_not receive(:clean_slug)

        archival_object.update(:ref_id => "foobar")
      end
    end

    describe "slug code runs" do
      it "executes slug code when auto-gen on id and id is changed" do
        AppConfig[:auto_generate_slugs_with_id] = true

        archival_object = ArchivalObject.create_from_json(build(:json_archival_object, {:is_slug_auto => true}))

        expect(archival_object).to receive(:auto_gen_slug!)

        archival_object.update(:ref_id => 'foo')
      end

      it "executes slug code when auto-gen on title and title is changed" do
        AppConfig[:auto_generate_slugs_with_id] = false

        archival_object = ArchivalObject.create_from_json(build(:json_archival_object, {:is_slug_auto => true}))

        expect(archival_object).to receive(:auto_gen_slug!)

        archival_object.update(:title => "foobar")
      end

      it "executes slug code when autogen is turned on" do
        AppConfig[:auto_generate_slugs_with_id] = false
        archival_object = ArchivalObject.create_from_json(build(:json_archival_object, {:is_slug_auto => false}))

        expect(archival_object).to receive(:auto_gen_slug!)

        archival_object.update(:is_slug_auto => 1)
      end

      it "executes slug code when autogen is off and slug is updated" do
        archival_object = ArchivalObject.create_from_json(build(:json_archival_object, {:is_slug_auto => false}))

        expect(SlugHelpers).to receive(:clean_slug)

        archival_object.update(:slug => "snow white")
      end
    end

  end
end
