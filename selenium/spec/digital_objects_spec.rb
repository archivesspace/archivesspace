require_relative 'spec_helper'

describe "Digital Objects" do

  before(:all) do

    @repo = create(:repo, :repo_code => "do_test_#{Time.now.to_i}")
    set_repo @repo

    @do = create(:digital_object)
    @do_child1 = create(:digital_object_component, {:digital_object => {:ref => @do.uri}})
    @do_child2 = create(:digital_object_component, {:digital_object => {:ref => @do.uri}})

    @do2 = create(:digital_object)

    user = create_user(@repo => ['repository-archivists'])
    @driver = Driver.get.login_to_repo(user, @repo)
  end


  after(:all) do
    @driver.quit
  end


  it "reports errors and warnings when creating an invalid Digital Object" do
    @driver.find_element(:link, "Create").click
    @driver.click_and_wait_until_gone(:link, "Digital Object")
    @driver.find_element(:id, "digital_object_title_").clear
    @driver.click_and_wait_until_gone(:css => "form#new_digital_object button[type='submit']")

    @driver.find_element_with_text('//div[contains(@class, "error")]', /Identifier - Property is required but was missing/)

    # cancel those changes (shows a new form)
    @driver.click_and_wait_until_gone(:css, "a.btn.btn-cancel")

    # and jump back home so we can start again
    @driver.go_home
  end


  digital_object_title = "Pony Express Digital Image"

  it "can create a digital_object with one file version" do
    @driver.find_element(:link, "Create").click
    @driver.click_and_wait_until_gone(:link, "Digital Object")

    @driver.clear_and_send_keys([:id, "digital_object_title_"],(digital_object_title))
    @driver.clear_and_send_keys([:id, "digital_object_digital_object_id_"],(Digest::MD5.hexdigest("#{Time.now}")))

    @driver.find_element(:id => 'digital_object_digital_object_type_').select_option_with_text("Mixed Materials")

    @driver.find_element(:css => "section#digital_object_file_versions_ > h3 > .btn:not(.show-all)").click

    @driver.clear_and_send_keys([:id, "digital_object_file_versions__0__file_uri_"], "/uri/for/this/file/version")
    @driver.clear_and_send_keys([:id , "digital_object_file_versions__0__file_size_bytes_"], '100')

    @driver.click_and_wait_until_gone(:css => "form#new_digital_object button[type='submit']")

    # The new Digital Object shows up on the tree
    @driver.find_element(:css => "tr.root-row .title").text.strip.should match(/#{digital_object_title}/)
  end

  it "can handle multiple file versions and file system and network path types" do
    [
     '/root/top_secret.txt',
     'C:\Program Files\windows.exe',
     '\\\\SomeAwesome\Network\location.bat',
    ].each_with_index do |uri, idx|
      i = idx + 1
      @driver.find_element(:css => "section#digital_object_file_versions_ > h3 > .btn:not(.show-all)").click
      @driver.clear_and_send_keys([:id, "digital_object_file_versions__#{i}__file_uri_"], uri)
      @driver.click_and_wait_until_gone(:css => ".form-actions button[type='submit']")
    end
    @driver.find_element(:link, "Close Record").click
    @driver.find_element_with_text('//h3', /File Versions/)
    @driver.click_and_wait_until_gone(:link, "Edit")
  end

  it "reports errors if adding a child with no title to a Digital Object" do
    @driver.get_edit_page(@do2)
    @driver.find_element(:link, "Add Child").click
    @driver.wait_for_ajax
    @driver.find_element(:id, "digital_object_component_component_id_")

    @driver.clear_and_send_keys([:id, "digital_object_component_component_id_"], "123")
    sleep(2)

    # False start: create an object without filling it out
    @driver.click_and_wait_until_gone(:id => "createPlusOne")
    @driver.find_element_with_text('//div[contains(@class, "error")]', /you must provide/)

    @driver.click_and_wait_until_gone(:css, "a.btn.btn-cancel")
  end


  # Digital Object Component Nodes in Tree

  it "can populate the digital object component tree" do
    @driver.get_edit_page(@do2)
    @driver.find_element(:link, "Add Child").click
    @driver.wait_for_ajax
    @driver.find_element(:id, "digital_object_component_component_id_")

    @driver.clear_and_send_keys([:id, "digital_object_component_title_"], "JPEG 2000 Verson of Image")
    @driver.clear_and_send_keys([:id, "digital_object_component_component_id_"],(Digest::MD5.hexdigest("#{Time.now}")))

    @driver.click_and_wait_until_gone(:id => "createPlusOne")

    ["PNG format", "GIF format", "BMP format"].each_with_index do |thing, idx|

      # Wait for the new empty form to be populated.  There's a tricky race
      # condition here that I can't quite track down, so here's my blunt
      # instrument fix.
      @driver.find_element(:xpath, "//textarea[@id='digital_object_component_title_' and not(text())]")

      @driver.clear_and_send_keys([:id, "digital_object_component_title_"],(thing))
      @driver.clear_and_send_keys([:id, "digital_object_component_label_"],(thing))
      @driver.clear_and_send_keys([:id, "digital_object_component_component_id_"],(Digest::MD5.hexdigest("#{thing}#{Time.now}")))

      @driver.find_element(:css => "section#digital_object_component_file_versions_ > h3 > .btn:not(.show-all)").click
      @driver.clear_and_send_keys([:id, "digital_object_component_file_versions__0__file_uri_"], "/uri/for/this/file/version")

      if idx < 2
        @driver.click_and_wait_until_gone(:id => "createPlusOne")
      else
        @driver.click_and_wait_until_gone(:css => "form#new_digital_object_component button[type='submit']")
      end
    end


    elements = @driver.blocking_find_elements(:css => ".largetree-node.indent-level-1").map{|li| li.text.strip}

    ["PNG format", "GIF format", "BMP format"].each do |thing|
      elements.any? {|elt| elt =~ /#{thing}/}.should be_truthy
    end

  end

  it "can drag and drop reorder a Digital Object" do

    @driver.get("#{$frontend}#{@do.uri.sub(/\/repositories\/\d+/, '')}/edit#tree::digital_object_component_#{@do_child1.id}")
    @driver.wait_for_ajax

    child = @driver.find_element(:id, "digital_object_component_#{@do_child1.id}")
    expect(child.attribute('class')).to include('current')

    # create grand child
    tree_add_child

    child_title = 'ICO'

    @driver.clear_and_send_keys([:id, "digital_object_component_title_"], child_title)
    @driver.clear_and_send_keys([:id, "digital_object_component_component_id_"],(Digest::MD5.hexdigest("#{Time.now}")))

    @driver.click_and_wait_until_gone(:css => "form#new_digital_object_component button[type='submit']")
    @driver.wait_for_ajax

    expand_tree_pane
    root = tree_node_for_title(@do.title)
    expect(root.attribute('class')).to include('root-row')
    child = @driver.find_element(:id, "digital_object_component_#{@do_child1.id}")
    expect(child.attribute('class')).to include('indent-level-1')
    grand_child = tree_node_for_title(child_title)
    expect(grand_child.attribute('class')).to include('indent-level-2')

    tree_drag_and_drop(grand_child, root, 'Add Items as Children')

    root = tree_node_for_title(@do.title)
    expect(root.attribute('class')).to include('root-row')
    child = @driver.find_element(:id, "digital_object_component_#{@do_child1.id}")
    expect(child.attribute('class')).to include('indent-level-1')
    grand_child = tree_node_for_title(child_title)
    expect(grand_child.attribute('class')).to include('indent-level-1')

    # refresh the page and verify that the change really stuck
    @driver.navigate.refresh
    @driver.wait_for_ajax

    root = tree_node_for_title(@do.title)
    expect(root.attribute('class')).to include('root-row')
    child = @driver.find_element(:id, "digital_object_component_#{@do_child1.id}")
    expect(child.attribute('class')).to include('indent-level-1')
    grand_child = tree_node_for_title(child_title)
    expect(grand_child.attribute('class')).to include('indent-level-1')
  end

  it "can change default values" do
  end
end
