# frozen_string_literal: true

require_relative '../spec_helper'

describe 'User Preferences' do
  before(:all) do
    @repo = create(:repo, repo_code: "user_pref_test_#{Time.now.to_i}")
    set_repo(@repo)

    @accession = create(:accession, title: 'a browseable accession')

    run_all_indexers

    @driver = Driver.get
    @driver.login_to_repo($admin, @repo)
  end

  after(:all) do
    @driver ? @driver.quit : next
  end

  it 'allows you to configure browse columns' do
    @driver.find_element(:css, '.user-container .btn.dropdown-toggle.last').click
    @driver.wait_for_dropdown
    @driver.find_element(:link, 'Repository Preferences').click

    @driver.find_element(id: 'preference_defaults__accession_browse_column_1_').select_option_with_text('Title')
    @driver.find_element(id: 'preference_defaults__accession_browse_column_2_').select_option_with_text('Acquisition Type')
    @driver.click_and_wait_until_gone(css: 'button[type="submit"]')
    @driver.find_element(css: '.alert-success')

    @driver.find_element(link: 'Browse').click
    @driver.click_and_wait_until_gone(link: 'Accessions')
    @driver.find_element(link: 'Create Accession')

    cells = @driver.find_elements(:css, 'table th')
    expect(cells[1].text).to eq('Title')
    expect(cells[2].text).to eq('Acquisition Type')
  end

  it 'allows you to set default sort column and direction' do
    @driver.find_element(:css, '.user-container .btn.dropdown-toggle.last').click
    @driver.wait_for_dropdown
    @driver.find_element(:link, 'Repository Preferences').click
    @driver.find_element(id: 'preference_defaults__accession_sort_column_').select_option_with_text('Accession Date')
    @driver.find_element(id: 'preference_defaults__accession_sort_direction_').select_option_with_text('Descending')
    @driver.click_and_wait_until_gone(css: 'button[type="submit"]')
    @driver.find_element(css: '.alert-success')

    @driver.find_element(link: 'Browse').click
    @driver.click_and_wait_until_gone(link: 'Accessions')

    expect do
      @driver.find_element_with_text('//span', /Accession Date Descending/)
    end.not_to raise_error
  end

  it 'allows you to reset previously set preferences to defaults' do
    @driver.find_element(:css, '.user-container .btn.dropdown-toggle.last').click
    @driver.wait_for_dropdown
    @driver.find_element(:link, 'Repository Preferences').click
    @driver.find_element(:css, '.reset-prefs.btn').click
    @driver.click_and_wait_until_gone(:css, '#confirmChangesModal #confirmButton')
    @driver.find_element(css: '.alert-success')

    @driver.find_element(:css, '.user-container .btn.dropdown-toggle.last').click
    @driver.wait_for_dropdown
    @driver.find_element(:link, 'Repository Preferences').click

    # The default changes made above are now gone
    expect(@driver.find_element(id: 'preference_defaults__accession_browse_column_1_').text).to match(/Accept Default:/)
    expect(@driver.find_element(id: 'preference_defaults__accession_sort_column_').text).to match(/Accept Default:/)
  end

  it 'has date and extent columns by default' do
    @driver.find_element(link: 'Browse').click
    @driver.click_and_wait_until_gone(link: 'Accessions')

    expect do
      @driver.find_element_with_text('//th', /Dates/)
      @driver.find_element_with_text('//th', /Extent/)
    end.not_to raise_error
  end
end

describe 'User Preferences (unprivileged)' do
  before(:all) do
    @repo = create(:repo, repo_code: "user_pref_unpriv_test_#{Time.now.to_i}")
    set_repo(@repo)

    run_all_indexers

    @driver = Driver.get

    @viewer_user = create_user(@repo => ['repository-viewers'])
    @driver.login_to_repo(@viewer_user, @repo)
  end

  after(:all) do
    @driver ? @driver.quit : next
  end

  it "allows access to global preferences for unprivileged users" do
    @driver.find_element(:css, '.user-container .btn.dropdown-toggle.last').click
    @driver.wait_for_dropdown
    @driver.find_element(:link, "Global Preferences (#{@viewer_user.username})").click
  end
end
