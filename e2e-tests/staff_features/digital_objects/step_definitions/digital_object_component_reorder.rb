# frozen_string_literal: true

Given 'a Digital Object with two Digital Object Components has been created' do
  visit "#{STAFF_URL}/digital_objects/new"

  fill_in 'digital_object_digital_object_id_', with: "Digital Object Identifier #{@uuid}"
  fill_in 'digital_object_title_', with: "Digital Object Title #{@uuid}"

  click_on 'Add Date'
  select 'Single', from: 'digital_object_dates__0__date_type_'
  fill_in 'digital_object_dates__0__begin_', with: '2000-01-01'

  click_on 'Save'

  wait_for_ajax
  expect(find('.alert.alert-success.with-hide-alert').text).to have_text "Digital Object Digital Object Title #{@uuid} Created"
  @digital_object_id = current_url.split('::digital_object_').pop

  click_on 'Add Child'
  wait_for_ajax
  fill_in 'Label', with: "Digital Object Component A Label #{@uuid}"
  click_on 'Save'
  wait_for_ajax
  expect(find('.alert.alert-success.with-hide-alert').text).to eq "Digital Object Component created on Digital Object Digital Object Title #{@uuid}"
  @digital_object_component_first_id = current_url.split('::digital_object_component_').pop

  within '#tree-container' do
    click_on "Digital Object Title #{@uuid}"
  end

  click_on 'Add Child'
  wait_for_ajax
  fill_in 'Label', with: "Digital Object Component B Label #{@uuid}"
  click_on 'Save'
  wait_for_ajax
  expect(find('.alert.alert-success.with-hide-alert').text).to eq "Digital Object Component created on Digital Object Digital Object Title #{@uuid}"
  @digital_object_component_second_id = current_url.split('::digital_object_component_').pop
end

Given 'a Digital Object with two nested Digital Object Components has been created' do
  visit "#{STAFF_URL}/digital_objects/new"

  fill_in 'digital_object_digital_object_id_', with: "Digital Object Identifier #{@uuid}"
  fill_in 'digital_object_title_', with: "Digital Object Title #{@uuid}"

  click_on 'Add Date'
  select 'Single', from: 'digital_object_dates__0__date_type_'
  fill_in 'digital_object_dates__0__begin_', with: '2000-01-01'

  click_on 'Save'

  wait_for_ajax
  expect(find('.alert.alert-success.with-hide-alert').text).to have_text "Digital Object Digital Object Title #{@uuid} Created"
  @digital_object_id = current_url.split('::digital_object_').pop

  click_on 'Add Child'
  wait_for_ajax
  fill_in 'Label', with: "Digital Object Component A Label #{@uuid}"
  click_on 'Save'
  wait_for_ajax
  expect(find('.alert.alert-success.with-hide-alert').text).to eq "Digital Object Component created on Digital Object Digital Object Title #{@uuid}"
  @digital_object_component_first_id = current_url.split('::digital_object_component_').pop

  click_on 'Add Child'
  wait_for_ajax
  fill_in 'Label', with: "Digital Object Component B Label #{@uuid}"
  click_on 'Save'
  wait_for_ajax
  expect(find('.alert.alert-success.with-hide-alert').text).to eq "Digital Object Component created as child of on Digital Object Digital Object Title #{@uuid}"
  @digital_object_component_second_id = current_url.split('::digital_object_component_').pop
end

When 'the user selects the second Digital Object Component' do
  click_on "Digital Object Component B Label #{@uuid}"

  wait_for_ajax
end

When 'the user selects the first Digital Object Component' do
  click_on "Digital Object Component A Label #{@uuid}"

  wait_for_ajax
end

Then 'the second Digital Object Component is pasted as a child of the Digital Object Component' do
  expect(page).to have_css "#digital_object_component_#{@digital_object_component_first_id}.indent-level-1"
  expect(page).to have_css "#digital_object_component_#{@digital_object_component_second_id}.indent-level-2"
end

Then 'the second Digital Object Component moves a level up' do
  expect(page).to have_css "#digital_object_component_#{@digital_object_component_first_id}.indent-level-1"
  expect(page).to have_css "#digital_object_component_#{@digital_object_component_second_id}.indent-level-1"
end

Then 'the second Digital Object Component moves one position up' do
  wait_for_ajax

  elements = all('.table-row.largetree-node.indent-level-1')

  tries = 0
  while elements[0][:id] == ''
    break if tries == 3

    sleep 3
    tries += 1
    elements = all('.table-row.largetree-node.indent-level-1')
  end

  puts "\n\n\n\nelements[0][:id].inspect"
  puts elements[0][:id].inspect
  puts elements[1][:id].inspect

  expect(elements[0][:id]).to eq "digital_object_component_#{@digital_object_component_second_id}"
  expect(elements[1][:id]).to eq "digital_object_component_#{@digital_object_component_first_id}"
end

When 'the user selects the first Digital Object Component from the dropdown menu' do
  within '.dropdown-menu' do
    find('.rounded-0.dropdown-item.cursor-default.move-node.move-node-down-into', match: :first).hover
  end

  element = find("[data-tree_id=\"digital_object_component_#{@digital_object_component_first_id}\"]")
  element.click
end

Then 'the second Digital Object Component moves as a child into the first Digital Object Component' do
  expect(page).to have_css "#digital_object_component_#{@digital_object_component_first_id}.indent-level-1"
  expect(page).to have_css "#digital_object_component_#{@digital_object_component_second_id}.indent-level-2"
end
