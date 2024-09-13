# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Container Profiles', js: true do
  before(:all) do
    @repository = create(:repo, repo_code: "container_profiles_test_#{Time.now.to_i}", publish: true)
    @user = create_user(@repository => ['repository-archivists'])

    run_all_indexers
  end

  before(:each) do
    login_user(@user)
    select_repository(@repo)
  end

  it 'can create a container profile' do
    now = Time.now.to_i

    click_on 'Create'
    click_on 'Container Profile'

    fill_in 'Name', with: "Container Profile Name #{now}"
    select 'Millimeters', from: 'Dimension Units'
    select 'Depth', from: 'Extent Dimension'
    fill_in 'Depth', with: '1'
    fill_in 'Height', with: '2'
    fill_in 'Width', with: '3'

    # Click on save
    element = find('button', text: 'Save Container Profile', match: :first)
    element.click

    expect(page).to have_text 'Container Profile Created'
  end

  it 'cannot create a container profile with non-digit dimensions' do
    now = Time.now.to_i

    click_on 'Create'
    click_on 'Container Profile'

    fill_in 'Name', with: "Container Profile Name #{now}"
    select 'Millimeters', from: 'Dimension Units'
    select 'Depth', from: 'Extent Dimension'
    fill_in 'Depth', with: '1.1mm'
    fill_in 'Height', with: '2.2222'
    fill_in 'Width', with: '3.3m'

    # Click on save
    element = find('button', text: 'Save Container Profile', match: :first)
    element.click

    expect(page).to have_text 'Depth - Must be a number with no more than 2 decimal places'
    expect(page).to have_text 'Height - Must be a number with no more than 2 decimal places'
    expect(page).to have_text 'Width - Must be a number with no more than 2 decimal places'

    fill_in 'Depth', with: '1.11'
    fill_in 'Height', with: '2.22'
    fill_in 'Width', with: '3.33'

    # Click on save
    element = find('button', text: 'Save Container Profile', match: :first)
    element.click

    expect(page).to have_text 'Container Profile Created'
  end

  it 'can merge container profiles from browse when a repository manager' do
    now = Time.now.to_i

    profile_a = create(:json_container_profile, :name => "Container Profile A #{now}")
    profile_b = create(:json_container_profile, :name => "Container Profile B #{now}")

    run_index_round

    click_on 'Browse'
    click_on 'Container Profiles'

    element = find(:xpath, "//table//tr[td[contains(., '#{profile_a.name}')]]")
    within element do
      find('#multiselect-item').click
    end

    element = find(:xpath, "//table//tr[td[contains(., '#{profile_b.name}')]]")
    within element do
      find('#multiselect-item').click
    end

    click_on 'Merge'

    within '#batchMergeModal' do
      within '#mergeList' do
        find(:css, "[id='/container_profiles/#{profile_a.id}']").click
      end

      click_on 'Select merge destination'
    end

    within '#bulkMergeConfirmModal' do
      click_on 'Merge 2 records'
    end

    expect(page).to have_text 'Container Profiles(s) Merged'

    run_index_round

    visit '/'
    click_on 'Browse'
    click_on 'Container Profiles'
    expect(page).to have_text profile_a.name

    # Search for merged record
    input_text = find('#filter-text')
    input_text.fill_in with: profile_b.name
    input_text.send_keys(:enter)
    expect(page).to have_text 'No records found'
  end
end
