# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Digital Objects', js: true do
  let(:admin_user) { BackendClientMethods::ASpaceUser.new('admin', 'admin') }

  before(:all) do
    @repository = create(:repo, repo_code: "digital_objects_test_#{Time.now.to_i}")
    set_repo @repository

    @user = create_user(@repository => ['repository-archivists'])
  end

  before(:each) do
    login_user(@user)
    select_repository(@repository)
  end

  it 'reports errors and warnings when creating an invalid Digital Object' do
    now = Time.now.to_i

    click_on 'Create'
    click_on 'Digital Object'
    element = find('h2')
    expect(element.text).to eq 'New Digital Object Digital Object'

    # Click on save
    find('button', text: 'Save Digital Object', match: :first).click

    element = find('.alert.alert-danger.with-hide-alert')
    expect(element.text).to eq "Title - Property is required but was missing\nIdentifier - Property is required but was missing"
  end

  it 'can handle multiple file versions and file system and network path types' do
    now = Time.now.to_i

    click_on 'Create'
    click_on 'Digital Object'
    element = find('h2')
    expect(element.text).to eq 'New Digital Object Digital Object'

    fill_in 'digital_object_title_', with: "Digital Object Title #{now}"
    fill_in 'digital_object_digital_object_id_', with: "Digital Object Identifier #{now}"
    select 'Mixed Materials', from: 'digital_object_digital_object_type_'

    find('button', text: 'Add File Version', match: :first).click
    fill_in 'digital_object_file_versions__0__file_uri_', with: '/root/top_secret.txt'
    element = find('#digital_object_file_versions__0__file_size_bytes_')
    element.fill_in with: '100'

    find('button', text: 'Add File Version', match: :first).click
    fill_in 'digital_object_file_versions__1__file_uri_', with: 'C:\Program Files\windows.exe'
    element = find('#digital_object_file_versions__1__file_size_bytes_')
    element.fill_in with: '200'

    find('button', text: 'Add File Version', match: :first).click
    fill_in 'digital_object_file_versions__2__file_uri_', with: '\\\\NetworkPath\Network\location.bat'
    element = find('#digital_object_file_versions__2__file_size_bytes_')
    element.fill_in with: '300'

    # Click on save
    element = find('button', text: 'Save Digital Object', match: :first).click

    while true do
      sleep 1
      break if page.evaluate_script('jQuery.active') == 0
    end

    element = find('.alert.alert-success.with-hide-alert')
    expect(element.text).to eq "Digital Object Digital Object Title #{now} Created"

    click_on 'Close Record'

    element = find('h2')
    expect(element.text).to eq "Digital Object Title #{now} Digital Object"
    expect(page).to have_css 'h3', text: 'File Versions'
    elements = all('#digital_object_file_versions__accordion .row')
    expect(elements.length).to eq 3

    expect(elements[0]).to have_text '/root/top_secret.txt'
    expect(elements[1]).to have_text 'C:\Program Files\windows.exe'
    expect(elements[2]).to have_text '\\\\NetworkPath\Network\location.bat'
  end

  it "make representative is disabled unless published is checked, and vice versa" do
    now = Time.now.to_i

    click_on 'Create'
    click_on 'Digital Object'
    element = find('h2')
    expect(element.text).to eq 'New Digital Object Digital Object'

    fill_in 'digital_object_title_', with: "Digital Object Title #{now}"
    fill_in 'digital_object_digital_object_id_', with: "Digital Object Identifier #{now}"
    select 'Mixed Materials', from: 'digital_object_digital_object_type_'

    click_on 'Add File Version'
    fill_in 'digital_object_file_versions__0__file_uri_', with: "File Version URI #{now}"
    element = find('#digital_object_file_versions__0__file_size_bytes_')
    element.fill_in with: '100'

    # Click on save
    element = find('button', text: 'Save Digital Object', match: :first).click
    element = find('.alert.alert-success.with-hide-alert')
    expect(element.text).to eq "Digital Object Digital Object Title #{now} Created"

    within '#digital_object_file_versions__0_' do
      expect(page).to have_button('Make Representative', disabled: true)
      find('#digital_object_file_versions__0__publish_').click
      expect(page).to have_button('Make Representative', disabled: false)
    end
  end

  it 'reports errors if adding a child with no title to a Digital Object' do
    now = Time.now.to_i
    digital_object = create(:digital_object, title: "Digital Object Title #{now}")
    run_index_round

    visit "digital_objects/#{digital_object.id}/edit"

    click_on 'Add Child'

    while true do
      sleep 1
      break if page.evaluate_script('jQuery.active') == 0
    end

    element = find('h2')
    expect(element.text).to eq "Digital Object Component Digital Object Component"

    fill_in 'digital_object_component_component_id_', with: "Digital Object Identifier #{now}"

    find('#createPlusOne').click

    element = find('.alert.alert-danger.with-hide-alert')
    expect(element.text).to eq "Dates - you must provide a Label, Title or Date\nTitle - you must provide a Label, Title or Date\nLabel - you must provide a Label, Title or Date"
  end

  it 'can populate the digital object component tree' do
    now = Time.now.to_i
    digital_object = create(:digital_object, title: "Digital Object Title #{now}", dates: [], extents: [])
    run_index_round

    visit "digital_objects/#{digital_object.id}/edit"

    click_on 'Add Child'

    fill_in 'digital_object_component_component_id_', with: "Child 1 #{now}"
    fill_in 'digital_object_component_title_', with: "Child 1 #{now}"

    find('#createPlusOne').click
    while true do
      sleep 1
      break if page.evaluate_script('jQuery.active') == 0
    end
    element = find('.alert.alert-success.with-hide-alert')
    expect(element.text).to eq "Digital Object Component Child 1 #{now} created on Digital Object Digital Object Title #{now}"

    fill_in 'digital_object_component_component_id_', with: "Child 2 #{now}"
    fill_in 'digital_object_component_title_', with: "Child 2 #{now}"

    find('#createPlusOne').click
    while true do
      sleep 1
      break if page.evaluate_script('jQuery.active') == 0
    end
    element = find('.alert.alert-success.with-hide-alert')
    expect(element.text).to eq "Digital Object Component Child 2 #{now} created on Digital Object Digital Object Title #{now}"

    fill_in 'digital_object_component_component_id_', with: "Child 3 #{now}"
    fill_in 'digital_object_component_title_', with: "Child 3 #{now}"

    # Click on save
    find('button', text: 'Save Digital Object', match: :first).click
    while true do
      sleep 1
      break if page.evaluate_script('jQuery.active') == 0
    end
    element = find('.alert.alert-success.with-hide-alert')
    expect(element.text).to eq "Digital Object Component Child 3 #{now} created on Digital Object Digital Object Title #{now}"

    elements = all('.largetree-node.indent-level-1')
    expect(elements.length).to eq 3
    expect(elements[0]).to have_text "Child 1 #{now}"
    expect(elements[1]).to have_text "Child 2 #{now}"
    expect(elements[2]).to have_text "Child 3 #{now}"
  end

  it 'can drag and drop reorder a Digital Object' do
    now = Time.now.to_i
    digital_object = create(:digital_object, title: "Digital Object Title #{now}")
    digital_object_child = create(:digital_object_component, title: "Child #{now}", digital_object: { ref: digital_object.uri })
    run_index_round

    visit "digital_objects/#{digital_object.id}/edit"
    click_on "Child #{now}"

    click_on 'Add Child'
    while true do
      sleep 1
      break if page.evaluate_script('jQuery.active') == 0
    end
    fill_in 'digital_object_component_title_', with: "Sub-Child #{now}"
    fill_in 'digital_object_component_component_id_', with: "Sub-Child #{now}"

    # Click on save
    find('button', text: 'Save Digital Object', match: :first).click

    while true do
      sleep 1
      break if page.evaluate_script('jQuery.active') == 0
    end
    element = find('.alert.alert-success.with-hide-alert')
    expect(element.text).to eq "Digital Object Component Sub-Child #{now} created as child of Child #{now} on Digital Object Digital Object Title #{now}"

    find('button.tree-resize-toggle').click

    root_node = find("#digital_object_#{digital_object.id}")
    child_node = find("#digital_object_component_#{digital_object_child.id}.table-row.largetree-node.indent-level-1")
    expect(child_node).to have_text "Child #{now}"
    sub_child_node = find('.table-row.largetree-node.indent-level-2.current')
    expect(sub_child_node).to have_text "Sub-Child #{now}"

    click_on 'Enable Reorder Mode'
    sub_child_node.drag_to root_node

    root_node = find("#digital_object_#{digital_object.id}")
    child_node = find("#digital_object_component_#{digital_object_child.id}.table-row.largetree-node.indent-level-1")
    expect(child_node).to have_text "Child #{now}"
    sub_child_node = find('.table-row.largetree-node.indent-level-1.current')
    expect(sub_child_node).to have_text "Sub-Child #{now}"

    visit "digital_objects/#{digital_object.id}/edit"

    root_node = find("#digital_object_#{digital_object.id}")
    expect(root_node).to have_text "Digital Object Title #{now}"

    elements = all('.table-row.largetree-node.indent-level-1')
    expect(elements.length).to eq 2
    expect(elements[0]).to have_text "Sub-Child #{now}"
    expect(elements[1]).to have_text "Child #{now}"
  end

  it 'can link a classification to digital object' do
    now = Time.now.to_i
    digital_object = create(:digital_object, title: "Digital Object Title #{now}", dates: [], extents: [])
    classification = create(:classification)
    run_index_round

    visit "digital_objects/#{digital_object.id}/edit"

    click_on 'Add Classification'

    fill_in 'token-input-digital_object_classifications__0__ref_', with: classification.title
    dropdown_items = all('li.token-input-dropdown-item2')
    dropdown_items.first.click

    # Click on save
    find('button', text: 'Save Digital Object', match: :first).click
    element = find('.alert.alert-success.with-hide-alert')
    expect(element.text).to eq "Digital Object Digital Object Title #{now} Updated"

    element = find('#digital_object_classifications__0_')
    expect(element).to have_text classification.title
  end

  xit 'provides alt text for Digital Object file version images based on caption or title' do
    # TODO: not sure yet on this one
    now = Time.now.to_i
    digital_object = create(
      :digital_object,
      title: "Digital Object Title #{now}",
      file_versions: [
        {
          file_uri: "File URI 1 #{now}",
          file_format_name: "jpeg",
          caption: "File Format Caption 1 #{now}"
        },
        {
          file_uri: "File URI 2 #{now}",
          file_format_name: "jpeg",
          caption: "File Format Caption 2 #{now}"
        }
      ]
    )

    run_index_round

    visit "digital_objects/#{digital_object.id}"

    expand_elements = all('#digital_object_file_versions__accordion .glyphicon')
    expect(expand_elements.length).to eq 2

    expand_elements[0].click

    wait_for_ajax

    element = find('#digital_object_file_versions__file_version_0')
    expect(element).to have_text "File Format Caption 1 #{now}"

    sleep 3

    expand_elements[1].click
    element = find('#digital_object_file_versions__file_version_1')
    expect(element).to have_text "File Format Caption 2 #{now}"
  end

  it 'provides alt text for Digital Object Component file version images based on caption or title' do
    now = Time.now.to_i
    digital_object = create(
      :digital_object,
      title: "Digital Object Title #{now}",
      file_versions: [
        {
          file_uri: "File URI 1 #{now}",
          file_format_name: "jpeg",
          caption: "File Format Caption 1 #{now}"
        },
        {
          file_uri: "File URI 2 #{now}",
          file_format_name: "jpeg",
          caption: "File Format Caption 2 #{now}"
        }
      ]
    )

    digital_object_component = create(
      :digital_object_component,
      digital_object: { ref: digital_object.uri },
      title: "Digital Object Component Title #{now}",
      file_versions: [
        {
          file_uri: "File URI 1 #{now}",
          file_format_name: "jpeg",
          caption: "File Format Caption 1 #{now}"
        },
        {
          file_uri: "File URI 2 #{now}",
          file_format_name: "jpeg",
          caption: "File Format Caption 2 #{now}"
        }
      ]
    )

    run_index_round

    visit "digital_objects/#{digital_object.id}/#tree::digital_object_component_#{digital_object_component.id}"

    expand_elements = all('#digital_object_component_file_versions_ .glyphicon')
    expect(expand_elements.length).to eq 2

    expand_elements[0].click
    element = find('#digital_object_component_file_versions__file_version_0')
    expect(element).to have_text "File Format Caption 1 #{now}"

    sleep 3

    expand_elements[1].click
    element = find('#digital_object_component_file_versions__file_version_1')
    expect(element).to have_text "File Format Caption 2 #{now}"
  end
end
