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
          :file_uri => 'data:',
          :xlink_show_attribute => "new", # can't be 'embed'!
        })
      ])

      @do4 = create(:digital_object, publish: true, :file_versions => [
        build(:file_version, {
          :publish => true,
          :is_representative => false,
          :file_uri => 'http',
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

    it "shows a 'generic icon' if no representative file version is set, the "\
       "file version is published, and the file uri starts with 'http' or 'data:'" do

      get(:show, params: { rid: @repo.id, obj_type: 'digital_objects', id: @do3.id })
      icon_css = '.external-digital-object__link[href="data:"]'
      page = response.body
      expect(page).to have_css(icon_css)

      get(:show, params: { rid: @repo.id, obj_type: 'digital_objects', id: @do4.id })
      icon_css_1 = '.external-digital-object__link[href="http"]'
      page_1 = response.body
      expect(page_1).to have_css(icon_css_1)

      get(:show, params: { rid: @repo.id, obj_type: 'digital_objects', id: @do5.id })
      icon_css_2 = '.external-digital-object__link[href="not_http_or_data"]'
      page_2 = response.body
      expect(page_2).not_to have_css(icon_css_2)
    end

    describe 'additional file versions' do
      it 'not designated as representative when there is a representative, are listed '\
         'in an Additional File Versions accordion' do
        get(:show, params: { rid: @repo.id, obj_type: 'digital_objects', id: @do1.id })
        page = response.body
        expect(page).to have_css(additional_file_versions_accordion_css)
        expect(page).to have_css(additional_file_version_css, :count => 4)
      end

      it 'with a caption should display text of caption and link to uri' do
        get(:show, params: { rid: @repo.id, obj_type: 'digital_objects', id: @do1.id })
        page = response.body
        expect(page).to have_css("#{additional_file_versions_accordion_css} a[href='#{img_uri1}']", :text => caption1)
        expect(page).to have_css("#{additional_file_versions_accordion_css} a[href='#{img_uri4}']", :text => caption2)
      end

      it 'with a use statement and no caption should display text of use statement and link to uri' do
        get(:show, params: { rid: @repo.id, obj_type: 'digital_objects', id: @do1.id })
        page = response.body
        expect(page).to have_css("#{additional_file_versions_accordion_css} a[href='#{img_uri3}']", :text => 'image-service')
      end

      it 'with no caption or use statement should display text of the uri and link to the uri' do
        get(:show, params: { rid: @repo.id, obj_type: 'digital_objects', id: @do1.id })
        page = response.body
        expect(page).to have_css("#{additional_file_versions_accordion_css} a[href='#{img_uri5}']", :text => img_uri5)
      end
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
            :use_statement => 'image-service'
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

    it 'should display additional published File Versions not designated as representative in an Additional File Versions accordion' do
      get(:show, params: { rid: @repo.id, obj_type: 'digital_object_components', id: @doc.id })

      page = response.body

      additional_file_versions_accordion_css = '#res_accordion > .card > #additional_file_versions_list'
      additional_file_version_css = '#additional_file_versions_list li[data-additional-file-version]'

      expect(page).to have_css(additional_file_versions_accordion_css)
      expect(page).to have_css(additional_file_version_css, :count => 2)
    end

  end

  describe 'Archival Objects' do
    render_views

    before(:all) do
      @fv_uri = 'https://www.archivesspace.org/demos/Congreave%20E-4/ms292_008.jpg'
      @fv_caption = 'arch_obj_with_rep_file_ver caption'

      @resource = create(:resource, publish: true, title: 'Resource with child')

      @digital_object_with_rep_file_ver = create(:digital_object,
        publish: true,
        title: 'Digital object with representative file version',
        :file_versions => [build(:file_version, {
          :publish => true,
          :is_representative => true,
          :file_uri => @fv_uri,
          :caption => @fv_caption,
          :use_statement => 'image-service'
        })]
      )

      @arch_obj_with_rep_file_ver = create(:archival_object,
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
      it 'displays a representative file version image and caption when set' do
        get(:show, params: {rid: @repo.id, obj_type: 'archival_objects', id: @arch_obj_with_rep_file_ver.id})

        expect(response).to render_template("shared/_representative_file_version_record")
        page = Capybara.string(response.body)
        expect(page).to have_css("figure[data-rep-file-version-wrapper] img[src='#{@fv_uri}']")
        page.find(:css, 'figure[data-rep-file-version-wrapper] figcaption') do |fc|
          expect(fc.text).to have_content(@fv_caption)
        end
      end
    end

  end

end
