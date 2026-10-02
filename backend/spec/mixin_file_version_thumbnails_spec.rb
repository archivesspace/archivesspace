require 'spec_helper'
require_relative 'thumbnail_spec_helper'

describe 'FileVersionThumbnails mixin' do
  include ThumbnailSpecHelper

  # The including group defines record_with(file_versions, opts = {}), which creates a published record
  # with those file versions (opts[:digital_object_type] sets the type of its Digital Object), and
  # caption_fallback(record).
  shared_examples 'a record with a file version thumbnail' do |model|
    it 'shows the thumbnail from its own file versions, with the type of its digital object' do
      thumbnail_fv = image_file_version(:is_display_thumbnail => true, :caption => 'Thumbnail caption')
      link_fv = link_file_version(:is_display_link => true)
      record = record_with([link_file_version, thumbnail_fv, link_fv], :digital_object_type => 'moving_image')

      expect(thumbnail_for(model, record)).to eq(
        'image_url' => thumbnail_fv['file_uri'],
        'link_url' => link_fv['file_uri'],
        'caption' => 'Thumbnail caption',
        'digital_object_type' => 'moving_image',
      )
    end

    it 'falls back to the record for the caption' do
      record = record_with([image_file_version(:is_display_thumbnail => true)])

      expect(thumbnail_for(model, record)['caption']).to eq(caption_fallback(record))
    end

    it 'gives each record its own thumbnail when several are loaded at once' do
      with_image = record_with([image_file_version(:is_display_thumbnail => true)])
      with_icon = record_with([link_file_version(:is_display_link => true)], :digital_object_type => 'text')
      without = record_with([link_file_version])

      jsons = model.sequel_to_jsonmodel(model.filter(:id => [with_image.id, with_icon.id, without.id]).all)
      thumbnails = jsons.to_h { |json| [json['uri'], json['thumbnail']] }

      expect(thumbnails[with_image.uri]).to have_key('image_url')
      expect(thumbnails[with_icon.uri]).not_to have_key('image_url')
      expect(thumbnails[with_icon.uri]['digital_object_type']).to eq('text')
      expect(thumbnails[without.uri]).to be_nil
    end

    describe 'no fallback display link' do
      it 'does not mark a display link when the record is created' do
        record = record_with([link_file_version(:is_display_thumbnail => true), link_file_version, link_file_version])

        file_versions = model.to_jsonmodel(record.id)['file_versions']
        expect(file_versions.map { |fv| fv['is_display_link'] }).to eq([false, false, false])
        expect(thumbnail_for(model, record)).not_to have_key('link_url')
      end

      it 'does not mark a display link when the record is updated' do
        record = record_with([link_file_version(:is_display_thumbnail => true)])
        json = model.to_jsonmodel(record.id)
        json['file_versions'] << link_file_version.to_hash
        model[record.id].update_from_json(json)

        file_versions = model.to_jsonmodel(record.id)['file_versions']
        expect(file_versions.map { |fv| fv['is_display_link'] }).to eq([false, false])
        expect(thumbnail_for(model, record)).not_to have_key('link_url')
      end
    end
  end

  describe 'digital objects' do
    it_behaves_like 'a record with a file version thumbnail', DigitalObject do
      def record_with(file_versions, opts = {})
        digital_object_with(file_versions, opts)
      end

      def caption_fallback(record)
        DigitalObject.to_jsonmodel(record.id)['title']
      end
    end
  end

  describe 'digital object components' do
    it_behaves_like 'a record with a file version thumbnail', DigitalObjectComponent do
      def record_with(file_versions, opts = {})
        parent = digital_object_with([], :digital_object_type => opts.fetch(:digital_object_type, 'still_image'))
        create(:json_digital_object_component,
               :digital_object => {'ref' => parent.uri},
               :title => 'Component title',
               :dates => [],
               :publish => true,
               :file_versions => file_versions)
      end

      def caption_fallback(record)
        DigitalObjectComponent.to_jsonmodel(record.id)['display_string']
      end
    end
  end
end
