# frozen_string_literal: true

# Cut/Paste button enable/disable rules live in infinite_tree_toolbar_spec.rb
# under reorder mode > Cut and paste controls. This file covers paste execution,
# accept_children API verification, and effective move-set deduping.

require 'spec_helper'
require 'rails_helper'

describe 'Infinite Tree Cut/Paste', js: true do
  context 'Resources' do
    include_context 'infinite tree reorder hierarchy setup', InfiniteTreeHierarchyConfigs::REORDER.fetch(:resources)

    it_behaves_like 'cutting and pasting in reorder mode'

    it 'does not paste when target is part of the cut set' do
      install_accept_children_capture
      enable_reorder_mode

      select_tree_row(child_record)
      click_infinite_tree_toolbar_cut

      find('.js-itree-toolbar-paste').click
      wait_for_reorder_idle

      aggregate_failures do
        expect(accept_children_requests).to eq([])
        expect(page).to have_css("li.node.cut[data-uri='#{child_record.uri}']")
      end
    end

    describe 'paste target eligibility inside a cut subtree' do
      before do
        install_accept_children_capture
        enable_reorder_mode
        wait_for_reorder_mode_ready
        expand_tree_node(sibling2.uri)
        expect(page).to have_css("li.node[data-uri='#{nested_under_sibling2.uri}']")
      end

      it 'disables Paste when the current record is a descendant of a cut record' do
        select_tree_row(sibling2)
        click_infinite_tree_toolbar_cut
        expect(page).to have_css("li.node.cut[data-uri='#{sibling2.uri}']")

        select_tree_row(nested_under_sibling2)

        expect_infinite_tree_toolbar_paste_enabled(false)
      end

      it 'does not call accept_children when Paste is clicked on a descendant of a cut record' do
        select_tree_row(sibling2)
        click_infinite_tree_toolbar_cut
        select_tree_row(nested_under_sibling2)

        find('.js-itree-toolbar-paste').click
        wait_for_reorder_idle

        aggregate_failures do
          expect(accept_children_requests).to eq([])
          expect(page).to have_css("li.node.cut[data-uri='#{sibling2.uri}']")
        end
      end
    end

    # Cut state is cleared by reorderModeChanged and EVENT_MOVE_SUCCESS only. A tree
    # rebuild that comes from anywhere else (loadNodeWithAncestors via back/forward
    # or a hand-edited hash) drops the `.cut` classes with the old DOM but leaves
    # cutUris and the toolbar's cutActive in place.
    describe 'cut state when the tree is rebuilt by navigation' do
      it 'keeps the Paste control in sync with the cut markers in the tree' do
        install_accept_children_capture
        enable_reorder_mode
        wait_for_reorder_mode_ready

        select_tree_row(child_record)
        click_infinite_tree_toolbar_cut
        expect(page).to have_css("li.node.cut[data-uri='#{child_record.uri}']")

        select_tree_row(sibling3)
        expect_infinite_tree_toolbar_paste_enabled(true)

        # nested_under_sibling2 has never been expanded into view, so this hash goes
        # through loadNodeWithAncestors -> #renderAncestorsAndShow(replace: true),
        # which calls container.replaceChildren().
        navigate_tree_hash(tree_hash_for(nested_under_sibling2.uri))
        expect(page).to have_css("li.node.current[data-uri='#{nested_under_sibling2.uri}']")

        cut_uris = page
          .all('#infinite-tree-container li.node.cut', visible: :all)
          .map { |node| node['data-uri'] }
        paste_enabled = page.has_no_css?('.js-itree-toolbar-paste.disabled[disabled]')

        aggregate_failures do
          # Either the rebuild cleared the cut, or it re-applied the markers.
          # Paste must never be offered with nothing marked as cut.
          expect(paste_enabled).to eq(cut_uris.any?)
          expect(cut_uris - [child_record.uri]).to be_empty
        end
      end
    end
  end

  context 'Digital Objects' do
    include_context 'infinite tree reorder hierarchy setup', InfiniteTreeHierarchyConfigs::REORDER.fetch(:digital_objects)

    it_behaves_like 'cutting and pasting in reorder mode'
  end

  context 'Classifications' do
    include_context 'infinite tree reorder hierarchy setup', InfiniteTreeHierarchyConfigs::REORDER.fetch(:classifications)

    it_behaves_like 'cutting and pasting in reorder mode'
  end
end
