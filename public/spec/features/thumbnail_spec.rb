require 'spec_helper'
require 'rails_helper'

describe 'Thumbnails', js: true do
  before(:all) do
    @img_1 = 'https://www.archivesspace.org/demos/Congreave%20E-4/ms292_008.jpg'
    @img_2 = 'https://www.archivesspace.org/demos/Congreave%20E-1/ms292_001.jpg'
    @link_1 = 'https://www.archivesspace.org/demos/Congreave%20E-1/ms292_002.pdf'
    @link_2 = 'https://www.archivesspace.org/demos/Congreave%20E-1/ms292_003.pdf'
    @caption_1 = 'This is caption 1'
    @caption_2 = 'This is caption 2'

    @dobj_with_thumbnail = create(
      :digital_object,
      publish: true,
      title: 'Digital object with thumbnail',
      digital_object_type: 'still_image',
      file_versions: [
        { publish: true, is_display_thumbnail: true, file_uri: @img_1, file_format_name: 'jpeg', caption: @caption_1 },
        { publish: true, is_display_link: true, file_uri: @link_1 },
        { publish: true, file_uri: @link_2 },
      ]
    )
    @dobj_thumbnail_without_link = create(
      :digital_object,
      publish: true,
      title: 'Digital object with thumbnail and no link',
      file_versions: [
        { publish: true, is_display_thumbnail: true, file_uri: @img_1, file_format_name: 'jpeg', caption: @caption_1 },
        { publish: true, file_uri: @link_2 },
      ]
    )
    @dobj_with_icon = create(
      :digital_object,
      publish: true,
      title: 'Digital object with generic icon',
      digital_object_type: 'moving_image',
      file_versions: [
        { publish: true, is_display_link: true, file_uri: @link_1, caption: @caption_2 },
      ]
    )
    @dobjc_with_thumbnail = create(
      :digital_object_component,
      publish: true,
      digital_object: { ref: @dobj_with_thumbnail.uri },
      title: 'Digital object component with thumbnail',
      file_versions: [
        { publish: true, is_display_thumbnail: true, file_uri: @img_2, file_format_name: 'jpeg', caption: @caption_2 },
        { publish: true, is_display_link: true, file_uri: @link_1 },
      ]
    )

    @resource_with_thumbnail = create(:resource,
                                      publish: true,
                                      title: 'Resource with thumbnail',
                                      instances: [build(:instance_digital,
                                                        digital_object: { ref: @dobj_with_thumbnail.uri },
                                                        is_representative: true)])
    @aobj_with_thumbnail = create(:archival_object,
                                  publish: true,
                                  title: 'Archival Object with thumbnail',
                                  resource: { 'ref' => @resource_with_thumbnail.uri },
                                  instances: [build(:instance_digital,
                                                    digital_object: { ref: @dobj_with_thumbnail.uri },
                                                    is_representative: true)])
    @accession_with_thumbnail = create(:accession,
                                       publish: true,
                                       title: 'Accession with thumbnail',
                                       instances: [build(:instance_digital,
                                                         digital_object: { ref: @dobj_with_thumbnail.uri },
                                                         is_representative: true)])
    @accession_with_icon = create(:accession,
                                  publish: true,
                                  title: 'Accession with generic icon',
                                  instances: [build(:instance_digital,
                                                    digital_object: { ref: @dobj_with_icon.uri },
                                                    is_representative: true)])

    # a resource with no representative instance of its own shows the image of an archival object's
    @resource_from_tree = create(:resource, publish: true, title: 'Resource with thumbnail from its tree')
    create(:archival_object,
           publish: true,
           resource: { 'ref' => @resource_from_tree.uri },
           instances: [build(:instance_digital, digital_object: { ref: @dobj_with_icon.uri }, is_representative: true)])
    create(:archival_object,
           publish: true,
           resource: { 'ref' => @resource_from_tree.uri },
           instances: [build(:instance_digital, digital_object: { ref: @dobj_with_thumbnail.uri }, is_representative: true)])

    run_indexers
  end

  describe 'on digital objects and components' do
    it 'shows the display thumbnail linked to the display link file version' do
      visit @dobj_with_thumbnail.uri
      expect(page).to have_css ".pui-thumbnail a[href='#{@link_1}'] img[src='#{@img_1}']"
      expect(page).to have_css '.pui-thumbnail-caption', text: @caption_1
    end

    it 'shows the display thumbnail without a link when there is no display link' do
      visit @dobj_thumbnail_without_link.uri
      expect(page).to have_css ".pui-thumbnail img[src='#{@img_1}']"
      expect(page).not_to have_css '.pui-thumbnail a'
    end

    it 'shows a format-specific generic icon linked to the display link file version' do
      visit @dobj_with_icon.uri
      expect(page).to have_css ".pui-thumbnail a[href='#{@link_1}'] i.fa-file-video-o"
      expect(page).not_to have_css '.pui-thumbnail img'
      expect(page).to have_css '.pui-thumbnail-caption', text: @caption_2
    end

    it 'shows the display thumbnail of a digital object component' do
      visit @dobjc_with_thumbnail.uri
      expect(page).to have_css ".pui-thumbnail a[href='#{@link_1}'] img[src='#{@img_2}']"
    end

    it 'lists only the file versions not used as the display thumbnail or display link' do
      visit @dobj_with_thumbnail.uri
      within '#additional_file_versions_list' do
        expect(page).to have_css "a[href='#{@link_2}']", visible: :all
        expect(page).not_to have_css "a[href='#{@img_1}']", visible: :all
        expect(page).not_to have_css "a[href='#{@link_1}']", visible: :all
      end
    end
  end

  describe 'on records with a representative digital object instance' do
    it 'links the resource thumbnail to the digital object and to its digital objects' do
      visit @resource_with_thumbnail.uri
      expect(page).to have_css ".pui-thumbnail a[href$='#{@dobj_with_thumbnail.uri}'] img[src='#{@img_1}']"
      expect(page).to have_css ".pui-thumbnail-digital-materials a[href$='#{@resource_with_thumbnail.uri}/digitized']"
    end

    it 'links the archival object thumbnail to the digital object' do
      visit @aobj_with_thumbnail.uri
      expect(page).to have_css ".pui-thumbnail a[href$='#{@dobj_with_thumbnail.uri}'] img[src='#{@img_1}']"
      expect(page).not_to have_css '.pui-thumbnail-digital-materials'
    end

    it 'links the accession thumbnail to the digital object' do
      visit @accession_with_thumbnail.uri
      expect(page).to have_css ".pui-thumbnail a[href$='#{@dobj_with_thumbnail.uri}'] img[src='#{@img_1}']"
    end

    it 'links the generic icon of the digital object to the digital object' do
      visit @accession_with_icon.uri
      expect(page).to have_css ".pui-thumbnail a[href$='#{@dobj_with_icon.uri}'] i.fa-file-video-o"
    end

    it 'shows the first image among the representative instances of the archival objects of a resource' do
      visit @resource_from_tree.uri
      expect(page).to have_css ".pui-thumbnail a[href$='#{@dobj_with_thumbnail.uri}'] img[src='#{@img_1}']"
    end
  end

  describe 'search result thumbnail' do
    def search_for(title)
      visit('/')
      page.fill_in 'Enter your search terms', with: title
      click_button 'Search'
    end

    it 'is shown for digital objects' do
      search_for @dobj_with_thumbnail.title

      within ".recordrow[data-uri='#{@dobj_with_thumbnail.uri}']" do
        expect(page.find('.pui-thumbnail img', visible: :all)[:src]).to eq @img_1
        expect(page.find('.pui-thumbnail img')[:alt]).to eq @caption_1
      end
    end

    it 'is shown for digital object components' do
      search_for @dobjc_with_thumbnail.title

      within ".recordrow[data-uri='#{@dobjc_with_thumbnail.uri}']" do
        expect(page.find('.pui-thumbnail img', visible: :all)[:src]).to eq @img_2
        expect(page.find('.pui-thumbnail img')[:alt]).to eq @caption_2
      end
    end

    it 'is shown for resources, archival objects and accessions' do
      [@resource_with_thumbnail, @aobj_with_thumbnail, @accession_with_thumbnail].each do |record|
        search_for record.title

        within ".recordrow[data-uri='#{record.uri}']" do
          expect(page.find('.pui-thumbnail img', visible: :all)[:src]).to eq @img_1
          expect(page.find('.pui-thumbnail img')[:alt]).to eq @caption_1
        end
      end
    end
  end

  describe 'fallback to icon' do
    # Nothing listens on port 1, so the browser fails to load the image straight away
    unreachable_image = 'http://127.0.0.1:1/thumbnail.jpg'
    # A valid 1x1 TIFF: a format neither Chrome nor Firefox can display
    tiff_image = 'data:image/tiff;base64,SUkqAAgAAAAJAAABAwABAAAAAQAAAAEBAwABAAAAAQAAAAIBAwABAAAACAAAAAMBAwABAAAAAQAAAAYBAwABAAAAAQAAABEBBAABAAAAegAAABUBAwABAAAAAQAAABYBAwABAAAAAQAAABcBBAABAAAAAQAAAAAAAAD/'

    before(:all) do
      @dobj_with_unreachable_thumbnail = create(
        :digital_object,
        publish: true,
        title: 'Digital object with unreachable thumbnail',
        digital_object_type: 'still_image',
        file_versions: [{ publish: true, is_display_thumbnail: true, file_uri: unreachable_image }]
      )
      @dobj_with_tiff_thumbnail = create(
        :digital_object,
        publish: true,
        title: 'Digital object with TIFF thumbnail',
        digital_object_type: 'still_image',
        file_versions: [{ publish: true, is_display_thumbnail: true, file_uri: tiff_image, file_format_name: 'tiff' }]
      )
      @aobj_with_tiff_thumbnail = create(
        :archival_object,
        publish: true,
        title: 'Archival Object with TIFF thumbnail',
        resource: { 'ref' => @resource_with_thumbnail.uri },
        instances: [build(:instance_digital, digital_object: { ref: @dobj_with_tiff_thumbnail.uri }, is_representative: true)]
      )

      run_indexers
    end

    def expect_fallback_icon(record, image_url)
      visit record.uri
      expect(page).to have_css(".pui-thumbnail img[src='#{image_url}']", visible: :hidden)
      expect(page).to have_css('.pui-thumbnail .pui-thumbnail-fallback.fa-file-image-o', visible: true)
    end

    it 'shows the fallback icon if the thumbnail URL cannot be reached' do
      expect_fallback_icon(@dobj_with_unreachable_thumbnail, unreachable_image)
    end

    it 'shows the fallback icon, still linked to the digital object, if the thumbnail is in a format the browser cannot display' do
      expect_fallback_icon(@aobj_with_tiff_thumbnail, tiff_image)
      expect(page).to have_css(".pui-thumbnail a[href$='#{@dobj_with_tiff_thumbnail.uri}'] .pui-thumbnail-fallback")
    end
  end
end
