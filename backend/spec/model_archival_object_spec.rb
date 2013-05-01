require 'spec_helper'

describe 'ArchivalObject model' do

  it "Allows archival objects to be created" do
    ao = ArchivalObject.create_from_json(
                                          build(
                                                :json_archival_object,
                                                :title => 'A new archival object'
                                                ),
                                          :repo_id => $repo_id)

    ArchivalObject[ao[:id]].title.should eq('A new archival object')
  end


  it "Allow multiple archival objects to be created without conflicts" do
    create_list(:json_archival_object, 5)
  end


  it "Allows archival objects to be created with an extent" do
    
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


  it "Allows archival objects to be created with a date" do
    
    opts = {:dates => [{
         "date_type" => "single",
         "label" => "creation",
         "begin" => generate(:yyyy_mm_dd),
         "end" => generate(:yyyy_mm_dd),
      }]}
    
    ao = ArchivalObject.create_from_json(
                                          build(:json_archival_object, opts),
                                          :repo_id => $repo_id)

    ArchivalObject[ao[:id]].date.length.should eq(1)
    ArchivalObject[ao[:id]].date[0].begin.should eq(opts[:dates][0]['begin'])
  end


  it "Allows archival objects to be created with an instance" do
    
    opts = {:instances => [{
         "instance_type" => generate(:instance_type),
         "container" => build(:json_container)
       }]}
    
       ao = ArchivalObject.create_from_json(
                                             build(:json_archival_object, opts),
                                             :repo_id => $repo_id)

    ArchivalObject[ao[:id]].instance.length.should eq(1)
    ArchivalObject[ao[:id]].instance[0].instance_type.should eq(opts[:instances][0]['instance_type'])
    ArchivalObject[ao[:id]].instance[0].container.first.type_1.should eq(opts[:instances][0]['container']['type_1'])
  end


  it "will generate a ref_id if non is provided" do
    ao = ArchivalObject.create_from_json(build(:json_archival_object),
                                         :repo_id => $repo_id)

    ArchivalObject[ao[:id]].ref_id.should_not be_nil
  end


  it "throws an error if 'level' is 'otherlevel' and 'other level' isn't provided" do

    opts = {:level => "otherlevel", :other_level => nil}

    expect { ArchivalObject.create_from_json(
                                build(:json_archival_object, opts),
                                :repo_id => $repo_id)
    }.to raise_error
  end


  it "enforces ref_id uniqueness only within a resource" do
    res1 = create(:resource, {:repo_id => $repo_id})
    res2 = create(:resource, {:repo_id => $repo_id})

    create(:archival_object, {:ref_id => "the same", :root_record_id => res1.id, :repo_id => $repo_id})
    create(:archival_object, {:ref_id => "the same", :root_record_id => nil, :repo_id => $repo_id})

    expect {
      create(:archival_object, {:ref_id => "the same", :root_record_id => res1.id, :repo_id => $repo_id})
    }.to raise_error(Sequel::ValidationFailed)

    expect {
      create(:archival_object, {:ref_id => "the same", :root_record_id => res2.id, :repo_id => $repo_id})
    }.to_not raise_error

    expect {
      create(:archival_object, {:ref_id => "the same", :root_record_id => nil, :repo_id => $repo_id})
    }.to_not raise_error
  end


  it "auto generates a 'label' based on the title (when no date)" do
    title = "Just a title"

    ao = ArchivalObject.create_from_json(
          build(:json_archival_object, {
            :title => title
          }),
          :repo_id => $repo_id)

    ArchivalObject[ao[:id]].label.should eq(title)
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

    ArchivalObject[ao[:id]].label.should eq(date['expression'])

    # try with begin and end
    date = build(:json_date, :expression => nil)
    ao = ArchivalObject.create_from_json(
      build(:json_archival_object, {
        :title => nil,
        :dates => [date]
      }),
      :repo_id => $repo_id)

    ArchivalObject[ao[:id]].label.should eq("#{date['begin']} - #{date['end']}")
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

    ArchivalObject[ao[:id]].label.should eq("#{title}, #{date['expression']}")
  end

end
