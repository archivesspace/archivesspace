# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Infinite Tree Selection (reorder-mode multi-select)', js: true do
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

  def install_selection_event_capture
    execute_js(<<~JS)
      window.__itreeSelectionEvents = [];
      const names = [
        'infiniteTreeSelection:changed',
        'infiniteTreeSelection:cleared'
      ];
      names.forEach(function(name) {
        document.addEventListener(name, function(event) {
          const detail = {};
          if (event.detail && event.detail.selectedNodes) {
            detail.selectedUris = event.detail.selectedNodes.map(function(n) {
              return n.getAttribute('data-uri');
            });
          }
          if (event.detail && event.detail.anchorNode) {
            detail.anchorUri = event.detail.anchorNode.getAttribute('data-uri');
          }
          window.__itreeSelectionEvents.push({ name: event.type, detail: detail });
        });
      });
    JS
  end

  def selection_events
    evaluate_js('window.__itreeSelectionEvents')
  end

  def last_changed_event
    evaluate_js(<<~JS)
      (function() {
        var evs = window.__itreeSelectionEvents.filter(function(e) {
          return e.name === 'infiniteTreeSelection:changed';
        });
        return evs[evs.length - 1] || null;
      })();
    JS
  end

  def cleared_event_count
    evaluate_js(<<~JS)
      window.__itreeSelectionEvents.filter(function(e) {
        return e.name === 'infiniteTreeSelection:cleared';
      }).length
    JS
  end

  def data_selection_uris
    evaluate_js(
      "document.querySelector('#infinite-tree-container').dataset.selectionUris || null"
    )
  end

  # Dispatch a synthetic click on an li.node's .node-row with the given modifiers.
  # Capture-phase listener in InfiniteTreeSelection will intercept before
  # InfiniteTree's bubble-phase title click handler routes.
  def click_row(uri, modifiers = {})
    execute_js(<<~JS)
      (function() {
        var container = document.querySelector('#infinite-tree-container');
        var li = container.querySelector('li.node[data-uri="#{uri}"]');
        if (!li) throw new Error('No li with data-uri=#{uri}');
        var row = li.querySelector('.node-row');
        if (!row) throw new Error('No .node-row for #{uri}');
        var ev = new MouseEvent('click', {
          bubbles: true,
          cancelable: true,
          view: window,
          metaKey: #{!!modifiers[:meta]},
          ctrlKey: #{!!modifiers[:ctrl]},
          shiftKey: #{!!modifiers[:shift]}
        });
        row.dispatchEvent(ev);
      })();
    JS
  end

  def expand_node(uri)
    execute_js(<<~JS)
      (function() {
        var container = document.querySelector('#infinite-tree-container');
        var li = container.querySelector('li.node[data-uri="#{uri}"]');
        if (!li) return;
        var btn = li.querySelector(':scope > .node-row .node-expand');
        if (btn) btn.click();
      })();
    JS
  end

  def collapse_node(uri)
    expand_node(uri)
  end

  def enable_reorder_mode
    find('.js-itree-toolbar-reorder-toggle').click
  end

  def find_badge(uri)
    evaluate_js(<<~JS)
      (function() {
        var li = document.querySelector('li.node[data-uri="#{uri}"]');
        if (!li) return null;
        var badge = li.querySelector('.selection-order-badge');
        return badge ? badge.textContent : null;
      })();
    JS
  end

  def has_locked_class(uri)
    evaluate_js(<<~JS)
      (function() {
        var li = document.querySelector('li.node[data-uri="#{uri}"]');
        return li ? li.classList.contains('selection-locked') : false;
      })();
    JS
  end

  def has_implicitly_selected_class(uri)
    evaluate_js(<<~JS)
      (function() {
        var li = document.querySelector('li.node[data-uri="#{uri}"]');
        return li ? li.classList.contains('implicitly-multiselected') : false;
      })();
    JS
  end

  before do |example|
    # Nested `let!` hooks run after this hook, so the default visit would load the
    # tree before ancestry fixture rows exist. Examples tagged :ancestry_multilevel_tree
    # perform their own visit after those lets run (see nested before block).
    next if example.metadata[:ancestry_multilevel_tree]

    visit "#{edit_path}#{root_hash}"
    wait_for_ajax
    install_selection_event_capture
  end

  context 'when reorder mode is off' do
    it 'plain clicks retain router navigation behavior' do
      within '#infinite-tree-container' do
        click_link ao.title
      end
      wait_for_ajax

      expect(page.current_url).to include("tree::archival_object_#{ao.id}")
      expect(data_selection_uris).to be_nil
    end

    it 'ignores modifier-keyed clicks (no selection mutation)' do
      click_row(ao.uri, meta: true)

      expect(selection_events).to eq([])
      expect(data_selection_uris).to be_nil
      expect(page).to have_no_css('#infinite-tree-container .node.multiselected')
    end
  end

  context 'when reorder mode is on' do
    before do |example|
      next if example.metadata[:ancestry_multilevel_tree]

      enable_reorder_mode
    end

    it 'toggles .reorder-mode on the tree container' do
      expect(page).to have_css('#infinite-tree-container.reorder-mode')
    end

    describe 'Cmd/Ctrl + click toggles membership' do
      it 'adds rows with meta key, toggles off on second meta click' do
        click_row(ao.uri, meta: true)

        expect(page).to have_css("li.node[data-uri='#{ao.uri}'].multiselected")
        expect(data_selection_uris).to eq(ao.uri)

        evt = last_changed_event
        expect(evt['detail']['selectedUris']).to eq([ao.uri])
        expect(evt['detail']['anchorUri']).to eq(ao.uri)

        click_row(ao.uri, meta: true)

        expect(page).to have_no_css('.node.multiselected')
        expect(data_selection_uris).to be_nil
        expect(cleared_event_count).to be >= 1
      end

      it 'adds rows with ctrl key and reflects DOM order in data-selection-uris' do
        click_row(ao.uri, ctrl: true)
        click_row(ao3.uri, ctrl: true)

        expect(data_selection_uris).to eq("#{ao.uri},#{ao3.uri}")

        evt = last_changed_event
        expect(evt['detail']['selectedUris']).to eq([ao.uri, ao3.uri])
        expect(evt['detail']['anchorUri']).to eq(ao3.uri)
      end

      it 'preserves click order, not DOM order' do
        click_row(ao3.uri, meta: true)
        click_row(ao.uri, meta: true)

        uris = data_selection_uris.split(',')
        expect(uris).to eq([ao3.uri, ao.uri])

        evt = last_changed_event
        expect(evt['detail']['selectedUris']).to eq([ao3.uri, ao.uri])
        expect(evt['detail']['anchorUri']).to eq(ao.uri)
      end
    end

    describe 'Shift + click extends selection across all depths' do
      before do
        expand_node(ao2.uri)
        wait_for_ajax
        # Guard the precondition: the level-2 child_ao is now in the DOM
        # between the two level-1 siblings ao2 and ao3, so cross-depth range
        # behavior is actually being exercised.
        expect(page).to have_css("li.node[data-uri='#{child_ao.uri}']")
      end

      it 'extends across same-level siblings and includes deeper rows in the range' do
        click_row(ao.uri, meta: true)
        click_row(ao3.uri, shift: true)

        uris = data_selection_uris.split(',')
        expect(uris).to eq([ao.uri, ao2.uri, ao3.uri])
        expect(has_implicitly_selected_class(child_ao.uri)).to be true
      end

      it 'extends from a level-1 anchor to a level-2 endpoint inside an expanded parent' do
        click_row(ao.uri, meta: true)
        click_row(child_ao.uri, shift: true)

        uris = data_selection_uris.split(',')
        expect(uris).to eq([ao.uri, child_ao.uri])
        expect(has_locked_class(ao2.uri)).to be true

        evt = last_changed_event
        expect(evt['detail']['selectedUris']).to eq([ao.uri, child_ao.uri])
        expect(evt['detail']['anchorUri']).to eq(child_ao.uri)
      end

      it 'extends from a level-2 anchor to a level-1 endpoint, walking backward across depths' do
        click_row(child_ao.uri, meta: true)
        click_row(ao.uri, shift: true)

        uris = data_selection_uris.split(',')
        # Click order: child_ao first, then only ao from range
        # ao2 is SKIPPED because it's an ancestor of child_ao (locked)
        expect(uris).to eq([child_ao.uri, ao.uri])
      end
    end

    describe 'selection order badges' do
      it 'hides badge when only one row selected' do
        click_row(ao.uri, meta: true)

        badge = find_badge(ao.uri)
        expect(badge).to eq('')
      end

      it 'shows badges when multiple rows selected' do
        click_row(ao.uri, meta: true)
        click_row(ao3.uri, meta: true)

        expect(find_badge(ao.uri)).to eq('1')
        expect(find_badge(ao3.uri)).to eq('2')
      end

      it 'renumbers badges when middle item deselected' do
        click_row(ao.uri, meta: true)
        click_row(ao2.uri, meta: true)
        click_row(ao3.uri, meta: true)

        expect(find_badge(ao.uri)).to eq('1')
        expect(find_badge(ao2.uri)).to eq('2')
        expect(find_badge(ao3.uri)).to eq('3')

        # Deselect middle item
        click_row(ao2.uri, meta: true)

        expect(data_selection_uris).to eq("#{ao.uri},#{ao3.uri}")
        expect(find_badge(ao.uri)).to eq('1')
        expect(find_badge(ao3.uri)).to eq('2')
      end
    end

    describe 'ancestry-based locking (multi-level)', :ancestry_multilevel_tree do
      let!(:a_ao) do
        create(:archival_object, resource: { 'ref' => resource.uri }, title: "A #{now}")
      end

      let!(:b_ao) do
        create(:archival_object, resource: { 'ref' => resource.uri }, title: "B #{now}")
      end

      let!(:ba_ao) do
        create(:archival_object, resource: { 'ref' => resource.uri }, parent: { 'ref' => b_ao.uri }, title: "BA #{now}")
      end

      let!(:bb_ao) do
        create(:archival_object, resource: { 'ref' => resource.uri }, parent: { 'ref' => b_ao.uri }, title: "BB #{now}")
      end

      let!(:bba_ao) do
        create(:archival_object, resource: { 'ref' => resource.uri }, parent: { 'ref' => bb_ao.uri }, title: "BBA #{now}")
      end

      let!(:bbb_ao) do
        create(:archival_object, resource: { 'ref' => resource.uri }, parent: { 'ref' => bb_ao.uri }, title: "BBB #{now}")
      end

      let!(:bc_ao) do
        create(:archival_object, resource: { 'ref' => resource.uri }, parent: { 'ref' => b_ao.uri }, title: "BC #{now}")
      end

      let!(:c_ao) do
        create(:archival_object, resource: { 'ref' => resource.uri }, title: "C #{now}")
      end

      let!(:d_ao) do
        create(:archival_object, resource: { 'ref' => resource.uri }, title: "D #{now}")
      end

      before do
        visit "#{edit_path}#{root_hash}"
        wait_for_ajax
        install_selection_event_capture
        enable_reorder_mode

        expect(page).to have_css("li.node[data-uri='#{b_ao.uri}']", wait: 10)
        expand_node(b_ao.uri)
        wait_for_ajax
        expect(page).to have_css("li.node[data-uri='#{bb_ao.uri}']", wait: 10)
        expand_node(bb_ao.uri)
        wait_for_ajax
        expect(page).to have_css("li.node[data-uri='#{bbb_ao.uri}']", wait: 10)
      end

      it 'locks all ancestors when grandchild is selected' do
        click_row(bbb_ao.uri, meta: true)

        # BB (parent) and B (grandparent) should both be locked
        expect(has_locked_class(bb_ao.uri)).to be true
        expect(has_locked_class(b_ao.uri)).to be true

        # Siblings are not locked
        expect(has_locked_class(bba_ao.uri)).to be false

        # Attempt to select BB should be ignored
        click_row(bb_ao.uri, meta: true)
        expect(data_selection_uris).to eq(bbb_ao.uri)

        # Attempt to select B should be ignored
        click_row(b_ao.uri, meta: true)
        expect(data_selection_uris).to eq(bbb_ao.uri)
      end

      it 'implicitly selects all descendants when grandparent is selected' do
        click_row(b_ao.uri, meta: true)

        # Direct children should be implicitly selected
        expect(has_implicitly_selected_class(ba_ao.uri)).to be true
        expect(has_implicitly_selected_class(bb_ao.uri)).to be true
        expect(has_implicitly_selected_class(bc_ao.uri)).to be true

        # Grandchildren should also be implicitly selected
        expect(has_implicitly_selected_class(bba_ao.uri)).to be true
        expect(has_implicitly_selected_class(bbb_ao.uri)).to be true

        # Attempt to select grandchild should be ignored
        click_row(bbb_ao.uri, meta: true)
        expect(data_selection_uris).to eq(b_ao.uri)
      end

      it 'prevents selecting grandchild when grandparent already selected' do
        click_row(b_ao.uri, meta: true)
        click_row(bbb_ao.uri, meta: true)

        # Only B should be selected (BBB is implicitly included)
        expect(data_selection_uris).to eq(b_ao.uri)
        expect(has_implicitly_selected_class(bbb_ao.uri)).to be true
      end

      it 'shows implicitly-multiselected on descendants and selection-locked on ancestors' do
        click_row(bb_ao.uri, meta: true)

        expect(has_implicitly_selected_class(bba_ao.uri)).to be true
        expect(has_implicitly_selected_class(bbb_ao.uri)).to be true

        expect(has_locked_class(b_ao.uri)).to be true

        expect(has_locked_class(ba_ao.uri)).to be false
        expect(has_implicitly_selected_class(ba_ao.uri)).to be false
      end

      it 'prevents selecting grandparent when grandchild already selected' do
        click_row(bbb_ao.uri, meta: true)
        click_row(b_ao.uri, meta: true)

        # Only BBB should be selected (B was locked)
        expect(data_selection_uris).to eq(bbb_ao.uri)
      end

      it 'creates visual holes in range selection across multiple levels' do
        # Select BBB (grandchild), which locks BB (parent) and B (grandparent)
        click_row(bbb_ao.uri, meta: true)

        expect(has_locked_class(bb_ao.uri)).to be true
        expect(has_locked_class(b_ao.uri)).to be true

        # Shift backward to BA (stays under B; flat range BA..BBA skips locked BB only).
        # Avoid shifting to A: many unrelated top-level rows sit between A and B in DOM order.
        click_row(ba_ao.uri, shift: true)

        expect(data_selection_uris).to eq("#{bbb_ao.uri},#{bba_ao.uri},#{ba_ao.uri}")

        expect(has_locked_class(bb_ao.uri)).to be true
        expect(has_locked_class(b_ao.uri)).to be true
      end

      it 'unlocks grandparent only when all descendants deselected' do
        click_row(bba_ao.uri, meta: true)
        click_row(bbb_ao.uri, meta: true)

        # B and BB should both be locked
        expect(has_locked_class(bb_ao.uri)).to be true
        expect(has_locked_class(b_ao.uri)).to be true

        # Deselect BBA - BB and B still locked (BBB still selected)
        click_row(bba_ao.uri, meta: true)
        expect(data_selection_uris).to eq(bbb_ao.uri)
        expect(has_locked_class(bb_ao.uri)).to be true
        expect(has_locked_class(b_ao.uri)).to be true

        # Deselect BBB - now BB and B are unlocked
        click_row(bbb_ao.uri, meta: true)
        expect(data_selection_uris).to be_nil
        expect(has_locked_class(bb_ao.uri)).to be false
        expect(has_locked_class(b_ao.uri)).to be false
      end

      it 'allows selecting from multiple unrelated branches' do
        click_row(a_ao.uri, meta: true)
        click_row(bbb_ao.uri, meta: true)

        # Both should be selected (no shared ancestry)
        expect(data_selection_uris).to eq("#{a_ao.uri},#{bbb_ao.uri}")
      end
    end

    describe 'plain click on record links' do
      # Record-title clicks in reorder mode are for page-level navigation and
      # destination targeting, not multiselect mutations. The click clears
      # transient multiselect state and then routes through InfiniteTree.
      it 'navigates and clears multiselect state' do
        click_row(ao.uri, ctrl: true)
        click_row(ao3.uri, ctrl: true)
        expect(data_selection_uris).to eq("#{ao.uri},#{ao3.uri}")

        within '#infinite-tree-container' do
          click_link ao2.title
        end
        wait_for_ajax

        expect(page.current_url).to include("tree::archival_object_#{ao2.id}")
        expect(data_selection_uris).to be_nil
      end
    end

    describe 'outside click' do
      it 'clears selection when mousedown lands outside tree/toolbar/resizer' do
        click_row(ao.uri, meta: true)
        expect(data_selection_uris).to eq(ao.uri)

        execute_js(<<~JS)
          document.body.dispatchEvent(
            new MouseEvent('mousedown', { bubbles: true, cancelable: true })
          );
        JS

        expect(data_selection_uris).to be_nil
        expect(cleared_event_count).to be >= 1
      end

      it 'preserves selection when mousedown is inside the toolbar' do
        click_row(ao.uri, meta: true)
        expect(data_selection_uris).to eq(ao.uri)

        execute_js(<<~JS)
          document.querySelector('#infinite-tree-toolbar')
            .dispatchEvent(new MouseEvent('mousedown', { bubbles: true, cancelable: true }));
        JS

        expect(data_selection_uris).to eq(ao.uri)
      end
    end

    describe 'expand and collapse do not mutate the selection' do
      before do
        expand_node(ao2.uri)
        wait_for_ajax
      end

      it 'preserves selected descendants in the explicit selection when their ancestor collapses' do
        click_row(child_ao.uri, meta: true)
        expect(data_selection_uris).to eq(child_ao.uri)

        collapse_node(ao2.uri)
        wait_for_ajax

        expect(data_selection_uris).to eq(child_ao.uri)
      end

      it 'preserves a multi-row selection across collapse + re-expand' do
        click_row(ao.uri, meta: true)
        click_row(child_ao.uri, meta: true)
        expect(data_selection_uris).to eq("#{ao.uri},#{child_ao.uri}")

        collapse_node(ao2.uri)
        wait_for_ajax

        expect(data_selection_uris).to eq("#{ao.uri},#{child_ao.uri}")

        expand_node(ao2.uri)
        wait_for_ajax

        expect(data_selection_uris).to eq("#{ao.uri},#{child_ao.uri}")
        expect(page).to have_css(
          "li.node[data-uri='#{child_ao.uri}'].multiselected"
        )
      end
    end

    describe 'toggling reorder mode off' do
      it 'clears selection and removes .reorder-mode from the container' do
        click_row(ao.uri, meta: true)
        expect(data_selection_uris).to eq(ao.uri)

        find('.js-itree-toolbar-reorder-toggle').click

        expect(page).to have_no_css('#infinite-tree-container.reorder-mode')
        expect(data_selection_uris).to be_nil
        expect(cleared_event_count).to be >= 1
      end
    end

  end

  context 'drag-handle column visibility and widths' do
    def column_rect_width(uri, column_name)
      evaluate_js(<<~JS)
        (function() {
          var li = document.querySelector(
            '#infinite-tree-container li.node[data-uri="#{uri}"]'
          );
          if (!li) return null;
          var col = li.querySelector(
            ':scope > .node-row > .node-body > [data-column="#{column_name}"]'
          );
          if (!col) return null;
          return col.getBoundingClientRect().width;
        })();
      JS
    end

    def handle_display(uri)
      evaluate_js(<<~JS)
        (function() {
          var li = document.querySelector(
            '#infinite-tree-container li.node[data-uri="#{uri}"]'
          );
          var col = li.querySelector(
            ':scope > .node-row > .node-body > [data-column="drag-handle"]'
          );
          return window.getComputedStyle(col).display;
        })();
      JS
    end

    it 'hides the drag-handle column by default and reveals it in reorder mode' do
      expect(handle_display(ao.uri)).to eq('none')

      enable_reorder_mode

      expect(page).to have_css('#infinite-tree-container.reorder-mode')
      expect(handle_display(ao.uri)).not_to eq('none')
    end

    it 'leaves non-title column pixel widths unchanged across reorder toggle' do
      level_before = column_rect_width(ao.uri, 'level')
      type_before = column_rect_width(ao.uri, 'type')
      container_before = column_rect_width(ao.uri, 'container')

      enable_reorder_mode
      expect(page).to have_css('#infinite-tree-container.reorder-mode')

      level_after = column_rect_width(ao.uri, 'level')
      type_after = column_rect_width(ao.uri, 'type')
      container_after = column_rect_width(ao.uri, 'container')

      expect(level_after).to be_within(0.5).of(level_before)
      expect(type_after).to be_within(0.5).of(type_before)
      expect(container_after).to be_within(0.5).of(container_before)
    end

    it 'shrinks the title column by the handle column width when reorder turns on' do
      title_before = column_rect_width(ao.uri, 'title')

      enable_reorder_mode
      expect(page).to have_css('#infinite-tree-container.reorder-mode')

      title_after = column_rect_width(ao.uri, 'title')
      handle_width = column_rect_width(ao.uri, 'drag-handle')

      expect(handle_width).to be > 0
      expect(title_before - title_after).to be_within(0.5).of(handle_width)
    end
  end
end
