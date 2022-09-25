require 'spec_helper'
require 'rails_helper'

describe 'Accessions', js: true do
  context 'browsing' do
    it 'should show all published accessions' do
      visit('/')
      click_link 'Unprocessed Material'
      expect(current_path).to eq ('/accessions')
      finished_all_ajax_requests?
      within all('.col-sm-12')[0] do
        expect(page).to have_content("Showing Unprocessed Materials: 1 - 9 of 9")
      end
      within all('.col-sm-12')[1] do
        expect(page.all("a[class='record-title']", text: 'Published Accession').length).to eq 2
      end
    end

    it 'should not show any unpublished accessions' do
      visit('/')
      click_link 'Unprocessed Material'
      expect(current_path).to eq ('/accessions')
      finished_all_ajax_requests?
      within all('.col-sm-12')[1] do
        expect(page.all("a[class='record-title']", text: 'Unpublished Accession')).to be_empty
      end
    end
  end

  context 'viewing a record' do
    it 'displays an accession when the record exists' do
      visit '/accessions'
      click_link 'Published Accession'
      expect(current_path).to match(/repositories\/\d+\/accessions\/\d+/)
      expect(page).to have_content('Published Accession')
    end

    it 'displays language and script of description on an accession show page' do
      visit '/accessions'
      click_link 'Accession with Lang/Script'

      expect(page).to have_content('Language of Description')
      expect(page).to have_content('Script of Description')
    end

    it 'displays an related accessions on the show page', :skip => "UPGRADE skipping for green CI" do
      visit '/accessions'
      click_link 'Accession with Relationship'

      expect(page).to have_content('Published Accession')
      expect(page).to_not have_content('Unpublished Accession')
    end

    it 'displays deaccessions on show page' do
      visit '/accessions'
      click_link 'Accession with Deaccession'
      expect(page).to have_content('Deaccessions')
    end

    it 'displays language of material note on accession show page' do
      visit '/accessions'
      click_link 'Accession with Lang Material Note'

      expect(page).to have_content('Language of Materials')
      within '.upper-record-details' do
        expect(page).to have_css(".langmaterial")
        expect(page).not_to have_css(".language")
      end
    end

    it 'displays language of material language on accession show page if no language note' do
      visit '/accessions'
      click_link 'Accession without Lang Material Note'

      expect(page).to have_content('Language of Materials')
      within '.upper-record-details' do
        expect(page).not_to have_css(".langmaterial")
        expect(page).to have_css(".language")
      end
    end

  end
end
