require 'spec_helper'
require_relative 'thumbnail_spec_helper'

describe 'Thumbnails::Rules' do
  include ThumbnailSpecHelper

  def thumbnail(file_versions, title = 'The title', digital_object_type = 'still_image')
    Thumbnails::Rules.thumbnail_for_file_versions(file_versions.map(&:to_hash), title, digital_object_type)
  end

  describe 'thumbnail_for_file_versions' do
    it 'shows the display thumbnail image linked to the display link file version' do
      thumbnail_fv = image_file_version(:is_display_thumbnail => true, :caption => 'Thumbnail caption')
      link_fv = link_file_version(:is_display_link => true, :caption => 'Link caption')

      expect(thumbnail([link_file_version, thumbnail_fv, link_fv])).to eq(
        'image_url' => thumbnail_fv['file_uri'],
        'link_url' => link_fv['file_uri'],
        'caption' => 'Thumbnail caption',
        'digital_object_type' => 'still_image',
      )
    end

    it 'shows a display thumbnail image without a link when there is no display link (ANW-3005)' do
      thumbnail_fv = image_file_version(:is_display_thumbnail => true)

      result = thumbnail([thumbnail_fv, link_file_version])
      expect(result['image_url']).to eq(thumbnail_fv['file_uri'])
      expect(result).not_to have_key('link_url')
    end

    it 'uses the display thumbnail file URI as the image whatever its file format (ANW-3001)' do
      [
        link_file_version(:is_display_thumbnail => true),
        image_file_version(:is_display_thumbnail => true, :file_format_name => 'tiff'),
        image_file_version(:is_display_thumbnail => true, :file_format_name => nil),
      ].each do |thumbnail_fv|
        expect(thumbnail([thumbnail_fv])['image_url']).to eq(thumbnail_fv['file_uri'])
      end
    end

    it 'shows a generic icon linked to the display link when there is no display thumbnail (ANW-3003)' do
      link_fv = link_file_version(:is_display_link => true)

      result = thumbnail([image_file_version, link_fv])
      expect(result).not_to have_key('image_url')
      expect(result['link_url']).to eq(link_fv['file_uri'])
    end

    it 'shows nothing when no file version is marked display thumbnail or display link (ANW-3003)' do
      expect(thumbnail([image_file_version(:use_statement => 'image-thumbnail'), link_file_version])).to be_nil
    end

    it 'ignores unpublished file versions' do
      expect(thumbnail([image_file_version(:is_display_thumbnail => true, :publish => false)])).to be_nil
    end

    it 'uses one file version as both the image and the link when it carries both flags' do
      file_version = image_file_version(:is_display_thumbnail => true, :is_display_link => true)

      result = thumbnail([file_version])
      expect(result['image_url']).to eq(file_version['file_uri'])
      expect(result['link_url']).to eq(file_version['file_uri'])
    end

    it 'falls back from the thumbnail caption to the link caption to the title (ANW-3007)' do
      expect(thumbnail([image_file_version(:is_display_thumbnail => true),
                        link_file_version(:is_display_link => true, :caption => 'Link caption')])['caption']).to eq('Link caption')

      expect(thumbnail([image_file_version(:is_display_thumbnail => true)], 'The DO title')['caption']).to eq('The DO title')
    end
  end
end
