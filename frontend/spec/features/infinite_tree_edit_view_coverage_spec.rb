# frozen_string_literal: true

# Resource edit view equivalents for examples that skip_if_infinite_tree_toolbar_active
# now skips unconditionally, because resources/edit.html.erb always renders the
# InfiniteTree toolbar:
#
#   trees_spec.rb:80                    (skips the whole 'Tree UI' describe)
#   reorder_mode_spec.rb:304, :310      ('supporting reorder mode' + dirty toggle)
#   tree_toolbar_action_matrix_spec.rb:38, :55
#
# Already covered elsewhere, deliberately not repeated here:
#   - toolbar action matrix (root and child rows) -> infinite_tree_toolbar_spec.rb
#     'provides the default root controls' / '...plus Add Sibling and Add Duplicate'
#   - Add Sibling / Add Child / Add Duplicate flows -> infinite_tree_toolbar_spec.rb
#   - Auto-Expand All and Collapse Tree -> infinite_tree_toolbar_spec.rb
#   - reorder toggle while dirty -> infinite_tree_toolbar_spec.rb
#   - cut/paste and move enable rules -> infinite_tree_toolbar_spec.rb
#
# Obsolete on this branch, intentionally dropped:
#   - 'persists selected drop behavior across reloads': the drop-behavior radio
#     group is gone, replaced by the per-row drop-intent hitbox
#     (InfiniteTreeDropHitbox, covered in infinite_tree_dragdrop_spec.rb).
#   - 'presents toolbar buttons in correct order': asserted the legacy
#     #tree-toolbar button order, which this toolbar deliberately changes.

require 'spec_helper'
require 'rails_helper'

describe 'Infinite Tree Resource edit view coverage', js: true do
  include_context 'infinite tree integration setup'

  let(:show_path) { "/resources/#{resource.id}" }
  let(:edit_path) { "#{show_path}/edit" }

  let!(:ao2) do
    create(
      :archival_object,
      resource: { 'ref' => resource.uri },
      title: "Second AO #{now}"
    )
  end

  let!(:suppressed_ao) do
    create(
      :archival_object,
      resource: { 'ref' => resource.uri },
      title: "Suppressed AO #{now}"
    ).tap { |record| record.set_suppressed(true) }
  end

  before do
    visit edit_path
    wait_for_ajax
  end

  # Ported from trees_spec.rb 'shows the suppressed tag only for suppressed records'.
  # The read-only view is covered by 'showing a badge on suppressed records' in
  # infinite_tree_shared_examples.rb; the edit view had no equivalent.
  describe 'suppressed records' do
    it 'badges only the suppressed record' do
      badges = page.all('#infinite-tree-container .record-title .badge', text: 'Suppressed')

      aggregate_failures do
        expect(badges.length).to eq(1)
        expect(
          page
        ).to have_css(
          "li.node[data-uri='#{suppressed_ao.uri}'] .record-title .badge",
          text: 'Suppressed'
        )
      end
    end
  end

  # Ported from trees_spec.rb 'preserves the tree hash when finishing editing'.
  # infinite_tree_toolbar_action_contracts_spec.rb only asserts the event payload
  # for the root node; this covers the navigation end to end for a child node.
  describe 'Close Record' do
    it 'lands on the read-only view with the current child record hash' do
      select_tree_row(ao)
      expect(page.current_url).to include("#tree::archival_object_#{ao.id}")

      find('.js-itree-toolbar-finish-editing').click
      wait_for_ajax

      aggregate_failures do
        expect(page.current_url).not_to include('/edit')
        expect(page.current_url).to include(show_path)
        expect(page.current_url).to include("#tree::archival_object_#{ao.id}")
      end
    end
  end

  # Ported from trees_spec.rb 'does not affect the duplicated archival object if
  # the original is deleted'. The form-field copying is covered by
  # infinite_tree_toolbar_spec.rb 'Add Duplicate'; what is missing is that the
  # duplicate outlives its original.
  describe 'a duplicated record' do
    ROOT_CHILD_SELECTOR = '#infinite-tree-container .root.node > .node-children > li.node'

    # The tree renders over fetch, so wait for it rather than reading whatever
    # Capybara's non-waiting `all` happens to see.
    def root_child_titles
      expect(page).to have_css(ROOT_CHILD_SELECTOR, minimum: 1)

      page
        .all("#{ROOT_CHILD_SELECTOR} > .node-row .record-title", visible: :all)
        .map { |title| title.text(:all).strip }
    end

    it 'is placed after its original and survives the original being deleted' do
      duplicate_title = "[Duplicated] #{ao.title}"

      select_tree_row(ao)
      click_infinite_tree_toolbar_add_duplicate

      # The record pane loads over fetch, so click_infinite_tree_toolbar_add_duplicate's
      # wait_for_ajax does not cover the form swap. Without this wait the original's
      # form is still mounted and Save overwrites it instead of creating the duplicate.
      expect(page).to have_css('.alert.alert-success.with-hide-alert', text: /duplicated from/)
      expect(page.current_url).to include('#new')

      fill_and_save_new_child_record(
        title: duplicate_title,
        form_prefix: child_form_prefix
      )

      expect(page).to have_css('#infinite-tree-container .record-title', text: duplicate_title)

      # Ordering is a persistence property, and right after Save the tree still
      # holds the synthetic create row, so re-read it from a fresh load.
      visit edit_path
      wait_for_ajax

      titles = root_child_titles
      expect(titles).to include(ao.title, duplicate_title)
      expect(titles.index(duplicate_title)).to eq(titles.index(ao.title) + 1)

      select_tree_row(ao)
      # Same fetch-vs-wait_for_ajax gap: make sure the pane really is showing the
      # original before Delete, or the duplicate gets deleted instead.
      wait_for_infinite_tree_inline_edit_form(form_prefix: child_form_prefix)
      within '#infinite-tree-record-pane' do
        expect(page).to have_css('h2', text: ao.title)
        click_on 'Delete'
      end
      within '#confirmChangesModal' do
        click_on 'Delete'
      end
      wait_for_ajax

      visit edit_path
      wait_for_ajax

      aggregate_failures do
        expect(root_child_titles).to include(duplicate_title)
        expect(root_child_titles).not_to include(ao.title)
      end
    end
  end

  # Ported from the 'supporting reorder mode' shared examples ('hides root node
  # drag handle'). #refreshDraggables excludes li.node.root, and the root row
  # template renders an empty drag-handle column with no grip svg.
  describe 'the root row in reorder mode' do
    before do
      enable_reorder_mode
      wait_for_reorder_mode_ready
    end

    it 'is not draggable and shows no drag handle' do
      root_row = page.find("#infinite-tree-container li.node.root[data-uri='#{resource.uri}'] > .node-row")
      child_row = tree_row(ao.uri)

      aggregate_failures do
        expect(root_row['draggable']).not_to eq('true')
        expect(root_row).to have_no_css('.node-column[data-column="drag-handle"] svg')
        # Sanity check that reorder mode is genuinely on.
        expect(child_row['draggable']).to eq('true')
        expect(child_row).to have_css('.node-column[data-column="drag-handle"] svg', visible: :all)
      end
    end
  end
end
