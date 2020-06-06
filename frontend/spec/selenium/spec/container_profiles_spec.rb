# frozen_string_literal: true

require_relative '../spec_helper'

describe 'Container Profiles' do
  before(:all) do
    @repo = create(:repo, repo_code: "container_profiles_test_#{Time.now.to_i}")
    set_repo @repo

    @archivist_user = create_user(@repo => ['repository-archivists'])
    @manager_user = create_user(@repo => ['repository-managers'])

    run_all_indexers

    @driver = Driver.get.login_to_repo(@manager_user, @repo)
  end

  after(:all) do
    @driver ? @driver.quit : next
  end

  it 'can create a container profile' do
    @driver.login_to_repo(@archivist_user, @repo)
    @driver.find_element(:link, 'Create').click
    @driver.click_and_wait_until_gone(:link, 'Container Profile')

    @driver.clear_and_send_keys([:id, 'container_profile_name_'], 'An itty bitty box')
    @driver.find_element(id: 'container_profile_dimension_units_').select_option('millimeters')
    @driver.find_element(id: 'container_profile_extent_dimension_').select_option('depth')
    @driver.clear_and_send_keys([:id, 'container_profile_depth_'], 1)
    @driver.clear_and_send_keys([:id, 'container_profile_height_'], 1)
    @driver.clear_and_send_keys([:id, 'container_profile_width_'], 0.2)

    @driver.click_and_wait_until_gone(:css, 'form#new_container_profile .btn-primary')

    @driver.find_element_with_text('//div[contains(@class, "alert-success")]', /Container Profile Created/)

  end

  it 'cannot create a container profile with non-digit dimensions' do
    @driver.login_to_repo(@archivist_user, @repo)
    @driver.find_element(:link, 'Create').click
    @driver.click_and_wait_until_gone(:link, 'Container Profile')

    @driver.clear_and_send_keys([:id, 'container_profile_name_'], 'Not-a-number box')
    @driver.find_element(id: 'container_profile_dimension_units_').select_option('inches')
    @driver.find_element(id: 'container_profile_extent_dimension_').select_option('height')
    @driver.clear_and_send_keys([:id, 'container_profile_depth_'], 12)
    @driver.clear_and_send_keys([:id, 'container_profile_height_'], 'one')
    @driver.clear_and_send_keys([:id, 'container_profile_width_'], 18)

    @driver.click_and_wait_until_gone(:css, 'form#new_container_profile .btn-primary')

    expect do
      @driver.find_element_with_text('//div[contains(@class, "error")]', /Height - Must be a number with no more than 2 decimal places\./, false, true)
    end.to raise_error(Selenium::WebDriver::Error::NoSuchElementError)

    @driver.clear_and_send_keys([:id, 'container_profile_height_'], 10)
    @driver.click_and_wait_until_gone(:css, 'form#new_container_profile .btn-primary')

    @driver.find_element_with_text('//div[contains(@class, "alert-success")]', /Container Profile Created/)

  end

  it 'can merge container profiles from browse when a repository manager' do

    run_all_indexers

    @driver.find_element(:link, 'Browse').click
    @driver.click_and_wait_until_gone(:link, 'Container Profiles')

    # Two container profiles exist
    @driver.find_element_with_text('//td[contains(@class, "col")]', /An itty bitty box/)
    @driver.find_element_with_text('//td[contains(@class, "col")]', /Not-a-number box/)

    # Select profiles to merge
    @driver.find_element(:css, 'th input#select_all').click
    @driver.find_element(:css, '.record-toolbar .btn#batchMerge').click

    # Selection modal exists and includes selected elements
    expect do
      @driver.find_element(:css, '#batchMergeModal')
      @driver.find_element_with_text('//div[contains(@class, "selected-record-list")]', /An itty bitty box/)
      @driver.find_element_with_text('//div[contains(@class, "selected-record-list")]', /Not-a-number box/)
    end.not_to raise_error

    # Select target and merge
    @driver.find_elements(:css, 'div.selected-record-list input')[0].click
    @driver.find_element(:css, 'div#batchMergeModal .merge-button').click

    # Confirmation modal exists and merge occurs
    expect do
      @driver.find_element(:css, '#bulkMergeConfirmModal')
    end.not_to raise_error

    @driver.click_and_wait_until_gone(:css, 'div#bulkMergeConfirmModal .merge-button')
    assert(5) { expect(@driver.find_element(:css, '.alert.alert-success').text).to eq('Container Profiles(s) Merged') }

    run_index_round

    @driver.find_element(:link, 'Browse').click
    @driver.click_and_wait_until_gone(:link, 'Container Profiles')

    @driver.find_element_with_text('//div', /Showing 1 - 1 of 1 Results/)
    assert(5) { expect(@driver.find_element_with_text('//tr[1]/td[2]', /An itty bitty box/)).not_to be_nil }

  end

end
