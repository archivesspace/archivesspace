require 'spec_helper'
require_relative 'thumbnail_spec_helper'

describe 'Thumbnails::FromRepresentativeInstance' do
  include ThumbnailSpecHelper

  shared_examples 'a record with a representative instance thumbnail' do |model, factory|
    it 'shows the thumbnail of the representative digital object, linked to the digital object record (ANW-3008)' do
      digital_object = digital_object_with([image_file_version(:is_display_thumbnail => true, :caption => 'DO caption'),
                                            link_file_version(:is_display_link => true)])
      other = digital_object_with([image_file_version(:is_display_thumbnail => true)])
      record = create(factory, :instances => [representative_instance(other, false),
                                              representative_instance(digital_object)])

      thumbnail = thumbnail_for(model, record)
      expect(thumbnail['image_url']).to eq(DigitalObject.to_jsonmodel(digital_object.id)['thumbnail']['image_url'])
      expect(thumbnail['record_uri']).to eq(digital_object.uri)
      expect(thumbnail['caption']).to eq('DO caption')
      expect(thumbnail).not_to have_key('link_url')
    end

    it 'shows the generic icon of the representative digital object (ANW-3009)' do
      digital_object = digital_object_with([link_file_version(:is_display_link => true)])
      record = create(factory, :instances => [representative_instance(digital_object)])

      thumbnail = thumbnail_for(model, record)
      expect(thumbnail).not_to have_key('image_url')
      expect(thumbnail['record_uri']).to eq(digital_object.uri)
    end

    it 'shows nothing without a representative instance' do
      digital_object = digital_object_with([image_file_version(:is_display_thumbnail => true)])
      record = create(factory, :instances => [representative_instance(digital_object, false)])

      expect(thumbnail_for(model, record)).to be_nil
    end

    it 'shows nothing for an unpublished representative digital object' do
      digital_object = digital_object_with([image_file_version(:is_display_thumbnail => true)], :publish => false)
      record = create(factory, :instances => [representative_instance(digital_object)])

      expect(thumbnail_for(model, record)).to be_nil
    end

    it 'shows nothing for a suppressed representative digital object' do
      digital_object = digital_object_with([image_file_version(:is_display_thumbnail => true)])
      record = create(factory, :instances => [representative_instance(digital_object)])
      DigitalObject[digital_object.id].set_suppressed(true)

      expect(thumbnail_for(model, record)).to be_nil
    end

    context 'when the representative digital object a digital object component with a dislpay thumbnail file version (ANW-3057)' do
      it 'shows the image of its first digital object component in tree order with a diplay thumbnail file version, linked to that component' do
        digital_object = digital_object_with([])
        first = component_of(digital_object, [])
        nested = component_of(digital_object, [image_file_version(:is_display_thumbnail => true, :caption => 'Page caption')],
                              :parent => {'ref' => first.uri})
        component_of(digital_object, [image_file_version(:is_display_thumbnail => true)])
        record = create(factory, :instances => [representative_instance(digital_object)])

        thumbnail = thumbnail_for(model, record)
        expect(thumbnail['image_url']).to eq(DigitalObjectComponent.to_jsonmodel(nested.id)['thumbnail']['image_url'])
        expect(thumbnail['record_uri']).to eq(nested.uri)
        expect(thumbnail['caption']).to eq('Page caption')
        expect(thumbnail['digital_object_type']).to eq('still_image')
        expect(thumbnail).not_to have_key('link_url')
      end

      it 'captions the component image with the display string of the component, without captions' do
        digital_object = digital_object_with([])
        component = component_of(digital_object, [image_file_version(:is_display_thumbnail => true)])
        record = create(factory, :instances => [representative_instance(digital_object)])

        expect(thumbnail_for(model, record)['caption']).to eq(DigitalObjectComponent.to_jsonmodel(component.id)['display_string'])
      end

      it 'prefers the component image over the generic icon of the digital object' do
        digital_object = digital_object_with([link_file_version(:is_display_link => true)])
        component = component_of(digital_object, [image_file_version(:is_display_thumbnail => true)])
        record = create(factory, :instances => [representative_instance(digital_object)])

        thumbnail = thumbnail_for(model, record)
        expect(thumbnail).to have_key('image_url')
        expect(thumbnail['record_uri']).to eq(component.uri)
      end

      it 'ignores unpublished and suppressed components' do
        digital_object = digital_object_with([link_file_version(:is_display_link => true)])
        component_of(digital_object, [image_file_version(:is_display_thumbnail => true)], :publish => false)
        suppressed = component_of(digital_object, [image_file_version(:is_display_thumbnail => true)])
        DigitalObjectComponent[suppressed.id].set_suppressed(true)
        record = create(factory, :instances => [representative_instance(digital_object)])

        thumbnail = thumbnail_for(model, record)
        expect(thumbnail).not_to have_key('image_url')
        expect(thumbnail['record_uri']).to eq(digital_object.uri)
      end

      it 'shows nothing when no component has an image either' do
        digital_object = digital_object_with([])
        component_of(digital_object, [link_file_version(:is_display_link => true)])
        record = create(factory, :instances => [representative_instance(digital_object)])

        expect(thumbnail_for(model, record)).to be_nil
      end
    end

    it 'prefers to show the display thumbnail of the digital object over the display thumbnail of its components, linked to the digital object' do
      digital_object = digital_object_with([image_file_version(:is_display_thumbnail => true)])
      component_of(digital_object, [image_file_version(:is_display_thumbnail => true)])
      record = create(factory, :instances => [representative_instance(digital_object)])

      thumbnail = thumbnail_for(model, record)
      expect(thumbnail['image_url']).to eq(DigitalObject.to_jsonmodel(digital_object.id)['thumbnail']['image_url'])
      expect(thumbnail['record_uri']).to eq(digital_object.uri)
    end

    it 'is reindexed when a component of its representative digital object changes (ANW-3057)' do
      digital_object = digital_object_with([])
      record = create(factory, :instances => [representative_instance(digital_object)])
      mtime = model[record.id].system_mtime

      ArchivesSpaceService.wait(:long)
      component_of(digital_object, [image_file_version(:is_display_thumbnail => true)])

      expect(model[record.id].system_mtime).to be > mtime
    end

    it 'is reindexed when a component of its representative digital object is suppressed or unsuppressed (ANW-3057)' do
      digital_object = digital_object_with([])
      component = component_of(digital_object, [image_file_version(:is_display_thumbnail => true)])
      record = create(factory, :instances => [representative_instance(digital_object)])

      [true, false].each do |suppressed|
        mtime = model[record.id].system_mtime
        ArchivesSpaceService.wait(:long)
        DigitalObjectComponent[component.id].set_suppressed(suppressed)

        expect(model[record.id].system_mtime).to be > mtime
      end
    end
  end

  describe 'accessions' do
    it_behaves_like 'a record with a representative instance thumbnail', Accession, :json_accession
  end

  describe 'archival objects' do
    it_behaves_like 'a record with a representative instance thumbnail', ArchivalObject, :json_archival_object
  end

  describe 'resources' do
    it_behaves_like 'a record with a representative instance thumbnail', Resource, :json_resource
  end
end
