# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Digital Object RDE', js: true do
  let(:user) { create_user(repo => ['repository-archivists']) }
  let(:repo) { create(:repo, repo_code: "digital_object_rde_#{Time.now.to_i}") }

  before(:each) do
    set_repo repo
    login_user(user)
    run_indexer
    select_repository(repo)
  end

  it 'can review error messages on an invalid entry' do
    now = Time.now.to_i
    digital_object = create(:digital_object, title: "Digital Object Title #{now}")
    run_indexer
    visit "digital_objects/#{digital_object.id}/edit"
    wait_for_infinite_tree_pane_ready

    open_infinite_tree_rapid_data_entry_modal
    expect(page).to have_css '#digital_record_children_children__0__title_'

    click_on 'Save Rows'

    element = find('.alert.alert-danger')
    expect(element.text).to eq '1 row(s) with an error - click a row field to view the errors for that row'
    page.execute_script("$('#digital_record_children_children__0__title_').closest('tr').addClass('last-focused')")
    element = find('.error-summary-header')
    expect(element.text).to eq 'Errors in row:'
    element = find('.error-summary-list')

    expect(element.text).to eq "Date - you must provide a Label, Title or Date\nTitle - you must provide a Label, Title or Date\nLabel - you must provide a Label, Title or Date"

    select 'Single', from: 'digital_record_children_children__0__dates__0__date_type_'

    click_on 'Save Rows'
    wait_for_ajax

    element = find('.alert.alert-danger')
    expect(element.text).to eq '1 row(s) with an error - click a row field to view the errors for that row'

    page.execute_script("$('#digital_record_children_children__0__title_').closest('tr').addClass('last-focused')")

    element = find('.error-summary-header')
    expect(element.text).to eq 'Errors in row:'
    element = find('.error-summary-list')
    expect(element.text).to eq "Expression - is required unless a begin or end date is given\nBegin - is required unless an expression or an end date is given\nEnd - is required unless an expression or a begin date is given"
  end

  it 'can add a child via the RDE form' do
    now = Time.now.to_i
    child_title = "Children Title #{now}"
    digital_object = create(:digital_object, title: "Digital Object Title #{now}")
    run_indexer

    visit "digital_objects/#{digital_object.id}/edit"
    wait_for_infinite_tree_pane_ready

    open_infinite_tree_rapid_data_entry_modal

    select 'Single', from: 'digital_record_children_children__0__dates__0__date_type_'
    fill_in 'digital_record_children_children__0__title_', with: child_title
    fill_in 'digital_record_children_children__0__dates__0__begin_', with: '2013'

    click_on 'Save Rows'
    wait_for_ajax

    expect(page).to have_css(
      "#infinite-tree-container .node.indent-level-1 a.record-title",
      text: child_title,
      wait: 20
    )
  end

  it 'can access the RDE form when editing a digital object component' do
    now = Time.now.to_i
    child_title = "Children Title nav #{now}"
    digital_object = create(:digital_object, title: "Digital Object Title #{now}")
    run_indexer

    visit "digital_objects/#{digital_object.id}/edit"
    wait_for_infinite_tree_pane_ready

    open_infinite_tree_rapid_data_entry_modal

    select 'Single', from: 'digital_record_children_children__0__dates__0__date_type_'
    fill_in 'digital_record_children_children__0__title_', with: child_title
    fill_in 'digital_record_children_children__0__dates__0__begin_', with: '2013'

    click_on 'Save Rows'

    expect(page).to have_css(
      "#infinite-tree-container .node.indent-level-1 a.record-title",
      text: child_title,
      wait: 20
    )

    expect(page).to have_css('#infinite-tree-record-pane #form_digital_object', wait: 20)
    wait_for_ajax

    within('#infinite-tree-container') do
      click_link child_title
    end
    wait_for_ajax

    within('#infinite-tree-record-pane') do
      expect(page).to have_css('#form_digital_object_component', wait: 20)
      expect(page).to have_css('h2', text: "#{child_title}, 2013 Digital Object Component")
    end

    expect(find('#digital_object_component_title_', visible: false).text).to eq child_title

    open_infinite_tree_rapid_data_entry_modal
  end

  it 'can add multiple children and sticky columns stick' do
    now = Time.now.to_i
    digital_object = create(:digital_object, title: "Digital Object Title #{now}")
    run_indexer

    visit "digital_objects/#{digital_object.id}/edit"
    wait_for_infinite_tree_pane_ready

    open_infinite_tree_rapid_data_entry_modal

    select 'Single', from: 'digital_record_children_children__0__dates__0__date_type_'
    find('#digital_record_children_children__0__publish_').click
    fill_in 'digital_record_children_children__0__dates__0__begin_', with: '2013'
    fill_in 'digital_record_children_children__0__title_', with: 'Child 1'

    find('#rapidDataEntryModal .btn.add-rows-dropdown', match: :first).click
    click_on 'Add Rows'

    expect(find('#digital_record_children_children__1__dates__0__date_type_').value).to eq 'single'
    expect(find('#digital_record_children_children__1__publish_').checked?).to eq true
    expect(find('#digital_record_children_children__1__dates__0__begin_').value).to eq '2013'
    expect(find('#digital_record_children_children__1__title_').value).to eq 'Child 1'

    fill_in 'digital_record_children_children__1__title_', with: 'Child 2'

    click_on 'Save Rows'
    wait_for_ajax

    expect(page).to have_css(
      "#infinite-tree-container a.record-title",
      text: 'Child 1',
      wait: 20
    )
    expect(page).to have_css(
      "#infinite-tree-container a.record-title",
      text: 'Child 2',
      wait: 20
    )
  end

  it 'can add multiple rows in one action and can perform a basic fill and a sequence fill' do
    now = Time.now.to_i
    digital_object = create(:digital_object, title: "Digital Object Title #{now}")
    run_indexer

    visit "digital_objects/#{digital_object.id}/edit"
    wait_for_infinite_tree_pane_ready

    open_infinite_tree_rapid_data_entry_modal

    find('#digital_record_children_children__0__publish_').click

    find('#rapidDataEntryModal .btn.add-rows-dropdown', match: :first).click

    element = find('.add-rows-form input', match: :first)
    8.times do
      element.send_keys(:arrow_up)
    end
    expect(element.value).to eq '9'

    click_on 'Add Rows'

    9.times do |index|
      expect(find("#digital_record_children_children__#{index}__publish_").checked?).to eq true
    end

    # Basic fill
    click_on 'Fill Column'
    select 'Basic Information - Label', from: 'basicFillTargetColumn'
    fill_in 'basicFillValue', with: "Fill value #{now}"
    click_on 'Apply Fill'
    9.times do |index|
      expect(find("#digital_record_children_children__#{index}__label_").value).to eq "Fill value #{now}"
    end

    # Sequence fill
    click_on 'Fill Column'
    click_on 'Sequence'

    select 'Basic Information - Title', from: 'sequenceFillTargetColumn'
    fill_in 'sequenceFillPrefix', with: 'ABC'
    fill_in 'sequenceFillFrom', with: '1'
    fill_in 'sequenceFillTo', with: '5'

    click_on 'Apply Sequence'

    element = find('#sequenceTooSmallMsg')
    expect(element.text).to eq "There are more rows than there are items in the sequence.\nContinue"

    fill_in 'sequenceFillTo', with: '10'
    click_on 'Apply Sequence'

    (0..9).each do |index|
      expect(find("#digital_record_children_children__#{index}__title_").value).to eq "ABC#{index+1}"
    end
  end
end
