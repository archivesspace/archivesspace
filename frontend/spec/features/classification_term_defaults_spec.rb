# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Classification Term Defaults', js: true do
  describe 'Basic Information subform' do
    it 'can link to an agent' do
      login_admin
      visit '/classification_terms/defaults'
      expect(page).not_to have_css('#classification_term_creator__ref__combobox .token-input-token', visible: :all)

      find('#classification_term_creator__ref__combobox .dropdown-toggle').click

      within '#classification_term_creator__ref__combobox' do
        click_on 'Browse'
      end

      within '.modal' do
        find('td', text: 'Administrator').click
      end
      click_on 'Link'

      expect(page).to have_css('#classification_term_creator__ref__combobox .token-input-token', visible: true, text: 'Administrator')
    end
  end

  describe 'Record Links subform' do
    before(:each) do
      repo = create(:repo, repo_code: "classification_term_defaults_test_#{Time.now.to_i}")
      set_repo repo
      @resource1 = create(:resource, title: 'Resource 1')
      @resource2 = create(:resource, title: 'Resource 2')
      run_index_round
      login_admin
      select_repository(repo)
      visit '/classification_terms/defaults'
    end

    it 'can link to records' do
      expect(page).not_to have_css('#classification_term_linked_records_ ul.subrecord-form-list > li')

      click_on 'Add Record Link'
      within 'ul.subrecord-form-list > li:nth-child(1)' do
        find('.dropdown-toggle').click
        click_on 'Browse'
      end
      within '.modal' do
        find('td', text: @resource1.title).click
        click_on 'Link'
      end
      within 'ul.subrecord-form-list > li:nth-child(1)' do
        expect(page).to have_css('.token-input-token', text: @resource1.title)
      end

      click_on 'Add Record Link'
      within 'ul.subrecord-form-list > li:nth-child(2)' do
        find('.dropdown-toggle').click
        click_on 'Browse'
      end
      within '.modal' do
        find('td', text: @resource2.title).click
        click_on 'Link'
      end
      within 'ul.subrecord-form-list > li:nth-child(2)' do
        expect(page).to have_css('.token-input-token', text: @resource2.title)
      end

      expect(page).to have_css('#classification_term_linked_records_ ul.subrecord-form-list > li', count: 2)
    end
  end
end
