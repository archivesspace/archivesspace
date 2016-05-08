require 'spec_helper'
require_relative 'container_spec_helper'
require_relative 'factories'

describe 'Extent Calculator model' do

  def create_container_profile(name, depth, height, width, dim_units, ext_dim)
    create(:json_container_profile, :name => name,
           :depth => depth,
           :height => height,
           :width => width,
           :dimension_units => dim_units,
           :extent_dimension => ext_dim)
  end


  def create_containers(container_profile, num = 1)
    containers = []
    num.times do |n|
      containers << create(:json_top_container, 'container_profile' => {'ref' => container_profile.uri})
    end
    containers
  end


  def create_ao_with_instances(resource, parent, containers = [])
    create(:json_archival_object,
           "resource" => {"ref" => resource.uri},
           "parent" => {"ref" => parent.uri},
           "instances" => containers.map{|con| build_instance(con)})
  end


  before(:each) do
    stub_barcode_length(0, 255)

    allow(AppConfig).to receive(:has_key?).with(:container_management_extent_calculator).and_return(false)
  end

  let (:inch_to_cm) { 2.54 }
  let (:inch_to_feet) { 1.0/12.0 }
  let (:bigbox_extent) { 15 }
  let (:bigbox_profile) { create_container_profile("big box", "18", "12", bigbox_extent.to_s, "inches", "width") }
  let (:a_bigbox) { create(:json_top_container, 'container_profile' => {'ref' => bigbox_profile.uri}) }
  let (:a_box_without_a_profile) { create(:json_top_container, 'container_profile' => nil) }

  let (:big_box_name) { "big box [18d, 12h, 15w inches] extent measured by width" }
  let (:tiny_box_name) { "tiny box [1.5d, 4.5h, 3w centimeters] extent measured by depth" }


  it "can calculate the total extent for a resource" do
    (resource, grandparent, parent, child) = create_tree(a_bigbox)
    ext_cal = ExtentCalculator.new(resource)
    ext_cal.total_extent.should eq(bigbox_extent)
  end


  it "can tell you the dimension units it used" do
    (resource, grandparent, parent, child) = create_tree(a_bigbox)
    ext_cal = ExtentCalculator.new(resource)
    ext_cal.units.should eq(:inches)
  end


  it "allows you to change the dimension units" do
    (resource, grandparent, parent, child) = create_tree(a_bigbox)
    ext_cal = ExtentCalculator.new(resource)
    ext_cal.units = :centimeters
    ext_cal.total_extent.should eq(bigbox_extent*inch_to_cm)
    ext_cal.units = :feet
    ext_cal.total_extent.should eq(bigbox_extent*inch_to_feet)
  end


  it "tells you how many of each kind of container it found" do
    (resource, grandparent, parent, child) = create_tree(a_bigbox)
    ext_cal = ExtentCalculator.new(resource)
    ext_cal.containers("big box [18d, 12h, 15w inches] extent measured by width")[:count].should eq(1)
  end


  it "deals with large resources" do
    (resource, grandparent, parent, child) = create_tree(a_bigbox)
    boxes = create_containers(bigbox_profile, 100)
    create_ao_with_instances(resource, child, boxes)
    ext_cal = ExtentCalculator.new(resource)
    ext_cal.total_extent.should eq(bigbox_extent*101)
  end


  it "doesn't mind different kinds of containers" do
    tinybox_profile = create_container_profile("tiny box", "1.5", "4.5", "3", "centimeters", "depth")
    (resource, grandparent, parent, child) = create_tree(a_bigbox)
    boxes = create_containers(bigbox_profile, 10)
    baby = create_ao_with_instances(resource, child, boxes)
    tiny_boxes = create_containers(tinybox_profile, 21)
    create_ao_with_instances(resource, baby, tiny_boxes)

    ext_cal = ExtentCalculator.new(resource)
    ext_cal.units = :centimeters
    ext_cal.total_extent.should eq(bigbox_extent*11*inch_to_cm+21*1.5)
    ext_cal.containers(big_box_name)[:count].should eq(11)
    ext_cal.containers(big_box_name)[:extent].should eq(bigbox_extent*11*inch_to_cm)
    ext_cal.containers(tiny_box_name)[:count].should eq(21)
    ext_cal.containers(tiny_box_name)[:extent].should eq(21*1.5)
  end


  it "doesn't count containers twice" do
    (resource, grandparent, parent, child) = create_tree(a_bigbox)
    create_ao_with_instances(resource, child, [a_bigbox])
    ext_cal = ExtentCalculator.new(resource)
    ext_cal.total_extent.should eq(bigbox_extent)
  end


  it "can calculate extent for subtrees" do
    (resource, grandparent, parent, child) = create_tree(a_bigbox)
    boxes = create_containers(bigbox_profile, 10)
    baby = create_ao_with_instances(resource, child, boxes)
    more_boxes = create_containers(bigbox_profile, 10)
    egg = create_ao_with_instances(resource, baby, more_boxes)
    ext_cal = ExtentCalculator.new(ArchivalObject[baby.id])
    ext_cal.total_extent.should eq(bigbox_extent*20)
    ext_cal = ExtentCalculator.new(ArchivalObject[egg.id])
    ext_cal.total_extent.should eq(bigbox_extent*10)
  end


  it "can provide a hash rendering of itself" do
    tinybox_profile = create_container_profile("tiny box", "1.5", "4.5", "3", "centimeters", "depth")
    (resource, grandparent, parent, child) = create_tree(a_bigbox)
    boxes = create_containers(bigbox_profile, 10)
    baby = create_ao_with_instances(resource, child, boxes)
    tiny_boxes = create_containers(tinybox_profile, 21)
    create_ao_with_instances(resource, baby, tiny_boxes)
    
    ext_cal = ExtentCalculator.new(ArchivalObject[parent.id])
    ext_cal.units = :centimeters

    ec_hash = ext_cal.to_hash
    ec_hash[:container_count].should eq(32)
  end


  it "objects if you try to set a unit it doesn't recognize" do
    (resource, grandparent, parent, child) = create_tree(a_bigbox)
    ext_cal = ExtentCalculator.new(resource)
    expect {
      ext_cal.units = :cubits
    }.to raise_error(RuntimeError)
  end


  it "warns if it finds one or more containers that don't have container profiles" do
    (resource, grandparent, parent, child) = create_tree(a_box_without_a_profile)
    ext_cal = ExtentCalculator.new(ArchivalObject[child.id])
    ext_cal.to_hash[:container_without_profile_count].should eq(1)    
  end


  it "objects if told to be strict and it finds a container without a container profile" do
    (resource, grandparent, parent, child) = create_tree(a_box_without_a_profile)
    expect {
      ext_cal = ExtentCalculator.new(ArchivalObject[child.id], true)
    }.to raise_error(RuntimeError)
  end


  it "supports a config option to set the unit" do
    allow(AppConfig).to receive(:has_key?).with(:container_management_extent_calculator).and_return(true)
    allow(AppConfig).to receive(:[]).with(:container_management_extent_calculator).and_return({:unit => :centimeters})

    (resource, grandparent, parent, child) = create_tree(a_bigbox)
    ext_cal = ExtentCalculator.new(resource)
    ext_cal.units.should eq(:centimeters)
    ext_cal.total_extent.should eq(bigbox_extent*inch_to_cm)
  end


  it "supports a config option to set the number of decimal places to show in the report" do
    allow(AppConfig).to receive(:has_key?).with(:container_management_extent_calculator).and_return(true)
    allow(AppConfig).to receive(:[]).with(:container_management_extent_calculator).and_return({:decimal_places => 4})

    (resource, grandparent, parent, child) = create_tree(a_bigbox)
    ext_cal = ExtentCalculator.new(resource)
    ext_cal.units = :meters
    ext_cal.total_extent.should eq((bigbox_extent*inch_to_cm/100).round(4))
  end


  it "can calculate extent as a volume if so configured" do
    allow(AppConfig).to receive(:has_key?).with(:container_management_extent_calculator).and_return(true)
    allow(AppConfig).to receive(:[]).with(:container_management_extent_calculator).and_return({:report_volume => true,
                                                                                               :unit => :meters,
                                                                                               :decimal_places => 3})

    metric_box_profile = create_container_profile("metric box", "120", "120", "90", "centimeters", "depth")
    metric_box = create(:json_top_container, 'container_profile' => {'ref' => metric_box_profile.uri})
    (resource, grandparent, parent, child) = create_tree(metric_box)

    metric_box_volume_in_cubic_meters = metric_box_profile.width.to_f *
                                        metric_box_profile.height.to_f *
                                        metric_box_profile.depth.to_f / 1000000

    ext_cal = ExtentCalculator.new(resource)

    ext_cal.total_extent.should eq(metric_box_volume_in_cubic_meters.round(3))
  end


  it "behaves nicely if there are no containers to count" do
    accession = create_accession()
    ext_cal = ExtentCalculator.new(accession)
    ext_cal.total_extent.should eq(0)
  end

end
