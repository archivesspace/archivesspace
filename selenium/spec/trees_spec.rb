require_relative 'spec_helper'

describe "Tree UI" do

  before(:all) do
    @repo = create(:repo, :repo_code => "trees_test_#{Time.now.to_i}")
    set_repo @repo

    @viewer_user = create_user(@repo => ['repository-viewers'])

    @driver = Driver.get
    @driver.login_to_repo($admin, @repo)
  end

  before(:each) do

    @r = create(:resource)
    @a1 = create(:archival_object, {:resource => {:ref => @r.uri}})
    @a2 = create(:archival_object, {:resource => {:ref => @r.uri}})
    @a3 = create(:archival_object, {:resource => {:ref => @r.uri}})

    @driver.get_edit_page(@r)
    @driver.wait_for_ajax
  end


  after(:all) do
    @driver.quit
  end


  it "can add a sibling" do

    @driver.find_elements(:css => ".root-row").length.should eq(1)
    @driver.find_elements(:css => ".largetree-node").length.should eq(3)

    tree_click(tree_node(@a3))

    tree_add_sibling

    @driver.clear_and_send_keys([:id, "archival_object_title_"], "Sibling")
    @driver.find_element(:id, "archival_object_level_").select_option("item")
    @driver.click_and_wait_until_gone(:css, "form#archival_object_form button[type='submit']")
    @driver.wait_for_ajax

    @driver.find_elements(:css => ".largetree-node").length.should eq(4)

    # reload the parent form to make sure the changes stuck
    @driver.get("#{$frontend}/#{@r.uri.sub(/\/repositories\/\d+/, '')}/edit")
    @driver.wait_for_ajax

    @driver.find_elements(:css => ".root-row").length.should eq(1)
    @driver.find_elements(:css => ".largetree-node").length.should eq(4)
  end


  it "can support dnd: into a sibling archival object" do
    @driver.navigate.refresh

    tree_enable_reorder_mode

    source = @driver.find_element(:id, tree_node(@a1).tree_id)
    target = @driver.find_element(:id, tree_node(@a2).tree_id)

    tree_drag_and_drop(source, target, 'Add Items as Children')

    # and find the former sibling and check indent
    source = @driver.find_element(:id, tree_node(@a1).tree_id)
    expect(source.attribute('class')).to include('indent-level-2')

    # refresh the page and verify that the change really stuck
    @driver.navigate.refresh

    # same check again
    @driver.find_element(:id, tree_node(@a2).tree_id)
      .find_element(:css => ".expandme").click
    # but this time wait for lazy loading and re-find the parent node
    @driver.wait_for_ajax


    target = @driver.find_element(:id, tree_node(@a2).tree_id)
    expect(target.attribute('class')).to include('indent-level-1')

    source = @driver.find_element(:id, tree_node(@a1).tree_id)
    expect(source.attribute('class')).to include('indent-level-2')
  end

  it "can not reorder the tree while editing a node" do

    tree_click(tree_node(@a3))

    @driver.clear_and_send_keys([:id, "archival_object_title_"], @a3.title.sub(/Archival Object/, "Resource Component"))

    expect(tree_enable_reorder_toggle.attribute('class')).to include('disabled')

    @driver.ensure_no_such_element(:css, '.largetree-node .drag-handle')

    # save the item
    @driver.click_and_wait_until_gone(:css => "form#archival_object_form button[type='submit']")
  end

  it "can move tree nodes into and out of each other" do
    tree_enable_reorder_mode

    [@a2, @a3].each do |sibling|
      tree_click(tree_node(sibling))

      @driver.find_element(:link, "Move").click

      @driver.execute_script('$("#tree-toolbar .dropdown-submenu:visible").addClass("open")')

      @driver.find_element(:css => "ul.move-node-into-menu")
        .find_element(:xpath => ".//a[@data-tree_id='#{tree_node(@a1).tree_id}']")
        .click

      @driver.execute_script('$("#tree-toolbar .dropdown-submenu:visible").removeClass("open")')

      tree_wait_for_spinner
    end

    tree_disable_reorder_mode

    tree_click(tree_node(@a1))

    [@a2, @a3].each do |child_ao|
      parent = @driver.find_element(:id => tree_node(@a1).tree_id)
      expect(parent.attribute('class')).to include('indent-level-1')

      child = @driver.find_element(:id => tree_node(child_ao).tree_id)
      expect(child.attribute('class')).to include('indent-level-2')
    end

    # refresh the page and make sure they're still visible
    @driver.navigate.refresh

    [@a2, @a3].each do |child_ao|
      parent = @driver.find_element(:id => tree_node(@a1).tree_id)
      expect(parent.attribute('class')).to include('indent-level-1')

      child = @driver.find_element(:id => tree_node(child_ao).tree_id)
      expect(child.attribute('class')).to include('indent-level-2')
    end


    # now move them back
    tree_enable_reorder_mode

    [@a2, @a3].each do |child|
      tree_click(tree_node(child))

      @driver.find_element(:link, "Move").click
      @driver.find_element_with_text("//a", /Up a Level/).click

      tree_wait_for_spinner
    end

    tree_disable_reorder_mode

    2.times {|i|
      [@a2, @a3].each do |sibling|
        node = @driver.find_element(:id => tree_node(sibling).tree_id)
        expect(node.attribute('class')).to include('indent-level-1')
      end

      @driver.navigate.refresh if i == 0
    }

  end


  it "can delete a node and return to its parent" do
    tree_click(tree_node(@a1))

    @driver.find_element(:css, ".delete-record.btn").click
    @driver.click_and_wait_until_gone(:css, "#confirmChangesModal #confirmButton")

    node = @driver.find_element(:id => tree_node(@r).tree_id)
    expect(node.attribute('class')).to include('current')
  end


  it "can not reorder if logged in as a read only user" do
    @driver.login_to_repo(@viewer_user, @repo)
    @driver.get_view_page(@r)

    @driver.ensure_no_such_element(:link, 'Enable Reorder Mode')
    @driver.ensure_no_such_element(:css, '.largetree-node .drag-handle')
    @driver.login_to_repo($admin, @repo)
  end

end
