# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Thumbnail accessibility', js: true do
  before(:all) do
    @repository = create(:repo, repo_code: "thumbnail_a11y_test_#{Time.now.to_i}")
    set_repo @repository

    @digital_object = create(:digital_object, title: 'Thumbnail with a generic icon', digital_object_type: 'moving_image',
                                              file_versions: [{ file_uri: 'https://example.com/video.mp4', publish: true,
                                                                is_display_link: true, caption: 'Video of the event' }])

    run_index_round
  end

  before(:each) do
    login_admin
    select_repository(@repository)
  end

  it 'gives the generic icon an accessible name, so that its link is not empty' do
    visit "digital_objects/#{@digital_object.id}"

    within '#infinite-tree-record-pane' do
      aggregate_failures do
        expect(page).to have_css(".digital-object-thumbnail a i.fa-file-video[role='img'][aria-label='Video of the event']")
        expect(page).not_to have_css('.digital-object-thumbnail a[aria-hidden]')
      end
    end
  end

  it 'hides the thumbnail link in a browse table from screen readers and the keyboard, since it duplicates the row link' do
    set_browse_column_preference('digital_object', 3, 'Thumbnail')
    visit 'digital_objects'

    within '#tabledSearchResults' do
      expect(page).to have_css("td.thumbnail-column .digital-object-thumbnail a[aria-hidden='true'][tabindex='-1'] i.fa-file-video")
    end
  end
end
