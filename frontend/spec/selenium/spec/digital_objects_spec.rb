# frozen_string_literal: true

require_relative '../spec_helper'

describe 'Digital Objects' do
  before(:all) do
    @repo = create(:repo, repo_code: "do_test_#{Time.now.to_i}")
    set_repo @repo

    @do = create(:digital_object)
    @cl = create(:classification)

    @alt_do_title = 'File version alt text test'
    @alt_doc_title = 'Child of file version alt text test'
    alt_uri = 'https://www.archivesspace.org/demos/Congreave%20E-2/ms292_003_page002.jpg'
    alt_format = 'jpeg'
    @alt_caption = 'This is the caption'

    @alt_do = create(
      :digital_object,
      title: @alt_do_title,
      file_versions: [
        {
          file_uri: alt_uri,
          file_format_name: alt_format,
          caption: @alt_caption
        },
        {
          file_uri: alt_uri,
          file_format_name: alt_format
        }
      ]
    )
    @alt_doc = create(
      :digital_object_component,
      digital_object: { ref: @alt_do.uri },
      title: @alt_doc_title,
      file_versions: [
        {
          file_uri: alt_uri,
          file_format_name: alt_format,
          caption: @alt_caption
        },
        {
          file_uri: alt_uri,
          file_format_name: alt_format
        }
      ]
    )

    run_all_indexers

    @do_child1 = create(:digital_object_component, digital_object: { ref: @do.uri })
    @do_child2 = create(:digital_object_component, digital_object: { ref: @do.uri })

    @do2 = create(:digital_object)

    user = create_user(@repo => ['repository-archivists'])
    @driver = Driver.get.login_to_repo(user, @repo)
  end

  after(:all) do
    @driver ? @driver.quit : next
  end

  it 'reports errors and warnings when creating an invalid Digital Object' do
    @driver.find_element(:link, 'Create').click
    @driver.click_and_wait_until_gone(:link, 'Digital Object')
    @driver.find_hidden_element(:css, '#digital_object_title_').wait_for_class('initialised')
    @driver.execute_script("$('#digital_object_title_').data('CodeMirror').setValue('')")

    @driver.click_and_wait_until_gone(css: "form#new_digital_object button[type='submit']")

    @driver.find_element_with_text('//div[contains(@class, "error")]', /Identifier - Property is required but was missing/)

    # cancel those changes (shows a new form)
    @driver.click_and_wait_until_gone(:css, 'a.btn.btn-cancel')

    # and jump back home so we can start again
    @driver.go_home
  end

  digital_object_title = 'Pony Express Digital Image'

  it 'can create a digital_object with one file version' do
    @driver.find_element(:link, 'Create').click
    @driver.click_and_wait_until_gone(:link, 'Digital Object')

    @driver.find_hidden_element(:css, '#digital_object_title_').wait_for_class('initialised')
    @driver.execute_script("$('#digital_object_title_').data('CodeMirror').setValue('#{digital_object_title}')")

    @driver.clear_and_send_keys([:id, 'digital_object_digital_object_id_'], Digest::MD5.hexdigest(Time.now.to_s))

    @driver.find_element(id: 'digital_object_digital_object_type_').select_option_with_text('Mixed Materials')

    @driver.find_element(css: 'section#digital_object_file_versions_ > h3 > .btn:not(.show-all)').click

    @driver.clear_and_send_keys([:id, 'digital_object_file_versions__0__file_uri_'], '/uri/for/this/file/version')
    @driver.clear_and_send_keys([:id, 'digital_object_file_versions__0__file_size_bytes_'], '100')

    @driver.click_and_wait_until_gone(css: "form#new_digital_object button[type='submit']")

    # The new Digital Object shows up on the tree
    expect(@driver.find_element(css: '.table-row.root-row .title').text.strip).to match(/#{digital_object_title}/)
  end

  it 'can handle multiple file versions and file system and network path types' do
    [
      '/root/top_secret.txt',
      'C:\Program Files\windows.exe',
      '\\\\SomeAwesome\Network\location.bat'
    ].each_with_index do |uri, idx|
      i = idx + 1
      @driver.find_element(css: 'section#digital_object_file_versions_ > h3 > .btn:not(.show-all)').click
      @driver.clear_and_send_keys([:id, "digital_object_file_versions__#{i}__file_uri_"], uri)
      @driver.click_and_wait_until_gone(css: ".form-actions button[type='submit']")
    end
    @driver.find_element(:link, 'Close Record').click
    @driver.find_element_with_text('//h3', /File Versions/)
    @driver.click_and_wait_until_gone(:link, 'Edit')
  end

  it "make representative is disabled unless published is checked, and vice versa" do
    @driver.find_element(:link, 'Create').click
    @driver.click_and_wait_until_gone(:link, 'Digital Object')

    @driver.find_hidden_element(:css, '#digital_object_title_').wait_for_class('initialised')
    @driver.execute_script("$('#digital_object_title_').data('CodeMirror').setValue('#{digital_object_title}')")

    @driver.clear_and_send_keys([:id, 'digital_object_digital_object_id_'], Digest::MD5.hexdigest(Time.now.to_s))

    @driver.find_element(id: 'digital_object_digital_object_type_').select_option_with_text('Mixed Materials')

    @driver.find_element(css: 'section#digital_object_file_versions_ > h3 > .btn:not(.show-all)').click

    @driver.clear_and_send_keys([:id, 'digital_object_file_versions__0__file_uri_'], '/uri/for/this/file/version')
    @driver.clear_and_send_keys([:id, 'digital_object_file_versions__0__file_size_bytes_'], '100')

    @driver.click_and_wait_until_gone(css: "form#new_digital_object button[type='submit']")

    # make sure is representative is disabled with publish is unchecked
    is_rep_button = @driver.find_element(css: '.is-representative-toggle')
    expect(is_rep_button.attribute('disabled')).to eq("true")

    # make sure is representative is enabled when publish is checked
    @driver.find_element(css: '.js-file-version-publish').click
    expect(is_rep_button.attribute('disabled')).to be_nil
  end

  it 'reports errors if adding a child with no title to a Digital Object' do
    @driver.get_edit_page(@do2)
    @driver.find_element(:link, 'Add Child').click
    @driver.wait_for_ajax
    @driver.find_element(:id, 'digital_object_component_component_id_')

    @driver.clear_and_send_keys([:id, 'digital_object_component_component_id_'], '123')
    sleep(2)

    # False start: create an object without filling it out
    @driver.click_and_wait_until_gone(id: 'createPlusOne')
    @driver.find_element_with_text('//div[contains(@class, "error")]', /you must provide/)

    @driver.click_and_wait_until_gone(:css, 'a.btn.btn-cancel')
  end

  # Digital Object Component Nodes in Tree

  it 'can populate the digital object component tree' do
    @driver.get_edit_page(@do2)
    @driver.find_element(:link, 'Add Child').click
    @driver.wait_for_ajax
    @driver.find_element(:id, 'digital_object_component_component_id_')

    @driver.find_hidden_element(:css, '#digital_object_component_title_').wait_for_class('initialised')
    @driver.execute_script("$('#digital_object_component_title_').data('CodeMirror').setValue('JPEG 2000 Verson of Image')")

    @driver.clear_and_send_keys([:id, 'digital_object_component_component_id_'], Digest::MD5.hexdigest(Time.now.to_s))

    @driver.click_and_wait_until_gone(id: 'createPlusOne')

    ['PNG format', 'GIF format', 'BMP format'].each_with_index do |thing, idx|
      sleep 5
      @driver.find_hidden_element(:css, '#digital_object_component_title_').wait_for_class('initialised')
      @driver.execute_script("$('#digital_object_component_title_').data('CodeMirror').setValue('#{thing}')")
      @driver.clear_and_send_keys([:id, 'digital_object_component_label_'], thing)
      @driver.clear_and_send_keys([:id, 'digital_object_component_component_id_'], Digest::MD5.hexdigest("#{thing}#{Time.now}"))

      @driver.find_element(css: 'section#digital_object_component_file_versions_ > h3 > .btn:not(.show-all)').click
      @driver.clear_and_send_keys([:id, 'digital_object_component_file_versions__0__file_uri_'], '/uri/for/this/file/version')

      if idx < 2
        @driver.click_and_wait_until_gone(id: 'createPlusOne')
      else
        @driver.click_and_wait_until_gone(css: "form#new_digital_object_component button[type='submit']")
      end
    end

    elements = @driver.blocking_find_elements(css: '.largetree-node.indent-level-1').map { |li| li.text.strip }

    ['PNG format', 'GIF format', 'BMP format'].each do |thing|
      expect(elements.any? { |elt| elt =~ /#{thing}/ }).to be_truthy
    end
  end

  it 'can drag and drop reorder a Digital Object' do
    @driver.get_edit_page(@do_child1)
    @driver.wait_for_ajax

    child = @driver.find_element(:id, "digital_object_component_#{@do_child1.id}")
    expect(child.attribute('class')).to include('current')

    # create grand child
    tree_add_child

    child_title = 'ICO'
    @driver.find_hidden_element(:css, '#digital_object_component_title_').wait_for_class('initialised')
    @driver.execute_script("$('#digital_object_component_title_').data('CodeMirror').setValue('#{child_title}')")

    @driver.clear_and_send_keys([:id, 'digital_object_component_component_id_'], Digest::MD5.hexdigest(Time.now.to_s))

    @driver.click_and_wait_until_gone(css: "form#new_digital_object_component button[type='submit']")
    @driver.wait_for_ajax

    expand_tree_pane
    root = tree_node_for_title(@do.title)
    expect(root.attribute('class')).to include('root-row')
    child = @driver.find_element(:id, "digital_object_component_#{@do_child1.id}")
    expect(child.attribute('class')).to include('indent-level-1')
    grand_child = tree_node_for_title(child_title)
    expect(grand_child.attribute('class')).to include('indent-level-2')

    tree_drag_and_drop(grand_child, root, 'into')

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

  it 'can link a classification to digital object' do
    @driver.get_edit_page(@do2)
    @driver.find_element(css: '#digital_object_classifications_ button').click
    token_input = @driver.find_element(:id, 'token-input-digital_object_classifications__0__ref_')
    @driver.typeahead_and_select(token_input, @cl.title)
    @driver.click_and_wait_until_gone(css: "form .record-pane button[type='submit']")
    @driver.find_element(css: '#digital_object_classifications__0_')
  end

  it 'provides alt text for Digital Object file version images based on caption or title' do
    @driver.get_view_page(@alt_do)
    expect(@driver.find_hidden_element(css: "section#digital_object_file_versions_ #digital_object_file_versions__file_version_0 img[alt='#{@alt_caption}']"))
    expect(@driver.find_hidden_element(css: "section#digital_object_file_versions_ #digital_object_file_versions__file_version_1 img[alt='#{@alt_do_title}']"))
  end

  it 'provides alt text for Digital Object Component file version images based on caption or title' do
    @driver.get_view_page(@alt_doc)
    expect(@driver.find_hidden_element(css: "section#digital_object_component_file_versions_ #digital_object_component_file_versions__file_version_0 img[alt='#{@alt_caption}']"))
    expect(@driver.find_hidden_element(css: "section#digital_object_component_file_versions_ #digital_object_component_file_versions__file_version_1 img[alt='#{@alt_doc_title}']"))
  end

end
