# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Digital Object RDE', js: true do
  let(:user) { create_user(repo => ['repository-archivists']) }
  let(:repo) { create(:repo, repo_code: "accession_test_#{Time.now.to_i}") }

  before(:each) do
    login_user(user)
    run_all_indexers
    select_repository(repo)
  end

  it 'can review error messages on an invalid entry' do
    now = Time.now.to_i
    digital_object = create(:digital_object, title: "Digital Object Title #{now}")
    run_index_round
    visit "digital_objects/#{digital_object.id}/edit"

    click_on 'Rapid Data Entry'
    expect(page).to have_css '#rapidDataEntryModal'
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

    while true do
      sleep 1
      break if page.evaluate_script('jQuery.active') == 0
    end

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
    digital_object = create(:digital_object, title: "Digital Object Title #{now}")
    run_index_round

    visit "digital_objects/#{digital_object.id}/edit"

    click_on 'Rapid Data Entry'
    expect(page).to have_css '#rapidDataEntryModal'

    select 'Single', from: 'digital_record_children_children__0__dates__0__date_type_'
    fill_in 'digital_record_children_children__0__title_', with: "Children Title #{now}"
    fill_in 'digital_record_children_children__0__dates__0__begin_', with: "2013"

    click_on 'Save Rows'

    element = find("#tree-container a", text: "Children Title #{now}")
  end

  it 'can access the RDE form when editing an digital object' do
    now = Time.now.to_i
    digital_object = create(:digital_object, title: "Digital Object Title #{now}")
    run_index_round

    visit "digital_objects/#{digital_object.id}/edit"

    click_on 'Rapid Data Entry'
    expect(page).to have_css '#rapidDataEntryModal'

    select 'Single', from: 'digital_record_children_children__0__dates__0__date_type_'
    fill_in 'digital_record_children_children__0__title_', with: "Children Title #{now}"
    fill_in 'digital_record_children_children__0__dates__0__begin_', with: "2013"

    click_on 'Save Rows'

    find('.table-row.largetree-node.indent-level-1 a.record-title').click

    element = find('h2')
    expect(element.text).to eq "Children Title #{now}, 2013 Digital Object Component"
    element = find('#digital_object_component_title_', visible: false)
    expect(element.text).to eq "Children Title #{now}"

    click_on 'Rapid Data Entry'
    expect(page).to have_css '#rapidDataEntryModal'
  end

  it 'can add multiple children and sticky columns stick' do
    now = Time.now.to_i
    digital_object = create(:digital_object, title: "Digital Object Title #{now}")
    run_index_round

    visit "digital_objects/#{digital_object.id}/edit"

    click_on 'Rapid Data Entry'
    expect(page).to have_css '#rapidDataEntryModal'

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

    element = find("#tree-container a", text: "Child 1")
    element = element.find(:xpath, "ancestor::*[@role='listitem']")

    element = find("#tree-container a", text: "Child 2")
    element = element.find(:xpath, "ancestor::*[@role='listitem']")
  end

  it 'can add multiple rows in one action and can perform a basic fill and a sequence fill' do
    now = Time.now.to_i
    digital_object = create(:digital_object, title: "Digital Object Title #{now}")
    run_index_round

    visit "digital_objects/#{digital_object.id}/edit"

    click_on 'Rapid Data Entry'
    expect(page).to have_css '#rapidDataEntryModal'

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
