require 'spec_helper'
require 'rails_helper'

describe 'Accessions', js: true do
  context 'browsing' do

    it 'shows a list of ordered accessions' do
      visit('/')
      click_link 'Unprocessed Material'
      expect(current_path).to eq ('/accessions')
      finished_all_ajax_requests?

      within all('.col-sm-12')[0] do
        expect(page).to have_content(/Showing Unprocessed Materials: 1 - \d[0]? of \d{1,2}/)
      end
    end

    it 'lets you click on a search result', js: true do
      visit '/accessions?sort=year_sort+asc'
      click_link 'Published Accession'
      expect(current_path).to match(/repositories\/\d+\/accessions\/\d+/)
      expect(page).to have_content('Published Accession')
    end
  end

  context 'viewing a record' do
    it 'does not highlight repository uri' do
      visit('/')

      click_on 'Repositories'
      click_on 'Test Repo 1'
      find('#whats-in-container form .btn.btn-default.accession').click

      expect(page).to_not have_text Pathname.new(current_path).parent.to_s
    end

    it 'displays language and script of description on an accession show page' do
      visit '/repositories/2/accessions/7'
      expect(page).to have_content('Language of Description')
      expect(page).to have_content('Script of Description')
    end

    it 'displays an related accessions on the show page' do
      visit 'repositories/2/accessions/5'
      expect(page).to have_css('.related-accession', :text => 'Published Accession', :visible => false)
      expect(page).not_to have_css('.related-accession', :text => 'Unpublished Accession', :visible => false)
    end

    it 'displays deaccessions on show page' do
      visit 'repositories/2/accessions/6'
      expect(page).to have_content('Deaccessions')
    end

    it 'displays language of material note on accession show page' do
      visit 'repositories/2/accessions/8'
      expect(page).to have_content('Language of Materials')
      within '.upper-record-details' do
        expect(page).to have_css(".langmaterial")
        expect(page).not_to have_css(".language")
      end
    end

    it 'displays language of material language on accession show page if no language note' do
      visit 'repositories/2/accessions/9'
      expect(page).to have_content('Language of Materials')
      within '.upper-record-details' do
        expect(page).not_to have_css(".langmaterial")
        expect(page).to have_css(".language")
      end
    end

  end
end
