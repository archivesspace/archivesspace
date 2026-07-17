# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Infinite Tree Move', js: true do
  include_context 'infinite tree integration setup'

  let(:edit_path) { "/resources/#{resource.id}/edit" }
  let(:root_hash) { "#tree::resource_#{resource.id}" }
  let(:nested_hash) { "#tree::archival_object_#{ao_nested.id}" }

  let!(:ao2) do
    create(
      :archival_object,
      resource: { 'ref' => resource.uri },
      title: "Second AO #{now}"
    )
  end
  let!(:ao3) do
    create(
      :archival_object,
      resource: { 'ref' => resource.uri },
      title: "Third AO #{now}"
    )
  end
  let!(:ao_nested) do
    create(
      :archival_object,
      resource: { 'ref' => resource.uri },
      parent: { 'ref' => ao.uri },
      title: "Nested AO #{now}"
    )
  end

  def root_child_uris
    page.evaluate_script(<<~JS)
      Array.prototype.map.call(
        document.querySelectorAll('#infinite-tree-container .root.node > .node-children > li.node'),
        function(node) { return node.getAttribute('data-uri'); }
      )
    JS
  end

  def child_uris_for(parent_uri)
    page.evaluate_script(<<~JS)
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
    page.evaluate_script("document.querySelector('#infinite-tree-container li.node.selected')?.getAttribute('data-uri')")
  end

  def wait_for_reorder_idle
    expect(page).to have_no_css('#infinite-tree-container[data-reorder-move-in-flight]')
  end

  def install_reorder_capture
    page.execute_script(<<~JS)
      window.__itreeReorderEvents = [];
      window.__itreeAcceptChildrenRequests = [];
      var originalFetch = window.fetch.bind(window);
      window.fetch = function(input, init) {
        var url = typeof input === 'string' ? input : input.url;
        if (url && url.indexOf('/accept_children') !== -1) {
          window.__itreeAcceptChildrenRequests.push({
            url: url,
            body: init && init.body ? init.body.toString() : ''
          });
        }
        return originalFetch(input, init);
      };

      [
        'infiniteTreeMove:moveIntent',
        'infiniteTreeReorder:moveStart',
        'infiniteTreeReorder:moveSuccess',
        'infiniteTreeReorder:moveSkipped'
      ].forEach(function(name) {
        document.addEventListener(name, function(event) {
          var detail = event.detail || {};
          window.__itreeReorderEvents.push({
            name: name,
            detail: {
              reason: detail.reason || null,
              childUris: detail.childUris || detail.effectiveSourceUris || []
            }
          });
        });
      });
    JS
  end

  def reorder_events(name)
    page.evaluate_script(
      "window.__itreeReorderEvents.filter(function(e) { return e.name === '#{name}'; })"
    )
  end

  def accept_children_requests
    page.evaluate_script('window.__itreeAcceptChildrenRequests')
  end

  def accept_children_request_count
    page.evaluate_script('window.__itreeAcceptChildrenRequests.length')
  end

  def click_row(uri, modifiers = {})
    page.execute_script(<<~JS)
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

  def move_menu_has_action?(action, enabled: true)
    state_selector = enabled ? ':not([disabled])' : '[disabled]'
    page.evaluate_script(<<~JS)
      !!document.querySelector(
        ".js-itree-toolbar-move-menu button[data-move-action='#{action}']:not([data-target-node-id])#{state_selector}"
      )
    JS
  end

  def dispatch_move_option(action, target_node_id = nil)
    page.execute_script(<<~JS)
      (function() {
        var container = document.querySelector('#infinite-tree-container');
        if (!container) throw new Error('missing tree container');
        container.dispatchEvent(new CustomEvent('infiniteTreeToolbar:moveOptionSelected', {
          bubbles: true,
          detail: {
            action: '#{action}',
            targetNodeId: #{target_node_id ? "'#{target_node_id}'" : 'null'}
          }
        }));
      })();
    JS
  end

  def enable_reorder_mode
    find('.js-itree-toolbar-reorder-toggle').click
  end

  def select_row(uri)
    page.execute_script(<<~JS)
      (function() {
        var li = document.querySelector("#infinite-tree-container li.node[data-uri='#{uri}']");
        if (!li) throw new Error('no row for #{uri}');
        var link = li.querySelector('.record-title');
        if (!link) throw new Error('no title link for #{uri}');
        link.click();
      })();
    JS
    wait_for_ajax
  end

  def click_move_action(action, target_node_id = nil)
    within '.js-itree-toolbar-move-menu' do
      if target_node_id
        find(
          'button[data-move-action="down-into"]:not([data-target-node-id])'
        ).hover
        find(
          "button[data-move-action='down-into'][data-target-node-id='#{target_node_id}']",
          visible: true
        ).click
      else
        find(
          "button[data-move-action='#{action}']:not([data-target-node-id])",
          match: :first
        ).click
      end
    end
    wait_for_ajax
  end

  def open_move_menu_for(uri)
    select_row(uri)
    find('.js-itree-toolbar-move-toggle').click
  end

  before do
    visit "#{edit_path}#{root_hash}"
    wait_for_ajax
  end

  it 'hides Move outside reorder mode' do
    select_row(ao.uri)

    within '#infinite-tree-toolbar' do
      expect(page).to have_no_css('.js-itree-toolbar-move-toggle', visible: true)
    end
  end

  it 'shows Move disabled when root is selected in reorder mode' do
    enable_reorder_mode

    within '#infinite-tree-toolbar' do
      expect(page).to have_css('.js-itree-toolbar-move-toggle', visible: true)
      expect(page).to have_css('.js-itree-toolbar-move-toggle.disabled')
    end
  end

  it 'moves a node up among siblings' do
    enable_reorder_mode
    before_order = root_child_uris

    open_move_menu_for(ao2.uri)
    click_move_action('up')
    wait_for_reorder_idle

    expected_order = before_order.dup
    ao2_index = expected_order.index(ao2.uri)
    expected_order.delete(ao2.uri)
    expected_order.insert(ao2_index - 1, ao2.uri)

    aggregate_failures do
      expect(root_child_uris).to eq(expected_order)
      expect(selected_uri).to eq(ao2.uri)
    end
  end

  it 'refreshes Move menu options after a move' do
    enable_reorder_mode

    open_move_menu_for(ao2.uri)
    within '.js-itree-toolbar-move-menu' do
      expect(page).to have_css('button[data-move-action="up"]:not([disabled])')
    end

    click_move_action('up')
    wait_for_reorder_idle

    find('.js-itree-toolbar-move-toggle').click
    within '.js-itree-toolbar-move-menu' do
      expect(page).to have_css('button[data-move-action="down"]:not([disabled])')
      expect(page).to have_css('button[data-move-action="up"][disabled]')
    end
  end

  it 'moves a node down among siblings' do
    enable_reorder_mode
    before_order = root_child_uris

    open_move_menu_for(ao.uri)
    click_move_action('down')
    wait_for_reorder_idle

    expected_order = before_order.dup
    ao_index = expected_order.index(ao.uri)
    expected_order.delete(ao.uri)
    expected_order.insert(ao_index + 1, ao.uri)

    aggregate_failures do
      expect(root_child_uris).to eq(expected_order)
      expect(selected_uri).to eq(ao.uri)
    end
  end

  it 'moves a nested node up a level' do
    visit "#{edit_path}#{nested_hash}"
    wait_for_ajax
    enable_reorder_mode
    before_order = root_child_uris

    open_move_menu_for(ao_nested.uri)
    click_move_action('up-level')
    wait_for_reorder_idle

    aggregate_failures do
      expect(child_uris_for(ao.uri)).not_to include(ao_nested.uri)
      expect(root_child_uris).to eq(before_order + [ao_nested.uri])
      expect(selected_uri).to eq(ao_nested.uri)
    end
  end

  it 'moves a node down into a sibling as last child' do
    enable_reorder_mode

    open_move_menu_for(ao.uri)
    click_move_action('down-into', "archival_object_#{ao2.id}")
    wait_for_reorder_idle

    aggregate_failures do
      expect(root_child_uris).not_to include(ao.uri)
      expect(child_uris_for(ao2.uri).last).to eq(ao.uri)
      expect(selected_uri).to eq(ao.uri)
    end
  end

  it 'moves only the selected row when multiselection is present' do
    install_reorder_capture
    enable_reorder_mode
    before_order = root_child_uris

    within '#infinite-tree-container' do
      click_link ao2.title
    end
    wait_for_ajax

    click_row(ao.uri, meta: true)
    click_row(ao3.uri, meta: true)

    aggregate_failures do
      expect(page).to have_css("li.node[data-uri='#{ao2.uri}'].selected")
      expect(page).to have_css("li.node[data-uri='#{ao.uri}'].multiselected")
      expect(page).to have_css("li.node[data-uri='#{ao3.uri}'].multiselected")
    end

    find('.js-itree-toolbar-move-toggle').click
    click_move_action('up')
    wait_for_reorder_idle

    expected_order = before_order.dup
    ao2_index = expected_order.index(ao2.uri)
    expected_order.delete(ao2.uri)
    expected_order.insert(ao2_index - 1, ao2.uri)

    request = accept_children_requests.last
    expect(request).not_to be_nil

    aggregate_failures do
      expect(root_child_uris).to eq(expected_order)
      expect(selected_uri).to eq(ao2.uri)
      expect(request['body']).to include("children%5B%5D=#{ERB::Util.url_encode(ao2.uri)}")
      expect(request['body']).not_to include("children%5B%5D=#{ERB::Util.url_encode(ao.uri)}")
      expect(request['body']).not_to include("children%5B%5D=#{ERB::Util.url_encode(ao3.uri)}")
    end
  end

  it 'does not call accept_children when reorder mode is off' do
    install_reorder_capture

    within '#infinite-tree-container' do
      click_link ao2.title
    end
    wait_for_ajax

    dispatch_move_option('up')
    wait_for_ajax

    aggregate_failures do
      expect(accept_children_requests).to eq([])
      expect(reorder_events('infiniteTreeReorder:moveSkipped')).to eq([])
    end
  end

  it 'disables move up for the first sibling and move down for the last sibling' do
    enable_reorder_mode
    first_uri = root_child_uris.first
    last_uri = root_child_uris.last

    open_move_menu_for(first_uri)
    aggregate_failures do
      expect(move_menu_has_action?('up', enabled: false)).to eq(true)
      expect(move_menu_has_action?('down')).to eq(true)
    end

    open_move_menu_for(last_uri)
    aggregate_failures do
      expect(move_menu_has_action?('up')).to eq(true)
      expect(move_menu_has_action?('down', enabled: false)).to eq(true)
    end
  end

  it 'skips no-op reposition without calling accept_children' do
    install_reorder_capture
    enable_reorder_mode

    page.execute_script(<<~JS)
      (function() {
        var container = document.querySelector('#infinite-tree-container');
        var node = document.querySelector("li.node[data-uri='#{ao2.uri}']");
        if (!container || !node) throw new Error('required nodes missing');

        var position = parseInt(node.getAttribute('data-tree-position') || '', 10);
        if (!Number.isFinite(position)) {
          var siblings = Array.prototype.filter.call(
            node.parentElement.children,
            function(child) { return child.matches('li.node'); }
          );
          position = siblings.indexOf(node);
        }

        var parentLi = node.parentElement.closest('li.node');
        var targetParentUri = parentLi
          ? (parentLi.getAttribute('data-uri') || container.closest('#infinite-tree-component').getAttribute('data-root-uri'))
          : container.closest('#infinite-tree-component').getAttribute('data-root-uri');

        container.dispatchEvent(new CustomEvent('infiniteTreeMove:moveIntent', {
          bubbles: true,
          detail: {
            sourceNodes: [node],
            sourceUris: ['#{ao2.uri}'],
            effectiveSourceNodes: [node],
            effectiveSourceUris: ['#{ao2.uri}'],
            targetParentUri: targetParentUri,
            targetIndex: position,
            sameParentMove: true
          }
        }));
      })();
    JS

    aggregate_failures do
      expect(accept_children_requests).to eq([])
      expect(reorder_events('infiniteTreeReorder:moveSkipped').last['detail']['reason']).to eq('noop')
    end
  end

  it 'ignores a second move while a reorder move is in flight' do
    install_reorder_capture
    enable_reorder_mode
    before_order = root_child_uris

    within '#infinite-tree-container' do
      click_link ao2.title
    end
    wait_for_ajax

    page.execute_script(<<~JS)
      (function() {
        var container = document.querySelector('#infinite-tree-container');
        if (!container) throw new Error('missing tree container');
        var detail = { action: 'up', targetNodeId: null };
        container.dispatchEvent(new CustomEvent('infiniteTreeToolbar:moveOptionSelected', {
          bubbles: true,
          detail: detail
        }));
        container.dispatchEvent(new CustomEvent('infiniteTreeToolbar:moveOptionSelected', {
          bubbles: true,
          detail: detail
        }));
      })();
    JS
    wait_for_reorder_idle

    after_order = root_child_uris
    move_starts = reorder_events('infiniteTreeReorder:moveStart')

    aggregate_failures do
      expect(accept_children_request_count).to eq(1)
      expect(after_order).not_to eq(before_order)
      expect(move_starts.length).to eq(1)
      expect(move_starts.first['detail']['childUris'] || []).to eq([ao2.uri])
    end
  end
end
