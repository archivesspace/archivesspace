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

    it_behaves_like 'supporting reorder mode'
  end
end
