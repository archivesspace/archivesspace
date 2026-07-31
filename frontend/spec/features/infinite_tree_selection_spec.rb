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

  # Scroll the tree container so IntersectionObserver loads a child batch
  # (same pattern as infinite_tree_base_shared_examples).
  def scroll_to_load_child_batch(parent_uri, batch_offset)
    tree_container = find('#infinite-tree-container')
    parent_li = tree_container.find("li.node[data-uri='#{parent_uri}']")
    child_list = parent_li.find(':scope > ol.node-children')
    observer_node = child_list.find("[data-observe-offset='#{batch_offset}']", match: :first)
    tree_container.scroll_to(observer_node, align: :center)
    wait_for_ajax
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
      it 'are shown with only one row selected' do
        click_row(ao.uri, meta: true)

        expect(find_badge(ao.uri)).to eq('1')
      end

      it 'are shown with multiple rows selected' do
        click_row(ao.uri, meta: true)
        click_row(ao3.uri, meta: true)

        expect(find_badge(ao.uri)).to eq('1')
        expect(find_badge(ao3.uri)).to eq('2')
      end

      it 'are renumbered when a middle item is deselected' do
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
      # Record-title clicks in reorder mode serve as navigation AND destination
      # pick. A plain click replaces any existing multi-selection with the
      # single clicked row (.multiselected), then routes through InfiniteTree.
      it 'navigates and replaces multiselect with the clicked destination row' do
        click_row(ao.uri, ctrl: true)
        click_row(ao3.uri, ctrl: true)
        expect(data_selection_uris).to eq("#{ao.uri},#{ao3.uri}")

        within '#infinite-tree-container' do
          click_link ao2.title
        end
        wait_for_ajax

        expect(page.current_url).to include("tree::archival_object_#{ao2.id}")
        expect(data_selection_uris).to eq(ao2.uri)
        expect(page).to have_css("li.node[data-uri='#{ao2.uri}'].multiselected")
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

    describe 'implicit selection badges with single parent selected' do
      before do
        expand_node(ao2.uri)
        wait_for_ajax
        expect(page).to have_css("li.node[data-uri='#{child_ao.uri}']")
      end

      it 'shows checkmark badge on implicit descendants even with single parent selected' do
        click_row(ao2.uri, meta: true)

        # ao2 should be explicitly selected
        expect(page).to have_css("li.node[data-uri='#{ao2.uri}'].multiselected")

        # child_ao should be implicitly selected with checkmark badge
        expect(has_implicitly_selected_class(child_ao.uri)).to be true

        # Check that the checkmark badge is present
        badge = find_badge(child_ao.uri)
        expect(badge).to eq("\u2713") # Unicode checkmark
      end

      it 'shows numeric badge on single explicit selection' do
        click_row(ao2.uri, meta: true)

        expect(find_badge(ao2.uri)).to eq('1')
      end
    end

    describe 'lazy-loaded implicit selection', :ancestry_multilevel_tree do
      let(:tree_batch_size) { Rails.configuration.infinite_tree_batch_size }

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

      let!(:bd_ao) do
        create(:archival_object, resource: { 'ref' => resource.uri }, parent: { 'ref' => b_ao.uri }, title: "BD #{now}")
      end

      let!(:bd_batch_children) do
        (tree_batch_size + 1).times.map do |i|
          create(
            :archival_object,
            resource: { 'ref' => resource.uri },
            parent: { 'ref' => bd_ao.uri },
            title: "BD Child #{i + 1} #{now}"
          )
        end
      end

      let(:bd_first_batch_child) { bd_batch_children.first }
      let(:bd_second_batch_child) { bd_batch_children.last }

      let!(:c_ao) do
        create(:archival_object, resource: { 'ref' => resource.uri }, title: "C #{now}")
      end

      before do
        visit "#{edit_path}#{root_hash}"
        wait_for_ajax
        install_selection_event_capture
        enable_reorder_mode

        # Expand B to see its direct children (BA, BB, BC) but not grandchildren yet
        expect(page).to have_css("li.node[data-uri='#{b_ao.uri}']", wait: 10)
        expand_node(b_ao.uri)
        wait_for_ajax
        expect(page).to have_css("li.node[data-uri='#{bb_ao.uri}']", wait: 10)
      end

      it 'applies implicit selection to descendants when parent is expanded after selection' do
        # Select B (its direct children BA, BB, BC are visible but BB is collapsed)
        click_row(b_ao.uri, meta: true)
        expect(data_selection_uris).to eq(b_ao.uri)

        # Verify direct children are implicitly selected
        expect(has_implicitly_selected_class(ba_ao.uri)).to be true
        expect(has_implicitly_selected_class(bb_ao.uri)).to be true
        expect(has_implicitly_selected_class(bc_ao.uri)).to be true

        # Now expand BB to lazy-load grandchildren BBA and BBB
        expand_node(bb_ao.uri)
        wait_for_ajax
        expect(page).to have_css("li.node[data-uri='#{bba_ao.uri}']", wait: 10)

        # Grandchildren should now also have implicit selection styling
        expect(has_implicitly_selected_class(bba_ao.uri)).to be true
        expect(has_implicitly_selected_class(bbb_ao.uri)).to be true

        # And they should have checkmark badges
        expect(find_badge(bba_ao.uri)).to eq("\u2713")
        expect(find_badge(bbb_ao.uri)).to eq("\u2713")
      end

      it 'applies implicit selection to children whose batches load on scroll after expansion' do
        click_row(b_ao.uri, meta: true)
        expect(data_selection_uris).to eq(b_ao.uri)

        # Initial expansion of BD loads batch 0 only
        expand_node(bd_ao.uri)
        wait_for_ajax
        expect(page).to have_css("li.node[data-uri='#{bd_first_batch_child.uri}']", wait: 10)
        expect(page).to have_no_css("li.node[data-uri='#{bd_second_batch_child.uri}']")

        expect(has_implicitly_selected_class(bd_first_batch_child.uri)).to be true
        expect(find_badge(bd_first_batch_child.uri)).to eq("\u2713")

        scroll_to_load_child_batch(bd_ao.uri, 1)

        expect(page).to have_css("li.node[data-uri='#{bd_second_batch_child.uri}']", wait: 10)
        expect(has_implicitly_selected_class(bd_second_batch_child.uri)).to be true
        expect(find_badge(bd_second_batch_child.uri)).to eq("\u2713")
        expect(has_implicitly_selected_class(bd_first_batch_child.uri)).to be true
      end

      it 'applies implicit selection to nested descendants expanded multiple levels deep' do
        # Select B while it's expanded (children visible)
        click_row(b_ao.uri, meta: true)

        # BB is implicitly selected
        expect(has_implicitly_selected_class(bb_ao.uri)).to be true

        # Expand BB (which is implicitly selected, not explicitly)
        expand_node(bb_ao.uri)
        wait_for_ajax
        expect(page).to have_css("li.node[data-uri='#{bba_ao.uri}']", wait: 10)

        # BBA and BBB (grandchildren of B, children of BB) should be implicitly selected
        expect(has_implicitly_selected_class(bba_ao.uri)).to be true
        expect(has_implicitly_selected_class(bbb_ao.uri)).to be true

        # Selection should still only contain B
        expect(data_selection_uris).to eq(b_ao.uri)
      end

      it 'does not apply implicit selection when reorder mode is off' do
        # Exit reorder mode
        find('.js-itree-toolbar-reorder-toggle').click
        expect(page).to have_no_css('#infinite-tree-container.reorder-mode')

        # Expand BB (no selection active, reorder mode off)
        expand_node(bb_ao.uri)
        wait_for_ajax
        expect(page).to have_css("li.node[data-uri='#{bba_ao.uri}']", wait: 10)

        # No implicit selection classes should be present
        expect(has_implicitly_selected_class(bba_ao.uri)).to be false
        expect(has_implicitly_selected_class(bbb_ao.uri)).to be false
      end

      it 'does not apply implicit selection to unrelated branches when sibling is selected' do
        # Select A (a sibling of B with no descendants loaded)
        click_row(a_ao.uri, meta: true)
        expect(data_selection_uris).to eq(a_ao.uri)

        # Expand BB under B (which is not selected)
        expand_node(bb_ao.uri)
        wait_for_ajax
        expect(page).to have_css("li.node[data-uri='#{bba_ao.uri}']", wait: 10)

        # BBA and BBB should NOT be implicitly selected (they're not under A)
        expect(has_implicitly_selected_class(bba_ao.uri)).to be false
        expect(has_implicitly_selected_class(bbb_ao.uri)).to be false
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
