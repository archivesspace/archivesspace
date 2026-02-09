require 'spec_helper'

describe ObjectsController, type: :controller do
  img_uri1 = 'http://foo.com/image.jpg'
  img_uri2 = 'http://foo.com/image2.jpg'
  img_uri3 = 'http://foo.com/image3.jpg'
  img_uri4 = 'http://foo.com/image4.jpg'
  img_uri5 = 'http://foo.com/image5.jpg'
  caption1 = 'caption1'
  caption2 = 'caption2'
  additional_file_versions_accordion_css = '#res_accordion > .card > #additional_file_versions_list'
  additional_file_version_css = '#additional_file_versions_list li[data-additional-file-version]'

  before(:all) do
    @repo = create(:repo, repo_code: "do_test_#{Time.now.to_i}",
                   publish: true)
    set_repo @repo
    run_indexers
  end

  describe 'Digital Objects' do
    render_views

    before(:all) do
      @do1 = create(:digital_object, publish: true, :file_versions => [
        build(:file_version, {
          :publish => true,
          :is_representative => false,
          :file_uri => img_uri1,
          :caption => caption1,
          :use_statement => 'image-thumbnail',
          :xlink_show_attribute => 'embed',
        }),
        build(:file_version, {
          :publish => true,
          :is_representative => true,
          :file_uri => img_uri2,
          :use_statement => 'image-service'
        }),
        build(:file_version, {
          :publish => true,
          :is_representative => false,
          :file_uri => img_uri3,
          :use_statement => 'image-service'
        }),
        build(:file_version, {
          :publish => true,
          :is_representative => false,
          :file_uri => img_uri4,
          :use_statement => 'image-service',
          :caption => caption2,
        }),
        build(:file_version, {
          :publish => true,
          :is_representative => false,
          :file_uri => img_uri5,
          :use_statement => '',
        })
      ])

      @do3 = create(:digital_object, publish: true, :file_versions => [
        build(:file_version, {
          :publish => true,
          :is_representative => false,
          :file_uri => 'data:ABC123',
          :xlink_show_attribute => "new", # can't be 'embed'!
        })
      ])

      @do4 = create(:digital_object, publish: true, :file_versions => [
        build(:file_version, {
          :publish => true,
          :is_representative => false,
          :file_uri => 'http://testing',
          :xlink_show_attribute => "new", # can't be 'embed'!
        })
      ])

      @do5 = create(:digital_object, publish: true, :file_versions => [
        build(:file_version, {
          :publish => true,
          :is_representative => false,
          :file_uri => 'not_http_or_data',
          :xlink_show_attribute => "new",  # can't be 'embed'!
        })
      ])

      run_indexers
    end

    it "shows a thumbnail image when set" do
      get(:show, params: { rid: @repo.id, obj_type: 'digital_objects', id: @do1.id })
      thumbnail_css = '.pui-thumbnail'
      image_css = ".pui-thumbnail img[src='#{img_uri1}']"
      link_css = ".pui-thumbnail a[href='#{img_uri2}']"
      page = response.body
      expect(page).to have_css(thumbnail_css)
      expect(page).to have_css(image_css)
      expect(page).to have_css(link_css)
    end

    it "shows a 'generic icon' if no thumbnail is set, the "\
         "file version is published, and is not marked as embed and file_uri is a link" do

      get(:show, params: { rid: @repo.id, obj_type: 'digital_objects', id: @do3.id })
      thumbnail_css = '.pui-thumbnail'
      page = response.body
      expect(page).not_to have_css(thumbnail_css)

      get(:show, params: { rid: @repo.id, obj_type: 'digital_objects', id: @do4.id })
      thumbnail_1 = '.pui-thumbnail'
      icon_css_1 = '.pui-thumbnail .pui-thumbnail-icon'
      link_css_1 = ".pui-thumbnail a[href='http://testing']"
      page_1 = response.body
      expect(page_1).to have_css(thumbnail_1)
      expect(page_1).to have_css(icon_css_1)
      expect(page_1).to have_css(link_css_1)

      get(:show, params: { rid: @repo.id, obj_type: 'digital_objects', id: @do5.id })
      thumbnail_css_2 = '.pui-thumbnail'
      page_2 = response.body
      expect(page_2).not_to have_css(thumbnail_css_2)
    end
  end

  describe 'Digital Object Components' do
    render_views

    before(:all) do
      @do2 = create(:digital_object, publish: true)

      @doc = create(
        :digital_object_component,
        publish: true,
        digital_object: { ref: @do2.uri },
        :file_versions => [
          build(:file_version, {
            :publish => true,
            :is_representative => false,
            :file_uri => img_uri1,
            :use_statement => 'image-thumbnail',
            :xlink_show_attribute => 'embed',
          }),
          build(:file_version, {
            :publish => true,
            :is_representative => true,
            :file_uri => img_uri2,
            :use_statement => 'image-service'
          }),
          build(:file_version, {
            :publish => true,
            :is_representative => false,
            :file_uri => img_uri3,
            :use_statement => 'image-service'
          })
        ]
      )

      run_indexers
    end

    it "shows a thumbnail image when set" do
      get(:show, params: { rid: @repo.id, obj_type: 'digital_object_components', id: @doc.id })
      thumbnail_css = '.pui-thumbnail'
      image_css = ".pui-thumbnail img[src='#{img_uri1}']"
      link_css = ".pui-thumbnail a[href='#{img_uri2}']"
      page = response.body
      expect(page).to have_css(thumbnail_css)
      expect(page).to have_css(image_css)
      expect(page).to have_css(link_css)
    end

  end

  describe 'Archival Objects' do
    render_views

    before(:all) do
      @fv_thumbnail_uri = 'https://www.archivesspace.org/demos/Congreave%20E-4/ms292_008.jpg'
      @fv_master_uri = 'https://www.archivesspace.org/demos/testing_master_image.jpg'
      @fv_caption = 'arch_obj_with_thumbnail caption'

      @resource = create(:resource, publish: true, title: 'Resource with child')

      @digital_object_with_rep_file_ver = create(:digital_object,
                                                 publish: true,
                                                 title: 'Digital object with representative file version',
                                                 :file_versions => [
                                                   build(:file_version, {
                                                     :publish => true,
                                                     :file_uri => @fv_thumbnail_uri,
                                                     :use_statement => 'image-thumbnail',
                                                     :xlink_show_attribute => 'embed',
                                                     :caption => @fv_caption,
                                                   }),
                                                   build(:file_version, {
                                                     :publish => true,
                                                     :is_representative => true,
                                                     :file_uri => @fv_master_uri,
                                                     :use_statement => 'image-service'
                                                   })]
      )

      @arch_obj_with_thumbnail = create(:archival_object,
                                        title: "Archival Object with representative file version",
                                        publish: true,
                                        resource: {'ref' => @resource.uri},
                                        instances: [build(:instance_digital,
                                                          digital_object: {'ref' => @digital_object_with_rep_file_ver.uri},
                                                          is_representative: true
                                                    )]
      )

      run_indexers
    end

    describe 'show action' do
      it "shows a thumbnail image when set" do
        get(:show, params: { rid: @repo.id, obj_type: 'archival_objects', id: @arch_obj_with_thumbnail.id })
        thumbnail_css = '.pui-thumbnail'
        image_css = ".pui-thumbnail img[src='#{@fv_thumbnail_uri}']"
        link_css = ".pui-thumbnail a[href='#{@fv_master_uri}']"
        caption_css = ".pui-thumbnail .pui-thumbnail-caption"
        page = response.body
        expect(page).to have_css(thumbnail_css)
        expect(page).to have_css(image_css)
        expect(page).to have_css(link_css)

        Capybara.string(page).find(:css, caption_css) do |fc|
          expect(fc.text).to have_content(@fv_caption)
        end
      end
    end
  end
end
