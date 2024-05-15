# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Space Calculator', js: true do
  before(:all) do
    @repository = create(:repo, repo_code: "space_calculator_#{Time.now.to_i}")
    set_repo @repository

    @admin_user = BackendClientMethods::ASpaceUser.new('admin', 'admin')
    @manager_user = create_user(@repository => ['repository-managers'])

    @container_profile = create(:container_profile,
                                dimension_units: 'inches',
                                width: '10',
                                height: '10',
                                depth: '10',
                                stacking_limit: '2')

    @location_profile = create(:location_profile,
                               dimension_units: 'inches',
                               width: '100',
                               height: '20',
                               depth: '10')

    @location = create(:location,
                       floor: '5',
                       room: '1A',
                       area: 'Shadowy Corner',
                       location_profile: {
                         ref: @location_profile.uri
                       })

    @top_container = create(:top_container,
                            container_profile: {
                              ref: @container_profile.uri
                            })

    run_index_round
  end

  it 'can access the calculator via the container profile toolbar and run the calculator for a building, floor, room and area combination' do
    login_user(@manager_user)
    select_repository(@repository)

    visit "container_profiles/#{@container_profile.id}"
    expect(page).to have_text @container_profile.name

    click_on 'Space Calculator'

    element = find('#spaceCalculatorModal')
    expect(element).to have_text 'Space Calculator'

    select @location.building, from: 'building'
    select @location.floor, from: 'floor'
    select @location.room, from: 'room'
    select @location.area, from: 'area'

    click_on 'Check for Space'

    expect(page).to have_text 'Total number of spaces available for this container type: 20'
    expect(page).to have_text 'Total number of containers of this type found at these locations: 0'
    expect(page).to have_text 'Locations with space available: 1', normalize_ws: true
    elements = all('#tabledSearchResults tbody tr td')
    expect(elements[1]).to have_text @location.title
    expect(elements[2]).to have_text @location_profile.name
    expect(elements[3]).to have_text '20'

    click_on 'Close'
  end

  it 'can access the calculator from a top container form' do
    login_user(@admin_user)
    select_repository(@repository)

    visit "top_containers/#{@top_container.id}/edit"
    expect(page).to have_text @top_container.indicator

    click_on 'Add Location'
    element = find('#container_locations .linker-wrapper .btn.locations')
    element.click

    click_on 'Find with Space Calculator'

    element = find('#spaceCalculatorModal')
    expect(element).to have_text 'Space Calculator'
  end

  it 'can run the calculator for a specific location' do
    login_user(@admin_user)
    select_repository(@repository)

    visit "container_profiles/#{@container_profile.id}"
    expect(page).to have_text @container_profile.name

    click_on 'Space Calculator'
    click_on 'By Location(s)'

    element = find('#token-input-location')
    element.fill_in with: @location.title
    dropdown_items = all('li.token-input-dropdown-item2')
    dropdown_items.first.click

    click_on 'Check for Space'

    expect(page).to have_text 'Total number of spaces available for this container type: 20'
    expect(page).to have_text 'Total number of containers of this type found at these locations: 0'
    expect(page).to have_text 'Locations with space available: 1', normalize_ws: true

    elements = all('#tabledSearchResults tbody tr td')
    expect(elements[1]).to have_text @location.title
    expect(elements[2]).to have_text @location_profile.name
    expect(elements[3]).to have_text '20'

  end

  it "can select a location from the calculator results to populate the Container's Location field" do
    login_user(@admin_user)
    select_repository(@repository)

    visit "top_containers/#{@top_container.id}/edit"
    expect(page).to have_text @top_container.indicator

    click_on 'Add Location'
    element = find('#container_locations .linker-wrapper .btn.locations')
    element.click

    click_on 'Find with Space Calculator'

    element = find('#spaceCalculatorModal')
    expect(element).to have_text 'Space Calculator'

    click_on 'By Location(s)'

    element = find('#token-input-location')
    element.fill_in with: @location.title
    dropdown_items = all('li.token-input-dropdown-item2')
    dropdown_items.first.click

    click_on 'Check for Space'

    element = find("#linker-item__locations_#{@location.id}")
    element.click
    expect(element).to be_checked

    element = find("#tabledSearchResults tr.has-space.selected")
    element = find('#addSelectedButton')
    element.click


    element = find("#_locations_#{@location.id}")
    expect(element).to have_text @location.title
  end
end
