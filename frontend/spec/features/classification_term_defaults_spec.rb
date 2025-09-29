# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Classification Term Defaults', js: true do
  describe 'Basic Information subform' do
    it 'can link to an agent' do
      login_admin
      visit '/classification_terms/defaults'
      agent_linker = find('#classification_term_creator__ref__combobox')
      dropdown_btn = agent_linker.find('.dropdown-toggle')
      expect(agent_linker).not_to have_css('.token-input-token', visible: :all)

      dropdown_btn.click
      within agent_linker do
        click_on 'Browse'
      end
      within '.modal' do
        find('td', text: 'Administrator').click
      end
      click_on 'Link'

      expect(agent_linker).to have_css('.token-input-token', visible: true, text: 'Administrator')
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
      linked_record_subform = find('#classification_term_linked_records_')

      expect(linked_record_subform).not_to have_css('ul.subrecord-form-list > li')

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
        expect(find('.token-input-token').text).to include @resource1.title
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
        expect(find('.token-input-token').text).to include @resource2.title
      end

      expect(linked_record_subform).to have_css('ul.subrecord-form-list > li', count: 2)
    end
  end
end
