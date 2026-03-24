# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Reorder Mode', js: true do
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
      @doc3 = create(:digital_object_component, digital_object: { ref: @parent.uri }, parent: { ref: @doc2.uri }, title: "Digital Object Component 3 #{@now}")
      @child_type = 'digital_object_component'
      @children = [@doc, @doc2]

      run_indexer
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
