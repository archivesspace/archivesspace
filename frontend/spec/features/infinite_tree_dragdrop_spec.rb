# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Infinite Tree Drag and Drop (drop intent layer)', js: true do
  include_context 'infinite tree integration setup'

  let(:edit_path) { "/resources/#{resource.id}/edit" }
  let(:root_hash) { "#tree::resource_#{resource.id}" }

  let!(:ao2) do
    create(
      :archival_object,
      resource: { 'ref' => resource.uri },
      title: "Sibling AO #{now}"
    )
  end

  let!(:child_ao) do
    create(
      :archival_object,
      resource: { 'ref' => resource.uri },
      parent: { 'ref' => ao2.uri },
      title: "Child AO #{now}"
    )
  end

  let!(:ao3) do
    create(
      :archival_object,
      resource: { 'ref' => resource.uri },
      title: "Third AO #{now}"
    )
  end

  def execute_js(script)
    page.execute_script(script)
  end

  def evaluate_js(script)
    page.evaluate_script(script)
  end

  def enable_reorder_mode
    find('.js-itree-toolbar-reorder-toggle').click
  end

  def click_row(uri, modifiers = {})
    execute_js(<<~JS)
      (function() {
        var li = document.querySelector("#infinite-tree-container li.node[data-uri='#{uri}']");
        if (!li) throw new Error('no row for #{uri}');
        var row = li.querySelector('.node-row');
        row.dispatchEvent(new MouseEvent('click', {
          bubbles: true,
          cancelable: true,
          view: window,
          metaKey: #{!!modifiers[:meta]},
          ctrlKey: #{!!modifiers[:ctrl]},
          shiftKey: #{!!modifiers[:shift]}
        }));
      })();
    JS
  end

  def mousedown_row(uri, modifiers = {})
    execute_js(<<~JS)
      (function() {
        var li = document.querySelector("#infinite-tree-container li.node[data-uri='#{uri}']");
        if (!li) throw new Error('no row for #{uri}');
        var row = li.querySelector('.node-row');
        row.dispatchEvent(new MouseEvent('mousedown', {
          bubbles: true,
          cancelable: true,
          view: window,
          button: 0,
          metaKey: #{!!modifiers[:meta]},
          ctrlKey: #{!!modifiers[:ctrl]},
          shiftKey: #{!!modifiers[:shift]}
        }));
      })();
    JS
  end

  def selection_uris
    evaluate_js(
      "(document.querySelector('#infinite-tree-container').dataset.selectionUris || '').split(',').filter(Boolean)"
    )
  end

  def expand_node(uri)
    execute_js(<<~JS)
      (function() {
        var li = document.querySelector("#infinite-tree-container li.node[data-uri='#{uri}']");
        if (!li) return;
        var btn = li.querySelector(':scope > .node-row .node-expand');
        if (btn) btn.click();
      })();
    JS
  end

  def install_drag_helpers_and_capture
    execute_js(<<~JS)
      window.__itreeDropIntents = [];
      window.__itreeLastDragOver = null;

      document.addEventListener('infiniteTreeDragDrop:dropIntent', function(event) {
        var detail = event.detail || {};
        window.__itreeDropIntents.push({
          sourceUris: detail.sourceUris || [],
          effectiveSourceUris: detail.effectiveSourceUris || [],
          targetUri: detail.targetUri || null,
          edge: detail.edge || null,
          targetParentUri: detail.targetParentUri || null,
          targetIndex: detail.targetIndex,
          sameParentMove: !!detail.sameParentMove
        });
      });

      function buildEvent(type, clientY) {
        var ev = new Event(type, { bubbles: true, cancelable: true });
        Object.defineProperty(ev, 'clientX', { value: 10 });
        Object.defineProperty(ev, 'clientY', { value: clientY });
        Object.defineProperty(ev, 'dataTransfer', {
          value: {
            effectAllowed: 'move',
            setData: function() {},
            getData: function() { return ''; },
            setDragImage: function() {}
          }
        });
        return ev;
      }

      window.__itreeDispatchDrag = function(type, selector, yRatio) {
        var el = document.querySelector(selector);
        if (!el) throw new Error('No element for selector: ' + selector);
        var rect = el.getBoundingClientRect();
        var y = rect.top + (rect.height * (typeof yRatio === 'number' ? yRatio : 0.5));
        var ev = buildEvent(type, y);
        var dispatched = el.dispatchEvent(ev);
        window.__itreeLastDragOver = {
          selector: selector,
          defaultPrevented: ev.defaultPrevented,
          dispatched: dispatched
        };
      };
    JS
  end

  def dragstart_from(uri)
    execute_js(<<~JS)
      window.__itreeDispatchDrag(
        'dragstart',
        "#infinite-tree-container li.node[data-uri='#{uri}'] > .node-row",
        0.5
      );
    JS
  end

  def dragover_row(uri, y_ratio)
    execute_js(<<~JS)
      window.__itreeDispatchDrag(
        'dragover',
        "#infinite-tree-container li.node[data-uri='#{uri}'] > .node-row",
        #{y_ratio}
      );
    JS
  end

  def drop_row(uri, y_ratio = 0.5)
    execute_js(<<~JS)
      window.__itreeDispatchDrag(
        'drop',
        "#infinite-tree-container li.node[data-uri='#{uri}'] > .node-row",
        #{y_ratio}
      );
    JS
  end

  def last_drop_intent
    evaluate_js('window.__itreeDropIntents[window.__itreeDropIntents.length - 1] || null')
  end

  before do
    visit "#{edit_path}#{root_hash}"
    wait_for_ajax
    enable_reorder_mode
    install_drag_helpers_and_capture
  end

  it 'maps standardHitbox boundaries at 25% and 75%' do
    result = evaluate_js(<<~JS)
      (function() {
        var box = { top: 100, bottom: 200, height: 100 };
        return {
          topBoundary: InfiniteTreeDropHitbox.standardHitbox({ x: 0, y: 125 }, box),
          middle: InfiniteTreeDropHitbox.standardHitbox({ x: 0, y: 150 }, box),
          bottomBoundary: InfiniteTreeDropHitbox.standardHitbox({ x: 0, y: 175 }, box)
        };
      })();
    JS

    expect(result['topBoundary']).to eq('top')
    expect(result['middle']).to eq('into')
    expect(result['bottomBoundary']).to eq('bottom')
  end

  it 'makes the entire row draggable in reorder mode' do
    draggable_state = evaluate_js(<<~JS)
      (function() {
        var row = document.querySelector("#infinite-tree-container li.node[data-uri='#{ao.uri}'] > .node-row");
        var handle = document.querySelector("#infinite-tree-container li.node[data-uri='#{ao.uri}'] .node-column[data-column='drag-handle']");
        return {
          rowDraggable: row && row.getAttribute('draggable'),
          handleDraggable: handle && handle.getAttribute('draggable'),
          rowCursor: row ? window.getComputedStyle(row).cursor : null
        };
      })();
    JS

    expect(draggable_state['rowDraggable']).to eq('true')
    expect(draggable_state['handleDraggable']).to be_nil
    expect(draggable_state['rowCursor']).to eq('grab')
  end

  it 'emits dropIntent for a top-edge single-row drag' do
    dragstart_from(ao.uri)
    dragover_row(ao3.uri, 0.1)
    drop_row(ao3.uri, 0.1)

    intent = last_drop_intent
    expect(intent).not_to be_nil
    expect(intent['edge']).to eq('top')
    expect(intent['sourceUris']).to eq([ao.uri])
    expect(intent['effectiveSourceUris']).to eq([ao.uri])
    expect(intent['targetUri']).to eq(ao3.uri)
  end

  it 'emits dropIntent for an into-edge single-row drag' do
    dragstart_from(ao.uri)
    dragover_row(ao3.uri, 0.5)
    drop_row(ao3.uri, 0.5)

    intent = last_drop_intent
    expect(intent).not_to be_nil
    expect(intent['edge']).to eq('into')
    expect(intent['sourceUris']).to eq([ao.uri])
    expect(intent['effectiveSourceUris']).to eq([ao.uri])
    expect(intent['targetUri']).to eq(ao3.uri)
  end

  it 'emits dropIntent for a bottom-edge single-row drag' do
    dragstart_from(ao.uri)
    dragover_row(ao3.uri, 0.9)
    drop_row(ao3.uri, 0.9)

    intent = last_drop_intent
    expect(intent).not_to be_nil
    expect(intent['edge']).to eq('bottom')
    expect(intent['sourceUris']).to eq([ao.uri])
    expect(intent['effectiveSourceUris']).to eq([ao.uri])
    expect(intent['targetUri']).to eq(ao3.uri)
  end

  it 'plain mousedown resets prior multiselection before dragstart' do
    click_row(ao.uri, meta: true)
    click_row(ao2.uri, meta: true)
    expect(selection_uris).to eq([ao.uri, ao2.uri])

    mousedown_row(ao3.uri)
    expect(selection_uris).to eq([ao3.uri])

    dragstart_from(ao3.uri)
    dragover_row(ao2.uri, 0.1)
    drop_row(ao2.uri, 0.1)

    intent = last_drop_intent
    expect(intent).not_to be_nil
    expect(intent['sourceUris']).to eq([ao3.uri])
    expect(intent['effectiveSourceUris']).to eq([ao3.uri])
    expect(intent['targetUri']).to eq(ao2.uri)
  end

  it 'plain mousedown on an already selected row preserves multiselection for drag' do
    click_row(ao.uri, meta: true)
    click_row(ao2.uri, meta: true)
    expect(selection_uris).to eq([ao.uri, ao2.uri])

    mousedown_row(ao2.uri)
    expect(selection_uris).to eq([ao.uri, ao2.uri])

    dragstart_from(ao2.uri)
    dragover_row(ao3.uri, 0.1)
    drop_row(ao3.uri, 0.1)

    intent = last_drop_intent
    expect(intent).not_to be_nil
    expect(intent['sourceUris']).to eq([ao.uri, ao2.uri])
    expect(intent['effectiveSourceUris']).to eq([ao.uri, ao2.uri])
    expect(intent['targetUri']).to eq(ao3.uri)
  end

  it 'plain click on an already selected row collapses multiselection to that row' do
    click_row(ao.uri, meta: true)
    click_row(ao2.uri, meta: true)
    expect(selection_uris).to eq([ao.uri, ao2.uri])

    click_row(ao2.uri)
    expect(selection_uris).to eq([ao2.uri])
  end

  it 'dedupes ancestor and descendant in effectiveSourceUris' do
    expand_node(ao2.uri)
    wait_for_ajax

    click_row(ao2.uri, meta: true)
    click_row(child_ao.uri, meta: true)

    dragstart_from(ao2.uri)
    dragover_row(ao3.uri, 0.9)
    drop_row(ao3.uri, 0.9)

    intent = last_drop_intent
    expect(intent['sourceUris']).to eq([ao2.uri, child_ao.uri])
    expect(intent['effectiveSourceUris']).to eq([ao2.uri])
    expect(intent['edge']).to eq('bottom')
  end

  it 'blocks drops onto descendants of a dragged source subtree' do
    expand_node(ao2.uri)
    wait_for_ajax

    click_row(ao2.uri, meta: true)
    dragstart_from(ao2.uri)
    dragover_row(child_ao.uri, 0.5)

    blocked = evaluate_js(<<~JS)
      (function() {
        var row = document.querySelector("#infinite-tree-container li.node[data-uri='#{child_ao.uri}'] > .node-row");
        return {
          blockedAttr: row.getAttribute('data-drop-blocked'),
          prevented: window.__itreeLastDragOver.defaultPrevented
        };
      })();
    JS

    expect(blocked['blockedAttr']).to eq('true')
    expect(blocked['prevented']).to eq(false)
  end

  it 'cleans drag state and indicators after dragend' do
    dragstart_from(ao.uri)
    dragover_row(ao3.uri, 0.5)
    execute_js(<<~JS)
      window.__itreeDispatchDrag(
        'dragend',
        "#infinite-tree-container li.node[data-uri='#{ao.uri}'] .node-column[data-column='drag-handle']",
        0.5
      );
    JS

    state = evaluate_js(<<~JS)
      (function() {
        return {
          draggedCount: document.querySelectorAll('#infinite-tree-container li.node.is-being-dragged').length,
          edgeCount: document.querySelectorAll('#infinite-tree-container .node-row[data-drop-edge]').length,
          blockedCount: document.querySelectorAll('#infinite-tree-container .node-row[data-drop-blocked]').length
        };
      })();
    JS

    expect(state['draggedCount']).to eq(0)
    expect(state['edgeCount']).to eq(0)
    expect(state['blockedCount']).to eq(0)
  end
end
