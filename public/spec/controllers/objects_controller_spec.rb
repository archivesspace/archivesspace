require 'spec_helper'

describe ObjectsController, type: :controller do
  img_uri1 = 'http://foo.com/image.jpg'
  img_uri2 = 'http://foo.com/image2.jpg'
  img_uri3 = 'http://foo.com/image3.jpg'

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
      ])

      @do3 = create(:digital_object, publish: true, :file_versions => [
        build(:file_version, {
          :publish => true,
          :is_representative => false,
          :file_uri => 'not_http',
        })
      ])

      run_indexers
    end

    it 'should display additional published File Versions not designated as representative in an Additional File Versions accordion' do
      get(:show, params: { rid: @repo.id, obj_type: 'digital_objects', id: @do1.id })

      page = response.body

      additional_file_versions_accordion_css = '#res_accordion > .panel.panel-default > #additional_file_versions_list'
      additional_file_version_css = '#additional_file_versions_list li.additional-file-version'
      additional_file_version_1_src = "#{additional_file_version_css} img[src='#{img_uri1}']"
      additional_file_version_2_src = "#{additional_file_version_css} img[src='#{img_uri3}']"

      expect(page).to have_css(additional_file_versions_accordion_css)
      expect(page).to have_css(additional_file_version_css, :count => 2)
      expect(page).to have_css(additional_file_version_1_src)
      expect(page).to have_css(additional_file_version_2_src)
    end

    it "shows a 'generic icon' if no representative file version is set and the "\
       "file version is published, whether or not the file uri starts with 'http'" do
      get(:show, params: { rid: @repo.id, obj_type: 'digital_objects', id: @do3.id })

      icon_css = '.external-digital-object__link[href="not_http"]'

      page = response.body
      expect(page).to have_css(icon_css)
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

      additional_file_versions_accordion_css = '#res_accordion > .panel.panel-default > #additional_file_versions_list'
      additional_file_version_css = '#additional_file_versions_list li.additional-file-version'
      additional_file_version_1_src = "#{additional_file_version_css} img[src='#{img_uri1}']"
      additional_file_version_2_src = "#{additional_file_version_css} img[src='#{img_uri3}']"

      expect(page).to have_css(additional_file_versions_accordion_css)
      expect(page).to have_css(additional_file_version_css, :count => 2)
      expect(page).to have_css(additional_file_version_1_src)
      expect(page).to have_css(additional_file_version_2_src)
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
