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
  fill_in 'resource_dates__0__begin_', with: '2024'

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

  click_on 'Add Child'
  wait_for_ajax
  fill_in 'Title', with: "Archival Object 1 #{@uuid}"
  select 'Class', from: 'Level of Description'
  click_on 'Save'
  wait_for_ajax
  expect(page).to have_text "Archival Object Archival Object 1 #{@uuid} on Resource Resource #{@uuid} created"

  click_on 'Add Child'
  wait_for_ajax
  fill_in 'Title', with: "Archival Object 2 #{@uuid}"
  select 'Class', from: 'Level of Description'
  click_on 'Save'
  wait_for_ajax
  expect(page).to have_text "Archival Object Archival Object 2 #{@uuid} created as child of Archival Object 1 #{@uuid} on Resource Resource #{@uuid}"
end

Then 'the Resource is displayed as the top level of the navigation tree' do
  rows = all('#tree-container .table .table-row', visible: :all)

  expect(rows.length).to eq 4
  expect(rows[0].text).to include "Resource #{@uuid}"
end

Then 'the Resource is highlighted in the tree' do
  rows = all('#tree-container .table .table-row')

  expect(rows.length).to eq 2
  expect(rows[0].text).to include "Resource #{@uuid}"
  expect(rows[0][:class]).to include 'current'
end

Given 'only the first-level Archival Objects are displayed' do
  rows = all('#tree-container .table .table-row')

  expect(rows.length).to eq 2
  expect(rows[1].text).to include "Archival Object 1 #{@uuid}"
end

Then 'the expand arrows are disabled' do
  arrows = all('.expandme')

  expect(arrows.length).to eq 1

  expect(arrows[0][:class]).to include 'disabled'
  arrows[0].click
  expect(page).to have_text "Archival Object 2 #{@uuid}"
end

Then 'all Archival Objects are displayed' do
  wait_for_ajax

  rows = all('#tree-container .table .table-row')

  expect(rows.length).to eq 3
  expect(rows[1].text).to include "Archival Object 1 #{@uuid}"
  expect(rows[2].text).to include "Archival Object 2 #{@uuid}"
end

Then 'only the top-level Archival Objects are displayed' do
  rows = all('#tree-container .table .table-row')

  tries = 0
  loop do
    break if rows.length == 2 || tries == 3

    sleep 1
    tries += 1
    rows = all('#tree-container .table .table-row')
  end

  expect(rows.length).to eq 2
  expect(rows[1].text).to include "Archival Object 1 #{@uuid}"
end

Given 'all levels of hierarchy in the tree are expanded' do
  click_on 'Auto-Expand All'

  wait_for_ajax
end

Then 'the expand arrows are enabled' do
  arrows = all('.expandme')

  arrows.each do |arrow|
    expect(arrow[:class]).to_not include 'disabled'
  end
end
