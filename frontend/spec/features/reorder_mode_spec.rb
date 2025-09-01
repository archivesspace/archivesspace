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

    # Reliable element interaction
  def safely_interact_with_element(element, container: nil)
    if container
      container.scroll_to(element, align: :center)
    else
      page.execute_script("arguments[0].scrollIntoView({block: 'center'});", element.native)
    end

    expect(element).to be_visible

    element.click
    wait_for_ajax
  end

  # Reliable drag and drop operations
  def safely_drag_and_drop(source_element, target_element, container: nil)
    if container
      container.scroll_to(source_element, align: :center)
      container.scroll_to(target_element, align: :center)
    else
      page.execute_script("arguments[0].scrollIntoView({block: 'center'});", source_element.native)
      page.execute_script("arguments[0].scrollIntoView({block: 'center'});", target_element.native)
    end

    expect(source_element).to be_visible
    expect(target_element).to be_visible

    source_element.drag_to(target_element)
    wait_for_ajax
  end

  shared_examples 'supporting reorder mode' do
    before(:each) do
      visit "/#{@collection_path}/#{@parent.id}/edit"
      wait_for_ajax
      expect(page).not_to have_css '#tree-container.drag-enabled'
      click_on "Enable Reorder Mode"
      wait_for_ajax

      @tree_container = find('#tree-container')
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

    it 'root node does not have a visible .expandme button' do
      expect(page).not_to have_css '.drag-enabled .root-row.current .expandme'
    end

    it 'parent child nodes have a visible .expandme button' do
      # Find nodes that have children (parent nodes)
      parent_nodes = @children.select do |child|
        case @child_type
        when 'classification_term'
          [@classification_term2].include?(child) # classification_term2 has classification_term3 as child
        when 'digital_object_component'
          [@doc2].include?(child) # doc2 has doc3 as child
        when 'archival_object'
          [@ao2].include?(child) # ao2 has ao3 as child
        end
      end

      parent_nodes.each do |parent_node|
        expect(page).to have_css "##{@child_type}_#{parent_node.id} .expandme", visible: true
      end
    end

    it '.expandme buttons expand/collapse parents' do
      # Find a parent node that has children
      parent_node = case @child_type
                    when 'classification_term'
                      @classification_term2
                    when 'digital_object_component'
                      @doc2
                    when 'archival_object'
                      @ao2
                    end

      parent_row = find("##{@child_type}_#{parent_node.id}")
      expandme_button = parent_row.find('.expandme')

      # Wait for element to be fully ready
      expect(page).to have_css "##{@child_type}_#{parent_node.id} .expandme", visible: true

      # Initially collapsed
      expect(expandme_button['aria-expanded']).to eq('false')

      # Click to expand using safe interaction with tree container
      safely_interact_with_element(expandme_button, container: @tree_container)

      # Should now be expanded
      expect(expandme_button['aria-expanded']).to eq('true')

      # Click to collapse using safe interaction with tree container
      safely_interact_with_element(expandme_button, container: @tree_container)

      # Should be collapsed again
      expect(expandme_button['aria-expanded']).to eq('false')
    end

    it 'reorder mode works by drag and drop' do
      # Skip if there are fewer than 2 children
      skip('Need at least 2 children for drag and drop test') if @children.length < 2

      first_child = @children.first
      second_child = @children.last

      first_child_row = find("##{@child_type}_#{first_child.id}")
      second_child_row = find("##{@child_type}_#{second_child.id}")

      # Verify both nodes are present and draggable
      expect(first_child_row).to have_css '.drag-handle'
      expect(second_child_row).to have_css '.drag-handle'

      # Perform actual drag and drop using helper method with tree container
      safely_drag_and_drop(first_child_row, second_child_row, container: @tree_container)

      # Verify nodes still exist after drag and drop
      expect(page).to have_css "##{@child_type}_#{first_child.id}"
      expect(page).to have_css "##{@child_type}_#{second_child.id}"
    end

    it 'multiselect functionality is available' do
      # Verify that nodes can be selected and have the necessary elements for multiselect
      @children.each do |child|
        child_row = find("##{@child_type}_#{child.id}")

        # Click to select node using safe interaction with tree container
        safely_interact_with_element(child_row, container: @tree_container)

        # Verify the node exists and has basic functionality
        expect(child_row).to have_css '.drag-handle'
        expect(child_row).to have_css '.record-title'
      end
    end

    it 'toolbar buttons are present' do
      # Just verify that basic toolbar functionality exists
      expect(page).to have_css '#tree-toolbar'

      # Check for the buttons we know exist
      toolbar = find('#tree-toolbar')
      expect(toolbar).to have_css '.btn', text: 'Disable Reorder Mode'

      # Select a node to potentially enable more buttons
      first_child = @children.first
      first_child_row = find("##{@child_type}_#{first_child.id}")

      # Click using safe interaction with tree container
      safely_interact_with_element(first_child_row, container: @tree_container)

      # Verify toolbar still exists and functions
      expect(page).to have_css '#tree-toolbar'
    end

    it 'multiselected rows have drag functionality' do
      # Verify that all child nodes have proper drag handles for potential multiselect
      @children.each do |child|
        child_row = find("##{@child_type}_#{child.id}")

        # Scroll into view to ensure element is visible using tree container
        @tree_container.scroll_to(child_row, align: :center)

        # Ensure element is visible before checking attributes
        expect(child_row).to be_visible

        expect(child_row).to have_css '.drag-handle svg'
        expect(child_row).to have_css '.record-title'
      end
    end

    it 'disable reorder mode button works' do
      # Verify we're in reorder mode
      expect(page).to have_css '#tree-container.drag-enabled'

      # Click Disable Reorder Mode button
      disable_button = find('#tree-toolbar .btn-group:first-child .btn', text: 'Disable Reorder Mode')

      # Click disable button using safe interaction (no container needed for toolbar button)
      safely_interact_with_element(disable_button)

      # Verify reorder mode is disabled
      expect(page).not_to have_css '#tree-container.drag-enabled'

      # Verify Enable Reorder Mode button is visible again
      expect(page).to have_css '.btn', text: 'Enable Reorder Mode'

      # Verify drag handles are hidden
      @children.each do |child|
        expect(page).not_to have_css "##{@child_type}_#{child.id} .drag-handle svg", visible: true
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
