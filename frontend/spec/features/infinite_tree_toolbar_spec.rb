# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Infinite Tree Toolbar', js: true do
  include_context 'infinite tree integration setup'

  let(:edit_path) { "/resources/#{resource.id}/edit" }
  let(:root_hash) { "#tree::resource_#{resource.id}" }
  let(:ao_hash) { "#tree::archival_object_#{ao.id}" }

  before do
    visit edit_path
    wait_for_ajax
  end

  it 'renders expected controls in resources edit context' do
    within '#infinite-tree-toolbar' do
      aggregate_failures do
        expect(page).to have_css('.js-itree-toolbar-reorder-toggle', text: I18n.t('actions.enable_reorder'))
        expect(page).to have_css('.js-itree-toolbar-expand-mode', text: I18n.t('actions.expand_tree_mode_on'))
        expect(page).to have_css('.js-itree-toolbar-collapse-tree', text: I18n.t('actions.collapse_tree'))
        expect(page).to have_css('.js-itree-toolbar-add-child', text: I18n.t('resource._frontend.action.add_child'))
        expect(page).to have_css('.js-itree-toolbar-load-bulk', text: I18n.t('resource._frontend.action.load_bulk'))
        expect(page).to have_css('#load_via_spreadsheet_help_icon', visible: true)
        expect(page).to have_css('.js-itree-toolbar-rde', text: I18n.t('actions.rapid_data_entry'))
        expect(page).to have_css('.js-itree-toolbar-finish-editing', text: I18n.t('actions.finish_editing'))
        expect(page).to have_no_css('.js-itree-toolbar-cut', visible: true)
        expect(page).to have_no_css('.js-itree-toolbar-paste', visible: true)
        expect(page).to have_no_css('.js-itree-toolbar-move-toggle', visible: true)
        expect(page).to have_no_css('.js-itree-toolbar-add-sibling', visible: true)
        expect(page).to have_no_css('.js-itree-toolbar-add-duplicate', visible: true)
      end
    end
  end

  it 'shows add sibling and add duplicate when an archival object is selected' do
    within '#infinite-tree-container' do
      click_link ao.title
    end

    within '#infinite-tree-toolbar' do
      aggregate_failures do
        expect(page).to have_css('.js-itree-toolbar-add-sibling', text: I18n.t('archival_object._frontend.action.add_sibling'))
        expect(page).to have_css('.js-itree-toolbar-add-duplicate', text: I18n.t('archival_object._frontend.action.add_duplicate'))
        expect(page).to have_no_css('.js-itree-toolbar-move-toggle', visible: true)
      end
    end
  end

  it 'shows cut/paste and move only in reorder mode for archival object selection' do
    find('.js-itree-toolbar-reorder-toggle').click

    within '#infinite-tree-toolbar' do
      aggregate_failures do
        expect(page).to have_css('.js-itree-toolbar-reorder-toggle', text: I18n.t('actions.reorder_active'))
        expect(page).to have_css('.js-itree-toolbar-cut', text: I18n.t('actions.cut'))
        expect(page).to have_css('.js-itree-toolbar-paste', text: I18n.t('actions.paste'))
        expect(page).to have_css('.js-itree-toolbar-drop-behavior-group', visible: true)
        expect(page).to have_css('#infinite-drop-before', visible: false)
        expect(page).to have_css('#infinite-drop-into', visible: false)
        expect(page).to have_css('#infinite-drop-after', visible: false)
        expect(page).to have_no_css('.js-itree-toolbar-move-toggle', visible: true)
        expect(page).to have_no_css('.js-itree-toolbar-expand-mode', visible: true)
        expect(page).to have_no_css('.js-itree-toolbar-collapse-tree', visible: true)
        expect(page).to have_no_css('.js-itree-toolbar-add-child', visible: true)
        expect(page).to have_no_css('.js-itree-toolbar-add-sibling', visible: true)
        expect(page).to have_no_css('.js-itree-toolbar-add-duplicate', visible: true)
        expect(page).to have_no_css('.js-itree-toolbar-load-bulk', visible: true)
        expect(page).to have_css('#load_via_spreadsheet_help_icon', visible: :hidden)
        expect(page).to have_no_css('.js-itree-toolbar-rde', visible: true)
        expect(page).to have_css('.js-itree-toolbar-finish-editing', text: I18n.t('actions.finish_editing'))
      end
    end

    within '#infinite-tree-container' do
      click_link ao.title
    end

    within '#infinite-tree-toolbar' do
      expect(page).to have_css('.js-itree-toolbar-move-toggle', text: I18n.t('actions.move'))
    end
  end

  it 'defaults to before drop behavior' do
    expect(find('#infinite-drop-before', visible: false)).to be_checked
    expect(find('#infinite-drop-into', visible: false)).not_to be_checked
    expect(find('#infinite-drop-after', visible: false)).not_to be_checked
  end

  it 'toggles reorder and expand mode button labels' do
    reorder_btn = find('.js-itree-toolbar-reorder-toggle')
    expand_btn = find('.js-itree-toolbar-expand-mode')

    reorder_btn.click
    expect(page).to have_css('.js-itree-toolbar-reorder-toggle.active')

    reorder_btn.click
    expect(page).to have_no_css('.js-itree-toolbar-reorder-toggle.active')

    expand_btn.click
    expect(page).to have_css('.js-itree-toolbar-expand-mode.btn-success')

    expand_btn.click
    expect(page).to have_no_css('.js-itree-toolbar-expand-mode.btn-success')
  end

  context 'with a nested archival object' do
    let(:ao_nested) do
      create(
        :archival_object,
        resource: { 'ref' => resource.uri },
        parent: { 'ref' => ao.uri },
        title: "Nested Archival Object #{now}"
      )
    end

    before do
      ao_nested
      visit edit_path
      wait_for_ajax
    end

    it 'toggles expand-all on the container and collapses expanded nodes (LargeTree parity)' do
      expect(page).to have_no_css('#infinite-tree-container.expand-all')

      click_on I18n.t('actions.expand_tree_mode_on')
      expect(page).to have_css('#infinite-tree-container.expand-all', wait: 10)
      expect(page).to have_link(ao_nested.title, wait: 15)

      click_on I18n.t('actions.collapse_tree')
      expect(page).to have_no_css('#infinite-tree-container.expand-all', wait: 10)
      expect(page).to have_no_css('li.node:not(.root)[aria-expanded="true"]', wait: 15)
    end
  end

  it 'disables and re-enables mutating controls for dirty and clean record pane states' do
    within '#infinite-tree-container' do
      click_link ao.title
    end
    wait_for_ajax

    page.execute_script <<~JS
      const pane = document.querySelector('#infinite-tree-record-pane');
      pane.dispatchEvent(new CustomEvent('infiniteTreeRecordPane:dirty', { bubbles: true }));
    JS

    %w[
      .js-itree-toolbar-add-child
      .js-itree-toolbar-add-sibling
      .js-itree-toolbar-add-duplicate
      .js-itree-toolbar-load-bulk
      .js-itree-toolbar-rde
      .js-itree-toolbar-finish-editing
    ].each do |selector|
      expect(page).to have_css("#{selector}.disabled")
    end

    page.execute_script <<~JS
      const pane = document.querySelector('#infinite-tree-record-pane');
      pane.dispatchEvent(new CustomEvent('infiniteTreeRecordPane:clean', { bubbles: true }));
    JS

    %w[
      .js-itree-toolbar-add-child
      .js-itree-toolbar-add-sibling
      .js-itree-toolbar-add-duplicate
      .js-itree-toolbar-load-bulk
      .js-itree-toolbar-rde
      .js-itree-toolbar-finish-editing
    ].each do |selector|
      expect(page).to have_no_css("#{selector}.disabled")
    end
  end

  it 'navigates to non-edit URL preserving hash when finish editing is clicked' do
    visit "#{edit_path}#{ao_hash}"
    wait_for_ajax

    find('.js-itree-toolbar-finish-editing').click

    expect(page).to have_current_path(%r{/resources/#{resource.id}(#tree::archival_object_#{ao.id})?$}, url: true)
    expect(page.current_url).not_to include('/edit')
    expect(page.current_url).to include(ao_hash)
  end

  context 'Move menu in reorder mode' do
    before do
      find('.js-itree-toolbar-reorder-toggle').click
    end

    it 'does not show Move when the resource root is selected' do
      within '#infinite-tree-toolbar' do
        expect(page).to have_no_css('.js-itree-toolbar-move-toggle', visible: true)
      end
    end

    it 'shows no Move actions when the only top-level AO has no siblings' do
      within '#infinite-tree-container' do
        click_link ao.title
      end
      wait_for_ajax

      find('.js-itree-toolbar-move-toggle').click
      within '.js-itree-toolbar-move-menu' do
        expect(page).to have_no_css('button.js-itree-toolbar-move-option')
      end
    end
  end

  context 'with two sibling archival objects' do
    let(:ao2) do
      create(
        :archival_object,
        resource: { 'ref' => resource.uri },
        title: "Second Archival Object #{now}"
      )
    end

    before do
      ao2
      visit edit_path
      wait_for_ajax
    end

    context 'in reorder mode' do
      before do
        find('.js-itree-toolbar-reorder-toggle').click
      end

      it 'Move menu for the first sibling shows Down and Down Into... only' do
        within '#infinite-tree-container' do
          click_link ao.title
        end
        wait_for_ajax

        find('.js-itree-toolbar-move-toggle').click
        within '.js-itree-toolbar-move-menu' do
          expect(page).to have_css('button[data-move-action="down"]', text: I18n.t('actions.move_down'))
          expect(page).to have_css(
            'button[data-move-action="down-into"][data-toggle="dropdown"]',
            text: I18n.t('actions.move_down_into')
          )
          expect(page).to have_no_css('button[data-move-action="up"]')
          expect(page).to have_no_css('button[data-move-action="up-level"]')
        end
      end

      it 'Move menu for the second sibling shows Up and Down Into... only' do
        within '#infinite-tree-container' do
          click_link ao2.title
        end
        wait_for_ajax

        find('.js-itree-toolbar-move-toggle').click
        within '.js-itree-toolbar-move-menu' do
          expect(page).to have_css('button[data-move-action="up"]', text: I18n.t('actions.move_up'))
          expect(page).to have_css(
            'button[data-move-action="down-into"][data-toggle="dropdown"]',
            text: I18n.t('actions.move_down_into')
          )
          # "Down" must not match the separate "Down Into..." control (substring ambiguity).
          expect(page).to have_no_css('button[data-move-action="down"]')
          expect(page).to have_no_css('button[data-move-action="up-level"]')
        end
      end
    end
  end

  context 'with a nested archival object (child of another AO)' do
    let(:ao_nested) do
      create(
        :archival_object,
        resource: { 'ref' => resource.uri },
        parent: { 'ref' => ao.uri },
        title: "Nested Archival Object #{now}"
      )
    end
    let(:nested_ao_hash) { "#tree::archival_object_#{ao_nested.id}" }

    before do
      ao_nested
      visit "#{edit_path}#{nested_ao_hash}"
      wait_for_ajax
    end

    context 'in reorder mode' do
      before do
        find('.js-itree-toolbar-reorder-toggle').click
      end

      it 'Move menu includes Up a Level' do
        find('.js-itree-toolbar-move-toggle').click
        within '.js-itree-toolbar-move-menu' do
          expect(page).to have_button(I18n.t('actions.move_up_a_level'))
        end
      end
    end
  end
end
