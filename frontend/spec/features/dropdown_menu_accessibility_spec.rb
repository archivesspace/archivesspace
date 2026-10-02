# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Dropdown menu accessibility', js: true do
  include DropdownMenuAccessibilityHelpers

  before(:all) do
    @repo = create(:repo, repo_code: "dropdown_a11y_#{Time.now.to_i}", publish: true)
    set_repo(@repo)
  end

  before(:each) do
    login_admin
    select_repository(@repo)
  end

  context 'global header' do
    let(:global_header_menu_toggles) do
      {
        'Select Repository' => '.select-a-repository button.dropdown-toggle',
        'System' => '.system-menu button.dropdown-toggle',
        'Repository settings' => 'button[aria-label="Repository settings"]',
        'the user menu' => '#user-menu-dropdown',
        'Plugins' => '.plugin-container button.dropdown-toggle'
      }
    end

    it 'exposes haspopup and toggles expanded state for each menu' do
      aggregate_failures 'plugins system menu' do
        expect(AppConfig[:plugins]).to include('cat_in_a_box')
        expect(Plugins.system_menu_items).to include('cat_in_a_box')
      end

      aggregate_failures 'global header menu toggles' do
        global_header_menu_toggles.each do |label, selector|
          aggregate_failures label do
            expect(page).to have_css(selector), "expected #{label} toggle at #{selector}"
            expect_dropdown_menu_toggle(selector)
          end
        end

        aggregate_failures 'user menu accessible name' do
          user_menu = find('#user-menu-dropdown')
          expect(user_menu[:'aria-label']).to eq(I18n.t('navbar.global_settings'))
        end
      end
    end
  end

  describe 'agent merge dropdown' do
    before do
      agent = create(:agent_person, title: "Dropdown a11y merge agent #{Time.now.to_i}")
      visit "agents/agent_person/#{agent.id}/edit"
    end

    it 'exposes haspopup and toggles expanded state on the merge menu button' do
      expect(page).to have_css('#merge-dropdown .merge-action')
      expect_dropdown_menu_toggle('#merge-dropdown .merge-action')
    end
  end
end
