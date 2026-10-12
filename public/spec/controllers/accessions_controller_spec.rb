require 'spec_helper'

describe AccessionsController, type: :controller do
  context 'index' do
    it "returns results that include all published accessions" do
      expect(get :index).to have_http_status(200)
      results = assigns(:results)
      expect( results['total_hits'] ).to eq(8)
      expect( results.records.first["title"] ).to eq("Accession for Phrase Search")
      expect( results.records.select { |record| record["title"] == "Unpublished Accession" } ).to be_empty
    end

    describe 'deaccessions in accession results' do
      it 'returns deaccessions when AppConfig[:pui_display_deaccessions] is true' do
        AppConfig[:pui_display_deaccessions] = true
        expect(get :index).to have_http_status(200)
        results = assigns(:results)
        rec_with_deaccession = results.records.find {|x| x["title"] == "Published Accession with Deaccession"}
        expect( rec_with_deaccession.deaccessions ).not_to be_empty
      end

      it 'does not return deaccessions when AppConfig[:pui_display_deaccessions] is false' do
        AppConfig[:pui_display_deaccessions] = false
        expect(get :index).to have_http_status(200)
        results = assigns(:results)
        results.records.each do |rec|
          expect(rec.deaccessions).to be_empty
        end
      end
    end
  end

  describe 'show' do
    render_views

    before(:all) do
      @fv_thumbnail_uri = 'https://www.archivesspace.org/demos/Congreave%20E-4/ms292_008.jpg'
      @fv_master_uri = 'https://www.archivesspace.org/demos/testing_master_image.jpg'
      @fv_thumbnail_caption = 'File version thumbnail caption'
      @fv_master_caption = 'File version master caption'

      @repo = create(:repo,
                     repo_code: "acc_show_test_#{Time.now.to_i}",
                     publish: true)
      set_repo @repo

      @digi_obj_with_rep_file_ver = create(:digital_object,
                                           publish: true,
                                           title: 'Digital object with thumbnail',
                                           :file_versions => [
                                             build(:file_version, {
                                               :publish => true,
                                               :file_uri => @fv_thumbnail_uri,
                                               :caption => @fv_thumbnail_caption,
                                               :use_statement => 'image-thumbnail',
                                               :is_display_thumbnail => true,
                                               :xlink_show_attribute => 'embed',
                                             }),
                                             build(:file_version, {
                                               :publish => true,
                                               :file_uri => @fv_master_uri,
                                               :caption => @fv_master_caption,
                                               :use_statement => 'image-service',
                                               :is_representative => true,
                                             }),
                                           ]
      )

      @acc_with_rep_instance = create(:accession,
                                      title: "Accession with thumbnail file version",
                                      publish: true,
                                      instances: [build(:instance_digital,
                                                        digital_object: {'ref' => @digi_obj_with_rep_file_ver.uri},
                                                        is_representative: true
                                                  )]
      )
      run_indexers
    end

    it 'displays a thumbnail when set' do
      get(:show, params: {rid: @repo.id, id: @acc_with_rep_instance.id})

      expect(response).to render_template("shared/_thumbnail")
      page = Capybara.string(response.body)
      expect(page).to have_css(".pui-thumbnail img[src='#{@fv_thumbnail_uri}']")
      expect(page).to have_css(".pui-thumbnail a[href='#{@fv_master_uri}']")
      page.find(:css, '.pui-thumbnail .pui-thumbnail-caption') do |fc|
        expect(fc.text).to have_content(@fv_thumbnail_caption)
      end
    end
  end
end
