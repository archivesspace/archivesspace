# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Reorder Mode', js: true do
  def modified_click(element, key:)
    page.driver.browser.action
        .key_down(key)
        .move_to(element.native)
        .click
        .key_up(key)
        .perform
  end

  def ctrl_click(element)
    modified_click(element, key: :control)
  end

  def shift_click(element)
    modified_click(element, key: :shift)
  end

  before(:all) do
    @now = Time.now.to_i
    @repo = create(:repo, repo_code: "reorder_mode_test_#{@now}")

    set_repo(@repo)
  end

  before :each do
    login_admin
    select_repository(@repo)
  end

  shared_examples 'supporting reorder mode' do
    before(:each) do
      visit "/#{@collection_path}/#{@parent.id}/edit"
      wait_for_ajax
      expect(page).not_to have_css '#tree-container.drag-enabled'
      click_on "Enable Reorder Mode"
      wait_for_ajax
    end

    it 'allows enabling reorder mode' do
      expect(page).to have_css '#tree-container.drag-enabled'
    end

    it 'returns to non-reorder mode when disabled' do
      click_on 'Disable Reorder Mode'
      expect(page).to have_css '#tree-toolbar .drag-toggle', text: 'Enable Reorder Mode'
      expect(page).not_to have_css '#tree-container.drag-enabled'
    end

    it 'presents toolbar buttons in correct order' do
      toolbar = find('#tree-toolbar')
      expect(toolbar).to have_css '.btn-group:first-child .btn', text: 'Disable Reorder Mode'
      expect(toolbar).to have_css '.btn-group:nth-child(2) .btn:first-child', text: 'Cut'
      expect(toolbar).to have_css '.btn-group:nth-child(2) .btn:last-child', text: 'Paste'
      expect(toolbar).to have_css '.btn-group:nth-child(3) li:first-child', text: 'Drop Before'
      expect(toolbar).to have_css '.btn-group:nth-child(3) li:nth-child(2)', text: 'Drop as Child'
      expect(toolbar).to have_css '.btn-group:nth-child(3) li:last-child', text: 'Drop After'
      expect(toolbar).to have_css '.btn-group:nth-child(4)', visible: false
      expect(toolbar).to have_css '.btn-group:nth-child(5) .btn', text: 'Close Record'
      expect(toolbar).to have_css '.btn-group:nth-child(6)', visible: false
    end

    it 'hides non-reorder actions while reorder mode is active' do
      toolbar = find('#tree-toolbar')
      expect(toolbar).to have_no_button('Auto-Expand All')
      expect(toolbar).to have_no_button('Collapse Tree')
      expect(toolbar).to have_no_button('Load via Spreadsheet')
      expect(toolbar).to have_no_button('Rapid Data Entry')
    end

    it 'shows paste control in reorder mode before any cut action' do
      expect(page).to have_css '#tree-toolbar .paste-selection'
      expect(page).to have_no_css '.cut'
    end

    it 'cuts the current row and enables paste' do
      click_on @children.first.title
      click_on 'Cut'

      expect(page).to have_css ".cut##{@child_type}_#{@children.first.id}"
      expect(page).to have_no_css '#tree-toolbar .paste-selection.disabled'
    end

    it 'does not cut the root row' do
      click_on @children.first.title
      click_on 'Cut'
      expect(page).to have_css '.cut'

      find('.root-row .record-title').click
      click_on 'Cut'
      expect(page).to have_no_css '.cut'
    end

    it 'shows move action for non-root rows only' do
      expect(page).to have_no_css '#tree-toolbar .move-node'

      click_on @children.first.title
      expect(page).to have_css '#tree-toolbar .move-node'
    end

    it 'persists selected drop behavior across reloads' do
      find('label[for="drop-after"]').click
      expect(find('#drop-after', visible: false)).to be_checked
      expect(page.evaluate_script("window.localStorage.getItem('AS_Drop_Behavior')")).to eq('after')

      visit "/#{@collection_path}/#{@parent.id}/edit"
      wait_for_ajax
      click_on 'Enable Reorder Mode'
      expect(find('#drop-after', visible: false)).to be_checked
    end

    it 'hides root node drag handle' do
      expect(page).to have_css '.drag-enabled .root-row.current .no-drag-handle'
      expect(page).not_to have_css '.drag-enabled .root-row.current .no-drag-handle svg'
    end

    it 'shows child nodes drag handle' do
      @children.each do |child|
        expect(page).to have_css ".drag-enabled ##{@child_type}_#{child.id} .drag-handle svg"
      end
    end
  end

  context 'when viewing classifications' do
    before :all do
      @collection_path = 'classifications'
      @parent = create(:classification, title: "Classification #{@now}")
      @classification_term = create(:classification_term, classification: { ref: @parent.uri }, title: "Classification Term #{@now}")
      @classification_term2 = create(:classification_term, classification: { ref: @parent.uri }, title: "Classificatin Term 2 #{@now}")
      @classification_term3 = create(:classification_term, classification: { ref: @parent.uri }, parent: { ref: @classification_term2.uri }, title: "Classification Term 3 #{@now}")
      @classification_term4 = create(:classification_term, classification: { ref: @parent.uri }, parent: { ref: @classification_term3.uri }, title: "Classification Term 4 #{@now}")
      @child_type = 'classification_term'
      @children = [@classification_term, @classification_term2]

      run_indexer
    end

    it_behaves_like 'supporting reorder mode'
  end

  context 'when viewing digital objects' do
    before :all do
      @collection_path = 'digital_objects'
      @parent = create(:digital_object, title: "Digital Object #{@now}")
      @doc = create(:digital_object_component, digital_object: { ref: @parent.uri }, title: "Digital Object Component #{@now}")
      @doc2 = create(:digital_object_component, digital_object: { ref: @parent.uri }, title: "Digital Object Component 2 #{@now}")
      @doc3 = create(:digital_object_component, digital_object: { ref: @parent.uri }, title: "Digital Object Component 3 #{@now}")
      @doc2_child = create(:digital_object_component, digital_object: { ref: @parent.uri }, parent: { ref: @doc2.uri }, title: "Digital Object Component 2 Child #{@now}")
      @child_type = 'digital_object_component'
      @children = [@doc, @doc2, @doc3]

      run_indexer
    end

    context 'legacy multi-select' do
      before(:each) do
        visit "/#{@collection_path}/#{@parent.id}/edit"
        wait_for_ajax
        expect(page).not_to have_css '#tree-container.drag-enabled'
        click_on 'Enable Reorder Mode'
        wait_for_ajax
        expect(page).to have_css '#tree-container.drag-enabled'

        expect(page).to have_css "#digital_object_component_#{@doc.id}"
        expect(page).to have_css "#digital_object_component_#{@doc2.id}"
        expect(page).to have_css "#digital_object_component_#{@doc3.id}"
      end

      def row_for(id)
        find("#digital_object_component_#{id}")
      end

      def expect_row_selected(id)
        expect(row_for(id)[:class].to_s.split).to include('multiselected-row')
      end

      def expect_row_not_selected(id)
        expect(row_for(id)[:class].to_s.split).not_to include('multiselected-row')
      end

      def expect_row_cut(id)
        expect(row_for(id)[:class].to_s.split).to include('cut')
      end

      def ctrl_select_row(id)
        execute_script(<<~JS)
          (function () {
            var row = document.querySelector('#digital_object_component_#{id}');
            if (!row) return;
            row.dispatchEvent(new MouseEvent('mousedown', { bubbles: true, ctrlKey: true }));
          })();
        JS
      end

      def shift_select_row(id)
        execute_script(<<~JS)
          (function () {
            var row = document.querySelector('#digital_object_component_#{id}');
            if (!row) return;
            row.dispatchEvent(new MouseEvent('mousedown', { bubbles: true, shiftKey: true }));
          })();
        JS
      end

      it 'supports ctrl multiselect toggle add/remove' do
        ctrl_select_row(@doc.id)
        expect(row_for(@doc.id)).to have_css('.drag-handle.multiselected')
        expect_row_selected(@doc.id)

        ctrl_select_row(@doc2.id)
        expect_row_selected(@doc.id)
        expect_row_selected(@doc2.id)

        ctrl_select_row(@doc.id)
        expect_row_not_selected(@doc.id)
        expect_row_selected(@doc2.id)
      end

      it 'supports shift range selection using last-selected anchor and same-level filtering' do
        find("#digital_object_component_#{@doc2.id} button.expandme").click
        expect(page).to have_css("#digital_object_component_#{@doc2_child.id}", visible: true)

        ctrl_select_row(@doc.id)
        shift_select_row(@doc3.id)

        expect_row_selected(@doc.id)
        expect_row_selected(@doc2.id)
        expect_row_selected(@doc3.id)

        expect_row_not_selected(@doc2_child.id)
      end

      it 'clears transient multiselection when clicking outside tree/toolbar' do
        ctrl_select_row(@doc.id)
        ctrl_select_row(@doc2.id)
        expect(page).to have_css('#tree-container .multiselected-row', count: 2)

        execute_script("document.dispatchEvent(new MouseEvent('mousedown', { bubbles: true }));")
        expect(page).to have_no_css('#tree-container .multiselected')
        expect(page).to have_no_css('#tree-container .multiselected-row')
      end

      it 'prunes hidden selections when collapsing a node' do
        find("#digital_object_component_#{@doc2.id} button.expandme").click
        expect(page).to have_css("#digital_object_component_#{@doc2_child.id}", visible: true)

        ctrl_select_row(@doc2_child.id)
        ctrl_select_row(@doc3.id)
        expect(page).to have_css('#tree-container .multiselected-row', count: 2)

        find("#digital_object_component_#{@doc2.id} button.expandme").click

        expect_row_selected(@doc3.id)
        expect(page).to have_css('#tree-container .multiselected-row', count: 1)
        expect(page).to have_no_css("#digital_object_component_#{@doc2_child.id}.multiselected-row", visible: :all)
      end

      it 'cuts the multiselection set and clears transient selection' do
        ctrl_select_row(@doc.id)
        ctrl_select_row(@doc2.id)
        click_on 'Cut'

        expect_row_cut(@doc.id)
        expect_row_cut(@doc2.id)
        expect(page).to have_no_css('#tree-container .multiselected')
        expect(page).to have_no_css('#tree-container .multiselected-row')
      end

      it 'uses the last-selected item as the shift-range anchor' do
        ctrl_select_row(@doc.id)
        ctrl_select_row(@doc2.id)
        ctrl_select_row(@doc.id) # remove doc, leaving doc2 as last selection anchor
        shift_select_row(@doc3.id)

        expect_row_not_selected(@doc.id)
        expect_row_selected(@doc2.id)
        expect_row_selected(@doc3.id)
      end
    end

    it_behaves_like 'supporting reorder mode'
  end

  context 'when viewing resources' do
    before :all do
      @collection_path = 'resources'
      @parent = create(:resource, title: "Resource #{@now}")
      @ao = create(:archival_object, resource: { ref: @parent.uri }, title: "Archival Object #{@now}")
      @ao2 = create(:archival_object, resource: { ref: @parent.uri }, title: "Archival Object 2 #{@now}")
      @ao3 = create(:archival_object, resource: { ref: @parent.uri }, parent: { ref: @ao2.uri }, title: "Archival Object 3 #{@now}")
      @child_type = 'archival_object'
      @children = [@ao, @ao2]

      run_indexer
    end

    before(:each) do
      visit "/#{@collection_path}/#{@parent.id}/edit"
      skip_if_infinite_tree_toolbar_active
    end

    it_behaves_like 'supporting reorder mode'

    it 'disables reorder mode toggle when the form is dirty' do
      skip_if_infinite_tree_toolbar_active

      click_on @ao.title
      wait_for_ajax

      fill_in 'Title', with: "Dirty title #{@now}"
      expect(page).to have_css '#tree-toolbar .drag-toggle.disabled'
    end
  end
end
