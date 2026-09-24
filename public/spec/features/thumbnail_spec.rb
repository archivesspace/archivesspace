require 'spec_helper'
require 'rails_helper'

describe 'Thumbnails', js: true do
  before(:all) do
    @img_1 = 'https://www.archivesspace.org/demos/Congreave%20E-4/ms292_008.jpg'
    @img_2 = 'https://www.archivesspace.org/demos/Congreave%20E-1/ms292_001.jpg'
    @img_3 = 'https://www.archivesspace.org/demos/Congreave%20E-1/ms292_002.jpg'
    @unrenderable_img = 'https://lyrasis.org'
    @caption_1 = 'This is caption 1'
    @caption_2 = 'This is caption 2'
    @long_caption = 'This is the long caption whose character count exceeds 56'
    @max_caption_chars = 42
    @dobj_with_repfv = create(
      :digital_object,
      publish: true,
      title: 'Digital object with thumbnail',
      file_versions: [
        {
          publish: true,
          is_representative: true,
          file_uri: @img_1,
          use_statement: 'image-thumbnail',
          caption: @caption_1
        }
      ]
    )
    @dobjc_with_repfv = create(:digital_object_component,
                               publish: true,
                               digital_object: { ref: @dobj_with_repfv.uri },
                               title: 'Digital object component with thumbnail',
                               file_versions: [
                                 {
                                   publish: true,
                                   is_representative: true,
                                   file_uri: @img_2,
                                   use_statement: 'image-thumbnail',
                                   caption: @caption_2
                                 }
                               ]
    )
    @dobj_with_repfv_02 = create(
      :digital_object,
      publish: true,
      title: 'Digital object with thumbnail 02',
      file_versions: [
        {
          publish: true,
          is_representative: false,
          file_uri: @img_1,
          use_statement: 'image-thumbnail',
          caption: @caption_1
        },
        {
          publish: true,
          is_representative: true,
          file_uri: @img_3,
        }
      ]
    )
    @dobj_with_repfv_03 = create(
      :digital_object,
      publish: true,
      title: '03 Digital object with thumbnail',
      file_versions: [
        {
          publish: true,
          is_representative: true,
          file_uri: @img_1,
          use_statement: 'image-thumbnail',
          caption: @caption_1
        },
        {
          publish: false,
          file_uri: @img_3,
        }
      ]
    )
    @dobjc_with_repfv_02 = create(:digital_object_component,
                                  publish: true,
                                  digital_object: { ref: @dobj_with_repfv.uri },
                                  title: 'Digital object component with thumbnail 02',
                                  file_versions: [
                                    {
                                      publish: true,
                                      is_representative: false,
                                      file_uri: @img_2,
                                      use_statement: 'image-thumbnail',
                                      caption: @caption_2
                                    },
                                    {
                                      publish: true,
                                      is_representative: true,
                                      file_uri: @img_3,
                                    }
                                  ]
    )
    @dobjc_with_repfv_03 = create(:digital_object_component,
                                  publish: true,
                                  digital_object: { ref: @dobj_with_repfv.uri },
                                  title: 'Digital object component with thumbnail 03',
                                  file_versions: [
                                    {
                                      publish: true,
                                      is_representative: true,
                                      file_uri: @img_2,
                                      use_statement: 'image-thumbnail',
                                      caption: @caption_2
                                    },
                                    {
                                      publish: false,
                                      file_uri: @img_3,
                                    }
                                  ]
    )
    @dobj_with_unrenderable_thumbnail = create(
      :digital_object,
      publish: true,
      title: '05 Digital object with unrenderable thumbnail',
      file_versions: [
        {
          publish: true,
          is_representative: true,
          file_uri: @unrenderable_img,
          use_statement: 'image-thumbnail',
          caption: @caption_1
        }
      ]
    )
    @resource_with_repfv = create(:resource,
                                  publish: true,
                                  title: 'Resource with thumbnail',
                                  instances: [build(:instance_digital,
                                                    digital_object: { ref: @dobj_with_repfv.uri },
                                                    is_representative: true
                                              )]
    )
    @aobj_with_repfv = create(:archival_object,
                              publish: true,
                              title: 'Archival Object with thumbnail',
                              resource: {'ref' => @resource_with_repfv.uri},
                              instances: [build(:instance_digital,
                                                digital_object: { ref: @dobj_with_repfv.uri },
                                                is_representative: true
                                          )]
    )
    @accession_with_repfv = create(:accession,
                                   publish: true,
                                   title: 'Accession with thumbnail',
                                   instances: [build(:instance_digital,
                                                     digital_object: { ref: @dobj_with_repfv.uri },
                                                     is_representative: true
                                               )]
    )

    @dobj_with_repfv_long_caption = create(
      :digital_object,
      publish: true,
      title: 'Digital object with thumbnail and long caption',
      file_versions: [
        {
          publish: true,
          is_representative: true,
          file_uri: @img_1,
          use_statement: 'image-thumbnail',
          caption: @long_caption
        }
      ]
    )

    @aobj_with_unrenderable_thumbnail =
      create(:archival_object,
        publish: true,
        title: 'Archival Object with unrenderable thumbnail',
        resource: {'ref' => @resource_with_repfv.uri},
        instances: [build(:instance_digital,
                          digital_object: { ref: @dobj_with_unrenderable_thumbnail.uri },
                          is_representative: true
                    )]
    )

    run_indexers
  end

  it 'on Resource' do
    visit @resource_with_repfv.uri
    expect(page).to have_css ".pui-thumbnail a[href='#{@img_1}']"
    expect(page).to have_css ".pui-thumbnail img[src='#{@img_1}']"

  end
  it 'on Archival Object' do
    visit @aobj_with_repfv.uri
    expect(page).to have_css ".pui-thumbnail a[href='#{@img_1}']"
    expect(page).to have_css ".pui-thumbnail img[src='#{@img_1}']"
  end

  it 'on Accession records' do
    visit @accession_with_repfv.uri
    expect(page).to have_css ".pui-thumbnail a[href='#{@img_1}']"
    expect(page).to have_css ".pui-thumbnail img[src='#{@img_1}']"
  end

  it 'links to the non-thumbmail file version on DO' do
    visit @dobj_with_repfv_02.uri
    expect(page).to have_css ".pui-thumbnail a[href='#{@img_3}']"
    expect(page).to have_css ".pui-thumbnail img[src='#{@img_1}']"
  end

  it 'links to the file uri of the only published file version on DO' do
    visit @dobj_with_repfv_03.uri
    expect(page).to have_css ".pui-thumbnail a[href='#{@img_1}']"
    expect(page).to have_css ".pui-thumbnail img[src='#{@img_1}']"
  end

  it 'links to the non-thumbmail file version on DOC' do
    visit @dobjc_with_repfv_02.uri
    expect(page).to have_css ".pui-thumbnail a[href='#{@img_3}']"
    expect(page).to have_css ".pui-thumbnail img[src='#{@img_2}']"
  end

  it 'links to the file uri of the only published file version on DOC' do
    visit @dobjc_with_repfv_03.uri
    expect(page).to have_css ".pui-thumbnail a[href='#{@img_2}']"
    expect(page).to have_css ".pui-thumbnail img[src='#{@img_2}']"
  end

  describe 'search result thumbnail' do
    it 'is shown for digital objects' do
      visit('/')
      page.fill_in 'Enter your search terms', with: @dobj_with_repfv.title
      click_button 'Search'

      within ".recordrow[data-uri='#{@dobj_with_repfv.uri}']" do
        expect(page.find(".pui-thumbnail img", visible: :all)[:src]).to eq @img_1
        expect(page.find('.pui-thumbnail img')[:alt]).to eq @caption_1
      end
    end

    it 'is shown for digital object components' do
      visit('/')
      page.fill_in 'Enter your search terms', with: @dobjc_with_repfv.title
      click_button 'Search'

      within ".recordrow[data-uri='#{@dobjc_with_repfv.uri}']" do
        expect(page.find(".pui-thumbnail img", visible: :all)[:src]).to eq @img_2
        expect(page.find('.pui-thumbnail img')[:alt]).to eq @caption_2
      end
    end

    it 'is shown for resources' do
      visit('/')
      page.fill_in 'Enter your search terms', with: @resource_with_repfv.title
      click_button 'Search'

      within ".recordrow[data-uri='#{@resource_with_repfv.uri}']" do
        expect(page.find(".pui-thumbnail img", visible: :all)[:src]).to eq @img_1
        expect(page.find('.pui-thumbnail img')[:alt]).to eq @caption_1
      end
    end

    it 'is shown for archival objects' do
      visit('/')
      page.fill_in 'Enter your search terms', with: @aobj_with_repfv.title
      click_button 'Search'

      within ".recordrow[data-uri='#{@aobj_with_repfv.uri}']" do
        expect(page.find(".pui-thumbnail img", visible: :all)[:src]).to eq @img_1
        expect(page.find('.pui-thumbnail img')[:alt]).to eq @caption_1
      end
    end

    it 'is shown for accessions' do
      visit('/')
      page.fill_in 'Enter your search terms', with: @accession_with_repfv.title
      click_button 'Search'

      within ".recordrow[data-uri='#{@accession_with_repfv.uri}']" do
        expect(page.find(".pui-thumbnail img", visible: :all)[:src]).to eq @img_1
        expect(page.find('.pui-thumbnail img')[:alt]).to eq @caption_1
      end
    end
  end

  describe "fallback to icon" do
    it "shows fallback icon if the thumbnail URL cannot be rendered by the browser" do
      visit @aobj_with_unrenderable_thumbnail.uri
      expect(page).to have_css ".pui-thumbnail a[href='#{@unrenderable_img}']"
      expect(page).to have_css(".pui-thumbnail img[src='#{@unrenderable_img}']", visible: :hidden)
      expect(page).to have_css(".pui-thumbnail .pui-thumbnail-fallback", visible: true)
    end
  end
end
