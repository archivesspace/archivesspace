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

  it 'counts the component image of its own representative digital object as its image (ANW-3057)' do
    own = digital_object_with([])
    component = component_of(own, [image_file_version(:is_display_thumbnail => true)])
    resource = create(:json_resource, :instances => [representative_instance(own)])
    archival_object_in(resource, image_do)

    expect(thumbnail_for(Resource, resource)['record_uri']).to eq(component.uri)
  end

  it 'takes the first archival object in tree order, even when its image comes from a component (ANW-3057)' do
    resource = create(:json_resource)
    from_component = digital_object_with([])
    component = component_of(from_component, [image_file_version(:is_display_thumbnail => true)])
    archival_object_in(resource, from_component)
    archival_object_in(resource, image_do)

    expect(thumbnail_for(Resource, resource)['record_uri']).to eq(component.uri)
  end

  it 'shows the first generic icon when no representative instance has an image (ANW-3009)' do
    resource = create(:json_resource)
    archival_object_in(resource, icon_do)
    archival_object_in(resource, digital_object_with([link_file_version(:is_display_link => true)]))

    thumbnail = thumbnail_for(Resource, resource)
    expect(thumbnail['record_uri']).to eq(icon_do.uri)
    expect(thumbnail).not_to have_key('image_url')
  end

  it 'falls back to the images of its archival objects, in tree order, when the browser cannot display its own image (ANW-3089)' do
    own = image_do
    resource = create(:json_resource, :instances => [representative_instance(own)])
    first = image_do
    second = image_do
    archival_object_in(resource, first)
    archival_object_in(resource, icon_do)
    archival_object_in(resource, second)

    thumbnail = thumbnail_for(Resource, resource)
    expect(thumbnail['record_uri']).to eq(own.uri)
    expect(thumbnail['fallbacks'].map { |fallback| fallback['record_uri'] }).to eq([first.uri, second.uri])
  end

  it 'falls back to the image of a later archival object when the browser cannot display the image of the first one (ANW-3009)' do
    resource = create(:json_resource)
    document = digital_object_with([link_file_version(:is_display_thumbnail => true, :is_display_link => true)])
    later = image_do
    archival_object_in(resource, document)
    archival_object_in(resource, later)

    thumbnail = thumbnail_for(Resource, resource)
    expect(thumbnail['record_uri']).to eq(document.uri)
    expect(thumbnail['fallbacks'].map { |fallback| fallback['record_uri'] }).to eq([later.uri])
  end

  it 'offers at most AppConfig[:max_thumbnail_images] images' do
    allow(AppConfig).to receive(:[]).and_call_original
    allow(AppConfig).to receive(:[]).with(:max_thumbnail_images) { 2 }

    resource = create(:json_resource)
    digital_objects = (1..3).map { image_do }
    digital_objects.each { |digital_object| archival_object_in(resource, digital_object) }

    thumbnail = thumbnail_for(Resource, resource)
    expect(thumbnail['record_uri']).to eq(digital_objects.first.uri)
    expect(thumbnail['fallbacks'].map { |fallback| fallback['record_uri'] }).to eq([digital_objects[1].uri])
  end

  it 'lists a digital object once when it is both its own and an archival object representative instance' do
    own = image_do
    resource = create(:json_resource, :instances => [representative_instance(own)])
    archival_object_in(resource, own)

    expect(thumbnail_for(Resource, resource)).not_to have_key('fallbacks')
  end

  it 'shows the first generic icon of its archival objects when its own representative instance shows nothing' do
    unpublished = digital_object_with([image_file_version(:is_display_thumbnail => true)], :publish => false)
    resource = create(:json_resource, :instances => [representative_instance(unpublished)])
    archival_object_in(resource, icon_do)

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

  it 'ignores archival objects with an unpublished ancestor' do
    resource = create(:json_resource)
    unpublished = archival_object_in(resource, nil, :publish => false)
    child = archival_object_in(resource, nil, :parent => {'ref' => unpublished.uri})
    archival_object_in(resource, image_do, :parent => {'ref' => child.uri})
    later = image_do
    archival_object_in(resource, later)

    expect(thumbnail_for(Resource, resource)['record_uri']).to eq(later.uri)
  end

  it 'ignores archival objects with a suppressed ancestor' do
    resource = create(:json_resource)
    suppressed = archival_object_in(resource, nil)
    archival_object_in(resource, image_do, :parent => {'ref' => suppressed.uri})
    later = image_do
    archival_object_in(resource, later)
    ArchivalObject[suppressed.id].set_suppressed(true)

    expect(thumbnail_for(Resource, resource)['record_uri']).to eq(later.uri)
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
