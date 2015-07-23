require_relative 'spec_helper'

describe "Digital Objects" do

  before(:all) do
    login_as_archivist
  end


  after(:all) do
    logout
  end


  it "reports errors and warnings when creating an invalid Digital Object" do
    $driver.find_element(:link, "Create").click
    $driver.find_element(:link, "Digital Object").click
    $driver.find_element(:id, "digital_object_title_").clear
    $driver.find_element(:css => "form#new_digital_object button[type='submit']").click

    $driver.find_element_with_text('//div[contains(@class, "error")]', /Identifier - Property is required but was missing/)

    $driver.find_element(:css, "a.btn.btn-cancel").click
  end


  digital_object_title = "Pony Express Digital Image"

  it "can create a digital_object with one file version" do
    $driver.find_element(:link, "Create").click
    $driver.find_element(:link, "Digital Object").click

    $driver.clear_and_send_keys([:id, "digital_object_title_"],(digital_object_title))
    $driver.clear_and_send_keys([:id, "digital_object_digital_object_id_"],(Digest::MD5.hexdigest("#{Time.now}")))

    $driver.find_element(:id => 'digital_object_digital_object_type_').select_option_with_text("Mixed Materials")

    $driver.find_element(:css => "section#digital_object_file_versions_ > h3 > .btn:not(.show-all)").click

    $driver.clear_and_send_keys([:id, "digital_object_file_versions__0__file_uri_"], "/uri/for/this/file/version")
    $driver.clear_and_send_keys([:id , "digital_object_file_versions__0__file_size_bytes_"], '100')

    $driver.find_element(:css => "form#new_digital_object button[type='submit']").click

    # The new Digital Object shows up on the tree
    assert(5) { $driver.find_element(:css => "a.jstree-clicked").text.strip.should match(/#{digital_object_title}/) }
  end

  it "can handle multiple file versions and file system and network path types" do
    [
     '/root/top_secret.txt',
     'C:\Program Files\windows.exe',
     '\\\\SomeAwesome\Network\location.bat',
    ].each_with_index do |uri, idx|
      i = idx + 1
      $driver.find_element(:css => "section#digital_object_file_versions_ > h3 > .btn:not(.show-all)").click
      $driver.clear_and_send_keys([:id, "digital_object_file_versions__#{i}__file_uri_"], uri)
      $driver.find_element(:css => ".form-actions button[type='submit']").click
    end
    $driver.find_element(:link, "Close Record").click
    $driver.find_element_with_text('//h3', /File Versions/)
    $driver.find_element(:link, "Edit").click
  end

  it "reports errors if adding a child with no title to a Digital Object" do

    $driver.attempt(10) { |attempt|
      attempt.navigate.refresh
      attempt.find_element(:link, "Add Child").click
      attempt.wait_for_ajax
      attempt.find_element(:id, "digital_object_component_component_id_")
    }

    $driver.clear_and_send_keys([:id, "digital_object_component_component_id_"], "123")
    sleep(2)

    # False start: create an object without filling it out
    $driver.click_and_wait_until_gone(:id => "createPlusOne")
    $driver.find_element_with_text('//div[contains(@class, "error")]', /you must provide/)
  end


  # Digital Object Component Nodes in Tree

  it "can populate the digital object component tree" do
    $driver.clear_and_send_keys([:id, "digital_object_component_title_"], "JPEG 2000 Verson of Image")
    $driver.clear_and_send_keys([:id, "digital_object_component_component_id_"],(Digest::MD5.hexdigest("#{Time.now}")))

    $driver.click_and_wait_until_gone(:id => "createPlusOne")

    ["PNG format", "GIF format", "BMP format"].each_with_index do |thing, idx|

      # Wait for the new empty form to be populated.  There's a tricky race
      # condition here that I can't quite track down, so here's my blunt
      # instrument fix.
      $driver.find_element(:xpath, "//textarea[@id='digital_object_component_title_' and not(text())]")

      $driver.clear_and_send_keys([:id, "digital_object_component_title_"],(thing))
      $driver.clear_and_send_keys([:id, "digital_object_component_label_"],(thing))
      $driver.clear_and_send_keys([:id, "digital_object_component_component_id_"],(Digest::MD5.hexdigest("#{thing}#{Time.now}")))

      $driver.find_element(:css => "section#digital_object_component_file_versions_ > h3 > .btn:not(.show-all)").click
      $driver.clear_and_send_keys([:id, "digital_object_component_file_versions__0__file_uri_"], "/uri/for/this/file/version")

      if idx < 2
        $driver.click_and_wait_until_gone(:id => "createPlusOne")
      else
        $driver.find_element(:css => "form#new_digital_object_component button[type='submit']").click
      end
    end


    elements = $driver.blocking_find_elements(:css => "li.jstree-leaf").map{|li| li.text.strip}

    ["PNG format", "GIF format", "BMP format"].each do |thing|
      elements.any? {|elt| elt =~ /#{thing}/}.should be_truthy
    end

  end

  it "can drag and drop reorder a Digital Object" do
    # create grand child
    $driver.find_element(:link, "Add Child").click

    $driver.clear_and_send_keys([:id, "digital_object_component_title_"], "ICO")
    $driver.clear_and_send_keys([:id, "digital_object_component_component_id_"],(Digest::MD5.hexdigest("#{Time.now}")))
    $driver.click_and_wait_until_gone(:css => "form#new_digital_object_component button[type='submit']")

    # first resize the tree pane (do it incrementally so it doesn't flip out...)
    pane_resize_handle = $driver.find_element(:css => ".ui-resizable-handle.ui-resizable-s")
    10.times {
      $driver.action.drag_and_drop_by(pane_resize_handle, 0, 10).perform
    }

    #drag to become sibling of parent
    source = $driver.find_element_with_text("//div[@id='archives_tree']//a", /ICO/)
    target = $driver.find_element_with_text("//div[@id='archives_tree']//a", /Pony Express Digital Image/)
    $driver.action.drag_and_drop(source, target).perform
    $driver.wait_for_ajax

    target = $driver.find_element_with_text("//div[@id='archives_tree']//li", /Pony Express Digital Image/)
    target.find_element_with_text(".//a", /ICO/)

    # refresh the page and verify that the change really stuck
    $driver.navigate.refresh

    target = $driver.find_element_with_text("//div[@id='archives_tree']//li", /Pony Express Digital Image/)
    target.find_element_with_text(".//a", /ICO/)

    $driver.click_and_wait_until_gone(:link, "Close Record")
    $driver.find_element(:xpath, "//a[@title='#{digital_object_title}']").click

    $driver.find_element_with_text("//h2", /#{digital_object_title}/)
  end


  it "applies i18n to the show view" do
    $driver.find_element_with_text("//div", /Mixed Materials/) # not mixed_materials
  end

  it "can merge a DO into a DO" do
    logout
    login_to_repo("admin", "admin", $test_repo)

    [ "Thing1", "Thing2"].each do |title|
      create_digital_object(:title => title  )
    end

    assert(10) {

      run_index_round

      $driver.find_element(:link, "Browse").click
      $driver.find_element(:link, "Digital Objects").click

      $driver.clear_and_send_keys([:css, ".sidebar input.text-filter-field"], "Thing*" )
      $driver.find_element(:css, ".sidebar input.text-filter-field + div button").click

      $driver.find_element_with_text('//tr', /Thing1/).find_element(:link, 'Edit').click

      $driver.find_element(:link, "Merge").click

      $driver.clear_and_send_keys([:id, "token-input-merge_ref_"], "Thing2" )
      $driver.find_element(:css, "li.token-input-dropdown-item2").click

      $driver.find_element(:css, "button.merge-button").click

      $driver.wait_for_ajax

      $driver.find_element_with_text("//h3", /Merge into this record\?/)
      $driver.find_element(:css, "button#confirmButton").click
    }

    $driver.wait_for_ajax

    expect {
      assert(10) {
        $driver.navigate.refresh
        $driver.find_element_with_text('//div[contains(@class, "alert-success")]', /Digital object\(s\) Merged/)
      }
    }.not_to raise_error
  end

end
