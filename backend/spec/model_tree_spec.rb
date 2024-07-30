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

    expect(Resource[resource.id].ordered_records.map {|r| r['ref']}).to eq(ordered_uris)
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

    expect(Resource[resource.id].ordered_records.map {|r| r['ref']}).to eq(ordered_uris)
  end

  it "excludes suppressed records" do
    series_1.suppress

    ordered_uris = [
      resource.uri,
      series_2.uri,
      series_2_child_1.uri,
      series_2_child_2.uri,
    ]

    expect(Resource[resource.id].ordered_records.map {|r| r['ref']}).to eq(ordered_uris)
  end

  it "excludes unpublished root records" do
    resource.publish = false
    resource.save

    expect(Resource[resource.id].ordered_records).to eq([])
  end

  it "excludes suppressed root records" do
    resource.suppress

    expect(Resource[resource.id].ordered_records).to eq([])
  end


  it "knows if the top record has children" do
    expect(Resource[resource.id].children?).to be_truthy
    expect(Resource[create(:json_resource).id].children?).to be_falsey
  end

  it "creates the bulk updater tree" do
    quick_tree = Resource[resource.id].bulk_archival_object_updater_quick_tree
    expect(quick_tree[:title]).to eq(Resource[resource.id].title)
    expect(quick_tree[:uri]).to eq(Resource[resource.id].uri)
    expect(quick_tree[:identifier]).to eq(Identifiers.format(Identifiers.parse(Resource[resource.id].identifier)))
    expect(quick_tree[:children].map {|r| r[:uri]} - Resource[resource.id].ordered_records.map {|r| r['ref']}).to eq([])
  end
end
