require 'spec_helper'

describe 'ArchivalObject model' do

  it "allows archival objects to be created" do
    ao = ArchivalObject.create_from_json(
                                          build(
                                                :json_archival_object,
                                                :title => 'A new archival object'
                                                ),
                                          :repo_id => $repo_id)

    ArchivalObject[ao[:id]].title.should eq('A new archival object')
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
    ArchivalObject[ao[:id]].extent.length.should eq(1)
    ArchivalObject[ao[:id]].extent[0].extent_type.should eq(opts[:extents][0]['extent_type'])
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

    ArchivalObject[ao[:id]].date.length.should eq(1)
    ArchivalObject[ao[:id]].date[0].begin.should eq(opts[:dates][0]['begin'])
  end


  it "allows archival objects to be created with an instance" do
    instance = build(:json_instance)
    opts = {:instances => [instance]}
    
    ao = ArchivalObject.create_from_json(
                                         build(:json_archival_object, opts),
                                         :repo_id => $repo_id)

    ArchivalObject[ao[:id]].instance.length.should eq(1)
    ArchivalObject[ao[:id]].instance[0].instance_type.should eq(instance['instance_type'])
    ArchivalObject.to_jsonmodel(ao[:id])['instances'][0]["sub_container"]["type_2"].should eq(instance['sub_container']["type_2"])
  end


  it "will generate a ref_id if non is provided" do
    ao = ArchivalObject.create_from_json(build(:json_archival_object),
                                         :repo_id => $repo_id)

    ArchivalObject[ao[:id]].ref_id.should_not be_nil
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

    ArchivalObject[ao[:id]].display_string.should_not be_nil
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
    }.to_not raise_error
    
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
    }.to_not raise_error
  end

  it "auto generates a 'label' based on the title (when no date)" do
    title = "Just a title"

    ao = ArchivalObject.create_from_json(
          build(:json_archival_object, {
            :title => title
          }),
          :repo_id => $repo_id)

    ArchivalObject[ao[:id]].display_string.should eq(title)
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

    ArchivalObject[ao[:id]].display_string.should eq(date['expression'])

    # try with begin and end
    date = build(:json_date, :expression => nil)
    ao = ArchivalObject.create_from_json(
      build(:json_archival_object, {
        :title => nil,
        :dates => [date]
      }),
      :repo_id => $repo_id)

    ArchivalObject[ao[:id]].display_string.should eq("#{date['begin']} - #{date['end']}")
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

    ArchivalObject[ao[:id]].display_string.should eq("#{title}, #{date['expression']}")
  end


  it "persistent_ids are stored within the context of the tree root where applicable" do
    note = build(:json_note_bibliography,
                 :content => ["a little note"],
                 :persistent_id => "something")

    resource = create_resource

    obj = ArchivalObject.create_from_json(build(:json_archival_object,
                                                'resource' => {'ref' => resource.uri},
                                                'notes' => [note]))


    NotePersistentId.filter(:persistent_id => "something",
                            :parent_id => resource.id,
                            :parent_type => 'resource').count.should eq(1)
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

    ArchivalObject.to_jsonmodel(ao_with_index).notes[0]['items'][0]['reference_ref']['ref'].should eq(obj.uri)
  end


  it "can re-save a record with long notes" do
    long_note = build(:json_note_text, :content => "a really long note" * 3000)
    id = ArchivalObject.create_from_json(build(:json_archival_object,
                                               'notes' => [build(:json_note_multipart,
                                                                 'type' => 'accruals',
                                                                 :subnotes => [long_note])])).id

    expect {
      ArchivalObject[id].save
    }.to_not raise_error
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
    }.to_not raise_error
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
    }.to_not raise_error
    
    ao = ArchivalObject.get_or_die(ao.id)
    ao.children.all.length.should == 2
    # now add more!
    archival_object_3 = build(:json_archival_object)
    archival_object_4 = build(:json_archival_object)

    children = JSONModel(:archival_record_children).from_hash({
      "children" => [archival_object_3, archival_object_4]
    })
    
    expect {
      ao.add_children(children) 
    }.to_not raise_error
  
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

end
