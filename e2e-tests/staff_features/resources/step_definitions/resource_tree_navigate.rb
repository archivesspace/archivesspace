# frozen_string_literal: true

Given 'a Resource with two Archival Objects has been created' do
  visit "#{STAFF_URL}/resources/new"

  fill_in 'resource_title_', with: "Resource #{@uuid}"
  fill_in 'resource_id_0_', with: "Resource #{@uuid}"
  select 'Class', from: 'resource_level_'
  element = find('#resource_lang_materials__0__language_and_script__language_')
  element.send_keys('AU')
  element.send_keys(:tab)

  select 'Single', from: 'resource_dates__0__date_type_'
  within '.input-group.date' do
    fill_in 'resource_dates__0__begin_', with: '2024'
  end

  fill_in 'resource_extents__0__number_', with: '10'
  select 'Cassettes', from: 'resource_extents__0__extent_type_'

  element = find('#resource_finding_aid_language_')
  element.send_keys('ENG')
  element.send_keys(:tab)

  element = find('#resource_finding_aid_script_')
  element.send_keys('Latin')
  element.send_keys(:tab)

  find('button', text: 'Save Resource', match: :first).click

  wait_for_ajax
  expect(page).to have_text "Resource Resource #{@uuid} created"

  url_parts = current_url.split('/')
  url_parts.pop
  @resource_id = url_parts.pop

  within '#infinite-tree-toolbar' do
    click_on 'Add Child'
  end
  wait_for_infinite_tree_inline_new_form(form_prefix: 'archival_object')

  fill_in 'archival_object_title_', with: "Archival Object 1 #{@uuid}"
  select 'Class', from: 'archival_object_level_'
  find('button', text: 'Save Archival Object', match: :first).click
  wait_for_infinite_tree_inline_edit_form(form_prefix: 'archival_object')

  aggregate_failures do
    expect(page).to have_text "Archival Object Archival Object 1 #{@uuid} on Resource Resource #{@uuid} created"
    expect(page).to have_css('.infinite-tree .node.current', text: "Archival Object 1 #{@uuid}")
    expect(page).to have_no_css('#infinite-tree-toolbar .js-itree-toolbar-add-child.disabled')
  end

  within '#infinite-tree-toolbar' do
    click_on 'Add Child'
  end
  wait_for_infinite_tree_inline_new_form(form_prefix: 'archival_object')

  fill_in 'archival_object_title_', with: "Archival Object 2 #{@uuid}"
  select 'Class', from: 'archival_object_level_'
  find('button', text: 'Save Archival Object', match: :first).click
  wait_for_infinite_tree_inline_edit_form(form_prefix: 'archival_object')

  aggregate_failures do
    expect(page).to have_text "Archival Object Archival Object 2 #{@uuid} created as child of Archival Object 1 #{@uuid} on Resource Resource #{@uuid}"
    expect(page).to have_css('.infinite-tree .node', text: "Archival Object 2 #{@uuid}")
  end
end

Then 'the Resource is displayed as the top level of the navigation tree' do
  expect(page).to have_css ".infinite-tree > .root.node#resource_#{@resource_id}:only-child"

  rows = all('.infinite-tree .node', visible: true)

  aggregate_failures do
    expect(rows.length).to eq 2
    expect(rows[0].text).to include "Resource #{@uuid}"
  end
end

Then 'the Resource is current in the tree' do
  rows = all('.infinite-tree .node')

  aggregate_failures do
    expect(rows.length).to eq 2
    expect(rows[0].text).to include "Resource #{@uuid}"
    expect(rows[0][:class]).to include 'current'
  end
end

Given 'only the first-level Archival Objects are displayed' do
  rows = all('.infinite-tree .node')

  aggregate_failures do
    expect(rows.length).to eq 2
    expect(rows[1].text).to include "Archival Object 1 #{@uuid}"
  end
end

Then 'the expand arrows are disabled' do
  arrows = all('#infinite-tree-container li.node:not(.root) > .node-row .node-expand')

  aggregate_failures do
    expect(arrows.length).to eq 1
    expect(arrows[0][:class]).to include 'disabled'
  end

  arrows[0].click

  expect(page).to have_text "Archival Object 2 #{@uuid}"
end

Then 'all Archival Objects are displayed' do
  wait_for_ajax
  rows = all('.infinite-tree .node')

  aggregate_failures do
    expect(rows.length).to eq 3
    expect(rows[1].text).to include "Archival Object 1 #{@uuid}"
    expect(rows[2].text).to include "Archival Object 2 #{@uuid}"
  end
end

When 'the user clicks on {string} in the tree toolbar' do |string|
  within '#infinite-tree-toolbar' do
    click_on_string string
  end
end

Then 'only the top-level Archival Objects are displayed' do
  aggregate_failures do
    expect(page).to have_css('.infinite-tree .node', count: 2)
    expect(page).to have_css('.infinite-tree .node', text: "Archival Object 1 #{@uuid}")
    expect(page).to have_no_css('.infinite-tree .node', text: "Archival Object 2 #{@uuid}")
  end
end

Given 'all levels of hierarchy in the tree are expanded' do
  within '#infinite-tree-toolbar' do
    click_on 'Auto-Expand All'
  end
  aggregate_failures do
    expect(page).to have_css('#infinite-tree-container.expand-all')
    expect(page).to have_css(
      '#infinite-tree-container li.node:not(.root) > .node-row .node-expand.disabled'
    )
    expect(page).to have_css(
      '#infinite-tree-toolbar .js-itree-toolbar-expand-mode.btn-success',
      visible: true,
      text: 'Disable Auto-Expand'
    )
    expect(page).to have_css('.infinite-tree .node', text: "Archival Object 2 #{@uuid}")
  end
end

Then 'the expand arrows are enabled' do
  arrows = all('#infinite-tree-container li.node:not(.root) > .node-row .node-expand')

  arrows.each do |arrow|
    expect(arrow[:class]).to_not include 'disabled'
  end
end
