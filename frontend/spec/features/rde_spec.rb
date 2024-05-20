# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'RDE', js: true do
  let(:user) { create_user(repo => ['repository-archivists']) }
  let(:repo) { create(:repo, repo_code: "accession_test_#{Time.now.to_i}") }

  before(:each) do
    login_user(user)
    run_all_indexers
    select_repository(repo)
  end

  it 'can review error messages on an invalid entry' do
    resource = create(:resource)
    run_index_round

    visit "resources/#{resource.id}/edit"

    click_on 'Rapid Data Entry'
    expect(page).to have_css '#rapidDataEntryModal'
    expect(page).to have_css '#archival_record_children_children__0__level_'

    click_on 'Save Rows'

    element = find('.alert.alert-danger')
    expect(element.text).to eq '1 row(s) with an error - click a row field to view the errors for that row'
    page.execute_script("$('#archival_record_children_children__0__title_').closest('tr').addClass('last-focused')")
    element = find('.error-summary-header')
    expect(element.text).to eq 'Errors in row:'
    element = find('.error-summary-list')
    expect(element.text).to eq 'Level of Description - Property is required but was missing'

    select 'Single', from: 'archival_record_children_children__0__dates__0__date_type_'

    click_on 'Save Rows'

    while true do
      sleep 1
      break if page.evaluate_script('jQuery.active') == 0
    end

    element = find('.alert.alert-danger')
    expect(element.text).to eq '1 row(s) with an error - click a row field to view the errors for that row'
    page.execute_script("$('#archival_record_children_children__0__title_').closest('tr').addClass('last-focused')")

    element = find('.error-summary-header')
    expect(element.text).to eq 'Errors in row:'
    element = find('.error-summary-list')
    expect(element.text).to eq "Expression - is required unless a begin or end date is given\nBegin - is required unless an expression or an end date is given\nEnd - is required unless an expression or a begin date is given\nLevel of Description - Property is required but was missing"
  end

  it 'can add a child via the RDE form' do
    now = Time.now.to_i
    resource = create(:resource)
    run_index_round

    visit "resources/#{resource.id}/edit"

    click_on 'Rapid Data Entry'
    expect(page).to have_css '#rapidDataEntryModal'

    select 'Single', from: 'archival_record_children_children__0__dates__0__date_type_'
    select 'Item', from: 'archival_record_children_children__0__level_'
    fill_in 'archival_record_children_children__0__title_', with: "Children Title #{now}"
    fill_in 'archival_record_children_children__0__dates__0__begin_', with: "2013"

    click_on 'Save Rows'

    element = find("#tree-container a", text: "Children Title #{now}")
    element = element.find(:xpath, "ancestor::*[@role='listitem']")
    element = element.find('.resource-level')
    expect(element.text).to eq 'Item'
  end

  it 'can access the RDE form when editing an archival object' do
    now = Time.now.to_i
    resource = create(:resource)
    run_index_round

    visit "resources/#{resource.id}/edit"

    click_on 'Rapid Data Entry'
    expect(page).to have_css '#rapidDataEntryModal'

    select 'Single', from: 'archival_record_children_children__0__dates__0__date_type_'
    select 'Item', from: 'archival_record_children_children__0__level_'
    fill_in 'archival_record_children_children__0__title_', with: "Children Title #{now}"
    fill_in 'archival_record_children_children__0__dates__0__begin_', with: "2013"

    click_on 'Save Rows'

    find('.table-row.largetree-node.indent-level-1 a.record-title').click

    element = find('h2')
    expect(element.text).to eq "Children Title #{now}, 2013 Archival Object"
    element = find('#archival_object_title_', visible: false)
    expect(element.text).to eq "Children Title #{now}"

    click_on 'Rapid Data Entry'
    expect(page).to have_css '#rapidDataEntryModal'
  end

  it 'can add multiple children and sticky columns stick' do
    resource = create(:resource)
    run_index_round

    visit "resources/#{resource.id}/edit"

    click_on 'Rapid Data Entry'
    expect(page).to have_css '#rapidDataEntryModal'

    select 'Fonds', from: 'archival_record_children_children__0__level_'
    select 'Single', from: 'archival_record_children_children__0__dates__0__date_type_'
    find('#archival_record_children_children__0__publish_').click
    fill_in 'archival_record_children_children__0__dates__0__begin_', with: '2013'
    fill_in 'archival_record_children_children__0__title_', with: 'Child 1'
    find("#rapidDataEntryModal th", text: 'Title').click

    find('#rapidDataEntryModal .btn.add-rows-dropdown', match: :first).click
    click_on 'Add Rows'

    expect(find('#archival_record_children_children__1__level_').value).to eq 'fonds'
    expect(find('#archival_record_children_children__1__dates__0__date_type_').value).to eq 'single'
    expect(find('#archival_record_children_children__1__publish_').checked?).to eq true
    expect(find('#archival_record_children_children__1__dates__0__begin_').value).to eq '2013'
    expect(find('#archival_record_children_children__1__title_').value).to eq 'Child 1'

    fill_in 'archival_record_children_children__1__title_', with: 'Child 2'

    click_on 'Save Rows'

    element = find("#tree-container a", text: "Child 1")
    element = element.find(:xpath, "ancestor::*[@role='listitem']")
    element = element.find('.resource-level')
    expect(element.text).to eq 'Fonds'

    element = find("#tree-container a", text: "Child 2")
    element = element.find(:xpath, "ancestor::*[@role='listitem']")
    element = element.find('.resource-level')
    expect(element.text).to eq 'Fonds'
  end

  it 'can add multiple rows in one action and can perform a basic fill and a sequence fill' do
    resource = create(:resource)
    run_index_round

    visit "resources/#{resource.id}/edit"

    click_on 'Rapid Data Entry'
    expect(page).to have_css '#rapidDataEntryModal'

    select 'Fonds', from: 'archival_record_children_children__0__level_'
    find('#archival_record_children_children__0__publish_').click

    find('#rapidDataEntryModal .btn.add-rows-dropdown', match: :first).click

    element = find('.add-rows-form input', match: :first)
    8.times do
      element.send_keys(:arrow_up)
    end
    expect(element.value).to eq '9'

    click_on 'Add Rows'

    9.times do |index|
      expect(find("#archival_record_children_children__#{index}__level_").value).to eq 'fonds'
      expect(find("#archival_record_children_children__#{index}__publish_").checked?).to eq true
    end

    # Basic fill
    click_on 'Fill Column'
    select 'Basic Information - Level of Description', from: 'basicFillTargetColumn'
    select 'Item', from: 'basicFillValue'
    click_on 'Apply Fill'
    9.times do |index|
      expect(find("#archival_record_children_children__#{index}__level_").value).to eq 'item'
    end

    # Sequence fill
    click_on 'Fill Column'
    click_on 'Sequence'

    select 'Basic Information - Component Unique Identifier', from: 'sequenceFillTargetColumn'
    fill_in 'sequenceFillPrefix', with: 'ABC'
    fill_in 'sequenceFillFrom', with: '1'
    fill_in 'sequenceFillTo', with: '5'

    click_on 'Apply Sequence'

    element = find('#sequenceTooSmallMsg')
    expect(element.text).to eq "There are more rows than there are items in the sequence.\nContinue"

    fill_in 'sequenceFillTo', with: '10'
    click_on 'Apply Sequence'

    (0..9).each do |index|
      expect(find("#archival_record_children_children__#{index}__component_id_").value).to eq "ABC#{index+1}"
    end
  end

  it 'can perform a column reorder' do
    resource = create(:resource)
    run_index_round

    visit "resources/#{resource.id}/edit"

    click_on 'Rapid Data Entry'

    expect(page).to have_css '#rapidDataEntryModal'

    elements = all('table .fieldset-labels th')
    old_position = elements.index { |cell| cell[:id] === 'colLevel' }

    click_on 'Reorder Columns'

    select 'Basic Information - Level of Description', from: 'columnOrder'

    find('#columnOrderDown').click

    click_on 'Apply Column Order'

    elements = all('table .fieldset-labels th')
    new_position = elements.index { |cell| cell[:id] === 'colLevel' }

    expect(new_position > old_position).to eq true
  end
end
