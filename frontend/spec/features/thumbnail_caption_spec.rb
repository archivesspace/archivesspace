# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Thumbnail caption', js: true do
  before(:all) do
    @repository = create(:repo, repo_code: "thumbnail_caption_test_#{Time.now.to_i}")
    set_repo @repository

    @digital_object = create(:digital_object, title: 'Thumbnail with markup caption', digital_object_type: 'still_image',
                                              file_versions: [{ file_uri: 'http://127.0.0.1:1/thumbnail.jpg', publish: true, is_display_thumbnail: true,
                                                                caption: '<img src="x" class="caption-markup"/>Markup caption' }])

    run_index_round
  end

  before(:each) do
    login_admin
    select_repository(@repository)
  end

  it 'shows only the text of a caption containing markup' do
    visit "digital_objects/#{@digital_object.id}"

    within '#infinite-tree-record-pane' do
      expect(page).to have_css('.digital-object-thumbnail-caption', text: 'Markup caption')
      expect(page).not_to have_css('.digital-object-thumbnail-caption *', visible: :all)
    end
  end
end
