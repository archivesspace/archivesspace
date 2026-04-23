# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Keyboard Shortcuts', js: true do
  context 'available globally' do
    before(:each) do
      login_admin
      visit '/'
      expect(page).not_to have_css('#ASModal', visible: :all)
    end

    it 'can show and hide the shortcuts reference modal' do
      page.driver.browser.action.key_down(:shift).send_keys('?').key_up(:shift).perform
      expect(page).to have_css('#ASModal', visible: true)
      within '#ASModal' do
        expect(page).to have_content('Shift ?')
        expect(page).to have_content('ESC')
        expect(page).to have_content('Ctrl S')
        expect(page).to have_content('Ctrl X')
        expect(page).to have_content('Shift B')
        expect(page).to have_content('Shift C')
      end

      page.driver.browser.action.send_keys(:escape).perform
      expect(page).not_to have_css('#ASModal', visible: :all)
    end

    it 'can open the Browse and Create menus' do
      expect(page).to have_css('.browse-container > .dropdown-menu', visible: false)
      expect(page).to have_css('.create-container > .dropdown-menu', visible: false)

      page.driver.browser.action.key_down(:shift).send_keys('b').key_up(:shift).perform
      expect(page).to have_css('.browse-container > .dropdown-menu', visible: true)
      page.driver.browser.action.key_down(:shift).send_keys('b').key_up(:shift).perform
      expect(page).to have_css('.browse-container > .dropdown-menu', visible: false)

      page.driver.browser.action.key_down(:shift).send_keys('c').key_up(:shift).perform
      expect(page).to have_css('.create-container > .dropdown-menu', visible: true)
      page.driver.browser.action.key_down(:shift).send_keys('c').key_up(:shift).perform
      expect(page).to have_css('.create-container > .dropdown-menu', visible: false)
    end
  end

  let(:now) { Time.now.to_i }
  let(:repo) { create(:repo, repo_code: "keyboard_shortcuts_test_#{now}") }
  let(:accession) { create(:accession, title: "Accession #{now}") }

  context 'available for any record in edit mode' do
    let(:updated_text) { "UPDATED" }

    before do
      set_repo repo
      accession
      login_admin
      select_repository(repo)
      visit "/accessions/#{accession.id}/edit"
    end

    it 'can save the record' do
      expect(page).to have_field('accession_title_', with: accession.title)

      fill_in 'accession_title_', with: updated_text
      page.driver.browser.action.key_down(:control).send_keys('s').key_up(:control).perform
      expect(page).to have_content("Accession #{updated_text} updated")
      expect(page).to have_field('accession_title_', with: updated_text)
    end

    it 'can close the record' do
      page.driver.browser.action.key_down(:control).send_keys('x').key_up(:control).perform
      expect(page).to have_current_path("/accessions/#{accession.id}")
    end
  end
end
