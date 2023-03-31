# frozen_string_literal: true

module TreeHelperMethods
  class Node
    def initialize(obj)
      @obj = obj
    end

    def tree_id
      "#{@obj.jsonmodel_type}_#{@obj.class.id_for(@obj.uri)}"
    end

    def li_selector
      "##{tree_id}"
    end

    def a_selector
      "#{li_selector} a.record-title"
    end
  end

  def tree_drag_and_drop(source, target, where_to_drop)
    unless ['before', 'into', 'after'].include?(where_to_drop)
      raise 'Need to specify valid place to drop: "' + where_to_drop + '" not supported'
    end

    source_tree_id = source.attribute('id')
    target_tree_id = target.attribute('id')

    @driver.find_element(:link, 'Enable Reorder Mode').click

    @driver.find_element(css: "label[for='drop-#{where_to_drop}']").click

    @driver.execute_script("tree.dragdrop.simulate_drag_and_drop('#{source_tree_id}', '#{target_tree_id}');")

    tree_wait_for_spinner
  end

  def tree_node(obj)
    Node.new(obj)
  end

  def tree_click(node)
    @driver.find_element(css: node.a_selector).click
  end

  def tree_node_for_title(title)
    tree_node_link_for_title(title)
      .find_element_orig(xpath: 'ancestor::div[@role="listitem"]')
  end

  def tree_node_link_for_title(title)
    @driver.find_element_with_text('//div[@id="tree-container"]//a[@class="record-title"]', /#{title}/)
  end

  def tree_current
    @driver.find_element(css: '#tree-container .current')
  end

  def tree_nodes_at_level(level)
    @driver.blocking_find_elements(css: "#tree-container .largetree-node.indent-level-#{level}")
  end

  def tree_add_sibling
    @driver.click_and_wait_until_gone(:link, 'Add Sibling')
    @driver.wait_for_ajax
  end

  def tree_add_child
    @driver.click_and_wait_until_gone(:link, 'Add Child')
    @driver.wait_for_ajax
  end

  def tree_wait_for_spinner
    # no spinner ... yet!
    @driver.wait_for_spinner
    @driver.wait_for_ajax
  end

  def tree_enable_reorder_mode
    expect(tree_container.attribute('class')).not_to include('drag-enabled')
    tree_enable_reorder_toggle.click
    expect(tree_container.attribute('class')).to include('drag-enabled')
  end

  def tree_disable_reorder_mode
    expect(tree_container.attribute('class')).to include('drag-enabled')
    tree_disable_reorder_toggle.click
    expect(tree_container.attribute('class')).not_to include('drag-enabled')
  end

  def tree_disable_reorder_toggle
    @driver.find_element(:link, 'Reorder Mode Active')
  end

  def tree_enable_reorder_toggle
    @driver.find_element(:link, 'Enable Reorder Mode')
  end

  def tree_container
    @driver.find_element(:id, 'tree-container')
  end

  def expand_tree_pane
    # if we're already maximized, we unmaximize first ( since it's possible
    # there been children added since last maximization, so we need to resize )
    @driver.find_element_orig(css: '.ui-resizable-handle.ui-resizable-s.maximized').find_element('button.tree-resize-toggle')
  rescue Selenium::WebDriver::Error::NoSuchElementError, Selenium::WebDriver::Error::StaleElementReferenceError => e
    # we aren't currently maximized, so please continue..
  ensure
    # now we maximize!
    @driver.find_element(css: 'button.tree-resize-toggle').click
  end
end
