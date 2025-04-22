# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Representative File Version', js: true do
  describe 'search listing thumbnail' do
    before(:each) do
      @repo = create(:repo, repo_code: "thumbnail_images_test_#{Time.now.to_i}", publish: true)
      login_admin
      select_repository(@repo)

      visit "/preferences/#{@repo.id}/edit"
      find('#preference_defaults__digital_object_browse_column_2_')
        .select('Thumbnail Image')
      click_on('Save')

      set_repo(@repo)
      create(
        :digital_object,
        publish: true,
        title: 'Digital object with image',
        file_versions: [
          {
            publish: true,
            is_representative: true,
            file_uri: img_url,
            use_statement: 'image-thumbnail',
            caption: 'This is an image'
          }
        ]
      )

      run_indexer
    end

    context 'when a supported image format is available' do
      let(:img_url) { 'https://archivesspace.org/wp-content/uploads/2015/06/testimonial_5.jpg' }

      it 'is shown and includes alt text from its caption' do
        visit '/digital_objects'
        wait_for_ajax

        expect(page).to have_css("#tabledSearchResults .representative_file_version > img[src='#{img_url}'][alt='This is an image']", visible: :visible)
      end
    end

    context 'when a supported image format is not available' do
      let(:img_url) { 'https://example.com/example.mp3' }

      it 'is hidden' do
        visit '/digital_objects'
        wait_for_ajax
        expect(page).to have_css("#tabledSearchResults .representative_file_version > img[src='#{img_url}']", visible: :hidden)
      end
    end
  end
end
