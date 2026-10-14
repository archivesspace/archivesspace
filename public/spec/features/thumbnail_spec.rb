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
    @caption_with_markup = 'Letter to <emph render="italic">The Times</emph>'
    @link_with_apostrophe = "https://www.example.com/O'Brien_letter.pdf"
    @dobj_with_awkward_file_versions = create(
      :digital_object,
      publish: true,
      title: 'Digital object with markup and an apostrophe in its file versions',
      file_versions: [
        { publish: true, file_uri: @link_2, caption: @caption_with_markup },
        { publish: true, file_uri: @link_with_apostrophe },
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
    @aobj_without_thumbnail = create(:archival_object,
                                     publish: true,
                                     title: 'Archival Object without thumbnail',
                                     resource: { 'ref' => @resource_with_thumbnail.uri })
    @accession_without_thumbnail = create(:accession, publish: true, title: 'Accession without thumbnail')
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

    # 4.2.1 showed every digital instance with an embed or new file version on an archival object or
    # resource without a representative instance (ANW-3061)
    @dobj_embed = create(
      :digital_object,
      publish: true,
      title: 'Digital object with an embedded image',
      file_versions: [
        { publish: true, is_display_thumbnail: true, file_uri: @img_2, file_format_name: 'jpeg', xlink_show_attribute: 'embed' },
      ]
    )
    @dobj_new = create(
      :digital_object,
      publish: true,
      title: 'Digital object with a file opening in a new window',
      file_versions: [
        { publish: true, is_display_link: true, file_uri: @link_2, xlink_show_attribute: 'new' },
      ]
    )
    non_representative_instances = [@dobj_embed, @dobj_new].map do |digital_object|
      build(:instance_digital, digital_object: { ref: digital_object.uri }, is_representative: false)
    end
    @resource_without_representative = create(:resource,
                                              publish: true,
                                              title: 'Resource without a representative instance',
                                              instances: non_representative_instances)
    @aobj_without_representative = create(:archival_object,
                                          publish: true,
                                          title: 'Archival Object without a representative instance',
                                          resource: { 'ref' => @resource_without_representative.uri },
                                          instances: non_representative_instances)

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
      expect(page).not_to have_css '.pui-thumbnail-help-text', visible: :all
    end

    it 'opens the display link file version in a new window, with help text' do
      visit @dobj_with_thumbnail.uri

      aggregate_failures do
        expect(page).to have_css ".pui-thumbnail a[href='#{@link_1}'][target='_blank']"
        expect(page).to have_css '.pui-thumbnail a .pui-thumbnail-help-text', text: 'View Digital Material', visible: :all
        expect(page).not_to have_css '.pui-thumbnail a[aria-hidden]'
      end
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

    it 'shows the caption of a listed file version without its markup' do
      visit @dobj_with_awkward_file_versions.uri

      within '#additional_file_versions_list', visible: :all do
        aggregate_failures do
          expect(page).to have_css "a[href='#{@link_2}']", text: 'Letter to The Times', visible: :all
          expect(page).not_to have_css 'emph', visible: :all
        end
      end
    end

    it 'links to the whole file URI of a listed file version, even with an apostrophe in it' do
      visit @dobj_with_awkward_file_versions.uri

      within '#additional_file_versions_list', visible: :all do
        expect(page).to have_css %(a[href="#{@link_with_apostrophe}"]), text: @link_with_apostrophe, visible: :all
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

    it 'opens the digital object in the same window, with help text' do
      visit @accession_with_thumbnail.uri

      aggregate_failures do
        expect(page).to have_css ".pui-thumbnail a[href$='#{@dobj_with_thumbnail.uri}'][target='_self']"
        expect(page).to have_css '.pui-thumbnail a .pui-thumbnail-help-text', text: 'View Digital Object', visible: :all
      end
    end

    it 'links the generic icon of the digital object to the digital object' do
      visit @accession_with_icon.uri
      expect(page).to have_css ".pui-thumbnail a[href$='#{@dobj_with_icon.uri}'] i.fa-file-video-o"
    end

    it 'gives the generic icon an accessible name, so that its link is not empty' do
      visit @accession_with_icon.uri

      aggregate_failures do
        expect(page).to have_css ".pui-thumbnail a[href$='#{@dobj_with_icon.uri}'] i.fa-file-video-o[role='img'][aria-label='#{@caption_2}']"
        expect(page).not_to have_css '.pui-thumbnail a[aria-hidden]'
      end
    end

    it 'shows the first image among the representative instances of the archival objects of a resource' do
      visit @resource_from_tree.uri
      expect(page).to have_css ".pui-thumbnail a[href$='#{@dobj_with_thumbnail.uri}'] img[src='#{@img_1}']"
    end
  end

  describe 'on records with digital object instances, none of them representative (ANW-3061)' do
    shared_examples 'no thumbnail from its digital object instances' do
      it 'shows no thumbnail, image or file version of its digital object instances' do
        visit record.uri

        expect(page).to have_css 'h1', text: record.title
        aggregate_failures do
          expect(page).not_to have_css '.pui-thumbnail'
          expect(page).not_to have_css '.available-digital-objects, .objectimage', visible: :all
          expect(page).not_to have_css "img[src='#{@img_2}']", visible: :all
          expect(page).not_to have_css "a[href='#{@link_2}']", visible: :all
        end
      end
    end

    context 'on a resource' do
      let(:record) { @resource_without_representative }

      include_examples 'no thumbnail from its digital object instances'
    end

    context 'on an archival object' do
      let(:record) { @aobj_without_representative }

      include_examples 'no thumbnail from its digital object instances'
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

    it 'hides its link from screen readers and the keyboard, since it duplicates the title link' do
      search_for @accession_with_icon.title

      within ".recordrow[data-uri='#{@accession_with_icon.uri}']" do
        expect(page).to have_css ".pui-thumbnail a[aria-hidden='true'][tabindex='-1'] i.fa-file-video-o"
      end
    end

    it 'links to the result record in the same window, like the title' do
      search_for @dobj_with_thumbnail.title

      within ".recordrow[data-uri='#{@dobj_with_thumbnail.uri}']" do
        expect(page).to have_css ".pui-thumbnail a[href$='#{@dobj_with_thumbnail.uri}'][target='_self'] img[src='#{@img_1}']"
        expect(page).not_to have_css '.pui-thumbnail-help-text', visible: :all
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

    it 'is right aligned, after the record summary' do
      search_for @accession_with_thumbnail.title

      within ".recordrow[data-uri='#{@accession_with_thumbnail.uri}']" do
        expect(page).to have_css(':scope > .recordrow-summary + .pui-thumbnail:last-child')

        title_right = page.evaluate_script("document.querySelector(\".recordrow[data-uri='#{@accession_with_thumbnail.uri}'] .record-title\").getBoundingClientRect().right")
        thumbnail_left = page.evaluate_script("document.querySelector(\".recordrow[data-uri='#{@accession_with_thumbnail.uri}'] .pui-thumbnail\").getBoundingClientRect().left")
        expect(thumbnail_left).to be > title_right
      end
    end

    it 'leaves no space for a thumbnail when the record has none' do
      search_for @accession_without_thumbnail.title

      within ".recordrow[data-uri='#{@accession_without_thumbnail.uri}']" do
        expect(page).to have_css('.record-title', text: @accession_without_thumbnail.title)
        expect(page).not_to have_css('.pui-thumbnail', visible: :all)
        expect(page).not_to have_css('.pui-thumbnail-spacer', visible: :all)
      end
    end
  end

  describe 'collection tree thumbnail' do
    before(:each) do
      visit "#{@resource_with_thumbnail.uri}/collection_organization"
    end

    it 'links to the archival object, hidden from screen readers and the keyboard, since it duplicates the title link' do
      within '.infinite-item', text: @aobj_with_thumbnail.title do
        expect(page).to have_css ".pui-thumbnail a[href$='#{@aobj_with_thumbnail.uri}'][target='_self'][aria-hidden='true'][tabindex='-1'] img[src='#{@img_1}']"
      end
    end

    it 'leaves no spacer for an archival object without a thumbnail' do
      within '.infinite-item', text: @aobj_without_thumbnail.title do
        expect(page).not_to have_css '.pui-thumbnail', visible: :all
        expect(page).not_to have_css '.pui-thumbnail-spacer', visible: :all
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

    it 'gives the fallback icon an accessible name' do
      expect_fallback_icon(@dobj_with_unreachable_thumbnail, unreachable_image)
      expect(page).to have_css ".pui-thumbnail-fallback[role='img'][aria-label='#{@dobj_with_unreachable_thumbnail.title}']"
    end

    it 'shows the fallback icon, still linked to the digital object, if the thumbnail is in a format the browser cannot display' do
      expect_fallback_icon(@aobj_with_tiff_thumbnail, tiff_image)
      expect(page).to have_css(".pui-thumbnail a[href$='#{@dobj_with_tiff_thumbnail.uri}'] .pui-thumbnail-fallback")
    end
  end
end
