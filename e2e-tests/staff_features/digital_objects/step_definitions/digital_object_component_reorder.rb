# frozen_string_literal: true

Given 'a Digital Object with two Digital Object Components has been created' do
  create_e2e_digital_object_in_tree

  @digital_object_component_first_id = add_digital_object_component_via_toolbar(
    "Digital Object Component A Label #{@uuid}"
  )

  select_digital_object_root_in_infinite_tree

  @digital_object_component_second_id = add_digital_object_component_via_toolbar(
    "Digital Object Component B Label #{@uuid}"
  )
end

Given 'a Digital Object with two nested Digital Object Components has been created' do
  create_e2e_digital_object_in_tree

  @digital_object_component_first_id = add_digital_object_component_via_toolbar(
    "Digital Object Component A Label #{@uuid}"
  )

  @digital_object_component_second_id = add_digital_object_component_via_toolbar(
    "Digital Object Component B Label #{@uuid}"
  )
end

Given 'a Digital Object with two Digital Object Components in the same level has been created' do
  create_e2e_digital_object_in_tree

  @digital_object_component_first_id = add_digital_object_component_via_toolbar(
    "Digital Object Component A Label #{@uuid}"
  )

  @digital_object_component_second_id = add_digital_object_component_sibling_via_toolbar(
    "Digital Object Component B Label #{@uuid}"
  )
end

When 'the user expands the first Digital Object Component' do
  expand_selector = "#digital_object_component_#{@digital_object_component_first_id} .node-expand"
  find(expand_selector).click if page.has_css?(expand_selector, wait: 2)
end

When 'the user selects the second Digital Object Component' do
  select_digital_object_component_in_infinite_tree(
    @digital_object_component_second_id,
    label: "Digital Object Component B Label #{@uuid}"
  )
end

When 'the user selects the Digital Object' do
  select_digital_object_root_in_infinite_tree
end

When 'the user selects the first Digital Object Component' do
  select_digital_object_component_in_infinite_tree(
    @digital_object_component_first_id,
    label: "Digital Object Component A Label #{@uuid}"
  )
end

Then 'the second Digital Object Component is pasted as a child of the Digital Object' do
  wait_for_infinite_tree_reorder_idle
  expect(page).to have_css "#digital_object_component_#{@digital_object_component_first_id}.indent-level-1"
  expect(page).to have_css "#digital_object_component_#{@digital_object_component_second_id}.indent-level-1"
end

Then 'the second Digital Object Component moves a level up' do
  wait_for_infinite_tree_reorder_idle
  expect(page).to have_css "#digital_object_component_#{@digital_object_component_first_id}.indent-level-1"
  expect(page).to have_css "#digital_object_component_#{@digital_object_component_second_id}.indent-level-1"
end

Then 'the second Digital Object Component moves one position up' do
  expect_digital_object_root_child_order(
    @digital_object_component_second_id,
    @digital_object_component_first_id
  )
end

When 'the user selects the first Digital Object Component from the dropdown menu' do
  within '.js-itree-toolbar-move-menu' do
    find('button[data-move-action="down-into"]:not([data-target-node-id])').hover
    find(
      "button[data-move-action='down-into'][data-target-node-id='digital_object_component_#{@digital_object_component_first_id}']",
      visible: true
    ).click
  end
  wait_for_ajax
end

When 'the user selects the second Digital Object Component from the dropdown menu' do
  within '.js-itree-toolbar-move-menu' do
    find('button[data-move-action="down-into"]:not([data-target-node-id])').hover
    find(
      "button[data-move-action='down-into'][data-target-node-id='digital_object_component_#{@digital_object_component_second_id}']",
      visible: true
    ).click
  end
  wait_for_ajax
end

Then 'the second Digital Object Component moves as a child into the first Digital Object Component' do
  wait_for_infinite_tree_reorder_idle
  expect(page).to have_css "#digital_object_component_#{@digital_object_component_first_id}.indent-level-1"
  expect(page).to have_css "#digital_object_component_#{@digital_object_component_second_id}.indent-level-2"
end

Then 'the first Digital Object Component moves as a child into the second Digital Object Component' do
  wait_for_infinite_tree_reorder_idle
  expect(page).to have_css "#digital_object_component_#{@digital_object_component_second_id}.indent-level-1"
  expect(page).to have_css "#digital_object_component_#{@digital_object_component_first_id}.indent-level-2"
end
