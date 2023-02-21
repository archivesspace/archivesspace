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
      @fv_uri = 'https://www.archivesspace.org/demos/Congreave%20E-4/ms292_008.jpg'
      @fv_caption = 'digi_obj_with_rep_file_ver caption'

      @repo = create(:repo,
        repo_code: "acc_show_test_#{Time.now.to_i}",
        publish: true)
      set_repo @repo

      @digi_obj_with_rep_file_ver = create(:digital_object,
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

      @acc_with_rep_instance = create(:accession,
        title: "Accession with representative file version",
        publish: true,
        instances: [build(:instance_digital,
          digital_object: {'ref' => @digi_obj_with_rep_file_ver.uri},
          is_representative: true
        )]
      )
      run_indexers
    end

    it 'displays a representative file version image when set' do
      get(:show, params: {rid: @repo.id, id: @acc_with_rep_instance.id})

      expect(response).to render_template("shared/_representative_file_version_record")
      page = Capybara.string(response.body)
      expect(page).to have_css("figure[data-rep-file-version-wrapper] img[src='#{@fv_uri}']")
      page.find(:css, 'figure[data-rep-file-version-wrapper] figcaption') do |fc|
        expect(fc.text).to have_content(@fv_caption)
      end
    end
  end
end
