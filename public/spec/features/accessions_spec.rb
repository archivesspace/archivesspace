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
        expect(page).to have_content("Showing Unprocessed Materials: 1 - 4 of 4")
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

    it 'displays an related accessions on the show page' do
      pending 'test failing because indexer wont pick up test data created in spec_helper.rb:73'
      # Indexer error displayed: E, [2021-04-28T15:40:15.180815 #85739] ERROR -- : Thread-2046: SolrIndexerError when indexing records: {"responseHeader":{"status":400,"QTime":68},"error":{"msg":"Error parsing JSON field value. Unexpected OBJECT_START","code":400}}
      visit '/accessions'
      click_link 'Accession with Relationship'
      expect(page).to have_content('Published Accession')
      expect(page).to_not have_content('Unpublished Accession')
    end
  end
end
