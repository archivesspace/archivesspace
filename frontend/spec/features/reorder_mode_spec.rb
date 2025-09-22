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

    # For hidden elements (like radio buttons), don't check visibility
    if element[:type] == 'radio' && !element.visible?
      page.execute_script("arguments[0].click();", element)
    else
      expect(element).to be_visible
      element.click
    end
    wait_for_ajax
  end

  # Helper method to handle cross-platform multiselect key
  def multiselect_key
    # Use Command key on Mac, Control key on Windows/Linux
    if RUBY_PLATFORM.downcase.include?('darwin')
      :command
    else
      :control
    end
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

    it 'presents toolbar buttons in correct order and drop behavior buttons work' do
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

      # Verify the drop behavior radio buttons are present and functional
      drop_behavior_group = find('[data-radio-group="drop-behavior"]')
      expect(drop_behavior_group).to be_visible

      # Test each drop behavior radio button
      ['before', 'into', 'after'].each do |behavior|
        # Find and click the radio button directly
        radio_button = find("input[type='radio'][name='drop-behavior'][value='#{behavior}']", visible: false)
        expect(radio_button).to be_present
        
        # Click the radio button using JavaScript since it's hidden
        page.execute_script("arguments[0].click();", radio_button)
        
        # Verify it's selected
        expect(radio_button).to be_checked
      end
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

    it 'reorder mode works by drag and drop in conjunction with drop behavior buttons' do
      # Skip if there are fewer than 2 children
      skip('Need at least 2 children for drag and drop test') if @children.length < 2

      first_child = @children.first
      second_child = @children.last

      first_child_row = find("##{@child_type}_#{first_child.id}")
      second_child_row = find("##{@child_type}_#{second_child.id}")

      # Verify both nodes are present and draggable
      expect(first_child_row).to have_css '.drag-handle'
      expect(second_child_row).to have_css '.drag-handle'

      # Test different drop behavior modes
      ['before', 'into', 'after'].each do |drop_behavior|
        # Set the drop behavior using radio buttons
        radio_button = find("input[type='radio'][name='drop-behavior'][value='#{drop_behavior}']", visible: false)
        page.execute_script("arguments[0].click();", radio_button)
        
        # Verify the radio button is selected
        expect(radio_button).to be_checked

        # Perform drag and drop using helper method with tree container
        safely_drag_and_drop(first_child_row, second_child_row, container: @tree_container)

        # Verify nodes still exist after drag and drop
        expect(page).to have_css "##{@child_type}_#{first_child.id}"
        expect(page).to have_css "##{@child_type}_#{second_child.id}"
      end
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

    it 'multiselect drag and drop works' do
      # Skip if there are fewer than 3 children for proper multiselect testing
      skip('Need at least 3 children for multiselect drag and drop test') if @children.length < 3

      first_child = @children.first
      second_child = @children[1] if @children.length > 1
      third_child = @children.last

      first_child_row = find("##{@child_type}_#{first_child.id}")
      second_child_row = find("##{@child_type}_#{second_child.id}") if second_child
      third_child_row = find("##{@child_type}_#{third_child.id}")

      # Multiselect multiple nodes using Ctrl+click (or Cmd+click on Mac)
      # First, click the first node to select it
      safely_interact_with_element(first_child_row, container: @tree_container)

      # Then Ctrl+click the second node to add it to selection
      if second_child_row
        @tree_container.scroll_to(second_child_row, align: :center)
        page.driver.browser.action.key_down(multiselect_key).click(second_child_row.native).key_up(multiselect_key).perform
        wait_for_ajax
      end

      # Verify multiselection worked by checking for multiselected class
      expect(first_child_row).to have_css '.drag-handle.multiselected'
      if second_child_row
        expect(second_child_row).to have_css '.drag-handle.multiselected'
      end

      # Perform drag and drop of multiselected items
      safely_drag_and_drop(first_child_row, third_child_row, container: @tree_container)

      # Verify nodes still exist after multiselect drag and drop
      expect(page).to have_css "##{@child_type}_#{first_child.id}"
      if second_child
        expect(page).to have_css "##{@child_type}_#{second_child.id}"
      end
      expect(page).to have_css "##{@child_type}_#{third_child.id}"
    end

    it 'multiselected rows are numbered accordingly (1, 2, 3, etc.)' do
      # Skip if there are fewer than 3 children for proper numbering test
      skip('Need at least 3 children for numbering test') if @children.length < 3

      first_child = @children.first
      second_child = @children[1]
      third_child = @children[2] if @children.length > 2

      first_child_row = find("##{@child_type}_#{first_child.id}")
      second_child_row = find("##{@child_type}_#{second_child.id}")
      third_child_row = find("##{@child_type}_#{third_child.id}") if third_child

      # Multiselect multiple nodes using Ctrl+click (or Cmd+click on Mac)
      # First, click the first node to select it
      safely_interact_with_element(first_child_row, container: @tree_container)

      # Then Ctrl+click the second node to add it to selection
      @tree_container.scroll_to(second_child_row, align: :center)
      page.driver.browser.action.key_down(multiselect_key).click(second_child_row.native).key_up(multiselect_key).perform
      wait_for_ajax

      # Add third node if available
      if third_child_row
        @tree_container.scroll_to(third_child_row, align: :center)
        page.driver.browser.action.key_down(multiselect_key).click(third_child_row.native).key_up(multiselect_key).perform
        wait_for_ajax
      end

      # Verify that multiselected rows have drag annotations with numbers
      expect(first_child_row).to have_css '.drag-annotation', text: '1'
      expect(second_child_row).to have_css '.drag-annotation', text: '2'
      if third_child_row
        expect(third_child_row).to have_css '.drag-annotation', text: '3'
      end

      # Verify the drag handles are marked as multiselected
      expect(first_child_row).to have_css '.drag-handle.multiselected'
      expect(second_child_row).to have_css '.drag-handle.multiselected'
      if third_child_row
        expect(third_child_row).to have_css '.drag-handle.multiselected'
      end
    end

    it 'cut and paste buttons work' do
      # Skip if there are fewer than 2 children
      skip('Need at least 2 children for cut and paste test') if @children.length < 2

      first_child = @children.first
      second_child = @children.last

      first_child_row = find("##{@child_type}_#{first_child.id}")
      second_child_row = find("##{@child_type}_#{second_child.id}")

      # Select the first node
      safely_interact_with_element(first_child_row, container: @tree_container)

      # Click the Cut button
      cut_button = find('#tree-toolbar .btn', text: 'Cut')
      safely_interact_with_element(cut_button)

      # Verify the node is marked as cut (should have 'cut' class)
      expect(first_child_row).to have_css '.cut'

      # Verify the Paste button is now enabled (not disabled)
      paste_button = find('#tree-toolbar .btn', text: 'Paste')
      expect(paste_button).not_to have_css '.disabled'

      # Select the target node (where we want to paste)
      safely_interact_with_element(second_child_row, container: @tree_container)

      # Click the Paste button
      safely_interact_with_element(paste_button)

      # Wait for the operation to complete
      wait_for_ajax

      # Verify the cut class is removed after paste
      expect(first_child_row).not_to have_css '.cut'

      # Verify nodes still exist
      expect(page).to have_css "##{@child_type}_#{first_child.id}"
      expect(page).to have_css "##{@child_type}_#{second_child.id}"
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
      @classification_term2 = create(:classification_term, classification: { ref: @parent.uri }, title: "Classification Term 2 #{@now}")
      @classification_term3 = create(:classification_term, classification: { ref: @parent.uri }, parent: { ref: @classification_term2.uri }, title: "Classification Term 3 #{@now}")
      @classification_term4 = create(:classification_term, classification: { ref: @parent.uri }, parent: { ref: @classification_term3.uri }, title: "Classification Term 4 #{@now}")
      @classification_term5 = create(:classification_term, classification: { ref: @parent.uri }, title: "Classification Term 5 #{@now}")
      @child_type = 'classification_term'
      @children = [@classification_term, @classification_term2, @classification_term5]

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
      @doc4 = create(:digital_object_component, digital_object: { ref: @parent.uri }, title: "Digital Object Component 4 #{@now}")
      @child_type = 'digital_object_component'
      @children = [@doc, @doc2, @doc4]

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
      @ao4 = create(:archival_object, resource: { ref: @parent.uri }, title: "Archival Object 4 #{@now}")
      @child_type = 'archival_object'
      @children = [@ao, @ao2, @ao4]

      run_indexer
    end

    it_behaves_like 'supporting reorder mode'
  end
end
