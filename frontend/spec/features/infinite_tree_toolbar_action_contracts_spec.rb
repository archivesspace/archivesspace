# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Infinite Tree Toolbar Action Contracts', js: true do
  include_context 'infinite tree integration setup'

  let(:edit_path) { "/resources/#{resource.id}/edit" }
  let(:root_hash) { "#tree::resource_#{resource.id}" }

  def execute_js(script)
    page.execute_script(script)
  end

  def evaluate_js(script)
    page.evaluate_script(script)
  end

  def install_toolbar_event_capture
    execute_js(<<~JS)
      window.__itreeToolbarEvents = [];
      const names = [
        'infiniteTreeToolbar:reorderModeChanged',
        'infiniteTreeToolbar:expandModeChanged',
        'infiniteTreeToolbar:collapseTreeRequested',
        'infiniteTreeToolbar:dropBehaviorChanged',
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
    evaluate_js("window.__itreeToolbarEvents.filter(function(e){ return e.name === '#{name}'; }).length")
  end

  def dispatch_record_pane_state(state)
    execute_js(<<~JS)
      const pane = document.querySelector('#infinite-tree-record-pane');
      pane.dispatchEvent(new CustomEvent('infiniteTreeRecordPane:#{state}', { bubbles: true }));
    JS
  end

  def dispatch_toolbar_click(selector)
    execute_js(<<~JS)
      (function() {
        var el = document.querySelector("#{selector}");
        if (!el) return;
        el.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true }));
      })();
    JS
  end

  before do
    visit "#{edit_path}#{root_hash}"
    wait_for_ajax
    install_toolbar_event_capture
  end

  def event_names
    evaluate_js('window.__itreeToolbarEvents.map(function(e){ return e.name; })')
  end

  def last_event_detail
    evaluate_js('window.__itreeToolbarEvents[window.__itreeToolbarEvents.length - 1].detail')
  end

  it 'emits reorder/expand/collapse events with expected details' do
    # Expand/collapse controls are hidden while reorder mode is on — exercise them first.
    find('.js-itree-toolbar-expand-mode').click
    expect(event_names).to include('infiniteTreeToolbar:expandModeChanged')
    expect(last_event_detail['enabled']).to eq(true)

    find('.js-itree-toolbar-collapse-tree').click
    expect(event_names).to include('infiniteTreeToolbar:collapseTreeRequested')
    expect(last_event_detail).to eq({})

    find('.js-itree-toolbar-reorder-toggle').click
    expect(event_names).to include('infiniteTreeToolbar:reorderModeChanged')
    expect(last_event_detail['enabled']).to eq(true)
  end

  it 'emits contextual action events with root metadata' do
    dispatch_toolbar_click('.js-itree-toolbar-add-child')

    within '#infinite-tree-container' do
      click_link ao.title
    end
    wait_for_ajax

    %w[
      .js-itree-toolbar-add-sibling
      .js-itree-toolbar-add-duplicate
      .js-itree-toolbar-load-bulk
      .js-itree-toolbar-rde
    ].each { |selector| dispatch_toolbar_click(selector) }

    names = event_names
    expect(names).to include(
      'infiniteTreeToolbar:addChildRequested',
      'infiniteTreeToolbar:addSiblingRequested',
      'infiniteTreeToolbar:addDuplicateRequested',
      'infiniteTreeToolbar:loadBulkRequested',
      'infiniteTreeToolbar:rdeRequested'
    )

    # detail includes a DOM node; full detail does not round-trip through evaluate_script.
    contextual_detail = evaluate_js(<<~JS)
      (function() {
        var ev = window.__itreeToolbarEvents.find(function(e) {
          return e.name === 'infiniteTreeToolbar:addChildRequested';
        });
        if (!ev || !ev.detail) return {};
        return {
          rootType: ev.detail.rootType,
          rootUri: ev.detail.rootUri
        };
      })();
    JS

    expect(contextual_detail['rootType']).to eq('resource')
    expect(contextual_detail['rootUri']).to eq(resource.uri)
  end

  it 'emits drop behavior changed and persists AS_Drop_Behavior' do
    execute_js <<~JS
      var radio = document.getElementById('infinite-drop-after');
      radio.checked = true;
      var event = document.createEvent('HTMLEvents');
      event.initEvent('change', true, false);
      radio.dispatchEvent(event);
    JS

    expect(event_names).to include('infiniteTreeToolbar:dropBehaviorChanged')
    expect(last_event_detail['dropBehavior']).to eq('after')
    expect(evaluate_js("window.localStorage.getItem('AS_Drop_Behavior')")).to eq('after')

    visit "#{edit_path}#{root_hash}"
    wait_for_ajax
    expect(find('#infinite-drop-after', visible: false)).to be_checked
  end

  it 'does not emit mutating action events while controls are disabled by dirty state' do
    dispatch_record_pane_state('dirty')

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

  it 'emits finish editing with target URL preserving hash' do
    execute_js <<~JS
      var container = document.getElementById('infinite-tree-container');
      container.addEventListener('infiniteTreeToolbar:finishEditingRequested', function(event) {
        window.sessionStorage.setItem('itreeFinishTarget', event.detail.target);
      });
    JS

    find('.js-itree-toolbar-finish-editing').click

    finish_target = evaluate_js("window.sessionStorage.getItem('itreeFinishTarget')")
    expect(finish_target).to include("/resources/#{resource.id}")
    expect(finish_target).to include(root_hash)
  end
end
