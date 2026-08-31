# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

# Covers InfiniteTreeMultiSelection selection state, badges, ancestry locking,
# shift-range collapsing, outside-click clearing, and collapse/expand persistence.
# Plain mousedown → drag behavior is tested in infinite_tree_dragdrop_spec.rb.

describe 'Infinite Tree Multi-Selection (reorder-mode multi-select)', js: true do
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

  # Scroll the tree container so IntersectionObserver loads a child batch
  # (same pattern as infinite_tree_base_shared_examples).
  def scroll_to_load_child_batch(parent_uri, batch_offset)
    parent_li = tree_node(parent_uri)
    child_list = parent_li.find(':scope > ol.node-children')
    observer_node = child_list.find("[data-observe-offset='#{batch_offset}']", match: :first)
    tree_container.scroll_to(observer_node, align: :center)
    wait_for_ajax
  end

  def find_badge(uri)
    # Wait briefly for badge to appear and populate
    sleep 0.05
    badge = tree_node(uri).find(':scope > .node-row .selection-order-badge', visible: :all, wait: 1)
    badge.text(:all).strip
  rescue Capybara::ElementNotFound
    ''
  end

  def node_locked?(uri)
    # Brief wait for class to be applied
    sleep 0.05
    tree_node(uri)[:class].include?('selection-locked')
  end

  def node_implicitly_selected?(uri)
    # Brief wait for class to be applied
    sleep 0.05
    tree_node(uri)[:class].include?('implicitly-multiselected')
  end

  def data_selection_uris
    uris = selection_uris
    return nil if uris.empty?
    uris.join(',')
  end

  before do |example|
    # Nested `let!` hooks run after this hook, so the default visit would load the
    # tree before ancestry fixture rows exist. Examples tagged :ancestry_multilevel_tree
    # perform their own visit after those lets run (see nested before block).
    next if example.metadata[:ancestry_multilevel_tree]

    visit "#{edit_path}#{root_hash}"
    wait_for_ajax
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
      meta_click_row(ao.uri)

      expect(data_selection_uris).to be_nil
      expect(page).to have_no_css('#infinite-tree-container .node.multiselected')
    end
  end

  context 'when reorder mode is on' do
    before do |example|
      next if example.metadata[:ancestry_multilevel_tree]

      enable_reorder_mode
      wait_for_reorder_mode_ready
    end

    it 'toggles .reorder-mode on the tree container' do
      expect(page).to have_css('#infinite-tree-container.reorder-mode')
    end

    describe 'Cmd/Ctrl + click toggles membership' do
      it 'adds rows with meta key, toggles off on second meta click' do
        meta_click_row(ao.uri)

        expect(page).to have_css("li.node[data-uri='#{ao.uri}'].multiselected")
        expect(data_selection_uris).to eq(ao.uri)

        meta_click_row(ao.uri)

        expect(page).to have_no_css('.node.multiselected')
        expect(data_selection_uris).to be_nil
      end

      it 'adds rows with ctrl key and reflects DOM order in data-selection-uris' do
        ctrl_click_row(ao.uri)
        ctrl_click_row(ao3.uri)

        expect(page).to have_css(".node.multiselected", count: 2)
        expect(data_selection_uris).to eq("#{ao.uri},#{ao3.uri}")
      end

      it 'preserves click order, not DOM order' do
        meta_click_row(ao3.uri)
        meta_click_row(ao.uri)

        uris = data_selection_uris.split(',')
        expect(uris).to eq([ao3.uri, ao.uri])
      end
    end

    describe 'Shift + click extends selection across all depths' do
      before do
        expand_tree_node(ao2.uri)
        wait_for_ajax
        # Guard the precondition: the level-2 child_ao is now in the DOM
        # between the two level-1 siblings ao2 and ao3, so cross-depth range
        # behavior is actually being exercised.
        expect(page).to have_css("li.node[data-uri='#{child_ao.uri}']")
      end

      it 'extends across same-level siblings and includes deeper rows in the range' do
        meta_click_row(ao.uri)
        shift_click_row(ao3.uri)

        uris = data_selection_uris.split(',')
        expect(uris).to eq([ao.uri, ao2.uri, ao3.uri])
        expect(node_implicitly_selected?(child_ao.uri)).to be true
      end

      it 'extends from a level-1 anchor to a level-2 endpoint inside an expanded parent' do
        meta_click_row(ao.uri)
        shift_click_row(child_ao.uri)

        uris = data_selection_uris.split(',')
        expect(uris).to eq([ao.uri, child_ao.uri])
        expect(node_locked?(ao2.uri)).to be true
      end

      it 'extends from a level-2 anchor to a level-1 endpoint, walking backward across depths' do
        meta_click_row(child_ao.uri)
        shift_click_row(ao.uri)

        uris = data_selection_uris.split(',')
        # Click order: child_ao first, then only ao from range
        # ao2 is SKIPPED because it's an ancestor of child_ao (locked)
        expect(uris).to eq([child_ao.uri, ao.uri])
      end
    end

    describe 'range anchor' do
      it 'does not change when a middle item is deselected' do
        meta_click_row(ao.uri)
        meta_click_row(ao2.uri)
        meta_click_row(ao3.uri)
        expect(data_selection_uris).to eq("#{ao.uri},#{ao2.uri},#{ao3.uri}")

        meta_click_row(ao2.uri)
        expect(data_selection_uris).to eq("#{ao.uri},#{ao3.uri}")

        shift_click_row(ao2.uri)
        # Anchor is still ao3 (last remaining); range walks backward and adds ao2.
        expect(data_selection_uris).to eq("#{ao.uri},#{ao3.uri},#{ao2.uri}")
      end

      it 'moves to the new last item when the previous anchor is deselected' do
        meta_click_row(ao.uri)
        meta_click_row(ao2.uri)
        expect(data_selection_uris).to eq("#{ao.uri},#{ao2.uri}")

        meta_click_row(ao2.uri)
        expect(data_selection_uris).to eq(ao.uri)

        shift_click_row(ao3.uri)
        expect(data_selection_uris).to eq("#{ao.uri},#{ao2.uri},#{ao3.uri}")
      end
    end

    describe 'plain mousedown on row body' do
      it 'collapses multiselection to the mousedown row when that row is not selected' do
        meta_click_row(ao.uri)
        meta_click_row(ao2.uri)
        expect(data_selection_uris).to eq("#{ao.uri},#{ao2.uri}")

        click_tree_row(ao3.uri)
        expect(data_selection_uris).to eq(ao3.uri)
      end
    end

    describe 'selection order badges' do
      it 'are shown with only one row selected' do
        meta_click_row(ao.uri)

        expect(find_badge(ao.uri)).to eq('1')
      end

      it 'are shown with multiple rows selected' do
        meta_click_row(ao.uri)
        meta_click_row(ao3.uri)

        expect(find_badge(ao.uri)).to eq('1')
        expect(find_badge(ao3.uri)).to eq('2')
      end

      it 'are renumbered when a middle item is deselected' do
        meta_click_row(ao.uri)
        meta_click_row(ao2.uri)
        meta_click_row(ao3.uri)

        expect(find_badge(ao.uri)).to eq('1')
        expect(find_badge(ao2.uri)).to eq('2')
        expect(find_badge(ao3.uri)).to eq('3')

        # Deselect middle item
        meta_click_row(ao2.uri)

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
        enable_reorder_mode
        wait_for_reorder_mode_ready

        expect(page).to have_css("li.node[data-uri='#{b_ao.uri}']", wait: 10)
        expand_tree_node(b_ao.uri)
        wait_for_ajax
        expect(page).to have_css("li.node[data-uri='#{bb_ao.uri}']", wait: 10)
        expand_tree_node(bb_ao.uri)
        wait_for_ajax
        expect(page).to have_css("li.node[data-uri='#{bbb_ao.uri}']", wait: 10)
      end

      it 'locks all ancestors when grandchild is selected' do
        meta_click_row(bbb_ao.uri)

        # BB (parent) and B (grandparent) should both be locked
        expect(node_locked?(bb_ao.uri)).to be true
        expect(node_locked?(b_ao.uri)).to be true

        # Siblings are not locked
        expect(node_locked?(bba_ao.uri)).to be false

        # Attempt to select BB should be ignored
        meta_click_row(bb_ao.uri)
        expect(data_selection_uris).to eq(bbb_ao.uri)

        # Attempt to select B should be ignored
        meta_click_row(b_ao.uri)
        expect(data_selection_uris).to eq(bbb_ao.uri)
      end

      it 'implicitly selects all descendants when grandparent is selected' do
        meta_click_row(b_ao.uri)

        # Direct children should be implicitly selected
        expect(node_implicitly_selected?(ba_ao.uri)).to be true
        expect(node_implicitly_selected?(bb_ao.uri)).to be true
        expect(node_implicitly_selected?(bc_ao.uri)).to be true

        # Grandchildren should also be implicitly selected
        expect(node_implicitly_selected?(bba_ao.uri)).to be true
        expect(node_implicitly_selected?(bbb_ao.uri)).to be true

        # Attempt to select grandchild should be ignored
        meta_click_row(bbb_ao.uri)
        expect(data_selection_uris).to eq(b_ao.uri)
      end

      it 'prevents selecting grandchild when grandparent already selected' do
        meta_click_row(b_ao.uri)
        meta_click_row(bbb_ao.uri)

        # Only B should be selected (BBB is implicitly included)
        expect(data_selection_uris).to eq(b_ao.uri)
        expect(node_implicitly_selected?(bbb_ao.uri)).to be true
      end

      it 'shows implicitly-multiselected on descendants and selection-locked on ancestors' do
        meta_click_row(bb_ao.uri)

        expect(node_implicitly_selected?(bba_ao.uri)).to be true
        expect(node_implicitly_selected?(bbb_ao.uri)).to be true

        expect(node_locked?(b_ao.uri)).to be true

        expect(node_locked?(ba_ao.uri)).to be false
        expect(node_implicitly_selected?(ba_ao.uri)).to be false
      end

      it 'prevents selecting grandparent when grandchild already selected' do
        meta_click_row(bbb_ao.uri)
        meta_click_row(b_ao.uri)

        # Only BBB should be selected (B was locked)
        expect(data_selection_uris).to eq(bbb_ao.uri)
      end

      it 'creates visual holes in range selection across multiple levels' do
        # Select BBB (grandchild), which locks BB (parent) and B (grandparent)
        meta_click_row(bbb_ao.uri)

        expect(node_locked?(bb_ao.uri)).to be true
        expect(node_locked?(b_ao.uri)).to be true

        # Shift backward to BA (stays under B; flat range BA..BBA skips locked BB only).
        # Avoid shifting to A: many unrelated top-level rows sit between A and B in DOM order.
        shift_click_row(ba_ao.uri)

        expect(data_selection_uris).to eq("#{bbb_ao.uri},#{bba_ao.uri},#{ba_ao.uri}")

        expect(node_locked?(bb_ao.uri)).to be true
        expect(node_locked?(b_ao.uri)).to be true
      end

      it 'unlocks grandparent only when all descendants deselected' do
        meta_click_row(bba_ao.uri)
        meta_click_row(bbb_ao.uri)

        # B and BB should both be locked
        expect(node_locked?(bb_ao.uri)).to be true
        expect(node_locked?(b_ao.uri)).to be true

        # Deselect BBA - BB and B still locked (BBB still selected)
        meta_click_row(bba_ao.uri)
        expect(data_selection_uris).to eq(bbb_ao.uri)
        expect(node_locked?(bb_ao.uri)).to be true
        expect(node_locked?(b_ao.uri)).to be true

        # Deselect BBB - now BB and B are unlocked
        meta_click_row(bbb_ao.uri)
        expect(data_selection_uris).to be_nil
        expect(node_locked?(bb_ao.uri)).to be false
        expect(node_locked?(b_ao.uri)).to be false
      end

      it 'allows selecting from multiple unrelated branches' do
        meta_click_row(a_ao.uri)
        meta_click_row(bbb_ao.uri)

        # Both should be selected (no shared ancestry)
        expect(data_selection_uris).to eq("#{a_ao.uri},#{bbb_ao.uri}")
      end
    end

    describe 'plain click on record links' do
      # Record-title clicks in reorder mode serve as navigation AND destination
      # pick. A plain click replaces any existing multi-selection with the
      # single clicked row (.multiselected), then routes through InfiniteTree.
      it 'navigates and replaces multiselect with the clicked destination row' do
        ctrl_click_row(ao.uri)
        ctrl_click_row(ao3.uri)
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
        meta_click_row(ao.uri)
        expect(data_selection_uris).to eq(ao.uri)

        page.execute_script(<<~JS)
          document.body.dispatchEvent(
            new MouseEvent('mousedown', { bubbles: true, cancelable: true })
          );
        JS

        sleep 0.1
        expect(data_selection_uris).to be_nil
      end

      it 'preserves selection when mousedown is inside the toolbar' do
        meta_click_row(ao.uri)
        expect(data_selection_uris).to eq(ao.uri)

        page.execute_script(<<~JS)
          document.querySelector('#infinite-tree-toolbar')
            .dispatchEvent(new MouseEvent('mousedown', { bubbles: true, cancelable: true }));
        JS

        sleep 0.1

        expect(data_selection_uris).to eq(ao.uri)
      end
    end

    describe 'expand and collapse do not mutate the selection' do
      before do
        expand_tree_node(ao2.uri)
        wait_for_ajax
      end

      it 'preserves selected descendants in the explicit selection when their ancestor collapses' do
        meta_click_row(child_ao.uri)
        expect(data_selection_uris).to eq(child_ao.uri)

        collapse_tree_node(ao2.uri)
        wait_for_ajax

        expect(data_selection_uris).to eq(child_ao.uri)
      end

      it 'preserves a multi-row selection across collapse + re-expand' do
        meta_click_row(ao.uri)
        meta_click_row(child_ao.uri)
        expect(data_selection_uris).to eq("#{ao.uri},#{child_ao.uri}")

        collapse_tree_node(ao2.uri)
        wait_for_ajax

        expect(data_selection_uris).to eq("#{ao.uri},#{child_ao.uri}")

        expand_tree_node(ao2.uri)
        wait_for_ajax

        expect(data_selection_uris).to eq("#{ao.uri},#{child_ao.uri}")
        expect(page).to have_css(
          "li.node[data-uri='#{child_ao.uri}'].multiselected"
        )
      end
    end

    describe 'toggling reorder mode off' do
      it 'clears selection and removes .reorder-mode from the container' do
        meta_click_row(ao.uri)
        expect(data_selection_uris).to eq(ao.uri)

        find('.js-itree-toolbar-reorder-toggle').click

        expect(page).to have_no_css('#infinite-tree-container.reorder-mode')
        expect(data_selection_uris).to be_nil
      end
    end

    describe 'implicit selection badges with single parent selected' do
      before do
        expand_tree_node(ao2.uri)
        wait_for_ajax
        expect(page).to have_css("li.node[data-uri='#{child_ao.uri}']")
      end

      it 'shows checkmark badge on implicit descendants even with single parent selected' do
        meta_click_row(ao2.uri)

        badge = find_badge(child_ao.uri)
        aggregate_failures do
          expect(page).to have_css("li.node[data-uri='#{ao2.uri}'].multiselected")
          expect(node_implicitly_selected?(child_ao.uri)).to be true
          expect(badge).to eq("\u2713") # Unicode checkmark
        end
      end

      it 'shows numeric badge on single explicit selection' do
        meta_click_row(ao2.uri)

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
        enable_reorder_mode
        wait_for_reorder_mode_ready

        # Expand B to see its direct children (BA, BB, BC) but not grandchildren yet
        expect(page).to have_css("li.node[data-uri='#{b_ao.uri}']", wait: 10)
        expand_tree_node(b_ao.uri)
        wait_for_ajax
        expect(page).to have_css("li.node[data-uri='#{bb_ao.uri}']", wait: 10)
      end

      it 'applies implicit selection to descendants when parent is expanded after selection' do
        # Select B (its direct children BA, BB, BC are visible but BB is collapsed)
        meta_click_row(b_ao.uri)
        expect(data_selection_uris).to eq(b_ao.uri)

        # Verify direct children are implicitly selected
        expect(node_implicitly_selected?(ba_ao.uri)).to be true
        expect(node_implicitly_selected?(bb_ao.uri)).to be true
        expect(node_implicitly_selected?(bc_ao.uri)).to be true

        # Now expand BB to lazy-load grandchildren BBA and BBB
        expand_tree_node(bb_ao.uri)
        wait_for_ajax
        expect(page).to have_css("li.node[data-uri='#{bba_ao.uri}']", wait: 10)

        # Grandchildren should now also have implicit selection styling
        expect(node_implicitly_selected?(bba_ao.uri)).to be true
        expect(node_implicitly_selected?(bbb_ao.uri)).to be true

        # And they should have checkmark badges
        expect(find_badge(bba_ao.uri)).to eq("\u2713")
        expect(find_badge(bbb_ao.uri)).to eq("\u2713")
      end

      it 'applies implicit selection to children whose batches load on scroll after expansion' do
        meta_click_row(b_ao.uri)
        expect(data_selection_uris).to eq(b_ao.uri)

        # Initial expansion of BD loads batch 0 only
        expand_tree_node(bd_ao.uri)
        wait_for_ajax
        expect(page).to have_css("li.node[data-uri='#{bd_first_batch_child.uri}']", wait: 10)
        expect(page).to have_no_css("li.node[data-uri='#{bd_second_batch_child.uri}']")

        expect(node_implicitly_selected?(bd_first_batch_child.uri)).to be true
        expect(find_badge(bd_first_batch_child.uri)).to eq("\u2713")

        scroll_to_load_child_batch(bd_ao.uri, 1)

        expect(page).to have_css("li.node[data-uri='#{bd_second_batch_child.uri}']", wait: 10)
        expect(node_implicitly_selected?(bd_second_batch_child.uri)).to be true
        expect(find_badge(bd_second_batch_child.uri)).to eq("\u2713")
        expect(node_implicitly_selected?(bd_first_batch_child.uri)).to be true
      end

      it 'applies implicit selection to nested descendants expanded multiple levels deep' do
        # Select B while it's expanded (children visible)
        meta_click_row(b_ao.uri)

        # BB is implicitly selected
        expect(node_implicitly_selected?(bb_ao.uri)).to be true

        # Expand BB (which is implicitly selected, not explicitly)
        expand_tree_node(bb_ao.uri)
        wait_for_ajax
        expect(page).to have_css("li.node[data-uri='#{bba_ao.uri}']", wait: 10)

        # BBA and BBB (grandchildren of B, children of BB) should be implicitly selected
        expect(node_implicitly_selected?(bba_ao.uri)).to be true
        expect(node_implicitly_selected?(bbb_ao.uri)).to be true

        # Selection should still only contain B
        expect(data_selection_uris).to eq(b_ao.uri)
      end

      it 'does not apply implicit selection when reorder mode is off' do
        # Exit reorder mode
        find('.js-itree-toolbar-reorder-toggle').click
        expect(page).to have_no_css('#infinite-tree-container.reorder-mode')

        # Expand BB (no selection active, reorder mode off)
        expand_tree_node(bb_ao.uri)
        wait_for_ajax
        expect(page).to have_css("li.node[data-uri='#{bba_ao.uri}']", wait: 10)

        # No implicit selection classes should be present
        expect(node_implicitly_selected?(bba_ao.uri)).to be false
        expect(node_implicitly_selected?(bbb_ao.uri)).to be false
      end

      it 'does not apply implicit selection to unrelated branches when sibling is selected' do
        # Select A (a sibling of B with no descendants loaded)
        meta_click_row(a_ao.uri)
        expect(data_selection_uris).to eq(a_ao.uri)

        # Expand BB under B (which is not selected)
        expand_tree_node(bb_ao.uri)
        wait_for_ajax
        expect(page).to have_css("li.node[data-uri='#{bba_ao.uri}']", wait: 10)

        # BBA and BBB should NOT be implicitly selected (they're not under A)
        expect(node_implicitly_selected?(bba_ao.uri)).to be false
        expect(node_implicitly_selected?(bbb_ao.uri)).to be false
      end
    end

  end

  context 'drag-handle column visibility' do
    def handle_display(uri)
      page.evaluate_script(<<~JS)
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
      wait_for_reorder_mode_ready

      expect(page).to have_css('#infinite-tree-container.reorder-mode')
      expect(handle_display(ao.uri)).not_to eq('none')
    end
  end
end
