# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Infinite Tree Toolbar Action Contracts', js: true do
  include_context 'infinite tree integration setup'

  let(:edit_path) { "/resources/#{resource.id}/edit" }
  let(:root_hash) { "#tree::resource_#{resource.id}" }

  let!(:ao2) do
    create(
      :archival_object,
      resource: { 'ref' => resource.uri },
      title: "Second AO #{now}"
    )
  end

  def install_toolbar_event_capture
    page.execute_script(<<~JS)
      window.__itreeToolbarEvents = [];
      const names = [
        'infiniteTreeToolbar:reorderModeChanged',
        'infiniteTreeToolbar:expandModeChanged',
        'infiniteTreeToolbar:collapseTreeRequested',
        'infiniteTreeToolbar:addChildRequested',
        'infiniteTreeToolbar:addSiblingRequested',
        'infiniteTreeToolbar:addDuplicateRequested',
        'infiniteTreeToolbar:loadBulkRequested',
        'infiniteTreeToolbar:rdeRequested',
        'infiniteTreeToolbar:moveMenuRequested',
        'infiniteTreeToolbar:cutRequested',
        'infiniteTreeToolbar:pasteRequested',
        'infiniteTreeToolbar:finishEditingRequested'
      ];
      names.forEach(function(name) {
        document.addEventListener(name, function(event) {
          window.__itreeToolbarEvents.push({ name: event.type, detail: event.detail || {} });
        });
      });
    JS
  end

  def event_count(name)
    page.evaluate_script("window.__itreeToolbarEvents.filter(function(e){ return e.name === '#{name}'; }).length")
  end

  def event_names
    page.evaluate_script('window.__itreeToolbarEvents.map(function(e){ return e.name; })')
  end

  def last_event_detail
    page.evaluate_script('window.__itreeToolbarEvents[window.__itreeToolbarEvents.length - 1].detail')
  end

  # detail includes a DOM node; full detail does not round-trip through evaluate_script.
  def contextual_event_metadata(event_name)
    page.evaluate_script(<<~JS)
      (function() {
        var ev = window.__itreeToolbarEvents.find(function(e) {
          return e.name === '#{event_name}';
        });
        if (!ev || !ev.detail) return {};
        return {
          rootType: ev.detail.rootType,
          rootUri: ev.detail.rootUri
        };
      })();
    JS
  end

  before do
    visit "#{edit_path}#{root_hash}"
    wait_for_ajax
    install_toolbar_event_capture
  end

  describe 'Mode controls' do
    it 'emits events with expected details' do
      # Expand/collapse controls are hidden while reorder mode is on — exercise them first.
      find('.js-itree-toolbar-expand-mode').click
      expect(event_names).to include('infiniteTreeToolbar:expandModeChanged')
      expect(last_event_detail['enabled']).to be(true)

      find('.js-itree-toolbar-collapse-tree').click
      expect(event_names).to include('infiniteTreeToolbar:collapseTreeRequested')
      expect(last_event_detail).to eq({})

      find('.js-itree-toolbar-reorder-toggle').click
      expect(event_names).to include('infiniteTreeToolbar:reorderModeChanged')
      expect(last_event_detail['enabled']).to be(true)
    end
  end

  describe 'Contextual actions' do
    it 'emits events with root metadata' do
      find('.js-itree-toolbar-add-child').click
      select_tree_row(ao)

      %w[
        .js-itree-toolbar-add-sibling
        .js-itree-toolbar-add-duplicate
        .js-itree-toolbar-load-bulk
      ].each { |selector| find(selector).click }

      # Bulk modal opens synchronously; click RDE before dirty-state re-gating disables it.
      page.execute_script("document.querySelector('.js-itree-toolbar-rde').click()")

      names = event_names
      expect(names).to include(
        'infiniteTreeToolbar:addChildRequested',
        'infiniteTreeToolbar:addSiblingRequested',
        'infiniteTreeToolbar:addDuplicateRequested',
        'infiniteTreeToolbar:loadBulkRequested',
        'infiniteTreeToolbar:rdeRequested'
      )

      metadata = contextual_event_metadata('infiniteTreeToolbar:addChildRequested')
      expect(metadata['rootType']).to eq('resource')
      expect(metadata['rootUri']).to eq(resource.uri)
    end
  end

  describe 'Cut and paste actions' do
    before do
      enable_reorder_mode
      select_tree_row(ao)
    end

    it 'emits cutRequested and pasteRequested when buttons are clicked' do
      click_infinite_tree_toolbar_cut
      select_tree_row(ao2)
      click_infinite_tree_toolbar_paste

      expect(event_names).to include(
        'infiniteTreeToolbar:cutRequested',
        'infiniteTreeToolbar:pasteRequested'
      )
    end
  end

  describe 'Move menu actions' do
    before do
      enable_reorder_mode
      select_tree_row(child_record)
    end

    it 'emits moveMenuRequested when the Move toggle is clicked' do
      click_infinite_tree_toolbar_move_menu
      expect(event_names).to include('infiniteTreeToolbar:moveMenuRequested')
    end
  end

  context 'while controls are disabled by dirty state' do
    before { fill_in 'resource_title_', with: 'Modified Title' }

    it 'does not emit mutating action events' do
      expect(page).to have_css('.js-itree-toolbar-add-child.disabled')
      expect(page).to have_css('.js-itree-toolbar-finish-editing.disabled')

      before_add_child_events = event_count('infiniteTreeToolbar:addChildRequested')
      before_finish_events = event_count('infiniteTreeToolbar:finishEditingRequested')

      find('.js-itree-toolbar-add-child').click

      after_add_child_events = event_count('infiniteTreeToolbar:addChildRequested')
      after_finish_events = event_count('infiniteTreeToolbar:finishEditingRequested')

      expect(after_add_child_events).to eq(before_add_child_events)
      expect(after_finish_events).to eq(before_finish_events)
    end
  end

  describe 'Finish editing' do
    it 'preserves hash in target URL' do
      page.execute_script(<<~JS)
        var container = document.getElementById('infinite-tree-container');
        container.addEventListener('infiniteTreeToolbar:finishEditingRequested', function(event) {
          window.sessionStorage.setItem('itreeFinishTarget', event.detail.target);
        });
      JS

      find('.js-itree-toolbar-finish-editing').click

      finish_target = page.evaluate_script("window.sessionStorage.getItem('itreeFinishTarget')")
      expect(finish_target).to include("/resources/#{resource.id}")
      expect(finish_target).to include(root_hash)
    end
  end
end
