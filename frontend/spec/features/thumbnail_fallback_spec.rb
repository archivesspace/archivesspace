# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Thumbnail fallback icon', js: true do
  # Nothing listens on port 1, so the browser fails to load the image straight away
  unreachable_image = 'http://127.0.0.1:1/thumbnail.jpg'
  # A valid 1x1 TIFF: a format neither Chrome nor Firefox can display
  tiff_image = 'data:image/tiff;base64,SUkqAAgAAAAJAAABAwABAAAAAQAAAAEBAwABAAAAAQAAAAIBAwABAAAACAAAAAMBAwABAAAAAQAAAAYBAwABAAAAAQAAABEBBAABAAAAegAAABUBAwABAAAAAQAAABYBAwABAAAAAQAAABcBBAABAAAAAQAAAAAAAAD/'
  # A valid 1x1 GIF, which every browser displays
  loadable_image = 'data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7'

  before(:all) do
    @repository = create(:repo, repo_code: "thumbnail_fallback_test_#{Time.now.to_i}")
    set_repo @repository

    @unreachable = create(:digital_object, title: 'Unreachable thumbnail', publish: true, digital_object_type: 'still_image',
                                           file_versions: [{ file_uri: unreachable_image, publish: true, is_display_thumbnail: true }])
    @tiff = create(:digital_object, title: 'TIFF thumbnail', publish: true, digital_object_type: 'still_image',
                                    file_versions: [{ file_uri: tiff_image, file_format_name: 'tiff', publish: true, is_display_thumbnail: true }])
    @loadable = create(:digital_object, title: 'Loadable thumbnail', publish: true, digital_object_type: 'still_image',
                                        file_versions: [{ file_uri: loadable_image, publish: true, is_display_thumbnail: true }])
    @with_fallback_image = resource_with_representative_archival_objects([@unreachable, @loadable])
    @without_loadable_image = resource_with_representative_archival_objects([@unreachable, @tiff])

    run_index_round
  end

  def resource_with_representative_archival_objects(digital_objects)
    resource = create(:resource)
    digital_objects.each do |digital_object|
      create(:archival_object, title: digital_object.title, publish: true, resource: { 'ref' => resource.uri },
                               instances: [build(:instance_digital, digital_object: { ref: digital_object.uri }, is_representative: true)])
    end
    resource
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

  it 'shows the next image, linked to its digital object, in place of a thumbnail the browser cannot display (ANW-3089)' do
    visit "resources/#{@with_fallback_image.id}"

    within '#infinite-tree-record-pane' do
      expect(page).to have_css(".digital-object-thumbnail a[href$='#{CGI.escape(@loadable.uri)}'] img[src='#{loadable_image}']", visible: true)
      expect(page).to have_css(".digital-object-thumbnail img[src='#{unreachable_image}']", visible: :hidden)
      expect(page).not_to have_css('.digital-object-thumbnail-fallback', visible: true)
    end
  end

  it 'shows the generic icon of the first image, linked to its digital object, when the browser cannot display any image (ANW-3089)' do
    visit "resources/#{@without_loadable_image.id}"

    within '#infinite-tree-record-pane' do
      expect(page).to have_css(".digital-object-thumbnail img[src='#{tiff_image}']", visible: :hidden)
      expect(page).to have_css(".digital-object-thumbnail a[href$='#{CGI.escape(@unreachable.uri)}'] .digital-object-thumbnail-fallback.fa-file-image", visible: true)
    end
  end
end
