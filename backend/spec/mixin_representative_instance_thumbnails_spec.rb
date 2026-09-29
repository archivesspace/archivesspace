require 'spec_helper'
require_relative 'thumbnail_spec_helper'

describe 'RepresentativeInstanceThumbnails mixin' do
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
