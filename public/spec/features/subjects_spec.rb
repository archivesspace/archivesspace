require 'spec_helper'
require 'rails_helper'

describe 'Subjects', js: true do
  context 'viewing subjects list' do
    it 'should be able to see all subjects' do
      visit('/')
      click_link 'Subjects'
      within all('.col-sm-12')[0] do
        expect(page).to have_content("Showing Subjects: 1 - 2 of 2")
      end

      aggregate_failures 'supporting accessibility by not skipping heading levels' do
        expect(page).to be_axe_clean.checking_only :'heading-order'
      end
    end
  end

  context 'viewing a subject' do
    it 'displays subject page' do
      visit('/')
      click_link 'Subjects'
      click_link 'Term 1'
      expect(current_path).to match(/subjects\/\d+/)
      expect(page).to have_content('Term 1')

      aggregate_failures 'supporting accessibility by not skipping heading levels' do
        expect(page).to be_axe_clean.checking_only :'heading-order'
      end
    end

    it 'does not highlight repository uri' do
      visit('/')

      click_on 'Repositories'
      click_on 'Test Repo 1'
      find('#whats-in-container form .btn.btn-default.subject').click

      expect(page).to_not have_text Pathname.new(current_path).parent.to_s
    end
  end
end
