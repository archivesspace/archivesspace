require 'spec_helper'

describe 'Object graph filtering' do

  let!(:resource) {
    create(:json_resource,
           :publish => true,
           :extents => [{"portion" => "whole", "number" => "BILLIONS", "extent_type" => "reels"}])
  }

  let!(:series_1) {
    create(:json_archival_object, :resource => {:ref => resource.uri}, :publish => false, :title => "Series 1")
  }

  let!(:series_2) {
    create(:json_archival_object, :resource => {:ref => resource.uri}, :publish => true, :title => "Series 2")

  }

  let!(:series_1_child_1) {
    create(:json_archival_object,
           :resource => {:ref => resource.uri},
           :parent => {:ref => series_1.uri},
           :publish => false,
           :title => "Series 1 Child 1",
           :extents => [{"portion" => "whole", "number" => "ONE", "extent_type" => "reels"}])
  }

  let!(:series_1_child_2) {
    create(:json_archival_object,
           :resource => {:ref => resource.uri},
           :parent => {:ref => series_1.uri},
           :publish => false,
           :title => "Series 1 Child 2")
  }

  let!(:series_2_child_1) {
    create(:json_archival_object,
           :resource => {:ref => resource.uri},
           :parent => {:ref => series_2.uri},
           :publish => true,
           :title => "Series 2 Child 1")
  }

  let!(:series_2_child_2) {
    create(:json_archival_object,
           :resource => {:ref => resource.uri},
           :parent => {:ref => series_2.uri},
           :publish => true,
           :ref_id => 'EXCLUDE',
           :title => "Series 2 Child 2")
  }

  it "supports excluding items" do
    filters = {}
    filters[ArchivalObject] = ArchivalObject.exclude(:ref_id => 'EXCLUDE')

    og = Resource[resource.id].object_graph(filters)

    og.ids_for(ArchivalObject).length.should eq (5)
  end


  it "supports excluding items based on multiple criteria" do
    filters = {}
    filters[ArchivalObject] = ArchivalObject.exclude(:ref_id => 'EXCLUDE')
                                            .filter(:publish => 1)

    og = Resource[resource.id].object_graph(filters)

    og.ids_for(ArchivalObject).length.should eq (2)
  end


  it "supports excluding nested records" do
    filters = {}
    filters[Extent] = Extent.exclude(:number => 'BILLIONS')

    og = Resource[resource.id].object_graph(filters)

    og.ids_for(Extent).length.should eq (1)
  end


  it "supports multiple model filters" do
    filters = {}
    filters[Extent] = Extent.filter(:number => 'ONE')
    filters[ArchivalObject] = ArchivalObject.filter(:publish => 0)

    og = Resource[resource.id].object_graph(filters)

    og.ids_for(ArchivalObject).length.should eq (3)
    og.ids_for(Extent).length.should eq (1)
  end
end
