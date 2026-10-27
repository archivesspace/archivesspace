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

  describe 'choose_thumbnail' do
    def candidate(name, image = true)
      {'record_uri' => name}.merge(image ? {'image_url' => "http://example.com/#{name}.jpg"} : {})
    end

    it 'shows the first image, with the next images as fallbacks for the browser to try in turn (ANW-3089)' do
      expect(Thumbnails::Rules.choose_thumbnail([candidate('icon', false), candidate('first'), candidate('second')])).to eq(
        candidate('first').merge('fallbacks' => [candidate('second')])
      )
    end

    it 'offers ten images by default' do
      images = (1..12).map { |n| candidate("image#{n}") }

      thumbnail = Thumbnails::Rules.choose_thumbnail(images)
      expect(thumbnail['record_uri']).to eq('image1')
      expect(thumbnail['fallbacks'].map { |fallback| fallback['record_uri'] }).to eq((2..10).map { |n| "image#{n}" })
    end

    context 'with AppConfig[:max_thumbnail_images] set' do
      let(:images) { (1..4).map { |n| candidate("image#{n}") } }

      def configure_max_images(max_images)
        allow(AppConfig).to receive(:[]).and_call_original
        allow(AppConfig).to receive(:[]).with(:max_thumbnail_images) { max_images }
      end

      it 'offers at most the configured number of images' do
        configure_max_images(3)

        thumbnail = Thumbnails::Rules.choose_thumbnail(images)
        expect(thumbnail['record_uri']).to eq('image1')
        expect(thumbnail['fallbacks'].map { |fallback| fallback['record_uri'] }).to eq(%w[image2 image3])
      end

      it 'offers one image without fallbacks when configured for one or fewer' do
        [1, 0].each do |max_images|
          configure_max_images(max_images)

          expect(Thumbnails::Rules.choose_thumbnail(images)).to eq(candidate('image1'))
        end
      end
    end

    it 'has no fallbacks with a single image' do
      expect(Thumbnails::Rules.choose_thumbnail([candidate('icon', false), candidate('image')])).to eq(candidate('image'))
    end

    it 'shows the first generic icon without images' do
      expect(Thumbnails::Rules.choose_thumbnail([candidate('first', false), candidate('second', false)])).to eq(candidate('first', false))
    end

    it 'shows nothing without candidates' do
      expect(Thumbnails::Rules.choose_thumbnail([])).to be_nil
    end
  end
end
