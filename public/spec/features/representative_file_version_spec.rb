require 'spec_helper'
require 'rails_helper'

describe 'Representative File Version', js: true do
  before(:all) do
    @img_1 = 'https://www.archivesspace.org/demos/Congreave%20E-4/ms292_008.jpg'
    @img_2 = 'https://www.archivesspace.org/demos/Congreave%20E-1/ms292_001.jpg'
    @img_3 = 'https://www.archivesspace.org/demos/Congreave%20E-1/ms292_002.jpg'
    @caption_1 = 'This is caption 1'
    @caption_2 = 'This is caption 2'
    @long_caption = 'This is the long caption whose character count exceeds 56'
    @max_caption_chars = 42
    @dobj_with_repfv = create(
      :digital_object,
      publish: true,
      title: 'Digital object with representative file version',
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
      title: 'Digital object component with representative file version',
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
      title: 'Digital object with representative file version 02',
      file_versions: [
        {
          publish: true,
          is_representative: true,
          file_uri: @img_1,
          use_statement: 'image-thumbnail',
          caption: @caption_1
        },
        {
          publish: true,
          is_representative: false,
          file_uri: @img_3,
        }
      ]
    )
    @dobj_with_repfv_03 = create(
      :digital_object,
      publish: true,
      title: '03 Digital object with representative file version',
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
      title: 'Digital object component with representative file version 02',
      file_versions: [
        {
          publish: true,
          is_representative: true,
          file_uri: @img_2,
          use_statement: 'image-thumbnail',
          caption: @caption_2
        },
        {
          publish: true,
          is_representative: false,
          file_uri: @img_3,
        }
      ]
    )
    @dobjc_with_repfv_03 = create(:digital_object_component,
      publish: true,
      digital_object: { ref: @dobj_with_repfv.uri },
      title: 'Digital object component with representative file version 03',
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
    @resource_with_repfv = create(:resource,
      publish: true,
      title: 'Resource with representative file version',
      instances: [build(:instance_digital,
        digital_object: { ref: @dobj_with_repfv.uri },
        is_representative: true
      )]
    )
    @aobj_with_repfv = create(:archival_object,
      publish: true,
      title: 'Archival Object with representative file version',
      resource: {'ref' => @resource_with_repfv.uri},
      instances: [build(:instance_digital,
        digital_object: { ref: @dobj_with_repfv.uri },
        is_representative: true
      )]
    )
    @accession_with_repfv = create(:accession,
      publish: true,
      title: 'Accession with representative file version',
      instances: [build(:instance_digital,
        digital_object: { ref: @dobj_with_repfv.uri },
        is_representative: true
      )]
    )

    @dobj_with_repfv_long_caption = create(
      :digital_object,
      publish: true,
      title: 'Digital object with representative file version and long caption',
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

    run_indexers
  end

  it 'links to its digital object record on Resource, Archival Object, and'\
     ' Accession records' do
    visit @resource_with_repfv.uri
    expect(page).to have_css "figure[data-rep-file-version-wrapper] > a[href='#{@dobj_with_repfv.uri}']"

    visit @aobj_with_repfv.uri
    expect(page).to have_css "figure[data-rep-file-version-wrapper] > a[href='#{@dobj_with_repfv.uri}']"

    visit @accession_with_repfv.uri
    expect(page).to have_css "figure[data-rep-file-version-wrapper] > a[href='#{@dobj_with_repfv.uri}']"
  end

  it 'links to the file uri of the proceeding file version, if one exists and is published '\
  'in the Digital Object or Digital Object Component, on DO/DOC/Resource/AO/Accession pages' do
    link_css = ".objectimage figure[data-rep-file-version-wrapper] > a[href='#{@img_3}']"

    visit @dobj_with_repfv_02.uri
    expect(page).to have_css link_css

    visit @dobj_with_repfv_03.uri
    expect(page).not_to have_css link_css

    visit @dobjc_with_repfv_02.uri
    expect(page).to have_css link_css

    visit @dobjc_with_repfv_03.uri
    expect(page).not_to have_css link_css
  end

  describe 'search result thumbnail' do
    it 'is shown for digital objects' do
      visit('/')
      page.fill_in 'Enter your search terms', with: @dobj_with_repfv.title
      click_button 'Search'

      within ".recordrow[data-uri='#{@dobj_with_repfv.uri}']" do
        expect(page.find("img.result-repfv__img", visible: :all)[:src]).to eq @img_1
        expect(page.find('figcaption.result-repfv__figcaption')).to have_content @caption_1
      end
    end

    it 'is shown for digital object components' do
      visit('/')
      page.fill_in 'Enter your search terms', with: @dobjc_with_repfv.title
      click_button 'Search'

      within ".recordrow[data-uri='#{@dobjc_with_repfv.uri}']" do
        expect(page.find("img.result-repfv__img", visible: :all)[:src]).to eq @img_2
        expect(page.find('figcaption.result-repfv__figcaption')).to have_content @caption_2
      end
    end

    it 'is shown for resources' do
      visit('/')
      page.fill_in 'Enter your search terms', with: @resource_with_repfv.title
      click_button 'Search'

      within ".recordrow[data-uri='#{@resource_with_repfv.uri}']" do
        expect(page.find("img.result-repfv__img", visible: :all)[:src]).to eq @img_1
        expect(page.find('figcaption.result-repfv__figcaption')).to have_content @caption_1
      end
    end

    it 'is shown for archival objects' do
      visit('/')
      page.fill_in 'Enter your search terms', with: @aobj_with_repfv.title
      click_button 'Search'

      within ".recordrow[data-uri='#{@aobj_with_repfv.uri}']" do
        expect(page.find("img.result-repfv__img", visible: :all)[:src]).to eq @img_1
        expect(page.find('figcaption.result-repfv__figcaption')).to have_content @caption_1
      end
    end

    it 'is shown for accessions' do
      visit('/')
      page.fill_in 'Enter your search terms', with: @accession_with_repfv.title
      click_button 'Search'

      within ".recordrow[data-uri='#{@accession_with_repfv.uri}']" do
        expect(page.find("img.result-repfv__img", visible: :all)[:src]).to eq @img_1
        expect(page.find('figcaption.result-repfv__figcaption')).to have_content @caption_1
      end
    end

    it 'truncates captions longer than 42 characters with an appended ellipsis' do
      visit('/')
      page.fill_in 'Enter your search terms', with: @dobj_with_repfv_long_caption.title
      click_button 'Search'

      within ".recordrow[data-uri='#{@dobj_with_repfv_long_caption.uri}']" do
        expect(page.find('figcaption.result-repfv__figcaption')).to have_content @long_caption
          .split('')
          .first(@max_caption_chars)
          .join('') + '...'
      end
    end
  end
end
