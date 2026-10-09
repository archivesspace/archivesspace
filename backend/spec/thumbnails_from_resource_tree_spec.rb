require 'spec_helper'
require_relative 'thumbnail_spec_helper'

describe 'Thumbnails::FromResourceTree' do
  include ThumbnailSpecHelper

  let(:icon_do) { digital_object_with([link_file_version(:is_display_link => true)]) }

  def image_do
    digital_object_with([image_file_version(:is_display_thumbnail => true)])
  end

  def archival_object_in(resource, digital_object, opts = {})
    create(:json_archival_object, {
      :resource => {'ref' => resource.uri},
      :publish => true,
      :instances => digital_object ? [representative_instance(digital_object)] : [],
    }.merge(opts))
  end

  it 'shows the image of its own representative digital object' do
    own = image_do
    resource = create(:json_resource, :instances => [representative_instance(own)])
    archival_object_in(resource, image_do)

    expect(thumbnail_for(Resource, resource)['record_uri']).to eq(own.uri)
  end

  it 'looks through the representative instances of its archival objects, in tree order, for an image (ANW-3008)' do
    resource = create(:json_resource, :instances => [representative_instance(icon_do)])
    first = archival_object_in(resource, nil)
    archival_object_in(resource, image_do)
    nested = image_do
    archival_object_in(resource, nested, :parent => {'ref' => first.uri})

    thumbnail = thumbnail_for(Resource, resource)
    expect(thumbnail['record_uri']).to eq(nested.uri)
    expect(thumbnail).to have_key('image_url')
  end

  it 'shows the first generic icon when no representative instance has an image (ANW-3009)' do
    resource = create(:json_resource)
    archival_object_in(resource, icon_do)
    archival_object_in(resource, digital_object_with([link_file_version(:is_display_link => true)]))

    thumbnail = thumbnail_for(Resource, resource)
    expect(thumbnail['record_uri']).to eq(icon_do.uri)
    expect(thumbnail).not_to have_key('image_url')
  end

  it 'ignores unpublished archival objects' do
    resource = create(:json_resource)
    archival_object_in(resource, image_do, :publish => false)

    expect(thumbnail_for(Resource, resource)).to be_nil
  end

  it 'ignores suppressed archival objects' do
    resource = create(:json_resource)
    archival_object = archival_object_in(resource, image_do)
    ArchivalObject[archival_object.id].set_suppressed(true)

    expect(thumbnail_for(Resource, resource)).to be_nil
  end

  it 'gives each resource its own thumbnail when several are loaded at once' do
    own = image_do
    from_tree = image_do
    with_own_image = create(:json_resource, :instances => [representative_instance(own)])
    with_tree_image = create(:json_resource)
    archival_object_in(with_tree_image, from_tree)
    without_image = create(:json_resource)

    ids = [with_own_image.id, with_tree_image.id, without_image.id]
    jsons = Resource.sequel_to_jsonmodel(Resource.filter(:id => ids).all)
    thumbnails = jsons.to_h { |json| [json['uri'], json['thumbnail']] }

    expect(thumbnails[with_own_image.uri]['record_uri']).to eq(own.uri)
    expect(thumbnails[with_tree_image.uri]['record_uri']).to eq(from_tree.uri)
    expect(thumbnails[without_image.uri]).to be_nil
  end
end
