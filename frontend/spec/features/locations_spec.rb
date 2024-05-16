# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Locations', js: true do
  before(:all) do
    now = Time.now.to_i
    @repository = create(:repo, repo_code: "locations_test_#{now}")

    set_repo @repository

    @manager_user = create_user(@repository => ['repository-managers'])
    @archivist_user = create_user(@repository => ['repository-archivists'])

    run_index_round
  end

  before(:each) do
    login_user(@manager_user)
    select_repository(@repository)
  end

  it 'allows access to the single location form' do
    click_on 'Create'
    click_on 'Location'
    click_on 'Single Location'

    element = find('h2')
    expect(element.text).to eq 'New Location Location'
  end

  it 'displays error messages upon invalid location' do
    now = Time.now.to_i

    click_on 'Create'
    click_on 'Location'
    click_on 'Single Location'

    element = find('h2')
    expect(element.text).to eq 'New Location Location'

    # Click on save
    find('button', text: 'Save Location', match: :first).click
    element = find('.alert.alert-danger.with-hide-alert')
    expect(element.text).to eq 'Building - Property is required but was missing'

    fill_in 'location_building_', with: "Location Building #{now}"

    # Click on save
    find('button', text: 'Save Location', match: :first).click

    element = find('.alert.alert-danger.with-hide-alert')
    expect(element.text).to eq 'You must either specify a barcode, a classification, or both a coordinate 1 label and coordinate 1 indicator'
  end

  it 'saves a valid location' do
    now = Time.now.to_i

    click_on 'Create'
    click_on 'Location'
    click_on 'Single Location'

    element = find('h2')
    expect(element.text).to eq 'New Location Location'

    fill_in 'location_building_', with: "Location Building #{now}"
    fill_in 'location_floor_', with: '1'
    fill_in 'location_room_', with: '1'
    fill_in 'location_coordinate_1_label_', with: "Label 1 #{now}"
    fill_in 'location_coordinate_1_indicator_', with: "Indicator 1 #{now}"

    # Click on save
    find('button', text: 'Save Location', match: :first).click
    element = find('.alert.alert-success.with-hide-alert')
    expect(element.text).to eq 'Location Created'
  end

  it 'allows locations to be edited and persists the temporary location' do
    location = create(:location)

    visit "locations/#{location.id}/edit"
    fill_in 'location_room_', with: '111'
    find('#location_temporary_question_').click
    select 'Conservation', from: 'location_temporary_'

    # Click on save
    find('button', text: 'Save Location', match: :first).click
    element = find('.alert.alert-success.with-hide-alert')
    expect(element.text).to eq 'Location Saved'
    expect(find('#location_temporary_').value).to eq 'conservation'

    find('a.hide-alert').click
    # Click on save
    find('button', text: 'Save Location', match: :first).click
    element = find('.alert.alert-success.with-hide-alert')
    expect(element.text).to eq 'Location Saved'
    expect(find('#location_temporary_').value).to eq 'conservation'
  end

  it 'lists the new location in the browse list' do
    now = Time.now.to_i

    click_on 'Create'
    click_on 'Location'
    click_on 'Single Location'

    element = find('h2')
    expect(element.text).to eq 'New Location Location'

    fill_in 'location_building_', with: "Location Building #{now}"
    fill_in 'location_floor_', with: '1'
    fill_in 'location_room_', with: '1'
    fill_in 'location_coordinate_1_label_', with: "Label 1 #{now}"
    fill_in 'location_coordinate_1_indicator_', with: "Indicator 1 #{now}"

    # Click on save
    find('button', text: 'Save Location', match: :first).click
    element = find('.alert.alert-success.with-hide-alert')
    expect(element.text).to eq 'Location Created'

    run_index_round

    visit '/'
    click_on 'Browse'
    find('a', text: 'Locations', match: :first).click

    element = find('#filter-text')
    element.fill_in with: "Location Building #{now}"
    find('.sidebar input.text-filter-field + div button').click
    expect(page).to have_xpath("//tr[contains(., 'Location Building #{now}')]")
  end

  it 'saves a valid repository-owned location' do
    now = Time.now.to_i

    click_on 'Create'
    click_on 'Location'
    click_on 'Single Location'
    element = find('h2')
    expect(element.text).to eq 'New Location Location'
    fill_in 'location_building_', with: "Repository Building #{now}"
    fill_in 'location_coordinate_1_label_', with: "Coordinate Label #{now}"
    fill_in 'location_coordinate_1_indicator_', with: "Indicator Label #{now}"

    element = find('#token-input-location_owner_repo__ref_')
    element.fill_in with: 'locations_test_'
    dropdown_items = all('li.token-input-dropdown-item2')
    dropdown_items.first.click

    # Click on save
    find('button', text: 'Save Location', match: :first).click
    element = find('.alert.alert-success.with-hide-alert')
    expect(element.text).to eq 'Location Created'
  end

  it 'allows the new location to be viewed in non-edit mode' do
    now = Time.now.to_i

    click_on 'Create'
    click_on 'Location'
    click_on 'Single Location'

    element = find('h2')
    expect(element.text).to eq 'New Location Location'

    fill_in 'location_building_', with: "Location Building #{now}"
    fill_in 'location_floor_', with: '1'
    fill_in 'location_room_', with: '1'
    fill_in 'location_coordinate_1_label_', with: "Label 1 #{now}"
    fill_in 'location_coordinate_1_indicator_', with: "Indicator 1 #{now}"

    # Click on save
    find('button', text: 'Save Location', match: :first).click
    element = find('.alert.alert-success.with-hide-alert')
    expect(element.text).to eq 'Location Created'

    run_index_round

    visit '/'
    click_on 'Browse'
    click_on 'Locations'

    element = find('#filter-text')
    element.fill_in with: "Location Building #{now}"
    find('.sidebar input.text-filter-field + div button').click

    click_on 'View'

    element = find('h2')
    expect(element.text).to eq "Location Building #{now}, 1, 1 [Label 1 #{now}: Indicator 1 #{now}] Location"
  end

  it 'allows creation of a location with plus one stickies' do
    now = Time.now.to_i

    click_on 'Create'
    click_on 'Location'
    click_on 'Single Location'
    fill_in 'location_building_', with: "Location Building #{now}"
    fill_in 'location_floor_', with: '1'
    fill_in 'location_room_', with: '11'
    fill_in 'location_area_', with: '111'
    fill_in 'location_coordinate_1_label_', with: "Label 1 #{now}"
    fill_in 'location_coordinate_1_indicator_', with: "Indicator 1 #{now}"

    # Click on save
    find('.createPlusOneBtn', match: :first).click
    element = find('.alert.alert-success.with-hide-alert')
    expect(element.text).to eq 'Location Created'

    expect(find('#location_building_').value).to eq "Location Building #{now}"
    expect(find('#location_floor_').value).to eq '1'
    expect(find('#location_room_').value).to eq '11'
    expect(find('#location_area_').value).to eq '111'

    expect(find('#location_coordinate_1_label_').value).to eq ''
    expect(find('#location_coordinate_1_indicator_').value).to eq ''
  end

  it 'lists the new location for an archivist' do
    now = Time.now.to_i
    set_repo @repository
    location = create(:location, building: "Building #{now}")
    run_index_round

    visit 'logout'
    login_user(@archivist_user)
    select_repository(@repository)

    click_on 'Browse'
    click_on 'Locations'
    find('#filter-text').fill_in with: "#{now}"
    find('.sidebar input.text-filter-field + div button').click
    expect(page).to have_xpath("//tr[contains(., 'Building #{now}')]")
  end

  it "doesn't offer location edit actions to an archivist" do
    now = Time.now.to_i
    location = create(:location, building: "Location Building #{now}")
    run_index_round

    visit 'logout'
    login_user(@archivist_user)
    select_repository(@repository)

    click_on 'Browse'
    click_on 'Locations'
    find('#filter-text').fill_in with: "#{now}"
    find('.sidebar input.text-filter-field + div button').click
    expect(page).to have_xpath("//tr[contains(., 'Location Building #{now}')]")

    expect(page).not_to have_link('Create Location')
    expect(page).not_to have_link('Create Batch Locations')
    expect(page).not_to have_link('Edit')

    row = find(:xpath, "//tr[contains(., 'Location Building #{now}')]")
    within row do
      click_on 'View'
    end

    expect(page).not_to have_link('Edit')
  end

  it 'lists the location in different repositories and lists then filters locations by repository' do
    now = Time.now.to_i
    admin = BackendClientMethods::ASpaceUser.new('admin', 'admin')
    location = create(:location, building: "Location Building #{now}")
    repository = create(:repo, repo_code: "locations_test_different_repository#{now}")

    run_index_round

    visit "locations/#{location.id}/edit"

    element = find('#token-input-location_owner_repo__ref_')
    element.fill_in with: repository.repo_code
    dropdown_items = all('li.token-input-dropdown-item2')
    dropdown_items.first.click

    # Click on save
    find('button', text: 'Save Location', match: :first).click
    element = find('.alert.alert-success.with-hide-alert')
    expect(element.text).to eq 'Location Saved'

    run_index_round

    visit 'logout'

    login_user(admin)
    select_repository(repository.repo_code)

    click_on 'Browse'
    click_on 'Locations'
    find('#filter-text').fill_in with: "#{now}"
    find('.sidebar input.text-filter-field + div button').click
    expect(page).to have_xpath("//tr[contains(., 'Location Building #{now}')]")

    visit '/'
    click_on 'Browse'
    click_on 'Locations'

    within '.search-listing-filter' do
      find('h3', text: 'Repository')
      element = find('a', text: 'LOCATIONS_TEST_', match: :first)
      element.click
    end

    expect(page).to have_text /Showing .*1.* of.*Results/
  end
end

describe 'Location batch', js: true do
  before(:all) do
    now = Time.now.to_i
    @repository = create(:repo, repo_code: "locations_test_#{now}")

    set_repo @repository

    @manager_user = create_user(@repository => ['repository-managers'])
    @archivist_user = create_user(@repository => ['repository-archivists'])

    run_index_round
  end

  before(:each) do
    login_user(@manager_user)
    select_repository(@repository)
  end

  it 'displays error messages upon invalid batch' do
    click_on 'Browse'
    click_on 'Locations'
    click_on 'Create Batch Locations'

    # Click on save
    find('button', text: 'Create Locations', match: :first).click
    element = find('.alert.alert-danger.with-hide-alert')
    expect(element.text).to eq "Building - Property is required but was missing\nCoordinate Range 1 - Property is required but was missing"

    expect(page).not_to have_css('#location_batch_barcode_')
    expect(page).not_to have_css('#location_batch_classification_')
    expect(page).not_to have_css('#location_batch_coordinate_1_label_')
    expect(page).not_to have_css('#location_batch_coordinate_1_indicator_')
    expect(page).not_to have_css('#location_batch_coordinate_2_label_')
    expect(page).not_to have_css('#location_batch_coordinate_2_indicator_')
    expect(page).not_to have_css('#location_batch_coordinate_3_label_')
    expect(page).not_to have_css('#location_batch_coordinate_3_indicator_')
  end

  it 'can preview the titles of locations that will be created and creates all the locations for the range' do
    now = Time.now.to_i

    click_on 'Browse'
    click_on 'Locations'
    click_on 'Create Batch Locations'

    fill_in 'location_batch_building_', with: "Location Batch Building #{now}"

    fill_in 'location_batch_coordinate_1_range__label_', with: "Room"
    fill_in 'location_batch_coordinate_1_range__start_', with: "1A"
    fill_in 'location_batch_coordinate_1_range__end_', with: "1B"
    fill_in 'location_batch_coordinate_2_range__label_', with: "Shelf"
    fill_in 'location_batch_coordinate_2_range__start_', with: "1"
    fill_in 'location_batch_coordinate_2_range__end_', with: "4"

    click_on 'Preview'

    elements = all('#batchPreviewModal li')
    expect(elements.length).to eq 8

    expect(elements[0].text).to eq "Location Batch Building #{now} [Room: 1A, Shelf: 1]"
    expect(elements[1].text).to eq "Location Batch Building #{now} [Room: 1A, Shelf: 2]"
    expect(elements[2].text).to eq "Location Batch Building #{now} [Room: 1A, Shelf: 3]"
    expect(elements[3].text).to eq "Location Batch Building #{now} [Room: 1A, Shelf: 4]"
    expect(elements[4].text).to eq "Location Batch Building #{now} [Room: 1B, Shelf: 1]"
    expect(elements[5].text).to eq "Location Batch Building #{now} [Room: 1B, Shelf: 2]"
    expect(elements[6].text).to eq "Location Batch Building #{now} [Room: 1B, Shelf: 3]"
    expect(elements[7].text).to eq "Location Batch Building #{now} [Room: 1B, Shelf: 4]"

    click_on 'Continue'

    # Click on save
    find('button', text: 'Create Locations', match: :first).click
    element = find('.alert.alert-success.with-hide-alert')
    expect(element.text).to eq '8 Locations Created'

    run_index_round

    visit current_url

    find('#filter-text').fill_in with: "Location Batch Building #{now}"
    find('.sidebar input.text-filter-field + div button').click

    elements = all(:xpath, "//tr[contains(., 'Location Batch Building #{now}')]")
    expect(elements.length).to eq 8

    expect(elements[0].text).to include "Location Batch Building #{now} [Room: 1A, Shelf: 1]"
    expect(elements[1].text).to include "Location Batch Building #{now} [Room: 1A, Shelf: 2]"
    expect(elements[2].text).to include "Location Batch Building #{now} [Room: 1A, Shelf: 3]"
    expect(elements[3].text).to include "Location Batch Building #{now} [Room: 1A, Shelf: 4]"
    expect(elements[4].text).to include "Location Batch Building #{now} [Room: 1B, Shelf: 1]"
    expect(elements[5].text).to include "Location Batch Building #{now} [Room: 1B, Shelf: 2]"
    expect(elements[6].text).to include "Location Batch Building #{now} [Room: 1B, Shelf: 3]"
    expect(elements[7].text).to include "Location Batch Building #{now} [Room: 1B, Shelf: 4]"
  end

  it 'can edit locations in batch' do
    now = Time.now.to_i

    visit 'logout'
    login_admin

    location = create(:location, building: "Building 1 #{now}")
    location = create(:location, building: "Building 2 #{now}")
    location = create(:location, building: "Building 3 #{now}")

    run_index_round

    click_on 'Browse'
    click_on 'Locations'

    element = find('#filter-text').fill_in with: now
    find('.sidebar input.text-filter-field + div button').click

    elements = all(:xpath, "//tr[contains(., '#{now}')]")
    elements.each do |element|
      element.find('input').click
    end

    click_on 'Edit Batch'

    within '#confirmChangesModal' do
      click_on 'Edit Records'
    end

    fill_in 'location_batch_floor_', with: '6th'
    fill_in 'location_batch_room_', with: 'Studio 5'
    fill_in 'location_batch_area_', with: 'The corner'

    # Click on save
    find('button', text: 'Update Locations', match: :first).click
    element = find('.alert.alert-success.with-hide-alert')
    expect(element.text).to eq '3 Locations Updated'

    run_index_round
    visit current_url

    element = find('#filter-text').fill_in with: now
    find('.sidebar input.text-filter-field + div button').click

    elements = all(:xpath, "//tr[contains(., '#{now}')]")
    expect(elements.length).to eq 3

    expect(elements[0].text).to include "Building 1 #{now}, 6th, Studio 5"
    expect(elements[1].text).to include "Building 2 #{now}, 6th, Studio 5"
    expect(elements[2].text).to include "Building 3 #{now}, 6th, Studio 5"
  end

  it 'can create locations with +1 stickyness' do
    now = Time.now.to_i

    visit 'locations'
    click_on 'Create Batch Locations'

    fill_in 'location_batch_building_', with: "Location Batch Building #{now}"
    fill_in 'location_batch_floor_', with: "2nd"
    fill_in 'location_batch_room_', with: "201"
    fill_in 'location_batch_area_', with: "Corner"
    fill_in 'location_batch_coordinate_1_range__label_', with: "Room"
    fill_in 'location_batch_coordinate_1_range__start_', with: "1A"
    fill_in 'location_batch_coordinate_1_range__end_', with: "1B"
    fill_in 'location_batch_coordinate_2_range__label_', with: "Shelf"
    fill_in 'location_batch_coordinate_2_range__start_', with: "1"
    fill_in 'location_batch_coordinate_2_range__end_', with: "4"

    # Click on save
    find('#createPlusOne', match: :first).click
    element = find('.alert.alert-success.with-hide-alert')
    expect(element.text).to eq '8 Locations Created'

    expect(find('#location_batch_building_').value).to eq "Location Batch Building #{now}"
    expect(find('#location_batch_floor_').value).to eq '2nd'
    expect(find('#location_batch_room_').value).to eq '201'
    expect(find('#location_batch_area_').value).to eq 'Corner'
  end

  it 'correctly sorts locations in the browse list' do
    now = Time.now.to_i

    location = create(:location, building: "Building 1 AAA #{now}")
    location = create(:location, building: "Building 2 BBB #{now}")
    location = create(:location, building: "Building 3 CCC #{now}")

    run_index_round

    click_on 'Browse'
    click_on 'Locations'

    element = find('#filter-text')
    element.fill_in with: "#{now}"
    find('.sidebar input.text-filter-field + div button').click

    elements = all(:xpath, "//tr[contains(., '#{now}')]")
    expect(elements.length).to eq 3
    expect(elements[0].text).to include "Building 1 AAA #{now}"
    expect(elements[1].text).to include "Building 2 BBB #{now}"
    expect(elements[2].text).to include "Building 3 CCC #{now}"
  end
end
