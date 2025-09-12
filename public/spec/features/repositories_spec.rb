require 'spec_helper'
require 'rails_helper'

describe 'Repositories', js: true do
  context 'viewing the list of repositories' do
    describe 'accessibility' do
      before (:each) do
        visit '/'
        click_link 'Repositories'
      end

      it "does not skip heading levels" do
        expect(page).to be_axe_clean.checking_only :'heading-order'
      end
    end
  end

  context 'viewing a repository' do
    before(:each) do
      visit '/'
      click_link 'Repositories'
      first('.record-title').click
    end

    describe 'accessibility' do
      it "does not skip heading levels" do
        expect(page).to be_axe_clean.checking_only :'heading-order'
      end
    end

    it 'should only show archival objects for the record badge' do
      click_button 'Records'
      expect(current_path).to match(/repositories.*records/)
      expect(page).to have_content(/Found.*Test Repo.*Published Resource/)
      expect(page).to have_content('Item')
      expect(page).to_not have_content('Digital Record')
    end

    it 'should only show digital objects for the digital materials badge' do
      click_button 'Digital Materials'
      expect(current_path).to match(/repositories.*digital_objects/)
      expect(page).to have_content(/Found.*Test Repo/)
      expect(page).to have_content('Digital Record')
      expect(page).to_not have_content('Item')
    end
  end
end
