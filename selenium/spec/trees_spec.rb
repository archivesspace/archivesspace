require_relative 'spec_helper'

describe "Tree UI" do

  before(:all) do
    backend_login

    @repo = create(:repo)
    set_repo(@repo.uri)

    (@viewer_user, @viewer_pass) = create_user
    add_user_to_viewers(@viewer_user, @repo.uri)
  end

  before(:each) do

    @r = create(:resource)
    @a1 = create(:archival_object, {:resource => {:ref => @r.uri}})
    @a2 = create(:archival_object, {:resource => {:ref => @r.uri}})
    @a3 = create(:archival_object, {:resource => {:ref => @r.uri}})

    login("admin", "admin")
    select_repo(@repo.repo_code)

    $driver.get("#{$frontend}#{@r.uri.sub(/\/repositories\/\d+/, '')}/edit")
    $driver.wait_for_ajax
  end


  after(:each) do
    logout
  end


  it "can add a sibling" do

    $driver.find_elements(:css => "li.jstree-node").length.should eq(4)

    $driver.find_element(:id, js_node(@a3).a_id).click
    $driver.wait_for_ajax

    $driver.click_and_wait_until_gone(:link, "Add Sibling")
    $driver.clear_and_send_keys([:id, "archival_object_title_"], "Sibling")
    $driver.find_element(:id, "archival_object_level_").select_option("item")
    $driver.click_and_wait_until_gone(:css, "form#archival_object_form button[type='submit']")

    $driver.wait_for_ajax

    $driver.find_elements(:css => "li.jstree-node").length.should eq(5)

    # reload the parent form to make sure the changes stuck
    $driver.get("#{$frontend}/#{@r.uri.sub(/\/repositories\/\d+/, '')}/edit")
    $driver.wait_for_ajax

    $driver.find_elements(:css => "li.jstree-node").length.should eq(5)
  end


  it "can support dnd: into a sibling archival object" do
    $driver.navigate.refresh
    # first resize the tree pane (do it incrementally so it doesn't flip out...)
    pane_resize_handle = $driver.find_element(:css => ".ui-resizable-handle.ui-resizable-s")
    10.times {
      $driver.action.drag_and_drop_by(pane_resize_handle, 0, 30).perform
    }

    source = $driver.find_element(:id, js_node(@a1).a_id)
    target = $driver.find_element(:id, js_node(@a2).a_id)

    y_off = target.location[:y] - source.location[:y]

    $driver.action.drag_and_drop_by(source, 0, y_off).perform
    $driver.wait_for_ajax


    target = $driver.find_element(:id, js_node(@a2).li_id)
    # now open the target
    target.find_element(:css => "i.jstree-icon").click
    # and find the former sibling
    target.find_element(:id, js_node(@a1).li_id)

    # refresh the page and verify that the change really stuck
    $driver.navigate.refresh


    # same check again
    $driver.find_element(:id, js_node(@a2).li_id)
      .find_element(:css => "i.jstree-icon").click
    # but this time wait for lazy loading and re-find the parent node
    $driver.wait_for_ajax
    target = $driver.find_element(:id, js_node(@a2).li_id)
    target.find_element(:id, js_node(@a1).li_id)

  end


  it "can reorder the tree while editing a node" do

    pane_resize_handle = $driver.find_element(:css => ".ui-resizable-handle.ui-resizable-s")
    10.times {
      $driver.action.drag_and_drop_by(pane_resize_handle, 0, 30).perform
    }

    $driver.find_element(:id, js_node(@a3).a_id).click
    $driver.wait_for_ajax

    $driver.clear_and_send_keys([:id, "archival_object_title_"], @a3.title.sub(/Archival Object/, "Resource Component"))

    moving = $driver.find_element(:id, js_node(@a3).li_id)
    target = $driver.find_element(:id, js_node(@a2).li_id)

    # now do a drag and drop
    $driver.action.drag_and_drop(moving, target).perform
    $driver.wait_for_ajax

    # save the item
    $driver.click_and_wait_until_gone(:css => "form#archival_object_form button[type='submit']")
    $driver.wait_for_ajax

    # open the node (maybe this should happen by default?)
    $driver.find_element(:id => js_node(@a2).li_id)
      .find_element(:css => "i.jstree-icon").click
    sleep(5)

    $driver
      .find_element(:id => js_node(@a2).li_id)
      .find_element(:id => js_node(@a3).li_id).find_element(:css => "span.title-column").text.should match(/Resource Component/)

    # if we refresh the parent should now be open
    $driver.navigate.refresh
    $driver
      .find_element(:id => js_node(@a2).li_id)
      .find_element(:id => js_node(@a3).li_id).find_element(:css => "span.title-column").text.should match(/Resource Component/)

  end

  it "can move tree nodes into and out of each other" do
    # move siblings 2 and 3 into 1
    [@a2, @a3].each do |sibling|
      $driver.find_element(:id => js_node(sibling).a_id).click
      $driver.wait_for_ajax

      $driver.find_element(:link, "Move").click
      $driver.find_element_with_text("//a", /Down Into/).click

      $driver.find_element(:css => "div.move-node-menu")
        .find_element(:xpath => ".//a[@data-target-node-id='#{js_node(@a1).li_id}']")
        .click

      $driver.wait_for_ajax
    end

    2.times {|i|
      $driver.find_element(:id => js_node(@a1).a_id).click
      $driver.wait_for_ajax

      [@a2, @a3].each do |child|
        $driver.find_element(:id => js_node(@a1).li_id)
          .find_element(:id => js_node(child).li_id)
      end

      $driver.navigate.refresh if i == 0
    }

    # now move them back
    [@a2, @a3].each do |child|
      $driver.find_element(:id => js_node(child).a_id).click
      $driver.wait_for_ajax

      $driver.find_element(:link, "Move").click
      $driver.find_element_with_text("//a", /Up a Level/).click

      $driver.wait_for_ajax
    end


    2.times {|i|
      [@a2, @a3].each do |sibling|
        $driver.find_element(:id => js_node(sibling).li_id)
          .find_element(:xpath => "following-sibling::li[@id='#{js_node(@a1).li_id}']")
      end

      $driver.navigate.refresh if i == 0
    }

  end


  it "can delete a node and return to its parent" do
    $driver.find_element(:id => js_node(@a1).a_id).click
    $driver.wait_for_ajax

    $driver.find_element(:css, ".delete-record.btn").click
    $driver.find_element(:css, "#confirmChangesModal #confirmButton").click

    $driver.find_element(:id => js_node(@r).li_id).attribute("class").split(" ").should include('primary-selected')
  end


  it "can not reorder if logged in as a read only user" do

    # go to the resource view page
    url = "#{$frontend}#{@r.uri.sub(/\/repositories\/\d+/, '')}"

    logout
    login(@viewer_user, @viewer_pass) #actually doesn't matter
    select_repo(@repo.repo_code)

    $driver.get(url)

    pane_resize_handle = $driver.find_element(:css => ".ui-resizable-handle.ui-resizable-s")
    10.times {
      $driver.action.drag_and_drop_by(pane_resize_handle, 0, 30).perform
    }

    moving = $driver.find_element(:id => js_node(@a1).li_id)
    target = $driver.find_element(:id => js_node(@a2).li_id)

    # now do a drag and drop
    $driver.action.drag_and_drop(moving, target).perform

    moving.find_elements(:xpath => "following-sibling::li").length.should eq(2)
  end

  it "can celebrate the birth of jesus christ our lord" do
    resource_url = $driver.current_url

    $driver.click_and_wait_until_gone(:link, "Add Child")
    $driver.clear_and_send_keys([:id, "archival_object_title_"], "Gifts")
    $driver.find_element(:id, "archival_object_level_").select_option("collection")
    $driver.click_and_wait_until_gone(:css, "form#archival_object_form button[type='submit']")

    # lets add some nodes
    ["Fruit Cake", "Ham", "Coca-cola bears"].each_with_index do |ao, i|

      $driver.click_and_wait_until_gone(:link, "Add #{i == 0 ? 'Child' : 'Sibling'}")
      $driver.clear_and_send_keys([:id, "archival_object_title_"], ao)
      $driver.find_element(:id, "archival_object_level_").select_option("item")
      $driver.click_and_wait_until_gone(:css, "form#archival_object_form button[type='submit']")
    end


    # now lets move and delete some nodes
    ["Ham", "Coca-cola bears"].each do |ao|
      # open the tree a little
      dragger = $driver.find_element(:css => ".ui-resizable-handle.ui-resizable-s" )
      $driver.action.drag_and_drop_by(dragger, 0, 100).perform
      $driver.wait_for_ajax

      target = $driver.find_element_with_text("//div[@id='archives_tree']//a", /Gifts/)
      source = $driver.find_element_with_text("//div[@id='archives_tree']//a", /#{ao}/)
      y_off = target.location[:y] - source.location[:y]
      $driver.action.drag_and_drop_by(source, 0, y_off - 10).perform
      $driver.wait_for_ajax
      sleep(5)

      $driver.wait_for_ajax
      $driver.find_element_with_text("//div[@id='archives_tree']//a", /#{ao}/).click
      $driver.find_element(:link, "Move").click
      $driver.find_element(:link, "Up").click
      $driver.wait_for_ajax
      sleep(5)

      $driver.find_element(:css, ".delete-record.btn").click
      $driver.find_element(:css, "#confirmChangesModal #confirmButton").click
      $driver.click_and_wait_until_gone(:link, "Edit")
      $driver.click_and_wait_until_gone(:css, "li.jstree-closed > i.jstree-icon")
    end


    # now lets add some more and move them around
    [ "Santa Crap", "Japanese KFC", "Kalle Anka"].each do |ao|
      $driver.find_element_with_text("//div[@id='archives_tree']//a", /Gifts/).click
      $driver.click_and_wait_until_gone(:link, "Add Sibling")
      $driver.clear_and_send_keys([:id, "archival_object_title_"], ao)
      $driver.find_element(:id, "archival_object_level_").select_option("item")
      $driver.click_and_wait_until_gone(:css, "form#archival_object_form button[type='submit']")

      target = $driver.find_element_with_text("//div[@id='archives_tree']//a", /Gifts/)
      source = $driver.find_element_with_text("//div[@id='archives_tree']//a", /#{ao}/)

      y_off = target.location[:y] - source.location[:y]
      $driver.action.drag_and_drop_by(source, 0, y_off).perform
      $driver.wait_for_ajax
    end

    $driver.click_and_wait_until_gone(:link, 'Close Record')

    # now lets add some notes
    [ "Santa Crap", "Japanese KFC", "Kalle Anka"].each do |ao|
      sleep(10)
      $driver.find_element_with_text("//div[@id='archives_tree']//a", /#{ao}/).click
      # sanity check to make sure we're editing..
      edit_btn = $driver.find_element_with_text("//div[@class='record-toolbar']/div/a",  /Edit/, true, true)

      if edit_btn
        $driver.click_and_wait_until_gone(:link, 'Edit')
      end
      $driver.wait_for_ajax
      $driver.find_element_with_text("//button", /Add Note/).click
      # $driver.find_element(:css => '#notes .subrecord-form-heading .btn:not(.show-all)').click
      $driver.find_last_element(:css => '#notes select.top-level-note-type:last-of-type').select_option("note_multipart")
      $driver.clear_and_send_keys([:id, 'archival_object_notes__0__label_'], "A multipart note")
      $driver.execute_script("$('#archival_object_notes__0__subnotes__0__content_').data('CodeMirror').setValue('Some note content')")
      $driver.execute_script("$('#archival_object_notes__0__subnotes__0__content_').data('CodeMirror').save()")
      $driver.click_and_wait_until_gone(:css => "form#archival_object_form button[type='submit']")
      $driver.find_element(:link, 'Close Record').click
    end

    # everything should be in the order we want it...
    [ "Santa Crap", "Japanese KFC","Kalle Anka", "Fruit Cake" ].each_with_index do |ao, i|
      assert(5) {
        $driver.find_element( :xpath => "//div[@id='archives_tree']//li[a/@title='Gifts']/ul/li[position() = #{i + 1}]/a/span/span[@class='title-column pull-left']").text.should eq(ao)
      }
    end
  end
end
