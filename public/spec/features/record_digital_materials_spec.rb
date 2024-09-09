require 'spec_helper'
require 'rails_helper'

describe 'Digital Materials listing from a record context', js: true do
  before(:each) do
    visit('/')
    click_link 'Collections'
    fill_in 'Search within results', with: 'Resource with digital instance'
    click_button 'Search'
    click_link 'Resource with digital instance'
    click_link 'View Digital Material'
  end

  context 'identified in the breadcrumbs' do
    it 'should display a digital object linked through a published archival object' do
      expect(page).to have_content('AO with DO')
    end

    it 'should not display a digital object linked through an unpublished archival object' do
      expect(page).not_to have_content('AO with DO unpublished')
    end
  end
end
