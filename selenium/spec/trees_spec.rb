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

    @driver.find_elements(:css => "li.jstree-node").length.should eq(4)

    @driver.find_element(:id, js_node(@a3).a_id).click
    @driver.wait_for_ajax

    @driver.click_and_wait_until_gone(:link, "Add Sibling")
    @driver.clear_and_send_keys([:id, "archival_object_title_"], "Sibling")
    @driver.find_element(:id, "archival_object_level_").select_option("item")
    @driver.click_and_wait_until_gone(:css, "form#archival_object_form button[type='submit']")

    @driver.wait_for_ajax

    @driver.find_elements(:css => "li.jstree-node").length.should eq(5)

    # reload the parent form to make sure the changes stuck
    @driver.get("#{$frontend}/#{@r.uri.sub(/\/repositories\/\d+/, '')}/edit")
    @driver.wait_for_ajax

    @driver.find_elements(:css => "li.jstree-node").length.should eq(5)
  end


  it "can support dnd: into a sibling archival object" do
    @driver.navigate.refresh
    # first resize the tree pane (do it incrementally so it doesn't flip out...)
    pane_resize_handle = @driver.find_element(:css => ".ui-resizable-handle.ui-resizable-s")
    10.times {
      @driver.action.drag_and_drop_by(pane_resize_handle, 0, 30).perform
    }

    source = @driver.find_element(:id, js_node(@a1).a_id)
    target = @driver.find_element(:id, js_node(@a2).a_id)

    y_off = target.location[:y] - source.location[:y]

    @driver.action.drag_and_drop_by(source, 0, y_off).perform
    @driver.wait_for_ajax
    @driver.wait_for_spinner


    target = @driver.find_element(:id, js_node(@a2).li_id)
    # now open the target
    3.times do
      begin
        target.find_element(:css => "i.jstree-icon").click
        target.find_element_orig(:css => "ul.jstree-children")
        break 
      rescue
        $stderr.puts "hmm...lets try and reopen the node"
        sleep(2)
        next
      end
    end
    # and find the former sibling
    target.find_element(:id, js_node(@a1).li_id)

    # refresh the page and verify that the change really stuck
    @driver.navigate.refresh


    # same check again
    @driver.find_element(:id, js_node(@a2).li_id)
      .find_element(:css => "i.jstree-icon").click
    # but this time wait for lazy loading and re-find the parent node
    @driver.wait_for_ajax
    target = @driver.find_element(:id, js_node(@a2).li_id)
    target.find_element(:id, js_node(@a1).li_id)

  end

  # TODO: review this test when things quiet down?
  it "can not reorder the tree while editing a node" do

    pane_resize_handle = @driver.find_element(:css => ".ui-resizable-handle.ui-resizable-s")
    10.times {
      @driver.action.drag_and_drop_by(pane_resize_handle, 0, 30).perform
    }

    @driver.find_element(:id, js_node(@a3).a_id).click
    @driver.wait_for_ajax

    @driver.clear_and_send_keys([:id, "archival_object_title_"], @a3.title.sub(/Archival Object/, "Resource Component"))

    moving = @driver.find_element(:id, js_node(@a3).li_id)
    target = @driver.find_element(:id, js_node(@a2).li_id)

    # now do a drag and drop
    @driver.action.drag_and_drop(moving, target).perform
    @driver.wait_for_ajax

    # save the item
    @driver.click_and_wait_until_gone(:css => "form#archival_object_form button[type='submit']")
    @driver.wait_for_ajax

    # open the node (maybe this should happen by default?)
    @driver.find_element(:id => js_node(@a2).li_id)
      .find_element(:css => "i.jstree-icon").click

    sleep(5)

    # we expect the move to have been rebuffed
    expect {
      @driver
          .find_element(:id => js_node(@a2).li_id)
          .find_element_orig(:id => js_node(@a3).li_id)
    }.to raise_error Selenium::WebDriver::Error::NoSuchElementError

    # if we refresh the parent should now be open
    @driver.navigate.refresh

    @driver
      .find_element(:id => js_node(@a3).li_id).find_element(:css => "span.title-column").text.should match(/Resource Component/)

  end

  it "can move tree nodes into and out of each other", :retry => 2, :retry_wait => 10 do

    # move siblings 2 and 3 into 1
    [@a2, @a3].each do |sibling|
      @driver.find_element(:id => js_node(sibling).a_id).click
      @driver.wait_for_ajax

      @driver.find_element(:link, "Move").click
      
      el = @driver.find_element_with_text("//a", /Down Into/)
      @driver.mouse.move_to el

      @driver.wait_for_ajax

      @driver.find_element(:css => "div.move-node-menu")
        .find_element(:xpath => ".//a[@data-target-node-id='#{js_node(@a1).li_id}']")
        .click

      @driver.wait_for_ajax
      @driver.wait_for_spinner
      sleep(2)
    end

    2.times {|i|
      @driver.find_element(:id => js_node(@a1).a_id).click
      @driver.wait_for_ajax
      # @driver.wait_for_spinner
      [@a2, @a3].each do |child|
        @driver.find_element(:id => js_node(@a1).li_id)
          .find_element(:id => js_node(child).li_id)
      end

      @driver.navigate.refresh if i == 0
    }

    # now move them back
    [@a2, @a3].each do |child|
      @driver.find_element(:id => js_node(child).a_id).click
      @driver.wait_for_ajax

      @driver.find_element(:link, "Move").click
      @driver.find_element_with_text("//a", /Up a Level/).click

      @driver.wait_for_ajax
      @driver.wait_for_spinner

      sleep(2)
    end


    2.times {|i|
      [@a2, @a3].each do |sibling|
        @driver.find_element(:id => js_node(sibling).li_id)
          .find_element(:xpath => "following-sibling::li[@id='#{js_node(@a1).li_id}']")
      end

      @driver.navigate.refresh if i == 0
    }

  end


  it "can delete a node and return to its parent" do
    @driver.find_element(:id => js_node(@a1).a_id).click
    @driver.wait_for_ajax

    @driver.find_element(:css, ".delete-record.btn").click
    @driver.find_element(:css, "#confirmChangesModal #confirmButton").click

    @driver.find_element(:id => js_node(@r).li_id).attribute("class").split(" ").should include('primary-selected')
  end


  it "can not reorder if logged in as a read only user" do
    @driver.login_to_repo(@viewer_user, @repo)
    @driver.get_view_page(@r)

    pane_resize_handle = @driver.find_element(:css => ".ui-resizable-handle.ui-resizable-s")
    10.times {
      @driver.action.drag_and_drop_by(pane_resize_handle, 0, 30).perform
    }

    moving = @driver.find_element(:id => js_node(@a1).li_id)
    target = @driver.find_element(:id => js_node(@a2).li_id)

    # now do a drag and drop
    @driver.action.drag_and_drop(moving, target).perform

    moving.find_elements(:xpath => "following-sibling::li").length.should eq(2)
    @driver.login_to_repo($admin, @repo)
  end

  it "can celebrate the birth of jesus christ our lord" do
    @driver.click_and_wait_until_gone(:link, "Add Child")
    @driver.clear_and_send_keys([:id, "archival_object_title_"], "Gifts")
    @driver.find_element(:id, "archival_object_level_").select_option("collection")
    @driver.click_and_wait_until_gone(:css, "form#archival_object_form button[type='submit']")

    # lets add some nodes
    first_born = nil
    ["Fruit Cake", "Ham", "Coca-cola bears"].each_with_index do |ao, i|
      
      unless first_born 
        # lets make a baby! 
        @driver.click_and_wait_until_gone(:link, "Add Child")
        first_born = ao 
      else
        # really?!? another one?!? 
        @driver.find_element_with_text("//div[@id='archives_tree']//a", /#{first_born}/).click
        @driver.click_and_wait_until_gone(:link, "Add Sibling")
      end

      @driver.clear_and_send_keys([:id, "archival_object_title_"], ao)
      @driver.find_element(:id, "archival_object_level_").select_option("item")
      @driver.click_and_wait_until_gone(:css, "form#archival_object_form button[type='submit']")
    end
      
    # open the tree a little
    dragger = @driver.find_element(:css => ".ui-resizable-handle.ui-resizable-s" )
    @driver.action.drag_and_drop_by(dragger, 0, 300).perform
    @driver.wait_for_ajax


    # now lets move and delete some nodes
    ["Ham", "Coca-cola bears"].each do |ao|
      target = @driver.find_element_with_text("//div[@id='archives_tree']//a", /Gifts/)
      source = @driver.find_element_with_text("//div[@id='archives_tree']//a", /#{ao}/)
      y_off = target.location[:y] - source.location[:y]
     
      @driver.action.drag_and_drop_by(source, 0, y_off - 10).perform
      @driver.wait_for_spinner
      @driver.wait_for_ajax

      @driver.find_element_with_text("//div[@id='archives_tree']//a", /#{ao}/).click
      @driver.find_element(:link, "Move").click
      @driver.find_element(:link, "Up").click
      @driver.wait_for_spinner
      @driver.wait_for_ajax
      
      @driver.find_element_with_text("//div", /Please click to load records/).click
      
      @driver.find_element(:css, ".alert-info").click
      @driver.wait_for_ajax
      
      @driver.find_element_with_text("//div[@id='archives_tree']//a", /Gifts/).click
      @driver.find_element_with_text("//div[@id='archives_tree']//a", /#{ao}/).click
      @driver.wait_for_ajax
     
      @driver.find_element(:css, ".delete-record.btn").click
      @driver.wait_for_ajax
      sleep(2) 

      @driver.find_element(:css, "#confirmChangesModal #confirmButton").click
      @driver.click_and_wait_until_gone(:link, "Edit")
      @driver.click_and_wait_until_gone(:css, "li.jstree-closed > i.jstree-icon")
    end
      
    @driver.find_element(:id, js_node(@r).li_id).click
    @driver.find_element_with_text("//div[@id='archives_tree']//a", /Gifts/).click
    @driver.click_and_wait_until_gone(:link, "Add Sibling")
    @driver.clear_and_send_keys([:id, "archival_object_title_"], "Nothing")
    @driver.find_element(:id, "archival_object_level_").select_option("item")
    @driver.click_and_wait_until_gone(:css, "form#archival_object_form button[type='submit']")


    # now lets add some more and move them around
    [ "Santa Crap", "Japanese KFC", "Kalle Anka"].each do |ao|
      @driver.wait_for_ajax
      @driver.find_element(:id, js_node(@r).li_id).click
      
      @driver.wait_for_ajax
      @driver.find_element_with_text("//div[@id='archives_tree']//a", /Gifts/).click
      @driver.wait_for_ajax
      sleep(2)    


      @driver.click_and_wait_until_gone(:link, "Add Sibling")
      @driver.clear_and_send_keys([:id, "archival_object_title_"], ao)
      @driver.find_element(:id, "archival_object_level_").select_option("item")
      @driver.click_and_wait_until_gone(:css, "form#archival_object_form button[type='submit']")

      target = @driver.find_element_with_text("//div[@id='archives_tree']//a", /Gifts/)
      source = @driver.find_element_with_text("//div[@id='archives_tree']//a", /#{ao}/)

      y_off = target.location[:y] - source.location[:y]
      @driver.action.drag_and_drop_by(source, 0, y_off).perform
      @driver.wait_for_ajax
      @driver.wait_for_spinner
    end
   
    wait = Selenium::WebDriver::Wait.new(:timeout => 40)
    @driver.find_element(:id, js_node(@r).li_id).click
    @driver.click_and_wait_until_gone(:link, 'Close Record')
    @driver.wait_for_ajax
    sleep(2) 
    
    
    # now lets add some notes
    [ "Japanese KFC", "Kalle Anka", "Santa Crap"].each do |ao|
      
      # sanity check to make sure we're editing..
      edit_btn = @driver.find_element_with_text("//div[@class='record-toolbar']/div/a",  /Edit/, true, true)

      if edit_btn
        @driver.click_and_wait_until_gone(:link, 'Edit')
      end
    
      @driver.find_element(:id, js_node(@r).li_id).click
      
      @driver.find_element_with_text("//div[@id='archives_tree']//a", /Gifts/).click
      @driver.click_and_wait_until_gone(:css, "a.refresh-tree")

      @driver.find_element_with_text("//div[@id='archives_tree']//a", /#{ao}/).click
      @driver.wait_for_ajax
      @driver.find_element_with_text("//button", /Add Note/).click
      # @driver.find_element(:css => '#notes .subrecord-form-heading .btn:not(.show-all)').click
      @driver.find_last_element(:css => '#notes select.top-level-note-type:last-of-type').select_option("note_multipart")
      @driver.clear_and_send_keys([:id, 'archival_object_notes__0__label_'], "A multipart note")
      @driver.execute_script("$('#archival_object_notes__0__subnotes__0__content_').data('CodeMirror').setValue('Some note content')")
      @driver.execute_script("$('#archival_object_notes__0__subnotes__0__content_').data('CodeMirror').save()")
      @driver.click_and_wait_until_gone(:css => "form#archival_object_form button[type='submit']")
      @driver.find_element(:link, 'Close Record').click
    end

    # everything should be in the order we want it...
    [ "Kalle Anka", "Japanese KFC","Santa Crap", "Fruit Cake" ].each_with_index do |ao, i|
      ao.delete!("1")
      assert(5) {
        @driver.find_element( :xpath => "//div[@id='archives_tree']//li[a/@title='Gifts']/ul/li[position() = #{i + 1}]/a/span/span[@class='title-column pull-left']").text.should match(/#{ao}/)
      }
    end
  end

  it "can make and mess with bigger trees" do

    # let's make some children
    children = []
    9.times { |i|  children << create(:archival_object, :title => i.to_s,  :resource => {:ref => @r.uri}, :parent => {:ref => @a1.uri}).uri  }
    @driver.navigate.refresh

    # go to the page..
    @driver.find_element( :xpath => "//a[@title='#{@a1.title}']").click
    @driver.wait_for_ajax

    # lets make the pane nice and big...
    last =  @driver.find_elements(:xpath => "//div[@id='archives_tree']//li[a/@title='#{@a1.title}']/ul/li/a").last
    first =  @driver.find_elements(:xpath => "//div[@id='archives_tree']//li[a/@title='#{@a1.title}']/ul/li/a").first
    pane_size = last.location[:y] - first.location[:y]
    pane_resize_handle = @driver.find_element(:css => ".ui-resizable-handle.ui-resizable-s")
    @driver.action.drag_and_drop_by(pane_resize_handle, 0, ( pane_size * 2 ) ).perform

    # we cycle these nodes around in a circle.
    3.times do
      a =  @driver.element_finder(:xpath => "//div[@id='archives_tree']//li[a/@title='#{@a1.title}']/ul/li[7]/a")
      b =  @driver.element_finder(:xpath => "//div[@id='archives_tree']//li[a/@title='#{@a1.title}']/ul/li[9]/a")
      target =  @driver.find_elements(
                 :xpath => "//div[@id='archives_tree']//li[a/@title='#{@a1.title}']/ul/li").first
      offset = ( ( target.location[:y] - a.call.location[:y] ) - 9 )
      a.call.click
      @driver.action.key_down(:shift).perform
      b.call.click
      @driver.action.key_up(:shift).perform
      @driver.action.drag_and_drop_by(a.call, 0, offset).perform

      @driver.wait_for_spinner
    end

    # everything should be normal
    (0..8).each do |i|
      assert(5) {
        @driver.find_element( :xpath => "//li[a/@title='#{@a1.title}']/ul/li[position() = #{i + 1}]/a/span/span[@class='title-column pull-left']").text.should match(/#{i.to_s}/)
      }
    end

    # now lets cycles in reverse
    3.times do
      a =  @driver.element_finder(:xpath => "//div[@id='archives_tree']//li[a/@title='#{@a1.title}']/ul/li[1]/a")
      b =  @driver.element_finder(:xpath => "//div[@id='archives_tree']//li[a/@title='#{@a1.title}']/ul/li[3]/a")
      target =  @driver.find_elements(
                 :xpath => "//div[@id='archives_tree']//li[a/@title='#{@a1.title}']/ul/li").last
      offset = ( ( target.location[:y] - a.call.location[:y] ) + 7 )
      # @driver.action.click(a).key_down(:shift).click(b).key_up(:shift).drag_and_drop_by(a, 0, offset).perform
      a.call.click
      @driver.action.key_down(:shift).perform
      b.call.click
      @driver.action.key_up(:shift).perform
      @driver.action.drag_and_drop_by(a.call, 0, offset).perform

      @driver.wait_for_spinner
    end

    # back to normal
    (0..8).each do |i|
      assert(5) {
        @driver.find_element( :xpath => "//li[a/@title='#{@a1.title}']/ul/li[position() = #{i + 1 }]/a/span/span[@class='title-column pull-left']").text.should match(/#{i.to_s}/)
      }
    end

    # now lets stick some in the middle
    2.times do
      a =  @driver.element_finder(:xpath => "//div[@id='archives_tree']//li[a/@title='#{@a1.title}']/ul/li[1]/a")
      b =  @driver.element_finder(:xpath => "//div[@id='archives_tree']//li[a/@title='#{@a1.title}']/ul/li[3]/a")
      target =  @driver.find_elements(
                 :xpath => "//div[@id='archives_tree']//li[a/@title='#{@a1.title}']/ul/li")[5]
      offset = ( ( target.location[:y] - a.call.location[:y] ) + 7 )
      a.call.click
      @driver.action.key_down(:shift).perform
      b.call.click
      @driver.action.key_up(:shift).perform
      @driver.action.drag_and_drop_by(a.call, 0, offset).perform

      @driver.wait_for_spinner
    end

    # and again back to normal
    (0..8).each do |i|
      assert(5) {
        @driver.find_element( :xpath => "//li[a/@title='#{@a1.title}']/ul/li[position() = #{i + 1}]/a/span/span[@class='title-column pull-left']").text.should match(/#{i.to_s}/)
      }
    end

    # and now let's move them up a level and do it all again...
    a =  @driver.find_elements(:xpath => "//div[@id='archives_tree']//li[a/@title='#{@a1.title}']/ul/li/a").first
    b =  @driver.find_elements(:xpath => "//div[@id='archives_tree']//li[a/@title='#{@a1.title}']/ul/li/a").last
    target =  @driver.find_element(
                 :xpath => "//div[@id='archives_tree']//li[a/@title='#{@a1.title}']")

    offset = ( ( target.location[:y] - a.location[:y] ) - 9 )
    @driver.action.click(a).key_down(:shift).click(b).key_up(:shift).drag_and_drop_by(a, 0, offset).perform #fails here
    @driver.wait_for_spinner

    # heres the new order of our AOs. all on one level
    new_order = (0..8).to_a + [ @a1.title, @a2.title, @a3.title ]

    # let's check that everything is as expected
    new_order.each_with_index do |v, i|
    assert(5) {
        @driver.find_element( :xpath => "//li[a/@title='#{@r.title}']/ul/li[position() = #{i + 1 }]/a/span/span[@class='title-column pull-left']").text.should match(/#{v}/)
      }
    end

    # let's cycle bottom to top
    4.times do
      new_order = new_order.pop(3) + new_order
      a =  @driver.find_elements(:xpath => "//li[a/@title='#{@r.title}']/ul/li/a")[-3]
      b =  @driver.find_elements(:xpath => "//li[a/@title='#{@r.title}']/ul/li/a").last
      target =  @driver.find_elements(
                 :xpath => "//li[a/@title='#{@r.title}']/ul/li").first
      offset = ( ( target.location[:y] - a.location[:y] ) - 9 )
      @driver.action.click(a).key_down(:shift).click(b).key_up(:shift).drag_and_drop_by(a, 0, offset).perform
      @driver.wait_for_spinner
      new_order.each_with_index do |v, i|
        assert(5) {
          @driver.find_element( :xpath => "//li[a/@title='#{@r.title}']/ul/li[position() = #{i + 1 }]/a/span/span[@class='title-column pull-left']").text.should match(/#{v}/)
         }
      end
    end

    # let's cycle top to bottom
    4.times do
      n = new_order.shift(3)
      new_order =  new_order + n
      a =  @driver.find_elements(:xpath => "//li[a/@title='#{@r.title}']/ul/li/a").first
      b =  @driver.find_elements(:xpath => "//li[a/@title='#{@r.title}']/ul/li/a")[2]
      target =  @driver.find_elements(
                 :xpath => "//li[a/@title='#{@r.title}']/ul/li").last
      offset = ( ( target.location[:y] - a.location[:y] ) + 9 )
      @driver.action.click(a).key_down(:shift).click(b).key_up(:shift).drag_and_drop_by(a, 0, offset).perform
      @driver.wait_for_spinner
      new_order.each_with_index do |v, i|
        assert(5) {
          @driver.find_element( :xpath => "//li[a/@title='#{@r.title}']/ul/li[position() = #{i + 1 }]/a/span/span[@class='title-column pull-left']").text.should match(/#{v}/)
         }
      end
    end

    # let's move top 3 into the middle and see if that works
    2.times do
      n = new_order.shift(3)
      new_order.insert(3, n).flatten!

      a =  @driver.find_elements(:xpath => "//li[a/@title='#{@r.title}']/ul/li/a").first
      b =  @driver.find_elements(:xpath => "//li[a/@title='#{@r.title}']/ul/li/a")[2]
      target =  @driver.find_elements(
                 :xpath => "//li[a/@title='#{@r.title}']/ul/li")[5]
      offset = ( ( target.location[:y] - a.location[:y] ) + 7 )
      @driver.action.click(a).key_down(:shift).click(b).key_up(:shift).drag_and_drop_by(a, 0, offset).perform
      @driver.wait_for_spinner
      new_order.each_with_index do |v, i|
        assert(5) {
          @driver.find_element( :xpath => "//li[a/@title='#{@r.title}']/ul/li[position() = #{i + 1 }]/a/span/span[@class='title-column pull-left']").text.should match(/#{v}/)
         }
      end
    end


  end


end
