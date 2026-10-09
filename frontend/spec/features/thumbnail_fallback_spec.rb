# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Thumbnail fallback icon', js: true do
  # Nothing listens on port 1, so the browser fails to load the image straight away
  unreachable_image = 'http://127.0.0.1:1/thumbnail.jpg'
  # A valid 1x1 TIFF: a format neither Chrome nor Firefox can display
  tiff_image = 'data:image/tiff;base64,SUkqAAgAAAAJAAABAwABAAAAAQAAAAEBAwABAAAAAQAAAAIBAwABAAAACAAAAAMBAwABAAAAAQAAAAYBAwABAAAAAQAAABEBBAABAAAAegAAABUBAwABAAAAAQAAABYBAwABAAAAAQAAABcBBAABAAAAAQAAAAAAAAD/'

  before(:all) do
    @repository = create(:repo, repo_code: "thumbnail_fallback_test_#{Time.now.to_i}")
    set_repo @repository

    @unreachable = create(:digital_object, title: 'Unreachable thumbnail', digital_object_type: 'still_image',
                                           file_versions: [{ file_uri: unreachable_image, publish: true, is_display_thumbnail: true }])
    @tiff = create(:digital_object, title: 'TIFF thumbnail', digital_object_type: 'still_image',
                                    file_versions: [{ file_uri: tiff_image, file_format_name: 'tiff', publish: true, is_display_thumbnail: true }])

    run_index_round
  end

  before(:each) do
    login_admin
    select_repository(@repository)
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
    expect_fallback_icon(@tiff, tiff_image)
  end
end
