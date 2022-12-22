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

end
