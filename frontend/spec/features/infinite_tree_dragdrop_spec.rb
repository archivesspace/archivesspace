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
      window.__itreeReorderEvents = [];
      window.__itreeAcceptChildrenRequests = [];
      window.__itreeLastDragOver = null;
      window.__itreePageLoadMarker = 'drag-drop-spec-marker';

      var originalFetch = window.fetch.bind(window);
      window.fetch = function(input, init) {
        var url = typeof input === 'string' ? input : input.url;
        if (url && url.indexOf('/accept_children') !== -1) {
          window.__itreeAcceptChildrenRequests.push({
            url: url,
            method: init && init.method,
            body: init && init.body ? init.body.toString() : ''
          });
        }
        return originalFetch(input, init);
      };

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

      [
        'infiniteTreeReorder:moveStart',
        'infiniteTreeReorder:moveSuccess',
        'infiniteTreeReorder:moveError',
        'infiniteTreeReorder:moveSkipped'
      ].forEach(function(name) {
        document.addEventListener(name, function(event) {
          var detail = event.detail || {};
          window.__itreeReorderEvents.push({
            name: event.type,
            reason: detail.reason || null,
            childUris: detail.childUris || [],
            targetParentUri: detail.targetParentUri || null,
            rawIndex: detail.rawIndex,
            adjustedIndex: detail.adjustedIndex,
            error: detail.error || null
          });
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

  def last_accept_children_request
    evaluate_js('window.__itreeAcceptChildrenRequests[window.__itreeAcceptChildrenRequests.length - 1] || null')
  end

  def last_accept_children_params
    evaluate_js(<<~JS)
      (function() {
        var req = window.__itreeAcceptChildrenRequests[window.__itreeAcceptChildrenRequests.length - 1];
        if (!req) return null;
        var params = new URLSearchParams(req.body);
        return {
          children: params.getAll('children[]'),
          index: params.get('index')
        };
      })()
    JS
  end

  def accept_children_request_count
    evaluate_js('window.__itreeAcceptChildrenRequests.length')
  end

  def reorder_events(name)
    evaluate_js("window.__itreeReorderEvents.filter(function(e) { return e.name === '#{name}'; })")
  end

  def wait_for_reorder_idle
    expect(page).to have_no_css('#infinite-tree-container[data-reorder-move-in-flight]')
  end

  def root_child_uris
    evaluate_js(<<~JS)
      Array.prototype.map.call(
        document.querySelectorAll('#infinite-tree-container .root.node > .node-children > li.node'),
        function(node) { return node.getAttribute('data-uri'); }
      )
    JS
  end

  def child_uris_for(parent_uri)
    evaluate_js(<<~JS)
      (function() {
        var parent = document.querySelector("#infinite-tree-container li.node[data-uri='#{parent_uri}']");
        if (!parent) return [];
        return Array.prototype.map.call(
          parent.querySelectorAll(':scope > .node-children > li.node'),
          function(node) { return node.getAttribute('data-uri'); }
        );
      })()
    JS
  end

  def selected_uri
    evaluate_js("document.querySelector('#infinite-tree-container li.node.selected')?.getAttribute('data-uri')")
  end

  def row_in_tree_viewport?(uri)
    evaluate_js(<<~JS)
      (function() {
        var tree = document.querySelector('#infinite-tree-container');
        var node = document.querySelector("#infinite-tree-container li.node[data-uri='#{uri}'] > .node-row");
        if (!tree || !node) return false;
        var treeRect = tree.getBoundingClientRect();
        var nodeRect = node.getBoundingClientRect();
        return nodeRect.top >= treeRect.top && nodeRect.bottom <= treeRect.bottom;
      })()
    JS
  end

  def page_load_marker_present?
    evaluate_js("window.__itreePageLoadMarker === 'drag-drop-spec-marker'")
  end

  def select_tree_record(uri)
    target_hash = "##{tree_hash_for(uri)}"

    execute_js(<<~JS)
      (function() {
        var container = document.querySelector('#infinite-tree-container');
        container.dispatchEvent(new CustomEvent('infiniteTreeRouter:replaceHash', {
          detail: { targetHash: '#{target_hash}' }
        }));
        container.dispatchEvent(new CustomEvent('infiniteTreeRouter:nodeSelect', {
          detail: { targetHash: '#{target_hash}' }
        }));
      })();
    JS
    expect(page).to have_css("li.node[data-uri='#{uri}'].selected")
  end

  def tree_hash_for(uri)
    parts = uri.split('/')
    "tree::#{parts[-2].sub(/s$/, '')}_#{parts[-1]}"
  end

  # The drag preview list stays positioned off-screen unless a dragover event
  # repositions it, so `visible: :all` and `text(:all)` are needed to read its
  # content: Capybara's default visible-text lookup treats off-screen elements
  # as not visible.
  def drag_preview_item_texts
    page.all('.infinite-tree-drag-preview__item', visible: :all).map { |el| el.text(:all) }
  end

  def dispatch_dragend(uri)
    execute_js(<<~JS)
      window.__itreeDispatchDrag(
        'dragend',
        "#infinite-tree-container li.node[data-uri='#{uri}'] > .node-row",
        0.5
      );
    JS
  end

  before do
    visit "#{edit_path}#{root_hash}"
    wait_for_ajax
    enable_reorder_mode
    install_drag_helpers_and_capture
  end

  after do
    wait_for_reorder_idle if page.has_css?('#infinite-tree-container')
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

  it 'persists a top-edge drop, adjusts the same-parent index, and reveals the moved row' do
    before_order = root_child_uris
    source_uri = before_order.first
    target_uri = before_order.last
    expected_order = before_order - [source_uri]
    expected_index = expected_order.index(target_uri)
    expected_order.insert(expected_index, source_uri)

    dragstart_from(source_uri)
    dragover_row(target_uri, 0.1)
    drop_row(target_uri, 0.1)
    wait_for_reorder_idle

    params = last_accept_children_params

    aggregate_failures do
      expect(params['children']).to eq([source_uri])
      expect(params['index']).to eq(expected_index.to_s)
      expect(root_child_uris).to eq(expected_order)
      expect(selected_uri).to eq(resource.uri)
      expect(page.current_url).to include(root_hash)
      expect(row_in_tree_viewport?(source_uri)).to eq(true)
      expect(page_load_marker_present?).to eq(true)
      expect(page).to have_css(
        "li.node[data-uri='#{source_uri}'].reparented, " \
        "li.node[data-uri='#{source_uri}'].reparented-highlight"
      )
    end
  end

  it 'persists a bottom-edge drop after the target row' do
    before_order = root_child_uris
    source_uri = before_order.first
    target_uri = before_order.last
    expected_order = before_order - [source_uri]
    expected_order.insert(expected_order.index(target_uri) + 1, source_uri)

    dragstart_from(source_uri)
    dragover_row(target_uri, 0.9)
    drop_row(target_uri, 0.9)
    wait_for_reorder_idle

    aggregate_failures do
      expect(last_accept_children_params['children']).to eq([source_uri])
      expect(root_child_uris).to eq(expected_order)
      expect(selected_uri).to eq(resource.uri)
      expect(row_in_tree_viewport?(source_uri)).to eq(true)
    end
  end

  it 'persists an into-edge drop as a child of the target row' do
    dragstart_from(ao.uri)
    dragover_row(ao3.uri, 0.5)
    drop_row(ao3.uri, 0.5)
    wait_for_reorder_idle

    aggregate_failures do
      expect(last_accept_children_params['children']).to eq([ao.uri])
      expect(root_child_uris).not_to include(ao.uri)
      expect(child_uris_for(ao3.uri)).to include(ao.uri)
      expect(selected_uri).to eq(resource.uri)
      expect(row_in_tree_viewport?(ao.uri)).to eq(true)
    end
  end

  it 'preserves a selected record that is different from the first moved row' do
    select_tree_record(ao2.uri)

    dragstart_from(ao.uri)
    dragover_row(ao3.uri, 0.5)
    drop_row(ao3.uri, 0.5)
    wait_for_reorder_idle

    aggregate_failures do
      expect(selected_uri).to eq(ao2.uri)
      expect(page.current_url).to include("##{tree_hash_for(ao2.uri)}")
      expect(row_in_tree_viewport?(ao.uri)).to eq(true)
      expect(page_load_marker_present?).to eq(true)
      expect(page).to have_css(
        "li.node[data-uri='#{ao.uri}'].reparented, " \
        "li.node[data-uri='#{ao.uri}'].reparented-highlight"
      )
    end
  end

  it 'skips adjacent same-parent no-op drops without calling accept_children' do
    before_requests = accept_children_request_count
    before_order = root_child_uris
    source_uri = before_order.first
    next_uri = before_order.second

    dragstart_from(source_uri)
    dragover_row(next_uri, 0.1)
    drop_row(next_uri, 0.1)

    aggregate_failures do
      expect(accept_children_request_count).to eq(before_requests)
      expect(reorder_events('infiniteTreeReorder:moveSkipped').last['reason']).to eq('noop')
      expect(root_child_uris).to eq(before_order)
    end
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

    wait_for_reorder_idle

    aggregate_failures 'highlights moved rows that are present after recovery' do
      expect(last_accept_children_params['children']).to eq([ao.uri, ao2.uri])
      [ao.uri, ao2.uri].each do |uri|
        expect(page).to have_css(
          "li.node[data-uri='#{uri}'].reparented, " \
          "li.node[data-uri='#{uri}'].reparented-highlight"
        )
      end
    end
  end

  # Plain clicks no longer collapse the multi-selection: that would block
  # navigation to record links in reorder mode. Selection collapse is now the
  # mousedown handler's job, and it only fires when the pressed row is outside
  # the current multi-selection (so an already-multiselected row can still be
  # dragged as a group).
  it 'mousedown on a row outside the multi-selection collapses to that row before drag' do
    click_row(ao.uri, meta: true)
    click_row(ao2.uri, meta: true)
    expect(selection_uris).to eq([ao.uri, ao2.uri])

    mousedown_row(ao3.uri)
    expect(selection_uris).to eq([ao3.uri])
  end

  it 'mousedown on an already-selected row preserves the multi-selection so a group can be dragged' do
    click_row(ao.uri, meta: true)
    click_row(ao2.uri, meta: true)
    expect(selection_uris).to eq([ao.uri, ao2.uri])

    mousedown_row(ao2.uri)
    expect(selection_uris).to eq([ao.uri, ao2.uri])
  end

  it 'plain record-link click clears multiselection and navigates' do
    click_row(ao.uri, meta: true)
    click_row(ao2.uri, meta: true)
    expect(selection_uris).to eq([ao.uri, ao2.uri])

    within '#infinite-tree-container' do
      click_link ao3.title
    end
    wait_for_ajax

    expect(selection_uris).to eq([])
    expect(page.current_url).to include("##{tree_hash_for(ao3.uri)}")
  end

  it 'clicking a record title after drag-and-drop immediately updates the .selected class' do
    dragstart_from(ao.uri)
    dragover_row(ao3.uri, 0.5)
    drop_row(ao3.uri, 0.5)
    wait_for_reorder_idle

    expect(selected_uri).to eq(resource.uri)
    expect(page).to have_css("li.node[data-uri='#{resource.uri}'].selected")

    within '#infinite-tree-container' do
      click_link ao2.title
    end
    wait_for_ajax

    aggregate_failures do
      expect(selected_uri).to eq(ao2.uri)
      expect(page).to have_css("li.node[data-uri='#{ao2.uri}'].selected")
      expect(page).to have_no_css("li.node[data-uri='#{resource.uri}'].selected")
      expect(page.current_url).to include("##{tree_hash_for(ao2.uri)}")
    end

    within '#infinite-tree-container' do
      click_link ao3.title
    end
    wait_for_ajax

    aggregate_failures do
      expect(selected_uri).to eq(ao3.uri)
      expect(page).to have_css("li.node[data-uri='#{ao3.uri}'].selected")
      expect(page).to have_no_css("li.node[data-uri='#{ao2.uri}'].selected")
      expect(page.current_url).to include("##{tree_hash_for(ao3.uri)}")
    end
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
    wait_for_reorder_idle
    expect(last_accept_children_params['children']).to eq([ao2.uri])
  end

  it 'blocks drops onto descendants of a dragged source subtree' do
    expand_node(ao2.uri)
    wait_for_ajax

    click_row(ao2.uri, meta: true)
    dragstart_from(ao2.uri)
    before_requests = accept_children_request_count
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
    drop_row(child_ao.uri, 0.5)
    expect(accept_children_request_count).to eq(before_requests)
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

  describe 'root node drop target behavior' do
    def dragover_root(y_ratio)
      execute_js(<<~JS)
        window.__itreeDispatchDrag(
          'dragover',
          "#infinite-tree-container li.node.root > .node-row",
          #{y_ratio}
        );
      JS
    end

    def drop_root(y_ratio = 0.5)
      execute_js(<<~JS)
        window.__itreeDispatchDrag(
          'drop',
          "#infinite-tree-container li.node.root > .node-row",
          #{y_ratio}
        );
      JS
    end

    def root_drop_edge
      evaluate_js(<<~JS)
        document.querySelector('#infinite-tree-container li.node.root > .node-row').getAttribute('data-drop-edge')
      JS
    end

    it 'converts top-edge to into-edge when dragging over the root node' do
      dragstart_from(ao.uri)

      dragover_root(0.1)
      expect(root_drop_edge).to eq('into')

      dragover_root(0.5)
      expect(root_drop_edge).to eq('into')

      dragover_root(0.9)
      expect(root_drop_edge).to eq('bottom')
    end

    it 'appends to children when dropping into the root node' do
      before_order = root_child_uris
      source_uri = before_order.first
      expected_order = (before_order - [source_uri]) + [source_uri]

      dragstart_from(source_uri)
      dragover_root(0.5)
      drop_root(0.5)
      wait_for_reorder_idle

      intent = last_drop_intent
      params = last_accept_children_params

      aggregate_failures do
        expect(intent['edge']).to eq('into')
        expect(intent['targetUri']).to eq(resource.uri)
        expect(intent['targetParentUri']).to eq(resource.uri)
        expect(params['children']).to eq([source_uri])
        expect(root_child_uris).to eq(expected_order)
      end
    end

    it 'prepends to children when dropping after the root node' do
      before_order = root_child_uris
      source_uri = before_order.last
      expected_order = [source_uri] + (before_order - [source_uri])

      dragstart_from(source_uri)
      dragover_root(0.9)
      drop_root(0.9)
      wait_for_reorder_idle

      intent = last_drop_intent
      params = last_accept_children_params

      aggregate_failures do
        expect(intent['edge']).to eq('bottom')
        expect(intent['targetUri']).to eq(resource.uri)
        expect(intent['targetParentUri']).to eq(resource.uri)
        expect(intent['targetIndex']).to eq(0)
        expect(params['children']).to eq([source_uri])
        expect(params['index']).to eq('0')
        expect(root_child_uris).to eq(expected_order)
      end
    end
  end

  describe 'custom drag preview system' do
    describe 'empty drag image element' do
      it 'is appended to the DOM on the first drag event' do
        expect(page).to have_no_css('.infinite-tree-empty-drag-image', visible: :all)

        dragstart_from(ao.uri)

        aggregate_failures do
          expect(page).to have_css(
            'body > .infinite-tree-drag-preview + .infinite-tree-empty-drag-image', visible: :all
          )

          positioning = evaluate_js(<<~JS)
            (function() {
              const el = document.body.querySelector('.infinite-tree-empty-drag-image');
              const style = window.getComputedStyle(el);
              return {
                position: style.position,
                top: style.top,
                left: style.left
              };
            })()
          JS

          expect(positioning['position']).to eq('fixed')
          expect(positioning['top']).to eq('-1000px')
          expect(positioning['left']).to eq('-1000px')
        end
      end

      it 'is reused across multiple drag events' do
        dragstart_from(ao.uri)
        expect(page).to have_css(
            'body > .infinite-tree-drag-preview + .infinite-tree-empty-drag-image', visible: :all
          )
        dispatch_dragend(ao.uri)

        dragstart_from(ao2.uri)
        expect(page).to have_css(
            'body > .infinite-tree-empty-drag-image + .infinite-tree-drag-preview', visible: :all
          )
      end
    end

    describe 'drag preview' do # for small selection (< 20 nodes)' do
      it 'is created on dragstart' do
        expect(page).to have_no_css('body > .infinite-tree-drag-preview', visible: :all)

        dragstart_from(ao.uri)

        expect(page).to have_css('body > .infinite-tree-drag-preview', visible: :all)
      end

      context 'when there are 20 or less multi-selected nodes' do
        it 'shows the selected node title in a numbered list for single-node drag' do
          dragstart_from(ao.uri)

          aggregate_failures do
            expect(drag_preview_item_texts).to eq([ao.title])
            expect(page).to have_no_css('.infinite-tree-drag-preview__count', visible: :all)
          end
        end

        it 'shows all selected node titles for multi-node drag' do
          click_row(ao.uri, meta: true)
          click_row(ao2.uri, meta: true)
          click_row(ao3.uri, meta: true)

          dragstart_from(ao.uri)

          aggregate_failures do
            expect(drag_preview_item_texts).to eq([ao.title, ao2.title, ao3.title])
            expect(page).to have_no_css('.infinite-tree-drag-preview__count', visible: :all)
          end
        end

        it 'does not show a remaining count badge' do
          dragstart_from(ao.uri)

          expect(page).to have_no_css('.infinite-tree-drag-preview__count', visible: :all)
        end
      end

      context 'when there are more than 20 multi-selected nodes' do
        it 'truncates the list to 20 nodes and shows a remaining count badge' do
          # WAYPOINT_SIZE is 30 under ASPACE_INTEGRATION (see backend/app/model/large_tree.rb),
          # so 22 root-level siblings all load in a single waypoint with no extra
          # scrolling/pagination needed to bring them into the DOM.
          extra_aos = Array.new(19) do |i|
            create(
              :archival_object,
              resource: { 'ref' => resource.uri },
              title: "Extra AO #{format('%02d', i + 1)} #{now}"
            )
          end
          selected_records = [ao, ao2, ao3] + extra_aos

          # The records above were created after the tree already loaded in the
          # outer `before` block. Visiting the same URL again doesn't reliably
          # force a fresh navigation (same path + hash), so reload directly.
          execute_js('window.location.reload()')
          wait_for_ajax
          enable_reorder_mode
          install_drag_helpers_and_capture

          selected_records.each { |record| click_row(record.uri, meta: true) }
          expect(selection_uris).to eq(selected_records.map(&:uri))

          dragstart_from(selected_records.first.uri)

          aggregate_failures do
            expect(page).to have_css('.infinite-tree-drag-preview__item', count: 20, visible: :all)
            expect(page.find('.infinite-tree-drag-preview__count', visible: :all).text(:all)).to eq('+2')
            expect(drag_preview_item_texts).to eq(selected_records.first(20).map(&:title))
          end
        end
      end
    end

    describe 'drag preview removal' do
      it 'removes the preview immediately on valid drop' do
        dragstart_from(ao.uri)
        expect(page).to have_css('.infinite-tree-drag-preview', visible: :all)

        dragover_row(ao3.uri, 0.5)
        drop_row(ao3.uri, 0.5)

        expect(page).to have_no_css('.infinite-tree-drag-preview', visible: :all)
      end

      it 'removes the preview after snapback animation on invalid drop (blocked target)' do
        expand_node(ao2.uri)
        wait_for_ajax

        dragstart_from(ao2.uri)
        expect(page).to have_css('.infinite-tree-drag-preview', visible: :all)

        dragover_row(child_ao.uri, 0.5)
        drop_row(child_ao.uri, 0.5)

        using_wait_time(2) do
          expect(page).to have_no_css('.infinite-tree-drag-preview', visible: :all)
        end
      end

      it 'removes the preview after dragend (e.g. ESC key cancellation)' do
        dragstart_from(ao.uri)
        expect(page).to have_css('.infinite-tree-drag-preview', visible: :all)

        dispatch_dragend(ao.uri)

        using_wait_time(2) do
          expect(page).to have_no_css('.infinite-tree-drag-preview', visible: :all)
        end
      end
    end
  end
end
