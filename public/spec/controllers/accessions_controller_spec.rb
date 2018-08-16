require 'spec_helper'

describe AccessionsController, type: :controller do
  context 'index' do
    it "returns results that include all published accessions" do
      expect(get :index).to have_http_status(200)
      results = assigns(:results)
      expect( results['total_hits'] ).to eq(3)
      expect( results.records.first["title"] ).to eq("Accession for Phrase Search")
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
        results.records.each do | rec |
          expect(rec.deaccessions).to be_empty
        end
      end
    end
  end
end
