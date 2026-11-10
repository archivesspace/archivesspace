# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'
require 'base64'
require 'puma'

describe 'Thumbnail image in the browser', js: true do
  unreachable_image = 'http://127.0.0.1:1/thumbnail.jpg'
  unrenderable_tiff_image = 'data:image/tiff;base64,SUkqAAgAAAAJAAABAwABAAAAAQAAAAEBAwABAAAAAQAAAAIBAwABAAAACAAAAAMBAwABAAAAAQAAAAYBAwABAAAAAQAAABEBBAABAAAAegAAABUBAwABAAAAAQAAABYBAwABAAAAAQAAABcBBAABAAAAAQAAAAAAAAD/'
  # A valid 1x1 GIF, which every browser displays
  renderable_gif = Base64.decode64('R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7')
  # An SVG with a viewBox but no width or height, so without a width of its own
  svg_image = "data:image/svg+xml;base64,#{Base64.strict_encode64("<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 200 100'><rect width='200' height='100'/></svg>")}"

  before(:all) do
    @repository = create(:repo, repo_code: "thumbnail_fallback_test_#{Time.now.to_i}")
    set_repo @repository

    @unreachable = create(:digital_object, title: 'Unreachable thumbnail', digital_object_type: 'still_image',
                                           file_versions: [{ file_uri: unreachable_image, publish: true, is_display_thumbnail: true }])
    @tiff = create(:digital_object, title: 'TIFF thumbnail', digital_object_type: 'still_image',
                                    file_versions: [{ file_uri: unrenderable_tiff_image, file_format_name: 'tiff', publish: true, is_display_thumbnail: true }])
    @svg = create(:digital_object, title: 'SVG thumbnail', digital_object_type: 'still_image',
                                   file_versions: [{ file_uri: svg_image, publish: true, is_display_thumbnail: true, is_display_link: true }])

    @image_host = Puma::Server.new(->(_env) { [200, { 'content-type' => 'image/gif' }, [renderable_gif]] }, nil, log_writer: Puma::LogWriter.null)
    @image_host.binder.parse(['tcp://127.0.0.1:0'])
    @image_host.run
    @loadable_image = "http://127.0.0.1:#{@image_host.binder.connected_ports.first}/thumbnail.gif"
    @loadable = create(:digital_object, title: 'Loadable thumbnail', digital_object_type: 'still_image',
                                        file_versions: [{ file_uri: @loadable_image, publish: true, is_display_thumbnail: true }])

    run_index_round
  end

  after(:all) do
    @image_host&.stop(true)
  end

  before(:each) do
    login_admin_and_select_repository(@repository)
  end

  def expect_fallback_icon(digital_object, image_url)
    visit "digital_objects/#{digital_object.id}"

    within '#infinite-tree-record-pane' do
      expect(page).to have_css(".digital-object-thumbnail img[src='#{image_url}']", visible: :hidden)
      expect(page).to have_css('.digital-object-thumbnail .digital-object-thumbnail-fallback.fa-file-image', visible: true)
    end
  end

  it 'shows the generic icon in place of a thumbnail that cannot be reached' do
    expect_fallback_icon(@unreachable, unreachable_image)
  end

  it 'shows the generic icon in place of a thumbnail in a format the browser cannot display' do
    expect_fallback_icon(@tiff, unrenderable_tiff_image)
  end

  it 'links the generic icon of a thumbnail without a display link to the file of its image (ANW-3001)' do
    expect_fallback_icon(@unreachable, unreachable_image)

    within '#infinite-tree-record-pane' do
      expect(page).to have_css(".digital-object-thumbnail a[href='#{unreachable_image}'][target='_blank'][rel='noopener'] .digital-object-thumbnail-fallback", visible: true)
      expect(page).to have_css(".digital-object-thumbnail a[href='#{unreachable_image}'] .sr-only", text: 'Opens in new window', visible: :all)
    end
  end

  it 'links the generic icon of a thumbnail in a data: uri to download its file (ANW-3001)' do
    expect_fallback_icon(@tiff, unrenderable_tiff_image)

    within '#infinite-tree-record-pane' do
      expect(page).to have_css(".digital-object-thumbnail a[href='#{unrenderable_tiff_image}'][download]:not([target]) .digital-object-thumbnail-fallback", visible: true)
      expect(page).to have_css(".digital-object-thumbnail a[href*='image/tiff'] .sr-only", text: 'Download file', visible: :all)
    end
  end

  it 'shows a thumbnail image the browser can display without a link, when there is no display link (ANW-3001)' do
    visit "digital_objects/#{@loadable.id}"

    within '#infinite-tree-record-pane' do
      expect(page).to have_css(".digital-object-thumbnail img[src='#{@loadable_image}']", visible: true) { |image|
        image.evaluate_script('this.complete && this.naturalWidth > 0')
      }
      # Only shown with the generic icon
      expect(page).to have_css(".digital-object-thumbnail a[href='#{@loadable_image}']", visible: :hidden)
      expect(page).not_to have_css('.digital-object-thumbnail a')
    end
  end

  it 'shows a linked SVG image without a width of its own (ANW-3091)' do
    visit "digital_objects/#{@svg.id}"

    within '#infinite-tree-record-pane' do
      image = find(".digital-object-thumbnail a[href='#{svg_image}'] img[src='#{svg_image}']", visible: true)
      expect(image.evaluate_script('this.getBoundingClientRect().width')).to be > 0
    end
  end
end
