# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Representative File Version', js: true do

  describe 'search listing thumbnail' do
    before(:all) do
      @good_img = 'https://archivesspace.org/wp-content/uploads/2015/06/testimonial_5.jpg'
      @bad_img = 'https://example.com/example.mp3'
      @repo = create(:repo, repo_code: "thumbnail_images_test_#{Time.now.to_i}", publish: true)
      set_repo(@repo)
      @do_good_rep_fv = create(
        :digital_object,
        publish: true,
        title: 'Digital object with supported image',
        file_versions: [
          {
            publish: true,
            is_representative: true,
            file_uri: @good_img,
            use_statement: 'image-thumbnail',
            caption: 'This is a good image'
          }
        ]
      )
      @do_bad_rep_fv = create(
        :digital_object,
        publish: true,
        title: 'Digital object with unsupported image',
        file_versions: [
          {
            publish: true,
            is_representative: true,
            file_uri: @bad_img,
            use_statement: 'image-thumbnail'
          }
        ]
      )

      run_indexer
    end

    before(:each) do
      login_admin
      select_repository(@repo)

      visit "/preferences/#{@repo.id}/edit"
      find('#preference_defaults__digital_object_browse_column_2_')
        .select('Thumbnail Image')
      click_button('Save')
    end

    xit 'is shown when a supported image format is available and includes alt text from its caption' do
      visit '/digital_objects'
      expect(page).to have_css("#tabledSearchResults .representative_file_version > img[src='#{@good_img}'][alt='This is a good image']", visible: :visible)
    end
    it 'is hidden when a supported image format is not available' do
      visit '/digital_objects'
      expect(page).to have_css("#tabledSearchResults .representative_file_version > img[src='#{@bad_img}']", visible: :hidden)
    end
  end
end
