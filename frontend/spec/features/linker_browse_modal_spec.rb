require 'spec_helper'
require 'rails_helper'

describe 'Linker Browse Modal', js: true do
  describe 'results table sorting' do
    let!(:subject1) { create(:subject) }
    let!(:subject2) { create(:subject) }

    before :each do
      run_index_round
      login_admin
    end

    def expect_first_row_title(expected_text)
      expect(page).to have_css('.modal-dialog #tabledSearchResults tbody tr:first-child > td.title', text: expected_text)
    end

    it 'works by sort buttons and column headers' do
      visit 'accessions/new'

      aggregate_failures 'initial ascending sort' do
        expect(page).to have_css('#accession_subjects_')
        click_on 'Add Subject'
        within '#accession_subjects_' do
          find('.linker-wrapper .dropdown-toggle', match: :first).click
          find('.dropdown-menu .linker-browse-btn', match: :first).click
        end
        expect_first_row_title(subject1.title)
      end

      aggregate_failures 'descending sort' do
        within '#pagination-summary-primary-sort-opts' do
          click_on 'Terms Ascending'
          find('a', text: 'Terms').hover
          click_on 'Descending'
        end
        expect_first_row_title(subject2.title)
      end

      aggregate_failures 'final ascending sort' do
        within '.modal-dialog #tabledSearchResults' do
          click_on 'Terms'
        end
        expect_first_row_title(subject1.title)
      end
    end
  end
end
