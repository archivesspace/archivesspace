require 'spec_helper'

describe 'Object graph filtering' do

  let!(:resource) {
    create(:json_resource, :publish => true)
  }

  let!(:series_1) {
    create(:json_archival_object, :resource => {:ref => resource.uri}, :publish => true, :title => "Series 1")
  }

  let!(:series_2) {
    create(:json_archival_object, :resource => {:ref => resource.uri}, :publish => true, :title => "Series 2")

  }

  let!(:series_1_child_1) {
    create(:json_archival_object,
           :resource => {:ref => resource.uri},
           :parent => {:ref => series_1.uri},
           :publish => true,
           :title => "Series 1 Child 1")
  }

  let!(:series_1_child_2) {
    create(:json_archival_object,
           :resource => {:ref => resource.uri},
           :parent => {:ref => series_1.uri},
           :publish => true,
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

  it "supports excluding items from the graph" do

    filters = {}
    filters[ArchivalObject] = ArchivalObject.exclude(:ref_id => 'EXCLUDE')

    og = Resource[resource.id].object_graph(filters)

    og.ids_for(ArchivalObject).should eq ([1,2,3,4,5])

  end

end
