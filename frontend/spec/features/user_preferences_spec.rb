# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'User Preferences', js: true do
  before(:all) do
    now = Time.now.to_i
    repository_name = "user_preferences_test_#{now}"
    @repository = create(:repo, repo_code: repository_name)

    run_all_indexers
  end

  before(:each) do
    admin_user = BackendClientMethods::ASpaceUser.new('admin', 'admin')
    login_user(admin_user)
    select_repository(@repository)
  end

  it 'allows you to configure browse columns' do
    now = Time.now.to_i
    accession = create(:json_accession, title: "Test accession title #{now}")

    run_index_round

    element = find('#user-menu-dropdown')
    element.click
    click_on 'Default Repository Preferences'

    expect(page).to have_text "Default Repository Preferences -- #{@repository_name}"

    select 'Title', from: 'preference_defaults__accession_browse_column_1_'
    select 'Acquisition Type', from: 'preference_defaults__accession_browse_column_2_'
    select 'Restrictions Apply', from: 'preference_defaults__accession_browse_column_3_'

    # Click on save
    element = find('button', text: 'Save', match: :first)
    element.click

    expect(page).to have_text 'Preferences updated'
    expect(page).to have_text "Edit these values to set preferences for all users in the current repository. These values can be overridden by a user's own preferences."

    click_on 'Browse'
    click_on 'Accessions'

    element = all('table thead tr th')
    expect(element[1]).to have_text 'Title'
    expect(element[2]).to have_text 'Acquisition Type'
    expect(element[3]).to have_text 'Restrictions Apply'
  end

  it 'allows you to set default sort column and direction' do
    now = Time.now.to_i
    accession = create(:json_accession, title: "Test accession title #{now}")

    run_index_round

    element = find('#user-menu-dropdown')
    element.click
    click_on 'Default Repository Preferences'

    select 'Accession Date', from: 'preference_defaults__accession_sort_column_'
    select 'Descending', from: 'preference_defaults__accession_sort_direction_'

    # Click on save
    element = find('button', text: 'Save', match: :first)
    element.click

    expect(page).to have_text 'Preferences updated'
    expect(page).to have_text "Edit these values to set preferences for all users in the current repository. These values can be overridden by a user's own preferences."

    click_on 'Browse'
    click_on 'Accessions'

    expect(page).to have_text 'Accession Date Descending'
  end

  it 'allows you to reset previously set preferences to defaults' do
    now = Time.now.to_i
    accession = create(:json_accession, title: "Test accession title #{now}")

    run_index_round

    element = find('#user-menu-dropdown')
    element.click
    click_on 'Default Repository Preferences'

    expect(page).to have_text "Default Repository Preferences -- #{@repository_name}"

    select 'Title', from: 'preference_defaults__accession_browse_column_1_'
    select 'Acquisition Type', from: 'preference_defaults__accession_browse_column_2_'
    select 'Restrictions Apply', from: 'preference_defaults__accession_browse_column_3_'
    select 'Accession Date', from: 'preference_defaults__accession_sort_column_'
    select 'Descending', from: 'preference_defaults__accession_sort_direction_'

    # Click on save
    element = find('button', text: 'Save', match: :first)
    element.click

    click_on 'Reset Defaults'
    within '#confirmChangesModal' do
      click_on 'Reset Defaults'
    end

    expect(page).to have_text 'Preferences set to application defaults'

    element = find('#user-menu-dropdown')
    element.click
    click_on 'Default Repository Preferences'

    expect(page).to have_select('preference_defaults__accession_browse_column_1_', selected: '> Accept Default: Title')
    expect(page).to have_select('preference_defaults__accession_browse_column_2_', selected: '> Accept Default: Identifier')
    expect(page).to have_select('preference_defaults__accession_browse_column_3_', selected: '> Accept Default: Accession Date')
    expect(page).to have_select('preference_defaults__accession_sort_column_', selected: '> Accept Default: Title')
    expect(page).to have_select('preference_defaults__accession_sort_direction_', selected: '> Accept Default: Ascending')
  end

  it 'has date and extent columns by default' do
    now = Time.now.to_i
    accession = create(:json_accession, title: "Test accession title #{now}")

    run_index_round

    click_on 'Browse'
    click_on 'Accessions'

    element = all('table thead tr th')
    expect(element[4]).to have_text 'Dates'
    expect(element[5]).to have_text 'Extent'
  end
end

describe 'User Preferences (unprivileged)', js: true do
  before(:all) do
    now = Time.now.to_i
    repository_name = "user_preferences_test_#{now}"
    @repository = create(:repo, repo_code: repository_name)
    @repository_user = create_user(@repository => ['repository-viewers'])

    run_all_indexers
  end

  it "allows access to global preferences for unprivileged users" do
    login_user(@repository_user)
    select_repository(@repository)

    element = find('#user-menu-dropdown')
    element.click
    click_on "Global Preferences (#{@repository_user.username})"
    expect(page).to have_text "Global Preferences (#{@repository_user.username})"
    expect(page).to have_text 'Edit these values to set your user preferences. These values can be overridden by repository defaults or by your own preferences for a repository.'
  end
end
