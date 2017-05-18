require 'spec_helper'

describe 'Tree mixins' do

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
           :title => "Series 2 Child 2")
  }

  it "returns ordered records" do
    ordered_uris = [
      resource.uri,
      series_1.uri,
      series_1_child_1.uri,
      series_1_child_2.uri,
      series_2.uri,
      series_2_child_1.uri,
      series_2_child_2.uri,
    ]

    Resource[resource.id].ordered_records.map {|r| r['ref']}.should eq(ordered_uris)
  end

  it "excludes unpublished records" do
    series_1.publish = false
    series_1.save

    ordered_uris = [
      resource.uri,
      series_2.uri,
      series_2_child_1.uri,
      series_2_child_2.uri,
    ]

    Resource[resource.id].ordered_records.map {|r| r['ref']}.should eq(ordered_uris)
  end

  it "excludes suppressed records" do
    series_1.suppress

    ordered_uris = [
      resource.uri,
      series_2.uri,
      series_2_child_1.uri,
      series_2_child_2.uri,
    ]

    Resource[resource.id].ordered_records.map {|r| r['ref']}.should eq(ordered_uris)
  end

  it "excludes unpublished root records" do
    resource.publish = false
    resource.save

    Resource[resource.id].ordered_records.should eq([])
  end

  it "excludes suppressed root records" do
    resource.suppress

    Resource[resource.id].ordered_records.should eq([])
  end


  it "knows if the top record has children" do
    Resource[resource.id].children?.should be true
    Resource[create(:json_resource).id].children?.should be false
  end

end
